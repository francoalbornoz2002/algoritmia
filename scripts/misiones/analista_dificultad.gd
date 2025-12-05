class_name AnalistaDificultad extends Node

# --- DEFINICIÓN DE DIFICULTADES (GDD Sección 8) ---
const DIF_REDUNDANCIA = "SL-01"      # Redundancia de instrucciones
const DIF_NO_VALIDAR = "SL-02"       # No valida objeto antes de recoger
const DIF_INNECESARIA = "SL-03"      # Instrucciones innecesarias (contexto)
const DIF_BUCLE_INFINITO = "EC-01"   # Bucles mal controlados
const DIF_OPERADORES_LOGICOS = "LP-01" # Mal uso o confusión con operadores lógicos.
const DIF_VAR_NO_INIT = "VA-02" # Uso de variables sin inicializar

# --- UMBRALES DE EVALUACIÓN ---
# Cuántos intentos CON el error se necesitan para subir de grado
const UMBRALES = {
	"BAJO": 3,   # Con que aparezca en 1 intento ya es "Bajo" (atención)
	"MEDIO": 5,  # Si persiste en 3 intentos
	"ALTO": 7    # Si persiste en 5+ intentos
}

# Límite de pasos para considerar un bucle infinito (EC-01)
const MAX_PASOS_POR_EJECUCION = 500 

# --- ESTADO VOLÁTIL (Por intento) ---
var historial_acciones: Array[String] = [] 
var validaciones_recientes: Dictionary = {}
var paso_actual: int = 0
var errores_detectados_en_este_intento: Dictionary = {} # Para evitar duplicados masivos

# --- ESTADO PERSISTENTE (Sesión) ---
# Cuenta en CUÁNTOS intentos apareció el error (no cuántas veces por loop)
var contador_incidencias_acumuladas: Dictionary = {}

func _ready():
	_resetear_contadores_globales()

func _resetear_contadores_globales():
	contador_incidencias_acumuladas = {
		DIF_REDUNDANCIA: 0,
		DIF_NO_VALIDAR: 0,
		DIF_INNECESARIA: 0,
		DIF_BUCLE_INFINITO: 0,
		DIF_OPERADORES_LOGICOS: 0,
		DIF_VAR_NO_INIT: 0
	}

func registrar_error_externo(codigo: String):
	_registrar_incidencia(codigo)

# Se llama al darle "Ejecutar"
func iniciar_nuevo_intento():
	historial_acciones.clear()
	errores_detectados_en_este_intento.clear()
	
	# Reiniciamos a estructura vacía
	# Estructura interna será: "tipo": { "paso": 10, "resultado": true }
	validaciones_recientes = {}
	
	paso_actual = 0
	print("--- Analista: Nuevo intento ---")

# --- API DE EVENTOS ---

func registrar_validacion(tipo_objeto: String, resultado: bool = false):
	validaciones_recientes[tipo_objeto] = {
		"paso": paso_actual,
		"resultado": resultado
	}

func registrar_accion(accion: String):
	paso_actual += 1
	
	# 1. VERIFICACIÓN DE BUCLE INFINITO (EC-01)
	if paso_actual > MAX_PASOS_POR_EJECUCION:
		_registrar_incidencia(DIF_BUCLE_INFINITO)
		# Opcional: Podríamos pedir al Ejecutor que detenga el script aquí
		return

	# 2. ANÁLISIS DE REDUNDANCIA (SL-01)
	_analizar_redundancia(accion)
	
	historial_acciones.append(accion)

	# 3. ANÁLISIS DE VALIDACIÓN PREVIA (SL-02 y SL-03)
	_analizar_validacion_requerida(accion)
	
	# 4. ANÁLISIS LÓGICA PROPOSICIONAL (LP-01) <--- NUEVO
	_analizar_logica_operadores(accion)

# --- LÓGICA DE DETECCIÓN DE PATRONES ---
func _analizar_redundancia(accion_actual: String):
	if historial_acciones.is_empty(): return
	
	# Miramos hacia atrás para ver repeticiones
	var repeticiones = 0
	# Recorremos inversamente
	for i in range(historial_acciones.size() - 1, -1, -1):
		if historial_acciones[i] == accion_actual:
			repeticiones += 1
		else:
			break # Se cortó la racha
	
	# La acción actual sería la (repeticiones + 1)
	var racha_actual = repeticiones + 1
	
	# UMBRALES DE REDUNDANCIA
	# Para movimiento ("avanzar"), somos más permisivos: 3 o más es redundante.
	# Para acciones ("recoger", "atacar"), 2 o más ya es redundante.
	if accion_actual == "avanzar":
		if racha_actual >= 3:
			_registrar_incidencia(DIF_REDUNDANCIA)
	elif accion_actual in ["recogerMoneda", "recogerLlave", "atacar", "saltar", "abrirCofre", "activarPuente"]:
		if racha_actual >= 2:
			_registrar_incidencia(DIF_REDUNDANCIA)

func _analizar_validacion_requerida(accion: String):
	var sensor_requerido = ""
	var dificultad_tipo = ""
	
	# Mapeo según GDD
	match accion:
		"recogerMoneda":
			sensor_requerido = "moneda"
			dificultad_tipo = DIF_NO_VALIDAR # SL-02
		"recogerLlave":
			sensor_requerido = "llave"
			dificultad_tipo = DIF_NO_VALIDAR # SL-02
		"abrirCofre":
			sensor_requerido = "cofre"
			dificultad_tipo = DIF_NO_VALIDAR # SL-02
		"activarPuente":
			sensor_requerido = "puente"
			dificultad_tipo = DIF_INNECESARIA # SL-03 (Acción sin contexto) o SL-02
		"atacar":
			sensor_requerido = "enemigo"
			dificultad_tipo = DIF_INNECESARIA # SL-03
		"saltar":
			sensor_requerido = "obstaculo"
			dificultad_tipo = DIF_INNECESARIA # SL-03
			
	if sensor_requerido != "":
		if not _se_valido_recientemente(sensor_requerido):
			_registrar_incidencia(dificultad_tipo)


# --- NUEVA FUNCIÓN DE ANÁLISIS ---
func _analizar_logica_operadores(accion: String):
	# Detectamos si entró a una acción compuesta faltando una condición crítica
	# Esto sugiere uso de OR en vez de AND, o mal uso de NOT.
	
	if accion == "abrirCofre":
		# Requiere LLAVE. Si validó llave recientemente y dio FALSO, pero entró igual...
		if _valido_y_dio_falso("llave"):
			_registrar_incidencia(DIF_OPERADORES_LOGICOS)
			
	elif accion == "activarPuente":
		# Requiere MONEDA. Si validó moneda recientemente y dio FALSO, pero entró igual...
		if _valido_y_dio_falso("moneda"):
			_registrar_incidencia(DIF_OPERADORES_LOGICOS)

# Helper para verificar si se validó algo hace poco y dio false
func _valido_y_dio_falso(tipo: String) -> bool:
	if not validaciones_recientes.has(tipo): return false
	
	var data = validaciones_recientes[tipo]
	var distancia = paso_actual - data["paso"]
	
	# Si se validó en los últimos 3 pasos y el resultado fue FALSO
	return distancia <= 3 and data["resultado"] == false


func _se_valido_recientemente(tipo: String) -> bool:
	if not validaciones_recientes.has(tipo): return false
	
	var data = validaciones_recientes[tipo]
	var distancia = paso_actual - data["paso"]
	return distancia <= 3

func _registrar_incidencia(codigo: String):
	# CLAVE: Solo registramos UNA vez el error por intento.
	# Esto evita el problema de los "20 errores" en un bucle.
	if not errores_detectados_en_este_intento.has(codigo):
		errores_detectados_en_este_intento[codigo] = true
		print("!!! Analista: Patrón detectado [", codigo, "] en este intento.")

# --- PROCESAMIENTO FINAL (Al terminar misión o Game Over) ---

func procesar_resultados_finales():
	# 1. Consolidar el último intento
	consolidar_intento_actual()
	
	print("--- Analista: Resultados acumulados de la sesión ---")
	print(contador_incidencias_acumuladas)
	
	# 2. Enviar conteos crudos a la BD
	for codigo in contador_incidencias_acumuladas:
		var cantidad_errores = contador_incidencias_acumuladas[codigo]
		
		if cantidad_errores > 0:
			# Obtenemos el UUID real
			var id_uuid = _obtener_uuid_por_codigo(codigo)
			if id_uuid != "":
				# DELEGAMOS el cálculo de grado al DatabaseManager
				DatabaseManager.registrar_errores_dificultad(id_uuid, cantidad_errores)

# Llamar a esto cada vez que termina un intento (Game Over o Victoria)
# para "fijar" los errores detectados.
func consolidar_intento_actual():
	for codigo in errores_detectados_en_este_intento:
		# PESO: Bucle Infinito vale x3
		var peso = 1
		if codigo == DIF_BUCLE_INFINITO:
			peso = 3
			print("!!! Analista: Penalización x3 por Bucle Infinito.")
			
		if contador_incidencias_acumuladas.has(codigo):
			contador_incidencias_acumuladas[codigo] += peso
		else:
			contador_incidencias_acumuladas[codigo] = peso
	
	errores_detectados_en_este_intento.clear()

# --- HELPERS PARA ESTADÍSTICAS ---
func obtener_total_errores() -> int:
	# Retorna la suma de incidencias acumuladas
	var total = 0
	for key in contador_incidencias_acumuladas:
		total += contador_incidencias_acumuladas[key]
	return total

func hay_errores_graves() -> bool:
	for key in contador_incidencias_acumuladas:
		if contador_incidencias_acumuladas[key] >= UMBRALES.MEDIO:
			return true
	return false

# Mapeo temporal para conectar con los UUIDs que generamos en el paso anterior
func _obtener_uuid_por_codigo(codigo: String) -> String:
	# Estos UUIDs deben coincidir con los de tu script SQL
	match codigo:
		DIF_REDUNDANCIA: return "a1001001-0000-0000-0000-000000000001"
		DIF_NO_VALIDAR: return "a1001001-0000-0000-0000-000000000002"
		DIF_INNECESARIA: return "a1001001-0000-0000-0000-000000000003"
		DIF_BUCLE_INFINITO: return "c3003003-0000-0000-0000-000000000001"
		DIF_OPERADORES_LOGICOS: return "b2002002-0000-0000-0000-000000000001"
		DIF_VAR_NO_INIT: return "d4004004-0000-0000-0000-000000000002"
		# Agrega los demás si implementamos detección para ellos
	return ""
