class_name CondicionLlegarA extends CondicionMision

@export var objetivo: Vector2i
	
func _init(pos: Vector2i = Vector2i.ZERO):
	objetivo = pos
	descripcion = "Llegar a posición interna " + str(pos)

func verificar(j, _g, _e, _l) -> bool:
	return j.posicion_actual == objetivo
