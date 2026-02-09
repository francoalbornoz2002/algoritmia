class_name ElementoTablero extends Node2D

# Tipos de elementos disponibles
enum Tipo {MONEDA, LLAVE, COFRE, ENEMIGO, OBSTACULO, PUENTE}

@export var tipo: Tipo = Tipo.MONEDA
@export var sprite: Sprite2D

@export_group("Visuales")
@export var tex_moneda: Texture2D
@export var tex_llave: Texture2D
@export var tex_cofre: Texture2D
@export var tex_enemigo: Texture2D
@export var tex_obstaculo: Texture2D
@export var tex_puente_inactivo: Texture2D
@export var tex_puente_activo: Texture2D

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
	
	# Reset modulate para que la textura se vea con sus colores originales
	sprite.modulate = Color.WHITE
	
	match tipo:
		Tipo.MONEDA:
			if tex_moneda: sprite.texture = tex_moneda
			else: sprite.modulate = Color.YELLOW
		Tipo.LLAVE:
			if tex_llave: sprite.texture = tex_llave
			else: sprite.modulate = Color.ORANGE
		Tipo.COFRE:
			if tex_cofre: sprite.texture = tex_cofre
			else: sprite.modulate = Color.BROWN
		Tipo.ENEMIGO:
			if tex_enemigo: sprite.texture = tex_enemigo
			else: sprite.modulate = Color.RED
		Tipo.OBSTACULO:
			if tex_obstaculo: sprite.texture = tex_obstaculo
			else: sprite.modulate = Color.BLACK
		Tipo.PUENTE:
			if esta_activo:
				if tex_puente_activo: sprite.texture = tex_puente_activo
				else: sprite.modulate = Color.BLUE.lerp(Color.WHITE, 0.7)
			else:
				if tex_puente_inactivo: sprite.texture = tex_puente_inactivo
				else: sprite.modulate = Color.BLUE

func activar():
	if tipo == Tipo.PUENTE:
		esta_activo = true
		_actualizar_visual()

# Función para "consumir" el objeto (ej: recoger moneda)
func recoger():
	# Animación simple de desaparecer
	var tween = create_tween()
	tween.tween_property(self , "scale", Vector2.ZERO, 0.2)
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
