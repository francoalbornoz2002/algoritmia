extends Node

# Aquí guardaremos la definición de la misión que se va a jugar
var mision_seleccionada: DefinicionMision = null

# --- Flags para flujo de Login -> Menú ---
var recien_logueado: bool = false
var stats_login: Dictionary = {}

# Podríamos agregar más datos globales a futuro (ej: configuración de usuario, volumen, etc.)
