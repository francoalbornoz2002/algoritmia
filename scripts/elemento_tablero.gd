class_name ElementoTablero extends Node2D

# Tipos de elementos disponibles
enum Tipo {MONEDA, LLAVE, COFRE, ENEMIGO, OBSTACULO, PUENTE}

@export var tipo: Tipo = Tipo.MONEDA
@export var sprite: Sprite2D
@export var anim_player: AnimationPlayer

@export_group("Visuales")
@export var tex_moneda: Texture2D
@export var tex_llave: Texture2D
@export var tex_cofre: Texture2D
@export var tex_enemigo: Texture2D
@export var tex_obstaculo: Texture2D
@export var tex_puente_inactivo: Texture2D
@export var tex_puente_activo: Texture2D

@export var cantidad_variantes_enemigos: int = 2

var pos_grid: Vector2i
var esta_activo: bool = false # Solo relevante para PUENTE
var indice_variante_actual: int = 0
var semilla_visual: int = 0

func _ready():
	if not anim_player: anim_player = get_node_or_null("AnimationPlayer")
	_actualizar_visual()

func configurar(nuevo_tipo: Tipo, nueva_pos_grid: Vector2i, semilla: int = 0):
	tipo = nuevo_tipo
	pos_grid = nueva_pos_grid
	semilla_visual = semilla
	position = GridManager.grid_to_world(pos_grid)
	
	# Si es un puente, comienza INACTIVO (por defecto)
	if tipo == Tipo.PUENTE:
		esta_activo = false
	
	_actualizar_visual()

func _actualizar_visual():
	if not sprite: return
	
	# Reset modulate para que la textura se vea con sus colores originales
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	# Desactivamos region por defecto para que funcionen las animaciones basadas en frames (Enemigos, Cofres, Llaves)
	sprite.region_enabled = false
	
	if anim_player and tipo != Tipo.ENEMIGO: anim_player.stop()
	
	match tipo:
		Tipo.MONEDA:
			sprite.region_enabled = true
			if anim_player and anim_player.has_animation("moneda_idle"):
				anim_player.play("moneda_idle")
			elif tex_moneda: sprite.texture = tex_moneda
			else: sprite.modulate = Color.YELLOW
		Tipo.LLAVE:
			sprite.scale = Vector2(0.7, 0.7)
			if anim_player and anim_player.has_animation("llave_idle"):
				anim_player.play("llave_idle")
			elif tex_llave: sprite.texture = tex_llave
			else: sprite.modulate = Color.ORANGE
		Tipo.COFRE:
			sprite.scale = Vector2(1.2, 1.2)
			if anim_player and anim_player.has_animation("cofre_cerrado"):
				anim_player.play("cofre_cerrado")
			elif tex_cofre: sprite.texture = tex_cofre
			else: sprite.modulate = Color.BROWN
		Tipo.ENEMIGO:
			if anim_player:
				# Elegir variante determinista basada en la posición (para que no cambie al reiniciar)
				var rng = RandomNumberGenerator.new()
				rng.seed = semilla_visual + (pos_grid.x * 100) + pos_grid.y
				indice_variante_actual = rng.randi() % cantidad_variantes_enemigos
				var nombre_anim = "enemigo_" + str(indice_variante_actual) + "_idle"
				if anim_player.has_animation(nombre_anim):
					anim_player.play(nombre_anim)
				else:
					if tex_enemigo: sprite.texture = tex_enemigo
					else: sprite.modulate = Color.RED
			elif tex_enemigo: sprite.texture = tex_enemigo
			else: sprite.modulate = Color.RED
		Tipo.OBSTACULO:
			if tex_obstaculo: sprite.texture = tex_obstaculo
			else: sprite.modulate = Color.BLACK
		Tipo.PUENTE:
			sprite.scale = Vector2(0.8, 0.8)
			if esta_activo:
				if tex_puente_activo: sprite.texture = tex_puente_activo
				else: sprite.modulate = Color.BLUE.lerp(Color.WHITE, 0.7)
			else:
				if tex_puente_inactivo:
					sprite.texture = tex_puente_inactivo
					# Tinte rojizo para indicar que está inactivo
					sprite.modulate = Color(1, 0.5, 0.5)
				else: sprite.modulate = Color.BLUE

func activar():
	if tipo == Tipo.PUENTE:
		esta_activo = true
		_actualizar_visual()

func reproducir_ataque():
	if tipo == Tipo.ENEMIGO and anim_player:
		var nombre_anim = "enemigo_" + str(indice_variante_actual) + "_attack"
		if anim_player.has_animation(nombre_anim):
			anim_player.play(nombre_anim)

# Función para "consumir" el objeto (ej: recoger moneda)
func recoger():
	# Animación simple de desaparecer
	var tween = create_tween()
	tween.tween_property(self , "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)

# Función para abrir cofre (cambia visualmente o desaparece)
func abrir_cofre():
	if anim_player and anim_player.has_animation("cofre_abrir"):
		anim_player.play("cofre_abrir")
	else:
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
