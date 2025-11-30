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
	
	# 2. Conectar botón Ejecutar
	if not boton_ejecutar.pressed.is_connected(_on_ejecutar_pressed):
		boton_ejecutar.pressed.connect(_on_ejecutar_pressed)
	
	# 3. Configurar Timer
	timer_reinicio.one_shot = true
	if not timer_reinicio.timeout.is_connected(_on_reinicio_listo):
		timer_reinicio.timeout.connect(_on_reinicio_listo)
	
	# 4. Cargar Misión de Prueba
	var datos_prueba = {
		"nombre": "Prueba de Código",
		"descripcion": "Escribe: inicio, avanzar, derecha, avanzar, fin",
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
	# Colocamos algunos elementos para interactuar
	spawn_elemento(Vector2i(0, 1), ElementoTablero.Tipo.MONEDA)
	spawn_elemento(Vector2i(0, 3), ElementoTablero.Tipo.ENEMIGO)
	
	

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
	# El botón se re-habilita DESPUÉS del timer, en la función _on_reinicio_listo
	
	# 1. Mostrar mensaje final (o el popup de victoria/derrota si lo tuviéramos)
	# Por ahora, solo esperamos
	
	# 2. Iniciar el Timer de 3 segundos
	print("Reiniciando en 3 segundos...")
	timer_reinicio.start(3.0) 
	
	# Desconectamos el timer del nodo para evitar spam si ya estaba conectado
	if timer_reinicio.timeout.is_connected(_on_reinicio_listo):
		timer_reinicio.timeout.disconnect(_on_reinicio_listo)
	timer_reinicio.timeout.connect(_on_reinicio_listo)


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
