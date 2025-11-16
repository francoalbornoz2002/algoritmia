extends Node

# --- URLs del Backend ---
const URL_LOTE_MISIONES = "http://localhost:3000/api/progress/submit-missions"
# (Aquí iría también la URL_LOTE_DIFICULTADES, para hacer)

# --- Nodos Internos ---
var http_request: HTTPRequest
var timer: Timer

# --- Estado ---
var esta_sincronizando: bool = false

# Variable para guardar el lote que estamos enviando
var _lote_en_progreso: Array = []

# Se ejecuta una sola vez cuando el juego carga
func _ready():
	# 1. Creamos el nodo HTTPRequest
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completado)
	
	# 2. Creamos el Timer (revisará cada 5 minutos)
	timer = Timer.new()
	timer.wait_time = 300 # 300 segundos = 5 minutos
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	
	print("Gestor de Sincronización listo.")


# El Timer llama a esta función automáticamente
func _on_timer_timeout():
	print("Timer: Buscando tareas pendientes...")
	sincronizar_pendientes()

# --- La Lógica Principal ---

# Intenta sincronizar tareas pendientes.
# Esta función puede ser llamada por el Timer o por el juego.
func sincronizar_pendientes():
	# 1. Verificamos el estado (mutex)
	# Si ya está ocupado enviando algo, no hacemos nada.
	if esta_sincronizando:
		print("Sincronizador: Ya estoy ocupado, reintentando más tarde.")
		return

	# 2. Obtenemos tareas (SOLO MISIONES POR AHORA)
	_lote_en_progreso = DatabaseManager.obtener_misiones_pendientes()
	
	if _lote_en_progreso.is_empty():
		# No hay nada que hacer
		return
		
	print("Sincronizador: ¡Encontré %s misiones! Enviando lote..." % _lote_en_progreso.size())
	
	# 3. Colocamos el estado de sincronización a verdadero
	esta_sincronizando = true
	
	# 4. Obtenemos el ID del alumno (para el DTO)
	var id_alumno = DatabaseManager.obtener_id_alumno_actual()
	if id_alumno.is_empty():
		print("Sincronizador ERROR: No hay ID de alumno. Abortando.")
		esta_sincronizando = false
		return

	# 5. Preparamos el Lote
	var lote_para_enviar = []
	
	for mision_db in _lote_en_progreso:
		lote_para_enviar.append({
			"idAlumno": id_alumno,
			"idMision": mision_db["id_mision"],
			"estrellas": mision_db["estrellas"],
			"exp": mision_db["exp"],
			"intentos": mision_db["intentos"],
			"fechaCompletado": mision_db["fecha_completado"]
		})

	# 6. Preparamos la petición
	var json_body = JSON.stringify(lote_para_enviar)
	var headers = ["Content-Type: application/json"]

	var error = http_request.request(
		URL_LOTE_MISIONES,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if error != OK:
		print("Sincronizador ERROR: No se pudo iniciar la petición HTTP.")
		esta_sincronizando = false # Liberamos el candado


# --- El Callback (Respuesta del servidor) ---

func _on_http_request_completado(result, response_code, headers, body):
	# 1. Pase lo que pase, colocamos el estado de sincronización a falso para permitir mas sincronizaciones
	esta_sincronizando = false
	
	# 2. Verificamos el resultado de la red
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Sincronizador ERROR: Falló la conexión de red. Se reintentará más tarde.")
		_lote_en_progreso.clear()
		return
		
	# 3. Verificamos la respuesta del servidor
	if response_code == 200 or response_code == 201:
		# Envío exitoso
		print("Sincronizador: ¡Lote enviado con éxito!")
		
		# 4. Armamos la lista de IDs para marcar como sincronizados
		var ids_a_marcar = []
		for mision in _lote_en_progreso:
			ids_a_marcar.append(mision["id_mision"])
			
		DatabaseManager.marcar_lote_misiones_sincronizadas(ids_a_marcar)
		
	else:
		# El servidor respondió con un error (400, 500, etc.)
		print("Sincronizador ERROR: El servidor rechazó el lote (Código: %s). Se reintentará." % response_code)
		# No hacemos nada, las misiones siguen como 'sincronizado = 0'
	
	# 5. Limpiamos el lote temporal
	_lote_en_progreso.clear()
