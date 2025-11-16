extends Control

# --- Referencias a Nodos ---
@export var mision_opciones: OptionButton
@export var estrellas_input: SpinBox
@export var exp_input: SpinBox
@export var intentos_input: SpinBox
@export var boton_enviar: Button
@export var label_estado: Label

# Variable para saber qué misión estamos enviando
var _id_mision_en_progreso: String

func _ready():
	# Conectamos la señal
	boton_enviar.pressed.connect(_on_enviar_presionado)
	
	_poblar_misiones()

## Esta función carga el OptionButton desde la BD
func _poblar_misiones():
	# 1. Limpiamos items viejos
	mision_opciones.clear()
	
	# 2. Le pedimos las misiones al DatabaseManager
	var misiones = DatabaseManager.obtener_misiones()
	
	if misiones.is_empty():
		print("No se encontraron misiones en la BD local.")
		mision_opciones.add_item("No hay misiones cargadas", -1)
		mision_opciones.disabled = true
		return

	# 3. Recorremos el Array y añadimos cada misión
	for mision in misiones:
		
		var nombre_mision = mision["nombre"]
		var id_mision = mision["id"] # Este es el UUID
		
		# Añadimos el 'nombre' (lo que ve el usuario)
		mision_opciones.add_item(nombre_mision)
		
		# No podemos usar el 'id' (UUID) como ID del item (que espera un int).
		# Guardamos el UUID como "metadata" del ítem que acabamos de añadir.
		
		# Obtenemos el índice del ítem que acabamos de añadir
		var item_index = mision_opciones.get_item_count() - 1
		
		# Guardamos el id_mision (el UUID) en ese índice
		mision_opciones.set_item_metadata(item_index, id_mision)

# -----------------------------------------------------------------
# LÓGICA DE ENVÍO
# -----------------------------------------------------------------

func _on_enviar_presionado():
	label_estado.text = "Guardando..."
	boton_enviar.disabled = true
	
	# 1. --- OBTENER DATOS DE LA UI ---
	
	# Obtenemos la misión
	var indice_seleccionado = mision_opciones.selected
	if indice_seleccionado == -1:
		label_estado.text = "Error: Debes seleccionar una misión."
		boton_enviar.disabled = false
		return
	
	# Obtenemos el UUID guardado en la metadata
	var id_mision = mision_opciones.get_item_metadata(indice_seleccionado)
	
	# Obtenemos el resto de los datos de la misión
	var estrellas = estrellas_input.value
	var exp = exp_input.value
	var intentos = intentos_input.value
	
	# 2. --- GUARDADO LOCAL ---
	# Primero, escribimos en la BD local con 'sincronizado = false'
	var exito_local = DatabaseManager.registrar_mision_local(id_mision, estrellas, exp, intentos)
	
	if not exito_local:
		label_estado.text = "Error: No se pudo guardar en la BD local."
	else:
		label_estado.text = "¡Misión guardada localmente! Intentando sincronizar..."
		# 3. --- GESTOR DE SINCRONIZACIÓN ---
		# Llamamos al gestor para que intente sincronizar ahora, sin esperar al timer.
		GestorSincronizacion.sincronizar_pendientes()
	
	# Volvemos a activar el botón inmediatamente
	boton_enviar.disabled = false

@warning_ignore("unused_parameter")
func _on_http_request_completado(result, response_code, headers, body):
	boton_enviar.disabled = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		label_estado.text = "Error de red. El servidor no respondió."
		# Los datos siguen guardados localmente, listos para el próximo intento.
		return
	
	# El backend (NestJS) respondió
	if response_code == 200 or response_code == 201:
		label_estado.text = "¡Éxito! Misión registrada en la BD local y en el servidor."
		
		# 5. --- ACTUALIZAR FLAG LOCAL ---
		# Ahora que el servidor confirmó, marcamos la misión como 'sincronizado = true'
		DatabaseManager.marcar_mision_sincronizada(_id_mision_en_progreso)
		
	else:
		# El servidor respondió con un error (400, 404, 500, etc.)
		var respuesta_string = body.get_string_from_utf8()
		label_estado.text = "Error del servidor (%s): %s" % [response_code, respuesta_string]
		# Los datos siguen guardados localmente, listos para el próximo intento.
