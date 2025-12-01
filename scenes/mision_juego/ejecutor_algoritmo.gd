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
	
	# Separamos el código en dos partes: Variables Globales y Cuerpo de la Función
	var variables_globales_code = ""
	var cuerpo_funcion_code = ""
	
	var dentro_de_algoritmo = false
	
	for linea in lineas:
		# 1. Normalización
		var linea_normalizada = linea.replace("    ", "\t")
		# Quitamos comentarios (--) para procesar
		var linea_sin_comentarios = linea_normalizada.split("--")[0]
		var linea_limpia = linea_sin_comentarios.strip_edges().to_lower() # Para detección
		
		# Ignorar líneas vacías
		if linea_limpia.is_empty():
			continue
			
		# --- DETECCIÓN DE BLOQUES ---
		if linea_limpia == "inicio":
			dentro_de_algoritmo = true
			cuerpo_funcion_code += "func run():\n"
			continue
			
		if linea_limpia == "fin":
			dentro_de_algoritmo = false
			cuerpo_funcion_code += "\t_ctrl_.on_ejecucion_terminada(true)\n"
			break 
		
		# --- TRADUCCIÓN ---
		
		# A) ZONA DE VARIABLES GLOBALES (Antes del Inicio)
		if not dentro_de_algoritmo:
			# Detectar: var nombre: tipo
			if linea_limpia.begins_with("var "):
				# Ejemplo: var miPuntaje: entero
				# Queremos: var miPuntaje = null
				
				# 1. Extraer nombre y tipo
				var partes = linea_limpia.split(":")
				if partes.size() > 0:
					var declaracion = partes[0] # "var mipuntaje"
					var nombre_var = declaracion.replace("var ", "").strip_edges()
					
					# 2. Generar código GDScript (Inicializado en null para detectar errores)
					variables_globales_code += "var " + nombre_var + " = null\n"
				continue

		# B) ZONA DEL ALGORITMO (Dentro de Inicio...Fin)
		else:
			# Indentación original
			var indent_str = _obtener_indentacion_segura(linea_normalizada)
			var linea_procesada = linea_limpia # Usaremos esta para lógica
			
			# --- TRADUCCIONES DE SINTAXIS (ASIGNACIONES Y OPERADORES) ---
			# 0. Declaración de Variables Locales (var nombre: tipo)
			if linea_procesada.begins_with("var "):
				var partes = linea_procesada.split(":")
				if partes.size() > 0:
					var declaracion = partes[0]
					var nombre_var = declaracion.replace("var ", "").strip_edges()
					# Generamos var local inicializada en null
					cuerpo_funcion_code += indent_str + "var " + nombre_var + " = null\n"
				continue
			
			# 1. Asignación (:=) -> (=)
			if ":=" in linea_procesada:
				linea_procesada = linea_procesada.replace(":=", "=")
			
			# 2. Operador Módulo (mod) -> (%)
			# Usamos regex o replace simple con espacios para no romper palabras como "modo"
			linea_procesada = linea_procesada.replace(" mod ", " % ")
			
			# 3. Incremento/Decremento (++, --) -> (+= 1, -= 1)
			if "++" in linea_procesada:
				linea_procesada = linea_procesada.replace("++", " += 1")
			if "--" in linea_procesada:
				linea_procesada = linea_procesada.replace("--", " -= 1")

			# --- ESTRUCTURAS DE CONTROL ---
			
			# Si (If)
			if linea_procesada.begins_with("si "):
				var linea_trad = linea_procesada.replace("si ", "if ")
				linea_trad = linea_trad.replace(" entonces:", ":").replace(" entonces", ":")
				linea_trad = _procesar_condicion(linea_trad)
				cuerpo_funcion_code += indent_str + linea_trad + "\n"
				continue
				
			# Sino (Else)
			if linea_procesada == "sino" or linea_procesada == "sino:":
				cuerpo_funcion_code += indent_str + "else:\n"
				continue

			# Mientras (While)
			if linea_procesada.begins_with("mientras "):
				var linea_trad = linea_procesada.replace("mientras ", "while ")
				linea_trad = linea_trad.replace(" hacer:", ":").replace(" hacer", ":")
				linea_trad = _procesar_condicion(linea_trad)
				cuerpo_funcion_code += indent_str + linea_trad + "\n"
				continue
			
			# Repetir (For)
			if linea_procesada.begins_with("repetir "):
				var partes = linea_procesada.replace(":", "").split(" ", false)
				if partes.size() >= 2:
					var veces = _procesar_condicion(partes[1])
					cuerpo_funcion_code += indent_str + "for _iter_ in range(" + veces + "):\n"
				continue

			# Mapa()
			if linea_procesada.begins_with("mapa(") and linea_procesada.ends_with(")"):
				var contenido = linea_procesada.trim_prefix("mapa(").trim_suffix(")")
				var argumentos = contenido.split(",")
				if argumentos.size() == 2:
					var pos_sendero = _procesar_condicion(argumentos[0]) + " - 1"
					var pos_valle = _procesar_condicion(argumentos[1]) + " - 1"
					cuerpo_funcion_code += indent_str + "if not await _p_.intentar_teletransportar(Vector2i(" + pos_sendero + ", " + pos_valle + ")): return\n"
				continue

			# Imprimir()
			if linea_procesada.begins_with("imprimir(") and linea_procesada.ends_with(")"):
				var contenido = linea_procesada.trim_prefix("imprimir(").trim_suffix(")")
				contenido = _procesar_condicion(contenido)
				cuerpo_funcion_code += indent_str + "await _p_.imprimir([" + contenido + "])\n"
				continue
				
			# Instrucciones Atómicas
			var primera_palabra = linea_procesada.split(" ", false)[0].replace("(", "").replace(")", "")
			if COMANDOS_ATOMICOS.has(primera_palabra):
				cuerpo_funcion_code += indent_str + COMANDOS_ATOMICOS[primera_palabra] + "\n"
				continue
			
			# --- CASO POR DEFECTO: ASIGNACIONES MATEMÁTICAS ---
			# Si no es ninguna estructura reservada, asumimos que es una operación matemática
			# Ej: miVariable = 5 + 2
			# Como ya reemplazamos := por =, simplemente pasamos la línea procesada
			# Pero debemos asegurarnos de procesar sensores en la parte derecha de la asignación
			
			if "=" in linea_procesada or "+=" in linea_procesada or "-=" in linea_procesada:
				# Procesamos para traducir sensores/variables globales si las hubiera
				linea_procesada = _procesar_condicion(linea_procesada)
				cuerpo_funcion_code += indent_str + linea_procesada + "\n"
				continue

	if cuerpo_funcion_code == "": return ""
		
	# Envolver script final
	var script_final = "extends Node\n"
	script_final += "var _p_: Node\n"
	script_final += "var _ctrl_: Node\n"
	script_final += "\n"
	script_final += "# --- VARIABLES GLOBALES DEL ALUMNO ---\n"
	script_final += variables_globales_code
	script_final += "\n" 
	script_final += "# --- ALGORITMO PRINCIPAL ---\n"
	script_final += cuerpo_funcion_code
	
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
