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
	timer.wait_time = 10 # 300 segundos = 5 minutos
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
	
	# --- PASO 1: REVISAR MISIONES (NORMALES Y ESPECIALES) ---
	
	# A. Obtenemos las misiones normales pendientes
	var pendientes_normales = DatabaseManager.obtener_misiones_pendientes()
	var pendientes_especiales = DatabaseManager.obtener_misiones_especiales_pendientes()
	
	# B. Fusionamos las listas
	_lote_en_progreso = pendientes_normales + pendientes_especiales
	
	if not _lote_en_progreso.is_empty():
		print("Sincronizador: ¡Encontré %s misiones (total)! Enviando lote..." % _lote_en_progreso.size())
		tarea_en_progreso = "MISIONES" # Guardamos el contexto
		
		var lote_para_enviar = []
		for item_db in _lote_en_progreso:
			# Base común del payload
			var payload = {
				"idAlumno": id_alumno,
				"estrellas": item_db["estrellas"],
				"exp": item_db["exp"],
				"intentos": item_db["intentos"],
				"fechaCompletado": item_db["fecha_completado"]
			}
			
			# Diferenciamos si es especial o normal
			# (Sabemos que es especial si tiene la clave "nombre", que la tabla normal no tiene)
			if item_db.has("nombre"): 
				payload["idMision"] = item_db["id"] # UUID generado
				payload["esMisionEspecial"] = true
				payload["nombre"] = item_db["nombre"]
				payload["descripcion"] = item_db["descripcion"]
			else:
				payload["idMision"] = item_db["id_mision"] # ID del catálogo
				payload["esMisionEspecial"] = false
			
			lote_para_enviar.append(payload)
		
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
	if not esta_sincronizando: return 

	var tarea_terminada = tarea_en_progreso
	var lote_terminado = _lote_en_progreso.duplicate()
	
	# Liberamos recursos y el candado
	esta_sincronizando = false
	tarea_en_progreso = ""
	_lote_en_progreso.clear()

	var exito = false
	
	# 1. ANÁLISIS DE RESULTADO
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Sincronizador ERROR: Fallo de conexión o red.")
	elif response_code >= 200 and response_code < 300:
		print("Sincronizador: ¡Éxito (%s)!" % tarea_terminada)
		exito = true
		
		# 2. MARCADO EN BASE DE DATOS (Lógica Fusionada)
		if tarea_terminada == "MISIONES":
			var ids_normales = []
			var ids_especiales = []
			
			for m in lote_terminado:
				if m.has("nombre"): # Identificamos Misión Especial por el campo 'nombre'
					ids_especiales.append(m["id"])
				else:
					ids_normales.append(m["id_mision"])
			
			if not ids_normales.is_empty():
				DatabaseManager.marcar_lote_misiones_sincronizadas(ids_normales)
			
			if not ids_especiales.is_empty():
				DatabaseManager.marcar_lote_misiones_especiales_sincronizadas(ids_especiales)
				
		elif tarea_terminada == "DIFICULTADES":
			var ids_dificultades = lote_terminado.map(func(d): return d["id_dificultad"])
			DatabaseManager.marcar_lote_dificultades_sincronizadas(ids_dificultades)
			
	else:
		print("Sincronizador ERROR: Servidor rechazó (%s). Código: %s" % [tarea_terminada, response_code])

	# 3. LÓGICA DE REINTENTO (TIMER 10s)
	
	if exito:
		# Si hubo éxito, seguimos inmediatamente para vaciar la cola rápido
		sincronizar_pendientes()
	else:
		# Si falló, esperamos 10 segundos antes de volver a intentar
		print("Sincronizador: Reintentando envío en 10 segundos...")
		await get_tree().create_timer(10.0).timeout
		sincronizar_pendientes()
