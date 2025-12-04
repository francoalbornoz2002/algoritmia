class_name AnalistaDificultad extends Node

# --- DEFINICIÓN DE DIFICULTADES (IDs según DB/GDD) ---
const DIF_REDUNDANCIA = "SL-01"
const DIF_NO_VALIDAR = "SL-02"

# --- UMBRALES DE DIFICULTAD (Configuración) ---
# Cantidad de errores ACUMULADOS en varios intentos para subir de grado
const UMBRALES = {
	"BAJO": 3,   # 1 a 3 errores
	"MEDIO": 6,  # 4 a 6 errores
	"ALTO": 7    # 7 o más errores
}

# --- ESTADO VOLÁTIL (Se reinicia por intento) ---
var historial_acciones: Array = [] 
var validaciones_recientes: Dictionary = {
	"moneda": -1, # Timestamp (o paso) de la última validación
	"llave": -1,
	"enemigo": -1,
	"obstaculo": -1,
	"cofre": -1,
	"puente": -1
}
var paso_actual: int = 0

# --- ESTADO PERSISTENTE (Se mantiene en la sesión de juego actual) ---
# Diccionario para acumular errores: { "SL-01": 5, "SL-02": 2 }
var contador_errores_acumulados: Dictionary = {}

func _ready():
	# Inicializamos contadores en 0
	contador_errores_acumulados[DIF_REDUNDANCIA] = 0
	contador_errores_acumulados[DIF_NO_VALIDAR] = 0

# Se llama al inicio de cada ejecución (Botón Ejecutar)
func iniciar_nuevo_intento():
	historial_acciones.clear()
	validaciones_recientes = {
		"moneda": -1, 
		"llave": -1, 
		"enemigo": -1, 
		"obstaculo": -1,
		"cofre": -1,
		"puente": -1
	}
	paso_actual = 0
	print("--- Analista: Nuevo intento iniciado ---")

# --- API DE EVENTOS (El Jugador llama a esto) ---

func registrar_validacion(tipo_objeto: String):
	# Ej: El alumno hizo "Si hayMoneda" -> tipo_objeto = "moneda"
	validaciones_recientes[tipo_objeto] = paso_actual
	# print("Analista: Validación registrada de ", tipo_objeto, " en paso ", paso_actual)

func registrar_accion(accion: String, contexto: String = ""):
	paso_actual += 1
	
	# 1. DETECCIÓN SL-01: REDUNDANCIA DE INSTRUCCIONES
	# Regla: Ejecuta 2 o más veces la misma instrucción sin necesidad
	# (Aquí simplificamos: si la acción es idéntica a la anterior inmediata)
	if historial_acciones.size() > 0:
		var ultima = historial_acciones[-1]
		if ultima == accion:
			# Excepción: "avanzar" es común hacerlo seguido, pero acciones como 
			# "recogerMoneda" o "atacar" dos veces seguidas suelen ser error o redundancia.
			if accion in ["recogerMoneda", "recogerLlave", "atacar", "abrirCofre", "activarPuente"]:
				_registrar_error(DIF_REDUNDANCIA)
	
	historial_acciones.append(accion)

	# 2. DETECCIÓN SL-02 (Objetos) y SL-03 (Acciones innecesarias)
	match accion:
		"recogerMoneda":
			if not _se_valido_recientemente("moneda"): _registrar_error(DIF_NO_VALIDAR)
		"recogerLlave":
			if not _se_valido_recientemente("llave"): _registrar_error(DIF_NO_VALIDAR)
		"abrirCofre":
			if not _se_valido_recientemente("cofre"): _registrar_error(DIF_NO_VALIDAR) # SL-02
		"activarPuente":
			if not _se_valido_recientemente("puente"): _registrar_error(DIF_NO_VALIDAR) # SL-03/02
		"atacar":
			if not _se_valido_recientemente("enemigo"): _registrar_error("SL-03") # Acción innecesaria
		"saltar":
			if not _se_valido_recientemente("obstaculo"): _registrar_error("SL-03") # Acción innecesaria

# --- LÓGICA INTERNA ---

func _se_valido_recientemente(tipo: String) -> bool:
	var ultimo_check = validaciones_recientes.get(tipo, -1)
	# Si nunca se validó (-1), retornamos falso
	if ultimo_check == -1: return false
	
	# Tolerancia: La validación debe haber ocurrido hace poco (ej: últimos 5 pasos)
	# O, más estricto: debe estar dentro del mismo bloque lógico. 
	# Por ahora usamos distancia temporal simple.
	var distancia = paso_actual - ultimo_check
	return distancia <= 2 # Muy cerca (inmediatamente antes o casi)

func _registrar_error(codigo_dificultad: String):
	print("!!! Analista: ERROR DETECTADO [", codigo_dificultad, "] !!!")
	if codigo_dificultad in contador_errores_acumulados:
		contador_errores_acumulados[codigo_dificultad] += 1
	else:
		contador_errores_acumulados[codigo_dificultad] = 1

# --- FINALIZACIÓN Y GUARDADO ---

func procesar_resultados_finales():
	print("--- Analista: Procesando dificultades acumuladas ---")
	print(contador_errores_acumulados)
	
	for codigo in contador_errores_acumulados:
		var cantidad = contador_errores_acumulados[codigo]
		if cantidad > 0:
			var grado = _calcular_grado(cantidad)
			if grado != "Ninguno":
				_guardar_dificultad_bd(codigo, grado)

func _calcular_grado(cantidad: int) -> String:
	if cantidad >= UMBRALES.ALTO: return "Alto"
	if cantidad >= UMBRALES.MEDIO: return "Medio"
	if cantidad >= 1: return "Bajo" # Según tu criterio, 1 error ya cuenta como Bajo
	return "Ninguno"

func _guardar_dificultad_bd(codigo: String, grado: String):
	print(">>> GUARDANDO DIFICULTAD: ", codigo, " GRADO: ", grado)
	# Llamada al DatabaseManager existente
	DatabaseManager.registrar_dificultad_local(codigo, grado)
	# Marcamos para sincronizar en el futuro (FASE 3)

func obtener_total_errores() -> int:
	var total = 0
	for key in contador_errores_acumulados:
		total += contador_errores_acumulados[key]
	return total

func hay_errores_graves() -> bool:
	for key in contador_errores_acumulados:
		var cantidad = contador_errores_acumulados[key]
		# Usamos el umbral MEDIO (6) del GDD como referencia de gravedad
		# O ajustamos a >= 4 como sugerimos antes para ser estrictos con la calidad
		if cantidad >= 4: 
			return true
	return false
