class_name DefinicionMision extends Resource

@export_group("Información General")
# ID único (UUID) para sincronización con DB y Web
@export var id: String = "" 

# Nombre visible en el menú
@export var titulo: String = "Nueva Misión"

# Texto del enunciado (instrucciones para el alumno)
@export_multiline var descripcion: String = "Escribe tu algoritmo..."

# Dificultad (ej: "Fácil", "Medio", "Difícil" o numérico 1-3)
@export var dificultad: String = "Fácil" 

# Flag para saber si aplicamos recompensas dobles
@export var es_mision_especial: bool = false

@export_group("Evaluación")
# El código del alumno se ejecutará una vez por cada caso de prueba.
# Debe aprobar TODOS los casos para completar la misión.
@export var casos_de_prueba: Array[CasoPruebaMision] = []

# Helper para crear misiones simples (1 solo caso) manualmente o desde código
static func crear_simple(uuid: String, titulo_mision: String, enunciado: String, test_case: CasoPruebaMision) -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = uuid
	m.titulo = titulo_mision
	m.descripcion = enunciado
	m.casos_de_prueba = [test_case]
	return m
