class_name JugadorGrid extends CharacterBody2D

# Configuración
const TIEMPO_MOVIMIENTO = 0.4 # Un poco más lento para apreciar el paso
const TIEMPO_GIRO = 0.3
const TIEMPO_PAUSA_INSTRUCCION = 0.1
const TIEMPO_ACCION = 0.5 # Tiempo de espera para recolectar/atacar

@export var camara: Camera2D

# Estado
var esta_actuando: bool = false
var pos_grid_actual: Vector2i = Vector2i.ZERO
var direccion_actual: Vector2i = Vector2i(0, 1) # (0, 1) es ARRIBA lógico
var inventario = { "monedas": 0, "llaves": 0 }

# --- SEÑALES ---
signal game_over_triggered(mensaje)
signal consola_mensaje_enviado(texto, tipo)

func _ready():
	# 1. Configuración Inicial de Posición
	pos_grid_actual = GridManager.world_to_grid(position)
	teletransportar_a(pos_grid_actual)
	rotation_degrees = 0
	
	# 2. --- LÍMITES DE LA CÁMARA ---
	if camara:
		# Límite Izquierdo y Superior: El inicio del mundo (0 pixels)
		camara.limit_left = -1
		camara.limit_top = -1
		# Derecha y Abajo: Sumamos 5 para ver el borde
		camara.limit_right = (GridManager.COLUMNAS_MAX * GridManager.TAMANO_CELDA) + 1
		camara.limit_bottom = (GridManager.FILAS_MAX * GridManager.TAMANO_CELDA) + 1

func _input(event):
	# Si ya estamos haciendo algo, ignoramos
	if esta_actuando:
		return
		
	# 1. Movimiento (Teclas de control para avanzar y girar)
	if event.is_action_pressed("ui_up"):
		avanzar()
	elif event.is_action_pressed("ui_right"):
		girar_derecha()
	# 2. Acciones de Prueba (Mapeo a Primitivas del GDD)
	# ui_accept (Espacio/Enter) -> Moneda
	elif event.is_action_pressed("recoger_moneda"): 
		recoger_moneda()
	# ui_select (Enter/Space alternativa) -> Llave
	elif event.is_action_pressed("recoger_llave"): 
		recoger_llave()
	# ui_focus_next (Tab) -> Cofre
	elif event.is_action_pressed("abrir_cofre"): 
		abrir_cofre()
	elif event.is_action_pressed("atacar"):
		atacar()
	elif event.is_action_pressed("saltar"):
		saltar()
	elif event.is_action_pressed("activar_puente"):
		activar_puente()

# --- ACCIONES PRINCIPALES ---

func avanzar():
	if esta_actuando: return
	esta_actuando = true
	# 1. Lógica de peligro (Si hay Enemigo, Game Over)
	if _verificar_peligro_inminente():
		await _esperar_muerte()
		return
		
	var celda_destino = pos_grid_actual + direccion_actual
	await mover_a_celda(celda_destino)
	await get_tree().create_timer(TIEMPO_PAUSA_INSTRUCCION).timeout
	return true

func girar_derecha():
	if esta_actuando: return
	esta_actuando = true
	
	# 1. CHEQUEO ANTES DE GIRAR
	if _verificar_peligro_inminente():
		return # Game Over si hay enemigo al frente
	
	# 2. Lógica Matemática del Giro (solo si es seguro)
	var nueva_x = direccion_actual.y
	var nueva_y = -direccion_actual.x
	direccion_actual = Vector2i(nueva_x, nueva_y)
	
	print("Girando. Nueva dirección: ", direccion_actual)
	
	# 3. Animación de Giro (Tween)
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", rotation_degrees + 90, TIEMPO_GIRO)
	await tween.finished
	esta_actuando = false
	await get_tree().create_timer(TIEMPO_PAUSA_INSTRUCCION).timeout

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Mapa / Teletransporte Seguro) ---
func intentar_teletransportar(celda_destino: Vector2i):
	if esta_actuando: return
	esta_actuando = true
	
	# 1. Validar Límites del Mapa
	# Usamos la función estática que ya tienes en GridManager
	if not GridManager.es_celda_valida(celda_destino):
		# Mostramos las coordenadas en Base 1 para que el alumno entienda el error
		var coord_user = celda_destino + Vector2i(1, 1)
		game_over("¡Error de Coordenadas! Intentaste ir a " + str(coord_user) + " pero está fuera del mapa.")
		await _esperar_muerte()
		return

	# 2. Si es válida, usamos la función existente para movernos
	teletransportar_a(celda_destino)
	
	# Pequeña pausa para mantener la consistencia del ritmo de ejecución
	await get_tree().create_timer(TIEMPO_PAUSA_INSTRUCCION).timeout
	esta_actuando = false
	return true

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Moneda) ---
func recoger_moneda():
	if esta_actuando: return
	esta_actuando = true
	
	# 1. Consultamos qué hay en mi celda actual
	var objeto = GridManager.obtener_objeto_en_celda(pos_grid_actual)
	
	# 2. Validaciones (Game Over)
	if objeto == null:
		game_over("Intentaste recoger una moneda, pero aquí no hay nada.")
		await _esperar_muerte()
		return
	
	if objeto.tipo != ElementoTablero.Tipo.MONEDA:
		var nombre_real = ElementoTablero.obtener_nombre_tipo(objeto.tipo)
		game_over("Intentaste recoger una moneda, pero aquí hay un " + nombre_real + ".")
		await _esperar_muerte()
		return
	
	# 3. Éxito: Recoger
	inventario["monedas"] += 1
	print("¡Moneda recogida! Monedas totales: ", inventario["monedas"])
	
	# Actualizar GridManager (ya no hay objeto aquí)
	GridManager.quitar_objeto(pos_grid_actual)
	
	# Visualmente borrar el objeto
	objeto.recoger()
	
	# Pequeña pausa para simular la acción
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Llave) ---
func recoger_llave():
	if esta_actuando: return
	esta_actuando = true
	
	var objeto = GridManager.obtener_objeto_en_celda(pos_grid_actual)
	
	if objeto == null:
		game_over("Intentaste recoger una llave, pero aquí no hay nada.")
		await _esperar_muerte()
		return
	
	if objeto.tipo != ElementoTablero.Tipo.LLAVE:
		var nombre_real = ElementoTablero.obtener_nombre_tipo(objeto.tipo)
		game_over("Intentaste recoger una llave, pero aquí hay un " + nombre_real + ".")
		await _esperar_muerte()
		return
	
	print("¡Llave recogida! Llaves totales: ", inventario["llaves"] + 1)
	inventario["llaves"] += 1
	GridManager.quitar_objeto(pos_grid_actual)
	objeto.recoger()
	
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Cofre) ---
func abrir_cofre():
	if esta_actuando: return
	esta_actuando = true
	
	var objeto = GridManager.obtener_objeto_en_celda(pos_grid_actual)
	
	# VALIDACIÓN 1: ¿Hay Cofre?
	if objeto == null or objeto.tipo != ElementoTablero.Tipo.COFRE:
		var nombre_real = ""
		if objeto: nombre_real = ElementoTablero.obtener_nombre_tipo(objeto.tipo)
		game_over("Intentaste abrir un cofre, pero aquí hay un " + nombre_real + ".")
		await _esperar_muerte()
		return
	
	# VALIDACIÓN 2: ¿Tienes Llave?
	if inventario["llaves"] <= 0:
		game_over("Intentaste abrir el cofre, ¡pero no tienes una llave!")
		await _esperar_muerte()
		return
		
	# Éxito: Abrir
	print("¡Cofre abierto!")
	inventario["llaves"] -= 1
	inventario["monedas"] += 5 # SUMA +5 MONEDAS (GDD)
	
	GridManager.quitar_objeto(pos_grid_actual)
	objeto.abrir_cofre() # Usa la función del ElementoTablero
	
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Atacar) ---
func atacar():
	if esta_actuando: return
	esta_actuando = true
	
	# 1. Calculamos la celda que está inmediatamente en frente
	var celda_objetivo = pos_grid_actual + direccion_actual
	var objeto = GridManager.obtener_objeto_en_celda(celda_objetivo)
	
	# 2. Validar
	if objeto == null or objeto.tipo != ElementoTablero.Tipo.ENEMIGO:
		game_over("Intentaste atacar, pero no hay enemigo en frente. Error de lógica SL-03.")
		await _esperar_muerte()
		return
	
	# 3. Éxito: Eliminar Enemigo
	print("¡Enemigo atacado y derrotado!")
	GridManager.quitar_objeto(celda_objetivo)
	objeto.recoger() # Usamos la animación de desaparecer temporalmente
	
	# Pausa para ver la acción
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Saltar) ---
func saltar():
	if esta_actuando: return
	esta_actuando = true
	
	# 1. Celda que está inmediatamente en frente (el Obstáculo)
	var celda_obstaculo = pos_grid_actual + direccion_actual
	var obstaculo = GridManager.obtener_objeto_en_celda(celda_obstaculo)
	
	# 2. Validar
	if obstaculo == null or obstaculo.tipo != ElementoTablero.Tipo.OBSTACULO:
		game_over("Intentaste saltar, pero no hay un obstáculo en frente. Error de lógica SL-03.")
		await _esperar_muerte()
		return
		
	# 3. Celda de aterrizaje (salta 2 casillas)
	var celda_destino = pos_grid_actual + (direccion_actual * 2)
	
	# Validar que el aterrizaje sea válido
	if not GridManager.es_celda_valida(celda_destino):
		game_over("¡Salto inválido! Fuera del mapa.")
		await _esperar_muerte()
		return

	# 4. Éxito: Movimiento de Salto (Tween complejo que simule salto)
	print("¡Saltando!")
	
	# Animación de salto simple (Mover Y arriba y luego abajo, mientras avanza X/Y)
	var destino_pixel = GridManager.grid_to_world(celda_destino)
	var tween = create_tween()
	
	# Animación Salto (Arco)
	tween.tween_property(self, "position:y", position.y - GridManager.TAMANO_CELDA, TIEMPO_MOVIMIENTO / 2)
	tween.tween_property(self, "position", destino_pixel, TIEMPO_MOVIMIENTO / 2).set_delay(TIEMPO_MOVIMIENTO / 4)
	
	# Actualizamos la posición lógica al final
	pos_grid_actual = celda_destino
	await tween.finished # Esperar animación
	esta_actuando = false
	return true

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Activar puente) ---
func activar_puente():
	if esta_actuando: return
	esta_actuando = true
	
	# 1. Celda en frente
	var celda_en_frente = pos_grid_actual + direccion_actual
	var objeto = GridManager.obtener_objeto_en_celda(celda_en_frente)
	
	# VALIDACIÓN 1: ¿Hay Puente?
	# Game Over si no hay puente o si hay otro objeto
	if objeto == null or objeto.tipo != ElementoTablero.Tipo.PUENTE:
		var nombre_real = ""
		if objeto: nombre_real = ElementoTablero.obtener_nombre_tipo(objeto.tipo)
		game_over("Intentaste activar el puente, pero aquí no hay un puente o es un " + nombre_real + ".")
		await _esperar_muerte()
		return

	# VALIDACIÓN 2: ¿Está ya activo? (No es Game Over, solo un aviso)
	if objeto.esta_activo:
		print("Puente ya activo, no es necesario gastar moneda.")
		await get_tree().create_timer(TIEMPO_ACCION).timeout
		esta_actuando = false
		return
		
	# VALIDACIÓN 3: ¿Tienes Moneda? (Game Over si no hay)
	if inventario["monedas"] <= 0:
		game_over("¡No tienes monedas para activar el puente!")
		await _esperar_muerte()
		return
		
	# Éxito: Activar Puente
	print("¡Puente activado! Moneda consumida.")
	inventario["monedas"] -= 1 # CONSUME UNA MONEDA
	objeto.activar() # Cambia el estado visual y lógico del puente
	
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Imprimir) ---
func imprimir(argumentos: Array):
	# Unimos todos los argumentos en un solo texto
	var texto_final = ""
	for item in argumentos:
		texto_final += str(item) + " "

	# Lo enviamos a la UI
	consola_mensaje_enviado.emit(texto_final, "OUTPUT")

	# Pequeña pausa estética
	await get_tree().create_timer(TIEMPO_ACCION).timeout

# --- PRIMITIVAS DE SENSOR ---
# Sensor para saber si hay un enemigo en la celda adyacente (en la dirección actual)
func hay_enemigo() -> bool:
	var celda_en_frente = pos_grid_actual + direccion_actual
	if not GridManager.es_celda_valida(celda_en_frente):
		return false
	
	var objeto = GridManager.obtener_objeto_en_celda(celda_en_frente)
	if objeto and objeto.tipo == ElementoTablero.Tipo.ENEMIGO:
		return true
	return false

# Sensor para saber si hay un obstáculo en la celda adyacente
func hay_obstaculo() -> bool:
	var celda_en_frente = pos_grid_actual + direccion_actual
	if not GridManager.es_celda_valida(celda_en_frente):
		return false
	
	var objeto = GridManager.obtener_objeto_en_celda(celda_en_frente)
	if objeto and objeto.tipo == ElementoTablero.Tipo.OBSTACULO:
		return true
	return false

# Sensor para saber si hay un puente en la celda adyacente
func hay_puente() -> bool:
	var celda_en_frente = pos_grid_actual + direccion_actual
	if not GridManager.es_celda_valida(celda_en_frente):
		return false
	
	var objeto = GridManager.obtener_objeto_en_celda(celda_en_frente)
	if objeto and objeto.tipo == ElementoTablero.Tipo.PUENTE:
		return true
	return false

# Sensor para saber si hay un cofre en la celda actual
func hay_cofre() -> bool:
	var objeto = GridManager.obtener_objeto_en_celda(pos_grid_actual)
	if objeto and objeto.tipo == ElementoTablero.Tipo.COFRE:
		return true
	return false
	
# Sensor para saber si hay una moneda en la celda actual
func hay_moneda() -> bool:
	var objeto = GridManager.obtener_objeto_en_celda(pos_grid_actual)
	if objeto and objeto.tipo == ElementoTablero.Tipo.MONEDA:
		return true
	return false

# Sensor para saber si hay una llave en la celda actual
func hay_llave() -> bool:
	var objeto = GridManager.obtener_objeto_en_celda(pos_grid_actual)
	if objeto and objeto.tipo == ElementoTablero.Tipo.LLAVE:
		return true
	return false

# Retorna el número de Sendero actual (Columna). Base 1.
func pos_sendero() -> int:
	return pos_grid_actual.x + 1

# Retorna el número de Valle actual (Fila). Base 1.
func pos_valle() -> int:
	return pos_grid_actual.y + 1

# Retorna verdadero si tiene al menos una moneda en el inventario
func tengo_moneda() -> bool:
	return inventario["monedas"] > 0

# Retorna verdadero si tiene al menos una llave en el inventario
func tengo_llave() -> bool:
	return inventario["llaves"] > 0

# --- MOVIMIENTO INTERNO Y UTILIDADES ---
func mover_a_celda(celda_destino: Vector2i):
	# 1. Validar límites
	if not GridManager.es_celda_valida(celda_destino):
		# Llamamos a game_over y luego retornamos.
		game_over("¡Choque con el límite del mapa! Error de secuencia.")
		await _esperar_muerte()
		return
	
	# 2. Iniciar movimiento
	print("avanzando...")
	pos_grid_actual = celda_destino # Actualizamos lógica ya
	var destino_pixel = GridManager.grid_to_world(celda_destino)
	var tween = create_tween()
	tween.tween_property(self, "position", destino_pixel, TIEMPO_MOVIMIENTO)
	await tween.finished
	print("ya avanzó...")
	esta_actuando = false

func teletransportar_a(celda_destino: Vector2i):
	pos_grid_actual = celda_destino
	position = GridManager.grid_to_world(celda_destino)
	esta_actuando = false
	# Resetear rotación y dirección al inicio (Mirando arriba)
	rotation_degrees = 0
	direccion_actual = Vector2i(0, 1)

# --- NUEVA FUNCIÓN DE VERIFICACIÓN (Peligro Enemigo/Obstáculo) ---
func _verificar_peligro_inminente() -> bool:
	# 1. Celda en frente
	var celda_en_frente = pos_grid_actual + direccion_actual
	
	# Si no es celda válida (límites), no hay peligro, lo maneja mover_a_celda.
	if not GridManager.es_celda_valida(celda_en_frente):
		return false
		
	var objeto = GridManager.obtener_objeto_en_celda(celda_en_frente)
	
	if objeto:
		# --- Peligro 1: Enemigo al frente (Choque) ---
		if objeto.tipo == ElementoTablero.Tipo.ENEMIGO:
			# Si llegamos aquí, el jugador intentó avanzar, saltar, o girar (si lo permitiéramos)
			# mientras tenía un enemigo en frente.
			game_over("¡El enemigo te ha detectado y atacado! Debes usar 'atacar'.")
			return true
			
		# --- Peligro 2: Obstáculo al frente (Choque) ---
		elif objeto.tipo == ElementoTablero.Tipo.OBSTACULO:
			# Si llegamos aquí, intentó avanzar, lo cual está prohibido
			game_over("¡Choque con Obstáculo! Debes usar la instrucción 'saltar'.")
			return true
			
		# --- Peligro 3: Puente Inactivo al frente ---
		elif objeto.tipo == ElementoTablero.Tipo.PUENTE:
			if not objeto.esta_activo:
				game_over("¡Puente inactivo! Debes activarlo con la instrucción 'activarPuente'.")
				return true

	return false

# --- MANEJO DE GAME OVER ---
func game_over(razon: String):
	if esta_actuando == false:
		return 
		
	print("GAME OVER: ", razon)
	esta_actuando = true 
	
	# 1. Emitir señal para que el Ejecutor sepa que falló el código
	game_over_triggered.emit(razon) 

# Función para congelar la ejecución mientras esperamos que el controlador reinicie el nivel
func _esperar_muerte():
	# Esperamos 10 segundos (tiempo de sobra para que queue_free elimine el nodo)
	await get_tree().create_timer(10.0).timeout
