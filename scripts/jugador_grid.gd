class_name JugadorGrid extends CharacterBody2D

# Configuración
const TIEMPO_MOVIMIENTO = 0.8 # Sincronizado con la animación (8 frames * 0.1s)
const TIEMPO_GIRO = 0.3
const TIEMPO_PAUSA_INSTRUCCION = 0.8
const TIEMPO_ACCION = 0.8 # Tiempo de espera para recolectar/atacar

@export var camara: Camera2D
@export var anim_player: AnimationPlayer
@export var sprite_personaje: Sprite2D

# Estado
var escala_inicial: Vector2
var esta_actuando: bool = false
var posicion_actual: Vector2i = Vector2i.ZERO
var direccion_actual: Vector2i = Vector2i(0, 1) # (0, 1) es ARRIBA lógico
var inventario = {"monedas": 0, "llaves": 0, "cofres": 0}
var analista: AnalistaDificultad = null
var _tween_movimiento: Tween = null
var _ultimo_fue_avanzar: bool = false

# --- SEÑALES ---
signal game_over_triggered(mensaje)
signal consola_mensaje_enviado(texto, tipo)

func _ready():
	# 1. Configuración Inicial de Posición
	escala_inicial = scale
	posicion_actual = GridManager.world_to_grid(position)
	teletransportar_a(posicion_actual)
	
	# 2. --- LÍMITES DE LA CÁMARA ---
	if camara:
		# Límite Izquierdo y Superior: El inicio del mundo (0 pixels)
		camara.limit_left = -1
		camara.limit_top = -1
		# Derecha y Abajo: Sumamos 5 para ver el borde
		camara.limit_right = (GridManager.COLUMNAS_MAX * GridManager.TAMANO_CELDA) + 1
		camara.limit_bottom = (GridManager.FILAS_MAX * GridManager.TAMANO_CELDA) + 1

func reiniciar_inventario():
	inventario = {"monedas": 0, "llaves": 0, "cofres": 0}

# --- ACCIONES PRINCIPALES ---

func avanzar():
	if esta_actuando: return
	esta_actuando = true
	# 1. Lógica de peligro (Si hay Enemigo, Game Over)
	if await _verificar_peligro_inminente(true):
		await _esperar_muerte()
		return
		
	var celda_destino = posicion_actual + direccion_actual
	_reproducir_anim("caminar")
	await mover_a_celda(celda_destino)
	_actualizar_idle()
	_ultimo_fue_avanzar = true
	return true

func girar_derecha():
	if esta_actuando: return
	esta_actuando = true

	# PAUSA INICIAL: Detenerse antes de girar
	_actualizar_idle()
	if _ultimo_fue_avanzar:
		await get_tree().create_timer(TIEMPO_PAUSA_INSTRUCCION).timeout
	
	
	# 1. CHEQUEO ANTES DE GIRAR
	if await _verificar_peligro_inminente(false):
		return # Game Over si hay enemigo al frente
	
	# 2. Lógica Matemática del Giro (solo si es seguro)
	var nueva_x = direccion_actual.y
	var nueva_y = - direccion_actual.x
	direccion_actual = Vector2i(nueva_x, nueva_y)
	
	print("Girando. Nueva dirección: ", direccion_actual)
	
	# 3. Actualizar animación a la nueva dirección (Idle)
	_actualizar_idle()
	_ultimo_fue_avanzar = false
	await get_tree().create_timer(TIEMPO_PAUSA_INSTRUCCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Mapa / Teletransporte Seguro) ---
func intentar_teletransportar(celda_destino: Vector2i):
	if esta_actuando: return
	esta_actuando = true
	
	# 1. Validar Límites del Mapa
	# Usamos la función estática que ya tienes en GridManager
	if not GridManager.es_celda_valida(celda_destino):
		# Mostramos las coordenadas en Base 1 para que el alumno entienda el error
		var coord_user = celda_destino + Vector2i(1, 1)
		game_over("¡Error de Coordenadas! Intentaste ir a " + str(coord_user) + " pero está fuera del mapa. [LIMIT_CRASH]")
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
	if analista: analista.registrar_accion("recogerMoneda")
	if esta_actuando: return
	esta_actuando = true
	_actualizar_idle()
	
	# 1. Buscamos específicamente una MONEDA en la celda actual
	var objeto = GridManager.buscar_objeto_por_tipo(posicion_actual, ElementoTablero.Tipo.MONEDA)
	
	# 2. Validaciones (Game Over)
	if objeto == null:
		# Feedback mejorado: Si no hay moneda, vemos si hay otra cosa para dar un mensaje útil
		var otro = GridManager.obtener_objeto_en_celda(posicion_actual)
		if otro:
			var nombre_real = ElementoTablero.obtener_nombre_tipo(otro.tipo)
			consola_mensaje_enviado.emit("Intentaste recoger una moneda, pero aquí hay un " + nombre_real + ".", "ADVERTENCIA")
		else:
			consola_mensaje_enviado.emit("Intentaste recoger una moneda, pero aquí no hay nada.", "ADVERTENCIA")
			
		await get_tree().create_timer(0.5).timeout
		esta_actuando = false
		return
	
	# 3. Éxito: Recoger
	inventario["monedas"] += 1
	print("¡Moneda recogida! Monedas totales: ", inventario["monedas"])
	
	# Actualizar GridManager (ya no hay objeto aquí)
	GridManager.quitar_objeto(posicion_actual, objeto)
	
	# Visualmente borrar el objeto
	objeto.recoger()
	
	# Pequeña pausa para simular la acción
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Llave) ---
func recoger_llave():
	if analista: analista.registrar_accion("recogerLlave")
	if esta_actuando: return
	esta_actuando = true
	_actualizar_idle()
	
	var objeto = GridManager.buscar_objeto_por_tipo(posicion_actual, ElementoTablero.Tipo.LLAVE)
	
	if objeto == null:
		var otro = GridManager.obtener_objeto_en_celda(posicion_actual)
		if otro:
			var nombre_real = ElementoTablero.obtener_nombre_tipo(otro.tipo)
			consola_mensaje_enviado.emit("Intentaste recoger una llave, pero aquí hay un " + nombre_real + ".", "ADVERTENCIA")
		else:
			consola_mensaje_enviado.emit("Intentaste recoger una llave, pero aquí no hay nada.", "ADVERTENCIA")
			
		await get_tree().create_timer(0.5).timeout
		esta_actuando = false
		return
	
	print("¡Llave recogida! Llaves totales: ", inventario["llaves"] + 1)
	inventario["llaves"] += 1
	GridManager.quitar_objeto(posicion_actual, objeto)
	objeto.recoger()
	
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Cofre) ---
func abrir_cofre():
	if analista: analista.registrar_accion("abrirCofre")
	if esta_actuando: return
	esta_actuando = true
	_actualizar_idle()
	
	var objeto = GridManager.buscar_objeto_por_tipo(posicion_actual, ElementoTablero.Tipo.COFRE)
	
	# VALIDACIÓN 1: ¿Hay Cofre?
	if objeto == null:
		consola_mensaje_enviado.emit("Intentaste abrir un cofre, pero aquí no hay cofre.", "ADVERTENCIA")
		await get_tree().create_timer(0.5).timeout
		esta_actuando = false
		return
	
	# VALIDACIÓN 2: ¿Tienes Llave?
	if inventario["llaves"] <= 0:
		consola_mensaje_enviado.emit("El cofre está cerrado y no tienes llave.", "ADVERTENCIA")
		await get_tree().create_timer(0.5).timeout
		esta_actuando = false
		return
		
	# Éxito: Abrir
	print("¡Cofre abierto!")
	inventario["llaves"] -= 1
	inventario["monedas"] += 5 # SUMA +5 MONEDAS (GDD)
	inventario["cofres"] += 1
	
	GridManager.quitar_objeto(posicion_actual, objeto)
	objeto.abrir_cofre() # Usa la función del ElementoTablero
	
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Atacar) ---
func atacar():
	if analista: analista.registrar_accion("atacar")
	if esta_actuando: return
	esta_actuando = true

	# PAUSA INICIAL
	_actualizar_idle()
	if _ultimo_fue_avanzar:
		await get_tree().create_timer(TIEMPO_PAUSA_INSTRUCCION).timeout
	
	# 1. Calculamos la celda que está inmediatamente en frente
	var celda_objetivo = posicion_actual + direccion_actual
	var objeto = GridManager.buscar_objeto_por_tipo(celda_objetivo, ElementoTablero.Tipo.ENEMIGO)
	
	# 2. Validar
	if objeto == null:
		consola_mensaje_enviado.emit("Atacaste al aire. No hay enemigos.", "ADVERTENCIA")
		# Ejecutamos la animación igual para dar feedback visual
		_reproducir_anim("atacar")
		await get_tree().create_timer(TIEMPO_ACCION).timeout
		_actualizar_idle()
		esta_actuando = false
		await get_tree().create_timer(TIEMPO_ACCION).timeout
		return
	
	# 3. Éxito: Eliminar Enemigo
	print("¡Enemigo atacado y derrotado!")
	_reproducir_anim("atacar")
	# Sincronización: Esperamos 0.3s para que el golpe "conecte" visualmente antes de borrar al enemigo
	GridManager.quitar_objeto(celda_objetivo, objeto)
	objeto.recoger(0.3)
	_ultimo_fue_avanzar = false
	
	# Pausa para ver la acción
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	_actualizar_idle()
	await get_tree().create_timer(TIEMPO_ACCION).timeout
	esta_actuando = false

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Saltar) ---
func saltar():
	if analista: analista.registrar_accion("saltar")
	if esta_actuando: return
	esta_actuando = true

	# PAUSA INICIAL
	_actualizar_idle()
	if _ultimo_fue_avanzar:
		await get_tree().create_timer(TIEMPO_PAUSA_INSTRUCCION).timeout
	
	# 1. Celda que está inmediatamente en frente (el Obstáculo)
	var celda_obstaculo = posicion_actual + direccion_actual
	var obstaculo = GridManager.buscar_objeto_por_tipo(celda_obstaculo, ElementoTablero.Tipo.OBSTACULO)
	var enemigo = GridManager.buscar_objeto_por_tipo(celda_obstaculo, ElementoTablero.Tipo.ENEMIGO)
	
	# NUEVO: Si es enemigo, muere con animación
	if enemigo:
		if enemigo.has_method("reproducir_ataque"):
			enemigo.reproducir_ataque()
		
		await get_tree().create_timer(0.3).timeout
		var tween = create_tween()
		tween.tween_property(self , "scale", Vector2.ZERO, 0.5)
		await get_tree().create_timer(0.5).timeout
		
		game_over("¡Intentaste saltar sobre un enemigo! Te ha atacado.")
		await _esperar_muerte()
		return

	# 2. Validar
	if obstaculo == null:
		consola_mensaje_enviado.emit("No hay obstáculo para saltar.", "ADVERTENCIA")
		# Pequeño salto en el lugar (feedback visual)
		_reproducir_anim("caminar")
		if sprite_personaje:
			var tween_arc = create_tween()
			var altura_salto = 12
			tween_arc.tween_property(sprite_personaje, "position:y", -altura_salto, TIEMPO_MOVIMIENTO / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween_arc.tween_property(sprite_personaje, "position:y", 0, TIEMPO_MOVIMIENTO / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(TIEMPO_MOVIMIENTO).timeout
		_actualizar_idle()
		await get_tree().create_timer(TIEMPO_MOVIMIENTO).timeout
		esta_actuando = false
		return true
		
	# 3. Celda de aterrizaje (salta 2 casillas)
	var celda_destino = posicion_actual + (direccion_actual * 2)
	
	# Validar que el aterrizaje sea válido
	if not GridManager.es_celda_valida(celda_destino):
		game_over("¡Salto inválido! Fuera del mapa.")
		await _esperar_muerte()
		return

	# 4. Éxito: Movimiento de Salto (Tween complejo que simule salto)
	print("¡Saltando!")
	# Como no hay animación de salto, usamos caminar
	_reproducir_anim("caminar")
	
	# Animación de salto simple (Mover Y arriba y luego abajo, mientras avanza X/Y)
	var destino_pixel = GridManager.grid_to_world(celda_destino)
	
	if _tween_movimiento and _tween_movimiento.is_valid():
		_tween_movimiento.kill()
	_tween_movimiento = create_tween()
	
	# Movimiento lineal hacia el destino
	_tween_movimiento.tween_property(self , "position", destino_pixel, TIEMPO_MOVIMIENTO)
	
	# Simulación de arco de salto (Moviendo el sprite localmente hacia arriba y abajo)
	if sprite_personaje:
		var tween_arc = create_tween()
		var altura_salto = 24 # Pixeles hacia arriba
		tween_arc.tween_property(sprite_personaje, "position:y", -altura_salto, TIEMPO_MOVIMIENTO / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_arc.tween_property(sprite_personaje, "position:y", 0, TIEMPO_MOVIMIENTO / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Actualizamos la posición lógica al final
	posicion_actual = celda_destino
	await _tween_movimiento.finished # Esperar animación
	# PAUSA FINAL (Aterrizaje)
	_actualizar_idle()
	_ultimo_fue_avanzar = false
	await get_tree().create_timer(TIEMPO_PAUSA_INSTRUCCION).timeout
	esta_actuando = false
	return true

# --- PRIMITIVAS DEL PSEUDOCÓDIGO (Activar puente) ---
func activar_puente():
	if analista: analista.registrar_accion("activarPuente")
	if esta_actuando: return
	esta_actuando = true
	_actualizar_idle()
	
	# 1. Celda en frente
	var celda_en_frente = posicion_actual + direccion_actual
	var objeto = GridManager.buscar_objeto_por_tipo(celda_en_frente, ElementoTablero.Tipo.PUENTE)
	
	# VALIDACIÓN 1: ¿Hay Puente?
	if objeto == null:
		consola_mensaje_enviado.emit("No hay puente aquí para activar.", "ADVERTENCIA")
		await get_tree().create_timer(0.5).timeout
		esta_actuando = false
		return

	# VALIDACIÓN 2: ¿Está ya activo? (No es Game Over, solo un aviso)
	if objeto.esta_activo:
		consola_mensaje_enviado.emit("El puente ya está activo.", "ADVERTENCIA")
		await get_tree().create_timer(0.5).timeout
		esta_actuando = false
		return
		
	# VALIDACIÓN 3: ¿Tienes Moneda? (Game Over si no hay)
	if inventario["monedas"] <= 0:
		consola_mensaje_enviado.emit("Necesitas una moneda para activar el puente.", "ADVERTENCIA")
		await get_tree().create_timer(0.5).timeout
		esta_actuando = false
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

# ----- SENSORES DEL ENTORNO ----- #

# Sensor para saber si hay una moneda en la celda actual
func hay_moneda() -> bool:
	var objeto = GridManager.buscar_objeto_por_tipo(posicion_actual, ElementoTablero.Tipo.MONEDA)
	var res = (objeto != null)
	if analista: analista.registrar_validacion("moneda", res)
	return res

# Sensor para saber si hay una llave en la celda actual
func hay_llave() -> bool:
	var objeto = GridManager.buscar_objeto_por_tipo(posicion_actual, ElementoTablero.Tipo.LLAVE)
	var res = (objeto != null)
	if analista: analista.registrar_validacion("llave", res)
	return res

# Sensor para saber si hay un cofre en la celda actual
func hay_cofre() -> bool:
	var objeto = GridManager.buscar_objeto_por_tipo(posicion_actual, ElementoTablero.Tipo.COFRE)
	var res = (objeto != null)
	if analista: analista.registrar_validacion("cofre", res)
	return res

# Sensor para saber si hay un enemigo en la celda adyacente (en la dirección actual)
func hay_enemigo() -> bool:
	var pos_target = posicion_actual + direccion_actual
	var objeto = GridManager.buscar_objeto_por_tipo(pos_target, ElementoTablero.Tipo.ENEMIGO)
	var res = (objeto != null)
	if analista: analista.registrar_validacion("enemigo", res)
	return res

# Sensor para saber si hay un obstáculo en la celda adyacente
func hay_obstaculo() -> bool:
	var pos_target = posicion_actual + direccion_actual
	var objeto = GridManager.buscar_objeto_por_tipo(pos_target, ElementoTablero.Tipo.OBSTACULO)
	var res = (objeto != null)
	if analista: analista.registrar_validacion("obstaculo", res)
	return res

# Sensor para saber si hay un puente en la celda adyacente
func hay_puente() -> bool:
	var pos_target = posicion_actual + direccion_actual
	var objeto = GridManager.buscar_objeto_por_tipo(pos_target, ElementoTablero.Tipo.PUENTE)
	var res = (objeto != null)
	if analista: analista.registrar_validacion("puente", res)
	return res

# ----- SENSORES DE INVENTARIO ----- #

# Retorna verdadero si tiene al menos una moneda en el inventario
func tengo_moneda() -> bool:
	var res = inventario.monedas > 0
	if analista: analista.registrar_validacion("moneda", res) # Reutilizamos etiqueta "moneda" o usa "tengoMoneda" si prefieres diferenciar
	return res

# Retorna verdadero si tiene al menos una llave en el inventario
func tengo_llave() -> bool:
	var res = inventario.llaves > 0
	if analista: analista.registrar_validacion("llave", res)
	return res

# Retorna el número de Sendero actual (Columna). Base 1.
func pos_sendero() -> int:
	return posicion_actual.x + 1

# Retorna el número de Valle actual (Fila). Base 1.
func pos_valle() -> int:
	return posicion_actual.y + 1

# --- MOVIMIENTO INTERNO Y UTILIDADES ---
func mover_a_celda(celda_destino: Vector2i):
	# 1. Validar límites
	if not GridManager.es_celda_valida(celda_destino):
		# Llamamos a game_over y luego retornamos.
		game_over("¡Choque con el límite del mapa! Error de secuencia. [LIMIT_CRASH]")
		await _esperar_muerte()
		return
	
	# 2. Iniciar movimiento
	posicion_actual = celda_destino # Actualizamos lógica ya
	var destino_pixel = GridManager.grid_to_world(celda_destino)
	
	if _tween_movimiento and _tween_movimiento.is_valid():
		_tween_movimiento.kill()
	_tween_movimiento = create_tween()
	_tween_movimiento.tween_property(self , "position", destino_pixel, TIEMPO_MOVIMIENTO)
	await _tween_movimiento.finished
	esta_actuando = false

func teletransportar_a(celda_destino: Vector2i):
	# 1. Detener cualquier animación o movimiento físico en curso
	if anim_player:
		anim_player.stop()
	if _tween_movimiento and _tween_movimiento.is_valid():
		_tween_movimiento.kill()
		
	scale = escala_inicial
	posicion_actual = celda_destino
	position = GridManager.grid_to_world(celda_destino)
	esta_actuando = false
	# Resetear dirección al inicio (Mirando arriba)
	direccion_actual = Vector2i(0, 1)
	_actualizar_idle()
	_ultimo_fue_avanzar = false

# --- NUEVA FUNCIÓN DE VERIFICACIÓN (Peligro Enemigo/Obstáculo) ---
func _verificar_peligro_inminente(es_avance: bool = false) -> bool:
	# 1. Celda en frente
	var celda_en_frente = posicion_actual + direccion_actual
	
	# Si no es celda válida (límites), no hay peligro, lo maneja mover_a_celda.
	if not GridManager.es_celda_valida(celda_en_frente):
		return false
		
	# --- Peligro 1: Enemigo al frente (Choque) ---
	var enemigo = GridManager.buscar_objeto_por_tipo(celda_en_frente, ElementoTablero.Tipo.ENEMIGO)
	if enemigo:
		if enemigo.has_method("reproducir_ataque"):
			enemigo.reproducir_ataque()
		
		await get_tree().create_timer(0.3).timeout # Sincronización muerte
		var tween = create_tween()
		tween.tween_property(self , "scale", Vector2.ZERO, 0.5)
		await get_tree().create_timer(0.5).timeout
		
		game_over("¡El enemigo te ha detectado y atacado! Debes usar 'atacar'.")
		return true

	# --- Peligro 2: Obstáculo al frente (Choque) ---
	var obstaculo = GridManager.buscar_objeto_por_tipo(celda_en_frente, ElementoTablero.Tipo.OBSTACULO)
	if obstaculo and es_avance:
		game_over("¡Choque con Obstáculo! Debes usar la instrucción 'saltar'.")
		return true

	# --- Peligro 3: Puente Inactivo al frente ---
	var puente = GridManager.buscar_objeto_por_tipo(celda_en_frente, ElementoTablero.Tipo.PUENTE)
	if puente and not puente.esta_activo and es_avance:
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

# --- SISTEMA DE ANIMACIONES ---

func _obtener_sufijo_direccion() -> String:
	# Mapeo de Vector dirección a nombre de animación
	if direccion_actual == Vector2i(0, 1): return "_arriba"
	if direccion_actual == Vector2i(0, -1): return "_abajo"
	if direccion_actual == Vector2i(1, 0): return "_derecha"
	if direccion_actual == Vector2i(-1, 0): return "_izquierda"
	return "_abajo" # Default

func _reproducir_anim(nombre_base: String):
	if not anim_player: return
	var nombre_final = nombre_base + _obtener_sufijo_direccion()
	
	if anim_player.has_animation(nombre_final):
		anim_player.play(nombre_final)
	else:
		# Fallback: Si no existe 'idle_arriba', intentamos poner el primer frame de 'caminar_arriba'
		var fallback = "caminar" + _obtener_sufijo_direccion()
		if nombre_base == "idle" and anim_player.has_animation(fallback):
			anim_player.play(fallback)
			anim_player.stop() # Nos quedamos en el primer frame de la caminata (pose quieta)

func _actualizar_idle():
	_reproducir_anim("idle")
