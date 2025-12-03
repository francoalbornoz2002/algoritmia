class_name EjecutorAlgoritmo extends Node

# --- Referencias ---
var personaje: CharacterBody2D 
var controlador_nivel: Node2D

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
	"imprimir": -1 
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

# --- API DE INTROSPECCIÓN (Para Condiciones de Misión) ---

# Permite leer el valor final de una variable del alumno
func obtener_valor_variable(nombre: String):
	var nodo_runner = controlador_nivel.get_node_or_null("RunnerTemporal")
	if not is_instance_valid(nodo_runner): return null
	
	# Buscamos la propiedad en el script dinámico
	var valor_ref = nodo_runner.get(nombre)
	if valor_ref and "v" in valor_ref:
		return valor_ref.v
	return null

func obtener_funciones_definidas() -> Array:
	return funciones_definidas

func obtener_uso_estructura(nombre: String) -> int:
	return estructuras_usadas.get(nombre, 0)

# --- FUNCIÓN PRINCIPAL ---
func procesar_y_ejecutar(texto_codigo: String):
	# Limpieza de estado
	variables_registradas.clear()
	funciones_definidas.clear()
	metadatos_funciones.clear()
	estructuras_usadas = {"si": 0, "mientras": 0, "repetir": 0, "sino": 0}
	
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
	
	# FASE 0: Escaneo previo de funciones para validar llamadas antes de procesarlas
	_escanear_definiciones_funciones(lineas)
	
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
		
		# --- VALIDACIÓN 1: INDENTACIÓN ---
		var indent_curr_level = linea_normalizada.count("\t")
		
		if indent_expecting:
			if indent_curr_level <= indent_last_level:
				return { "error": true, "linea": i, "mensaje": "Error de Indentación: Se esperaba un bloque con sangría (Tab) después de la instrucción anterior." }
			indent_expecting = false
		
		# Actualizamos tracking de indentación
		indent_last_level = indent_curr_level
		
		# Detectamos si esta línea abre un bloque (termina en dos puntos implícitos o explícitos)
		# Keywords: Si, Sino, Mientras, Repetir, proceso
		if source.begins_with("Si ") or source == "Sino" or source == "Sino:" or \
		   source.begins_with("Mientras ") or source.begins_with("Repetir ") or source.begins_with("proceso "):
			indent_expecting = true
		
		# --- VALIDACIÓN 2: ARGUMENTOS EN LLAMADAS ---
		if "(" in source and not source.begins_with("proceso "):
			var err_args = _validar_argumentos_linea(source)
			if err_args != "":
				return { "error": true, "linea": i, "mensaje": err_args }
		
		# --- ANÁLISIS DE ESTRUCTURA ---
		if source.begins_with("Si "): estructuras_usadas["si"] += 1
		if source.begins_with("Mientras "): estructuras_usadas["mientras"] += 1
		if source.begins_with("Repetir "): estructuras_usadas["repetir"] += 1
		
		# --- ZONAS ---
		if source == "Inicio":
			encontro_inicio = true # Marcar flag
			zona = "MAIN"; main_code += "func run():\n"
			continue
		if source == "Fin":
			encontro_fin = true # Marcar flag
			if zona == "MAIN": main_code += "\t_ctrl_.on_ejecucion_terminada(true)\n"
			zona = "GLOBAL"
			continue
		if source.begins_with("proceso "):
			zona = "PROCESO"
			# Guardamos el nombre de la función para evaluarlo
			var nombre_proc = _extraer_nombre_proceso(source)
			funciones_definidas.append(nombre_proc)
			funciones_code += _procesar_cabecera_proceso(source) + "\n"
			continue

		# --- GENERACIÓN DE CÓDIGO ---
		var indent = _obtener_indentacion_segura(linea_normalizada)
		var codigo_generado = ""
		
		# Detectar si volvimos al margen izquierdo (Global)
		if zona == "PROCESO" and indent == "" and not source.begins_with("proceso "):
			zona = "GLOBAL"
		
		# 1. DECLARACIÓN
		if source.begins_with("var"):
			# VALIDACIÓN ESTRICTA: Debe ser "var " exacto.
			# Si escribe "var" (solo), "var  x" (doble espacio) o "var\tx" (tab), fallará aquí con mensaje claro.
			if not source.begins_with("var "):
				return { "error": true, "linea": i, "mensaje": "Sintaxis incorrecta. Se espera un solo espacio después de 'var'. Ejemplo: 'var numero: entero'." }
			
			var partes = source.split(":") 
			if partes.size() < 2:
				return { "error": true, "linea": i, "mensaje": "Declaración incompleta. Falta el tipo (ej: 'var x: entero')." }
			
			# Parseo del nombre
			var nombre_raw = partes[0].strip_edges() 
			# Quitamos el "var " inicial que ya sabemos que existe
			var nombre = nombre_raw.substr(4).strip_edges()
			
			# VALIDACIÓN: Nombre sin espacios internos
			# Si escribe "var mi numero: entero", nombre será "mi numero" -> Error
			if " " in nombre or "\t" in nombre:
				return { "error": true, "linea": i, "mensaje": "El nombre de la variable no puede contener espacios." }
			
			# Parseo del tipo
			var tipo = partes[1].strip_edges().to_lower()
			if tipo != "entero" and tipo != "real":
				return { "error": true, "linea": i, "mensaje": "Tipo desconocido '" + tipo + "'. Solo se permiten 'entero' o 'real'." }
			
			variables_registradas.append(nombre)
			
			var init_str = "AlgVar.new('" + tipo + "', _ctrl_, null)"
			
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
				return { "error": true, "linea": i, "mensaje": "Falta la palabra clave 'entonces' en la estructura Si." }
			# VALIDACIÓN: Variables en la condición
			var err_var = _validar_identificadores(source)
			if err_var != "": return { "error": true, "linea": i, "mensaje": err_var }
			
			var l = _inyectar_referencias(source)
			l = _procesar_matematicas_seguras(l)
			l = l.replace("Si ", "if ")
			l = l.replace(" entonces:", ":").replace(" entonces", ":")
			l = _procesar_condicion(l) # Aquí se arregla el AND -> and
			codigo_generado = indent + l
			
		elif source == "Sino" or source == "Sino:":
			codigo_generado = indent + "else:"
			
		elif source.begins_with("Mientras "):
			
			# VALIDACIÓN: Palabra clave 'hacer'
			if not ("hacer" in source or "Hacer" in source):
				return { "error": true, "linea": i, "mensaje": "Falta la palabra clave 'hacer' en la estructura Mientras." }
			# VALIDACIÓN: Variables
			var err_var = _validar_identificadores(source)
			if err_var != "": return { "error": true, "linea": i, "mensaje": err_var }
			
			var l = _inyectar_referencias(source)
			l = _procesar_matematicas_seguras(l)
			l = l.replace("Mientras ", "while ")
			l = l.replace(" hacer:", ":").replace(" hacer", ":")
			l = _procesar_condicion(l)
			codigo_generado = indent + l
			
		elif source.begins_with("Repetir "):
			var partes = source.replace(":", "").split(" ", false)
			if partes.size() >= 2:
				var veces = _inyectar_referencias(partes[1])
				veces = _procesar_matematicas_seguras(veces)
				veces = _procesar_condicion(veces)
				codigo_generado = indent + "for _iter_ in range(" + veces + "):"

		# 3. PRIMITIVAS
		elif source.begins_with("mapa(") and source.ends_with(")"):
			var args = source.trim_prefix("mapa(").trim_suffix(")").split(",")
			if args.size() == 2:
				var s = _procesar_condicion(_procesar_matematicas_seguras(_inyectar_referencias(args[0]))) + " - 1"
				var v = _procesar_condicion(_procesar_matematicas_seguras(_inyectar_referencias(args[1]))) + " - 1"
				codigo_generado = indent + "if not await _p_.intentar_teletransportar(Vector2i(" + s + ", " + v + ")): return"

		elif source.begins_with("imprimir(") and source.ends_with(")"):
			var idx1 = source.find("(")
			var idx2 = source.rfind(")")
			var contenido = source.substr(idx1+1, idx2-idx1-1)
			
			# VALIDACIÓN: Contenido vacío
			if contenido.strip_edges().is_empty():
				return { "error": true, "linea": i, "mensaje": "La instrucción 'imprimir' requiere al menos un valor o mensaje." }
			# VALIDACIÓN: Variables en argumentos
			var err_var = _validar_identificadores(contenido)
			if err_var != "": return { "error": true, "linea": i, "mensaje": err_var }
			
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
				return { "error": true, "linea": i, "mensaje": "La variable '" + lhs_raw + "' no ha sido declarada." }
			
			# VALIDACIÓN: Variables en la derecha (RHS)
			var err_var = _validar_identificadores(rhs_raw)
			if err_var != "": return { "error": true, "linea": i, "mensaje": err_var }
			
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
				codigo_generado = indent + "await " + _procesar_llamada_procedimiento(source)
				es_valido = true
				
			elif "++" in source or "--" in source:
				var l = source
				for v in variables_registradas:
					if v + "++" in l:
						l = "await " + v + ".set_val(" + v + ".v + 1)"
						break
					elif v + "--" in l:
						l = "await " + v + ".set_val(" + v + ".v - 1)"
						break
				if l == source:
					l = _inyectar_referencias(l)
					l = l.replace("++", ".v += 1").replace("--", ".v -= 1")
				codigo_generado = indent + l
				es_valido = true
			
			# --- VALIDACIÓN DE SINTAXIS ---
			# Si no entró en ninguno de los anteriores, es código basura (ej: "avnzr")
			if not es_valido:
				return { "error": true, "linea": i, "mensaje": "Instrucción no reconocida: '" + source + "'" }
		# Restauramos strings
		codigo_generado = _restaurar_strings(codigo_generado)
		
		if zona == "MAIN": main_code += codigo_generado + "\n"
		elif zona == "PROCESO": funciones_code += codigo_generado + "\n"
	
	
	# VALIDACIONES FINALES DE ESTRUCTURA
	if not encontro_inicio:
		return { "error": true, "linea": 0, "mensaje": "Falta la palabra clave 'Inicio' para comenzar el programa." }
	if not encontro_fin:
		return { "error": true, "linea": lineas.size(), "mensaje": "Falta la palabra clave 'Fin' al final del programa." }
	
	if main_code == "": return { "codigo": "" }
	
	# GENERACIÓN DEL SCRIPT
	var script = "extends Node\n"
	script += "var _p_: Node\n"
	script += "var _ctrl_: Node\n\n"
	
	script += "class AlgVar:\n"
	script += "\tvar v\n"
	script += "\tvar t\n"
	script += "\tvar c\n"
	script += "\tfunc _init(type, ctrl, val=null):\n"
	script += "\t\tv = val\n"
	script += "\t\tt = type\n"
	script += "\t\tc = ctrl\n"
	script += "\tfunc set_val(val):\n"
	script += "\t\tif t == 'entero' and typeof(val) == TYPE_FLOAT:\n"
	script += "\t\t\tif val != int(val):\n" 
	script += "\t\t\t\tc._on_jugador_game_over('Error de Tipo: No se puede asignar Real (' + str(val) + ') a Entero.')\n"
	script += "\t\t\t\tawait c.get_tree().create_timer(10.0).timeout\n"
	script += "\t\t\t\treturn\n"
	script += "\t\t\tval = int(val)\n" 
	script += "\t\tv = val\n\n"
	
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
	
	return { "codigo": script }

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
				var contenido = linea_limpia.substr(idx1+1, idx2-idx1-1).strip_edges()
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
	var nombre_func = palabras[palabras.size()-1]
	
	# Si es asignación o keyword, ignoramos (ej: Si (condicion))
	if nombre_func == "Si" or nombre_func == "Mientras": return ""
	
	# Contar argumentos pasados
	var contenido = linea.substr(idx1+1, idx2-idx1-1).strip_edges()
	var num_args_dados = 0
	if not contenido.is_empty():
		# OJO: Esto es simplificado. Si hay comas dentro de strings "a,b" fallaría.
		# Pero como ya ocultamos strings antes con _ocultar_strings, es seguro.
		num_args_dados = contenido.split(",").size()
	
	# 1. Validar Nativas
	if FIRMAS_NATIVAS.has(nombre_func):
		var esperados = FIRMAS_NATIVAS[nombre_func]
		if esperados != -1 and num_args_dados != esperados:
			return "Error de Llamada: La función '%s' espera %d argumentos, pero recibiste %d." % [nombre_func, esperados, num_args_dados]
			
	# 2. Validar Usuario
	elif metadatos_funciones.has(nombre_func):
		var esperados = metadatos_funciones[nombre_func]
		if num_args_dados != esperados:
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
		if ".v" in res and (variable + ".v") in res: continue
		res = regex.sub(res, variable + ".v", true)
	return res

func _procesar_llamada_procedimiento(linea: String) -> String:
	var idx1 = linea.find("(")
	var idx2 = linea.rfind(")")
	if idx1 == -1 or idx2 == -1: return linea
	
	# IMPORTANTE: Ya NO usamos to_lower() aquí para respetar el case sensitive
	var nombre_func = linea.substr(0, idx1).strip_edges()
	var args_raw = linea.substr(idx1+1, idx2-idx1-1).split(",")
	
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
		
		if modo == "E":
			codigo_clonacion += "\tvar _temp_" + nombre_param + " = AlgVar.new('" + tipo + "', _ctrl_, null)\n"
			codigo_clonacion += "\tawait _temp_" + nombre_param + ".set_val(" + nombre_param + ".v)\n"
			codigo_clonacion += "\t" + nombre_param + " = _temp_" + nombre_param + "\n"
			
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
