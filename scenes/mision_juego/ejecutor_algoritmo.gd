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
	"hayllave": "_p_.hay_llave()"
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


# --- EL TRANSPILADOR (ROBUSTO) ---
func _transpilar(texto: String) -> String:
	var lineas = texto.split("\n")
	var script_body = ""
	var dentro_de_algoritmo = false
	
	for linea in lineas:
		# 1. Normalización: Reemplazamos 4 espacios por 1 tabulador para simplificar
		# (Opcional, pero ayuda si el editor mezcla cosas)
		var linea_normalizada = linea.replace("    ", "\t")
		
		# Limpieza básica
		var linea_limpia = linea_normalizada.strip_edges().to_lower()
		
		if linea_limpia.is_empty() or linea_limpia.begins_with("--"):
			continue
			
		# --- Detección de Bloques Principales ---
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
		
		# --- GESTIÓN DE INDENTACIÓN (CLAVE) ---
		# En lugar de leer caracteres raros, contamos cuántos tabs hay al inicio
		# asumiendo que hemos normalizado.
		var indent_str = _obtener_indentacion_segura(linea_normalizada)
			
		# --- TRADUCCIÓN LÍNEA A LÍNEA ---
		
		# 1. Estructura: SI (IF)
		if linea_limpia.begins_with("si "):
			var linea_traducida = linea_limpia.replace("si ", "if ")
			linea_traducida = linea_traducida.replace(" entonces:", ":")
			linea_traducida = linea_traducida.replace(" entonces", ":")
			linea_traducida = linea_traducida.replace("~", " not ")
			
			for sensor in MAPEO_SENSORES:
				if sensor in linea_traducida:
					linea_traducida = linea_traducida.replace(sensor, MAPEO_SENSORES[sensor])
			
			script_body += indent_str + linea_traducida + "\n"
			continue
			
		# 2. Estructura: SINO (ELSE)
		if linea_limpia == "sino" or linea_limpia == "sino:":
			script_body += indent_str + "else:\n"
			continue

		# 3. Instrucciones Atómicas (Acciones)
		var primera_palabra = linea_limpia.split(" ", false)[0]
		primera_palabra = primera_palabra.replace("(", "").replace(")", "")

		if COMANDOS_ATOMICOS.has(primera_palabra):
			script_body += indent_str + COMANDOS_ATOMICOS[primera_palabra] + "\n"
		else:
			# Comentamos lo desconocido
			script_body += indent_str + "# Desconocido: " + linea_limpia + "\n"
	
	if script_body == "": return ""
		
	# Envolvemos
	var script_final = "extends Node\n"
	script_final += "var _p_: Node\n"
	script_final += "var _ctrl_: Node\n"
	# Variables globales placeholder
	script_final += "\n" 
	script_final += script_body
	
	print("--- TRADUCCIÓN ---\n", script_final)
	return script_final

# --- HELPER DE INDENTACIÓN (NUEVO Y SEGURO) ---
func _obtener_indentacion_segura(linea: String) -> String:
	var indent = ""
	for caracter in linea:
		if caracter == "\t":
			indent += "\t"
		elif caracter == " ":
			# Si encontramos un espacio suelto al principio, lo tratamos con cuidado.
			# Idealmente el replace("    ", "\t") ya arregló esto, pero por si acaso:
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
