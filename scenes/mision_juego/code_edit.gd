extends CodeEdit

func _ready():
	# --- 1. CONFIGURACIÓN VISUAL DEL EDITOR (FONDO CLARO) ---
	
	# Color del texto base (Gris casi negro)
	add_theme_color_override("font_color", Color("24292e"))
	# Color de la línea actual (Un sombreado muy suave para resaltar dónde escribes)
	add_theme_color_override("current_line_color", Color("00000064"))
	
	# --- 2. CONFIGURAR EL RESALTADOR (HIGHLIGHTER) ---
	var highlighter = CodeHighlighter.new()
	
	# Colores Dinámicos Globales
	highlighter.symbol_color = Color("d73a49") # Rojo vinotinto para: = < > ! :
	highlighter.number_color = Color("005cc5") # Azul intenso para los números
	highlighter.member_variable_color = Color("24292e") # Variables en el color base
	
	# A. Palabras Reservadas (Estructura) - Púrpura Profundo
	var color_estructura = Color("502b90ff")
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
	
	# B. Para tipos de datos - Verde Bosque
	var color_tipos = Color("22863a")
	highlighter.add_keyword_color("entero", color_tipos)
	highlighter.add_keyword_color("real", color_tipos)

	# C. Funciones/Instrucciones (Acciones) - Azul Marino
	var color_accion = Color("0050a1")
	highlighter.add_keyword_color("avanzar", color_accion)
	highlighter.add_keyword_color("derecha", color_accion)
	highlighter.add_keyword_color("saltar", color_accion)
	highlighter.add_keyword_color("atacar", color_accion)
	highlighter.add_keyword_color("recogerMoneda", color_accion)
	highlighter.add_keyword_color("recogerLlave", color_accion)
	highlighter.add_keyword_color("abrirCofre", color_accion)
	highlighter.add_keyword_color("activarPuente", color_accion)
	
	# D. Sensores (Retornan valor) - Marrón/Ocre Quemado
	var color_sensor = Color("a04100")
	highlighter.add_keyword_color("hayMoneda", color_sensor)
	highlighter.add_keyword_color("hayLlave", color_sensor)
	highlighter.add_keyword_color("hayCofre", color_sensor)
	highlighter.add_keyword_color("hayEnemigo", color_sensor)
	highlighter.add_keyword_color("hayObstaculo", color_sensor)
	highlighter.add_keyword_color("hayPuente", color_sensor)
	highlighter.add_keyword_color("posSendero", color_sensor)
	highlighter.add_keyword_color("posValle", color_sensor)
	highlighter.add_keyword_color("tengoMoneda", color_sensor)
	highlighter.add_keyword_color("tengoLlave", color_sensor)

	# E. Comentarios - Gris Medio
	highlighter.add_color_region("#", "", Color("6a737d"), true)
	
	# Aplicamos el resaltador al editor
	syntax_highlighter = highlighter

	# Texto por defecto
	text = "Inicio\n\t# Escribe tu algoritmo aquí\n\tvar puntos = 10\n\t\n\tSi hayMoneda entonces\n\t\trecogerMoneda\n\tFin\nFin"
