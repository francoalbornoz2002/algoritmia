class_name GestorCatalogo extends RefCounted

const DIR_MISIONES = "res://resources/misiones/campana/"

## Escanea la carpeta de recursos y actualiza la tabla 'misiones' en la BD local.
static func actualizar_catalogo_desde_recursos():
	print("GestorCatalogo: Iniciando escaneo de misiones...")
	
	var dir = DirAccess.open(DIR_MISIONES)
	if not dir:
		print("GestorCatalogo: ERROR. No se encontró la carpeta ", DIR_MISIONES)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var count = 0
	
	while file_name != "":
		# En el editor los archivos son .tres, en exportación pueden ser .tres.remap
		if !dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
			# Limpiamos la extensión .remap si existe para cargar el recurso
			var path = DIR_MISIONES + file_name.replace(".remap", "")
			
			var recurso = load(path)
			if recurso is DefinicionMision:
				print("GestorCatalogo: Cargando recurso '%s' -> Misión: %s (ID: %s)" % [file_name, recurso.titulo, recurso.id])
				# Insertamos o actualizamos en la BD
				DatabaseManager.insertar_mision_catalogo(recurso)
				count += 1
				
		file_name = dir.get_next()
		
	print("GestorCatalogo: Se actualizaron %d misiones en la base de datos." % count)

## Busca y carga el recurso .tres correspondiente a un ID
static func obtener_mision_por_id(id_buscado: String) -> DefinicionMision:
	var dir = DirAccess.open(DIR_MISIONES)
	if not dir: return null

	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if !dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
			var path = DIR_MISIONES + file_name.replace(".remap", "")
			var recurso = load(path)
			if recurso is DefinicionMision and recurso.id == id_buscado:
				return recurso
		file_name = dir.get_next()
	
	return null
