class_name GridManager extends Node

# --- CONFIGURACIÓN ---
const TAMANO_CELDA = 32 # Actualizado a 32px
const COLUMNAS_MAX = 25
const FILAS_MAX = 25

# --- MATRIZ DE DATOS ---
# Diccionario para guardar qué objeto hay en qué celda.
# Clave: Vector2i (celda), Valor: Referencia al nodo ElementoTablero
static var _grid_contenidos = {}

# --- FUNCIONES DE REGISTRO ---

static func limpiar_datos():
	_grid_contenidos.clear()

static func registrar_objeto(celda: Vector2i, objeto: Node2D):
	if es_celda_valida(celda):
		_grid_contenidos[celda] = objeto
	else:
		print("Error: Intentando registrar objeto fuera del mapa ", celda)

static func quitar_objeto(celda: Vector2i):
	if _grid_contenidos.has(celda):
		_grid_contenidos.erase(celda)

static func obtener_objeto_en_celda(celda: Vector2i) -> Node2D:
	if _grid_contenidos.has(celda):
		return _grid_contenidos[celda]
	return null

static func obtener_todos_los_objetos() -> Array:
	# Devuelve una lista con todos los nodos ElementoTablero activos en el mapa
	return _grid_contenidos.values()

# Convierte coordenada de Grilla (ej: 1,1) a Pixeles (ej: 48, 48)
# Nota: Devuelve el CENTRO de la celda para que el sprite quede centrado.
static func grid_to_world(celda: Vector2i) -> Vector2:
	# Eje X: Igual que antes (Izquierda a Derecha)
	var x = (celda.x * TAMANO_CELDA) + (TAMANO_CELDA / 2.0)
	
	# Eje Y: INVERTIDO. 
	# La fila lógica 0 debe dibujarse en la fila visual 24 (FILAS_MAX - 1)
	var fila_visual = (FILAS_MAX - 1) - celda.y
	
	var y = (fila_visual * TAMANO_CELDA) + (TAMANO_CELDA / 2.0)
	
	return Vector2(x, y)

# Convierte Pixeles a Grilla (útil para clics del mouse)
static func world_to_grid(pos_world: Vector2) -> Vector2i:
	var x = int(floor(pos_world.x / TAMANO_CELDA))
	
	# Invertimos también la lectura
	var fila_visual = int(floor(pos_world.y / TAMANO_CELDA))
	var y = (FILAS_MAX - 1) - fila_visual
	
	return Vector2i(x, y)

static func es_celda_valida(celda: Vector2i) -> bool:
	return celda.x >= 0 and celda.x < COLUMNAS_MAX and celda.y >= 0 and celda.y < FILAS_MAX
