class_name CondicionVariableTieneValor extends CondicionMision

@export var nombre_var: String
@export var valor_esperado: int

func _init(nombre = "", valor = 0):
	nombre_var = nombre
	valor_esperado = valor
	descripcion = "Variable '" + nombre + "' debe valer " + str(valor)
	
func verificar(_j, _g, ejecutor, _l) -> bool:
	var valor_real = ejecutor.obtener_valor_variable(nombre_var)
	if valor_real == null: return false # No existe o es null
	return valor_real == valor_esperado
