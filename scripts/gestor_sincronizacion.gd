extends Node

# --- URLs del Backend ---
const URL_LOTE_MISIONES = "http://localhost:3000/api/progress/submit-missions"
const URL_LOTE_DIFICULTADES = "http://localhost:3000/api/difficulties/submit-difficulties"

# --- Nodos Internos ---
var http_request: HTTPRequest
var timer: Timer

# --- Estado ---
var esta_sincronizando: bool = false
var tarea_en_progreso: String = "" # Para saber qué estamos enviando

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
		
	# 2. Obtenemos el ID del alumno (necesario para ambos lotes)
	var id_alumno = DatabaseManager.obtener_id_alumno_actual()
	if id_alumno.is_empty():
		print("Sincronizador ERROR: No hay ID de alumno. Abortando.")
		return
	
	# 3. Colocamos el estado de sincronización a verdadero
	esta_sincronizando = true
	
	# --- PASO 1: PRIORIZAMOS MISIONES ---
	# Obtenemos las misiones pendientes de sincronización
	_lote_en_progreso = DatabaseManager.obtener_misiones_pendientes()
	if not _lote_en_progreso.is_empty():
		print("Sincronizador: ¡Encontré %s misiones! Enviando lote..." % _lote_en_progreso.size())
		tarea_en_progreso = "MISIONES" # Guardamos el contexto
		
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
		
		_enviar_peticion(URL_LOTE_MISIONES, lote_para_enviar)
		return # Salimos, esperamos la respuesta del callback
		
	# --- PASO 2: REVISAMOS DIFICULTADES ---
	# (Solo llega aquí si no había misiones pendientes)
	_lote_en_progreso = DatabaseManager.obtener_dificultades_pendientes()
	if not _lote_en_progreso.is_empty():
		print("Sincronizador: ¡Encontré %s dificultades! Enviando lote..." % _lote_en_progreso.size())
		tarea_en_progreso = "DIFICULTADES" # Guardamos el contexto

		var lote_para_enviar = []
		for dificultad_db in _lote_en_progreso:
			lote_para_enviar.append({
				"idAlumno": id_alumno,
				"idDificultad": dificultad_db["id_dificultad"],
				"grado": dificultad_db["grado"]
			})
		
		_enviar_peticion(URL_LOTE_DIFICULTADES, lote_para_enviar)
		return # Salimos y esperamos la respuesta

	# --- NADA QUE HACER ---
	esta_sincronizando = false # Abrimos el sincronizador
	
	## HELPER: Envía la petición HTTP
func _enviar_peticion(url: String, lote_datos: Array):
	var json_body = JSON.stringify(lote_datos)
	var headers = ["Content-Type: application/json"]

	var error = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if error != OK:
		print("Sincronizador ERROR: No se pudo iniciar la petición HTTP.")
		# Liberamos el candado si la petición ni siquiera pudo empezar
		esta_sincronizando = false
		tarea_en_progreso = ""
		_lote_en_progreso.clear()


# --- El Callback (Respuesta del servidor) ---

func _on_http_request_completado(result, response_code, headers, body):
	# No aseguramos de que esta respuesta sea del gestor de sincronización
	if not esta_sincronizando: 
		return 

	# Guardamos el estado actual antes de limpiar
	var tarea_terminada = tarea_en_progreso
	var lote_terminado = _lote_en_progreso.duplicate() # Copiamos el array
	
	# 1. Pase lo que pase, Abrimos el sincronizador y limpiamos la tarea y lote
	esta_sincronizando = false
	tarea_en_progreso = ""
	_lote_en_progreso.clear()

	# 2. Verificamos el resultado de la red
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Sincronizador ERROR: Falló la conexión de red. Se reintentará más tarde.")
		# No hacemos nada más, los datos siguen 'sincronizado = 0'
		
	# 3. Verificamos la respuesta del servidor
	elif response_code == 200 or response_code == 201:
		# Éxito en el envío
		print("Sincronizador: ¡Lote de %s enviado con éxito!" % tarea_terminada)
		
		# Marcamos como sincronizado las misiones o dificultades (según el contexto)
		if tarea_terminada == "MISIONES":
			var ids_misiones = lote_terminado.map(func(m): return m["id_mision"])
			DatabaseManager.marcar_lote_misiones_sincronizadas(ids_misiones)
			
		elif tarea_terminada == "DIFICULTADES":
			var ids_dificultades = lote_terminado.map(func(d): return d["id_dificultad"])
			DatabaseManager.marcar_lote_dificultades_sincronizadas(ids_dificultades)
			
	else:
		# El servidor respondió con un error (400, 500, etc.)
		print("Sincronizador ERROR: El servidor rechazó el lote de %s (Código: %s). Se reintentará." % [tarea_terminada, response_code])
		# No hacemos nada, los datos siguen 'sincronizado = 0'

	# 4. Intentamos sincronizar de nuevo inmediatamente.
	# Si acabamos de enviar misiones, esto revisará si hay dificultades.
	# Si acabamos de enviar dificultades, esto revisará si (mientras tanto)
	# entró una nueva misión.
	sincronizar_pendientes()
