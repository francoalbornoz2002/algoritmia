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
var mision_actual = {}

# Precargamos la escena del elemento
var elemento_escena = preload("res://scenes/elemento_tablero/elemento_tablero.tscn")

func _ready():
	GridManager.limpiar_datos() 
	
	# 1. Configurar el Ejecutor
	# Le decimos quién es el personaje y quién manda (nosotros)
	ejecutor.personaje = jugador
	ejecutor.controlador_nivel = self
	
	if not jugador.game_over_triggered.is_connected(_on_jugador_game_over):
		jugador.game_over_triggered.connect(_on_jugador_game_over)
	
	# 2. Conectar botón Ejecutar
	if not boton_ejecutar.pressed.is_connected(_on_ejecutar_pressed):
		boton_ejecutar.pressed.connect(_on_ejecutar_pressed)
		
	if not jugador.has_signal("consola_mensaje"):
		# Esto evita errores si aún no agregaste la señal en el jugador
		pass
	else:
		if not jugador.consola_mensaje.is_connected(agregar_mensaje):
			jugador.consola_mensaje.connect(agregar_mensaje)
	
	# 3. Configurar Timer
	timer_reinicio.one_shot = true
	if not timer_reinicio.timeout.is_connected(_on_reinicio_listo):
		timer_reinicio.timeout.connect(_on_reinicio_listo)
	
	# 4. Cargar Misión de Prueba
	var datos_prueba = {
		"nombre": "Misión de prueba",
		"descripcion": "Recorre todo el sendero 1 hasta encontrar una moneda. Recógela, imprime la posición del valle actual y repite avanzar el número de la posición del valle. Luego, recorre todo el sendero 1 hasta el final recolectando todas las monedas e imprimiendo cuando encuentres una.",
		"dificultad": "Fácil",
		"pos_inicio": Vector2i(0, 0) 
	}
	cargar_mision(datos_prueba)
	
	queue_redraw()

func cargar_mision(datos: Dictionary):
	mision_actual = datos
	
	# 1. Actualizar UI
	label_mision.text = datos["nombre"]
	label_dificultad.text = datos["dificultad"]
	label_descripcion.text = datos["descripcion"]
	
	# 2. Posicionar Jugador
	jugador.teletransportar_a(datos["pos_inicio"])
	
	# --- Escenario de Prueba ---
	# Colocamos elementos estratégicos para probar todas las primitivas
	
	# Sendero 1: Monedas y Enemigo
	spawn_elemento(Vector2i(0, 2), ElementoTablero.Tipo.MONEDA)
	spawn_elemento(Vector2i(0, 3), ElementoTablero.Tipo.ENEMIGO) # Para probar atacar
	spawn_elemento(Vector2i(0, 5), ElementoTablero.Tipo.MONEDA)
	
	# Sendero 2: Llave y Obstáculo
	spawn_elemento(Vector2i(1, 2), ElementoTablero.Tipo.LLAVE)
	spawn_elemento(Vector2i(1, 4), ElementoTablero.Tipo.OBSTACULO) # Para probar saltar
	
	# Sendero 3: Puente y Cofre
	spawn_elemento(Vector2i(2, 3), ElementoTablero.Tipo.PUENTE) # Requiere moneda
	spawn_elemento(Vector2i(2, 5), ElementoTablero.Tipo.COFRE)  # Requiere llave
	
	# Límites y zonas vacías para probar movimiento libre
	
	

func spawn_elemento(pos: Vector2i, tipo):
	var nuevo_elemento = elemento_escena.instantiate()
	entidades_container.add_child(nuevo_elemento)
	
	# Configuramos visual y lógicamente
	nuevo_elemento.configurar(tipo, pos)
	
	# Registramos en la memoria del GridManager
	GridManager.registrar_objeto(pos, nuevo_elemento)

# --- LÓGICA DE EJECUCIÓN ---

func _on_ejecutar_pressed():
	if ejecutando_codigo:
		return # Ya está corriendo, no hacer nada
		
	print("--- INICIANDO EJECUCIÓN ---")
	ejecutando_codigo = true
	boton_ejecutar.disabled = true # Deshabilitar botón para evitar spam
	
	# Le pasamos el texto crudo al ejecutor
	var codigo_fuente = code_edit.text
	ejecutor.procesar_y_ejecutar(codigo_fuente)

# Esta función es llamada por el Ejecutor cuando el script termina (Línea 'Fin')
# o si hubo un error de sintaxis.
func on_ejecucion_terminada(exito: bool):
	print("--- EJECUCIÓN FINALIZADA (Éxito: " + str(exito) + ") ---")
	
	ejecutando_codigo = false
	
	# 2. Iniciar el Timer de 3 segundos
	print("Reiniciando en 3 segundos...")
	timer_reinicio.start(3.0) 
	
	# Desconectamos el timer del nodo para evitar spam si ya estaba conectado
	if timer_reinicio.timeout.is_connected(_on_reinicio_listo):
		timer_reinicio.timeout.disconnect(_on_reinicio_listo)
	timer_reinicio.timeout.connect(_on_reinicio_listo)

func _on_jugador_game_over(mensaje):
	# 1. Mandamos el error a la pantalla (Consola UI)
	agregar_mensaje("GAME OVER: " + mensaje, "ERROR")
	
	# 2. ¡IMPORTANTE! Matamos el script para evitar bucles infinitos
	ejecutor.detener_ejecucion_inmediata()
	
	# 3. Iniciamos la secuencia de reinicio
	on_ejecucion_terminada(false)

func _on_reinicio_listo():
	print("Reiniciando el estado del juego...")
	
	# 1. Habilitar el botón (para que el alumno pueda intentar de nuevo)
	boton_ejecutar.disabled = false 
	
	# 2. Reiniciar los objetos del mapa
	_reiniciar_estado_nivel()
	print("Nivel reiniciado")

func _reiniciar_estado_nivel():
	# Lógica para restaurar el estado inicial del nivel:
	
	# A. Limpiar entidades viejas del contenedor, EXCLUYENDO al Jugador
	for child in entidades_container.get_children():
		# Si el hijo NO es el jugador, lo eliminamos
		if child != jugador: 
			child.queue_free()
		
	# B. Limpiar la memoria del GridManager
	GridManager.limpiar_datos()
	
	# C. Reiniciar el inventario del jugador
	jugador.inventario.monedas = 0
	jugador.inventario.llaves = 0
	
	# D. Recargar la misión (esto repone objetos y al jugador)
	cargar_mision(mision_actual)


func agregar_mensaje(mensaje: String, tipo: String):
	if not consola_visual: return

	var color = "white"
	if tipo == "ERROR": color = "#ff5555" # Rojo
	if tipo == "OUTPUT": color = "#55ffff" # Cyan

	# Escribimos con BBCode
	consola_visual.append_text("[color=" + color + "]" + mensaje + "[/color]\n")
