extends Control

## -------------------- REFERENCIAS A NODOS -------------------- ##
@export var dificultad_opciones: OptionButton
@export var grado_opciones: OptionButton
@export var boton_enviar: Button
@export var label_estado: Label
# Definimos los grados según el Enum de Prisma
const GRADOS = ["Ninguno", "Bajo", "Medio", "Alto"]

## -------------------- FUNCIÓN READY -------------------- ##
func _ready():
	# Conectamos las señales
	boton_enviar.pressed.connect(_on_enviar_presionado)
	# Poblamos los dropdowns
	_poblar_dificultades()
	_poblar_grados()

## -------------------- FUNCIONES DE POBLADO -------------------- ##

## --- Carga el OptionButton de Dificultades --- ##
func _poblar_dificultades():
	# 1. Limpiamos items viejos
	dificultad_opciones.clear()
	
	# 2. Le pedimos las dificultades al DatabaseManager
	var dificultades = DatabaseManager.obtener_dificultades()
	
	if dificultades.is_empty():
		print("No se encontraron dificultades en la BD local.")
		dificultad_opciones.add_item("No hay dificultades cargadas", -1)
		dificultad_opciones.disabled = true
		return

	# 3. Recorremos el Array y añadimos cada dificultad
	for dificultad in dificultades:
		var nombre_dificultad = dificultad["nombre"]
		var id_dificultad = dificultad["id"] # Este es el UUID
		
		# Añadimos el 'nombre' (lo que ve el usuario)
		dificultad_opciones.add_item(nombre_dificultad)
		
		# No podemos usar el 'id' (UUID) como ID del item (que espera un int).
		# Guardamos el UUID como "metadata" del ítem que acabamos de añadir.
		
		# Obtenemos el índice del ítem que acabamos de añadir
		var item_index = dificultad_opciones.get_item_count() - 1
		
		# Guardamos el id_mision (el UUID) en ese índice
		dificultad_opciones.set_item_metadata(item_index, id_dificultad)

## --- Carga el OptionButton de Grados --- ##
func _poblar_grados():
	# Limpiamos valores viejos
	grado_opciones.clear()
	
	# Recorremos el array de grados y añadimos el nombre
	for i in range(GRADOS.size()):
		var grado_nombre = GRADOS[i]
		grado_opciones.add_item(grado_nombre)
		# Guardamos el mismo string como metadata para que coincida con el Enum de Prisma
		grado_opciones.set_item_metadata(i, grado_nombre)

## -------------------- LÓGICA DE ENVÍO -------------------- ##

## --- Función de envío de dificultades --- ##
func _on_enviar_presionado():
	label_estado.text = "Guardando..."
	boton_enviar.disabled = true

	# 1. --- OBTENER DATOS DE LA UI ---
	var indice_dificultad = dificultad_opciones.selected
	var indice_grado = grado_opciones.selected
	
	if indice_dificultad == -1 or indice_grado == -1:
		label_estado.text = "Error: Debes seleccionar ambos campos."
		boton_enviar.disabled = false
		return
		
	# Obtenemos el UUID y el string del Grado
	var id_dificultad = dificultad_opciones.get_item_metadata(indice_dificultad)
	var grado = grado_opciones.get_item_metadata(indice_grado)
	
	# 2. --- GUARDADO LOCAL (UPSERT) ---
	# Usamos la función que hace "INSERT OR REPLACE"
	var exito_local = DatabaseManager.registrar_dificultad_local(id_dificultad, grado)
	
	if not exito_local:
		label_estado.text = "Error: No se pudo guardar en la BD local."
	else:
		label_estado.text = "¡Dificultad guardada localmente! Intentando sincronizar..."
		
		# 3. --- GESTOR DE SINCRONIZACIÓN ---
		# Llamamos al gestor para que intente sincronizar ahora, sin esperar al timer.
		GestorSincronizacion.sincronizar_pendientes()

	boton_enviar.disabled = false
