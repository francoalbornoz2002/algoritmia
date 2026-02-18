class_name ElementoMision extends Resource

# Definimos el Enum localmente para romper la dependencia cíclica con ElementoTablero.
# Esto soluciona el error de carga en el editor.
enum Tipo {
	MONEDA,
	LLAVE,
	COFRE,
	ENEMIGO,
	OBSTACULO,
	PUENTE
}

@export var tipo: Tipo
@export var pos: Vector2i

func _init(p_tipo = Tipo.MONEDA, p_pos = Vector2i.ZERO):
	tipo = p_tipo
	pos = p_pos
