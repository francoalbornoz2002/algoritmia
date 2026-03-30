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
	"numero" INTEGER NOT NULL UNIQUE,
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
	"cant_errores" INTEGER NOT NULL DEFAULT 0,
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
		
		# Cargamos/Actualizamos el catálogo de misiones desde los archivos .tres
		GestorCatalogo.actualizar_catalogo_desde_recursos()
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

## Limpia los datos de la sesión actual (alumno y progreso local).
## Mantiene las tablas de catálogo (misiones y dificultades).
func limpiar_datos_sesion() -> bool:
	print("DBManager: Cerrando sesión y limpiando tablas locales...")
	if not db.query("BEGIN TRANSACTION;"):
		return false

	var sql_limpieza = """
	DELETE FROM alumno;
	DELETE FROM misiones_completadas_local;
	DELETE FROM dificultad_alumno_local;
	DELETE FROM misiones_especiales_local;
	"""
	
	if not db.query(sql_limpieza):
		print("ERROR (DBManager): No se pudieron limpiar las tablas. ", db.error_message)
		db.query("ROLLBACK;") # Revertimos en caso de error
		return false
		
	db.query("COMMIT;")
	return true

## Devuelve un Array de Diccionarios con todas las misiones.
func obtener_misiones() -> Array:
	# Hacemos la consulta
	var success = db.query("SELECT * FROM misiones ORDER BY numero ASC;")
	
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

## Obtiene el objeto completo del alumno actual (Nombre, Apellido, etc.)
func obtener_alumno_actual() -> Dictionary:
	var exito = db.query("SELECT * FROM alumno LIMIT 1;")
	if not exito or db.query_result.is_empty():
		return {}
	return db.query_result[0]


## Devuelve un Array de Strings con los IDs de las misiones completadas.
func obtener_ids_misiones_completadas() -> Array:
	var success = db.query("SELECT id_mision FROM misiones_completadas_local;")
	
	if not success:
		return []
	
	var ids = []
	for row in db.query_result:
		ids.append(row["id_mision"])
	return ids

## Devuelve un diccionario con los totales de progreso para el modal de estadísticas.
func obtener_estadisticas_progreso() -> Dictionary:
	var stats = {
		"campana_completadas": 0,
		"campana_total": 0,
		"total_estrellas": 0,
		"total_exp": 0,
		"total_intentos": 0,
		"total_partidas": 0
	}
	
	# 1. Total misiones disponibles en la campaña
	if db.query("SELECT COUNT(*) as total FROM misiones;"):
		if not db.query_result.is_empty():
			stats["campana_total"] = int(db.query_result[0]["total"])
			
	# 2. Sumarización de Misiones Normales Completadas
	var sql_normales = "SELECT COUNT(id_mision) as cant, COALESCE(SUM(estrellas), 0) as est, COALESCE(SUM(exp), 0) as xp, COALESCE(SUM(intentos), 0) as int FROM misiones_completadas_local;"
	if db.query(sql_normales) and not db.query_result.is_empty():
		var row = db.query_result[0]
		stats["campana_completadas"] += int(row["cant"])
		stats["total_partidas"] += int(row["cant"])
		stats["total_estrellas"] += int(row["est"])
		stats["total_exp"] += int(row["xp"])
		stats["total_intentos"] += int(row["int"])

	# 3. Sumarización de Misiones Especiales Completadas
	var sql_especiales = "SELECT COUNT(id) as cant, COALESCE(SUM(estrellas), 0) as est, COALESCE(SUM(exp), 0) as xp, COALESCE(SUM(intentos), 0) as int FROM misiones_especiales_local;"
	if db.query(sql_especiales) and not db.query_result.is_empty():
		var row = db.query_result[0]
		stats["total_partidas"] += int(row["cant"])
		stats["total_estrellas"] += int(row["est"])
		stats["total_exp"] += int(row["xp"])
		stats["total_intentos"] += int(row["int"])
		
	return stats

## Devuelve un Array de diccionarios con las dificultades activas (grado distinto a Ninguno)
func obtener_dificultades_activas() -> Array:
	var sql = """
		SELECT d.nombre, d.descripcion, dal.grado 
		FROM dificultad_alumno_local dal
		JOIN dificultades d ON dal.id_dificultad = d.id
		WHERE dal.grado != 'Ninguno' AND dal.grado IS NOT NULL;
	"""
	if not db.query(sql):
		print("ERROR (DBManager): No se pudieron obtener dificultades activas. ", db.error_message)
		return []
	return db.query_result

## Escribe una misión completada en la BD local.
## Usa "INSERT OR REPLACE" para sobrescribir si ya existía (ej: la jugó offline 2 veces).
## Marca "sincronizado" como 'false' (0).
## También actualiza la 'ultima_actividad' del alumno.
func registrar_mision_local(id_mision: String, estrellas: int, exp: int, intentos: int) -> bool:
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
	var bindings_alumno = [fecha_actual]
	
	if not db.query_with_bindings(sql_alumno, bindings_alumno):
		print("ERROR (DBManager): No se pudo actualizar ultima_actividad. ", db.error_message)
		db.query("ROLLBACK;")
		return false

	# 3. Si todo salió bien, cerramos la transacción
	if not db.query("COMMIT;"):
		print("ERROR (DBManager): No se pudo hacer COMMIT. ", db.error_message)
		return false
		
	return true

## Registra una misión ESPECIAL completada (generada dinámicamente).
## Genera un UUID propio, guarda nombre/descripción y actualiza ultima_actividad.
func registrar_mision_especial_local(nombre: String, descripcion: String, estrellas: int, exp: int, intentos: int) -> bool:
	# 1. Generar ID único (UUID)
	var id_uuid = generar_uuid_v4()
	
	# 2. Obtener Fecha UTC
	var dict_utc = Time.get_datetime_dict_from_system(true)
	var fecha_actual = "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		dict_utc.year, dict_utc.month, dict_utc.day,
		dict_utc.hour, dict_utc.minute, dict_utc.second
	]
	
	# 3. Iniciar Transacción
	if not db.query("BEGIN TRANSACTION;"):
		print("ERROR (DBManager): No se pudo iniciar transacción (Especial). ", db.error_message)
		return false
	
	# 4. Insertar en la tabla de misiones especiales
	# Notar que aquí guardamos nombre y descripción porque no existen en un catálogo externo
	var sql_especial = "INSERT INTO misiones_especiales_local (id, nombre, descripcion, estrellas, exp, intentos, fecha_completado, sincronizado) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
	
	var bindings_especial = [
		id_uuid,
		nombre,
		descripcion,
		estrellas,
		exp,
		intentos,
		fecha_actual,
		false # No sincronizado aún
	]
	
	if not db.query_with_bindings(sql_especial, bindings_especial):
		print("ERROR (DBManager): Falló insert en misiones_especiales_local. ", db.error_message)
		db.query("ROLLBACK;")
		return false
	
	# 5. Actualizar última actividad del alumno (Igual que en la misión normal)
	var sql_alumno = "UPDATE alumno SET ultima_actividad = ?;"
	if not db.query_with_bindings(sql_alumno, [fecha_actual]):
		print("ERROR (DBManager): Falló actualizar ultima_actividad. ", db.error_message)
		db.query("ROLLBACK;")
		return false
		
	# 6. Commit
	if not db.query("COMMIT;"):
		print("ERROR (DBManager): Falló COMMIT (Especial). ", db.error_message)
		return false
		
	return true

# Inserta o actualiza una misión en el catálogo local desde un Recurso
func insertar_mision_catalogo(mision: DefinicionMision):
	# Usamos INSERT OR REPLACE para no fallar si ya corrimos la demo antes
	var sql = """
		INSERT OR REPLACE INTO misiones (id, numero, nombre, descripcion, dificultad_mision)
		VALUES (?, ?, ?, ?, ?);
	"""
	var exito = db.query_with_bindings(sql, [
		mision.id,
		mision.numero,
		mision.titulo,
		mision.descripcion,
		mision.dificultad_mision
	])
	
	if exito:
		print("DBManager: Misión '%s' actualizada en catálogo." % mision.titulo)
	else:
		print("DBManager ERROR: Falló actualización de misión.", db.error_message)

# --- GESTIÓN ACUMULATIVA DE DIFICULTADES ---

func registrar_errores_dificultad(id_dificultad: String, nuevos_errores: int) -> bool:
	print("DBManager: Procesando %d errores nuevos para %s" % [nuevos_errores, id_dificultad])
	
	if nuevos_errores <= 0: return true # Nada que hacer
	
	# 1. Obtener estado actual
	var query = "SELECT cant_errores, grado FROM dificultad_alumno_local WHERE id_dificultad = ?;"
	db.query_with_bindings(query, [id_dificultad])
	
	var errores_totales = nuevos_errores
	var grado_actual = "Ninguno"
	
	if not db.query_result.is_empty():
		var registro = db.query_result[0]
		errores_totales += registro["cant_errores"]
		grado_actual = registro["grado"]
	
	# 2. Calcular nuevo grado según umbrales (ACUMULATIVO)
	# Definimos los umbrales
	var umbral_bajo = 3
	var umbral_medio = 5
	var umbral_alto = 7
	
	# Excepción para LP-03 (Problemas para formular proposiciones compuestas)
	# UUID: b2002002-0000-0000-0000-000000000003
	if id_dificultad == "b2002002-0000-0000-0000-000000000003":
		umbral_bajo = 6
		umbral_medio = 10
		umbral_alto = 14
	
	var nuevo_grado = "Ninguno"
	if errores_totales >= umbral_alto:
		nuevo_grado = "Alto"
	elif errores_totales >= umbral_medio:
		nuevo_grado = "Medio"
	elif errores_totales >= umbral_bajo:
		nuevo_grado = "Bajo"
	
	# 3. Optimización: Solo actualizamos si cambiaron los errores o el grado
	# Siempre marcamos sincronizado = false (0) al actualizar
	
	var sql = """
		INSERT OR REPLACE INTO dificultad_alumno_local (id_dificultad, grado, cant_errores, sincronizado)
		VALUES (?, ?, ?, 0);
	"""
	# Nota: INSERT OR REPLACE funciona bien aquí
	
	var exito = db.query_with_bindings(sql, [id_dificultad, nuevo_grado, errores_totales])
	
	if exito:
		print("DBManager: Dificultad actualizada. Total Errores: %d. Grado: %s -> %s" % [errores_totales, grado_actual, nuevo_grado])
	else:
		print("ERROR DBManager: Falló actualización de dificultad.", db.error_message)
		
	return exito

## Reduce la cantidad de errores de TODAS las dificultades activas en un porcentaje.
## Se usa cuando el alumno obtiene 3 estrellas (Sanación).
func reducir_dificultad_global(porcentaje_reduccion: float) -> bool:
	print("DBManager: Aplicando reducción global de dificultad (Sanación) del %.2f%%..." % (porcentaje_reduccion * 100))
	
	# 1. Obtenemos dificultades que tengan errores (> 0)
	if not db.query("SELECT id_dificultad, cant_errores FROM dificultad_alumno_local WHERE cant_errores > 0;"):
		return false
		
	var dificultades = db.query_result
	if dificultades.is_empty(): return true
	
	if not db.query("BEGIN TRANSACTION;"): return false
	
	var sql = "UPDATE dificultad_alumno_local SET cant_errores = ?, grado = ?, sincronizado = 0 WHERE id_dificultad = ?;"
	
	for dif in dificultades:
		var id = dif["id_dificultad"]
		var errores_actuales = dif["cant_errores"]
		
		# Aplicar reducción (floor implícito al castear a int)
		var factor = 1.0 - porcentaje_reduccion
		var nuevos_errores = int(errores_actuales * factor)
		
		# Recalcular grado (Lógica espejo de registrar_errores_dificultad)
		var nuevo_grado = "Ninguno"
		var umbral_bajo = 3
		var umbral_medio = 5
		var umbral_alto = 7
		
		# Excepción LP-03
		if id == "b2002002-0000-0000-0000-000000000003":
			umbral_bajo = 6
			umbral_medio = 10
			umbral_alto = 14
			
		if nuevos_errores >= umbral_alto: nuevo_grado = "Alto"
		elif nuevos_errores >= umbral_medio: nuevo_grado = "Medio"
		elif nuevos_errores >= umbral_bajo: nuevo_grado = "Bajo"
		
		if not db.query_with_bindings(sql, [nuevos_errores, nuevo_grado, id]):
			db.query("ROLLBACK;")
			return false
			
	db.query("COMMIT;")
	print("DBManager: Reducción global aplicada exitosamente.")
	return true

## Actualiza las dificultades locales con datos traídos de la Web.
## Convierte el Grado (Texto) a Cantidad de Errores (Int) para mantener consistencia.
func actualizar_dificultades_desde_web(lista_dificultades: Array) -> bool:
	print("DBManager: [SYNC] Iniciando actualización en BD local. Items a procesar: %d" % lista_dificultades.size())
	
	if lista_dificultades.is_empty():
		print("DBManager: [SYNC] Lista vacía. Nada que actualizar.")
		return true
	
	if not db.query("BEGIN TRANSACTION;"): # Iniciar transacción para asegurar atomicidad
		print("DBManager: [SYNC] ERROR CRÍTICO: No se pudo iniciar transacción SQL.")
		return false
	
	# Sincronizado = 1 (true) porque viene de la fuente de verdad
	var sql = "INSERT OR REPLACE INTO dificultad_alumno_local (id_dificultad, grado, cant_errores, sincronizado) VALUES (?, ?, ?, 1);"
	
	for item in lista_dificultades:
		var id_dif_web = item["id"] # ID de dificultad desde la web
		var grado_web = item["grado"] # Grado de dificultad desde la web
		var errores_umbral = 0
		
		# Mapeo de Grado a Umbral de Errores (coherente con AnalistaDificultad)
		match grado_web:
			"Bajo": errores_umbral = 3
			"Medio": errores_umbral = 5
			"Alto": errores_umbral = 7
			_: errores_umbral = 0
		
		# 1. Obtener estado actual de la dificultad en la BD local
		var current_local_dif = db.query_with_bindings("SELECT grado, cant_errores FROM dificultad_alumno_local WHERE id_dificultad = ?;", [id_dif_web])
		
		var cant_errores_final = errores_umbral # Por defecto, usamos el umbral
		var grado_local_actual = ""
		
		if current_local_dif and not db.query_result.is_empty():
			grado_local_actual = db.query_result[0]["grado"]
			var cant_errores_local_actual = db.query_result[0]["cant_errores"]
			
			# 2. Lógica de Sincronización Refinada
			if grado_web == grado_local_actual:
				# Si el grado es el mismo, mantenemos la cantidad de errores local
				cant_errores_final = cant_errores_local_actual
				print("DBManager: [SYNC] Grado %s para %s coincide. Manteniendo errores locales: %d." % [grado_web, id_dif_web, cant_errores_final])
			else:
				# Si el grado cambió, usamos el umbral del nuevo grado
				print("DBManager: [SYNC] Grado para %s cambió de %s a %s. Estableciendo errores a umbral: %d." % [id_dif_web, grado_local_actual, grado_web, errores_umbral])
		else:
			print("DBManager: [SYNC] Dificultad %s no encontrada localmente o nueva. Estableciendo errores a umbral: %d." % [id_dif_web, errores_umbral])
		
		# 3. Insertar o reemplazar con los valores determinados
		if not db.query_with_bindings(sql, [id_dif_web, grado_web, cant_errores_final]):
			print("DBManager: [SYNC] ERROR SQL al insertar/actualizar dificultad (ID: %s): %s" % [id_dif_web, db.error_message])
			db.query("ROLLBACK;") # Revertir la transacción en caso de error
			return false
			
	db.query("COMMIT;") # Confirmar la transacción
	print("DBManager: [SYNC] Transacción completada. Dificultades actualizadas exitosamente.")
	return true

## Marca una misión como sincronizada (sincronizado = true)
func marcar_mision_sincronizada(id_mision: String) -> bool:
	print("DBManager: Marcando misión como sincronizada: ", id_mision)
	var sql = "UPDATE misiones_completadas_local SET sincronizado = true WHERE id_mision = ?;"
	var bindings = [id_mision]
	
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

# Obtiene las misiones especiales que no se han subido aún
func obtener_misiones_especiales_pendientes() -> Array:
	# Consultamos la tabla ESPECÍFICA de misiones especiales
	var exito = db.query("SELECT * FROM misiones_especiales_local WHERE sincronizado = 0;")
	if not exito:
		print("ERROR (DBManager): No se pudieron obtener misiones especiales pendientes. ", db.error_message)
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

# Marca un lote de misiones especiales como sincronizadas
func marcar_lote_misiones_especiales_sincronizadas(ids_especiales: Array) -> bool:
	if ids_especiales.is_empty(): return true
	
	if not db.query("BEGIN TRANSACTION;"): return false
	
	# OJO: En la tabla especial la clave es 'id', no 'id_mision'
	var sql = "UPDATE misiones_especiales_local SET sincronizado = true WHERE id = ?;"
	
	for id_uuid in ids_especiales:
		if not db.query_with_bindings(sql, [id_uuid]):
			db.query("ROLLBACK;")
			return false
			
	db.query("COMMIT;")
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

# --- HELPERS ---

func generar_uuid_v4() -> String:
	# Generación manual de UUID v4 estándar
	var b = []
	for i in range(16):
		b.append(randi() % 256)
	
	# Ajustar bits para la versión 4 y variante DCE 1.1
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	
	# Formatear a string hexadecimal
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
		b[0], b[1], b[2], b[3],
		b[4], b[5],
		b[6], b[7],
		b[8], b[9],
		b[10], b[11], b[12], b[13], b[14], b[15]
	]
