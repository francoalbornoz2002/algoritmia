class_name CasoPruebaMision extends Resource

@export_group("Configuración del Escenario")
# Dónde empieza el jugador en este caso (Coordenadas internas Base 0)
@export var inicio_jugador: Vector2i = Vector2i(0, 0)
@export var direccion_inicial: Vector2i = Vector2i(0, 1) # (0,1) es abajo en Godot visual, pero Lógica depende de tu Grid

# Lista de elementos a spawnear. Array de Diccionarios.
# Formato: { "tipo": ElementoTablero.Tipo.MONEDA, "pos": Vector2i(2, 5) }
@export var elementos_mapa: Array[Dictionary] = []

@export_group("Criterios de Éxito")
# Todas estas condiciones deben retornar TRUE para aprobar este caso
@export var condiciones_victoria: Array[CondicionMision] = []

# Helper para el generador automático
func agregar_elemento(tipo, pos: Vector2i):
	elementos_mapa.append({
		"tipo": tipo,
		"pos": pos
	})

# Helper para el generador automático
func agregar_condicion(cond: CondicionMision):
	condiciones_victoria.append(cond)
