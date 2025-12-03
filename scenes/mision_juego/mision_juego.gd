extends Node2D

# --- REFERENCIAS ---
@export var tablero: Node2D
@export var mapa_visual: TileMapLayer
@export var jugador: CharacterBody2D
@export var entidades_container: Node2D

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
	
	# Cargar sandbox si se quiere
	if sandbox:
		jugador.teletransportar_a(Vector2i(0, 0))
		# --- ESCENARIO PARA TEST INTEGRAL ---
		
		# 1. Moneda en el mismo lugar de inicio (0,0)
		# Prueba: Si hayMoneda -> recogerMoneda
		spawn_elemento(Vector2i(0, 0), ElementoTablero.Tipo.MONEDA)
		
		# 2. Enemigo en frente (0,1)
		# Prueba: Si hayEnemigo -> atacar -> avanzar
		spawn_elemento(Vector2i(0, 1), ElementoTablero.Tipo.ENEMIGO)
		
		# 3. Obstáculo en (0,2)
		# Nota: Cuando el jugador avance a (0,1) tras matar al enemigo,
		# el obstáculo quedará en frente.
		# Prueba: Si hayObstaculo -> saltar (cae en 0,3)
		spawn_elemento(Vector2i(0, 2), ElementoTablero.Tipo.OBSTACULO)
		
		# 4. Moneda en el aterrizaje (0,3)
		spawn_elemento(Vector2i(0, 3), ElementoTablero.Tipo.MONEDA)
		
		# 5. Extras para pruebas manuales (Llave y Cofre) en el Sendero 2
		# (Para probar 'mapa(2,1)' si quisieras)
		spawn_elemento(Vector2i(1, 0), ElementoTablero.Tipo.LLAVE)
		spawn_elemento(Vector2i(1, 1), ElementoTablero.Tipo.COFRE)
	# 3. Cargar Misión de Prueba (Temporal, luego vendrá del menú)
	else:
		_cargar_mision_prueba()

# --- CARGA DE MISIÓN ---

func cargar_mision(definicion: DefinicionMision):
	mision_actual_def = definicion
	
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
	
	limpiar_errores_editor()
	limpiar_consola_visual()
	
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
	print("VICTORIA TOTAL")
	ejecutando_codigo = false
	boton_ejecutar.disabled = false
	# Aquí guardarías el progreso en la BD local

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
	
	# 3. Iniciar el timer de reinicio
	print("Iniciando reinicio por Game Over...")
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
