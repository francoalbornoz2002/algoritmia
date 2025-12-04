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











func _on_registrar_mision_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/registrar_mision/registrar_mision.tscn")

func _on_registrar_dificultad_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/registrar_dificultad/registrar_dificultad.tscn")

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/selector_misiones/selector_misiones.tscn")
