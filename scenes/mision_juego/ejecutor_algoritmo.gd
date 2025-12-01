class_name EjecutorAlgoritmo extends Node

# --- Referencias ---
# Se las asignará el controlador principal (mision_juego.gd)
var personaje: CharacterBody2D 
var controlador_nivel: Node2D

# --- Mapeo de Instrucciones ---
# Diccionario que traduce "Palabra del Alumno" -> "Código GDScript"
# Nota: _p_ es el nombre interno que usaremos para referirnos al personaje en el script generado.
const COMANDOS_ATOMICOS = {
	"avanzar": "await _p_.avanzar()",
	"derecha": "await _p_.girar_derecha()",
	"saltar": "await _p_.saltar()",
	"atacar": "await _p_.atacar()",
	"recogermoneda": "await _p_.recoger_moneda()",
	"recogerllave": "await _p_.recoger_llave()",
	"abrircofre": "await _p_.abrir_cofre()",
	"activarpuente": "await _p_.activar_puente()"
}

# --- Mapeo de SENSORES (Síncronos / Devuelven bool) ---
# Se usan dentro de los condicionales "Si ..."
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

# --- FUNCIÓN PRINCIPAL ---
# Esta es la que llamaremos cuando se pulse el botón "EJECUTAR"
func procesar_y_ejecutar(texto_codigo: String):
	
	# 1. Traducir el Pseudocódigo a GDScript
	var codigo_gdscript = _transpilar(texto_codigo)
	
	if codigo_gdscript == "":
		print("Error: No se pudo generar código válido (¿Falta Inicio/Fin?).")
		_finalizar_ejecucion(false)
		return

	# 2. Compilar y Ejecutar dinámicamente
	_ejecutar_dinamicamente(codigo_gdscript)


# --- EL TRANSPILADOR ---
func _transpilar(texto: String) -> String:
	var lineas = texto.split("\n")
	var script_body = ""
	var dentro_de_algoritmo = false
	
	for linea in lineas:
		# Normalización de tabs
		var linea_normalizada = linea.replace("    ", "\t")
		var linea_limpia = linea_normalizada.strip_edges().to_lower()
		
		if linea_limpia.is_empty() or linea_limpia.begins_with("--"):
			continue
			
		# --- Bloques Principales ---
		if linea_limpia == "inicio":
			dentro_de_algoritmo = true
			script_body += "func run():\n"
			continue
			
		if linea_limpia == "fin":
			dentro_de_algoritmo = false
			script_body += "\t_ctrl_.on_ejecucion_terminada(true)\n"
			break 
			
		if not dentro_de_algoritmo:
			continue
		
		# --- Indentación ---
		var indent_str = _obtener_indentacion_segura(linea_normalizada)
			
		# --- TRADUCCIÓN LÍNEA A LÍNEA ---
		
		# 1. Estructura: SI (IF)
		if linea_limpia.begins_with("si "):
			var linea_traducida = linea_limpia.replace("si ", "if ")
			linea_traducida = linea_traducida.replace(" entonces:", ":")
			linea_traducida = linea_traducida.replace(" entonces", ":")
			linea_traducida = _procesar_condicion(linea_traducida)
			
			script_body += indent_str + linea_traducida + "\n"
			continue
			
		# 2. Estructura: SINO (ELSE)
		if linea_limpia == "sino" or linea_limpia == "sino:":
			script_body += indent_str + "else:\n"
			continue

		# 3. Estructura: MIENTRAS (WHILE) 
		if linea_limpia.begins_with("mientras "):
			# Traducir 'mientras' -> 'while'
			var linea_traducida = linea_limpia.replace("mientras ", "while ")
			
			# Traducir 'hacer' -> ':'
			linea_traducida = linea_traducida.replace(" hacer:", ":")
			linea_traducida = linea_traducida.replace(" hacer", ":")
			
			# Procesar sensores y operadores lógicos
			linea_traducida = _procesar_condicion(linea_traducida)
			
			script_body += indent_str + linea_traducida + "\n"
			continue
		
		# 4. Estructura: REPETIR (FOR)
		if linea_limpia.begins_with("repetir "):
			# Formato esperado: "Repetir 3" o "Repetir posValle"
			var partes = linea_limpia.replace(":", "").split(" ", false)
			if partes.size() >= 2:
				var veces = partes[1] # Esto será "3" o una variable
				# Procesamos 'veces' para traducir 'posValle' -> '_p_.pos_valle()'
				veces = _procesar_condicion(veces)
				# Usamos '_iter_' como variable desechable para no ensuciar
				script_body += indent_str + "for _iter_ in range(" + veces + "):\n"
			else:
				script_body += indent_str + "# Error de sintaxis en Repetir\n"
			continue

		# 5. Estructura: MAPA (Teletransportación)
		if linea_limpia.begins_with("mapa(") and linea_limpia.ends_with(")"):
			# Extraemos el contenido de los paréntesis. Ej: "mapa(2, 5)" -> "2, 5"
			var contenido = linea_limpia.trim_prefix("mapa(").trim_suffix(")")
			var argumentos = contenido.split(",")
			
			if argumentos.size() == 2:
				# Obtenemos los valores como string para inyectarlos en el código
				# Nota: Agregamos " - 1" para corregir de Base 1 (Usuario) a Base 0 (Godot)
				var pos_sendero = argumentos[0].strip_edges() + " - 1"
				var pos_valle = argumentos[1].strip_edges() + " - 1"
				
				# Generamos la llamada segura con await
				script_body += indent_str + "await _p_.intentar_teletransportar(Vector2i(" + pos_sendero + ", " + pos_valle + "))\n"
				script_body += indent_str + "await _ctrl_.get_tree().create_timer(0.2).timeout\n"
			else:
				script_body += indent_str + "# Error: La instrucción mapa() requiere 2 parámetros\n"
			continue
		
		# 6. Estructura: IMPRIMIR
		if linea_limpia.begins_with("imprimir(") and linea_limpia.ends_with(")"):
			# 1. Quitamos "imprimir(" y ")"
			var contenido = linea_limpia.trim_prefix("imprimir(").trim_suffix(")")
			
			contenido = _procesar_condicion(contenido)
			# 2. Truco: Lo envolvemos en corchetes []
			# Así GDScript lo interpretará como un Array de argumentos reales.
			var args_array = "[" + contenido + "]"
			
			script_body += indent_str + "await _p_.imprimir(" + args_array + ")\n"
			continue
		
		# 7. Instrucciones Atómicas
		var primera_palabra = linea_limpia.split(" ", false)[0]
		primera_palabra = primera_palabra.replace("(", "").replace(")", "")

		if COMANDOS_ATOMICOS.has(primera_palabra):
			script_body += indent_str + COMANDOS_ATOMICOS[primera_palabra] + "\n"
		else:
			script_body += indent_str + "# Desconocido: " + linea_limpia + "\n"
	
	if script_body == "": return ""
		
	# Envolver script
	var script_final = "extends Node\n"
	script_final += "var _p_: Node\n"
	script_final += "var _ctrl_: Node\n"
	script_final += "\n" 
	script_final += script_body
	
	print("--- TRADUCCIÓN ---\n", script_final)
	return script_final

# --- HELPER: PROCESAR CONDICIÓN ---
func _procesar_condicion(linea: String) -> String:
	var resultado = linea
	
	# Operadores Lógicos
	resultado = resultado.replace("~", " not ")
	# 'and' y 'or' ya son válidos en GDScript
	
	# Reemplazo de Sensores
	for sensor in MAPEO_SENSORES:
		if sensor in resultado:
			resultado = resultado.replace(sensor, MAPEO_SENSORES[sensor])
			
	return resultado

# --- HELPER: OBTENER INDENTACIÓN ---
func _obtener_indentacion_segura(linea: String) -> String:
	var indent = ""
	for caracter in linea:
		if caracter == "\t":
			indent += "\t"
		elif caracter == " ":
			# Espacios simples se ignoran en el conteo de indentación si ya normalizamos
			pass
		else:
			break
	return indent

# --- EL EJECUTOR (Compilador) ---
func _ejecutar_dinamicamente(codigo_fuente: String):
	# 1. Crear un objeto GDScript nuevo
	var script_dinamico = GDScript.new()
	script_dinamico.source_code = codigo_fuente
	
	# 2. Recargar (Compilar)
	var error = script_dinamico.reload()
	if error != OK:
		print("Error sintaxis GDScript generado: ", error)
		_finalizar_ejecucion(false)
		return
		
	# 3. Instanciar el script como un Nodo temporal
	var nodo_runner = Node.new()
	nodo_runner.name = "RunnerTemporal"
	nodo_runner.set_script(script_dinamico)
	
	# 4. Inyectar las referencias (¡Magia!)
	nodo_runner._p_ = personaje
	nodo_runner._ctrl_ = controlador_nivel
	
	# 5. Añadir a la escena y correr
	controlador_nivel.add_child(nodo_runner)
	
	# Llamamos a la función 'run' que escribimos en el string
	nodo_runner.call_deferred("run")


# --- FUNCIÓN DE TÉRMINO ---
func _finalizar_ejecucion(exito: bool):
	# 1. Limpieza del nodo temporal
	var nodo_runner = controlador_nivel.get_node("RunnerTemporal")
	if is_instance_valid(nodo_runner):
		nodo_runner.queue_free()
		
	# 2. Notificar al controlador para que inicie la pausa/reinicio
	controlador_nivel.on_ejecucion_terminada(exito)

# Borra el script del alumno INMEDIATAMENTE.
func detener_ejecucion_inmediata():
	var nodo_runner = controlador_nivel.get_node_or_null("RunnerTemporal")
	if is_instance_valid(nodo_runner):
		nodo_runner.queue_free() # Adiós nodo, adiós bucle infinito.
		print("--- Ejecutor: Script del alumno eliminado por seguridad ---")
