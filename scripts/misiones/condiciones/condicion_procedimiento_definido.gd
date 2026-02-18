class_name CondicionProcedimientoDefinido extends CondicionMision

@export var nombre_proc: String

func _init(nombre = ""):
	nombre_proc = nombre
	descripcion = "Definir procedimiento '" + nombre + "'"
	
func verificar(_j, _g, ejecutor, _l) -> bool:
	# Buscamos en la lista de funciones definidas
	return nombre_proc in ejecutor.obtener_funciones_definidas()
