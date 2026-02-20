extends Control

@export var label_usuario: Label
@export var http_request_sync: HTTPRequest
@export var overlay_sincronizacion: Control
@export var label_mensaje_sync: Label
@export var label_error_sync: Label
@export var spinner: TextureRect
@export var boton_aceptar_sync: Button

@export_group("Modal Misión Especial")
@export var capa_modal_especial: CanvasLayer
@export var btn_aceptar_especial: Button
@export var btn_cancelar_especial: Button

# URL base del backend (ajustar si cambia el puerto/host)
const API_BASE_URL = "http://localhost:3000/api"

var _tiempo_inicio_sync: int = 0
var _spinner_tween: Tween

func _ready():
	# Verificamos inactividad al iniciar el menú
	_mostrar_datos_alumno()
	
	if http_request_sync:
		http_request_sync.request_completed.connect(_on_sync_completed)
	
	if boton_aceptar_sync:
		boton_aceptar_sync.pressed.connect(_on_boton_aceptar_sync_pressed)
	
	if capa_modal_especial:
		capa_modal_especial.visible = false
		
	if btn_aceptar_especial:
		btn_aceptar_especial.pressed.connect(_iniciar_mision_especial)
		
	if btn_cancelar_especial:
		btn_cancelar_especial.pressed.connect(_cerrar_modal_especial)
	
	# Iniciamos sincronización si hay alumno logueado
	if DatabaseManager.obtener_id_alumno_actual() != "":
		_iniciar_sincronizacion_con_ui()
	else:
		# Si es invitado (no hay sync), verificamos inactividad directamente
		_verificar_inactividad()

func _mostrar_datos_alumno():
	var alumno = DatabaseManager.obtener_alumno_actual()
	if not alumno.is_empty():
		var texto = "Alumno: %s %s" % [alumno["nombre"], alumno["apellido"]]
		if label_usuario: label_usuario.text = texto
	else:
		if label_usuario: label_usuario.text = "Alumno: Invitado"

func _iniciar_sincronizacion_con_ui():
	print("MenuPrincipal: [SYNC] Iniciando proceso de sincronización con UI...")
	if overlay_sincronizacion: overlay_sincronizacion.show()
	if label_mensaje_sync: label_mensaje_sync.text = "Sincronizando dificultades desde la web..."
	if label_error_sync: label_error_sync.text = ""
	if boton_aceptar_sync: boton_aceptar_sync.hide()
	
	# Iniciamos animación de spinner
	if spinner:
		if _spinner_tween: _spinner_tween.kill()
		spinner.pivot_offset = Vector2(32, 32) # Mitad de 64x64
		_spinner_tween = create_tween()
		_spinner_tween.set_loops()
		_spinner_tween.tween_property(spinner, "rotation_degrees", 360.0, 1.0).from(0.0)
	
	_tiempo_inicio_sync = Time.get_ticks_msec()
	_sincronizar_dificultades_web()

func _sincronizar_dificultades_web():
	# 1. Obtenemos ID del alumno local
	print("MenuPrincipal: [SYNC] Buscando ID de alumno local...")
	var id_alumno = DatabaseManager.obtener_id_alumno_actual()
	if id_alumno == "":
		print("MenuPrincipal: [SYNC] No se encontró ID de alumno (Invitado o Error). Abortando sync.")
		return # No hay sesión o es invitado
	
	print("MenuPrincipal: [SYNC] ID encontrado: ", id_alumno)
	print("MenuPrincipal: [SYNC] Preparando petición HTTP...")
	
	# 2. Construimos URL: /alumnos/:id/sync-difficulties
	var url = "%s/alumnos/%s/sync-difficulties" % [API_BASE_URL, id_alumno]
	print("MenuPrincipal: [SYNC] URL destino: ", url)
	
	# 3. Hacemos la petición
	if http_request_sync:
		var error = http_request_sync.request(url)
		if error != OK:
			print("MenuPrincipal: [SYNC] ERROR al iniciar request HTTP. Código error Godot: ", error)
			_mostrar_resultado_sync(false, "Error interno al iniciar petición.")
	else:
		print("MenuPrincipal: [SYNC] ERROR: Nodo HTTPRequest no asignado.")
		if overlay_sincronizacion: overlay_sincronizacion.hide()
		_verificar_inactividad()

func _on_sync_completed(result, response_code, _headers, body):
	print("MenuPrincipal: [SYNC] Respuesta recibida. Result: %d | HTTP Code: %d" % [result, response_code])
	var exito = false
	var mensaje_detalle = ""
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("MenuPrincipal: [SYNC] Conexión exitosa. Procesando JSON...")
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json != null and json is Array:
			print("MenuPrincipal: [SYNC] JSON válido (Array de %d elementos). Enviando a DBManager..." % json.size())
			if DatabaseManager.actualizar_dificultades_desde_web(json):
				exito = true
				mensaje_detalle = "Se actualizaron %d dificultades desde la web." % json.size()
			else:
				mensaje_detalle = "Error al guardar en base de datos."
		else:
			print("MenuPrincipal: [SYNC] ERROR: El cuerpo de la respuesta no es un Array válido o es nulo.")
			mensaje_detalle = "Datos recibidos inválidos."
	else:
		mensaje_detalle = "Error de conexión (%d)" % response_code
		print("MenuPrincipal: [SYNC] FALLÓ la sincronización. Código HTTP: ", response_code)

	_mostrar_resultado_sync(exito, mensaje_detalle)

func _mostrar_resultado_sync(exito: bool, detalle: String):
	if _spinner_tween: _spinner_tween.kill()
	
	if exito:
		if label_mensaje_sync: label_mensaje_sync.text = "¡Sincronización Exitosa!"
		if label_error_sync:
			label_error_sync.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2)) # Verde
			label_error_sync.text = detalle
	else:
		if label_mensaje_sync: label_mensaje_sync.text = "Error en Sincronización"
		if label_error_sync:
			label_error_sync.add_theme_color_override("font_color", Color(1, 0.2, 0.2)) # Rojo
			label_error_sync.text = detalle
			
	if boton_aceptar_sync: boton_aceptar_sync.show()

func _on_boton_aceptar_sync_pressed():
	if overlay_sincronizacion: overlay_sincronizacion.hide()
	_verificar_inactividad()

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
	
	if capa_modal_especial:
		capa_modal_especial.show()
		# Animación simple de entrada
		var panel = capa_modal_especial.get_node_or_null("ControlModal/PanelFondo")
		if panel:
			panel.scale = Vector2(0.8, 0.8)
			var tween = create_tween()
			tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _cerrar_modal_especial():
	if capa_modal_especial:
		capa_modal_especial.hide()

func _iniciar_mision_especial():
	# --- HARDCODE: Misión Especial de Prueba ---
	var timestamp = Time.get_datetime_string_from_system().replace("T", " ")
	var mision = DefinicionMision.new()
	mision.id = DatabaseManager.generar_uuid_v4()
	mision.titulo = "Misión de Retorno [%s]" % timestamp
	mision.descripcion = "¡Has vuelto! Completa este desafío para obtener DOBLE experiencia y estrellas. Recorre el Sendero 3. Tu objetivo es recolectar todas las monedas, eliminar a cualquier enemigo y eludir los obstáculos.\n(Generada: %s)" % timestamp
	mision.es_mision_especial = true
	mision.tamano_mapa = Vector2i(25, 25)
	mision.dificultad_mision = "Medio"

	# CASO 1: 5 monedas y 2 enemigos en Sendero 3 (x=2)
	var caso1 = CasoPruebaMision.new()
	caso1.inicio_jugador = Vector2i(2, 0) # Sendero 3, Valle 1
	
	# Distribuimos 5 monedas
	for y in [2, 5, 8, 11, 14]:
		caso1.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(2, y))
	
	# 2 Enemigos
	caso1.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 4))
	caso1.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 10))
	
	caso1.agregar_condicion(CondicionRecolectar.new("monedas", 5))
	caso1.agregar_condicion(CondicionEliminarEnemigos.new())
	mision.casos_de_prueba.append(caso1)

	# CASO 2: Sin monedas, solo enemigos y obstáculos (espacio de 2)
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 0)
	
	# Enemigos y Obstáculos con 2 espacios de separación (y=3, 6, 9, 12)
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 3))
	caso2.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(2, 6))
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 9))
	caso2.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(2, 12))
	
	caso2.agregar_condicion(CondicionEliminarEnemigos.new())
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
	mensaje += "Esto borrará todos tus datos locales de progreso y dificultades.\n"
	
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
