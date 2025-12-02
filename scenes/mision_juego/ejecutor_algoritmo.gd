class_name EjecutorAlgoritmo extends Node

# --- Referencias ---
var personaje: CharacterBody2D 
var controlador_nivel: Node2D

# --- Mapeo de Instrucciones ---
const COMANDOS_ATOMICOS = {
	"avanzar": "if not await _p_.avanzar(): return",
	"derecha": "await _p_.girar_derecha()",
	"saltar": "if not await _p_.saltar(): return",
	"atacar": "await _p_.atacar()",
	"recogermoneda": "await _p_.recoger_moneda()",
	"recogerllave": "await _p_.recoger_llave()",
	"abrircofre": "await _p_.abrir_cofre()",
	"activarpuente": "await _p_.activar_puente()"
}

const MAPEO_SENSORES = {
	"hayenemigo": "_p_.hay_enemigo()",
	"hayobstaculo": "_p_.hay_obstaculo()",
	"haypuente": "_p_.hay_puente()",
	"haycofre": "_p_.hay_cofre()",
	"haymoneda": "_p_.hay_moneda()",
	"hayllave": "_p_.hay_llave()",
	"tengomoneda": "_p_.tengo_moneda()",
	"tengollave": "_p_.tengo_llave()",
	"possendero": "_p_.pos_sendero()",
	"posvalle": "_p_.pos_valle()"
}

# --- ESTADO DEL TRANSPILADOR ---
var variables_registradas: Array[String] = []
var _string_cache = {} 
var _string_idx = 0

# --- FUNCIÓN PRINCIPAL ---
func procesar_y_ejecutar(texto_codigo: String):
	variables_registradas.clear()
	var codigo_gdscript = _transpilar(texto_codigo)
	
	if codigo_gdscript == "":
		controlador_nivel.agregar_mensaje_consola("Error: Código vacío o sin Inicio/Fin", "ERROR")
		_finalizar_ejecucion(false)
		return

	_ejecutar_dinamicamente(codigo_gdscript)

func detener_ejecucion_inmediata():
	var nodo_runner = controlador_nivel.get_node_or_null("RunnerTemporal")
	if is_instance_valid(nodo_runner):
		nodo_runner.queue_free()
		print("--- Ejecutor: Script eliminado por seguridad ---")

func _finalizar_ejecucion(exito: bool):
	var nodo_runner = controlador_nivel.get_node_or_null("RunnerTemporal")
	if is_instance_valid(nodo_runner):
		nodo_runner.queue_free()
	controlador_nivel.on_ejecucion_terminada(exito)

# --- EL TRANSPILADOR ---
func _transpilar(texto: String) -> String:
	var lineas = texto.split("\n")
	
	var vars_globales_code = ""
	var vars_globales_init_code = "" # NUEVO: Código para inicializar globales en _ready
	var funciones_code = ""
	var main_code = ""
	var zona = "GLOBAL"
	
	for linea in lineas:
		# 1. Normalización
		var linea_normalizada = linea.replace("    ", "\t")
		var linea_protegida = _ocultar_strings(linea_normalizada)
		var linea_sin_comentarios = linea_protegida.split("--")[0]
		
		var source = linea_sin_comentarios.strip_edges()
		var linea_lower = source.to_lower()
		
		if source.is_empty(): continue
		
		# --- ZONAS ---
		if linea_lower == "inicio":
			zona = "MAIN"
			main_code += "func run():\n"
			continue
		if linea_lower == "fin":
			if zona == "MAIN": main_code += "\t_ctrl_.on_ejecucion_terminada(true)\n"
			zona = "GLOBAL"
			continue
		if linea_lower.begins_with("proceso "):
			zona = "PROCESO"
			funciones_code += _procesar_cabecera_proceso(source) + "\n"
			continue

		# --- PROCESAMIENTO ---
		var indent = _obtener_indentacion_segura(linea_normalizada)
		var codigo_generado = ""
		
		# 1. DECLARACIÓN
		if linea_lower.begins_with("var "):
			var partes = source.split(":") 
			if partes.size() > 0:
				var nombre_raw = partes[0].strip_edges() 
				var nombre = ""
				if nombre_raw.to_lower().begins_with("var "):
					nombre = nombre_raw.substr(4).strip_edges()
				else:
					nombre = nombre_raw
				
				var tipo = "entero"
				if partes.size() > 1:
					tipo = partes[1].strip_edges().to_lower()
				
				variables_registradas.append(nombre)
				
				# Construimos la parte derecha de la inicialización
				var init_str = "Ref.new('" + tipo + "', _ctrl_, null)"
				
				if zona == "GLOBAL":
					# GLOBAL: Separamos declaración de inicialización
					vars_globales_code += "var " + nombre + "\n"
					vars_globales_init_code += "\t" + nombre + " = " + init_str + "\n"
				elif zona == "MAIN": 
					main_code += indent + "var " + nombre + " = " + init_str + "\n"
				elif zona == "PROCESO": 
					funciones_code += indent + "var " + nombre + " = " + init_str + "\n"
			continue

		# 2. ESTRUCTURAS DE CONTROL
		if linea_lower.begins_with("si "):
			var l = _inyectar_referencias(source)
			l = _procesar_matematicas_seguras(l)
			l = l.replace("Si ", "if ").replace("si ", "if ")
			l = l.replace(" entonces:", ":").replace(" entonces", ":")
			l = _procesar_condicion(l)
			codigo_generado = indent + l
			
		elif linea_lower == "sino" or linea_lower == "sino:":
			codigo_generado = indent + "else:"
			
		elif linea_lower.begins_with("mientras "):
			var l = _inyectar_referencias(source)
			l = _procesar_matematicas_seguras(l)
			l = l.replace("Mientras ", "while ").replace("mientras ", "while ")
			l = l.replace(" hacer:", ":").replace(" hacer", ":")
			l = _procesar_condicion(l)
			codigo_generado = indent + l
			
		elif linea_lower.begins_with("repetir "):
			var partes = source.replace(":", "").split(" ", false)
			if partes.size() >= 2:
				var veces = _inyectar_referencias(partes[1])
				veces = _procesar_matematicas_seguras(veces)
				veces = _procesar_condicion(veces)
				codigo_generado = indent + "for _iter_ in range(" + veces + "):"

		# 3. PRIMITIVAS
		elif linea_lower.begins_with("mapa(") and linea_lower.ends_with(")"):
			var args = source.trim_prefix("mapa(").trim_suffix(")").split(",")
			if args.size() == 2:
				var s = _procesar_condicion(_procesar_matematicas_seguras(_inyectar_referencias(args[0]))) + " - 1"
				var v = _procesar_condicion(_procesar_matematicas_seguras(_inyectar_referencias(args[1]))) + " - 1"
				codigo_generado = indent + "if not await _p_.intentar_teletransportar(Vector2i(" + s + ", " + v + ")): return"

		elif linea_lower.begins_with("imprimir(") and linea_lower.ends_with(")"):
			var idx1 = source.find("(")
			var idx2 = source.rfind(")")
			var contenido = source.substr(idx1+1, idx2-idx1-1)
			
			contenido = _inyectar_referencias(contenido)
			contenido = _procesar_matematicas_seguras(contenido)
			contenido = _procesar_condicion(contenido)
			
			codigo_generado = indent + "await _p_.imprimir([" + contenido + "])"

		# 4. ASIGNACIONES
		elif ":=" in linea_lower or ("=" in linea_lower and not "(" in linea_lower):
			var sep = ":=" if ":=" in source else "="
			var partes_asig = source.split(sep)
			var lhs_raw = partes_asig[0].strip_edges()
			var rhs_raw = partes_asig[1].strip_edges()
			
			if lhs_raw in variables_registradas:
				var rhs = _inyectar_referencias(rhs_raw)
				rhs = _procesar_matematicas_seguras(rhs)
				rhs = _procesar_condicion(rhs)
				codigo_generado = indent + "await " + lhs_raw + ".set_val(" + rhs + ")"
			else:
				var l = _inyectar_referencias(source)
				l = _procesar_matematicas_seguras(l)
				l = l.replace(":=", "=")
				codigo_generado = indent + _procesar_condicion(l)

		# 5. LLAMADAS Y ATÓMICOS
		else:
			var tokens = linea_lower.split(" ", false)
			var primera = tokens[0].replace("(", "").replace(")", "")
			
			if COMANDOS_ATOMICOS.has(primera):
				codigo_generado = indent + COMANDOS_ATOMICOS[primera]
				
			elif "(" in linea_lower:
				codigo_generado = indent + "await " + _procesar_llamada_procedimiento(source)
				
			elif "++" in linea_lower or "--" in linea_lower:
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
				
			else:
				var l = _inyectar_referencias(source)
				l = _procesar_matematicas_seguras(l)
				codigo_generado = indent + l

		# AL FINAL: Restauramos strings
		codigo_generado = _restaurar_strings(codigo_generado)
		
		if zona == "MAIN": main_code += codigo_generado + "\n"
		elif zona == "PROCESO": funciones_code += codigo_generado + "\n"
	
	if main_code == "": return ""

	var script = "extends Node\n"
	script += "var _p_: Node\n"
	script += "var _ctrl_: Node\n\n"
	
	script += "class Ref:\n"
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
	# --- NUEVO: Init en _ready ---
	script += "func _ready():\n" + vars_globales_init_code + "\n"
	
	script += "# FUNCS\n" + funciones_code + "\n"
	script += "# MAIN\n" + main_code
	
	print("--- TRADUCCIÓN ---\n", script)
	return script

# --- HELPERS ---

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
	
	var nombre_func = linea.substr(0, idx1).strip_edges().to_lower()
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
			args_procesados.append("Ref.new('temp', _ctrl_, " + arg_valor + ")")
			
	return nombre_func + "(" + ", ".join(args_procesados) + ")"

func _procesar_cabecera_proceso(linea_raw: String) -> String:
	var linea = linea_raw.strip_edges().replace("proceso ", "func ")
	var idx_paren = linea.find("(")
	var nombre_func = linea.substr(5, idx_paren - 5).strip_edges().to_lower()
	
	var contenido_params = linea.substr(idx_paren + 1, linea.rfind(")") - idx_paren - 1)
	var lista_params = contenido_params.split(",")
	
	var params_gd = []
	var codigo_clonacion = ""
	
	for p in lista_params:
		p = p.strip_edges()
		if p.is_empty(): continue
		var partes = p.split(" ") 
		var modo = partes[0].to_upper()
		var nombre_param = partes[1].replace(":", "")
		var tipo = "entero"
		if partes.size() > 2:
			tipo = partes[2].to_lower()
		
		variables_registradas.append(nombre_param)
		params_gd.append(nombre_param)
		
		if modo == "E":
			codigo_clonacion += "\t" + nombre_param + " = Ref.new('" + tipo + "', _ctrl_, " + nombre_param + ".v)\n"
			
	return "func " + nombre_func + "(" + ", ".join(params_gd) + "):\n" + codigo_clonacion

func _procesar_condicion(linea: String) -> String:
	var res = linea.replace("~", " not ")
	for sensor in MAPEO_SENSORES:
		if sensor in res:
			res = res.replace(sensor, MAPEO_SENSORES[sensor])
	return res

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
