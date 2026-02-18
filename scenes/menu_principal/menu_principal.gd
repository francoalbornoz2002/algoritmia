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
	# HARDCODE: Forzamos la misión especial para pruebas
	_ofrecer_mision_especial()

	## 1. Obtenemos el timestamp de la última vez que jugó (desde la BD local)
	#var ultima_vez = DatabaseManager.obtener_fecha_ultima_actividad()
	#
	## Si devuelve 0, es la primera vez que juega, así que no aplicamos lógica de inactividad
	#if ultima_vez == 0:
		#return
	#
	## 2. Obtenemos el tiempo actual (Unix Timestamp en segundos)
	#var ahora = Time.get_unix_time_from_system()
	#var diferencia = ahora - ultima_vez
	#
	## 3. Verificamos si pasaron 48 horas
	## 48 horas * 60 minutos * 60 segundos = 172800 segundos
	#if diferencia > 172800:
		## ¡Bingo! Usuario inactivo detectado.
		#_ofrecer_mision_especial()

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
	# --- HARDCODE: Misión Especial de Prueba ---
	var mision = DefinicionMision.new()
	mision.id = DatabaseManager.generar_uuid_v4()
	mision.titulo = "Misión de Retorno al Juego"
	mision.descripcion = "¡Has vuelto! Completa este desafío para obtener DOBLE experiencia y estrellas. Recorre el Sendero 3. Tu objetivo es recolecta todas las monedas, elimina a cualquier enemigo y elude obstáculos."
	mision.es_mision_especial = true
	mision.tamano_mapa = Vector2i(25, 25)
	mision.dificultad_mision = "Media"

	# CASO 1: 5 monedas y 2 enemigos en Sendero 3 (x=2)
	var caso1 = CasoPruebaMision.new()
	caso1.inicio_jugador = Vector2i(2, 0) # Sendero 3, Valle 1
	
	# Distribuimos 5 monedas
	for y in [2, 5, 8, 11, 14]:
		caso1.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(2, y))
	
	# 2 Enemigos
	caso1.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 4))
	caso1.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 10))
	
	caso1.agregar_condicion(CondicionMision.Recolectar.new("monedas", 5))
	caso1.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	mision.casos_de_prueba.append(caso1)

	# CASO 2: Sin monedas, solo enemigos y obstáculos (espacio de 2)
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 0)
	
	# Enemigos y Obstáculos con 2 espacios de separación (y=3, 6, 9, 12)
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 3))
	caso2.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(2, 6))
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 9))
	caso2.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(2, 12))
	
	caso2.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	mision.casos_de_prueba.append(caso2)

	# Comentamos la generación original para las pruebas
	# var mision_especial = GeneradorMisiones.generar_mision_especial_inactividad()
	
	# 2. La guardamos en nuestra "mochila" global
	GameData.mision_seleccionada = mision
	
	print("Iniciando misión especial HARDCODED: ", mision.titulo)
	# --- FIN HARDCODE ---

	# 3. Cambiamos a la escena de juego
	get_tree().change_scene_to_file("res://scenes/mision_juego/mision_juego.tscn")

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/selector_misiones/selector_misiones.tscn")

func _on_sandbox_pressed():
	GameData.mision_seleccionada = null
	get_tree().change_scene_to_file("res://scenes/mision_juego/mision_juego.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()

func _on_cerrar_sesion_pressed() -> void:
	# 1. Verificar si hay datos pendientes en las tablas locales
	var misiones_p = DatabaseManager.obtener_misiones_pendientes().size()
	var especiales_p = DatabaseManager.obtener_misiones_especiales_pendientes().size()
	var dificultades_p = DatabaseManager.obtener_dificultades_pendientes().size()
	var total_pendientes = misiones_p + especiales_p + dificultades_p
	
	# 2. Crear diálogo de confirmación
	var confirm = ConfirmationDialog.new()
	confirm.title = "Cerrar Sesión"
	
	var mensaje = "¿Estás seguro de que deseas cerrar la sesión?\n"
	mensaje += "Esto borrará todos los datos locales del alumno.\n"
	
	if total_pendientes > 0:
		mensaje += "\n[ADVERTENCIA]: Tienes %d elementos sin sincronizar.\n" % total_pendientes
		mensaje += "¿Deseas sincronizar ahora antes de salir?"
		confirm.get_ok_button().text = "Sincronizar y Salir"
		
		# Botón extra para salir sin sincronizar (borrado inmediato)
		var btn_forzar = confirm.add_button("Salir de todos modos", false, "force_logout")
		btn_forzar.pressed.connect(func():
			confirm.hide()
			_ejecutar_cierre_sesion(false)
		)
	else:
		confirm.get_ok_button().text = "Sí, cerrar sesión"
	
	confirm.dialog_text = mensaje
	confirm.get_cancel_button().text = "Cancelar"
	confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	
	# El botón OK ejecutará la sincronización si hay pendientes
	confirm.confirmed.connect(func(): _ejecutar_cierre_sesion(total_pendientes > 0))
	
	add_child(confirm)
	confirm.popup()

func _ejecutar_cierre_sesion(debe_sincronizar: bool):
	if debe_sincronizar:
		print("Iniciando sincronización final antes de cerrar sesión...")
		# Conectamos a la señal del gestor para saber cuándo terminar
		if not GestorSincronizacion.sincronizacion_finalizada.is_connected(_al_terminar_sincronizacion_final):
			GestorSincronizacion.sincronizacion_finalizada.connect(_al_terminar_sincronizacion_final)
		
		GestorSincronizacion.sincronizar_pendientes()
		# Aquí podrías añadir un overlay de "Sincronizando..." si lo deseas
	else:
		_finalizar_limpieza_y_redireccion()

func _al_terminar_sincronizacion_final(_exito: bool):
	# Desconectamos para evitar ejecuciones accidentales en el futuro
	if GestorSincronizacion.sincronizacion_finalizada.is_connected(_al_terminar_sincronizacion_final):
		GestorSincronizacion.sincronizacion_finalizada.disconnect(_al_terminar_sincronizacion_final)
	
	_finalizar_limpieza_y_redireccion()

func _finalizar_limpieza_y_redireccion():
	# 1. Limpiar base de datos local
	DatabaseManager.limpiar_datos_sesion()
	
	# 2. Redirigir a la escena de Login
	get_tree().change_scene_to_file("res://scenes/login/login.tscn")
