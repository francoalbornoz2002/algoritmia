class_name CondicionRecolectar extends CondicionMision

@export var tipo: String = "monedas" # "monedas" o "llaves"
@export var cantidad: int = 1

func _init(t: String = "monedas", cant: int = 1):
	tipo = t
	cantidad = cant
	descripcion = "Tener " + str(cant) + " " + tipo

func verificar(j, _g, _e, _l) -> bool:
	return j.inventario.get(tipo, 0) >= cantidad
