class_name GridManager extends Node

# --- CONFIGURACIÓN ---
const TAMANO_CELDA = 32 # Actualizado a 32px
const COLUMNAS_MAX = 25
const FILAS_MAX = 25

# --- MATRIZ DE DATOS ---
# Diccionario para guardar qué objeto hay en qué celda.
# Clave: Vector2i (celda), Valor: Array[ElementoTablero]
static var _grid_contenidos = {}

# --- FUNCIONES DE REGISTRO ---

static func limpiar_datos():
	_grid_contenidos.clear()

static func registrar_objeto(celda: Vector2i, objeto: Node2D):
	if not es_celda_valida(celda):
		print("Error: Intentando registrar objeto fuera del mapa ", celda)
		return

	if not _grid_contenidos.has(celda):
		_grid_contenidos[celda] = []
	
	var lista = _grid_contenidos[celda]
	
	# 1. Validar límite (Máximo 2 objetos)
	if lista.size() >= 2:
		print("Error: Celda llena en ", celda)
		return

	# 2. Validar combinaciones permitidas si ya hay un objeto
	if not lista.is_empty():
		var existente = lista[0]
		if not _es_combinacion_valida(existente.tipo, objeto.tipo):
			print("Error: Combinación de objetos no válida en ", celda)
			return
	
	lista.append(objeto)

static func _es_combinacion_valida(t1, t2) -> bool:
	var T = ElementoTablero.Tipo
	var par = [t1, t2]
	par.sort() # Ordenamos para no preocuparnos por el orden (ej: [0, 1] es igual a [1, 0])
	
	# Combinaciones permitidas explícitamente
	if par == [T.MONEDA, T.LLAVE]: return true
	if par == [T.LLAVE, T.COFRE]: return true
	if par == [T.COFRE, T.ENEMIGO]: return true
	if par == [T.MONEDA, T.ENEMIGO]: return true
	if par == [T.LLAVE, T.ENEMIGO]: return true
	if par == [T.MONEDA, T.MONEDA]: return true
	if par == [T.LLAVE, T.LLAVE]: return true
	if par == [T.COFRE, T.COFRE]: return true
	
	return false

static func quitar_objeto(celda: Vector2i, objeto: Node2D = null):
	if _grid_contenidos.has(celda):
		if objeto:
			_grid_contenidos[celda].erase(objeto)
			# Si la lista queda vacía, borramos la entrada del diccionario
			if _grid_contenidos[celda].is_empty():
				_grid_contenidos.erase(celda)
		else:
			# Si no se especifica objeto, borramos todo (comportamiento legacy/limpieza)
			_grid_contenidos.erase(celda)

static func obtener_objeto_en_celda(celda: Vector2i) -> Node2D:
	# Retorna el primer objeto encontrado (Legacy support)
	if _grid_contenidos.has(celda) and not _grid_contenidos[celda].is_empty():
		return _grid_contenidos[celda][0]
	return null

static func obtener_objetos_en_celda(celda: Vector2i) -> Array:
	if _grid_contenidos.has(celda):
		return _grid_contenidos[celda]
	return []

static func buscar_objeto_por_tipo(celda: Vector2i, tipo_buscado) -> Node2D:
	if _grid_contenidos.has(celda):
		for obj in _grid_contenidos[celda]:
			if obj.tipo == tipo_buscado:
				return obj
	return null

static func obtener_todos_los_objetos() -> Array:
	# Devuelve una lista con todos los nodos ElementoTablero activos en el mapa
	var todos = []
	for lista in _grid_contenidos.values():
		todos.append_array(lista)
	return todos

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
