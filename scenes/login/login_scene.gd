extends Control

# 1. --- VARIABLES Y REFERENCIAS ---

# URL del backend de NestJS
const GAME_LOGIN_URL = "http://localhost:3000/api/auth/game-login"

# Referencias a los nodos de la escena
@export var email_input: TextEdit
@export var contraseña_input: TextEdit
@export var boton_ingresar: Button
@export var label_errores: Label
@export var http_request: HTTPRequest

# 2. --- CONEXIÓN DE SEÑALES ---

func _ready():
	# Ocultamos la etiqueta de error al empezar
	label_errores.hide()
	
	# Conectamos las señales
	# 1. Cuando el botón "Ingresar" sea presionado, llama a la función _on_ingresar_button_pressed
	boton_ingresar.pressed.connect(_on_ingresar_pressed)
	
	# 2. Cuando el nodo HTTPRequest termine, llama a la función _on_http_request_completed
	http_request.request_completed.connect(_on_http_request_completed)

# 3. --- LÓGICA DE ENVÍO DE LOGIN ---

# Esta función se ejecuta cuando el jugador presiona el botón "Ingresar"
func _on_ingresar_pressed() -> void:
	# 1. Limpiamos errores y desactivamos el botón (para evitar doble clic)
	label_errores.hide()
	boton_ingresar.disabled = true
	
	# 2. Obtenemos los datos de los TextEdit
	var email = email_input.text
	var contraseña = contraseña_input.text
	
	# 3. Validación simple
	if email.is_empty() or contraseña.is_empty():
		label_errores.text = "Email y contraseña no pueden estar vacíos."
		label_errores.show()
		boton_ingresar.disabled = false
		return
	
	# 4. Preparamos los datos a enviar
	var datos_a_enviar = {
		"email": email,
		"password": contraseña,
	}
	
	# Convertimos el diccionario datos_a_enviar a JSON
	var json_body = JSON.stringify(datos_a_enviar)
	
	# Definimos los headers
	var headers = [
		"Content-Type: application/json"
	]
	
	# 5. Realizamos la petición al endpoint /auth/login
	var error = http_request.request(
		GAME_LOGIN_URL,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if error != OK:
		label_errores.text = "Error al iniciar la petición HTTP"
		label_errores.show()
		boton_ingresar.disabled = false

# 4. --- LÓGICA DE RESPUESTA DE LOGIN ---

# Esta función se ejecuta automáticamente cuando el servidor responde
func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	# 1. Pase lo que pase, volvemos a activar el botón
	boton_ingresar.disabled = false
	
	# 2. Verificamos si la petición fue exitosa
	if result != HTTPRequest.RESULT_SUCCESS:
		label_errores.text = "Error de red. No se pudo conectar."
		label_errores.show()
		return
	
	# 3. Verificamos el código de respuesta del servidor
	if response_code == 200:
		# Si es verdadero, hubo éxito en la petición.
		print("Login exitoso. Procesando datos...")
		
		# 4. Parseamos la respuesta (Body)
		var response_string = body.get_string_from_utf8()
		var response_data = JSON.parse_string(response_string)
		
		if response_data == null:
			label_errores.text = "Error: respuesta inválida del servidor (JSON Nulo)"
			label_errores.show()
		
		# 5. Llamamos al DatabaseManager para poblar la BD local
		var exito_db = DatabaseManager.poblar_datos_login(response_data)
		
		if exito_db:
			print("Base de datos poblada. Cargando menú principal...")
			# Cambiamos al menú principal del juego.
			get_tree().change_scene_to_file("res://scenes/menu_principal/menu_principal.tscn")
		else:
			label_errores.text = "Error al guardar los datos en la base de datos local"
			label_errores.show()
	else:
		#ERROR (Ej: 401 Credenciales inválidas, 404 No encontrado, etc.)
		
		# Intentamos leer el mensaje de error de NestJS
		var response_string = body.get_string_from_utf8()
		var error_data = JSON.parse_string(response_string)
		
		if error_data and error_data.has("message"):
			# Si NestJS envió {"message": "Credenciales inválidas"}
			label_errores.text = error_data["message"]
		else:
			# Error genérico
			label_errores.text = "Error del servidor (Código: %s)" % response_code
			
		label_errores.show()
