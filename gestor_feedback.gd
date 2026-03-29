extends Node

const DIR_FEEDBACK = "res://resources/feedback/"

var _feedback_cache: Dictionary = {}

func _ready():
	_cargar_recursos_feedback()

func _cargar_recursos_feedback():
	var dir = DirAccess.open(DIR_FEEDBACK)
	if not dir:
		print("GestorFeedback: ERROR. No se encontró la carpeta de recursos de feedback en ", DIR_FEEDBACK)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
			var path = DIR_FEEDBACK + file_name.replace(".remap", "")
			
			var recurso = load(path)
			if recurso is FeedbackDificultad:
				if not recurso.codigo_dificultad.is_empty():
					_feedback_cache[recurso.codigo_dificultad] = recurso
					print("GestorFeedback: Cargado feedback para '", recurso.codigo_dificultad, "'")
		
		file_name = dir.get_next()

func obtener_feedback_por_codigo(codigo: String) -> FeedbackDificultad:
	return _feedback_cache.get(codigo, null)
