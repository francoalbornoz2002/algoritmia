class_name ElementoTablero extends Node2D

# Tipos de elementos disponibles
enum Tipo { MONEDA, LLAVE, COFRE, ENEMIGO, OBSTACULO, PUENTE }

@export var tipo: Tipo = Tipo.MONEDA
@export var sprite: Sprite2D

var pos_grid: Vector2i
var esta_activo: bool = false # Solo relevante para PUENTE

func _ready():
	_actualizar_visual()

func configurar(nuevo_tipo: Tipo, nueva_pos_grid: Vector2i):
	tipo = nuevo_tipo
	pos_grid = nueva_pos_grid
	position = GridManager.grid_to_world(pos_grid)
	
	# Si es un puente, comienza INACTIVO (por defecto)
	if tipo == Tipo.PUENTE:
		esta_activo = false 
	
	_actualizar_visual()

func _actualizar_visual():
	if not sprite: return
	
	# Colores temporales (Whiteboxing) para diferenciar
	match tipo:
		Tipo.MONEDA:
			sprite.modulate = Color.YELLOW # Amarillo
		Tipo.LLAVE:
			sprite.modulate = Color.ORANGE # Naranja
		Tipo.COFRE:
			sprite.modulate = Color.BROWN # Marrón
		Tipo.ENEMIGO:
			sprite.modulate = Color.RED # Rojo
		Tipo.OBSTACULO:
			sprite.modulate = Color.BLACK # Negro
		Tipo.PUENTE:
			# Si es un puente, cambia el color según el estado
			sprite.modulate = Color.BLUE.lerp(Color.WHITE, 0.7) if esta_activo else Color.BLUE # Azul claro si activo, azul oscuro si inactivo

func activar():
	if tipo == Tipo.PUENTE:
		esta_activo = true
		_actualizar_visual()

# Función para "consumir" el objeto (ej: recoger moneda)
func recoger():
	# Animación simple de desaparecer
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)

# Función para abrir cofre (cambia visualmente o desaparece)
func abrir_cofre():
	# Por ahora lo desaparecemos, luego pondremos sprite de cofre abierto
	recoger()

# --- NUEVA FUNCIÓN DE TRADUCCIÓN ---
static func obtener_nombre_tipo(valor: int) -> String:
	match valor:
		Tipo.MONEDA: return "MONEDA"
		Tipo.LLAVE: return "LLAVE"
		Tipo.COFRE: return "COFRE"
		Tipo.ENEMIGO: return "ENEMIGO"
		Tipo.OBSTACULO: return "OBSTACULO"
		Tipo.PUENTE: return "PUENTE"
		_: return "DESCONOCIDO"
