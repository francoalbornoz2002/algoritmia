class_name CondicionEliminarEnemigos extends CondicionMision

func _init():
	descripcion = "Eliminar todos los enemigos"

func verificar(_j, grid, _e, _l) -> bool:
	for obj in grid.obtener_todos_los_objetos():
		if obj.tipo == ElementoTablero.Tipo.ENEMIGO: return false
	return true
