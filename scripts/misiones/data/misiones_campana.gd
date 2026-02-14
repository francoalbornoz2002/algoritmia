class_name MisionesCampana extends RefCounted

# Misión 1: Introducción a Bucles (Mientras)
static func crear_mision_01_bucle_basico() -> DefinicionMision:
	var mision = DefinicionMision.new()
	mision.id = "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"
	mision.titulo = "Misión 1"
	mision.descripcion = "Recorre el Sendero 3. Tu objetivo es recolecta todas las monedas, elimina a cualquier enemigo y elude obstáculos."
	mision.tamano_mapa = Vector2i(25, 25)
	mision.dificultad_mision = "Media"

	# CASO 1: 5 monedas y 2 enemigos en Sendero 3 (x=2)
	var caso1 = CasoPruebaMision.new()
	caso1.inicio_jugador = Vector2i(2, 0) # Sendero 3, Valle 1

	# Distribuimos 5 monedas
	for y in [2, 5, 8, 11, 14]:
		caso1.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(2, y))

	# 2 Enemigos
	caso1.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 4))
	caso1.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 10))

	caso1.agregar_condicion(CondicionMision.Recolectar.new("monedas", 5))
	caso1.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	mision.casos_de_prueba.append(caso1)

	# CASO 2: Sin monedas, solo enemigos y obstáculos (espacio de 2)
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 0)

	# Enemigos y Obstáculos con 2 espacios de separación (y=3, 6, 9, 12)
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 3))
	caso2.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(2, 6))
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 9))
	caso2.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(2, 12))

	caso2.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	mision.casos_de_prueba.append(caso2)
	return mision

# ==========================================
# TEMA 1: SECUENCIA Y LÓGICA BÁSICA
# ==========================================

static func crear_mision_secuencia_01() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
	m.titulo = "Secuencia 1: El Primer Paso"
	m.descripcion = "Todo viaje comienza con un paso. Tu objetivo es simple: avanza 3 casillas hacia el norte."
	m.dificultad_mision = "Fácil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0) # (0,0)
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 3))) # Avanza 3 -> (0,3)
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 2) # (2,2)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 5))) # Avanza 3 -> (2,5)
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_secuencia_02() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a12"
	m.titulo = "Secuencia 2: El Giro Táctico"
	m.descripcion = "El camino no siempre es recto. Avanza 2 pasos, gira a la derecha y avanza 2 pasos más para rodear la estructura antigua."
	m.dificultad_mision = "Fácil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	# (0,0) -> Avanza 2 -> (0,2) -> Derecha -> Avanza 2 -> (2,2)
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 2)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(4, 4)
	# (4,4) -> Avanza 2 -> (4,6) -> Derecha -> Avanza 2 -> (6,6)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(6, 6)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_secuencia_03() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a13"
	m.titulo = "Secuencia 3: Salto de Fe"
	m.descripcion = "Una Raíz Enredante bloquea tu camino. No puedes atravesarla, debes saltarla. Avanza, salta el obstáculo y posiciónate en la meta."
	m.dificultad_mision = "Fácil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(0, 2)) # Dejamos espacio para "Avanza" antes
	# (0,0) -> Avanza -> (0,1) -> Salta (sobre 0,2) -> (0,3)
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 3)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 2)
	caso2.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(2, 4))
	# (2,2) -> Avanza -> (2,3) -> Salta (sobre 2,4) -> (2,5)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 5)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_secuencia_04() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "d3eebc99-9c0b-4ef8-bb6d-6bb9bd380a14"
	m.titulo = "Secuencia 4: Limpieza de Bugs"
	m.descripcion = "Un Bug bloquea el pasillo. Los Bugs no se pueden saltar. Debes avanzar, atacar para eliminarlo y luego ocupar su lugar."
	m.dificultad_mision = "Fácil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(0, 2)) # Espacio para avanzar
	caso.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 2)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(3, 3)
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(3, 5))
	caso2.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(3, 5)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_secuencia_05() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a15"
	m.titulo = "Secuencia 5: Recolección"
	m.descripcion = "Los recursos son vitales. Avanza por el sendero, recoge la moneda y luego la llave que se encuentra más adelante."
	m.dificultad_mision = "Fácil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 2))
	caso.agregar_elemento(ElementoTablero.Tipo.LLAVE, Vector2i(0, 4))
	
	caso.agregar_condicion(CondicionMision.Recolectar.new("monedas", 1))
	caso.agregar_condicion(CondicionMision.Recolectar.new("llaves", 1))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(1, 1)
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(1, 3))
	caso2.agregar_elemento(ElementoTablero.Tipo.LLAVE, Vector2i(1, 5))
	
	caso2.agregar_condicion(CondicionMision.Recolectar.new("monedas", 1))
	caso2.agregar_condicion(CondicionMision.Recolectar.new("llaves", 1))
	m.casos_de_prueba.append(caso2)
	return m

# ==========================================
# TEMA 2: BUCLES (MIENTRAS / REPETIR)
# ==========================================

static func crear_mision_bucles_01() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "f5eebc99-9c0b-4ef8-bb6d-6bb9bd380a16"
	m.titulo = "Bucles 1: El Sendero Largo"
	m.descripcion = "El pasillo es largo y tedioso. Usa el 'Ritual de la Perseverancia' (Repetir) para avanzar 8 pasos sin escribir la instrucción 8 veces."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 8))) # Avanza 8
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 2)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 10)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_bucles_02() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "a6eebc99-9c0b-4ef8-bb6d-6bb9bd380a17"
	m.titulo = "Bucles 2: Caminata Cauta"
	m.descripcion = "Debes llegar hasta el final del valle (casilla 14), pero no sabes exactamente cuántos pasos son. Usa 'Mientras posValle < 14' para avanzar seguro."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 13))) # Casilla 14 es índice 13
	m.casos_de_prueba.append(caso)
	
	# Caso 2: Empieza más adelante, el bucle debe funcionar igual (menos iteraciones)
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(0, 5)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 13)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_bucles_03() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "b7eebc99-9c0b-4ef8-bb6d-6bb9bd380a18"
	m.titulo = "Bucles 3: Barrido de Monedas"
	m.descripcion = "Hay una fila de 5 monedas frente a ti. Crea un bucle que repita la acción de 'recogerMoneda' y 'avanzar' para obtenerlas todas."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	for i in range(5):
		caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 0 + i)) # Monedas en la misma casilla antes de avanzar o siguiente
	
	# Ajuste lógico: Moneda en 1, 2, 3, 4, 5. Jugador empieza en 1.
	# Estrategia: Repetir 5 (Recoger, Avanzar) o similar.
	caso.elementos_mapa.clear()
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 1))
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 2))
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 3))
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 4))
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 5))
	
	caso.agregar_condicion(CondicionMision.Recolectar.new("monedas", 5))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 2)
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(2, 3))
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(2, 4))
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(2, 5))
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(2, 6))
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(2, 7))
	
	caso2.agregar_condicion(CondicionMision.Recolectar.new("monedas", 5))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_bucles_04() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "c8eebc99-9c0b-4ef8-bb6d-6bb9bd380a19"
	m.titulo = "Bucles 4: Patrulla Cuadrada"
	m.descripcion = "Realiza una patrulla en forma de cuadrado de 3x3 pasos. Usa un bucle que se repita 4 veces: avanzar 3 pasos y girar a la derecha."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(2, 2) # (2,2) Base 0
	# Si hace el cuadrado perfecto, vuelve al inicio.
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 2)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(4, 4)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(4, 4)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_bucles_05() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "d9eebc99-9c0b-4ef8-bb6d-6bb9bd380a20"
	m.titulo = "Bucles 5: El Valle de las Sombras"
	m.descripcion = "El camino está infestado de enemigos invisibles. Avanza hasta el final del sendero (casilla 8), pero ATACA antes de cada paso por seguridad."
	m.dificultad_mision = "Difícil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(0, 2))
	caso.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(0, 5))
	
	caso.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 7))) # Casilla 8 es índice 7
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 0)
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 1))
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 4))
	
	caso2.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 7)))
	m.casos_de_prueba.append(caso2)
	return m

# ==========================================
# TEMA 3: CONDICIONALES (SI / SINO)
# ==========================================

static func crear_mision_condicionales_01() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a21"
	m.titulo = "Condicionales 1: Ojos Abiertos"
	m.descripcion = "Avanza 5 pasos. En cada paso, verifica 'Si hayMoneda' entonces recógela. No siempre habrá monedas."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	# Caso A: Hay moneda
	var casoA = CasoPruebaMision.new()
	casoA.inicio_jugador = Vector2i(0, 0)
	casoA.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 3))
	casoA.agregar_condicion(CondicionMision.Recolectar.new("monedas", 1))
	casoA.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 5)))
	m.casos_de_prueba.append(casoA)
	
	# Caso B: No hay moneda (El código no debe fallar)
	var casoB = CasoPruebaMision.new()
	casoB.inicio_jugador = Vector2i(0, 0)
	casoB.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 5)))
	m.casos_de_prueba.append(casoB)
	
	return m

static func crear_mision_condicionales_02() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "f1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22"
	m.titulo = "Condicionales 2: Defensa Reactiva"
	m.descripcion = "Avanza por el pasillo. Si encuentras un enemigo, atácalo. Si no hay enemigo, simplemente avanza."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	# Caso con enemigo
	var caso1 = CasoPruebaMision.new()
	caso1.inicio_jugador = Vector2i(0, 0)
	caso1.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(0, 2))
	caso1.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	caso1.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 4)))
	m.casos_de_prueba.append(caso1)
	
	# Caso sin enemigo (debe avanzar sin atacar)
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(0, 0)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 4)))
	m.casos_de_prueba.append(caso2)
	
	return m

static func crear_mision_condicionales_03() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "a2eebc99-9c0b-4ef8-bb6d-6bb9bd380a23"
	m.titulo = "Condicionales 3: Decisiones del Camino"
	m.descripcion = "El camino puede tener raíces. Usa 'Si hayObstaculo' para saltar, 'Sino' avanza normalmente. Repite esto 5 veces."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(0, 2))
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 6))) # 1 salto (+2) + 4 avances = pos 6 aprox
	m.casos_de_prueba.append(caso)
	
	# Caso sin obstáculo
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(0, 0)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 5))) # 5 avances simples
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_condicionales_04() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a24"
	m.titulo = "Condicionales 4: Lógica Compuesta"
	m.descripcion = "Busca una moneda protegida. Solo si 'hayMoneda AND hayEnemigo' debes atacar y luego recoger. Si solo hay moneda, recógela sin atacar."
	m.dificultad_mision = "Difícil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(0, 1))
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 1)) # Moneda debajo del enemigo
	caso.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	caso.agregar_condicion(CondicionMision.Recolectar.new("monedas", 1))
	m.casos_de_prueba.append(caso)
	
	# Caso 2: Solo moneda (NO debe atacar)
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(0, 0)
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 1))
	caso2.agregar_condicion(CondicionMision.Recolectar.new("monedas", 1))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_condicionales_05() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "c4eebc99-9c0b-4ef8-bb6d-6bb9bd380a25"
	m.titulo = "Condicionales 5: El Guardián del Cofre"
	m.descripcion = "Avanza hasta el cofre. Verifica 'Si tengoLlave' para abrirlo. (Nota: Debes haber recogido la llave antes)."
	m.dificultad_mision = "Difícil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.LLAVE, Vector2i(0, 2))
	caso.agregar_elemento(ElementoTablero.Tipo.COFRE, Vector2i(0, 4))
	caso.agregar_condicion(CondicionMision.Recolectar.new("monedas", 5)) # Cofre da 5 monedas
	m.casos_de_prueba.append(caso)
	
	# Caso 2: Sin llave (No debe abrir el cofre, ni fallar)
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(0, 0)
	caso2.agregar_elemento(ElementoTablero.Tipo.COFRE, Vector2i(0, 4))
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 4)))
	m.casos_de_prueba.append(caso2)
	return m

# ==========================================
# TEMA 4: VARIABLES
# ==========================================

static func crear_mision_variables_01() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "d5eebc99-9c0b-4ef8-bb6d-6bb9bd380a26"
	m.titulo = "Variables 1: La Cuenta"
	m.descripcion = "Declara una variable 'pasos' de tipo entero, asígnale el valor 5 y úsala en un bucle 'Repetir pasos' para avanzar."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_condicion(CondicionMision.VariableTieneValor.new("pasos", 5))
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 5)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(1, 0)
	caso2.agregar_condicion(CondicionMision.VariableTieneValor.new("pasos", 5))
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(1, 5)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_variables_02() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "e6eebc99-9c0b-4ef8-bb6d-6bb9bd380a27"
	m.titulo = "Variables 2: El Acumulador"
	m.descripcion = "Recorre el camino. Crea una variable 'total' que inicie en 0. Cada vez que recojas una moneda, aumenta 'total' en 1."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 2))
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 4))
	caso.agregar_condicion(CondicionMision.VariableTieneValor.new("total", 2))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(0, 0)
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 1))
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 2))
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 3))
	caso2.agregar_condicion(CondicionMision.VariableTieneValor.new("total", 3))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_variables_03() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "f7eebc99-9c0b-4ef8-bb6d-6bb9bd380a28"
	m.titulo = "Variables 3: Matemáticas de Combate"
	m.descripcion = "Declara 'fuerza' = 2 y 'enemigos' = 2. Calcula 'ataques_necesarios' multiplicando ambas variables y avanza esa cantidad de pasos."
	m.dificultad_mision = "Difícil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	# 2 * 2 = 4 pasos
	caso.agregar_condicion(CondicionMision.VariableTieneValor.new("ataques_necesarios", 4))
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 4)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(1, 0)
	caso2.agregar_condicion(CondicionMision.VariableTieneValor.new("ataques_necesarios", 4))
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(1, 4)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_variables_04() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "a8eebc99-9c0b-4ef8-bb6d-6bb9bd380a29"
	m.titulo = "Variables 4: Límite Variable"
	m.descripcion = "Usa la variable del sistema 'posValle'. Crea un bucle 'Mientras posValle < 6' para avanzar hasta la casilla 6."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 5))) # Casilla 6 es índice 5
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(0, 2)
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 5)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_variables_05() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "b9eebc99-9c0b-4ef8-bb6d-6bb9bd380a30"
	m.titulo = "Variables 5: Intercambio"
	m.descripcion = "Declara 'A' = 5 y 'B' = 2. Intercambia sus valores usando una variable auxiliar 'C', luego avanza 'A' pasos (que ahora debe valer 2)."
	m.dificultad_mision = "Difícil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_condicion(CondicionMision.VariableTieneValor.new("A", 2))
	caso.agregar_condicion(CondicionMision.VariableTieneValor.new("B", 5))
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 2)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 0)
	caso2.agregar_condicion(CondicionMision.VariableTieneValor.new("A", 2))
	caso2.agregar_condicion(CondicionMision.VariableTieneValor.new("B", 5))
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 2)))
	m.casos_de_prueba.append(caso2)
	return m

# ==========================================
# TEMA 5: PROCEDIMIENTOS
# ==========================================

static func crear_mision_procedimientos_01() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a31"
	m.titulo = "Procedimientos 1: Técnica Básica"
	m.descripcion = "Define un proceso llamado 'avanzar_tres' que contenga 3 instrucciones 'avanzar'. Llámalo desde el Inicio."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("avanzar_tres"))
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 3)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 0)
	caso2.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("avanzar_tres"))
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 3)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_procedimientos_02() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "d1eebc99-9c0b-4ef8-bb6d-6bb9bd380a32"
	m.titulo = "Procedimientos 2: Recolección Organizada"
	m.descripcion = "Define 'verificar_casilla' que recoja moneda si la hay. Úsalo dentro de un bucle mientras avanzas 5 pasos."
	m.dificultad_mision = "Media"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 3))
	caso.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("verificar_casilla"))
	caso.agregar_condicion(CondicionMision.Recolectar.new("monedas", 1))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(0, 0)
	# Sin moneda, el código no debe fallar
	caso2.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("verificar_casilla"))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_procedimientos_03() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "e2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33"
	m.titulo = "Procedimientos 3: Parámetros de Entrada"
	m.descripcion = "Define 'mover(E pasos: entero)' que use un bucle para avanzar la cantidad de pasos recibida. Llámalo con el valor 4."
	m.dificultad_mision = "Difícil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("mover"))
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 4)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 0)
	caso2.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("mover"))
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 4)))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_procedimientos_04() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "f3eebc99-9c0b-4ef8-bb6d-6bb9bd380a34"
	m.titulo = "Procedimientos 4: Parámetros E/S"
	m.descripcion = "Define 'incrementar(ES valor: entero)' que sume 1 a la variable recibida. Úsalo para contar 3 monedas encontradas."
	m.dificultad_mision = "Difícil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 1))
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 2))
	caso.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(0, 3))
	
	caso.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("incrementar"))
	# No podemos validar fácilmente si usó ES, pero validamos el resultado y la definición
	caso.agregar_condicion(CondicionMision.Recolectar.new("monedas", 3))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(1, 0)
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(1, 1))
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(1, 2))
	caso2.agregar_elemento(ElementoTablero.Tipo.MONEDA, Vector2i(1, 3))
	
	caso2.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("incrementar"))
	caso2.agregar_condicion(CondicionMision.Recolectar.new("monedas", 3))
	m.casos_de_prueba.append(caso2)
	return m

static func crear_mision_procedimientos_05() -> DefinicionMision:
	var m = DefinicionMision.new()
	m.id = "a4eebc99-9c0b-4ef8-bb6d-6bb9bd380a35"
	m.titulo = "Procedimientos 5: El Algoritmo Maestro"
	m.descripcion = "Combina todo. Define 'resolver_obstaculo' (saltar/atacar) y úsalo para superar un camino mixto de enemigos y raíces."
	m.dificultad_mision = "Difícil"
	m.tamano_mapa = Vector2i(25, 25)
	
	var caso = CasoPruebaMision.new()
	caso.inicio_jugador = Vector2i(0, 0)
	caso.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(0, 2))
	caso.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(0, 4))
	
	caso.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("resolver_obstaculo"))
	caso.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	caso.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(0, 6)))
	m.casos_de_prueba.append(caso)
	
	var caso2 = CasoPruebaMision.new()
	caso2.inicio_jugador = Vector2i(2, 0)
	caso2.agregar_elemento(ElementoTablero.Tipo.OBSTACULO, Vector2i(2, 2))
	caso2.agregar_elemento(ElementoTablero.Tipo.ENEMIGO, Vector2i(2, 5))
	
	caso2.agregar_condicion(CondicionMision.ProcedimientoDefinido.new("resolver_obstaculo"))
	caso2.agregar_condicion(CondicionMision.EliminarEnemigos.new())
	caso2.agregar_condicion(CondicionMision.LlegarA.new(Vector2i(2, 6)))
	m.casos_de_prueba.append(caso2)
	return m
