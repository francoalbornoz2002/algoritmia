extends Node

# 1. Referencia a la base de datos.
var db

# 2. Ruta de la base de datos
const DB_PATH = "user://algoritmia_game.db"

# 3. Script SQL de creación de tablas
const CREATE_TABLES_SQL = """
CREATE TABLE IF NOT EXISTS "alumno" (
	"id" TEXT NOT NULL UNIQUE,
	"nombre" TEXT NOT NULL,
	"apellido" TEXT NOT NULL,
	"genero" TEXT NOT NULL,
	"ultima_actividad" TEXT,
	PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "misiones" (
	"id" TEXT NOT NULL UNIQUE,
	"nombre" TEXT NOT NULL UNIQUE,
	"descripcion" TEXT NOT NULL UNIQUE,
	"dificultad_mision" TEXT NOT NULL,
	PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "misiones_especiales_local" (
	"id" TEXT NOT NULL UNIQUE,
	"nombre" TEXT NOT NULL,
	"descripcion" TEXT NOT NULL,
	"estrellas" INTEGER NOT NULL,
	"exp" INTEGER NOT NULL,
	"intentos" INTEGER NOT NULL,
	"fecha_completado" TEXT NOT NULL,
	"sincronizado" BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "misiones_completadas_local" (
	"id_mision" TEXT NOT NULL UNIQUE,
	"estrellas" INTEGER NOT NULL,
	"exp" INTEGER NOT NULL,
	"intentos" INTEGER NOT NULL,
	"fecha_completado" TEXT NOT NULL,
	"sincronizado" BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY ("id_mision"),
	FOREIGN KEY ("id_mision") REFERENCES "misiones" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "dificultades" (
	"id" TEXT NOT NULL UNIQUE,
	"nombre" TEXT NOT NULL,
	"descripcion" TEXT NOT NULL,
	"tema" TEXT NOT NULL,
	PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "dificultad_alumno_local" (
	"id_dificultad" TEXT NOT NULL UNIQUE,
	"grado" TEXT NOT NULL,
	"sincronizado" BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY ("id_dificultad"),
	FOREIGN KEY ("id_dificultad") REFERENCES "dificultades" ("id") ON UPDATE NO ACTION ON DELETE NO ACTION
);

"""


# 4. Función de inicio
func _ready():
	print("Iniciando DatabaseManager...")
	
	# Creamos una nueva instancia del objeto SQLite
	db = SQLite.new()
	
	# 1. Establecemos la ruta ANTES de abrir
	db.path = DB_PATH
	
	# 2. Habilitamos las claves foráneas
	db.foreign_keys = true
	
	# 3. Abrimos la base de datos
	var success = db.open_db()
	
	# Verificamos el éxito
	if not success:
		# El README dice que el error se guarda en "error_message"
		print("ERROR: No se pudo abrir la base de datos en: ", DB_PATH)
		print("Mensaje de error: ", db.error_message)
		return
	print("Base de datos abierta exitosamente en: ", DB_PATH)
	
	# 4. Ejecutamos el script de creación de tablas
	success = db.query(CREATE_TABLES_SQL)
	
	if success:
		print("Tablas verificadas/creadas exitosamente.")
	else:
		# Si falla, el error también está en "error_message"
		print("ERROR al crear tablas: ", db.error_message)


# 5. Función de cierre (_exit_tree)
func _exit_tree():
	if db:
		db.close_db()
		print("Base de datos cerrada.")

# -----------------------------------------------------------------
# FUNCIONES PÚBLICAS
# -----------------------------------------------------------------

## Recibe el JSON del endpoint 'auth/game-login' y escribe en la base de datos local.
func poblar_datos_login(datos_login: Dictionary) -> bool:
	print("Iniciando poblado de base de datos local...")
	
	# Verificamos que los datos mínimos existan
	if not datos_login.has("alumno"):
		print("ERROR (DBManager): Datos de login incompletos, falta 'alumno'.")
		return false
	
	# -----------------
	# 1. INICIAR TRANSACCIÓN
	# -----------------
	# Esto asegura que si algo falla, no dejamos la BD a medias.
	if not db.query("BEGIN TRANSACTION;"):
		print("ERROR (DBManager): No se pudo iniciar la transacción. ", db.error_message)
		return false

	# -----------------
	# 2. LIMPIAR DATOS ANTERIORES
	# -----------------
	var sql_limpieza = """
	DELETE FROM alumno;
	DELETE FROM misiones_completadas_local;
	DELETE FROM dificultad_alumno_local;
	DELETE FROM misiones_especiales_local;
	"""
	
	if not db.query(sql_limpieza):
		print("ERROR (DBManager): No se pudieron limpiar las tablas locales. ", db.error_message)
		db.query("ROLLBACK;") # Revertimos en caso de error
		return false
	
	# -----------------
	# 3. INSERTAR ALUMNO (1 fila)
	# -----------------
	var alumno = datos_login["alumno"]
	var sql_alumno = "INSERT INTO alumno (id, nombre, apellido, genero, ultima_actividad) VALUES (?, ?, ?, ?, ?);"
	
	# Mapeamos camelCase (JSON) a los bindings
	var bindings_alumno = [
		alumno["id"],
		alumno["nombre"],
		alumno["apellido"],
		alumno["genero"],
		alumno["ultimaActividad"] # Mapeo de 'ultimaActividad'
	]
	
	if not db.query_with_bindings(sql_alumno, bindings_alumno):
		print("ERROR (DBManager): No se pudo insertar el alumno. ", db.error_message)
		db.query("ROLLBACK;")
		return false

	# -----------------
	# 4. INSERTAR MISIONES COMPLETADAS (Loop)
	# -----------------
	var misiones_completadas = datos_login.get("misionesCompletadas", [])
	var sql_mision = "INSERT INTO misiones_completadas_local (id_mision, estrellas, exp, intentos, fecha_completado, sincronizado) VALUES (?, ?, ?, ?, ?, ?);"
	
	for mision in misiones_completadas:
		var bindings_mision = [
			mision["idMision"],
			mision["estrellas"],
			mision["exp"],
			mision["intentos"],
			mision["fechaCompletado"],
			true # Marcamos como sincronizado
			]
		if not db.query_with_bindings(sql_mision, bindings_mision):
			print("ERROR (DBManager): No se pudo insertar misión completada. ", db.error_message)
			db.query("ROLLBACK;")
			return false

	# -----------------
	# 5. INSERTAR DIFICULTADES ALUMNO (Loop)
	# -----------------
	var dificultades_alumno = datos_login.get("dificultadesAlumno", [])
	var sql_dificultad = "INSERT INTO dificultad_alumno_local (id_dificultad, grado, sincronizado) VALUES (?, ?, ?);"
	
	for dificultad in dificultades_alumno:
		var bindings_dificultad = [
			dificultad["idDificultad"],
			dificultad["grado"],
			true # Marcamos como sincronizado
		]
		if not db.query_with_bindings(sql_dificultad, bindings_dificultad):
			print("ERROR (DBManager): No se pudo insertar dificultad de alumno. ", db.error_message)
			db.query("ROLLBACK;")
			return false
	
	# -----------------
	# 6. CERRAR TRANSACCIÓN
	# -----------------
	if not db.query("COMMIT;"):
		print("ERROR (DBManager): No se pudo hacer COMMIT de la transacción. ", db.error_message)
		db.query("ROLLBACK;") # Intentar revertir
		return false
	
	print("Datos de login poblados exitosamente en la BD local.")
	return true

## Devuelve un Array de Diccionarios con todas las misiones.
func obtener_misiones() -> Array:
	# Hacemos la consulta
	var success = db.query("SELECT id, nombre FROM misiones;")
	
	if not success:
		print("ERROR (DBManager): No se pudieron obtener las misiones. ", db.error_message)
		return [] # Devolver array vacío en caso de error
	
	# Devolvemos el resultado
	return db.query_result


## Devuelve un Array de Diccionarios con todas las dificultades.
func obtener_dificultades() -> Array:
	# Hacemos la consulta
	var success = db.query("SELECT id, nombre FROM dificultades;")
	
	if not success:
		print("ERROR (DBManager): No se pudieron obtener las dificultades. ", db.error_message)
		return [] # Devolver array vacío en caso de error
	
	# Devolvemos el resultado
	return db.query_result

## Obtiene el ID del alumno actualmente logueado para enviar a la API de NestJS.
func obtener_id_alumno_actual() -> String:
	var exito = db.query("SELECT id FROM alumno LIMIT 1;")
	if not exito:
		print("ERROR (DBManager): No se pudo obtener id_alumno. ", db.error_message)
		return ""
	
	# Verificamos que tengamos un resultado
	if db.query_result.is_empty():
		print("ERROR (DBManager): No hay ningún alumno en la BD local.")
		return ""
		
	# Devolvemos el ID
	return db.query_result[0]["id"]


## Escribe una misión completada en la BD local.
## Usa "INSERT OR REPLACE" para sobrescribir si ya existía (ej: la jugó offline 2 veces).
## Marca "sincronizado" como 'false' (0).
## También actualiza la 'ultima_actividad' del alumno.
func registrar_mision_local(id_mision: String, estrellas: int, exp: int, intentos: int) -> bool:
	print("DBManager: Registrando misión localmente...")
	
	# Obtenemos el diccionario de tiempo EN UTC
	var dict_utc = Time.get_datetime_dict_from_system(true) # true = UTC

	# Construimos el string ISO 8601 manualmente para asegurar la "Z"
	var fecha_actual = "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		dict_utc.year,
		dict_utc.month,
		dict_utc.day,
		dict_utc.hour,
		dict_utc.minute,
		dict_utc.second
	]
	
	# Usamos una transacción para asegurar que ambas escrituras (misión y alumno) ocurran
	if not db.query("BEGIN TRANSACTION;"):
		print("ERROR (DBManager): No se pudo iniciar transacción. ", db.error_message)
		return false

	# 1. Insertamos o reemplazamos la misión
	var sql_mision = "INSERT OR REPLACE INTO misiones_completadas_local (id_mision, estrellas, exp, intentos, fecha_completado, sincronizado) VALUES (?, ?, ?, ?, ?, ?);"
	var bindings_mision = [
		id_mision,
		estrellas,
		exp,
		intentos,
		fecha_actual,
		false # false (0) -> NO sincronizado
	]
	
	if not db.query_with_bindings(sql_mision, bindings_mision):
		print("ERROR (DBManager): No se pudo registrar misión local. ", db.error_message)
		db.query("ROLLBACK;")
		return false
		
	# 2. Actualizamos la última actividad del alumno
	var sql_alumno = "UPDATE alumno SET ultima_actividad = ?;"
	var bindings_alumno = [ fecha_actual ]
	
	if not db.query_with_bindings(sql_alumno, bindings_alumno):
		print("ERROR (DBManager): No se pudo actualizar ultima_actividad. ", db.error_message)
		db.query("ROLLBACK;")
		return false

	# 3. Si todo salió bien, cerramos la transacción
	if not db.query("COMMIT;"):
		print("ERROR (DBManager): No se pudo hacer COMMIT. ", db.error_message)
		return false
		
	print("DBManager: Misión local registrada y ultima_actividad actualizada.")
	return true

## Marca una misión como sincronizada (sincronizado = true)
func marcar_mision_sincronizada(id_mision: String) -> bool:
	print("DBManager: Marcando misión como sincronizada: ", id_mision)
	var sql = "UPDATE misiones_completadas_local SET sincronizado = true WHERE id_mision = ?;"
	var bindings = [ id_mision ]
	
	if not db.query_with_bindings(sql, bindings):
		print("ERROR (DBManager): No se pudo marcar como sincronizado. ", db.error_message)
		return false
	
	return true

# Devuelve un Array de Diccionarios con todas las misiones pendientes de sincronizar.
func obtener_misiones_pendientes() -> Array:
	# Selecciona todo de misiones_completadas_local donde sincronizado = 0 (false)
	var exito = db.query("SELECT * FROM misiones_completadas_local WHERE sincronizado = 0;")
	
	if not exito:
		print("ERROR (DBManager): No se pudieron obtener misiones pendientes. ", db.error_message)
		return []
	
	# Retornamos el resultado
	return db.query_result


# Marca un LOTE de misiones como sincronizadas (sincronizado = true)
# Recibe un array de IDs de misiones.
func marcar_lote_misiones_sincronizadas(ids_misiones: Array) -> bool:
	if ids_misiones.is_empty():
		return true # No hay nada que hacer
		
	print("DBManager: Marcando %s misiones como sincronizadas..." % ids_misiones.size())
	
	# Usamos una transacción para esto
	if not db.query("BEGIN TRANSACTION;"):
		print("ERROR (DBManager): No se pudo iniciar transacción (marcar lote). ", db.error_message)
		return false

	var sql = "UPDATE misiones_completadas_local SET sincronizado = true WHERE id_mision = ?;"
	
	# Recorremos el array y ejecutamos un UPDATE por cada ID
	for id_mision in ids_misiones:
		if not db.query_with_bindings(sql, [id_mision]):
			print("ERROR (DBManager): No se pudo marcar misión %s. " % id_mision, db.error_message)
			db.query("ROLLBACK;") # Revertimos la transacción
			return false

	# Si todo salió bien, cerramos la transacción
	if not db.query("COMMIT;"):
		print("ERROR (DBManager): No se pudo hacer COMMIT (marcar lote). ", db.error_message)
		return false
		
	return true

## Escribe una dificultad de alumno en la BD local.
## Usa "INSERT OR REPLACE" para crear o actualizar el grado.
## Marca "sincronizado" como 'false' (0).
func registrar_dificultad_local(id_dificultad: String, grado: String) -> bool:
	print("DBManager: Registrando dificultad localmente...")
	
	# INSERT OR REPLACE asegura que si la dificultad ya existe, solo actualiza el grado.
	var sql = "INSERT OR REPLACE INTO dificultad_alumno_local (id_dificultad, grado, sincronizado) VALUES (?, ?, ?);"
	var bindings = [
		id_dificultad,
		grado,
		false # false (0) -> NO sincronizado
	]
	
	if not db.query_with_bindings(sql, bindings):
		print("ERROR (DBManager): No se pudo registrar dificultad local. ", db.error_message)
		return false
		
	print("DBManager: Dificultad local registrada (o actualizada).")
	return true


## Devuelve un Array de Diccionarios con TODAS las dificultades pendientes.
func obtener_dificultades_pendientes() -> Array:
	var exito = db.query("SELECT * FROM dificultad_alumno_local WHERE sincronizado = 0;")
	
	if not exito:
		print("ERROR (DBManager): No se pudieron obtener dificultades pendientes. ", db.error_message)
		return []
	
	# Devolvemos el resultado
	return db.query_result


## Marca un LOTE de dificultades como sincronizadas (sincronizado = true)
func marcar_lote_dificultades_sincronizadas(ids_dificultades: Array) -> bool:
	if ids_dificultades.is_empty():
		return true # No hay nada que hacer
		
	print("DBManager: Marcando %s dificultades como sincronizadas..." % ids_dificultades.size())
	
	if not db.query("BEGIN TRANSACTION;"):
		print("ERROR (DBManager): No se pudo iniciar transacción (marcar lote dif). ", db.error_message)
		return false

	var sql = "UPDATE dificultad_alumno_local SET sincronizado = true WHERE id_dificultad = ?;"
	
	for id_dificultad in ids_dificultades:
		if not db.query_with_bindings(sql, [id_dificultad]):
			print("ERROR (DBManager): No se pudo marcar dificultad %s. " % id_dificultad, db.error_message)
			db.query("ROLLBACK;")
			return false

	if not db.query("COMMIT;"):
		print("ERROR (DBManager): No se pudo hacer COMMIT (marcar lote dif). ", db.error_message)
		return false
		
	return true

# 1. Función para saber si hay un alumno registrado (Sesión iniciada)
func existe_sesion_activa() -> bool:
	# Simplemente buscamos si hay alguna fila en la tabla 'alumno'
	db.query("SELECT count(*) as total FROM alumno;")
	if db.query_result.is_empty():
		return false
	
	# Si el conteo es mayor a 0, es que hay un usuario
	var total = db.query_result[0]["total"]
	return total > 0

# 2. Modificamos esta función para NO pedir ID (toma el único que hay)
func obtener_fecha_ultima_actividad() -> int:
	# Seleccionamos el campo del único registro que debería existir
	db.query("SELECT ultima_actividad FROM alumno LIMIT 1;")
	
	if db.query_result.is_empty():
		return 0 
	
	var fecha_str = db.query_result[0]["ultima_actividad"]
	
	if fecha_str == null or fecha_str == "":
		return 0
	
	# Parseo de fecha (String ISO a Unix Timestamp)
	var fecha_dict = Time.get_datetime_dict_from_datetime_string(fecha_str, false)
	var unix_time = Time.get_unix_time_from_datetime_dict(fecha_dict)
	return unix_time
