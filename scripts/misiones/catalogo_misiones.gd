class_name CatalogoMisiones extends RefCounted

# ==========================================

# Diccionario que mapea un ID legible (para uso interno/UI) a la función constructora.
# Usamos una función estática para evitar errores de "Constant Expression" con Callables.
static func _get_misiones() -> Dictionary:
	return {
		# TEMA 1: SECUENCIA
		"secuencia_01": MisionesCampana.crear_mision_secuencia_01,
		"secuencia_02": MisionesCampana.crear_mision_secuencia_02,
		"secuencia_03": MisionesCampana.crear_mision_secuencia_03,
		"secuencia_04": MisionesCampana.crear_mision_secuencia_04,
		"secuencia_05": MisionesCampana.crear_mision_secuencia_05,
		# TEMA 2: BUCLES
		"bucles_01": MisionesCampana.crear_mision_bucles_01,
		"bucles_02": MisionesCampana.crear_mision_bucles_02,
		"bucles_03": MisionesCampana.crear_mision_bucles_03,
		"bucles_04": MisionesCampana.crear_mision_bucles_04,
		"bucles_05": MisionesCampana.crear_mision_bucles_05,
		# TEMA 3: CONDICIONALES
		"condicionales_01": MisionesCampana.crear_mision_condicionales_01,
		"condicionales_02": MisionesCampana.crear_mision_condicionales_02,
		"condicionales_03": MisionesCampana.crear_mision_condicionales_03,
		"condicionales_04": MisionesCampana.crear_mision_condicionales_04,
		"condicionales_05": MisionesCampana.crear_mision_condicionales_05,
		# TEMA 4: VARIABLES
		"variables_01": MisionesCampana.crear_mision_variables_01,
		"variables_02": MisionesCampana.crear_mision_variables_02,
		"variables_03": MisionesCampana.crear_mision_variables_03,
		"variables_04": MisionesCampana.crear_mision_variables_04,
		"variables_05": MisionesCampana.crear_mision_variables_05,
		# TEMA 5: PROCEDIMIENTOS
		"procedimientos_01": MisionesCampana.crear_mision_procedimientos_01,
		"procedimientos_02": MisionesCampana.crear_mision_procedimientos_02,
		"procedimientos_03": MisionesCampana.crear_mision_procedimientos_03,
		"procedimientos_04": MisionesCampana.crear_mision_procedimientos_04,
		"procedimientos_05": MisionesCampana.crear_mision_procedimientos_05
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
