class_name CatalogoMisiones extends RefCounted

# Diccionario que mapea un ID legible (para uso interno/UI) a la función constructora.
# Usamos una función estática para evitar errores de "Constant Expression" con Callables.
static func _get_misiones() -> Dictionary:
	return {
		"campana_01": MisionesCampana.crear_mision_01_bucle_basico
	}

# Obtiene una misión instanciada por su clave del catálogo
static func obtener_mision(clave_catalogo: String) -> DefinicionMision:
	var misiones = _get_misiones()
	if misiones.has(clave_catalogo):
		return misiones[clave_catalogo].call()
	return null

# Devuelve todas las misiones del catálogo instanciadas
static func obtener_todas() -> Array[DefinicionMision]:
	var lista: Array[DefinicionMision] = []
	var misiones = _get_misiones()
	for key in misiones:
		lista.append(misiones[key].call())
	return lista