extends Node2D

# --- REFERENCIAS ---
@export var tablero: Node2D
@export var mapa_visual: TileMapLayer
@export var jugador: CharacterBody2D
@export var entidades_container: Node2D
var analista_dificultad: AnalistaDificultad

# UI Referencias
@export var label_mision: Label
@export var label_dificultad: Label
@export var label_descripcion: Label
@export var code_edit: CodeEdit
@export var boton_ejecutar: Button
@export var consola_visual: RichTextLabel

@export var ejecutor: Node
@export var timer_reinicio: Timer

# Estado del juego
var ejecutando_codigo: bool = false
var sandbox: bool = true
var juego_fallido: bool = false # Bandera para abortar secuencia si hay Game Over
var intentos_totales: int = 0

# --- SISTEMA DE MISIONES ---
var mision_actual_def: DefinicionMision = null
var caso_actual_idx: int = 0
var logs_consola: Array[String] = [] # Para verificar condiciones de Output

# Precargamos la escena del elemento
var elemento_escena = preload("res://scenes/elemento_tablero/elemento_tablero.tscn")

func _ready():
	GridManager.limpiar_datos() 
	
	# 1. Configurar el Ejecutor
	ejecutor.personaje = jugador
	ejecutor.controlador_nivel = self
	
	# 2. Conexiones
	if not boton_ejecutar.pressed.is_connected(_on_ejecutar_pressed):
		boton_ejecutar.pressed.connect(_on_ejecutar_pressed)
	
	timer_reinicio.one_shot = true
	if not timer_reinicio.timeout.is_connected(_on_reiniciar_mision):
		timer_reinicio.timeout.connect(_on_reiniciar_mision)
		
	if not jugador.game_over_triggered.is_connected(_on_jugador_game_over):
		jugador.game_over_triggered.connect(_on_jugador_game_over)
		
	if not jugador.consola_mensaje_enviado.is_connected(agregar_mensaje_consola):
		jugador.consola_mensaje_enviado.connect(agregar_mensaje_consola)
	
	if not sandbox:
		analista_dificultad = AnalistaDificultad.new()
		add_child(analista_dificultad)
		
		# Conectarlo con el jugador
		jugador.analista = analista_dificultad
	else:
		print("--- Modo Sandbox: Analista de Dificultad DESACTIVADO ---")
	
	# Verificamos si hay una misión pendiente en el Singleton
	if GameData.mision_seleccionada != null:
		cargar_mision(GameData.mision_seleccionada)
		# Limpiamos la variable para no recargarla por error si volvemos al menú y entramos a otro lado
		GameData.mision_seleccionada = null
	elif sandbox:
		jugador.teletransportar_a(Vector2i(0, 0))
	else:
		_cargar_mision_prueba()

# --- CARGA DE MISIÓN ---

func cargar_mision(definicion: DefinicionMision):
	mision_actual_def = definicion
	intentos_totales = 0
	
	print("--- DEBUG DESCRIPCIÓN ---")
	print(definicion.descripcion) # <-- Mira esto en la consola de Godot
	print("-------------------------")
	
	# Actualizar UI
	label_mision.text = definicion.titulo
	label_dificultad.text = definicion.dificultad
	label_descripcion.text = definicion.descripcion
	
	# Preparamos el primer caso de prueba visualmente para que el alumno vea el escenario 1
	_preparar_caso_prueba(0)

func _cargar_mision_compleja():
	var caso = CasoPruebaMision.new()
	caso.agregar_elemento(ElementoTablero.Tipo.LLAVE, Vector2i(0, 2))
	caso.agregar_elemento(ElementoTablero.Tipo.LLAVE, Vector2i(0, 4))
	
	# 1. Debe tener 2 llaves físicas
	caso.agregar_condicion(CondicionMision.Recolectar.new("llaves", 2))
	
	# 2. Debe tener una variable "contador" con valor 2
	caso.agregar_condicion(CondicionMision.VariableTieneValor.new("contador", 2))
	
	# 3. Debe imprimirlo
	caso.agregar_condicion(CondicionMision.OutputContiene.new("2"))
	
	var mision = DefinicionMision.new()
	mision.titulo = "Desafío de Variables"
	mision.descripcion = "Recoge las llaves y cuéntalas en una variable llamada 'contador'."
	mision.casos_de_prueba.append(caso)
	cargar_mision(mision)

func _cargar_mision_prueba():
	randomize()
	print("--- GENERANDO MISIÓN COMPLEJA ---")
	
	# Prueba con Dificultad Media para ver variables y enemigos
	var mision = GeneradorMisiones.generar_mision_compleja(GeneradorMisiones.DIFICULTAD_DIFICIL)
	
	cargar_mision(mision)

func _preparar_caso_prueba(indice: int):
	if mision_actual_def == null or indice >= mision_actual_def.casos_de_prueba.size():
		return
		
	var caso = mision_actual_def.casos_de_prueba[indice]
	
	# 1. Limpiar escenario anterior
	_limpiar_entidades()
	GridManager.limpiar_datos()
	logs_consola.clear()
	
	# 2. Reiniciar Jugador
	jugador.inventario.monedas = 0
	jugador.inventario.llaves = 0
	jugador.teletransportar_a(caso.inicio_jugador)
	# TODO: Soportar dirección inicial si se define en el caso
	
	# 3. Spawnear Elementos
	for item_data in caso.elementos_mapa:
		spawn_elemento(item_data["pos"], item_data["tipo"])
		
	agregar_mensaje_consola("--- Cargando Caso de Prueba " + str(indice + 1) + " ---", "SISTEMA")

func _limpiar_entidades():
	for child in entidades_container.get_children():
		if child != jugador: 
			child.queue_free()

# --- PREPARACIÓN DEL ESCENARIO ---
func spawn_elemento(pos: Vector2i, tipo):
	var nuevo_elemento = elemento_escena.instantiate()
	entidades_container.add_child(nuevo_elemento)
	
	# Configuramos visual y lógicamente
	nuevo_elemento.configurar(tipo, pos)
	
	# Registramos en la memoria del GridManager
	GridManager.registrar_objeto(pos, nuevo_elemento)

# --- LÓGICA DE EJECUCIÓN (TEST RUNNER) ---
func _on_ejecutar_pressed():
	if ejecutando_codigo: return # Ya está corriendo, no hacer nada
	
	intentos_totales += 1
	
	print("--- INICIANDO INTENTO #", intentos_totales, " ---") # Log para debug
	
	limpiar_errores_editor()
	limpiar_consola_visual()
	
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
	
	# Pequeña pausa para que se asienten los nodos
	await get_tree().process_frame
	
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
	
	# 1. Calcular Recompensas con la nueva lógica
	var resultado = calcular_resultado_final()
	var estrellas_finales = resultado["estrellas"]
	var exp_final = resultado["exp"]
	
	print("Recompensas Base -> Estrellas: ", estrellas_finales, " | XP: ", exp_final)
	
	# 2. Guardado en BD y Lógica Diferenciada
	if mision_actual_def:
		# --- RAMA A: MISIÓN ESPECIAL ---
		if mision_actual_def.es_mision_especial:
			agregar_mensaje_consola("¡BONUS MISIÓN ESPECIAL! (x2 Recompensas)", "SISTEMA")
			
			# Multiplicar recompensas
			estrellas_finales *= 2 
			exp_final *= 2
			
			DatabaseManager.registrar_mision_especial_local(
				mision_actual_def.titulo,
				mision_actual_def.descripcion,
				estrellas_finales,
				exp_final,
				intentos_totales
			)
		# --- RAMA B: MISIÓN NORMAL ---
		else:
			DatabaseManager.registrar_mision_local(
				mision_actual_def.id, 
				estrellas_finales, 
				exp_final, 
				intentos_totales
			)
		
		# 3. Procesar Dificultades para ambos tipos de misión
		if analista_dificultad:
			analista_dificultad.procesar_resultados_finales()
		
		# 4. Intentamos hacer la sincronización Automática
		GestorSincronizacion.sincronizar_pendientes()
	
	print("Resultado FINAL -> Estrellas: ", estrellas_finales, " | XP: ", exp_final)
	
	# 5. MOSTRAR POPUP DE VICTORIA
	await get_tree().create_timer(1.0).timeout
	mostrar_popup_victoria(estrellas_finales, exp_final)

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
		
		# Consolidamos el intento fallido
		analista_dificultad.consolidar_intento_actual()
	
	# 4. Iniciar el timer de reinicio
	print("Iniciando reinicio por Game Over...")
	if timer_reinicio.is_stopped():
		timer_reinicio.start(3.0)

func agregar_mensaje_consola(mensaje: String, tipo: String = "NORMAL"):
	logs_consola.append(mensaje) # Guardamos para validación (OutputContiene)
	
	if not consola_visual: return
	
	var color_hex = "#FFFFFF"
	var prefijo = "> "
	
	match tipo:
		"ERROR":
			color_hex = "#FF5555"
			prefijo = "[ERROR] "
		"OUTPUT":
			color_hex = "#55FFFF"
			prefijo = ""
		"SISTEMA":
			color_hex = "#FFFF55"
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

func _obtener_xp_base(dificultad: String) -> int:
	# Normalizamos el string por si acaso (ej: "Fácil" vs "Facil")
	var dif = dificultad.to_lower()
	
	if "facil" in dif or "fácil" in dif:
		return 250
	elif "media" in dif or "medio" in dif:
		return 500
	elif "dificil" in dif or "difícil" in dif:
		return 750
	
	# Valor por defecto si no coincide
	return 250

func calcular_resultado_final() -> Dictionary:
	# 1. Configuración Base
	var estrellas = 3
	# Obtenemos la base según la dificultad definida en el recurso de la misión
	var xp_base = _obtener_xp_base(mision_actual_def.dificultad)
	
	# 2. Penalización por Intentos (NUEVA FÓRMULA)
	# 1 a 3 intentos: -0
	# 4 a 6 intentos: -1
	# +7 intentos: -2
	if intentos_totales <= 3:
		pass # Perfecto (0 penalización)
	elif intentos_totales <= 6:
		estrellas -= 1
		print("Evaluación: -1 Estrella por intentos (", intentos_totales, ")")
	else:
		estrellas -= 2
		print("Evaluación: -2 Estrellas por intentos (", intentos_totales, ")")
	
	# 3. Penalización por "Buenas Prácticas" (Analista)
	if analista_dificultad:
		var total_errores = analista_dificultad.obtener_total_errores()
		var errores_graves = analista_dificultad.hay_errores_graves()
		
		# Si hay errores graves o más de 3 errores leves acumulados
		if total_errores > 3 or errores_graves:
			estrellas -= 1
			print("Evaluación: -1 Estrella por calidad de código (Errores: ", total_errores, ")")

	# 4. Clamp (Mínimo 1, Máximo 3)
	# Aunque penalicemos mucho, si completó la misión, merece 1 estrella.
	if estrellas < 1: estrellas = 1
	if estrellas > 3: estrellas = 3
	
	# 5. Cálculo de XP (NUEVA FÓRMULA)
	# Fórmula: XP Final = Base * (Estrellas / 2)
	# Usamos float para que la división no trunque decimales (ej: 3/2 = 1.5)
	var factor_estrellas = float(estrellas) / 2.0
	var xp_final = int(xp_base * factor_estrellas)
	
	print("Cálculo XP: Base(", xp_base, ") * Factor(", factor_estrellas, ") = ", xp_final)
		
	return {"estrellas": estrellas, "exp": xp_final}

# --- UI DE VICTORIA ---

func mostrar_popup_victoria(estrellas: int, xp: int):
	# 1. Creamos el diálogo al vuelo
	var popup = AcceptDialog.new()
	popup.title = "¡MISIÓN COMPLETADA!"
	
	# 2. Construimos el mensaje
	var mensaje = "¡Felicitaciones! Has completado la misión.\n\n"
	mensaje += "Recompensas obtenidas:\n"
	mensaje += "⭐ Estrellas: " + str(estrellas) + "\n"
	mensaje += "✨ Experiencia: " + str(xp) + " XP"
	
	# Mensaje especial si hubo bonus
	if mision_actual_def and mision_actual_def.es_mision_especial:
		mensaje += "\n\n(¡Incluye Bonus x2 por Misión Especial!)"
	
	popup.dialog_text = mensaje
	popup.ok_button_text = "Continuar"
	
	# 3. Importante: Conectar la señal para irse al menú cuando cierre
	# Usamos 'confirmed' (botón OK) y 'canceled' (botón X) por seguridad
	popup.confirmed.connect(_volver_al_menu)
	popup.canceled.connect(_volver_al_menu)
	
	# 4. Lo agregamos a la escena y lo mostramos
	add_child(popup)
	popup.popup_centered()

func _volver_al_menu():
	print("Regresando al selector de misiones...")
	# Asegúrate de que esta ruta sea correcta en tu proyecto
	get_tree().change_scene_to_file("res://scenes/selector_misiones/selector_misiones.tscn")
