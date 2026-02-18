class_name CondicionMision extends Resource

# Texto descriptivo para debug o UI
@export var descripcion: String = "Condición Genérica"

# Función base que debe sobreescribirse
# Quitamos el tipado estricto de clases complejas para evitar dependencias cíclicas en recursos
func verificar(jugador, grid, ejecutor, consola_logs: Array) -> bool:
	return false
