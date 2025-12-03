class_name CondicionMision extends Resource

# Texto descriptivo para debug o UI
@export var descripcion: String = "Condición Genérica"

# Función base que debe sobreescribirse
func verificar(jugador: JugadorGrid, grid, ejecutor: EjecutorAlgoritmo, consola_logs: Array) -> bool:
	return false

# --- SUBCLASES ---

# 1. Condición: Llegar a una posición específica (Base 0 interna)
class LlegarA extends CondicionMision:
	@export var objetivo: Vector2i
		
	func _init(pos: Vector2i = Vector2i.ZERO):
		objetivo = pos
		descripcion = "Llegar a posición interna " + str(pos)
	
	func verificar(j, _g, _e, _l) -> bool:
		return j.pos_grid_actual == objetivo

# 2. Condición: Tener items en inventario
class Recolectar extends CondicionMision:
	@export var tipo: String = "monedas" # "monedas" o "llaves"
	@export var cantidad: int = 1
	
	func _init(t: String = "monedas", cant: int = 1):
		tipo = t
		cantidad = cant
		descripcion = "Tener " + str(cant) + " " + tipo
	
	func verificar(j, _g, _e, _l) -> bool:
		return j.inventario.get(tipo, 0) >= cantidad

# 3. Condición: Haber eliminado enemigos (Mapa limpio)
class EliminarEnemigos extends CondicionMision:
	func _init():
		descripcion = "Eliminar todos los enemigos"

	func verificar(_j, grid, _e, _l) -> bool:
		for obj in grid.obtener_todos_los_objetos():
			if obj.tipo == ElementoTablero.Tipo.ENEMIGO: return false
		return true

# 4. Condición: Output en Consola (Para "imprime el resultado")
class OutputContiene extends CondicionMision:
	@export var texto_esperado: String
	
	func _init(txt: String = ""):
		texto_esperado = txt
		descripcion = "Imprimir en consola: " + txt

	func verificar(_j, _g, _e, logs) -> bool:
		for linea in logs:
			# Buscamos si el texto esperado está contenido en alguna línea del log
			if texto_esperado in linea:
				return true
		return false

# 5. VariableTieneValor: Evalúa si una variable existe y vale X
class VariableTieneValor extends CondicionMision:
	@export var nombre_var: String
	@export var valor_esperado: int
	
	func _init(nombre="", valor=0):
		nombre_var = nombre
		valor_esperado = valor
		descripcion = "Variable '" + nombre + "' debe valer " + str(valor)
		
	func verificar(_j, _g, ejecutor: EjecutorAlgoritmo, _l) -> bool:
		var valor_real = ejecutor.obtener_valor_variable(nombre_var)
		if valor_real == null: return false # No existe o es null
		return valor_real == valor_esperado

# 6. ProcedimientoDefinido: Evalúa si el alumno creó una función específica
class ProcedimientoDefinido extends CondicionMision:
	@export var nombre_proc: String
	
	func _init(nombre=""):
		nombre_proc = nombre
		descripcion = "Definir procedimiento '" + nombre + "'"
		
	func verificar(_j, _g, ejecutor: EjecutorAlgoritmo, _l) -> bool:
		# Buscamos en la lista de funciones definidas
		return nombre_proc in ejecutor.obtener_funciones_definidas()

# 7. VisitoZona: Verifica si el jugador pisó una zona (Ruta)
# Para esto necesitamos que el Jugador guarde historial de pasos.
# (Pendiente: Actualizar JugadorGrid si queremos usar esto estrictamente)
