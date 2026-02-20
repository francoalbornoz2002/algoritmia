-- Script de inserción de misiones para Algoritmia
-- Tabla asumida: misiones (id, numero, nombre, descripcion, dificultad_mision)

INSERT INTO
    misiones (
        id,
        numero,
        nombre,
        descripcion,
        dificultad_mision
    )
VALUES (
        '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
        1,
        'Tutorial 1: Movimiento Básico',
        '¡Comienza el viaje! Comencemos por lo básico. Utiliza las primitivas "avanzar" y "derecha" para recorrer las celdas indicadas en el mapa para terminar donde empezaste.',
        'Facil'
    ),
    (
        'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a12',
        2,
        'Tutorial 2: Recolección',
        '¡Monedas! Avanza 3 casillas hacia adelante y utiliza la primitiva ''recogerMoneda'' para recolectar las monedas en el mapa.',
        'Facil'
    ),
    (
        'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a13',
        3,
        'Tutorial 3: Salto y obstáculos',
        '¡Atención! En tu viaje encontrarás obstáculos. Cuando estés frente a uno, usa la primitiva ''saltar'' para evadirlo. Avanza y evade para recoger la moneda que se encuentra al final de los obstáculos.',
        'Facil'
    ),
    (
        'd3eebc99-9c0b-4ef8-bb6d-6bb9bd380a14',
        4,
        'Tutorial 4: Enemigos',
        '¡Cuidado! Hay muchos monstruos asechando. Cada 2 casillas encontrarás un enemigo, avanza una vez y utiliza la primitiva ''atacar'' para derrotar a los enemigos y recolectar la moneda al final.',
        'Facil'
    ),
    (
        'e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a15',
        5,
        'Tutorial 5: Decisiones 1',
        'Todos los días tomamos decisiones, donde sea y en cualquier lugar, y aqui no es la excepción. Avanza 3 casillas y utiliza el ''Emblema del Juicio'' con los sensores ''hayObstaculo'' y ''hayMoneda'' para decidir si ejecutar o no ''recogerMoneda'' o ''saltar''. ¡Prepara bien tu algoritmo! el mapa cambiará su composición de manera inesperada...',
        'Facil'
    ),
    (
        'f5eebc99-9c0b-4ef8-bb6d-6bb9bd380a16',
        6,
        'Tutorial 6: Decisiones 2',
        '¡Más decisiones!. El emblema del juicio no solo sirve para hacer algo si y solo si se cumple algo, tambien puedes especificar si quieres hacer OTRA COSA si no se cumple dicha condición. Avanza 3 casillas y utiliza el sensor ''hayEnemigo'' para verificar si hay un enemigo. Si hay, atácalo, gira a la dercha y avanza dos casillas más. Sino, sigue tu camino y avanza 3 casillas más.',
        'Facil'
    ),
    (
        'a6eebc99-9c0b-4ef8-bb6d-6bb9bd380a17',
        7,
        'Tutorial 7: Decisiones 3 (AND)',
        '¡Decisiones compuestas! El Emblema del Juicio es bastante poderoso y te permite evaluar más de una condición con la palabra clave AND entre proposiciones. Avanza 3 casillas, si hay una moneda y un obstáculo en frente, recoge la moneda y salta el obstáculo. Si no se cumplen esas condiciones, gira hacia atrás y vuelve donde comenzaste.',
        'Medio'
    ),
    (
        'b7eebc99-9c0b-4ef8-bb6d-6bb9bd380a18',
        8,
        'Tutorial 8: Decisiones 4 (OR)',
        'Más decisiones... Así como el Emblema del Jucio te permite evaluar si se cumplen si o si dos condiciones, tambien te permite evaluar si se cumple al menos una de ellas con la palabra clave OR entre proposiciones. Avanza 3 casillas, si hay una moneda o hay un obstaculo, haz un giro de 360 grados, recoge la moneda y salta el obstáculo. Sino, gira a la derecha y avanza 3 casillas más.',
        'Medio'
    ),
    (
        'c8eebc99-9c0b-4ef8-bb6d-6bb9bd380a19',
        9,
        'Tutorial 9: Decisiones 5 (NOT)',
        '¡Negador! Cuánto poder del Emblema del Juicio, hasta te permite negar cualquier proposición. Avanza 3 casillas, si no hay enemigo al asecho, avanza 3 casillas más. Sino, atácalo, da media vuelta y vuelve al inicio.',
        'Medio'
    ),
    (
        'd9eebc99-9c0b-4ef8-bb6d-6bb9bd380a20',
        10,
        'Tutorial 10: Puentes',
        'El terreno, a veces, tiene fosas de agua y solo se pueden atravesar mediante un puente, pero debes pagar peaje. Necesitas una moneda para poder activar el puente. Avanza 3 casillas y si encuentras una moneda, recógela. Luego, utiliza el sensor hayPuente para ver si hay uno. ¡Recuerda verificar si tienes una moneda para pagar! activa el puente y avanza 3 casillas más. Si no hay puente o no puedes activarlo, da media vuelta y vuelve al inicio.',
        'Facil'
    ),
    (
        'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380a21',
        11,
        'Tutorial 11: Llaves y Cofres',
        '¡Tesoros! Por el camino puedes encontrar cofres que te otorgarán 5 monedas al abrirlos, pero necesitas una llave para ello. Utiliza los sensores hayLlave, hayCofre y tengoLlave para evaluar, y la primitiva abrirCofre si tienes llave y existe dicho cofre. Avanza una casilla y busca una llave, luego avanza una casilla más y abre un cofre si existe.',
        'Medio'
    ),
    (
        'f1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
        12,
        'Tutorial 12: Repetir',
        '¡Repito! Puedes usar el Ritual de la Perseverancia para repetir una serie de acciones un numero conocido y finito de veces. ¡Pruébalo! Avanza 10 lugares recolectando las monedas que haya por el camino.',
        'Facil'
    ),
    (
        'a2eebc99-9c0b-4ef8-bb6d-6bb9bd380a23',
        13,
        'Tutorial 13: Bucles 1',
        '¡Repito! Mejorado. Usando el Orbe del Ciclo Infinito puedes repetir acciones mientras se esté cumpliendo una condición, pero ten cuidado, es un arma de doble filo, si no se utiliza bien ¡Puedes caer en un bucle infinito!. Recorre todo el sendero 1 hasta el final, luego, gira a la derecha y recorre todo el valle 25. ¡Asegurate de no chocar con los límites del mapa! Utiliza los sensores ''posSendero'' y ''posValle'' para evaluar tu posicion actual. En todo tu recorrido tienes que ir recolectando las monedas que encuentres.',
        'Medio'
    ),
    (
        'b3eebc99-9c0b-4ef8-bb6d-6bb9bd380a24',
        14,
        'Tutorial 14: Bucles 2 (AND)',
        'Al igual que el Emblema del Juicio, El Orbe del Ciclo Infinito también te permite realizar acciones mientras se cumplan dos o más condiciones usando el conectivo AND. Recorre todo el sendero 1 hasta encontrar una moneda. Si la encuentras, recógela, gira a la derecha y recorre el valle hasta el final. Si no encuentra la moneda, da media vuelta y vuelve al inicio.',
        'Medio'
    ),
    (
        'c4eebc99-9c0b-4ef8-bb6d-6bb9bd380a25',
        15,
        'Tutorial 15: Bucles 3 (OR)',
        'O esto o lo otro... una de dos. Tambien puedes usar el conectivo OR en el Orbe del Ciclo Infinito para evaluar si al menos una de las proposiciones se cumple para continuar. Recorre todo el sendero 1 hasta encontrar una moneda y una llave en la misma casilla, es algo raro de ver asi que habrán enemigos al asecho. Cuando las encuentres, recógelas, gira a la derecha y recorre el valle hasta el final. Si no las encuentras hasta el final del sendero, da media vuelta y vuelve al inicio.',
        'Medio'
    ),
    (
        'd5eebc99-9c0b-4ef8-bb6d-6bb9bd380a26',
        16,
        'Tutorial 16: Bucles 4 (NOT)',
        '¡Negador! Tambien puedes usar el NOT para negar las proposiciones usando el Orbe del Ciclo Infinito. Recorre todo el sendero 1 mientras no encuentres una moneda. Si la encuentras, gira a la derecha y recorre todo el valle en el que te encuentres. Si no la encuentras, da media vuelta y vuelve al inicio.',
        'Medio'
    ),
    (
        'e6eebc99-9c0b-4ef8-bb6d-6bb9bd380a27',
        17,
        'Mision Prueba',
        'Recorre todo el sendero 1, recolectando monedas, llaves, abriendo cofres, activando puentes (o rodearlos si no puedes), derrotando enemigos y evadiendo obstáculos.',
        'Dificil'
    );