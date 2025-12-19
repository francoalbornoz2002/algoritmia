class_name MisionesCampana extends RefCounted

# Misión 1: Introducción a Bucles (Mientras)
static func crear_mision_01_bucle_basico() -> DefinicionMision:
	var mision = DefinicionMision.new()
	# UUID fijo para sincronización (Ejemplo)
	mision.id = "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d" # UUID v4 válido y fijo
	mision.titulo = "Mision Campaña (Demo)"
	mision.dificultad_mision = "Facil"
	mision.descripcion = "Recorre todo el sendero 1 recolectando las monedas que encuentres en el camino."
	mision.tamano_mapa = Vector2i(25, 25)
	
	# --- CASO 1: Distancia Corta (5 pasos) ---
	var caso1 = CasoPruebaMision.new()
	caso1.inicio_jugador = Vector2i(1, 0) # Sendero 1, Valle 0
	
	# Colocamos la moneda en (1, 5)
	caso1.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(1, 5))
	
	# Condición: Debe tener 1 moneda
	caso1.agregar_condicion(CondicionMision.Recolectar.new("monedas", 1))
	
	mision.casos_de_prueba.append(caso1)
	
	# --- CASO 2: Distancia Larga (12 pasos) ---
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(1, 0)
	
	# Colocamos la moneda más lejos (1, 12)
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(1, 12))
	
	# Misma condición
	caso2.agregar_condicion(CondicionMision.Recolectar.new("monedas", 1))
	
	mision.casos_de_prueba.append(caso2)
	
	return mision
