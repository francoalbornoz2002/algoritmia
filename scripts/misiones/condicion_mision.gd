class_name CondicionMision extends Resource

# Texto descriptivo para debug o UI
@export var descripcion: String = "Condición Genérica"

# Función base que debe sobreescribirse
# Recibe el estado final para evaluar si se cumplió
func verificar(jugador: JugadorGrid, grid, consola_logs: Array) -> bool:
	return false

# --- SUBCLASES ---

# 1. Condición: Llegar a una posición específica (Base 0 interna)
class LlegarA extends CondicionMision:
	@export var objetivo: Vector2i
		
	func _init(pos: Vector2i = Vector2i.ZERO):
		objetivo = pos
		descripcion = "Llegar a posición interna " + str(pos)
	
	func verificar(jugador: JugadorGrid, _grid, _logs) -> bool:
		return jugador.pos_grid_actual == objetivo

# 2. Condición: Tener items en inventario
class Recolectar extends CondicionMision:
	@export var tipo: String = "monedas" # "monedas" o "llaves"
	@export var cantidad: int = 1
	
	func _init(t: String = "monedas", cant: int = 1):
		tipo = t
		cantidad = cant
		descripcion = "Tener " + str(cant) + " " + tipo

	func verificar(jugador: JugadorGrid, _grid, _logs) -> bool:
		return jugador.inventario.get(tipo, 0) >= cantidad

# 3. Condición: Haber eliminado enemigos (Mapa limpio)
class EliminarEnemigos extends CondicionMision:
	func _init():
		descripcion = "Eliminar todos los enemigos"

	func verificar(_jugador, grid, _logs) -> bool:
		# 'grid' es la clase estática GridManager
		var objetos = grid.obtener_todos_los_objetos() 
		for obj in objetos:
			if obj.tipo == ElementoTablero.Tipo.ENEMIGO:
				return false # Aún queda uno vivo
		return true

# 4. Condición: Output en Consola (Para "imprime el resultado")
class OutputContiene extends CondicionMision:
	@export var texto_esperado: String
	
	func _init(txt: String = ""):
		texto_esperado = txt
		descripcion = "Imprimir en consola: " + txt

	func verificar(_jugador, _grid, logs: Array) -> bool:
		for linea in logs:
			# Buscamos si el texto esperado está contenido en alguna línea del log
			if texto_esperado in linea:
				return true
		return false
