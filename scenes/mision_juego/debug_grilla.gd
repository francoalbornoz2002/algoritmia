extends Node2D

func _ready():
	# Forzamos el redibujado al iniciar
	queue_redraw()

func _draw():
	# Color de las líneas (Blanco semi-transparente)
	var color_linea = Color(1, 1, 1, 0.3)
	
	# Usamos las constantes del GridManager
	var ancho_total = GridManager.COLUMNAS_MAX * GridManager.TAMANO_CELDA
	var alto_total = GridManager.FILAS_MAX * GridManager.TAMANO_CELDA
	
	# 1. Líneas Verticales
	for x in range(GridManager.COLUMNAS_MAX + 1):
		var pos_x = x * GridManager.TAMANO_CELDA
		draw_line(Vector2(pos_x, 0), Vector2(pos_x, alto_total), color_linea, 1.0)
		
	# 2. Líneas Horizontales
	for y in range(GridManager.FILAS_MAX + 1):
		var pos_y = y * GridManager.TAMANO_CELDA
		draw_line(Vector2(0, pos_y), Vector2(ancho_total, pos_y), color_linea, 1.0)
