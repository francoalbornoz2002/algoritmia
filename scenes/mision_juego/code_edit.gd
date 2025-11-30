extends CodeEdit

func _ready():
	
	# --- CONFIGURAR EL RESALTADOR (HIGHLIGHTER) ---
	var highlighter = CodeHighlighter.new()
	
	# 1. Palabras Reservadas (Estructura) - Color Púrpura/Rosa
	var color_estructura = Color("ff7085") # Un rosado tipo GDScript
	highlighter.add_keyword_color("Inicio", color_estructura)
	highlighter.add_keyword_color("Fin", color_estructura)
	highlighter.add_keyword_color("Si", color_estructura)
	highlighter.add_keyword_color("Sino", color_estructura)
	highlighter.add_keyword_color("entonces", color_estructura)
	highlighter.add_keyword_color("Mientras", color_estructura)
	highlighter.add_keyword_color("hacer", color_estructura)
	highlighter.add_keyword_color("Repetir", color_estructura)
	highlighter.add_keyword_color("var", color_estructura)
	highlighter.add_keyword_color("proceso", color_estructura)
	
	# 2. Para tipos
	var color_tipos = Color("008650ff")
	highlighter.add_keyword_color("entero", color_tipos)
	highlighter.add_keyword_color("real", color_tipos)

	# 3. Funciones/Instrucciones (Acciones) - Color Azul/Celeste
	var color_accion = Color("42ffc2") # Un cyan brillante
	highlighter.add_keyword_color("avanzar", color_accion)
	highlighter.add_keyword_color("derecha", color_accion)
	highlighter.add_keyword_color("saltar", color_accion)
	highlighter.add_keyword_color("atacar", color_accion)
	highlighter.add_keyword_color("recogerMoneda", color_accion)
	highlighter.add_keyword_color("recogerLlave", color_accion)
	highlighter.add_keyword_color("abrirCofre", color_accion)
	highlighter.add_keyword_color("activarPuente", color_accion)
	
	# 3. Sensores (Retornan valor) - Color Naranja
	var color_sensor = Color("ffbd42")
	highlighter.add_keyword_color("hayMoneda", color_sensor)
	highlighter.add_keyword_color("hayLlave", color_sensor)
	highlighter.add_keyword_color("hayCofre", color_sensor)
	highlighter.add_keyword_color("hayEnemigo", color_sensor)
	highlighter.add_keyword_color("hayObstaculo", color_sensor)
	highlighter.add_keyword_color("hayPuente", color_sensor)

	# 4. Comentarios - Color Gris
	highlighter.add_color_region("#", "", Color("6e6e6e"), true) # True = hasta fin de linea
	
	# Aplicamos el resaltador al editor
	syntax_highlighter = highlighter

	# Texto por defecto (Placeholder)
	text = "Inicio\n\t# Escribe tu algoritmo aquí\n\t\nFin"
