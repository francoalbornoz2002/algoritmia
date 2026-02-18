class_name CondicionOutputContiene extends CondicionMision

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
