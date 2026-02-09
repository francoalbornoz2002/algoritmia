extends Control

@export var label_usuario: Label

func _ready():
	# Verificamos inactividad al iniciar el menú
	_verificar_inactividad()
	_mostrar_datos_alumno()

func _mostrar_datos_alumno():
	var alumno = DatabaseManager.obtener_alumno_actual()
	if not alumno.is_empty():
		var texto = "Alumno: %s %s" % [alumno["nombre"], alumno["apellido"]]
		if label_usuario: label_usuario.text = texto
	else:
		if label_usuario: label_usuario.text = "Alumno: Invitado"

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
	get_tree().change_scene_to_file("res://scenes/mision_juego/mision_juego.tscn")

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/selector_misiones/selector_misiones.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()
