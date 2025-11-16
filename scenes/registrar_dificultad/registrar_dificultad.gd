extends Control

@export var dificultad_option_button: OptionButton

func _ready():
	_poblar_lista_de_dificultades()

func _poblar_lista_de_dificultades():
	# 1. Limpiamos items viejos
	dificultad_option_button.clear()
	
	# 2. Le pedimos las dificultades al DatabaseManager
	var dificultades = DatabaseManager.obtener_dificultades()
	
	if dificultades.is_empty():
		print("No se encontraron dificultades en la BD local.")
		dificultad_option_button.add_item("No hay dificultades cargadas", -1)
		dificultad_option_button.disabled = true
		return

	# 3. Recorremos el Array y añadimos cada dificultad
	for dificultad in dificultades:
		
		var nombre_dificultad = dificultad["nombre"]
		var id_dificultad = dificultad["id"] # Este es el UUID
		
		# Añadimos el 'nombre' (lo que ve el usuario)
		dificultad_option_button.add_item(nombre_dificultad)
		
		# No podemos usar el 'id' (UUID) como ID del item (que espera un int).
		# Guardamos el UUID como "metadata" del ítem que acabamos de añadir.
		
		# Obtenemos el índice del ítem que acabamos de añadir
		var item_index = dificultad_option_button.get_item_count() - 1
		
		# Guardamos el id_mision (el UUID) en ese índice
		dificultad_option_button.set_item_metadata(item_index, id_dificultad)
