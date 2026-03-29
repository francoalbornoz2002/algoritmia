extends Node2D

# --- REFERENCIAS ---
@export var tablero: Node2D
@export var mapa_visual: TileMapLayer
@export var mapa_agua: TileMapLayer
@export var jugador: CharacterBody2D
@export var entidades_container: Node2D
var analista_dificultad: AnalistaDificultad

# UI Referencias
@export var label_mision: Label
@export var label_dificultad: Label
@export var label_descripcion: Label
@export var code_edit: CodeEdit
@export var boton_ejecutar: Button
@export var boton_volver: Button
@export var consola_visual: RichTextLabel

@export var ejecutor: Node
@export var timer_reinicio: Timer

# --- UI VICTORIA PERSONALIZADA ---
@export_group("UI Victoria")
@export var capa_victoria: CanvasLayer
@export var panel_victoria_rect: TextureRect
@export var label_titulo_victoria: Label
@export var label_xp_victoria: Label
@export var boton_continuar_victoria: Button
@export var texturas_estrellas: Array[Texture2D] # Índice 0=1 estrella, 1=2 estrellas, 2=3 estrellas
@export var dialogo_confirmar_salida: ConfirmationDialog
@export var overlay_sync: Control
@export var spinner_sync: TextureRect
@export var label_detalle_sync: Label
@export var boton_aceptar_sync: Button

# --- FEEDBACK FORMATIVO ---
var modal_feedback: FeedbackFormativo = null

# Estado del juego
var ejecutando_codigo: bool = false
var sandbox: bool = false
var juego_fallido: bool = false # Bandera para abortar secuencia si hay Game Over
var intentos_totales: int = 0
var semilla_mision: int = 0
var mision_finalizada: bool = false
var _saliendo_del_juego: bool = false
var _spinner_tween: Tween

@export_group("Configuración Visual del Mapa")
@export var tiles_suelo_centro: Array[Vector2i] = [Vector2i(5, 3)]
@export var tiles_borde_sup: Array[Vector2i] = [Vector2i(6, 5)]
@export var tiles_borde_inf: Array[Vector2i] = [Vector2i(6, 4)]
@export var tiles_borde_izq: Array[Vector2i] = [Vector2i(3, 5)]
@export var tiles_borde_der: Array[Vector2i] = [Vector2i(2, 5)]
@export var tile_esquina_sup_izq: Vector2i = Vector2i(0, 7)
@export var tile_esquina_sup_der: Vector2i = Vector2i(1, 7)
@export var tile_esquina_inf_izq: Vector2i = Vector2i(5, 7)
@export var tile_esquina_inf_der: Vector2i = Vector2i(4, 7)

# --- SISTEMA DE MISIONES ---
var mision_actual_def: DefinicionMision = null
var caso_actual_idx: int = 0
var logs_consola: Array[String] = [] # Para verificar condiciones de Output
var _victoria_tween: Tween

# Precargamos la escena del elemento
var elemento_escena = preload("res://scenes/elemento_tablero/elemento_tablero.tscn")

func _ready():
	randomize()
	get_tree().set_auto_accept_quit(false) # Manejamos la salida manualmente
	semilla_mision = randi()
	GridManager.limpiar_datos()
	
	# Si hay misión seleccionada, desactivamos modo sandbox para activar el analista
	var es_tutorial = false
	if GameData.mision_seleccionada != null:
		sandbox = false
		es_tutorial = GameData.mision_seleccionada.es_tutorial
	else:
		sandbox = true
	
	# 1. Configurar el Ejecutor
	ejecutor.personaje = jugador
	ejecutor.controlador_nivel = self
	
	# 2. Conexiones
	if not boton_ejecutar.pressed.is_connected(_on_ejecutar_pressed):
		boton_ejecutar.pressed.connect(_on_ejecutar_pressed)
	
	if boton_volver and not boton_volver.pressed.is_connected(_on_boton_volver_pressed):
		boton_volver.pressed.connect(_on_boton_volver_pressed)
	
	if boton_continuar_victoria and not boton_continuar_victoria.pressed.is_connected(_on_victoria_continuar_pressed):
		boton_continuar_victoria.pressed.connect(_on_victoria_continuar_pressed)
	
	timer_reinicio.one_shot = true
	if not timer_reinicio.timeout.is_connected(_on_reiniciar_mision):
		timer_reinicio.timeout.connect(_on_reiniciar_mision)
		
	if not jugador.game_over_triggered.is_connected(_on_jugador_game_over):
		jugador.game_over_triggered.connect(_on_jugador_game_over)
		
	if not jugador.consola_mensaje_enviado.is_connected(agregar_mensaje_consola):
		jugador.consola_mensaje_enviado.connect(agregar_mensaje_consola)
		
	if dialogo_confirmar_salida and not dialogo_confirmar_salida.confirmed.is_connected(_on_confirmar_salida_confirmed):
		dialogo_confirmar_salida.confirmed.connect(_on_confirmar_salida_confirmed)
	
	if boton_aceptar_sync and not boton_aceptar_sync.pressed.is_connected(_on_boton_aceptar_sync_pressed):
		boton_aceptar_sync.pressed.connect(_on_boton_aceptar_sync_pressed)
	
	# --- PREPARAR MODAL DE FEEDBACK ---
	var escena_feedback = preload("res://scenes/ui/feedback_formativo/FeedbackFormativo.tscn")
	if escena_feedback:
		modal_feedback = escena_feedback.instantiate()
		add_child(modal_feedback)
		modal_feedback.feedback_completado.connect(_volver_al_menu)
	
	if not sandbox and not es_tutorial:
		analista_dificultad = AnalistaDificultad.new()
		add_child(analista_dificultad)
		
		# Conectarlo con el jugador
		jugador.analista = analista_dificultad
	else:
		if es_tutorial:
			print("--- Modo Tutorial: Analista de Dificultad DESACTIVADO ---")
		else:
			print("--- Modo Sandbox: Analista de Dificultad DESACTIVADO ---")
	
	# Verificamos si hay una misión pendiente en el Singleton
	if GameData.mision_seleccionada != null:
		cargar_mision(GameData.mision_seleccionada)
		# Limpiamos la variable para no recargarla por error si volvemos al menú y entramos a otro lado
		GameData.mision_seleccionada = null
	elif sandbox:
		_generar_suelo(Vector2i(25, 25))
		jugador.teletransportar_a(Vector2i(0, 0))

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_intentar_salir(true)

func _on_boton_volver_pressed():
	_intentar_salir(false)

func _intentar_salir(es_quit: bool):
	_saliendo_del_juego = es_quit
	
	# Condiciones para salir directo:
	# 1. Modo Sandbox (no hay registro)
	# 2. No se ha hecho ningún intento (nada que registrar)
	# 3. La misión ya terminó (ya se registró)
	if sandbox or intentos_totales == 0 or mision_finalizada:
		_ejecutar_salida()
		return

	# Si hay intentos pendientes y no terminó, mostramos advertencia
	if dialogo_confirmar_salida:
		dialogo_confirmar_salida.popup_centered()
	else:
		# Fallback si no hay diálogo
		_ejecutar_salida()

func _on_confirmar_salida_confirmed():
	# Registramos errores como abandono (Equivalente a 1 estrella: 100% errores)
	if analista_dificultad:
		print("MisionJuego: Abandonando misión. Registrando errores acumulados...")
		# Usamos la lógica de 1 estrella para guardar todo lo acumulado
		analista_dificultad.procesar_victoria_segun_estrellas(1)
	
	_ejecutar_salida()

func _ejecutar_salida():
	# Deshabilitamos botones para evitar múltiples clics
	if boton_volver: boton_volver.disabled = true
	if boton_continuar_victoria: boton_continuar_victoria.disabled = true
	if boton_ejecutar: boton_ejecutar.disabled = true

	# Verificamos si hay algo pendiente de sincronizar antes de irnos
	var pendientes = 0
	pendientes += DatabaseManager.obtener_misiones_pendientes().size()
	pendientes += DatabaseManager.obtener_misiones_especiales_pendientes().size()
	pendientes += DatabaseManager.obtener_dificultades_pendientes().size()
	
	if pendientes > 0:
		_iniciar_espera_sincronizacion()
	else:
		_realizar_salida_definitiva()

func _iniciar_espera_sincronizacion():
	print("MisionJuego: Datos pendientes detectados. Iniciando sincronización bloqueante...")
	
	# Ocultamos la capa de victoria para que se vea el overlay de sincronización (que está en CapaUI)
	if capa_victoria: capa_victoria.visible = false
	if overlay_sync: overlay_sync.show()
	
	# Reset UI Sync
	if boton_aceptar_sync: boton_aceptar_sync.hide()
	if label_detalle_sync: label_detalle_sync.text = ""
	if spinner_sync: spinner_sync.show()
	
	# Animación Spinner
	if spinner_sync:
		if _spinner_tween: _spinner_tween.kill()
		spinner_sync.pivot_offset = Vector2(32, 32)
		_spinner_tween = create_tween()
		_spinner_tween.set_loops()
		_spinner_tween.tween_property(spinner_sync, "rotation_degrees", 360.0, 1.0).from(0.0)
	
	# Conectamos señal del Gestor
	if not GestorSincronizacion.sincronizacion_finalizada.is_connected(_on_sincronizacion_finalizada):
		GestorSincronizacion.sincronizacion_finalizada.connect(_on_sincronizacion_finalizada)
	
	# Iniciamos la sincronización
	GestorSincronizacion.sincronizar_pendientes()
	
	# Timeout de seguridad (15 segundos) por si la red se cuelga o tarda
	await get_tree().create_timer(15.0).timeout
	
	# Si el botón de aceptar NO está visible, significa que aún estamos esperando (o se colgó)
	if overlay_sync and overlay_sync.visible and boton_aceptar_sync and not boton_aceptar_sync.visible:
		print("MisionJuego: Timeout de sincronización. Forzando salida.")
		_on_sincronizacion_finalizada(false)

func _on_sincronizacion_finalizada(_exito):
	if GestorSincronizacion.sincronizacion_finalizada.is_connected(_on_sincronizacion_finalizada):
		GestorSincronizacion.sincronizacion_finalizada.disconnect(_on_sincronizacion_finalizada)
	
	if _spinner_tween: _spinner_tween.kill()
	if spinner_sync: spinner_sync.hide()
	
	# Feedback Visual
	if _exito:
		if label_detalle_sync:
			label_detalle_sync.text = "¡Datos sincronizados en la web!"
			label_detalle_sync.add_theme_color_override("font_color", Color.GREEN)
	else:
		if label_detalle_sync:
			label_detalle_sync.text = "Sin conexión. Se guardó localmente."
			label_detalle_sync.add_theme_color_override("font_color", Color.ORANGE)
			
	# Mostramos el botón para que el usuario confirme y salga
	if boton_aceptar_sync: boton_aceptar_sync.show()

func _on_boton_aceptar_sync_pressed():
	if overlay_sync: overlay_sync.hide()
	_realizar_salida_definitiva()

func _realizar_salida_definitiva():
	if _saliendo_del_juego:
		get_tree().quit()
	else:
		# _volver_al_menu() ahora es solo cambiar de escena
		print("Regresando al selector de misiones...")
		get_tree().change_scene_to_file("res://scenes/selector_misiones/selector_misiones.tscn")

# --- CARGA DE MISIÓN ---

func cargar_mision(definicion: DefinicionMision):
	mision_actual_def = definicion
	intentos_totales = 0
	
	print("--- DEBUG DESCRIPCIÓN ---")
	print(definicion.descripcion) # <-- Mira esto en la consola de Godot
	print("-------------------------")
	
	# Actualizar UI
	label_mision.text = definicion.titulo
	label_dificultad.text = definicion.dificultad_mision
	label_descripcion.text = definicion.descripcion
	
	# Pasamos el tamaño del mapa al ejecutor para validaciones estáticas (LP-02)
	if ejecutor: ejecutor.tamano_mapa_ref = definicion.tamano_mapa
	
	# Generamos el suelo visualmente
	_generar_suelo(definicion.tamano_mapa)
	
	# Preparamos el primer caso de prueba visualmente para que el alumno vea el escenario 1
	_preparar_caso_prueba(0)

func _preparar_caso_prueba(indice: int):
	if mision_actual_def == null or indice >= mision_actual_def.casos_de_prueba.size():
		return
		
	var caso = mision_actual_def.casos_de_prueba[indice]
	
	# 1. Limpiar escenario anterior
	_limpiar_entidades()
	GridManager.limpiar_datos()
	if mapa_agua: mapa_agua.clear()
	logs_consola.clear()
	
	# 2. Reiniciar Jugador
	jugador.reiniciar_inventario()
	jugador.teletransportar_a(caso.inicio_jugador)
	# TODO: Soportar dirección inicial si se define en el caso
	
	# 3. Spawnear Elementos
	for elemento in caso.elementos_mapa:
		spawn_elemento(elemento.pos, elemento.tipo)

func _limpiar_entidades():
	for child in entidades_container.get_children():
		if child != jugador:
			child.queue_free()

# --- PREPARACIÓN DEL ESCENARIO ---
func spawn_elemento(pos: Vector2i, tipo):
	var nuevo_elemento = elemento_escena.instantiate()
	entidades_container.add_child(nuevo_elemento)
	
	# Configuramos visual y lógicamente
	nuevo_elemento.configurar(tipo, pos, semilla_mision)
	
	# --- Lógica de Agua bajo el Puente ---
	if tipo == ElementoTablero.Tipo.PUENTE and mapa_agua:
		var fila_visual = (GridManager.FILAS_MAX - 1) - pos.y
		var pos_mapa = Vector2i(pos.x, fila_visual)
		# Usamos específicamente el tile (1, 3) para el agua para evitar piedras randomizadas
		var coords_tile = Vector2i(1, 3)
		mapa_agua.set_cell(pos_mapa, 0, coords_tile)

	# --- Lógica de Offset Visual (Si ya hay objeto) ---
	var objetos_en_celda = GridManager.obtener_objetos_en_celda(pos)
	if not objetos_en_celda.is_empty():
		var existente = objetos_en_celda[0]
		# Desplazamos el existente a la izquierda
		existente.position.x -= 8
		# Desplazamos el nuevo a la derecha
		nuevo_elemento.position.x += 8

	# Registramos en la memoria del GridManager
	GridManager.registrar_objeto(pos, nuevo_elemento)

func _generar_suelo(tamano: Vector2i):
	if not mapa_visual: return
	
	# 1. Limpiamos el TileMapLayer de cualquier celda previa
	mapa_visual.clear()
	
	for x in range(tamano.x):
		for y in range(tamano.y):
			var coords_atlas = Vector2i(0, 0)
			if not tiles_suelo_centro.is_empty():
				coords_atlas = tiles_suelo_centro.pick_random()
			
			# Lógica visual: En GridManager Y=0 es ABAJO (Valle 1), Y=Max es ARRIBA
			var es_abajo = (y == 0)
			var es_arriba = (y == tamano.y - 1)
			var es_izq = (x == 0)
			var es_der = (x == tamano.x - 1)
			
			if es_arriba and es_izq: coords_atlas = tile_esquina_sup_izq
			elif es_arriba and es_der: coords_atlas = tile_esquina_sup_der
			elif es_abajo and es_izq: coords_atlas = tile_esquina_inf_izq
			elif es_abajo and es_der: coords_atlas = tile_esquina_inf_der
			elif es_arriba:
				if not tiles_borde_sup.is_empty(): coords_atlas = tiles_borde_sup.pick_random()
			elif es_abajo:
				if not tiles_borde_inf.is_empty(): coords_atlas = tiles_borde_inf.pick_random()
			elif es_izq:
				if not tiles_borde_izq.is_empty(): coords_atlas = tiles_borde_izq.pick_random()
			elif es_der:
				if not tiles_borde_der.is_empty(): coords_atlas = tiles_borde_der.pick_random()
			
			# 2. Calculamos la posición visual en el TileMap (invirtiendo Y para que coincida con GridManager)
			var fila_visual = (GridManager.FILAS_MAX - 1) - y
			var pos_mapa = Vector2i(x, fila_visual)
			
			# 3. Pintamos la celda en el TileMapLayer (source_id 0 es el Atlas por defecto)
			mapa_visual.set_cell(pos_mapa, 0, coords_atlas)

# --- LÓGICA DE EJECUCIÓN (TEST RUNNER) ---
func _on_ejecutar_pressed():
	if ejecutando_codigo: return # Ya está corriendo, no hacer nada
	
	intentos_totales += 1
	
	print("--- INICIANDO INTENTO #", intentos_totales, " ---") # Log para debug
	
	limpiar_errores_editor()
	limpiar_consola_visual()
	agregar_mensaje_consola("--- Iniciando ejecución ---", "SISTEMA")
	
	# Avisar al analista que empieza un nuevo intento
	if analista_dificultad:
		analista_dificultad.iniciar_nuevo_intento()
	
	print("--- INICIANDO SUITE DE PRUEBAS ---")
	ejecutando_codigo = true
	juego_fallido = false
	caso_actual_idx = 0
	boton_ejecutar.disabled = true
	
	if sandbox:
		# 2. Inyectar código al ejecutor
		var codigo_fuente = code_edit.text
		ejecutor.procesar_y_ejecutar(codigo_fuente)
	else:
		 # Ejecutamos el primer caso
		_ejecutar_caso_actual()

func _ejecutar_caso_actual():
	if juego_fallido: return
	
	# 1. Resetear el tablero para el caso actual
	_preparar_caso_prueba(caso_actual_idx)
	agregar_mensaje_consola("--- Ejecutando Caso de Prueba " + str(caso_actual_idx + 1) + " ---", "SISTEMA")

	
	# Pequeña pausa para que se asienten los nodos
	await get_tree().process_frame
	
	# Pausa para que la cámara se acomode y el jugador vea el inicio del caso
	await get_tree().create_timer(1).timeout
	
	# 2. Inyectar código al ejecutor
	var codigo_fuente = code_edit.text
	ejecutor.procesar_y_ejecutar(codigo_fuente)

# Esta función es llamada por el Ejecutor cuando el script termina (Línea 'Fin')
func on_ejecucion_terminada(exito: bool):
	# Si ya falló por Game Over, no hacemos nada más que esperar el reinicio UI
	if juego_fallido: return
	
	if not exito:
		# Falló por error de sintaxis o runtime error
		_manejar_fallo("Error de ejecución en el script.")
		return
	
	if sandbox:
		print("--- EJECUCIÓN SANDBOX FINALIZADA (Éxito: " + str(exito) + ") ---")
		agregar_mensaje_consola("Ejecución sandbox finalizada con éxito", "SISTEMA")
		ejecutando_codigo = false
		# 2. Iniciar el Timer de 3 segundos
		print("Reiniciando en 3 segundos...")
		agregar_mensaje_consola("Reiniciando en 3 segundos...", "SISTEMA")
		timer_reinicio.start(3.0)
		return
	
	# Si el script terminó bien, verificamos los casos de prueba
	print("Script finalizado. Verificando condiciones del caso ", caso_actual_idx + 1)
	var caso = mision_actual_def.casos_de_prueba[caso_actual_idx]
	var condiciones_cumplidas = true
	var error_msg = ""
	
	for condicion in caso.condiciones_victoria:
		var paso = condicion.verificar(jugador, GridManager, ejecutor, logs_consola)
		if not paso:
			condiciones_cumplidas = false
			error_msg = condicion.descripcion
			break
	
	if condiciones_cumplidas:
		agregar_mensaje_consola("¡Caso " + str(caso_actual_idx + 1) + " Superado!", "SISTEMA")
		_avanzar_siguiente_caso()
	else:
		_manejar_fallo("Objetivo no cumplido: " + error_msg)

func _avanzar_siguiente_caso():
	caso_actual_idx += 1
	
	if caso_actual_idx < mision_actual_def.casos_de_prueba.size():
		# Hay más casos, seguimos ejecutando
		await get_tree().create_timer(1.0).timeout
		_ejecutar_caso_actual()
	else:
		# ¡TODOS LOS CASOS SUPERADOS!
		_victoria_total()

func _victoria_total():
	agregar_mensaje_consola("¡MISIÓN COMPLETADA! ★★★", "SISTEMA")
	ejecutando_codigo = false
	boton_ejecutar.disabled = true
	mision_finalizada = true
	
	# 1. Calcular Recompensas con la nueva lógica
	var resultado = calcular_resultado_final()
	var estrellas_base = resultado["estrellas"] # 1, 2 o 3 (Rendimiento real)
	var estrellas_db = estrellas_base # Lo que guardaremos (puede tener bonus)
	var exp_final = resultado["exp"]
	
	# 2. Guardado en BD y Lógica Diferenciada
	if mision_actual_def:
		# --- RAMA A: MISIÓN ESPECIAL ---
		if mision_actual_def.es_mision_especial:
			agregar_mensaje_consola("¡BONUS MISIÓN ESPECIAL! (x2 Recompensas)", "SISTEMA")
			
			# Multiplicar recompensas
			estrellas_db *= 2
			exp_final *= 2
			
			DatabaseManager.registrar_mision_especial_local(
				mision_actual_def.titulo,
				mision_actual_def.descripcion,
				estrellas_db,
				exp_final,
				intentos_totales
			)
		# --- RAMA B: MISIÓN NORMAL ---
		else:
			DatabaseManager.registrar_mision_local(
				mision_actual_def.id,
				estrellas_db,
				exp_final,
				intentos_totales
			)
		
		# 3. Procesar Dificultades para ambos tipos de misión
		if analista_dificultad:
			# IMPORTANTE: Al analista le pasamos el rendimiento REAL (base), no el duplicado.
			analista_dificultad.procesar_victoria_segun_estrellas(estrellas_base)
	
	# 5. MOSTRAR POPUP DE VICTORIA
	await get_tree().create_timer(1.0).timeout
	# A la UI le pasamos las estrellas base para que muestre la textura correcta (1, 2 o 3)
	mostrar_popup_victoria(estrellas_base, exp_final)

func _manejar_fallo(mensaje: String):
	juego_fallido = true
	agregar_mensaje_consola("FALLO: " + mensaje, "ERROR")
	
	# Timer para permitir reintentar
	timer_reinicio.start(3.0)

func _on_jugador_game_over(mensaje):
	# 1. Informar al usuario
	agregar_mensaje_consola("GAME OVER: " + mensaje, "ERROR")
	
	# 2. Marcar estado de fallo y detener scripts
	juego_fallido = true
	ejecutor.detener_ejecucion_inmediata()
	
	# 3. INTERCEPTAR ERROR DE BUCLE Y CONSOLIDAR
	if analista_dificultad:
		# Si fue un bucle infinito (mensaje del Ejecutor), avisamos
		if "Bucle Infinito" in mensaje:
			analista_dificultad.registrar_error_externo(AnalistaDificultad.DIF_BUCLE_INFINITO)
			
		# Detección LP-02: Choque con límites (Off-by-one error)
		if "[LIMIT_CRASH]" in mensaje:
			analista_dificultad.registrar_error_externo(AnalistaDificultad.DIF_RELACIONALES)
		
		# Consolidamos el intento fallido
		analista_dificultad.consolidar_intento_actual()
	
	# 4. Iniciar el timer de reinicio
	print("Iniciando reinicio por Game Over...")
	if timer_reinicio.is_stopped():
		timer_reinicio.start(3.0)

func agregar_mensaje_consola(mensaje: String, tipo: String = "NORMAL"):
	logs_consola.append(mensaje) # Guardamos para validación (OutputContiene)
	
	if not consola_visual: return
	
	var color_hex = "#333333"
	var prefijo = "> "
	
	match tipo:
		"ERROR":
			color_hex = "#CC0000"
			prefijo = "[ERROR] "
		"ADVERTENCIA":
			color_hex = "#D4A017" # Dorado oscuro (visible en beige)
			prefijo = "[AVISO] "
		"OUTPUT":
			color_hex = "#0066CC"
			prefijo = ""
		"SISTEMA":
			color_hex = "#0044AA" # Azul oscuro
			prefijo = "[SISTEMA] "
			
	var texto_final = "[color=" + color_hex + "]" + prefijo + mensaje + "[/color]"
	consola_visual.append_text(texto_final + "\n")
	
	await get_tree().process_frame
	consola_visual.scroll_to_line(consola_visual.get_line_count())

func _on_reiniciar_mision():
	boton_ejecutar.disabled = false
	ejecutando_codigo = false
	
	if sandbox:
		# Reinicio simple para Sandbox
		agregar_mensaje_consola("Reiniciando sandbox...", "SISTEMA")
		_limpiar_entidades()
		GridManager.limpiar_datos()
		jugador.teletransportar_a(Vector2i(0, 0))
		jugador.inventario.monedas = 0
		jugador.inventario.llaves = 0
		logs_consola.clear()
		agregar_mensaje_consola("Sandbox reiniciado", "SISTEMA")
	else:
		agregar_mensaje_consola("Reiniciando misión para reintento...", "SISTEMA")
		# Volvemos a mostrar el caso 0 para que el alumno piense
		_preparar_caso_prueba(0)

# --- MANEJO VISUAL DE ERRORES DE SINTAXIS ---

func mostrar_error_sintaxis(linea_idx: int, mensaje: String):
	# 1. Mostrar mensaje en consola
	agregar_mensaje_consola("ERROR SINTAXIS (Línea " + str(linea_idx + 1) + "): " + mensaje, "ERROR")

	# 2. Resaltar línea en el editor (Rojo suave)
	var color_error = Color(0.5, 0.0, 0.0, 0.5)
	code_edit.set_line_background_color(linea_idx, color_error)

	# 3. Mover el cursor a esa línea
	code_edit.set_caret_line(linea_idx)

func limpiar_errores_editor():
	# Limpiamos el fondo de todas las líneas
	for i in range(code_edit.get_line_count()):
		code_edit.set_line_background_color(i, Color(0, 0, 0, 0)) # Transparente

func limpiar_consola_visual():
	if consola_visual:
		consola_visual.clear()
	logs_consola.clear() # También limpiamos el historial interno de validación

# --- HELPERS DE RECOMPENSA ---

func _obtener_multiplicador_dificultad(dificultad: String) -> int:
	# Normalizamos el string por si acaso (ej: "Fácil" vs "Facil")
	var dif = dificultad.to_lower()
	
	if "facil" in dif or "fácil" in dif:
		return 1
	elif "media" in dif or "medio" in dif:
		return 2
	elif "dificil" in dif or "difícil" in dif:
		return 3
	
	# Valor por defecto si no coincide
	return 1

func calcular_resultado_final() -> Dictionary:
	# --- NUEVO SISTEMA DE PUNTUACIÓN (0-100) ---
	var puntuacion = 100
	
	# 1. Penalización por Intentos (Más estricta y gradual)
	if intentos_totales == 1:
		puntuacion -= 0 # Sin penalización
	elif intentos_totales <= 3:
		puntuacion -= 10
		print("Evaluación: -10 pts por intentos (%d)" % intentos_totales)
	elif intentos_totales <= 5:
		puntuacion -= 20
		print("Evaluación: -20 pts por intentos (%d)" % intentos_totales)
	else:
		puntuacion -= 35
		print("Evaluación: -35 pts por intentos (%d)" % intentos_totales)
	
	# 2. Penalización por Calidad de Código (Más granular)
	if analista_dificultad:
		var total_errores = analista_dificultad.obtener_total_errores()
		var errores_graves = analista_dificultad.hay_errores_graves()
		
		if errores_graves:
			puntuacion -= 40
			print("Evaluación: -40 pts por errores graves detectados.")
		elif total_errores > 5:
			puntuacion -= 25
			print("Evaluación: -25 pts por alta cantidad de errores (%d)." % total_errores)
		elif total_errores > 0:
			puntuacion -= 10
			print("Evaluación: -10 pts por errores menores (%d)." % total_errores)

	# 3. Conversión de Puntuación a Estrellas
	var estrellas = 1
	if puntuacion >= 80: estrellas = 3
	elif puntuacion >= 50: estrellas = 2
	
	# 4. Cálculo de XP (NUEVA FÓRMULA)
	# Fórmula: XP = Puntos * 10 * Multiplicador Dificultad
	var multiplicador = _obtener_multiplicador_dificultad(mision_actual_def.dificultad_mision)
	var xp_final = puntuacion * 10 * multiplicador
	
	print("Cálculo XP: Puntos(", puntuacion, ") * 10 * Multiplicador(", multiplicador, ") = ", xp_final)
		
	return {"estrellas": estrellas, "exp": xp_final}

# --- UI DE VICTORIA ---

func mostrar_popup_victoria(estrellas: int, xp: int):
	if not capa_victoria:
		print("ERROR: No se ha asignado la CapaVictoria en el inspector.")
		_volver_al_menu()
		return

	# Asegurarse de que el tween anterior esté detenido
	if _victoria_tween and _victoria_tween.is_running():
		_victoria_tween.kill()

	# 1. Configurar Textura del Panel según estrellas
	# El array texturas_estrellas debe tener: [0]=1 estrella, [1]=2 estrellas, [2]=3 estrellas
	var idx_textura = clampi(estrellas - 1, 0, 2)
	if texturas_estrellas.size() > idx_textura:
		panel_victoria_rect.texture = texturas_estrellas[idx_textura]
	
	# 2. Configurar Título
	var titulo = ""
	match estrellas:
		3: titulo = "¡Algoritmo Perfecto!"
		2: titulo = "¡Bien hecho!"
		_: titulo = "¡Bien! pero... Puedes mejorar"
	label_titulo_victoria.text = titulo
	
	# 3. Configurar XP y mensaje de bonus
	var texto_xp = "EXP Obtenida: +%d" % xp
	if mision_actual_def and mision_actual_def.es_mision_especial:
		texto_xp += "\n(¡Bonus x2 Aplicado!)"
	label_xp_victoria.text = texto_xp
	
	# 4. Preparar para la animación
	panel_victoria_rect.scale = Vector2(0.7, 0.7) # Empieza más pequeño
	panel_victoria_rect.modulate = Color(1, 1, 1, 0) # Empieza transparente
	
	# 5. Mostrar la capa (el panel aún es invisible por modulate)
	capa_victoria.visible = true
	
	# 6. Iniciar la animación de "pop-in"
	_victoria_tween = create_tween()
	_victoria_tween.set_parallel(true) # Animamos escala y opacidad al mismo tiempo
	_victoria_tween.tween_property(panel_victoria_rect, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_victoria_tween.tween_property(panel_victoria_rect, "modulate", Color(1, 1, 1, 1), 0.3).set_trans(Tween.TRANS_LINEAR)
	_victoria_tween.play()

func _on_victoria_continuar_pressed():
	# Ocultamos la pantalla de victoria
	if capa_victoria:
		capa_victoria.visible = false
	
	# Recopilamos las dificultades cometidas en esta sesión
	var codigos_dificultad = []
	if analista_dificultad:
		for codigo in analista_dificultad.contador_incidencias_acumuladas:
			if analista_dificultad.contador_incidencias_acumuladas[codigo] > 0:
				codigos_dificultad.append(codigo)
	
	# Llamamos al modal de feedback. Si está vacío, él mismo emite la señal de salida.
	if modal_feedback:
		modal_feedback.mostrar_feedbacks(codigos_dificultad)
	else:
		_volver_al_menu()

func _volver_al_menu():
	# Redirigimos al flujo de salida seguro
	_intentar_salir(false)
