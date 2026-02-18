class_name EjecutorAlgoritmo extends Node

const MAX_ITERACIONES_BUCLE = 1000 # Límite para evitar crasheos por bucle infinito

# --- Referencias ---
var personaje: CharacterBody2D
var controlador_nivel: Node2D
# Variable de clase para guardar la referencia exacta
var runner_actual: Node

# --- Mapeo de Instrucciones (CASE SENSITIVE) ---
const COMANDOS_ATOMICOS = {
	"avanzar": "if not await _p_.avanzar(): return",
	"derecha": "await _p_.girar_derecha()",
	"saltar": "if not await _p_.saltar(): return",
	"atacar": "await _p_.atacar()",
	"recogerMoneda": "await _p_.recoger_moneda()",
	"recogerLlave": "await _p_.recoger_llave()",
	"abrirCofre": "await _p_.abrir_cofre()",
	"activarPuente": "await _p_.activar_puente()"
}

# Configuración de Argumentos Esperados (-1 = VarArgs)
const FIRMAS_NATIVAS = {
	"mapa": 2,
	"imprimir": - 1
}

const MAPEO_SENSORES = {
	"hayEnemigo": "_p_.hay_enemigo()",
	"hayObstaculo": "_p_.hay_obstaculo()",
	"hayPuente": "_p_.hay_puente()",
	"hayCofre": "_p_.hay_cofre()",
	"hayMoneda": "_p_.hay_moneda()",
	"hayLlave": "_p_.hay_llave()",
	"tengoMoneda": "_p_.tengo_moneda()",
	"tengoLlave": "_p_.tengo_llave()",
	"posSendero": "_p_.pos_sendero()",
	"posValle": "_p_.pos_valle()"
}

# --- ESTADO DEL TRANSPILADOR ---
var variables_registradas: Array[String] = []
var funciones_definidas: Array[String] = []
var estructuras_usadas: Dictionary = {}
var metadatos_funciones: Dictionary = {} # { "nombre": num_args }
var _string_cache = {}
var _string_idx = 0

# Variables para análisis estático (PR-03)
var _params_proceso_actual = {} # { "nombre_param": false } (false = no usado)
# Variables para análisis estático (PR-02)
var _params_es_proceso_actual = {} # { "nombre_param": false } (false = no modificado)
# Variables para análisis estático (VA-03)
var _var_usage_stats = {} # { "nombre": { "reads": 0, "writes": 0 } }

# Referencia al tamaño del mapa para validaciones estáticas (LP-02)
var tamano_mapa_ref: Vector2i = Vector2i(25, 25)

# --- API DE INTROSPECCIÓN (Para Condiciones de Misión) ---

# Permite leer el valor final de una variable del alumno
func obtener_valor_variable(nombre: String):
	if not is_instance_valid(runner_actual): return null
	
	# Buscamos la propiedad en el script dinámico
	var valor_ref = runner_actual.get(nombre)
	if valor_ref and "v" in valor_ref:
		return valor_ref.v
	return null

func obtener_funciones_definidas() -> Array:
	return funciones_definidas

func obtener_uso_estructura(nombre: String) -> int:
	return estructuras_usadas.get(nombre, 0)

# --- FUNCIÓN PRINCIPAL ---
func procesar_y_ejecutar(texto_codigo: String):
	# Limpiar runner anterior
	# Esto asegura que get_node("RunnerTemporal") siempre traiga el actual
	detener_ejecucion_inmediata()
	# Esperamos un frame para asegurar que queue_free actúe (opcional pero recomendado)
	await controlador_nivel.get_tree().process_frame
	
	# Limpieza de estado
	variables_registradas.clear()
	funciones_definidas.clear()
	metadatos_funciones.clear()
	estructuras_usadas = {"si": 0, "mientras": 0, "repetir": 0, "sino": 0}
	_params_proceso_actual.clear()
	_params_es_proceso_actual.clear()
	_var_usage_stats.clear()
	
	# --- NUEVO: FASE DE ANÁLISIS DE REDUNDANCIA (SL-01) ---
	_analizar_redundancia_estatica(texto_codigo)
	
	# 1. Transpilación con Linter (Validación)
	var resultado = _transpilar(texto_codigo)
	
	# 2. Verificamos si hubo error de sintaxis detectado
	if resultado.has("error"):
		controlador_nivel.mostrar_error_sintaxis(resultado["linea"], resultado["mensaje"])
		_finalizar_ejecucion(false)
		return
		
	var codigo_gdscript = resultado["codigo"]
	if codigo_gdscript == "":
		controlador_nivel.agregar_mensaje_consola("Error: Código vacío o sin Inicio/Fin", "ERROR")
		_finalizar_ejecucion(false)
		return

	print("--- CÓDIGO GDSCRIPT GENERADO ---\n", codigo_gdscript, "\n--------------------------------")
	_ejecutar_dinamicamente(codigo_gdscript)

# Helper para reportar al analista
func _reportar_dificultad(codigo: String, es_bloqueante: bool = false):
	if controlador_nivel and controlador_nivel.analista_dificultad:
		controlador_nivel.analista_dificultad.registrar_error_externo(codigo)
		# Si el error detiene la ejecución (sintaxis), debemos consolidar AHORA porque no habrá Game Over ni Victoria
		if es_bloqueante:
			controlador_nivel.analista_dificultad.consolidar_intento_actual()

func detener_ejecucion_inmediata():
	var nodo_runner = controlador_nivel.get_node_or_null("RunnerTemporal")
	if is_instance_valid(nodo_runner):
		nodo_runner.queue_free()
		print("--- Ejecutor: Script eliminado por seguridad ---")

func _finalizar_ejecucion(exito: bool):
	controlador_nivel.on_ejecucion_terminada(exito)

# --- EL TRANSPILADOR ---
func _transpilar(texto: String) -> Dictionary:
	var lineas = texto.split("\n")
	var loop_safety_count = 0
	
	# FASE 0: Escaneo previo de funciones para validar llamadas antes de procesarlas
	_escanear_definiciones_funciones(lineas)
	_analizar_estructuras_control(lineas)
	_analizar_anidamiento_ec03(lineas)
	
	var vars_globales_code = ""
	var vars_globales_init_code = ""
	var funciones_code = ""
	var main_code = ""
	var zona = "GLOBAL"
	
	# Banderas para verificar estructura principal
	var encontro_inicio = false
	var encontro_fin = false
	
	# Estado para validación de indentación
	var indent_expecting = false # ¿La línea anterior terminó en ':'?
	var indent_last_level = 0
	
	# --- SCOPE TRACKING (VA-01) ---
	var global_vars_scope: Array[String] = [] # Variables zona GLOBAL
	var local_scope_stack: Array[Array] = [[]] # Pila de scopes locales (Array de Arrays de Strings)
	var loop_depth_stack: Array[int] = [] # Pila para saber si estamos dentro de bucles (guarda el nivel de indent)
	# ------------------------------
	
	for i in range(lineas.size()):
		var linea = lineas[i]
		
		# 1. Normalización
		#var linea_normalizada = linea.replace("    ", "\t").replace("  ", "\t")
		var linea_normalizada = linea.replace("    ", "\t")
		
		# 2. Protección de Strings
		var linea_protegida = _ocultar_strings(linea_normalizada)
		
		# 3. Quitar comentarios
		var linea_sin_comentarios = linea_protegida.split("--")[0]
		
		var source = linea_sin_comentarios.strip_edges()
		
		if source.is_empty(): continue
		
		# --- ANÁLISIS ESTÁTICO LP-02 (Relacionales) ---
		if "posValle" in source or "posSendero" in source:
			_verificar_limites_estaticos(source)
		
		# --- VALIDACIÓN 1: INDENTACIÓN ---
		var indent_curr_level = linea_normalizada.count("\t")
		
		if indent_expecting:
			if indent_curr_level <= indent_last_level:
				return {"error": true, "linea": i, "mensaje": "Error de Indentación: Se esperaba un bloque con sangría (Tab) después de la instrucción anterior."}
			indent_expecting = false
		
		# Actualizamos tracking de indentación
		indent_last_level = indent_curr_level
		
		# --- GESTIÓN DE CIERRE DE SCOPES (VA-01) ---
		# Si la indentación bajó, cerramos scopes locales
		while local_scope_stack.size() > (indent_curr_level + 1):
			local_scope_stack.pop_back()
			
		# Si la indentación bajó, verificamos si salimos de un bucle
		while not loop_depth_stack.is_empty() and loop_depth_stack.back() >= indent_curr_level:
			loop_depth_stack.pop_back()
		
		# Detectamos si esta línea abre un bloque (termina en dos puntos implícitos o explícitos)
		# Keywords: Si, Sino, Mientras, Repetir, proceso
		if source.begins_with("Si ") or source == "Sino" or source == "Sino:" or \
		   source.begins_with("Mientras ") or source.begins_with("Repetir ") or source.begins_with("proceso "):
			indent_expecting = true
			# Preparamos un nuevo scope local para el bloque que se abrirá en la SIGUIENTE línea
			# Nota: Como procesamos línea a línea, el scope efectivo empieza cuando indent aumenta.
			# Pero para simplificar, aseguramos que el stack tenga tamaño suficiente.
			if local_scope_stack.size() <= (indent_curr_level + 1):
				local_scope_stack.append([])
		
		# --- VALIDACIÓN 2: ARGUMENTOS EN LLAMADAS ---
		if "(" in source and not source.begins_with("proceso "):
			var err_args = _validar_argumentos_linea(source)
			if err_args != "":
				return {"error": true, "linea": i, "mensaje": err_args}
		
		# --- ANÁLISIS DE ESTRUCTURA ---
		if source.begins_with("Si "): estructuras_usadas["si"] += 1
		if source.begins_with("Mientras "): estructuras_usadas["mientras"] += 1
		if source.begins_with("Repetir "): estructuras_usadas["repetir"] += 1
		
		# --- ZONAS ---
		if source == "Inicio":
			encontro_inicio = true # Marcar flag
			zona = "MAIN"; main_code += "func run():\n"
			# Resetear scopes locales al entrar a Main
			local_scope_stack = [[]]
			continue
		if source == "Fin":
			encontro_fin = true # Marcar flag
			if zona == "MAIN": main_code += "\t_ctrl_.on_ejecucion_terminada(true)\n"
			# Limpiar scopes locales al salir
			local_scope_stack = [[]]
			zona = "GLOBAL"
			continue
		if source.begins_with("proceso "):
			# Si veníamos de otro proceso, verificar PR-03 antes de cambiar
			if zona == "PROCESO":
				_verificar_uso_parametros_proceso()
				_verificar_modificacion_parametros_es()
			
			zona = "PROCESO"
			# Guardamos el nombre de la función para evaluarlo
			var nombre_proc = _extraer_nombre_proceso(source)
			funciones_definidas.append(nombre_proc)
			funciones_code += _procesar_cabecera_proceso(source) + "\n"
			# Resetear scopes locales al entrar a Proceso
			local_scope_stack = [[]]
			continue

		# --- ANÁLISIS DE USO DE PARÁMETROS (PR-03) ---
		if zona == "PROCESO":
			for param in _params_proceso_actual:
				if _palabra_en_linea(param, source):
					_params_proceso_actual[param] = true
			continue

		# --- GENERACIÓN DE CÓDIGO ---
		var indent = _obtener_indentacion_segura(linea_normalizada)
		var codigo_generado = ""
		
		# Detectar si volvimos al margen izquierdo (Global)
		if zona == "PROCESO" and indent == "" and not source.begins_with("proceso "):
			_verificar_uso_parametros_proceso() # Verificar el proceso que acaba de terminar
			_verificar_modificacion_parametros_es()
			zona = "GLOBAL"
		
		# 1. DECLARACIÓN
		if source.begins_with("var"):
			# VALIDACIÓN ESTRICTA: Debe ser "var " exacto.
			# Si escribe "var" (solo), "var  x" (doble espacio) o "var\tx" (tab), fallará aquí con mensaje claro.
			if not source.begins_with("var "):
				return {"error": true, "linea": i, "mensaje": "Sintaxis incorrecta. Se espera un solo espacio después de 'var'. Ejemplo: 'var numero: entero'."}
			
			var partes = source.split(":")
			if partes.size() < 2:
				return {"error": true, "linea": i, "mensaje": "Declaración incompleta. Falta el tipo (ej: 'var x: entero')."}
			
			# Parseo del nombre
			var nombre_raw = partes[0].strip_edges()
			# Quitamos el "var " inicial que ya sabemos que existe
			var nombre = nombre_raw.substr(4).strip_edges()
			
			# VALIDACIÓN: Nombre sin espacios internos
			# Si escribe "var mi numero: entero", nombre será "mi numero" -> Error
			if " " in nombre or "\t" in nombre:
				return {"error": true, "linea": i, "mensaje": "El nombre de la variable no puede contener espacios."}
			
			# Parseo del tipo
			var tipo = partes[1].strip_edges().to_lower()
			if tipo != "entero" and tipo != "real":
				return {"error": true, "linea": i, "mensaje": "Tipo desconocido '" + tipo + "'. Solo se permiten 'entero' o 'real'."}
			
			variables_registradas.append(nombre)
			
			# --- REGISTRO DE USO (VA-03) ---
			_var_usage_stats[nombre] = {"reads": 0, "writes": 0}
			
			# --- REGISTRO DE SCOPE (VA-01) ---
			if zona == "GLOBAL":
				global_vars_scope.append(nombre)
			else:
				# Estamos en local (Main o Proceso)
				# 1. Detectar redefinición en bucle
				if not loop_depth_stack.is_empty():
					_reportar_dificultad(AnalistaDificultad.DIF_SCOPE_VARS, false)
				
				# 2. Registrar en el scope actual (el último del stack)
				if local_scope_stack.is_empty(): local_scope_stack.append([])
				local_scope_stack.back().append(nombre)
			# ---------------------------------
			
			var init_str = "AlgVar.new('" + tipo + "', _ctrl_, '" + nombre + "', null)"
			
			if zona == "GLOBAL":
				vars_globales_code += "var " + nombre + "\n"
				vars_globales_init_code += "\t" + nombre + " = " + init_str + "\n"
			elif zona == "MAIN":
				main_code += indent + "var " + nombre + " = " + init_str + "\n"
			elif zona == "PROCESO":
				funciones_code += indent + "var " + nombre + " = " + init_str + "\n"
			continue

		# 2. ESTRUCTURAS DE CONTROL
		if source.begins_with("Si "):
			# VALIDACIÓN: Palabra clave 'entonces'
			if not ("entonces" in source or "Entonces" in source):
				return {"error": true, "linea": i, "mensaje": "Falta la palabra clave 'entonces' en la estructura Si."}
			# VALIDACIÓN: Variables en la condición
			var err_var = _validar_identificadores(source)
			if err_var != "": return {"error": true, "linea": i, "mensaje": err_var}
			
			# VALIDACIÓN VA-01: Verificar alcance de variables usadas
			if _verificar_alcance_vars_linea(source, global_vars_scope, local_scope_stack): return {"error": true, "linea": i, "mensaje": "Variable fuera de alcance (VA-01)."}
			
			# REGISTRO VA-03 (Lectura en condición)
			_registrar_lectura_vars(source)
			
			var l = _inyectar_referencias(source)
			l = _procesar_matematicas_seguras(l)
			l = l.replace("Si ", "if ")
			l = l.replace(" entonces:", ":").replace(" entonces", ":")
			l = _procesar_condicion(l) # Aquí se arregla el AND -> and
			
			# Agregamos "and not _ctrl_.juego_fallido" a la condición.
			# Si get_val() detecta error, activa 'juego_fallido', esto se vuelve FALSE y no entra al bloque.
			l = l.trim_suffix(":") + " and not _ctrl_.juego_fallido:"
			codigo_generado = indent + l
			
		elif source == "Sino" or source == "Sino:":
			codigo_generado = indent + "else:"
			
		elif source.begins_with("Mientras "):
			# VALIDACIÓN: Palabra clave 'hacer'
			if not ("hacer" in source or "Hacer" in source):
				return {"error": true, "linea": i, "mensaje": "Falta la palabra clave 'hacer' en la estructura Mientras."}
			# VALIDACIÓN: Variables
			var err_var = _validar_identificadores(source)
			if err_var != "": return {"error": true, "linea": i, "mensaje": err_var}
			
			# VALIDACIÓN VA-01
			if _verificar_alcance_vars_linea(source, global_vars_scope, local_scope_stack): return {"error": true, "linea": i, "mensaje": "Variable fuera de alcance (VA-01)."}
			
			# REGISTRO VA-03 (Lectura en condición)
			_registrar_lectura_vars(source)
			
			# --- INYECCIÓN DE SEGURIDAD ---
			loop_safety_count += 1
			var var_safety = "_safety_" + str(loop_safety_count)
			
			# 1. Declarar contador
			codigo_generado += indent + "var " + var_safety + " = 0\n"
			
			# 2. Línea del While
			var l = _inyectar_referencias(source)
			l = _procesar_matematicas_seguras(l)
			l = l.replace("Mientras ", "while ")
			l = l.replace(" hacer:", ":").replace(" hacer", ":")
			l = _procesar_condicion(l)
			
			# Agregamos "and not _ctrl_.juego_fallido" a la condición.
			# Si get_val() detecta error, activa 'juego_fallido', esto se vuelve FALSE y no entra al bloque.
			l = l.trim_suffix(":") + " and not _ctrl_.juego_fallido:"
			
			codigo_generado += indent + l + "\n"
			
			# 3. Chequeo de seguridad (dentro del bucle)
			var indent_inner = indent + "\t"
			codigo_generado += indent_inner + var_safety + " += 1\n"
			codigo_generado += indent_inner + "if " + var_safety + " > " + str(MAX_ITERACIONES_BUCLE) + ":\n"
			codigo_generado += indent_inner + "\t_ctrl_._on_jugador_game_over(\"Error Crítico: Bucle Infinito detectado (+1000 ciclos).\")\n"
			codigo_generado += indent_inner + "\tawait _ctrl_.get_tree().create_timer(0.1).timeout\n"
			codigo_generado += indent_inner + "\treturn" # Sin \n final, el loop principal lo añade
			
			# Registrar que entramos a un bucle (para VA-01)
			loop_depth_stack.append(indent_curr_level)
			
		elif source.begins_with("Repetir "):
			var partes = source.replace(":", "").split(" ", false)
			if partes.size() >= 2:
				# VALIDACIÓN VA-01
				if _verificar_alcance_vars_linea(partes[1], global_vars_scope, local_scope_stack): return {"error": true, "linea": i, "mensaje": "Variable fuera de alcance (VA-01)."}
				
				# REGISTRO VA-03 (Lectura en repeticiones)
				_registrar_lectura_vars(partes[1])
				
				var veces = _inyectar_referencias(partes[1])
				veces = _procesar_matematicas_seguras(veces)
				veces = _procesar_condicion(veces)
				# INYECCIÓN: Usamos min() para limitar las repeticiones
				codigo_generado = indent + "for _iter_ in range(min(" + veces + ", " + str(MAX_ITERACIONES_BUCLE) + ")):"

			# Registrar que entramos a un bucle (para VA-01)
			loop_depth_stack.append(indent_curr_level)

		# 3. PRIMITIVAS
		elif source.begins_with("mapa(") and source.ends_with(")"):
			var args = source.trim_prefix("mapa(").trim_suffix(")").split(",")
			if args.size() == 2:
				# VALIDACIÓN VA-01
				if _verificar_alcance_vars_linea(args[0] + " " + args[1], global_vars_scope, local_scope_stack): return {"error": true, "linea": i, "mensaje": "Variable fuera de alcance (VA-01)."}
				
				# REGISTRO VA-03 (Lectura en argumentos)
				_registrar_lectura_vars(args[0] + " " + args[1])
				
				var s = _procesar_condicion(_procesar_matematicas_seguras(_inyectar_referencias(args[0]))) + " - 1"
				var v = _procesar_condicion(_procesar_matematicas_seguras(_inyectar_referencias(args[1]))) + " - 1"
				codigo_generado = indent + "if not await _p_.intentar_teletransportar(Vector2i(" + s + ", " + v + ")): return"

		elif source.begins_with("imprimir(") and source.ends_with(")"):
			var idx1 = source.find("(")
			var idx2 = source.rfind(")")
			var contenido = source.substr(idx1 + 1, idx2 - idx1 - 1)
			
			# VALIDACIÓN: Contenido vacío
			if contenido.strip_edges().is_empty():
				return {"error": true, "linea": i, "mensaje": "La instrucción 'imprimir' requiere al menos un valor o mensaje."}
			# VALIDACIÓN: Variables en argumentos
			var err_var = _validar_identificadores(contenido)
			if err_var != "": return {"error": true, "linea": i, "mensaje": err_var}
			
			# VALIDACIÓN VA-01
			if _verificar_alcance_vars_linea(contenido, global_vars_scope, local_scope_stack): return {"error": true, "linea": i, "mensaje": "Variable fuera de alcance (VA-01)."}
			
			# REGISTRO VA-03 (Lectura en argumentos)
			_registrar_lectura_vars(contenido)
			
			contenido = _inyectar_referencias(contenido)
			contenido = _procesar_matematicas_seguras(contenido)
			contenido = _procesar_condicion(contenido)
			
			codigo_generado = indent + "await _p_.imprimir([" + contenido + "])"

		# 4. ASIGNACIONES
		elif ":=" in source or ("=" in source and not "(" in source):
			var sep = ":=" if ":=" in source else "="
			var partes_asig = source.split(sep)
			var lhs_raw = partes_asig[0].strip_edges()
			var rhs_raw = partes_asig[1].strip_edges()
			
			# VALIDACIÓN: ¿Existe la variable de la izquierda?
			if not lhs_raw in variables_registradas:
				return {"error": true, "linea": i, "mensaje": "La variable '" + lhs_raw + "' no ha sido declarada."}
			
			# VALIDACIÓN: Variables en la derecha (RHS)
			var err_var = _validar_identificadores(rhs_raw)
			if err_var != "": return {"error": true, "linea": i, "mensaje": err_var}
			
			# VALIDACIÓN VA-01 (Revisar ambos lados)
			if _verificar_alcance_vars_linea(source, global_vars_scope, local_scope_stack): return {"error": true, "linea": i, "mensaje": "Variable fuera de alcance (VA-01)."}
			
			# REGISTRO VA-03
			if _var_usage_stats.has(lhs_raw): _var_usage_stats[lhs_raw].writes += 1
			_registrar_lectura_vars(rhs_raw)
			
			# Detección PR-02: Asignación a parámetro ES
			if zona == "PROCESO" and _params_es_proceso_actual.has(lhs_raw):
				_params_es_proceso_actual[lhs_raw] = true
			
			if lhs_raw in variables_registradas:
				var rhs = _inyectar_referencias(rhs_raw)
				rhs = _procesar_matematicas_seguras(rhs)
				rhs = _procesar_condicion(rhs)
				codigo_generado = indent + "await " + lhs_raw + ".set_val(" + rhs + ")"
			else:
				var l = _inyectar_referencias(source)
				l = _procesar_matematicas_seguras(l)
				l = l.replace(":=", "=")
				l = _procesar_condicion(l)
				codigo_generado = indent + l

		# 5. LLAMADAS Y ATÓMICOS (Con Validación)
		else:
			var tokens = source.split(" ", false)
			var primera = tokens[0].replace("(", "").replace(")", "")
			var es_valido = false
			
			if COMANDOS_ATOMICOS.has(primera):
				codigo_generado = indent + COMANDOS_ATOMICOS[primera]
				es_valido = true
				
			elif "(" in source:
				# REGISTRO VA-03 (Lectura en argumentos de llamada)
				_registrar_lectura_vars(source)
				
				codigo_generado = indent + "await " + _procesar_llamada_procedimiento(source)
				es_valido = true
				
			elif "++" in source or "--" in source:
				# VALIDACIÓN VA-01
				if _verificar_alcance_vars_linea(source, global_vars_scope, local_scope_stack): return {"error": true, "linea": i, "mensaje": "Variable fuera de alcance (VA-01)."}
				
				# REGISTRO VA-03 (Incremento/Decremento cuenta como lectura y escritura)
				for v in variables_registradas:
					if v + "++" in source or v + "--" in source:
						if _var_usage_stats.has(v):
							_var_usage_stats[v].reads += 1
							_var_usage_stats[v].writes += 1
				
				var l = source
				for v in variables_registradas:
					if v + "++" in l:
						# Detección PR-02
						if zona == "PROCESO" and _params_es_proceso_actual.has(v): _params_es_proceso_actual[v] = true
						l = "await " + v + ".set_val(" + v + ".get_val() + 1)"
						break
					elif v + "--" in l:
						# Detección PR-02
						if zona == "PROCESO" and _params_es_proceso_actual.has(v): _params_es_proceso_actual[v] = true
						l = "await " + v + ".set_val(" + v + ".get_val() - 1)"
						break
				codigo_generado = indent + l
				es_valido = true
			
			# --- VALIDACIÓN DE SINTAXIS ---
			# Si no entró en ninguno de los anteriores, es código basura (ej: "avnzr")
			if not es_valido:
				return {"error": true, "linea": i, "mensaje": "Instrucción no reconocida: '" + source + "'"}
		# Restauramos strings
		codigo_generado = _restaurar_strings(codigo_generado)
		
		if zona == "MAIN": main_code += codigo_generado + "\n"
		elif zona == "PROCESO": funciones_code += codigo_generado + "\n"
	
	# Verificación final por si el archivo termina dentro de un proceso
	if zona == "PROCESO":
		_verificar_uso_parametros_proceso()
		_verificar_modificacion_parametros_es()
	
	_verificar_va03()
	
	# VALIDACIONES FINALES DE ESTRUCTURA
	if not encontro_inicio:
		return {"error": true, "linea": 0, "mensaje": "Falta la palabra clave 'Inicio' para comenzar el programa."}
	if not encontro_fin:
		return {"error": true, "linea": lineas.size(), "mensaje": "Falta la palabra clave 'Fin' al final del programa."}
	
	if main_code == "": return {"codigo": ""}
	
	# GENERACIÓN DEL SCRIPT
	var script = "extends Node\n"
	script += "var _p_: Node\n"
	script += "var _ctrl_: Node\n\n"
	
	script += "class AlgVar:\n"
	script += "\tvar v = null\n"
	script += "\tvar t\n"
	script += "\tvar c\n"
	script += "\tvar n\n"
	
	script += "\tfunc _init(type, ctrl, name_str, val=null):\n"
	script += "\t\tv = val\n"
	script += "\t\tt = type\n"
	script += "\t\tc = ctrl\n"
	script += "\t\tn = name_str\n"
	
	script += "\tfunc set_val(val):\n"
	script += "\t\tif t == 'entero' and typeof(val) == TYPE_FLOAT:\n"
	script += "\t\t\tif val != int(val):\n"
	script += "\t\t\t\tc._on_jugador_game_over('Error de Tipo: No se puede asignar Real (' + str(val) + ') a Entero.')\n"
	script += "\t\t\t\tawait c.get_tree().create_timer(10.0).timeout\n"
	script += "\t\t\t\treturn\n"
	script += "\t\t\tval = int(val)\n"
	script += "\t\tv = val\n\n"
	
	# --- NUEVO GETTER SEGURO (VA-02) ---
	script += "\tfunc get_val():\n"
	script += "\t\tif v == null:\n"
	script += "\t\t\t# Reportar VA-02 al Analista\n"
	script += "\t\t\tif c.analista_dificultad:\n"
	script += "\t\t\t\tc.analista_dificultad.registrar_error_externo('" + AnalistaDificultad.DIF_VAR_NO_INIT + "')\n"
	script += "\t\t\t\tc.analista_dificultad.consolidar_intento_actual()\n"
	
	script += "\t\t\tc._on_jugador_game_over('Error VA-02: La variable \"' + n + '\" se usó sin tener valor inicial.')\n"
	script += "\t\t\treturn 0\n" # Retorno dummy para no romper operaciones math inmediatas mientras muere
	script += "\t\treturn v\n\n"
	
	script += "func _div(a, b):\n"
	script += "\tif b == 0:\n"
	script += "\t\t_ctrl_._on_jugador_game_over(\"Error Matemático: División por cero\")\n"
	script += "\t\tawait _ctrl_.get_tree().create_timer(10.0).timeout\n"
	script += "\t\treturn 0\n"
	script += "\treturn a / b\n\n"

	script += "func _mod(a, b):\n"
	script += "\tif b == 0:\n"
	script += "\t\t_ctrl_._on_jugador_game_over(\"Error Matemático: Módulo por cero\")\n"
	script += "\t\tawait _ctrl_.get_tree().create_timer(10.0).timeout\n"
	script += "\t\treturn 0\n"
	script += "\treturn a % b\n\n"
	script += "# VARS GLOBALES\n" + vars_globales_code + "\n"
	
	# --- FIX DEL READY VACÍO ---
	script += "func _ready():\n"
	if vars_globales_init_code.strip_edges().is_empty():
		script += "\tpass\n"
	else:
		script += vars_globales_init_code + "\n"
	# ---------------------------
	
	script += "# FUNCS\n" + funciones_code + "\n"
	script += "# MAIN\n" + main_code
	
	return {"codigo": script}

# --- HELPERS DE ANÁLISIS ESTÁTICO (PR-03) ---

func _verificar_uso_parametros_proceso():
	for param in _params_proceso_actual:
		if _params_proceso_actual[param] == false:
			# Detectamos PR-03: Parámetro declarado pero no usado
			# No es bloqueante, solo registramos la dificultad
			_reportar_dificultad(AnalistaDificultad.DIF_PARAM_NO_USADO, false)
	_params_proceso_actual.clear()

func _verificar_modificacion_parametros_es():
	for param in _params_es_proceso_actual:
		if _params_es_proceso_actual[param] == false:
			# Detectamos PR-02: Parámetro ES declarado pero no modificado
			_reportar_dificultad(AnalistaDificultad.DIF_PARAM_NO_MODIFICADO, false)
	_params_es_proceso_actual.clear()

func _registrar_lectura_vars(linea: String):
	var regex = RegEx.new()
	regex.compile("[a-zA-Z_][a-zA-Z0-9_]*")
	var resultados = regex.search_all(linea)
	for res in resultados:
		var palabra = res.get_string()
		if _var_usage_stats.has(palabra):
			_var_usage_stats[palabra].reads += 1

func _verificar_va03():
	for var_name in _var_usage_stats:
		var stats = _var_usage_stats[var_name]
		# Caso 1: Declarada pero no leída (ni usada en condiciones/cálculos)
		# Esto cubre "Declarada no usada" y "Asignada pero no leída"
		if stats.reads == 0:
			_reportar_dificultad(AnalistaDificultad.DIF_VAR_INCONSISTENTE, false)

func _verificar_limites_estaticos(linea: String):
	# Regex para detectar "posValle > N" (LP-02: Comparación imposible)
	var regex = RegEx.new()
	regex.compile("posValle\\s*>\\s*(\\d+)")
	var matches = regex.search_all(linea)
	for m in matches:
		var val = int(m.get_string(1))
		if val >= tamano_mapa_ref.y:
			_reportar_dificultad(AnalistaDificultad.DIF_RELACIONALES, false)

	regex.compile("posSendero\\s*>\\s*(\\d+)")
	matches = regex.search_all(linea)
	for m in matches:
		var val = int(m.get_string(1))
		if val >= tamano_mapa_ref.x:
			_reportar_dificultad(AnalistaDificultad.DIF_RELACIONALES, false)

func _palabra_en_linea(palabra: String, linea: String) -> bool:
	# Búsqueda simple de palabra completa usando regex
	var regex = RegEx.new()
	regex.compile("\\b" + palabra + "\\b")
	return regex.search(linea) != null

# --- ANÁLISIS DE ESTRUCTURAS DE CONTROL (EC-02) ---

func _analizar_estructuras_control(lineas: Array):
	var i = 0
	while i < lineas.size():
		var linea = lineas[i]
		var linea_norm = linea.replace("    ", "\t")
		var indent = linea_norm.count("\t")
		# Limpieza básica para detectar keywords
		var content = linea_norm.split("--")[0].strip_edges()
		
		if content.begins_with("Si ") and ("entonces" in content or "Entonces" in content):
			# Encontramos un bloque Si. Vamos a escanear su contenido y buscar su Sino.
			var si_indent = indent
			var block_si = []
			var block_sino = []
			var has_sino = false
			
			# Avanzamos para capturar el cuerpo
			var j = i + 1
			while j < lineas.size():
				var l_sub = lineas[j].replace("    ", "\t")
				var sub_indent = l_sub.count("\t")
				var sub_content = l_sub.split("--")[0].strip_edges()
				
				if sub_content.is_empty(): # Ignorar líneas vacías
					j += 1
					continue
				
				if sub_indent <= si_indent:
					# Se acabó el bloque Si (o encontramos el Sino)
					if sub_content == "Sino" or sub_content == "Sino:":
						has_sino = true
						j += 1 # Consumir la línea del Sino
						# Capturar bloque Sino
						while j < lineas.size():
							var l_sino = lineas[j].replace("    ", "\t")
							var sino_indent = l_sino.count("\t")
							var sino_content = l_sino.split("--")[0].strip_edges()
							
							if sino_content.is_empty():
								j += 1
								continue
							
							if sino_indent <= si_indent:
								break # Fin del Sino
							
							block_sino.append(sino_content)
							j += 1
					break # Fin del análisis de este Si/Sino
				
				block_si.append(sub_content)
				j += 1
			
			if has_sino:
				_verificar_ec02(block_si, block_sino)
		
		i += 1

func _verificar_ec02(block_si: Array, block_sino: Array):
	# Caso 1: Sino Vacío
	if block_sino.is_empty():
		_reportar_dificultad(AnalistaDificultad.DIF_SI_SINO, false)
		return

	# Caso 2: Bloques Idénticos (Incoherencia)
	if block_si == block_sino:
		_reportar_dificultad(AnalistaDificultad.DIF_SI_SINO, false)
		return

	# Caso 3: Redundancia de Cola (Tail Redundancy)
	# Si la última instrucción de ambos bloques es igual, debería estar afuera.
	if not block_si.is_empty() and not block_sino.is_empty():
		if block_si.back() == block_sino.back():
			_reportar_dificultad(AnalistaDificultad.DIF_SI_SINO, false)

# --- ANÁLISIS DE ANIDAMIENTO (EC-03) ---

func _analizar_anidamiento_ec03(lineas: Array):
	var stack = [] # Array de diccionarios { "indent": int, "type": String, "dirty": bool }
	
	for linea in lineas:
		var linea_norm = linea.replace("    ", "\t")
		var source = linea_norm.strip_edges()
		
		# Ignorar líneas vacías o comentarios
		if source.is_empty() or source.begins_with("--") or source.begins_with("#"):
			continue
			
		var indent = linea_norm.count("\t")
		
		# Sacar de la pila los bloques que ya se cerraron (indentación menor o igual)
		while not stack.is_empty() and stack.back().indent >= indent:
			stack.pop_back()
			
		if source.begins_with("Si "):
			# Verificar si el padre inmediato es un Si o un Sino
			if not stack.is_empty():
				var parent = stack.back()
				# Solo reportamos si el padre es Si/Sino Y NO ha tenido contenido intermedio (dirty == false)
				if (parent.type == "Si" or parent.type == "Sino") and not parent.dirty:
					_reportar_dificultad(AnalistaDificultad.DIF_CONDICIONALES_ANIDADOS, false)
			stack.append({"indent": indent, "type": "Si", "dirty": false})
			
		elif source.begins_with("Sino") or source.begins_with("Sino:"):
			stack.append({"indent": indent, "type": "Sino", "dirty": false})
		
		else:
			# Cualquier otra instrucción (Mientras, Repetir, Asignación, Primitiva)
			# marca el bloque actual como "sucio" (ya tiene contenido previo)
			if not stack.is_empty():
				stack.back().dirty = true

# --- VERIFICACIÓN DE ALCANCE (VA-01) ---

func _verificar_alcance_vars_linea(linea: String, globals: Array, local_stack: Array) -> bool:
	# Retorna TRUE si hay error de alcance (VA-01)
	var regex = RegEx.new()
	regex.compile("[a-zA-Z_][a-zA-Z0-9_]*")
	var resultados = regex.search_all(linea)
	
	for res in resultados:
		var palabra = res.get_string()
		# Si es una variable registrada (es decir, existe en el programa)
		if palabra in variables_registradas:
			# Verificar si está visible en el scope actual
			var visible = false
			if palabra in globals: visible = true
			else:
				for scope in local_stack:
					if palabra in scope:
						visible = true
						break
			
			if not visible:
				_reportar_dificultad(AnalistaDificultad.DIF_SCOPE_VARS, true)
				return true # Error encontrado
	return false

# --- HELPERS DE VALIDACIÓN ---

func _escanear_definiciones_funciones(lineas: Array):
	for l in lineas:
		var linea_limpia = l.strip_edges()
		if linea_limpia.begins_with("proceso "):
			var nombre = _extraer_nombre_proceso(linea_limpia)
			# Contamos cuántas comas hay para estimar argumentos
			# proceso x(E a, E b) -> 1 coma -> 2 args. Sin coma -> 1 arg. () -> 0 args.
			var idx1 = linea_limpia.find("(")
			var idx2 = linea_limpia.rfind(")")
			if idx1 != -1 and idx2 != -1:
				var contenido = linea_limpia.substr(idx1 + 1, idx2 - idx1 - 1).strip_edges()
				if contenido.is_empty():
					metadatos_funciones[nombre] = 0
				else:
					# Split por coma ignorando espacios
					var args = contenido.split(",")
					metadatos_funciones[nombre] = args.size()

func _validar_argumentos_linea(linea: String) -> String:
	# Busca llamadas tipo nombre(...)
	var idx1 = linea.find("(")
	var idx2 = linea.rfind(")")
	if idx1 == -1 or idx2 == -1: return "" # No es llamada
	
	# Extraer nombre funcion
	# Puede ser:  mapa(  o  miVar = suma(
	var pre_paren = linea.substr(0, idx1)
	# Buscamos la última palabra antes del paréntesis
	var palabras = pre_paren.split(" ", false)
	if palabras.is_empty(): return ""
	var nombre_func = palabras[palabras.size() - 1]
	
	# Si es asignación o keyword, ignoramos (ej: Si (condicion))
	if nombre_func == "Si" or nombre_func == "Mientras": return ""
	
	# Contar argumentos pasados
	var contenido = linea.substr(idx1 + 1, idx2 - idx1 - 1).strip_edges()
	var num_args_dados = 0
	if not contenido.is_empty():
		# OJO: Esto es simplificado. Si hay comas dentro de strings "a,b" fallaría.
		# Pero como ya ocultamos strings antes con _ocultar_strings, es seguro.
		num_args_dados = contenido.split(",").size()
	
	# 1. Validar Nativas
	if FIRMAS_NATIVAS.has(nombre_func):
		var esperados = FIRMAS_NATIVAS[nombre_func]
		if esperados != -1 and num_args_dados != esperados:
			_reportar_dificultad(AnalistaDificultad.DIF_MAL_PARAMETROS, true)
			return "Error de Llamada: La función '%s' espera %d argumentos, pero recibiste %d." % [nombre_func, esperados, num_args_dados]
			
	# 2. Validar Usuario
	elif metadatos_funciones.has(nombre_func):
		var esperados = metadatos_funciones[nombre_func]
		if num_args_dados != esperados:
			_reportar_dificultad(AnalistaDificultad.DIF_MAL_PARAMETROS, true)
			return "Error de Llamada: El proceso '%s' espera %d argumentos, pero recibiste %d." % [nombre_func, esperados, num_args_dados]
			
	return ""

# Extraer nombre del proceso
func _extraer_nombre_proceso(linea: String) -> String:
	# "proceso miFuncion(..." -> "miFuncion"
	var idx_proceso = linea.find("proceso ") + 8
	var idx_paren = linea.find("(")
	if idx_paren == -1: return ""
	return linea.substr(idx_proceso, idx_paren - idx_proceso).strip_edges()

# Procesar condiciones
func _procesar_condicion(linea: String) -> String:
	var res = linea
	var regex_ops = RegEx.new()
	
	# 1. Operadores Lógicos (AND/OR -> and/or)
	regex_ops.compile("\\bAND\\b")
	res = regex_ops.sub(res, "and", true)
	
	regex_ops.compile("\\bOR\\b")
	res = regex_ops.sub(res, "or", true)
	
	regex_ops.compile("\\bNOT\\b")
	res = regex_ops.sub(res, "not", true)
	res = res.replace("~", " not ")
	
	# 2. Sensores (Estrictos, Case Sensitive)
	for sensor in MAPEO_SENSORES:
		regex_ops.compile("\\b" + sensor + "\\b")
		res = regex_ops.sub(res, MAPEO_SENSORES[sensor], true)
		
	return res

# Procesar operaciones matemáticas de manera segura
func _procesar_matematicas_seguras(linea: String) -> String:
	var regex_mod = RegEx.new()
	regex_mod.compile("\\s+mod\\s+")
	var res = regex_mod.sub(linea, " % ", true)

	var regex_div = RegEx.new()
	regex_div.compile("([a-zA-Z0-9_.]+(?:\\.v)?)\\s*([/%])\\s*([a-zA-Z0-9_.]+(?:\\.v)?)")
	
	var max_iteraciones = 10
	var iter = 0
	
	while iter < max_iteraciones:
		var match_result = regex_div.search(res)
		if not match_result:
			break
			
		var todo = match_result.get_string()
		var op1 = match_result.get_string(1)
		var operador = match_result.get_string(2)
		var op2 = match_result.get_string(3)
		
		var reemplazo = ""
		if operador == "/":
			reemplazo = "await _div(" + op1 + ", " + op2 + ")"
		else:
			reemplazo = "await _mod(" + op1 + ", " + op2 + ")"
			
		res = res.replace(todo, reemplazo)
		iter += 1
		
	return res

func _ocultar_strings(texto: String) -> String:
	_string_cache.clear()
	_string_idx = 0
	var regex = RegEx.new()
	regex.compile("\"([^\"]*)\"")
	
	var resultados = regex.search_all(texto)
	var texto_seguro = texto
	
	for i in range(resultados.size() - 1, -1, -1):
		var match_result = resultados[i]
		var string_original = match_result.get_string()
		var placeholder = "__STR_" + str(_string_idx) + "__"
		_string_cache[placeholder] = string_original
		_string_idx += 1
		
		texto_seguro = texto_seguro.erase(match_result.get_start(), string_original.length())
		texto_seguro = texto_seguro.insert(match_result.get_start(), placeholder)
		
	return texto_seguro

func _restaurar_strings(texto: String) -> String:
	var texto_final = texto
	for placeholder in _string_cache:
		texto_final = texto_final.replace(placeholder, _string_cache[placeholder])
	return texto_final

func _inyectar_referencias(linea: String) -> String:
	var res = linea
	var regex = RegEx.new()
	for variable in variables_registradas:
		regex.compile("\\b" + variable + "\\b")
		
		# Si ya tiene .v o .set_val, lo ignoramos (evitar doble inyección)
		if ".v" in res and (variable + ".v") in res: continue
		if ".set_val" in res and (variable + ".set_val") in res: continue
		if ".get_val" in res and (variable + ".get_val") in res: continue
		
		# Usamos el getter seguro
		res = regex.sub(res, variable + ".get_val()", true)
	return res

func _procesar_llamada_procedimiento(linea: String) -> String:
	var idx1 = linea.find("(")
	var idx2 = linea.rfind(")")
	if idx1 == -1 or idx2 == -1: return linea
	
	# IMPORTANTE: Ya NO usamos to_lower() aquí para respetar el case sensitive
	var nombre_func = linea.substr(0, idx1).strip_edges()
	var args_raw = linea.substr(idx1 + 1, idx2 - idx1 - 1).split(",")
	
	var args_procesados = []
	for arg in args_raw:
		arg = arg.strip_edges()
		if arg.is_empty(): continue
		
		if arg in variables_registradas:
			args_procesados.append(arg)
		else:
			var arg_valor = _inyectar_referencias(arg)
			arg_valor = _procesar_matematicas_seguras(arg_valor)
			arg_valor = _procesar_condicion(arg_valor)
			args_procesados.append("AlgVar.new('temp', _ctrl_, " + arg_valor + ")")
			
	return nombre_func + "(" + ", ".join(args_procesados) + ")"

func _procesar_cabecera_proceso(linea_raw: String) -> String:
	var linea = linea_raw.strip_edges().replace("proceso ", "func ")
	var idx_paren = linea.find("(")
	var nombre_func = linea.substr(5, idx_paren - 5).strip_edges()
	
	var contenido_params = linea.substr(idx_paren + 1, linea.rfind(")") - idx_paren - 1)
	
	var lista_params = contenido_params.split(",", false)
	
	var params_gd = []
	var codigo_clonacion = ""
	
	_params_proceso_actual.clear()
	_params_es_proceso_actual.clear()
	
	for p in lista_params:
		p = p.strip_edges().replace("\t", " ")
		if p.is_empty(): continue
		var partes = p.split(" ", false)
		if partes.size() < 2: continue
		
		var modo = partes[0].to_upper()
		var nombre_param = partes[1].replace(":", "")
		
		var tipo = "entero"
		if partes.size() > 2:
			tipo = partes[2].to_lower()
		
		variables_registradas.append(nombre_param)
		params_gd.append(nombre_param)
		
		# Registramos para seguimiento de PR-03 (inicialmente false = no usado)
		_params_proceso_actual[nombre_param] = false
		
		if modo == "E":
			codigo_clonacion += "\tvar _temp_" + nombre_param + " = AlgVar.new('" + tipo + "', _ctrl_, '" + nombre_param + "', null)\n"
			codigo_clonacion += "\tawait _temp_" + nombre_param + ".set_val(" + nombre_param + ".get_val())\n"
			codigo_clonacion += "\t" + nombre_param + " = _temp_" + nombre_param + "\n"
		elif modo == "ES":
			# Registramos para seguimiento de PR-02 (inicialmente false = no modificado)
			_params_es_proceso_actual[nombre_param] = false
			
	return "func " + nombre_func + "(" + ", ".join(params_gd) + "):\n" + codigo_clonacion

func _obtener_indentacion_segura(linea: String) -> String:
	var indent = ""
	for c in linea:
		if c == "\t": indent += "\t"
		else: break
	return indent

func _ejecutar_dinamicamente(codigo: String):
	var script = GDScript.new()
	script.source_code = codigo
	var err = script.reload()
	if err != OK:
		controlador_nivel.agregar_mensaje_consola("Error interno Parser: " + str(err), "ERROR")
		_finalizar_ejecucion(false)
		return
		
	var nodo = Node.new()
	nodo.name = "RunnerTemporal"
	nodo.set_script(script)
	nodo._p_ = personaje
	nodo._ctrl_ = controlador_nivel
	controlador_nivel.add_child(nodo)
	runner_actual = nodo
	nodo.call_deferred("run")


func _validar_identificadores(linea: String) -> String:
	# Busca palabras que parecen variables y verifica si existen
	var regex = RegEx.new()
	regex.compile("[a-zA-Z_][a-zA-Z0-9_]*") # Identificadores
	var resultados = regex.search_all(linea)
	
	# Palabras que NO son variables pero pueden aparecer en código
	var palabras_reservadas = ["Si", "Sino", "Mientras", "Repetir", "Inicio", "Fin", "var", "proceso", "entonces", "hacer", "and", "or", "not", "AND", "OR", "NOT", "E", "ES", "entero", "real", "mod", "true", "false", "mapa", "imprimir"]
	
	for res in resultados:
		var palabra = res.get_string()
		
		# 1. Ignoramos palabras clave del lenguaje
		if palabra in palabras_reservadas: continue
		# 2. Ignoramos comandos del juego (avanzar, etc)
		if COMANDOS_ATOMICOS.has(palabra): continue
		# 3. Ignoramos sensores (hayEnemigo)
		if MAPEO_SENSORES.has(palabra): continue
		# 4. Ignoramos funciones nativas (mapa)
		if FIRMAS_NATIVAS.has(palabra): continue
		# 5. Ignoramos funciones del usuario
		if metadatos_funciones.has(palabra): continue
		# 6. Ignoramos placeholders de strings (__STR_0__)
		if palabra.begins_with("__STR_"): continue
		
		# 7. CRÍTICO: Si no es nada de lo anterior, DEBE ser una variable registrada
		if not palabra in variables_registradas:
			return "Identificador '" + palabra + "' no declarado (¿Variable mal escrita o inexistente?)."
			
	return ""

func _analizar_redundancia_estatica(texto: String):
	var lineas = texto.split("\n")
	var ultima_accion = ""
	var repeticiones = 0
	
	for linea in lineas:
		# Limpiamos espacios y comentarios
		var linea_limpia = linea.strip_edges().split("--")[0].strip_edges()
		
		if linea_limpia.is_empty():
			continue
			
		# Verificamos si la línea es un comando atómico (avanzar, atacar, etc.)
		var es_atomico = false
		# Extraemos el primer token y limpiamos paréntesis para ser consistentes con el transpiler
		var partes = linea_limpia.split(" ", false)
		if partes.is_empty(): continue
		
		var token = partes[0].replace("(", "").replace(")", "")
		
		if COMANDOS_ATOMICOS.has(token):
			es_atomico = true
		
		if es_atomico:
			if token == ultima_accion:
				repeticiones += 1
			else:
				# Cambio de acción, reseteamos
				ultima_accion = token
				repeticiones = 1
		else:
			# Si encontramos una estructura (Si, Mientras, Fin, var...), rompemos la racha
			ultima_accion = ""
			repeticiones = 0
			
		# --- EVALUACIÓN DE UMBRALES ---
		if ultima_accion != "":
			var umbral = 2 # Por defecto (acciones complejas como recoger, atacar)
			if ultima_accion == "avanzar":
				umbral = 3 # Somos más permisivos con avanzar
			
			if repeticiones >= umbral:
				# Reportamos SL-01
				_reportar_dificultad(AnalistaDificultad.DIF_REDUNDANCIA, false)
				return # Con detectar una redundancia basta por este intento
