-- Script de inserción de misiones para Algoritmia
-- Tabla asumida: misiones (id, nombre, descripcion, dificultad_mision)

INSERT INTO
    misiones (
        id,
        nombre,
        descripcion,
        dificultad_mision
    )
VALUES
    -- TEMA 1: SECUENCIA
    (
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'Secuencia 1: El Primer Paso',
        'Todo viaje comienza con un paso. Tu objetivo es simple: avanza 3 casillas hacia el norte para adentrarte en el Santuario.',
        'Facil'
    ),
    (
        'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
        'Secuencia 2: El Giro Táctico',
        'El camino no siempre es recto. Avanza 2 pasos, gira a la derecha y avanza 2 pasos más para rodear la estructura antigua.',
        'Facil'
    ),
    (
        'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a13',
        'Secuencia 3: Salto de Fe',
        'Una Raíz Enredante bloquea tu camino. No puedes atravesarla, debes saltarla. Avanza, salta el obstáculo y posiciónate en la meta.',
        'Facil'
    ),
    (
        'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a14',
        'Secuencia 4: Limpieza de Bugs',
        'Un Bug bloquea el pasillo. Los Bugs no se pueden saltar. Debes avanzar, atacar para eliminarlo y luego ocupar su lugar.',
        'Facil'
    ),
    (
        'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a15',
        'Secuencia 5: Recolección',
        'Los recursos son vitales. Avanza por el sendero, recoge la moneda y luego la llave que se encuentra más adelante.',
        'Facil'
    ),
    -- TEMA 2: BUCLES
    (
        'f5eebc99-9c0b-4ef8-bb6d-6bb9bd380a16',
        'Bucles 1: El Sendero Largo',
        'El pasillo es largo y tedioso. Usa el ''Ritual de la Perseverancia'' (Repetir) para avanzar 8 pasos sin escribir la instrucción 8 veces.',
        'Medio'
    ),
    (
        'a6eebc99-9c0b-4ef8-bb6d-6bb9bd380a17',
        'Bucles 2: Caminata Cauta',
        'Debes llegar hasta el final del valle (casilla 14), pero no sabes exactamente cuántos pasos son. Usa ''Mientras posValle < 14'' para avanzar seguro.',
        'Medio'
    ),
    (
        'b7eebc99-9c0b-4ef8-bb6d-6bb9bd380a18',
        'Bucles 3: Barrido de Monedas',
        'Hay una fila de 5 monedas frente a ti. Crea un bucle que repita la acción de ''recogerMoneda'' y ''avanzar'' para obtenerlas todas.',
        'Medio'
    ),
    (
        'c8eebc99-9c0b-4ef8-bb6d-6bb9bd380a19',
        'Bucles 4: Patrulla Cuadrada',
        'Realiza una patrulla en forma de cuadrado de 3x3 pasos. Usa un bucle que se repita 4 veces: avanzar 3 pasos y girar a la derecha.',
        'Medio'
    ),
    (
        'd9eebc99-9c0b-4ef8-bb6d-6bb9bd380a20',
        'Bucles 5: El Valle de las Sombras',
        'El camino está infestado de enemigos invisibles. Avanza hasta el final del sendero (casilla 8), pero ATACA antes de cada paso por seguridad.',
        'Dificil'
    ),
    -- TEMA 3: CONDICIONALES
    (
        'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a21',
        'Condicionales 1: Ojos Abiertos',
        'Avanza 5 pasos. En cada paso, verifica ''Si hayMoneda'' entonces recógela. No siempre habrá monedas.',
        'Medio'
    ),
    (
        'f1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
        'Condicionales 2: Defensa Reactiva',
        'Avanza por el pasillo. Si encuentras un enemigo, atácalo. Si no hay enemigo, simplemente avanza.',
        'Medio'
    ),
    (
        'a2eebc99-9c0b-4ef8-bb6d-6bb9bd380a23',
        'Condicionales 3: Decisiones del Camino',
        'El camino puede tener raíces. Usa ''Si hayObstaculo'' para saltar, ''Sino'' avanza normalmente. Repite esto 5 veces.',
        'Medio'
    ),
    (
        'b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a24',
        'Condicionales 4: Lógica Compuesta',
        'Busca una moneda protegida. Solo si ''hayMoneda AND hayEnemigo'' debes atacar y luego recoger. Si solo hay moneda, recógela sin atacar.',
        'Dificil'
    ),
    (
        'c4eebc99-9c0b-4ef8-bb6d-6bb9bd380a25',
        'Condicionales 5: El Guardián del Cofre',
        'Avanza hasta el cofre. Verifica ''Si tengoLlave'' para abrirlo. (Nota: Debes haber recogido la llave antes).',
        'Dificil'
    ),
    -- TEMA 4: VARIABLES
    (
        'd5eebc99-9c0b-4ef8-bb6d-6bb9bd380a26',
        'Variables 1: La Cuenta',
        'Declara una variable ''pasos'' de tipo entero, asígnale el valor 5 y úsala en un bucle ''Repetir pasos'' para avanzar.',
        'Medio'
    ),
    (
        'e6eebc99-9c0b-4ef8-bb6d-6bb9bd380a27',
        'Variables 2: El Acumulador',
        'Recorre el camino. Crea una variable ''total'' que inicie en 0. Cada vez que recojas una moneda, aumenta ''total'' en 1.',
        'Medio'
    ),
    (
        'f7eebc99-9c0b-4ef8-bb6d-6bb9bd380a28',
        'Variables 3: Matemáticas de Combate',
        'Declara ''fuerza'' = 2 y ''enemigos'' = 2. Calcula ''ataques_necesarios'' multiplicando ambas variables y avanza esa cantidad de pasos.',
        'Dificil'
    ),
    (
        'a8eebc99-9c0b-4ef8-bb6d-6bb9bd380a29',
        'Variables 4: Límite Variable',
        'Usa la variable del sistema ''posValle''. Crea un bucle ''Mientras posValle < 6'' para avanzar hasta la casilla 6.',
        'Medio'
    ),
    (
        'b9eebc99-9c0b-4ef8-bb6d-6bb9bd380a30',
        'Variables 5: Intercambio',
        'Declara ''A'' = 5 y ''B'' = 2. Intercambia sus valores usando una variable auxiliar ''C'', luego avanza ''A'' pasos (que ahora debe valer 2).',
        'Dificil'
    ),
    -- TEMA 5: PROCEDIMIENTOS
    (
        'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a31',
        'Procedimientos 1: Técnica Básica',
        'Define un proceso llamado ''avanzar_tres'' que contenga 3 instrucciones ''avanzar''. Llámalo desde el Inicio.',
        'Medio'
    ),
    (
        'd1eebc99-9c0b-4ef8-bb6d-6bb9bd380a32',
        'Procedimientos 2: Recolección Organizada',
        'Define ''verificar_casilla'' que recoja moneda si la hay. Úsalo dentro de un bucle mientras avanzas 5 pasos.',
        'Medio'
    ),
    (
        'e2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33',
        'Procedimientos 3: Parámetros de Entrada',
        'Define ''mover(E pasos: entero)'' que use un bucle para avanzar la cantidad de pasos recibida. Llámalo con el valor 4.',
        'Dificil'
    ),
    (
        'f3eebc99-9c0b-4ef8-bb6d-6bb9bd380a34',
        'Procedimientos 4: Parámetros E/S',
        'Define ''incrementar(ES valor: entero)'' que sume 1 a la variable recibida. Úsalo para contar 3 monedas encontradas.',
        'Dificil'
    ),
    (
        'a4eebc99-9c0b-4ef8-bb6d-6bb9bd380a35',
        'Procedimientos 5: El Algoritmo Maestro',
        'Combina todo. Define ''resolver_obstaculo'' (saltar/atacar) y úsalo para superar un camino mixto de enemigos y raíces.',
        'Dificil'
    );