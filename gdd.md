# Game Design Document

**Versión:** 3.1
**Fecha:** 05/12/2025
**Autor(es):** Franco Andrés Albornoz

---

# 1. Título

El título del juego será “Algoritmia”.

# 2. Resumen del juego

Algoritmia es un videojuego que forma parte de la Plataforma Algoritmia. Es un videojuego en donde aprenderás algoritmos, lógica y estructuras de control resolviendo problemas diseñando y visualizando la ejecución tu propio algoritmo. Deberás enfrentarte a desafíos, recolectar y usar objetos, atacar enemigos y evitar obstáculos con tu propio algoritmo diseñado a tu manera para completar la misión y aprendiendo en el proceso.

# 3. Concepto y pilares de diseño

La escencia del videojuego y lo que se quiere transmitir se basan en estos 3 pilares:

## 3.1 Pseudolenguaje gamificado y ejecución del algoritmo

Algoritmia tendrá un pseudolenguaje gamificado compuesto con primitivas, estructuras de control, manejo de variables y procedimientos que permitirán al jugador diseñar sus soluciones para las misiones del juego, visualizando la ejecución del algoritmo en el Mapa de misión. Se tienen las siguientes reglas generales para el lenguaje:

- Se escribe en formato pseudocódigo adaptado.
- Cada línea representa una instrucción o bloque lógico.
- El pseudocodigo es sensible a la estructura (usa indentación) para saber qué instrucciones pertenecen a qué bloque de código.
- Para diferenciar el programa principal de la declaración de variables globales, procedimientos, etc, se utilizarán dos palabras reservadas
  - “Inicio” para indicar el inicio del algoritmo principal
  - “Fin” para indicar el fin del algoritmo.
- Todo lo que esté dentro de las palabras reservadas “Inicio” y “Fin” serán ejecutadas en el Mapa de misión.
- Por encima de la palabra “Inicio” solamente podrán haber declaraciones de variables (NO ASIGNACIONES A VARIABLES) y procedimientos.
- No podrá haber nada por debajo de la palabra “Fin”.

## 3.2 Aprendizaje continuo con feedback inmediato

Algoritmia busca brindar aprendizaje continuo mediante feedback inmediato durante y post diseño del algoritmo para resolver la misión. Algoritmia analizará automáticamente el código del jugador y ofrecerá sugerencias y optimizaciones para mejorar el algoritmo propuesto, asi como tambien la recopilación de datos de los errores frecuentes individuales para la toma de decisiones o refuerzo de contenidos a posteriori por parte de los docentes.

## 3.3 Detección de dificultades

Una de las tareas del videojuego Algoritmia es detectar las dificultades de los jugadores para registrarlas o actualizarlas a la Plataforma Algoritmia. Algoritmia evaluará en cada ejecución del algoritmo los posibles errores o malas prácticas y los relacionará con las dificultades detectables del videojuego. Teniendo umbrales definidos para cada grado de dificultad, se le registrará una nueva dificultad al jugador o bien se le actualizará el grado de alguna existente, de manera local y posteriormente se sincronizará a la Plataforma Algoritmia.

# 4. Descripción del juego

Algoritmia es un videojuego de aventura con estética pixel art estilo RPG con vista top-down, en donde el jugador tendrá que completar misiones diseñadas y enfocadas temáticamente a los conceptos base de la programación. El alcance del videojuego abarcará los conceptos de:

- Algoritmos y secuencia de pasos
- Lógica proposicional
  - Proposiciones simples y compuestas
  - Operadores lógicos: OR, AND, NOT
  - Operadores matemáticos: suma (+), resta (-), multiplicación (\*), división (/) y módulo (mod).
  - Operadores relacionales: <, >, ==, <=, >=, !=
- Estructuras de control (Si-Sino, Mientras y Repetir)
- Declaración y asignación de variables (globales y locales)
- Procedimientos sin parámetros o con parámetros de: entrada y entrada/salida.

El jugador deberá hacer uso del pseudolenguaje gamificado utilizando las primitivas, estructuras de control, manejo de variables y procedimientos que permiten al jugador diseñar algoritmos para poder completar misiones con reglas y condiciones específicas, visualizando la ejecución del algoritmo en el Mapa de Misión, el cual está diseñado y representado como un tablero con columnas, filas y casilleros.

El objetivo de Algoritmia es que el jugador pueda lograr el aprendizaje continuo de las bases de la programación. Para ello, el videojuego ofrecerá la documentación del pseudolenguaje en todo momento, ayudas al jugador para detectar y corregir errores de manera sencilla y lo más importante: feedback inmediato en forma de sugerencias y optimizaciones formativas y explicativas para mejorar el algoritmo propuesto.

Además, Algoritmia forma parte de un sistema más grande, la Plataforma Algoritmia. Es unna plataforma web de seguimiento de progreso y dificultades para instituciones educativas con materias orientadas a las bases de la programación o algoritmos. Algoritmia registrará las misiones completadas del jugador con sus resultados obtenidos (estrellas, exp e intentos) y detectará las dificultades del jugador a la hora de resolver las misiones, todo ello para registrarlas (misiones y dificultades) en la plataforma web para el seguimiento por parte de los docentes.

## 4.1 Feedback formativo y ayudas

Las ayudas que se ofrecerán son las siguientes:

1. **Manual del heroe**: El “_Manual del Heroe_” es un manual que representará la documentación de las primitivas, variables de juego entre otras instrucciones. Estará disponible para consulta del jugador en todo momento durante el diseño del algoritmo. Especificará la sintaxis y semántica de cada primitiva, estructura de control, variable de juego, el manejo de variables y procedimientos que el jugador puede utilizar para resolver la misión.
2. **Resaltado de sintaxis**: se resaltarán los errores de sintaxis y advertencias en color rojo y amarillo respectivamente.

En cuando al feedback formativo, se dará en dos etapas:

**1. Al intentar ejecutar**
Cuando el alumno terminó de diseñar el algoritmo y decida ejecutar, el sistema verificará que la estructura y sintaxis esté correctamente escrita para ejecutar.

**Errores**
Los errores son aquellos que impiden que la ejecución del algoritmo se lleve a cabo. Los posibles errores a indicar son los siguientes:

| Error                  | Descripción                                                                               | Feedback                                                                                                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Error de sintaxis      | Se da cuando hay instrucciones o estructuras mal escritas                                 | Indicador rojo en el número de la linea del error y subrayado en rojo en la instrucción o estructura mal escrita. Si se apoya el cursor por encima del error se mostrará “Error de sintaxis”.                |
| Variable no declarada  | Cuando se intenta utilizar una variable (global o local) que no fue declarada previamente | Indicador rojo en el número de la linea del error y subrayado en rojo en donde se quiere utilizar la variable. Si se apoya el cursor por encima del error se mostrará el mensaje de “Variable no declarada”. |
| Parámetros indefinidos | Cuando se llama a un procedimiento y no se colocan los parámetros de manera correcta      | Indicador rojo en la linea del error y subrayado en rojo en el procedimiendo llamado. Si se apoya el cursor por encima del error se mostrará “Parámetros erróneos o indefinidos”.                            |

**Advertencias**
Las advertencias son aquellas que no impiden que el algoritmo se ejecute pero son recomendable de atender. Las posibles advertencias son las siguientes:

| Advertencia                              | Descripción                                             | Feedback                                                                                                                                                                                                                                                             |
| ---------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Variable declarada pero no utilizada     | Cuando se declara una variable pero nunca se utiliza    | Mientras el jugador no la utilice, indicador en amarillo en la línea de la advertencia y subrayado en amarillo en la variable declarada pero no utilizada. Si se apoya el cursor por encima de este aviso se mostrará “Variable no utilizada”.                       |
| Procedimiento definido pero no utilizado | Cuando se define un procedimiento pero nunca se utiliza | Mientras el jugador no lo utilice, indicador en amarillo en la línea de la advertencia y subrayado en amarillo en la cabecera del procedimiento definido pero no utilizado. Si se apoya el cursor por encima de este aviso se mostrará “Procedimiento no utilizado”. |

**2. Después de la ejecución del algoritmo indicando:**
Luego de la ejecución del algoritmo del alumno, completado el ejercicio y dada la puntuación obtenida, el sistema analizará el algoritmo proponiendo mejoras y optimizaciones:

- **Validación de existencia del objeto antes de recogerlo**: si el jugador escribió una linea de, por ejemplo, `recogerMoneda` sin verificar si la monea existe, es decir, dentro de un bloque Si-Sino, se sugerirá colocar siempre una estructura Si-Sino verificando primero si el objeto existe antes de recolectarlo.
- **Redundancia de instrucciones**: si hay al menos 2 lineas de código secuenciales llamando a la misma instrucción se sugerirá reemplazarlas por una estructura repetitiva como un mientras o un repetir.
- **Redundancia de condicionales**: si hay al menos 2 estructuras de control “Si” una debajo de la otra se sugerirá reemplazarlas por una estructura condicional con una proposición compuesta por las dos proposiciones originales utilizando un conectivo lógico apropiado.
- **Redundancia de bucles**: si hay al menos 2 estructuras de control “Mientras” o “Repetir” una debajo de la otra se sugerirá reemplazarlas por una estructura repetitiva con una proposición compuesta por las dos proposiciones originales utilizando un conectivo lógico apropiado.
- **Variables no utilizadas**: si hay variables declaradas pero no utilizadas se sugerirán eliminarlas del código.

## 4.2 Detección de dificultades

Algoritmia podrá detectar hasta 15 dificultades diferentes divididas en 5 temas: Secuencia, Lógica, Estructuras de Control, Variables y Procedimientos. De cada tema se tendrán 3 dificultades detectables:

| Codigo | Dificultad                                        | Tema                        | Descripción                                                                                                                                                                                                                                                                                             |
| ------ | ------------------------------------------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SL-01  | Redundancia de instrucciones                      | `Secuencia y Lógica Básica` | El alumno ejecuta dos o más veces la misma instrucción atómica sin necesidad en lugar de usar una estructura de control como Repetir o Mientras.                                                                                                                                                        |
| SL-02  | No valida un objeto antes de recogerlo            | `Secuencia y Lógica Básica` | El alumno realiza recolección de objetos como recogerMoneda o recogerLlave sin primero validar si ese objeto existe con una estructura Si-Sino con los sensores correspondientes (hayMoneda, hayLlave).                                                                                                 |
| SL-03  | Uso de instrucciones innecesarias                 | `Secuencia y Lógica Básica` | El alumno realiza acciones específicas fuera de contexto de manera arbitraria, como usar ‘atacar’ sin validar si hay un enemigo o ‘saltar’ sin comprobar si existe un obstáculo.                                                                                                                        |
| LP-01  | Mal uso o confusión con operadores lógicos        | `Lógica Proposicional`      | El alumno posee problemas para formular condiciones compuestas con AND, OR, NOT, como usar OR en lugar de AND, AND en lugar de OR o utilizar la negación NOT en lugar incorrecto.                                                                                                                       |
| LP-02  | Mal uso o confusión con operadores relacionales   | `Lógica Proposicional`      | El alumno posee problemas usando <, >, <=, >=, =, !=. Comparaciones imposibles, comparadores duplicados o confusión entre = y !=.                                                                                                                                                                       |
| LP-03  | Problemas para formular proposiciones compuestas  | `Lógica Proposicional`      | Esta es una dificultad generalizada. Se calcula a partir de LP-01 y LP-02. No se detecta por casos de prueba individuales.                                                                                                                                                                              |
| EC-01  | Bucles mal controlados o infinitos                | `Estructuras de Control`    | El alumno escribe un bucle cuya condición nunca cambia, es imposible o es siempre verdadera generando un bucle infinito o nunca ejecutado.                                                                                                                                                              |
| EC-02  | Uso incorrecto del bloque SI–SINO                 | `Estructuras de Control`    | El alumno construye mal una estructura condicional, generando acciones redundantes, incoherentes o innecesarias dentro del bloque SI–SINO, como un bloque instrucciones escritas tanto en el SI como en el SINO o se tiene un SINO vacío.                                                               |
| EC-03  | Condicionales mal anidados                        | `Estructuras de Control`    | El alumno utiliza condicionales dentro de otros condicionales de forma innecesaria, confusa o incorrecta, cuando debería combinar proposiciones atómicas usando AND/OR para generar una proposición compuesta y reorganizar la estructura.                                                              |
| VA-01  | Confusión entre variables locales y globales      | `Variables`                 | El alumno realiza redefiniciones indebidas, uso de una variable fuera de su bloque o pérdida de valores.                                                                                                                                                                                                |
| VA-02  | Uso de variables sin inicializar                  | `Variables`                 | El alumno utiliza una variable en algún proceso de calculo o decisión sin antes asignarle un valor a dicha variable (está evaluando un null).                                                                                                                                                           |
| VA-03  | Uso inconsistente de variables                    | `Variables`                 | El alumno declara variables pero no las utiliza o las utiliza de manera que no aportan ningún efecto al algoritmo, como asignar valores que nunca son leídos, crear variables que nunca participan del proceso de decisión o cálculo o esa variable nunca cambia de valor (almacena un dato constante). |
| PR-01  | Mal pasaje de parámetros                          | `Procedimientos`            | El alumno llama un procedimiento pasándole más o menos parámetros de los definidos en el procedimiento, o pasa parámetros incompatibles con el tipo de dato esperado.                                                                                                                                   |
| PR-02  | No modifica el parámetro de entrada/salida        | `Procedimientos`            | El alumno declara un parámetro como E/S pero éste nunca se modifica dentro del cuerpo del procedimiento.                                                                                                                                                                                                |
| PR-03  | No utiliza todos los parámetros del procedimiento | `Procedimientos`            | El alumno declara un procedimiento con parámetros, pero alguno de ellos (o todos) nunca son usados dentro del cuerpo del procedimiento.                                                                                                                                                                 |

## 4.3 Core Loop

El Core Loop principal del videojuego es:

1. Iniciar sesión en el videojuego (solo la primera vez, luego se guarda e inicia solo.)
2. Ingresar al mapa principal del juego.
3. Seleccionar la misión deseada.
4. Diseñar un algoritmo para resolver la misión.
5. Ejecutar el algoritmo visualizando el efecto de cada instrucción en el mapa.
6. Si se completa la misión exitosamente, recibir una puntuación entre 1 y 3 estrellas con los puntos de experiencia (EXP) correspondientes.
7. Recibir feedback formativo por parte del juego para refactorizar y mejorar el algoritmo.

# 5. Historia

## 5.1 Narrativa

“Cuenta la leyenda que en el reino de **“Algoritmia”**, en lo más profundo del _Santuario Algorismi_ se encuentra escondido un tesoro muy especial: un algoritmo que tiene el poder de resolverlo todo, llamado _Algorismus Resolutor_.
No importa el problema, el contexto ni los involucrados: se dice que este algoritmo es capaz de adaptarse a cualquier situación y resolverla de manera eficiente y eficaz.

Muchos guerreros algorítmicos han intentado alcanzar este anhelado tesoro, pero ninguno ha logrado superar todas las pruebas del Santuario Algorismi. Algunos dicen que fallan porque no razonan ni analizan el problema frente a ellos, que se lanzan sin planificación o toman decisiones apresuradas sin considerar las condiciones del entorno.

La leyenda indica que solo aquel guerrero que desarrolle ciertas habilidades muy especiales será digno de hallar el _Algorismus Resolutor_:

I. Gran capacidad de razonamiento lógico.
II. Planificación ordenada de sus acciones”.
III. Toma de decisiones precisas, evaluando los posibles caminos..
IV. Tenacidad para repetir acciones las veces que sea necesario, conociendo o no su fin.
V. Administración y uso de los suministros y objetos del viaje.
VI. Definición de planes de acción para distintas situaciones.

Y lo más importante, el guerrero deberá tener presente las tres sagradas reglas de la Algoritmia:

I. **Finitud** de acciones a realizar
II. **Precisión** en cada acción sin ambigüedad y con exactitud.
III. **Definición** de comportamiento para producir los mismos resultados en diferentes situaciones.

Movido por esta leyenda, un/una joven guerrero/a algorítmico/a novato/a —pero con una gran determinación- decide emprender su viaje hacia el _Santuario Algorismi_, con la esperanza de alcanzar el _Algorismus Resolutor_.
A lo largo del camino, deberá superar pruebas difíciles, adquirir conocimientos y habilidades en el arte de la algoritmia, enfrentar obstáculos, combatir enemigos, recolectar objetos clave y perfeccionar estrategias que lo acerquen, paso a paso, a su objetivo.”

# 6. Gameplay

## 6.1 Mapa de misión

Cada misión estará compuesto por un mapa de misión que estará organizado por **Senderos** (columnas), **Valles** (filas) y **Cruces** (intersección de un Sendero y un Valle). Tanto Sendero como Valle tienen como valor mínimo 1, sus valores máximo estarán dados por el tamaño del Mapa de Misión, el cual puede tener 4 posibles tamaños: 25x25, 50x50, 75x75 y 100x100.

- **Senderos**: Son columnas verticales del mapa.
  - Cuando el jugador recorre un sendero, se desplaza **hacia arriba o hacia abajo**, manteniéndose siempre en el mismo sendero.
  - En este caso, lo que cambia es el Valle en el que se encuentra.
- **Valles**: Son filas horizontales del mapa.
  - Cuando el jugador recorre un valle, se desplaza **hacia la izquierda o hacia la derecha**, manteniéndose en el mismo valle.
  - En este caso, lo que cambia es el Sendero en el que se encuentra.

**En resumen**:

- **Recorrer un sendero** = moverse verticalmente → cambia _posValle_.
- **Recorrer un valle** = moverse horizontalmente → cambia _posSendero_.

### Posición inicial

El jugador siempre comenzará la misión posicionado en el Cruce (1, 1) (Sendero 1, Valle 1) mirando hacia arriba.

### Límites del mapa

Si el jugador intenta sobrepasar el límite del mapa (tanto vertical como horizontal) se da un error de ejecución y la misión falla.

- Por ejemplo, si el jugador está jugando una misión con un mapa de 25x25, se encuentra en el Sendero 25 y, mirando hacia arriba, intenta ejecutar `avanzar` o `saltar`, el jugador choca con el límite (con alguna animación de choque o algo), la ejecución se detiene y falla el intento automáticamente porque se quiso sobrepasar los límites del mapa.
  - Lo mismo ocurre si el jugador está en el Sendero 1 y, mirando hacia abajo, intenta ejecutar `avanzar` o `saltar`, el jugador choca con el límite (con alguna animación de choque o algo), la ejecución se detiene porque se quiso sobrepasar los límites del mapa.
- Otro ejemplo, si el jugador está jugando una misión, con el mismo tamaño de mapa (25x25), se encuentra en el Valle 25 y, mirando hacia la derecha, intenta ejecutar `avanzar` o `saltar`, el jugador choca con el límite (con alguna animación de choque o algo), la ejecución se detiene porque se quiso sobrepasar los límites del mapa.
  - Lo mismo ocurre si el jugador está en el Valle 1 y, mirando hacia la izquierda, intenta ejecutar `avanzar` o `saltar`, el jugador choca con el límite (con alguna animación de choque o algo), la ejecución se detiene porque se quiso sobrepasar los límites del mapa.

## 6.2 Mecánicas del personaje (Primitivas)

Estas son las instrucciones básicas (primitivas) que el jugador podrá realizar

| Primitiva                                                                                                             | Tipo          | Descripción                                                                                                                                                                                                             |
| --------------------------------------------------------------------------------------------------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `avanzar`                                                                                                             | `movimiento`  | - El jugador avanza a la siguiente casilla en la dirección a la que está viendo actualmente                                                                                                                             |
| `derecha`                                                                                                             | `movimiento`  | - El jugador hace un giro de 90° hacia la derecha.                                                                                                                                                                      |
| `saltar`                                                                                                              | `movimiento`  | - El jugador salta hacia adelante (en la dirección a la que está viendo actualmente) omitiendo una casilla. Es decir, si estoy en la casilla 1 y hago un salto, omito o esquivo la casilla 2 y termino en la casilla 3. |
| - Esta primitiva solo puede usarse cuando haya que superar un obstáculo, no se podrá saltar por encima de un enemigo. |
| `atacar`                                                                                                              | `interacción` | - El jugador ataca, si existe, al enemigo en la casilla siguiente a la casilla donde se encuentra posicionado y viendo actualmente el jugador.                                                                          |
| `recogerMoneda`                                                                                                       | `interacción` | - El jugador recoge, si existe, la moneda en la casilla actual y suma +1 a las monedas de inventario.                                                                                                                   |
| `recogerLlave`                                                                                                        | `interacción` | - El jugador recoge, si existe, la llave en la casilla actual y suma +1 a las llaves de inventario.                                                                                                                     |
| `abrirCofre`                                                                                                          | `interacción` | - El jugador abre, si existe y si tiene una llave, el cofre en la casilla actual y suma +5 a las monedas de inventario.                                                                                                 |

- Al encontrar un cofre y al hacer la validación compleja (si hayCofre AND tengoLlave) se le suma 1 estrella automáticamente al puntaje del alumno.
- Si el alumno ya llevaba 2 o un poco más de estrellas acumulada mientras se ejecuta, se le suma 3 directamente, siempre y cuando complete bien la misión. |
  | `activarPuente` | `interacción` | - El jugador activa, si existe un puente en la casilla ubicada justo al frente en la dirección en que está mirando y si tiene al menos una moneda, dicho puente, consumiendo una moneda al hacerlo. |
  | `hayMoneda` | `sensor` | - Evalúa si existe una moneda en la casilla actual del jugador, retorna verdadero o falso.
- Esta primitiva solo puede usarse como proposición dentro de estructuras de control “Si” o “Mientras”. |
  | `hayLlave` | `sensor` | - Evalúa si existe una llave en la casilla actual del jugador, retorna verdadero o falso.
- Esta primitiva solo puede usarse como proposición dentro de estructuras de control “Si” o “Mientras”. |
  | `hayCofre` | `sensor` | - Evalúa si existe una cofre en la casilla actual del jugador, retorna verdadero o falso.
- Esta primitiva solo puede usarse como proposición dentro de estructuras de control “Si” o “Mientras”. |
  | `hayEnemigo` | `sensor` | - Evalúa si hay un enemigo en la casilla siguiente a la casilla del jugador (teniendo en cuenta la dirección a la que está viendo actualmente), retorna verdadero o falso.
- Con enemigo nos referimos a cualquier enemigo definido en el juego sin distinción.
- Esta primitiva solo puede usarse como proposición en estructuras de control “Si” o “Mientras” |
  | `hayPuente` | `sensor` | - Evalúa si hay un puente en la casilla siguiente a la casilla del jugador (teniendo en cuenta la dirección a la que está viendo actualmente), retorna verdadero o falso.
- Esta primitiva solo puede usarse como proposición en estructuras de control “Si” o “Mientras” |
  | `hayObstaculo` | `sensor` | - Evalúa si hay un obstáculo en la casilla siguiente a la casilla del jugador (teniendo en cuenta la dirección a la que está viendo actualmente), retorna verdadero o falso.
- Con obstáculo nos referimos a cualquier obstáculo definido en el juego sin distinción.
- Esta primitiva solo puede usarse como proposición en estructuras de control “Si” o “Mientras”. |

## 6.3 Variables de juego

Las variables de juego son las variables relacionadas a los distintos elementos presentes en el mapa de la misión.

| Variable     | Tipo        | Descripción                                       |
| ------------ | ----------- | ------------------------------------------------- |
| `posSendero` | `escenario` | - Representa las `Columnas` del `Tablero (Mapa)`. |

- Es el valor de posición actual del jugador en el eje vertical (eje Y) en el `Mapa`. Tiene como valor mínimo 1 y como valor máximo el límite del `Mapa` definido en el eje Y (El cual puede variar entre misiones).
- Esta variable puede usarse para asignar su valor a otra variable declarada y evaluarse en estructuras de control (Si, Mientras, Repetir) |
  | `posValle` | `escenario` | - Representa las `Filas` del `Tablero (Mapa)`.
- Es el valor de posición actual del jugador en el eje horizontal (eje X) en el `Mapa`. Tiene como valor mínimo 1 y como valor máximo el límite del tablero definido en el eje X (El cual puede variar entre misiones).
- Esta variable puede usarse para asignar su valor a otra variable declarada y evaluarse en estructuras de control (Si, Mientras, Repetir) |
  | `tengoMoneda` | `inventario` | - Evalúa si se tiene al menos una `moneda` en el `inventario`. Retorna verdadero o falso. |
  | `tengoLlave` | `inventario` | - Evalúa si se tiene al menos una `llave` en el `inventario`. Retorna verdadero o falso. |

## 6.4 Estructuras de control

Las estructuras de control básicas que se podrán utilizar son: Si-Sino, Mientras y Repetir, donde se podrán manejar proposiciones simples o compuestas utilizando operadores lógicos, matemáticos y/o operadores relacionales. Estas estructuras serán representadas como “Habilidades especiales” a modo de gamificación unicamente.

### Emblema del Juicio

Le da el poder al jugador de tomar decisiones complejas evaluando su inventario y/o elementos del mapa.

**Sintaxis**

```gdscript
Si (condición) entonces:
	instruccion1
	instruccion2
	...
	instruccionN
Sino
	instruccion3
	instruccion4
	...
	instruccionM
-- Las instruccioens pueden ser primitivas u otras estructuras.
```

### **Ritual de la Perseverancia**

Le da el poder al jugador de repetir una serie de instrucciones un número finito de veces

**Sintaxis**

```gdscript
Repetir
	instruccion1
	instruccion2
	...
	instruccion3
-- Las instruccioens pueden ser primitivas u otras estructuras.
```

### **Orbe del Ciclo Infinito**

Le da el poder al jugador de ejecutar una serie de instrucciones mientras una condición sea verdadera. Es una poderosa habilidad pero se debe tener cuidado en la elección de la condición, ¡pueden llegar a generarse secuencias infinitas si no se controla correctamente la condición!

**Sintaxis**

```gdscript
Mientras (condición) hacer:
   instruccion1
   instruccion2
   ...
   instruccion3
-- Las instruccioens pueden ser primitivas u otras estructuras.
```

### Lógica proposicional

La lógica proposicional trata sobre la verdad o la falsedad de las proposiciones.

<aside>
💡

_Una proposición es la unidad mínima de significado susceptible de ser verdadera o falsa._

</aside>

Es decir, una proposición es una oración de la cual podemos concluir si la afirmación que nos dice es verdadera o falsa.

### Tipos de proposiciones

Debemos distinguir dos tipos de proposiciones:

- **Proposiciones atómicas**: son aquellas que no se componen de otras proposiciones
- **Proposiciones moleculares**: son aquellas que están compuestas por dos o más proposiciones atómicas unidas por conectivos u operadores lógicos.

### Formulación de las proposiciones

En el juego, podemos construir proposiciones con lo siguiente:

- Primitivas de tipo `sensor`
- `tengoMoneda` y `tengoLlave` de las variables del juego.
- Evaluación o comparación de variables (más adelante)

### Operadores lógicos

Se pueden utilizar los operadores lógicos AND, OR y NOT en las condiciones de las estructuras Si y Mientras.

```gdscript
Si hayMoneda AND ~hayEnemigo entonces: -- El NOT se escribe con el símbolo ~nombreVariable
	tomarMoneda

Mientras ~hayMoneda OR ~hayCofre hacer: -- Mientras no haya moneda o no haya cofre, avanzamos.
	avanzar

Si tengoLlave AND hayCofre entonces:
	abrirCofre

Mientras ~hayPuente hacer:
	avanzar

Si tengoMoneda entonces:
	activarPuente
```

### Operadores relacionales

Se pueden utilizar los operadores relacionales tales como:

- (<) Menor qué
- (>) Mayor qué
- (<=) Menos o igual qué
- (>=) Mayor o igual qué
- (=) Igual qué
- (!=) Distinto qué

```gdscript
-- Ejemplo teniendo un mapa de 25x25
-- Mientras no lleguemos al límite vertical, avanzamos.
Mientras posValle < 25 hacer:
	-- Por qué < 25 y no <= 25? porque si colocamos el =
	-- evaluará que es 25, será verdadero, intentará avanzar y se chocará con el límite
	avanzar

-- Mientras no lleguemos al límite horizontal, avanzamos.
derecha -- Giramos a la derecha para recorrer horizontalmente
Mientras posSendero < 25 hacer:
	avanzar
```

### Combinando operadores lógicos y relacionales

```gdscript
-- Tu misión es recorrer los bordes del mapa hasta encontrar una moneda, si la encuentra, tómala.
Inicio
	-- Recorremos verticalmente (vamos por el sendero 1 hacia arriba, es decir tenemos que ir evaluando los valles)
	Mientras posValle < 25 AND ~hayMoneda hacer:
		avanzar
	-- Si salió por la condición de que ~hayMoneda (Es decir, encontró una moneda, la agarramos)
	Si hayMoneda entonces:
		recogerMoneda

	-- Si no se cumple el Si anterior, significa que llegó al limite y no encontró la moneda.
	-- Giramos a la derecha
	derecha
	-- Seguimos recorriendo pero ahora horizontalmente
	-- Como ahora recorreremos el valle 25, evaluamos los senderos.
	Mientras posSendero < 25 AND ~hayMoneda hacer:
		avanzar
	-- Si salió por la condición de que ~hayMoneda (Es decir, encontró una moneda, la agarramos)
	Si hayMoneda entonces:
		recogerMoneda
	-- Si no se cumple el Si anterior, significa que llegó al limite y no encontró la moneda.
Fin
```

## 6.5 Variables

El jugador podrá declarar, asignar valores y utilizar variables de tipo entero y real de hasta 2 decimales. En el diseño del algoritmo.

**Sintaxis básica**

```gdscript
-- Declarar una varible
var variableEntera: entero
var variableReal: real
var otroEntero: entero
var otroReal: real

Inicio
	-- Asignar valor a una variable
	variableEntera:= 5
	variableReal:= 10.50
	otroEntero:= 15
	otroReal:= 5.50

	-- Asignar el valor de una variable a otra variable. SOLO si las variables son del mismo tipo.
	variableEntera:= otroEntero -- variableEntera ahora vale 15
	variableReal:= otroReal -- variableReal ahora vale 5.50

	-- Asignar el valor de una variable con una operación matemática teniendo como operandos otras variables
	var division: real
	division:= variableEntera / variableReal

	-- Aumentar el valor de una variable
	variableEntera:= variableEntera + 1
	-- O de la forma
	variableEntera++ -- (Solo para aumentar en uno)

	-- Disminuir el valor de una variable
	variableEntera:= variableEntera - 1 -- variableEntera toma el valor de variableEntera (valor actual) menos 1.
	-- O de la forma:
	variableEntera-- -- (Solo para disminuir en uno)
Fin
```

### Reglas entre operaciones matemáticas

Se definen algunas reglas para las operaciones matemáticas, válidas tanto para números como para variables.

**Suma (+)**

| Operando 1 | Operando 2 | Condición del resultado                | Tipo resultante | Ejemplo            |
| ---------- | ---------- | -------------------------------------- | --------------- | ------------------ |
| `entero`   | `entero`   | Siempre                                | `entero`        | 2 + 3 = 5          |
| `entero`   | `real`     | Si la parte decimal del resultado es 0 | `entero`        | 2 + 1.00 = 3       |
| `entero`   | `real`     | Si la parte decimal del resultado ≠ 0  | `real`          | 2 + 1.50 = 3.50    |
| `real`     | `real`     | Si la parte decimal del resultado es 0 | `entero`        | 1.50 + 2.50 = 4    |
| `real`     | `real`     | Si la parte decimal del resultado ≠ 0  | `real`          | 1.50 + 1.10 = 2.60 |

**Resta (-)**

| Operando 1 | Operando 2 | Condición del resultado                | Tipo resultante | Ejemplo            |
| ---------- | ---------- | -------------------------------------- | --------------- | ------------------ |
| `entero`   | `entero`   | Siempre                                | `entero`        | 2 - 3 = -1         |
| `entero`   | `real`     | Si la parte decimal del resultado es 0 | `entero`        | 2 - 1.00 = 1       |
| `entero`   | `real`     | Si la parte decimal del resultado ≠ 0  | `real`          | 2 - 1.50 = 0.5     |
| `real`     | `real`     | Si la parte decimal del resultado es 0 | `entero`        | 1.50 - 2.50 = -1   |
| `real`     | `real`     | Si la parte decimal del resultado ≠ 0  | `real`          | 1.50 - 1.10 = 0.40 |

**Multiplicación (\*)**

| Operando 1 | Operando 2 | Condición del resultado                | Tipo resultante | Ejemplo             |
| ---------- | ---------- | -------------------------------------- | --------------- | ------------------- |
| `entero`   | `entero`   | Siempre                                | `entero`        | 2 \* 3 = 6          |
| `entero`   | `real`     | Si la parte decimal del resultado es 0 | `entero`        | 2 \* 1.00 = 2       |
| `entero`   | `real`     | Si la parte decimal del resultado ≠ 0  | `real`          | 2 \* 1.30 = 2.60    |
| `real`     | `real`     | Si la parte decimal del resultado es 0 | `entero`        | 1.00 \* 2.00 = 2    |
| `real`     | `real`     | Si la parte decimal del resultado ≠ 0  | `real`          | 1.50 \* 1.10 = 1.65 |

**División (/)**

| Operando 1   | Operando 2 | Condición del resultado                | Tipo resultante | Ejemplo           |
| ------------ | ---------- | -------------------------------------- | --------------- | ----------------- |
| `entero`     | `entero`   | Si la división es exacta (resto 0)     | `entero`        | 10 / 2 = 5        |
| `entero`     | `entero`   | Si la división **no** es exacta        | `real`          | 10 / 4 = 2.50     |
| `entero`     | `real`     | Si la parte decimal del resultado es 0 | `entero`        | 10 / 2.0 = 5      |
| `entero`     | `real`     | Si la parte decimal del resultado ≠ 0  | `entero`        | 10 / 2.5 = 4      |
| `real`       | `real`     | Si la parte decimal del resultado es 0 | `real`          | 5.5 / 1.1 = 5     |
| `real`       | `real`     | Si la parte decimal del resultado ≠ 0  | `real`          | 5.5 / 2.0 = 2.75  |
| `cualquiera` | 0          | **Siempre**                            | `ERROR`         | División por cero |

**Módulo (%)**

| Operando 1   | Operando 2   | Condición del resultado | Tipo resultante | Ejemplo           |
| ------------ | ------------ | ----------------------- | --------------- | ----------------- |
| `entero`     | `entero`     | **Siempre**             | `entero`        | 5 % 2 = 1         |
| `entero`     | `real`       | **Siempre**             | `ERROR`         | No compatible     |
| `real`       | `cualquiera` | **Siempre**             | `ERROR`         | No compatible     |
| `cualquiera` | 0            | **Siempre**             | `ERROR`         | División por cero |

## 6.6 Procedimientos

Un procedimiento es una secuencia de instrucciones que realiza una acción específica y que puede reutilizarse cuando se la llama. Los procedimientos pueden recibir parámetros, los cuales se clasifican en dos tipos:

- **Parámetros de entrada**: Son valores que el procedimiento recibe cuando es llamado. Le sirven para trabajar con información específica, sin depender de variables externas. El procedimiento **usa** estos valores, pero no los **modifica** fuera de su ámbito.
- **Parámetros de entrada/salida:** Son valores que el procedimiento recibe, pero que además **puede modificar y devolver cambiados** al finalizar.

### Procedimientos (o funciones) del juego

El juego ofrece algunas funciones o procedimientos para realizar acciones específicas que el jugador no puede realizar por otros medios.

| Función                                                                                   | Descripción                                                                                              | Argumentos                                                                                    | Ejemplo           | Efecto o salida                                                |
| ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ----------------- | -------------------------------------------------------------- |
| mapa(posSendero: entero, posValle: entero)                                                | Realiza un posicionamiento en el cruce del sendero y del valle pasados como argumento.                   | posSendero: variable cuyo valor es un número entero que representa a qué sendero queremos ir. |
| posValle: variable cuyo valor es un número entero que representa a qué valle queremos ir. | mapa(2,3)                                                                                                | El jugador se posiciona en el senero 2 y valle 3.                                             |
| imprimir(var1: any, var2: any, … , varN: any)                                             | Imprime por pantalla (o por algun tipo de salida) el valor de la o las variables pasadas como argumento. | var1..N: variables que almacenan el valor (entero o real) que será impreso por pantalla.      | imprimir(monedas) | Imprime por pantalla el valor actual de la variable “monedas”. |

### Declaración de procedimientos

Un procedimiendo se declara de la siguiente manera utilizando la palabra reservada `proceso`

**Sintaxis**

```gdscript
-- Variables globales
var entero: entero
var otroEntero: entero

-- Declarar un proceso con dos parámetros solo de entrada
-- Para declarar un parámetro de entrada se debe colocar "E" antes del nombre del parámetro
-- Se debe especificar el tipo de dato del parámetro
proceso miProceso(E param1: entero, E param2: entero)
	imprimir(param1)
	imprimir(param2)

-- Declarar un proceso con dos parámetros, uno de entrada y otro de entrada/salida.
-- Para declarar un parámetro de entrada/salida se debe colocar "ES" antes del nombre del parámetro
proceso otroProceso(E param1: entero, ES param2: entero)
	param2:= param1 * param2 -- Modificamos la variable param2

Inicio -- Programa principal
	entero:= 10
	otroEntero:= 20

	-- Llamada al proceso 1
	miProceso(entero, otroEntero) -- Mostrará dos lineas: 10 y 20.

	-- Llamada al proceso 2
	otroProceso(entero, otroEntero)
	imprimir(otroEntero) -- Mostrará 200, porque "otroProceso" modificó la variable "otroEntero"
Fin
```

# 7. Sistema de misiones

### Requerimientos

1. **Complejidad Lógica:** El enunciado puede requerir bifurcaciones (`Si/Sino`), bucles (`Mientras`) y secuencias específicas (`Ir a X, luego buscar Y`).
   - _Ejemplo:_ "Si encuentras moneda -> Haz A. Sino -> Haz B".
   - _Implicación:_ Para evaluar esto, **una sola ejecución no basta**. Si el alumno ejecuta el código y _casualmente_ había una moneda, nunca sabremos si programó bien la parte del "Sino".
2. **Evaluación por Casos de Prueba:** Para decir que la misión está "Aprobada", el código del alumno debe funcionar en **varios escenarios** (Ej: Escenario 1 con moneda, Escenario 2 sin moneda).
3. **Detección de Dificultades (Errores Semánticos):** No basta con que el personaje llegue al final. Si intentó recoger una moneda sin preguntar `si hayMoneda`, eso es un error (SL-02), aunque el juego no crashee. El sistema debe "espiar" la ejecución.

---

### Arquitectura: "Sistema Basado en Casos de Prueba"

Para lograr esto, se propondrá una arquitectura en donde una Misión es un **Conjunto de Escenarios de Validación**.

### 1. Estructura de Datos (`MissionDefinition` y `TestCase`)

Una misión se compone de una configuración general y una lista de casos de prueba que el código del alumno debe superar **con el mismo script**.

```gdscript
class_name MissionDefinition extends Resource

# Info Básica
@export var id: String
@export var titulo: String
@export var enunciado: String # El texto complejo (generado o escrito a mano)
@export var dificultad: int

# --- EL CORAZÓN DE LA EVALUACIÓN ---
# Una lista de escenarios. El código del alumno se ejecutará una vez por cada caso.
# Para aprobar, debe pasar TODOS los casos (o al menos los críticos).
@export var casos_de_prueba: Array[MissionTestCase]
```

Y el `MissionTestCase` define el estado inicial del mundo y qué esperamos que pase:

```gdscript
class_name MissionTestCase extends Resource

# CONFIGURACIÓN DEL MAPA PARA ESTE CASO
# Ej: En el Caso A, ponemos moneda en (0,2). En el Caso B, no ponemos nada.
@export var mapa_config: Dictionary

# CONDICIONES DE VICTORIA (Asserts)
# Qué debe ser cierto al finalizar la ejecución de este caso
@export var condiciones: Array[Condition]

# Ejemplo de condiciones:
# - FinalPositionCondition(Vector2i(5, 5)) -> Debe terminar en 5,5
# - ItemCountCondition("monedas", 1) -> Debe tener 1 moneda
# - OutputContainsCondition("Enemigo encontrado en 2,2") -> Debe haber impreso eso
```

### 2. El Generador de Misiones (Para el Módulo Inteligente)

Para las misiones especiales automáticas, el generador hará lo siguiente:

1. **Elegir Plantilla Lógica:** (Ej: "Búsqueda Condicional").
2. **Generar Enunciado:** "Busca X. Si está, haz Y. Si no, haz Z".
3. **Generar 2 Casos de Prueba (Automáticamente):**
   - _Caso 1 (Happy Path):_ Genera un mapa donde X **sí está**. Define como condición de éxito que ocurra Y.
   - _Caso 2 (Alternative Path):_ Genera un mapa donde X **no está**. Define como condición de éxito que ocurra Z.
4. **Empaquetar:** Crea el `MissionDefinition` con esos 2 casos.

---

### Discusión y Conclusión

Esta arquitectura resuelve el planteamiento de "Misiones Complejas":

1. **Evaluación Justa:** Al usar casos de prueba, se garantiza que el algoritmo del alumno es genérico y robusto (resuelve el problema, no solo el mapa actual).
2. **Misiones Especiales Simples:** El generador simplemente crea una misión con **1 solo Caso de Prueba** (más fácil de generar) y un enunciado directo ("Recolecta todo"). No hace falta que las especiales tengan lógica compleja if/else si no queremos complicar el generador, pero la arquitectura _soporta_ que lo hagamos si quisiéramos.

# 8. Dificultades y cómo detectarlas o evaluarlas

### Redundancia de instrucciones | `Secuencia y Lógica Básica`

El alumno ejecuta dos o más veces la misma instrucción atómica sin necesidad en lugar de usar una estructura de control como Repetir o Mientras.

```gdscript
-- 1. Ejecuta 2 o más veces la misma instrucción
avanzar
avanzar
avanzar
```

### No valida un objeto antes de recogerlo | `Secuencia y Lógica Básica`

El alumno realiza recolección de objetos como recogerMoneda o recogerLlave sin primero validar si ese objeto existe con una estructura Si-Sino con los sensores correspondientes (hayMoneda, hayLlave). Algunos ejemplos:

1. Intenta recoger una moneda sin verificar que exista

Incorrecto:

```gdscript
Inicio
	...
	recogerMoneda
	...
Fin
```

Correcto:

```gdscript
Inicio
	...
	Si hayMoneda entonces:
		recogerMoneda
	...
Fin
```

1. Intenta recoger una llave sin verificar si existe

Incorrecto:

```gdscript
Inicio
	...
	recogerLlave
	...
Fin
```

Correcto

```gdscript
Inicio
	...
	Si hayLlave entonces:
		recogerLlave
	...
Fin
```

### Uso de instrucciones innecesarias | `Secuencia y Lógica Básica`

El alumno realiza acciones específicas fuera de contexto de manera arbitraria, como usar ‘atacar’ sin validar si hay un enemigo o ‘saltar’ sin comprobar si existe un obstáculo. Algunos ejemplos:

1. Uso de “atacar” fuera de su bloque Si correspondiente

Incorrecto:

```gdscript
-- Esto NO afectará a la ejecución del algoritmo, pero ESTA MAL
Inicio
	...
	atacar
	...
Fin
```

Correcto:

```gdscript
Inicio
	...
	Si hayEnemigo entonces:
		atacar
	...
Fin
```

1. Uso de “saltar” fuera de su bloque Si correspondiente

Incorrecto:

```gdscript
-- Esto NO afectará a la ejecución del algoritmo, pero ESTA MAL
Inicio
	...
	saltar
	...
Fin
```

Correcto:

```gdscript
Inicio
	...
	Si hayObstaculo entonces:
		saltar
	...
Fin
```

### **Mal uso o confusión con operadores lógicos | `Lógica Proposicional`**

El alumno posee problemas para formular condiciones compuestas con AND, OR, NOT, como usar OR en lugar de AND, AND en lugar de OR o utilizar la negación NOT en lugar incorrecto. Algunos ejemplos:

1. Para abrir un cofre

Incorrecto:

```gdscript
Inicio
	...
	Si hayCofre OR tengoLlave entonces:
		abrirCofre
	...
Fin
```

Correcto:

```gdscript
Inicio
	...
	Si hayCofre AND tengoLlave entonces: -- Las dos deben cumplirse para abrir el cofre.
		abrirCofre
	...
Fin
```

1. Para activar un puente

Incorrecto:

```gdscript
Inicio
	...
	Si hayPuente OR tengoMoneda entonces:
		activarPuente
	...
Fin
```

Correcto:

```gdscript
Inicio
	...
	Si hayPuente AND tengoMoneda entonces: -- Las dos deben cumplirse para activar el puente
		activarPuente
	...
Fin
```

### Mal uso o confusión con operadores relacionales | `Lógica Proposicional`

El alumno posee problemas usando <, >, <=, >=, =, !=. Comparaciones imposibles, comparadores duplicados o confusión entre = y !=. Básicamente cuando el enunciado pida, por ejemplo, que algo sea menor qué y se coloca cualquier otra cosa, suma error. Algunos ejemplos

1. Supongamos un mapa 25x25. Recorrer todo el sendero 1 hasta el final.

Incorrecto

```gdscript
Inicio
	...
	Mientras posValle > 25 hacer: -- Nunca se ejecuta. Condición imposible
		avanzar
	...
Fin

-- /////////////////////////// --

Inicio
	...
	Mientras posValle <= 25 hacer: -- Va a chocar con el límite del mapa porque estando en el valle 25 avanza una vez más.
		avanzar
	...
Fin
```

Correcto

```gdscript
Inicio
	...
	Mientras posValle < 25 hacer:
		avanzar
	...
Fin

-- /////////////////////////// --

Inicio
	...
	Mientras posValle != 25 hacer:
		avanzar
	...
Fin
```

### Problemas para formular proposiciones compuestas | `Lógica Proposicional`

Esta es una dificultad generalizada. Se calcula a partir de LP-01 y LP-02. No se detecta por casos de prueba individuales. No se detecta por casos de prueba individuales, sino que esta dificultad nace de tener dificultades en las dos anteriores.

### Bucle mal controlado o infinito | `Estructuras de Control`

El alumno escribe un bucle cuya condición nunca cambia, es imposible o es siempre verdadera generando un bucle infinito o nunca ejecutado. Algunos ejemplos:

1. Supongamos un mapa NxN (25x25, 50x50, 75x75, 100x100). Recorrer todo el sendero 1 hasta el final.

Incorrecto:

```gdscript
Mientras posValle >, >=, = N hacer: -- Nunca se ejecuta. Condiciones imposibles
	avanzar

-- /////////////////////////// --

Mientras posValle <= N hacer: -- Chocará con los límites del mapa al avanzar una vez más al estar en el valle N.
	avanzar

-- /////////////////////////// --

Mientras posSendero <, <=, != N hacer: -- Siempre verdadero. Bucle infinito. Mal controlado por confusión con posValle
	avanzar

-- /////////////////////////// --

Mientras posSendero >, >=, = N hacer: -- Nunca se ejecuta. Condiciones imposibles. Mal controlado por confusión con posValle
	avanzar

-- /////////////////////////// --

Repetir N -- Repetir mal controlado respecto a los límites del mapa
	avanzar
```

Correcto

```gdscript
Mientras posValle < N hacer: -- Nos quedamos justo en el cruce N.
	avanzar

-- /////////////////////////// --

Mientras posValle != N hacer: -- Nos quedamos justo en el cruce N.
	avanzar

-- /////////////////////////// --

Mientras posValle <= N hacer: -- Si queremos realizar cierta acción en todas las casillas incluida la N, podemos hacer una validación extra
	Si posValle != N entonces:
		avanzar -- Avanzamos solamente si no es la casilla N (límite)
	... -- Otras instrucciones / validaciones que querramos hacer en la casilla N también.
```

1. Recorrer todo el valle 1 hasta el final

Incorrecto

```gdscript
Mientras posSendero >, >=, = N hacer: -- Nunca se ejecuta. Condiciones imposibles.
Mientras posSendero <= N hacer: -- Chocará con los límites del mapa al avanzar una vez más al estar en el sendero N.
Mientras posValle <, <=, != N hacer: -- Siempre verdadero. Bucle infinito. Mal controlado por confusión con posSendero
Mientras posSendero >, >=, = N hacer: -- Nunca se ejecuta. Condiciones imposibles. Mal controlado por confusión con posValle
Repetir N -- Repetir mal controlado respecto a los límites del mapa
```

Correcto

```gdscript
Mientras posSendero < N hacer: -- Nos quedamos justo en el cruce N.
	avanzar

-- /////////////////////////// --

Mientras posSendero != N hacer: -- Nos quedamos justo en el cruce N.
	avanzar

-- /////////////////////////// --

-- Si queremos realizar cierta acción en todas las casillas incluida la N, podemos usar un contador.

var contador: entero
contador:= posSendero
Mientras contador <= N hacer: -- Evaluamos contador y no posSendero (para evitar el bucle infinito)
	... -- Otras instrucciones que querramos hacer en la casilla N también.
	Si posSendero != N entonces:
		avanzar -- Avanzamos solamente si no es la casilla N (límite)
	contador++

```

### Uso incorrecto del bloque SI–SINO | `Estructuras de Control`

El alumno construye mal una estructura condicional, generando acciones redundantes, incoherentes o innecesarias dentro del bloque SI–SINO, como un bloque instrucciones escritas tanto en el SI como en el SINO o se tiene un SINO vacío. Algunos ejemplos

1. Repite instrucciones tanto en el Si y el Sino

Incorrecto:

```gdscript
Si hayMoneda entonces:
	recogerMoneda
	avanzar
Sino
	avanzar
```

Correcto:

```gdscript
Si hayMoneda entonces:
	recogerMoneda
avanzar
-- No hace falta bloque SINO, porque avanzar se ejecuta de todas formas.
```

1. Usa un Si-Sino cuando debería usar un Mientras o Repetir

Incorrecto:

```gdscript
Si ~hayEnemigo AND ~hayObstaculo entonces:
	avanzar
-- Esto estaría bien dentro de un bloque Mientras o Repetir, pero no por si solo o "al aire", porque solo se ejecutaría una vez.
```

Correcto:

```gdscript
Mientras ~hayEnemigo AND ~hayObstaculo hacer:
	avanzar
```

### Condicionales mal anidados | `Estructuras de Control`

El alumno utiliza condicionales dentro de otros condicionales de forma innecesaria, confusa o incorrecta, cuando debería combinar proposiciones atómicas usando AND/OR para generar una proposición compuesta y reorganizar la estructura. Algunos ejemplos:

1. Supongamos un mapa de NxN. Recorrer todo el sendero 1 atacando a los enemigos y saltando los obstáculos.

Incorrecto:

```gdscript
Mientras posValle < N hacer:
	Si ~hayEnemigo entonces:
		Si ~hayObstaculo entonces:
				avanzar
		Sino
			saltar
	Sino
		atacar
```

Correcto:

```gdscript
Mientras posValle < N hacer:
	Si ~hayEnemigo AND ~hayObstaculo entonces:
		avanzar
	Si hayEnemigo entonces:
		atacar
	Si hayObstaculo entonces:
		saltar
```

1. Supongamos un mapa de NxN. Recorrer todo el sendero 1 juntanto las moendas y llaves en el camino.

Incorrecto

```gdscript
Mientras posValle < N hacer:
	Si ~hayMoneda entonces:
		Si ~hayLlave entonces:
				avanzar
		Sino
			recogerLlave
	Sino
		recogerMoneda
-- Qué pasa con la última casilla? tambien debemos verificar la casilla N pero posValle al estar con valor N no entra en el bucle.
-- Fuera del mientras tendríamos que volver a validar cada cosa
Si hayMoneda entonces:
	recogerMoneda
Si hayLlave entonces:
	recogerLlave
```

Correcto

```gdscript
-- Como podemos solucionar esto? con un contador y evaluandolo en el mientras (más avanzado)
-- Mejoramos la anidación y además solucionamos el problema de evaluar la última casilla también.
var contador: entero

Inicio
	contador:= posValle -- Valor inicial igual al valor del valle actual.
	Mientras contador <= N hacer: -- Ahora que evaluamos el contador, podríamos entrar en el bucle estando en la casilla N también.
		Si hayMoneda entonces:
			recogerMoneda
		Si hayLlave entonces:
			recogerLlave
		Si posValle != N entonces:
			avanzar -- Avanzamos solamente si no es la casilla N (límite)
		contador++ -- Aumentamos el contador.
Fin
```

### Confusión entre variables locales y globales | `Variables`

El alumno realiza redefiniciones indebidas, uso de una variable fuera de su bloque o pérdida de valores. Algunos ejemplos:

1. Quiere usar una variable local (definida en una estructura de control, procedimiento, etc,) fuera de su bloque.

Supongamos un mapa de NxN. Recorrer todo el sendero 1 juntando todas las monedas que haya y al final del sendero informar cuantas monedas juntó.

Incorrecto

```gdscript
Inicio
	Mientras posValle < N hacer:
		var monedas: entero -- Redefine cada vez que entra en el loop.
		Si hayMoneda entonces:
			recogerMoneda
			monedas:= monedas + 1
		avanzar
	imprimir(monedas) -- ERROR, no existe la variable monedas en el contexto actual
Fin
```

Correcto

```gdscript
var monedas: entero -- definir una variable global para utilizarla en todo el programa.
var contador: entero -- definir una variable global para el recorrido.

Inicio
	Mientras contador <= N hacer:
		Si hayMoneda entonces:
			recogerMoneda
			monedas:= monedas + 1
		Si posValle != N entonces:
			avanzar
		contador:= contador + 1
	imprimir(monedas)
Fin
```

### Uso de variables sin inicializar | `Variables`

El alumno utiliza una variable en algún proceso de calculo o decisión sin antes asignarle un valor a dicha variable (está evaluando un null). Ejemplo:

Incorrecto

```gdscript
var variable: entero

Inicio
	Mientras variable < 25 hacer: -- Error, está queriendo evaluar un NULL
		avanzar
	imprimir(variable) -- Técnicamente funciona, pero imprimirá un NULL
Fin
```

Correcto

```gdscript
var variable: entero

Inicio
	variable:= 1
	Mientras variable < 25 hacer: -- Error, está queriendo evaluar un NULL
		avanzar
		variable++
	imprimir(variable) -- Técnicamente funciona, pero imprimirá un NULL
Fin
```

### Uso inconsistente de variables | `Variables`

El alumno declara variables pero no las utiliza o las utiliza de manera que no aportan ningún efecto al algoritmo, como asignar valores que nunca son leídos, crear variables que nunca participan del proceso de decisión o cálculo o esa variable nunca cambia de valor (almacena un dato constante). Algunos ejemplos

Incorrecto

```gdscript
var miEntero: entero -- Declara
var miReal: real  -- Declara
var noOcupo: entero -- Solo declara, no utiliza

Inicio
	miEntero:= 1 -- Asigna pero nunca lee o cambia el valor
	miReal:= 10 -- Asigna

	Repetir miReal: -- Ocupa en un repetir, pero nunca cambia de valor. Hubiera hecho Repetir 10 y sería el mismo efecto.
		avanzar

Fin
```

Correcto

```gdscript
var miEntero: entero
var miReal: entero
var division: entero
-- var noOcupo: entero -> si no ocupo, no declaro.

Inicio
	miEntero:= 1
	miReal:= 10.0

	Mientras miEntero < miReal hacer:
		avanzar
		miEntero++ -- o miEntero:= miEntero + 1
	division:= miEntero / miReal
	imprimir(division) -- Imprime 1, porque son valores iguales.
Fin
```

### Mal pasaje de parámetros | `Procedimientos`

El alumno llama un procedimiento pasándole más o menos parámetros de los definidos en el procedimiento, o pasa parámetros incompatibles con el tipo de dato esperado. Ejemplos

Incorrecto

```gdscript
proceso sumar(E entero1: entero, E entero2: entero)
	var suma: entero
	suma:= entero1 + entero2
	imprimir(suma)

var unEntero: entero
var dosEntero: entero
var unReal: real
var sumaEntero: entero

Inicio
	unEntero:= 10
	dosEntero:= 10
	unReal:= 25.25
	sumar(unEntero, dosEntero, sumaEntero) -- Error, pasa un parámetro de más.
	sumar(unEntero) -- Error, pasa un parámetro menos.
	sumar(unEntero, unReal) -- Error, pasa los dos parámetros pero uno es un real.
Fin
```

### No modificar un parámetro de entrada/salida | `Procedimientos`

El alumno declara un parámetro como E/S pero éste nunca se modifica dentro del cuerpo del procedimiento. Ejemplo:

Incorrecto

```gdscript
proceso sumar(E entero1: entero, E entero2: entero, ES suma: entero)
	var sumar: entero -- Declara una variable en lugar de usar la de ES
	sumar:= entero1 + entero2
	imprimir(sumar) -- Imprime otra variable en lugar de usar la de ES
```

Correcto

```gdscript
var suma: entero
var num1: entero
var num2: entero

proceso sumar(E entero1: entero, E entero2: entero, ES sumar: entero)
	sumar:= entero1 + entero2 -- Usamos la variable de ES

Inicio
	num1:= 10
	num2:= 20
	suma:= 0
	sumar(num1, num2, suma)
	imprimir(suma) -- Imprime 30
Fin
```

### No utilizar todos los parámetros del procedimiento | `Procedimientos`

El alumno declara un procedimiento con parámetros, pero alguno de ellos (o todos) nunca son usados dentro del cuerpo del procedimiento. Ejemplos

Incorrecto

```gdscript
var numero1: entero
var numero2: entero

proceso imprimirNumeros(E num1: entero, E num2: entero)
	imprimir(num1) -- Solo usa un parámetro

Inicio
	numero1:= 10
	numero2:= 20
	imprimirNumeros(numero1, numero2) -- Por más que le pasemos los dos parámetros, la definición del mismo está mal
Fin
```

Correcto

```gdscript
var numero1: entero
var numero2: entero

proceso imprimirNumeros(E num1: entero, E num2: entero)
	imprimir(num1, num2) -- Usamos todos los parámetros

Inicio
	numero1:= 10
	numero2:= 20
	imprimirNumeros(numero1, numero2) -- Le pasamos los dos parámetros y funcionará bien.
Fin
```

## 8.1 Detector de Dificultades

Para detectar errores como **SL-02 (No validar antes de recoger)** o **SL-01 (Redundancia)**, necesitamos un **Analista de Ejecución** que monitoree en tiempo real.

Podemos implementarlo dentro de `JugadorGrid` o `EjecutorAlgoritmo`.

- **¿Cómo funciona?**
  - Cada vez que el código ejecuta `Si hayMoneda`, el "Espía" registra: `ultimo_chequeo = "moneda"`, `timestamp = ahora`.
  - Cada vez que el código ejecuta `recogerMoneda`, el "Espía" verifica: `¿Hizo un chequeo de moneda recientemente?`. Si no -> **Registrar Error SL-02**.

Al tener un "Espía" separado de la lógica de misión, podemos detectar las dificultades en cualquier misión (normal o especial) sin escribir código extra para cada una.

# 9. Elementos del juego

## 9.1 Personaje principal

El personaje principal será el heroe o heroína que inicia su aventura para encontrar el _Algorismus Resolutor._ Puede realizar las siguientes acciones:

- Avanzar
- Saltar
- Atacar
- Recoger y usar monedas y llaves
- Abrir cofres
- Evaluar el entorno o inventario

Puede morir (perder el intento en la misión) en las siguientes situaciones

1. Si hay un enemigo en la casilla siguiente a la posición actual del jugador y la dirección actual del jugador está apuntando hacia la posición del enemigo y, además, el jugador intenta realizar cualquier otra acción que no sea atacar (para derrotar al enemigo) éste lo atacará primero y perderá el intento. Esto ocurre solamente si el jugador tiene su dirección actual viendo hacia la casilla donde está el enemigo. El jugador no morirá si, por ejemplo, está viendo hacia la derecha y el enemigo está en la casilla de arriba.
2. Si hay un obstáculo en la casilla siguiente a la posición actual del jugador y la dirección actual del jugador está apuntando hacia la posición del obstáculo y, además, el jugador intenta avanzar, éste chocará/caerá/etc contra el obstáculo y perderá el intento.
3. Si el jugador se encuentra en el límite del sendero (dependiendo de la configuración del mapa y de la misión) y mirando hacia arriba, si el jugador intenta avanzar o saltar, éste chocará con el límite vertical superior del mapa y perderá el intento.
4. Si el jugador se encuentra en el inicio del sendero y mirando hacia abajo, si el jugador intenta avanzar o saltar, este chocará con el límite vertical inferior del mapa y perderá el intento.
5. Si el jugador se encuentra en el límite del valle (dependiendo de la configuración del mapa y de la misión) y mirando hacia la derecha, si el jugador intenta avanzar o saltar, éste chocará con el límite horizontal superior del mapa y perderá el intento.
6. Si el jugador se encuentra en el inicio del valle y mirando hacia la izquierda, si el jugador intenta avanzar o saltar, este chocará con el límite horizontal inferior del mapa y perderá el intento.

## 9.2 Monedas, llaves y cofres

Las monedas, llaves y cofres estarán esparcidos por el mapa de misión de manera aleatoria según lo requiera el enunciado de la misión. Es decir, por ejemplo, un enunciado que solo pida recolectar monedas no deberían por qué aparecer llaves o cofres. Lo mismo por si el enunciado pide que recolecte llaves y habra todos los cofres que encuentre si se pueden, no debería porque haber monedas. Esto para evitar que el jugador tenga que controlar o añadir bloques innecesarios donde el problema no lo requiera.

- Recolectar una moneda sumará 1 a las monedas totales del jugador.
- Recolectar una llave sumará 1 a las llaves totales del jugador.
- Abrir un cofre sumará 5 monedas a las monedas totales del jugador.

## 9.3 Enemigos

Los enemigos estarán esparcidos por el mapa de misión de manera aleatoria según lo requiera el enunciado de la misión. Es decir, la existencia de los mismos en la misión dependerá del enunciado. Para evitar que, por ejemplo, en un enunciado donde solo se tenga que contar monedas, no se tenga que controlar explícitamente si existe o no enemigo para atacar y no perder.

Los enemigos se comportarán de manera estática, es decir, una vez posicionados en el mapa, se quedarán allí a la espera de que un jugador esté en la casilla de enfrente para poder atacarlo (solamente si el jugador está viendo hacia la casilla del enemigo y está inmediatamente frente a el).

### Enemigos del juego

**Bugs**

Pequeños insectos mágicos que representan “errores simples” que aparecen cuando uno programa sin pensar. No son muy peligrosos, pero molestan constantemente al guerrero algorítmico.

**Overflow Golems**

Golems hechos de bloques numéricos y símbolos, que tiemblan como si estuvieran “a punto de explotar”. Representan los errores en cálculos, límites, comparaciones y desbordes.

**Algoritmo Corrupto**

Una figura formada por **fragmentos de pseudocódigo rotos flotando** y girando sin un orden.

## 9.4 Obstáculos

Los obstáculos estarán esparcidos por el mapa de misión de manera aleatoria según lo requiera el enunciado de la misión. Es decir, la existencia de los mismos en la misión dependerá del enunciado. Para evitar que, por ejemplo, en un enunciado donde solo se tenga que contar monedas, no se tenga que controlar explícitamente si existe o no obstáculo para saltar y no perder.

### Obstáculos del juego

**Fosa del Ciclo Infinito**

Fosa con efectos circulares en el fondo, girando como espirales. Representan el mal uso de bucles: ciclos infinitos o repeticiones incorrectas. Al caer, es como que el jugador entrar en un bucle infinito donde no puede salir, entonces pierde.

**Raíz Enredante**

Una raíz viva, formada por patrones fractales. No bloquea del todo el camino, pero es un estorbo que requiere un salto para evitar quedar atrapado.

**Bloque “Null”**

Representa un valor nulo, un lugar vacío donde el algoritmo no puede operar. Si el jugador intenta avanzar hacia un Null, es “un espacio no definido”, por lo que debe saltarlo para pasar al siguiente cruce válido.

## 9.5 Puentes

Los puentes estarán esparcidos por el mapa de misión de manera aleatoria según lo requiera el enunciado de la misión. Es decir, la existencia de los mismos en la misión dependerá del enunciado. Para evitar que, por ejemplo, en un enunciado donde solo se tenga que contar monedas, no se tenga que controlar explícitamente si existe o no puente para activarlo y no perder por no poder avanzar.

- Abrir un puente desbloqueará el paso y quedara disponible para avanzar.
