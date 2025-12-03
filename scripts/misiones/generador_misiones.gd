class_name GeneradorMisiones extends RefCounted

# Configuraciones base
const TIPOS_RUTA = ["SENDERO", "VALLE"]
const DIFICULTAD_FACIL = 1
const DIFICULTAD_MEDIA = 2
const DIFICULTAD_DIFICIL = 3

# Estructura auxiliar para manejar las rutas generadas
class RutaGenerada:
	var tipo: String
	var indice: int
	var coords: Array[Vector2i]
	
	func _init(t, i, c):
		tipo = t;
		indice = i;
		coords = c

# --- FUNCIÓN PRINCIPAL ---
# Esta es la que llamarás desde el juego
static func generar_mision_compleja(nivel_dificultad: int = DIFICULTAD_MEDIA) -> DefinicionMision:
	var mision = DefinicionMision.new()
	mision.id = "gen_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
	mision.es_mision_especial = true
	mision.tamano_mapa = Vector2i(25, 25) # Tamaño estándar
	
	# 1. Configuración de la Narrativa y Lógica
	# -----------------------------------------
	# Decidimos cuántas etapas (rutas) tendrá la misión
	var cantidad_rutas = 1
	if nivel_dificultad >= DIFICULTAD_MEDIA: cantidad_rutas = 2
	
	var rutas_seleccionadas: Array[RutaGenerada] = []
	var indices_usados = []
	
	for i in range(cantidad_rutas):
		var tipo = TIPOS_RUTA.pick_random()
		var indice = randi_range(1, 10) # Limitamos al 10 para no irnos muy lejos visualmente
		
		# Evitar repetir la misma ruta exacta
		while indice in indices_usados:
			indice = randi_range(1, 15)
		indices_usados.append(indice)
		
		var coords = _obtener_coords_ruta(tipo, indice)
		rutas_seleccionadas.append(RutaGenerada.new(tipo, indice, coords))

	# 2. Definir Requerimientos Lógicos (Condiciones)
	# -----------------------------------------------
	var requiere_variable_contador = (randf() > 0.5 and nivel_dificultad >= DIFICULTAD_MEDIA)
	var requiere_procedimiento = (nivel_dificultad == DIFICULTAD_DIFICIL)
	var hay_enemigos = (randf() > 0.3)
	
	# 3. Generación de Casos de Prueba (Escenarios)
	# ---------------------------------------------
	# Generamos 2 casos para asegurar que el algoritmo sea robusto
	for i in range(2):
		var caso = CasoPruebaMision.new()
		# El jugador siempre empieza al inicio de la PRIMERA ruta
		caso.inicio_jugador = rutas_seleccionadas[0].coords[0]
		
		var total_monedas = 0
		var total_enemigos = 0
		
		# Llenamos cada ruta seleccionada con objetos
		for ruta in rutas_seleccionadas:
			# Copiamos coords para ir sacando posiciones ocupadas
			var huecos_libres = ruta.coords.duplicate()
			# Quitamos el inicio si es la primera ruta (para no spawnear encima del jugador)
			if ruta == rutas_seleccionadas[0]:
				huecos_libres.pop_front()
			
			# A. Monedas (Casi siempre)
			var cant_monedas = randi_range(2, 4)
			for c in range(cant_monedas):
				var pos = _pick_and_remove(huecos_libres)
				if pos != Vector2i(-1,-1):
					caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, pos)
					total_monedas += 1
			
			# B. Enemigos (Si aplica)
			if hay_enemigos:
				var cant_enemigos = randi_range(1, 2)
				for c in range(cant_enemigos):
					var pos = _pick_and_remove(huecos_libres)
					if pos != Vector2i(-1,-1):
						caso.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, pos)
						total_enemigos += 1
			
			# C. Obstáculos (Salpicados)
			if randf() > 0.6:
				var pos = _pick_and_remove(huecos_libres)
				if pos != Vector2i(-1,-1):
					# Verificamos si la posición es segura para saltar (no está en los bordes)
					if _es_posicion_segura_para_obstaculo(pos, mision.tamano_mapa):
						caso.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, pos)

		# --- CONDICIONES DE VICTORIA DEL CASO ---
		
		# 1. Recolectar todo
		if total_monedas > 0:
			caso.agregar_condicion(CondicionMision.Recolectar.new("monedas", total_monedas))
			
		# 2. Eliminar amenazas
		if total_enemigos > 0:
			caso.agregar_condicion(CondicionMision.EliminarEnemigos.new())
			
		# 3. Uso de Variables (Si la misión lo pide)
		if requiere_variable_contador:
			# El generador decide que la variable se llame 'tesoro' o 'total'
			var nombre_var = "total"
			caso.agregar_condicion(CondicionMision.VariableTieneValor.new(nombre_var, total_monedas))
			
		# 4. Uso de Procedimientos (Si es difícil)
		if requiere_procedimiento:
			caso.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("recolectar"))

		mision.casos_de_prueba.append(caso)

	# 4. Construcción del Enunciado (Texto Lineal Sin Saltos)
	# -------------------------------------------------------
	var titulo = "Misión Táctica: "
	var desc = ""
	
	# Parte A: Rutas (Narrativa de movimiento)
	for j in range(rutas_seleccionadas.size()):
		var ruta = rutas_seleccionadas[j]
		var nombre_zona = "%s %d" % [ruta.tipo.capitalize(), ruta.indice]
		
		if j == 0:
			desc += "Recorre el %s" % nombre_zona
		else:
			# Concatena con coma para seguir la línea
			desc += ", luego posiciónate en el %s y recórrelo también" % nombre_zona
			titulo += "Expedición Cruzada "
	
	if rutas_seleccionadas.size() == 1:
		var r = rutas_seleccionadas[0]
		titulo += "%s %d" % [r.tipo.capitalize(), r.indice]

	desc += "." # Fin de la instrucción de movimiento

	# Parte B: Objetivos (Narrativa de acción)
	var acciones = []
	acciones.append("recolecta todas las monedas")
	
	if hay_enemigos:
		acciones.append("elimina a cualquier enemigo")
		
	desc += " Tu objetivo es " + " y ".join(acciones) + "."
		
	# Parte C: Requerimientos Técnicos (Restricciones)
	if requiere_variable_contador:
		desc += " Importante: DEBES guardar la cantidad de monedas en una variable llamada 'total'."
	
	if requiere_procedimiento:
		desc += " Además, encapsula la lógica en un procedimiento llamado 'recolectar'."
	
	mision.titulo = titulo
	mision.descripcion = desc # Todo en una sola línea larga
	
	if nivel_dificultad == DIFICULTAD_FACIL: mision.dificultad = "Fácil"
	elif nivel_dificultad == DIFICULTAD_MEDIA: mision.dificultad = "Media"
	else: mision.dificultad = "Difícil"
	
	return mision

# --- UTILS PRIVADOS ---

static func _obtener_coords_ruta(tipo: String, indice: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	var index_0 = indice - 1 # Base 0
	
	if tipo == "SENDERO": # Vertical
		for y in range(25): 
			coords.append(Vector2i(index_0, y))
	elif tipo == "VALLE": # Horizontal
		for x in range(25):
			coords.append(Vector2i(x, index_0))
	return coords

static func _pick_and_remove(arr: Array) -> Vector2i:
	if arr.is_empty(): return Vector2i(-1, -1)
	var idx = randi() % arr.size()
	var val = arr[idx]
	arr.remove_at(idx)
	return val

# Función de seguridad para evitar game over injustos
static func _es_posicion_segura_para_obstaculo(pos: Vector2i, tamano: Vector2i) -> bool:
	# Los obstáculos NO pueden estar en los límites del mapa (x=0, x=Max, y=0, y=Max)
	# porque requieren saltar (mover 2 casillas) y eso podría sacar al jugador del mapa.
	
	var es_borde_x = (pos.x == 0) or (pos.x == tamano.x - 1)
	var es_borde_y = (pos.y == 0) or (pos.y == tamano.y - 1)
	
	# Si está en algún borde, NO es seguro
	return not (es_borde_x or es_borde_y)
