# Etapa 3 — Justificación de las preguntas propias

## Punto de partida

La pregunta del proyecto es en qué equipo invertiríamos para la temporada
2021/2022. Nuestra posición como grupo es que ninguna métrica aislada puede
sustentar esa decisión.

Un equipo que gana mucho puede estar gastando de más y sin margen para
sostenerlo. Un equipo barato puede ser barato porque es malo. Un equipo en
ascenso puede venir de tan abajo que su mejora no signifique nada. Por eso
definimos tres condiciones que deben cumplirse **simultáneamente**:

1. **Rendimiento sostenido.** Gana de forma consistente y con un piso alto.
2. **Valor por el dinero.** Convierte nómina en victorias con eficiencia y
   conserva margen financiero.
3. **Crecimiento.** Su trayectoria apunta hacia arriba y tiene talento joven.

Las trece consultas responden a estas tres dimensiones y convergen en un
índice compuesto que produce la recomendación.

E3.5 y E3.6 funcionan como controles cualitativos de oportunidad y riesgo. El
componente cuantitativo de valor dentro del índice utiliza victorias por millón
para evitar contar dos veces información relacionada con la misma nómina.

---

## Dimensión 1 — Rendimiento sostenido

### E3.1 Consistencia con piso alto

**Por qué.** La primera versión de esta pregunta ordenaba por desviación
estándar del porcentaje de victorias. El resultado colocaba a Sacramento en
el segundo lugar con 39.8% de victorias promedio: un equipo consistentemente
malo. La consistencia por sí sola no es una virtud; solo importa acompañada
de rendimiento.

**Qué hicimos.** Exigimos un piso mínimo de 40% de victorias en la peor de
las seis temporadas y ordenamos por rendimiento promedio, reportando la
variabilidad como información complementaria.

**Qué encontramos.** Solo nueve de treinta equipos superan el filtro. Utah
tiene el piso más alto de todos, con 48.8% de victorias en su peor
temporada, y a la vez la segunda variabilidad más baja. Boston y los
Clippers tienen mejor promedio, pero cayeron más bajo en sus peores años.

---

### E3.2 Diferencial de puntos frente al récord

**Por qué.** El porcentaje de victorias es ruidoso: un equipo puede acumular
triunfos ajustados por suerte o perder muchos partidos cerrados. El
diferencial de puntos por partido es una medida más estable del nivel real
de un equipo, y por eso comparamos su posición en ambos rankings.

**Qué encontramos.** Utah aparece tercero en margen de puntos con +4.45 pero
séptimo en victorias, una brecha de cuatro posiciones a su favor. Su récord
subestima su nivel real. San Antonio y Oklahoma City muestran el patrón
contrario: ganaron más de lo que su juego sugería.

---

### E3.3 Ventaja de local

**Por qué.** Esta pregunta introduce la dimensión comercial, que es la que
más directamente conecta con una decisión de inversión. Un equipo que gana
notoriamente más en casa sostiene mejor la asistencia, la venta de boletos y
el valor de los patrocinios locales.

**Qué encontramos.** Philadelphia lidera con 24.7 puntos porcentuales de
diferencia entre local y visitante. San Antonio destaca por magnitud
absoluta: gana el 72.2% de sus partidos en casa. Utah aparece sexta, pero
con el detalle relevante de que también gana más de la mitad de sus partidos
como visitante, algo que solo tres equipos de la lista logran.

---

## Dimensión 2 — Valor por el dinero

### E3.4 Victorias por millón de dólares

**Por qué.** Es la medida más directa de eficiencia del gasto. Dos equipos
con 47 victorias no valen lo mismo si uno las consiguió con 30 millones
menos de nómina.

**Qué encontramos.** Nueva York encabeza con 0.420 victorias por millón, pero
con solo 41 victorias: es eficiente porque gasta poco, no porque gane mucho.
Phoenix y Utah aparecen segundo y cuarto, ambos con 47 victorias, que es el
mejor registro de la lista. Philadelphia ganó más partidos que nadie, 49,
pero con la tercera nómina más alta de la liga.

---

### E3.5 Talento por encima de lo que la nómina sugiere

**Por qué.** Si un equipo tiene mejores jugadores de los que su gasto
indicaría, significa que obtuvo talento por debajo del precio de mercado. Ese
es el perfil clásico de una buena inversión.

Usamos PIE como medida de valor del jugador porque
`all_star_appearances` solo tiene dato para 3 de los 523 jugadores con
salario registrado en 2020-21, lo que la vuelve inservible.

**Qué encontramos.** Dallas presenta la mayor brecha de la liga: puesto 23 en
nómina y puesto 6 en talento, diecisiete posiciones a su favor. Es el efecto
directo de tener a Luka Doncic con contrato de novato. Denver le sigue con
quince posiciones, con Nikola Jokic y la decimoséptima nómina.

Este resultado matiza la conclusión de la pregunta 4 de la Etapa 2: la
correlación entre nómina y talento es positiva pero moderada (+0.48), y las
excepciones son precisamente donde está la oportunidad.

---

### E3.6 Margen financiero hacia adelante

**Por qué.** Un equipo bueno pero con la nómina comprometida al máximo tiene
poca capacidad de reforzarse. El porcentaje de salario ya comprometido para
2021-22 mide cuánto espacio le queda bajo el tope salarial.

**Qué encontramos.** San Antonio y Nueva York tienen menos de la mitad de su
nómina comprometida, es decir, máxima flexibilidad. Utah y Milwaukee no
aparecen entre los doce con más margen: ambos tienen su núcleo bajo contrato
a largo plazo.

Esto es un argumento en contra de nuestra recomendación y lo presentamos como
tal. La lectura alternativa es que un núcleo asegurado también significa
continuidad y menor riesgo de perder jugadores clave.

---

## Dimensión 3 — Crecimiento y talento joven

### E3.7 Trayectoria ascendente

**Por qué.** Comparar únicamente la primera contra la última temporada
confunde un repunte puntual con una mejora sostenida. Usamos la pendiente de
una regresión lineal sobre las seis temporadas, que considera todos los
puntos y no solo los extremos.

**Qué encontramos.** Philadelphia tiene la pendiente más pronunciada, seguida
de los Lakers y Brooklyn. Utah tiene una pendiente positiva pero modesta,
porque partía de un nivel ya alto: es más difícil mejorar desde 59% de
victorias que desde 30%.

---

### E3.8 Calidad del roster actual

**Por qué.** Las tres consultas anteriores miran al pasado. Esta evalúa el
plantel con el que el equipo efectivamente jugó 2020-21, usando estadísticas
reales de la temporada obtenidas del API de la NBA en lugar de promedios de
carrera.

**Qué encontramos.** Atlanta, Toronto y Houston tienen cinco jugadores con 15
o más puntos por partido. Utah tiene cuatro, pero con la mejor rotación de
las primeras posiciones: once jugadores con 40 o más partidos disputados, lo
que indica profundidad y no dependencia de un quinteto corto.

---

### E3.9 Producción combinada del núcleo

**Por qué.** Sumamos puntos, asistencias y rebotes de los cinco jugadores más
productivos de cada equipo. Un núcleo fuerte y balanceado sostiene el
rendimiento mejor que una estrella rodeada de suplentes.

**Qué encontramos.** Brooklyn lidera con amplio margen, resultado de haber
concentrado tres estrellas. Utah aparece octava, lo que confirma que su
fortaleza no está en la producción bruta de su núcleo sino en la
distribución del esfuerzo.

---

### E3.10 Construcción mediante el draft

**Por qué.** El talento formado en el draft cuesta considerablemente menos que
el fichado en agencia libre, porque los contratos de novato están limitados
por convenio. Un buen historial de draft es una ventaja financiera
sostenida en el tiempo.

**Nota metodológica.** La tabla registra al equipo que hizo la selección, no
al equipo donde el jugador terminó jugando. Luka Doncic aparece asociado a
Atlanta porque los Hawks lo eligieron en el tercer puesto y lo traspasaron a
Dallas esa misma noche a cambio de Trae Young.

**Qué encontramos.** Philadelphia tiene siete selecciones de primera ronda
entre 2016 y 2020 que ya producen, muy por encima del resto. Denver y Atlanta
tienen cuatro, pero con promedios de anotación mucho más altos: cantidad
frente a calidad.

---

### E3.11 Dependencia de una sola figura

**Por qué.** Un equipo cuya producción se concentra en un jugador es frágil:
una lesión hunde la temporada completa. Esta consulta funciona como control
de riesgo sobre las anteriores.

**Qué encontramos.** Orlando, Miami y Charlotte son los menos dependientes,
aunque en varios casos porque simplemente no tienen una figura dominante.
Utah no aparece entre los doce menos dependientes, lo que indica una
concentración algo mayor de lo ideal.

---

## Consolidación

### E3.12 Índice compuesto de inversión

**Por qué normalizar.** Las métricas están en escalas incompatibles: un
margen de 4.45 puntos y una eficiencia de 0.345 victorias por millón no se
pueden sumar directamente. Usamos `PERCENT_RANK`, que convierte cada valor en
una posición relativa entre 0 y 1 dentro de la liga.

**Ponderaciones y su razón:**

| Dimensión | Peso | Razón |
|---|---|---|
| Rendimiento | 40% | Es la base. Sin ganar no hay negocio. Se reparte en 50% récord, 30% margen, 20% piso. |
| Valor | 35% | Distingue al equipo bien gestionado del que solo compra resultados. |
| Crecimiento | 25% | Se invierte para el futuro, pero pesa menos porque es la dimensión más incierta. |

**Resultado.** Utah Jazz encabeza con 0.8483, seguido de Milwaukee (0.8279) y
Denver (0.7983).

Lo relevante es *cómo* gana: Utah no es primero en ninguna consulta
individual, pero está en el grupo alto de las tres dimensiones a la vez.
Tiene el mejor margen de puntos entre los equipos que superan el filtro de
piso, la cuarta mejor eficiencia de gasto y una tendencia positiva.

---

### E3.13 Análisis de sensibilidad

**Por qué.** La crítica evidente a cualquier índice compuesto es que las
ponderaciones se eligieron para producir el resultado deseado. Esta consulta
se adelanta a esa objeción comparando el esquema mixto con tres esquemas
alternativos.

**Qué encontramos.** Utah queda primero con el esquema mixto, primero
priorizando rendimiento y primero priorizando valor. Solo desciende al cuarto
lugar cuando el crecimiento pesa 60%, donde Philadelphia toma la delantera.

La conclusión es robusta: no depende de los pesos elegidos.

---

## Recomendación

**Utah Jazz.**

El argumento en una línea: es el equipo que mejor combina un rendimiento
sostenido con piso alto, eficiencia de gasto y una tendencia positiva, y su
posición no depende de cómo se ponderen esas tres cosas.

**Los riesgos que reconocemos:**

- Tiene poco margen financiero: su nómina está comprometida a largo plazo.
- No está entre los equipos menos dependientes de una figura individual.
- Su crecimiento es el más modesto de los cuatro primeros del índice, porque
  partía de un nivel ya alto.

**La alternativa de mayor riesgo y mayor recompensa** sería Philadelphia:
primera en crecimiento, primera en construcción vía draft y con el mejor
jugador de la liga por PIE, pero con diferencial de puntos negativo en las
seis temporadas y una caída al 12.2% de victorias en su peor año. El
contraste entre ambos perfiles es, en sí mismo, la respuesta a la pregunta de
negocio: define qué tipo de inversionista se es.
