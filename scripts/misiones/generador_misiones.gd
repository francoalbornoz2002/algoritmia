class_name GeneradorMisiones extends RefCounted

# Genera una misión completa con parámetros aleatorios
static func generar_mision_especial() -> DefinicionMision:
	var mision = DefinicionMision.new()
	
	# ID único temporal (idealmente usarías un generador de UUID real aquí)
	mision.id = "especial_" + str(Time.get_unix_time_from_system())
	mision.es_mision_especial = true # ¡Doble Recompensa!
	mision.dificultad = "Media"
	
	# Elegimos un arquetipo aleatorio
	var tipo = randi() % 2 # 0: Recolector, 1: Cazador
	
	if tipo == 0:
		_generar_arquetipo_recolector(mision)
	else:
		_generar_arquetipo_cazador(mision)
		
	return mision

# --- ARQUETIPO 1: RECOLECTOR DE MONEDAS ---
# Objetivo: El mapa se llena de monedas. Hay que recoger X cantidad.
static func _generar_arquetipo_recolector(mision: DefinicionMision):
	var cantidad_objetivo = randi_range(3, 5) # Pedimos entre 3 y 5 monedas
	
	mision.titulo = "Fiebre del Oro (Evento Especial)"
	mision.descripcion = "¡Evento de Inactividad Detectado!\n\n" + \
		"Se han detectado grandes cantidades de oro en el sector.\n" + \
		"OBJETIVO: Recolecta al menos " + str(cantidad_objetivo) + " monedas.\n" + \
		"RECOMPENSA: Doble experiencia."
	
	# Generamos 2 Casos de Prueba para asegurar que el alumno use bucles/sensores
	# y no solo 'avanzar' 'recoger' 'avanzar'.
	for i in range(2):
		var caso = CasoPruebaMision.new()
		caso.inicio_jugador = Vector2i(0, 0)
		
		# Ponemos más monedas de las necesarias para despistar, o las justas.
		# Vamos a poner las justas pero en posiciones muy aleatorias.
		var posiciones_usadas = []
		
		for c in range(cantidad_objetivo):
			var pos = _obtener_posicion_libre(posiciones_usadas)
			posiciones_usadas.append(pos)
			caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, pos)
			
		# Agregamos la condición de victoria
		caso.agregar_condicion(CondicionMision.Recolectar.new("monedas", cantidad_objetivo))
		
		mision.casos_de_prueba.append(caso)

# --- ARQUETIPO 2: CAZADOR DE BUGS ---
# Objetivo: Eliminar a todos los enemigos del mapa.
static func _generar_arquetipo_cazador(mision: DefinicionMision):
	var cantidad_enemigos = randi_range(2, 4)
	
	mision.titulo = "Invasión de Bugs (Evento Especial)"
	mision.descripcion = "¡Alerta de Seguridad!\n\n" + \
		"Varios Bugs han invadido el sistema debido a la inactividad.\n" + \
		"OBJETIVO: Elimina a TODOS los enemigos del mapa.\n" + \
		"RECOMPENSA: Doble experiencia."
		
	for i in range(2):
		var caso = CasoPruebaMision.new()
		caso.inicio_jugador = Vector2i(0, 0)
		
		var posiciones_usadas = []
		for c in range(cantidad_enemigos):
			var pos = _obtener_posicion_libre(posiciones_usadas)
			posiciones_usadas.append(pos)
			caso.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, pos)
			
		# Condición: Mapa limpio
		caso.agregar_condicion(CondicionMision.EliminarEnemigos.new())
		
		mision.casos_de_prueba.append(caso)

# --- UTILS ---
static func _obtener_posicion_libre(excluidos: Array) -> Vector2i:
	# Genera una posición aleatoria simple en los primeros 3 senderos y 10 valles
	# para no hacer mapas gigantes
	var max_intentos = 100
	for i in range(max_intentos):
		var x = randi_range(0, 2) # Senderos 1-3
		var y = randi_range(2, 10) # Valles 3-11 (dejamos espacio al inicio)
		var pos = Vector2i(x, y)
		
		if not pos in excluidos:
			return pos
			
	return Vector2i(0, 5) # Fallback seguro
