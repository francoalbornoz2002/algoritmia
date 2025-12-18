extends Control

func _ready():
	# Verificamos inactividad al iniciar el menú
	_verificar_inactividad()

func _verificar_inactividad():
	# 1. Obtenemos el timestamp de la última vez que jugó (desde la BD local)
	var ultima_vez = DatabaseManager.obtener_fecha_ultima_actividad()
	
	# Si devuelve 0, es la primera vez que juega, así que no aplicamos lógica de inactividad
	if ultima_vez == 0:
		return

	# 2. Obtenemos el tiempo actual (Unix Timestamp en segundos)
	var ahora = Time.get_unix_time_from_system()
	var diferencia = ahora - ultima_vez
	
	# 3. Verificamos si pasaron 48 horas
	# 48 horas * 60 minutos * 60 segundos = 172800 segundos
	if diferencia > 172800:
		# ¡Bingo! Usuario inactivo detectado.
		_ofrecer_mision_especial()

func _ofrecer_mision_especial():
	print("--- Detectada inactividad > 48hs. Ofreciendo misión especial ---")
	
	# Creamos un diálogo de confirmación en tiempo de ejecución
	var confirm = ConfirmationDialog.new()
	confirm.title = "¡Bienvenido de vuelta!"
	confirm.dialog_text = "¡Han pasado más de 48hs desde tu última misión!\n\nEl sistema te ofrece una Misión Especial de Retorno.\nSi la aceptas, ganarás DOBLE EXP y ESTRELLAS.\n\n¿Aceptas el desafío?"
	confirm.get_ok_button().text = "¡Sí, aceptar!"
	confirm.get_cancel_button().text = "No, gracias"
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	
	# Conectamos la señal de "Aceptar"
	confirm.confirmed.connect(_iniciar_mision_especial)
	
	add_child(confirm)
	confirm.popup()

func _iniciar_mision_especial():
	# 1. Generamos la misión especial
	var mision_especial = GeneradorMisiones.generar_mision_especial_inactividad()
	
	# 2. La guardamos en nuestra "mochila" global
	GameData.mision_seleccionada = mision_especial
	
	print("Iniciando misión especial: ", mision_especial.titulo)
	
	# 3. Cambiamos a la escena de juego
	# Asegúrate de que la ruta sea correcta según tu estructura de carpetas
	get_tree().change_scene_to_file("res://scenes/mision_juego/mision_juego.tscn")

func _on_jugar_pressed() -> void:
	print("--- Generando Misión Compleja para Demo ---")
	
	# 1. Usamos el generador existente (Dificultad Media o Dificil)
	var mision_demo = GeneradorMisiones.generar_mision_compleja(GeneradorMisiones.DIFICULTAD_MEDIA)
	
	# 2. LA FORZAMOS a ser una Misión Normal con ID Fijo
	# Esto es vital para que puedas crearla en la Web y la sincronización funcione.
	mision_demo.id = "11111111-1111-1111-1111-111111111111" 
	mision_demo.titulo = "Misión Generada: Demo Video"
	mision_demo.es_mision_especial = false 
	
	# 3. Inyectar en el catálogo local (Tabla 'misiones')
	# Requerido para evitar el error de Foreign Key al guardar el progreso
	DatabaseManager.insertar_mision_demo_catalogo(mision_demo)
	
	# 4. Iniciar Juego
	GameData.mision_seleccionada = mision_demo
	get_tree().change_scene_to_file("res://scenes/mision_juego/mision_juego.tscn")
