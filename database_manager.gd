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
	PRIMARY KEY("id")
);

CREATE TABLE IF NOT EXISTS "misiones" (
	"id" TEXT NOT NULL UNIQUE,
	"nombre" TEXT NOT NULL,
	"descripcion" TEXT NOT NULL,
	"dificultad_mision" TEXT NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE IF NOT EXISTS "misiones_especiales_local" (
	"id" TEXT NOT NULL UNIQUE,
	"estrellas" INTEGER NOT NULL,
	"exp" INTEGER NOT NULL,
	"intentos" INTEGER NOT NULL,
	"fecha_completado" TEXT NOT NULL,
	"sincronizado" BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY("id")
);

CREATE TABLE IF NOT EXISTS "misiones_completadas_local" (
	"id_mision" TEXT NOT NULL UNIQUE,
	"estrellas" INTEGER NOT NULL,
	"exp" INTEGER NOT NULL,
	"intentos" INTEGER NOT NULL,
	"fecha_completado" TEXT NOT NULL,
	"sincronizado" BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY("id_mision"),
	FOREIGN KEY ("id_mision") REFERENCES "misiones"("id")
	ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE IF NOT EXISTS "dificultades" (
	"id" TEXT NOT NULL UNIQUE,
	"nombre" TEXT NOT NULL,
	"descripcion" TEXT NOT NULL,
	"tema" TEXT NOT NULL,
	PRIMARY KEY("id")
);

CREATE TABLE IF NOT EXISTS "dificultad_alumno_local" (
	"id_dificultad" TEXT NOT NULL UNIQUE,
	"grado" TEXT NOT NULL,
	"sincronizado" BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY("id_dificultad"),
	FOREIGN KEY ("id_dificultad") REFERENCES "dificultades"("id")
	ON UPDATE NO ACTION ON DELETE NO ACTION
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
