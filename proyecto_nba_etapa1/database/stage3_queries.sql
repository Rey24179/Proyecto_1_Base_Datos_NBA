/* ===================================================================
   ETAPA 3 - Preguntas propias
   CC3088 Base de Datos 1 - Proyecto 1

   PREGUNTA DE NEGOCIO
   ¿En qué equipo invertiríamos para la temporada 2021/2022?

   TESIS DEL GRUPO
   Un equipo atractivo para invertir debe cumplir tres condiciones a la
   vez. Ninguna basta por sí sola:

     1. RENDIMIENTO SOSTENIDO. Gana de forma consistente y con un piso
        alto, no por un pico aislado.
     2. VALOR POR EL DINERO. Convierte nómina en victorias de forma
        eficiente y tiene margen financiero hacia adelante.
     3. CRECIMIENTO. Su trayectoria apunta hacia arriba y tiene talento
        joven bajo contrato.

   Cada consulta responde a una de las tres dimensiones y alimenta el
   índice compuesto del final (E3.12), que consolida las tres y produce
   la recomendación.

   PREREQUISITO: la vista analysis_team_season debe existir.
   =================================================================== */

DROP VIEW IF EXISTS analysis_team_season CASCADE;
CREATE VIEW analysis_team_season AS
WITH resultados AS (
    SELECT season_id, home_team_id AS team_id, home_points AS favor,
           away_points AS contra, (home_result = 'W')::int AS win
    FROM game
    UNION ALL
    SELECT season_id, away_team_id, away_points, home_points,
           (away_result = 'W')::int
    FROM game
)
SELECT season_id,
       team_id,
       COUNT(*)                            AS partidos,
       SUM(win)                            AS victorias,
       COUNT(*) - SUM(win)                 AS derrotas,
       SUM(win)::numeric / COUNT(*)        AS pct,
       AVG(favor - contra)::numeric        AS margen,
       AVG(favor)::numeric                 AS puntos_favor,
       AVG(contra)::numeric                AS puntos_contra
FROM resultados
GROUP BY season_id, team_id;


/* ===================================================================
   DIMENSIÓN 1 - RENDIMIENTO SOSTENIDO
   =================================================================== */

/* E3.1 ¿Qué equipos ganan de forma consistente Y con un piso alto?

   Ordenar solo por variabilidad premia a los equipos consistentemente
   malos: Sacramento tiene baja desviación estándar con 39.8% de
   victorias promedio. Por eso se exige un piso mínimo de 40% en la peor
   de las seis temporadas, y se ordena por rendimiento promedio.

   Técnicas: JOIN, GROUP BY, HAVING, funciones de agregación.
*/
SELECT t.abbreviation AS equipo,
       t.full_name,
       ROUND(AVG(a.pct), 4)          AS pct_promedio,
       ROUND(MIN(a.pct), 4)          AS piso_peor_temporada,
       ROUND(STDDEV_SAMP(a.pct), 4)  AS variabilidad,
       ROUND(AVG(a.margen), 2)       AS margen_promedio
FROM analysis_team_season a
JOIN team t ON t.team_id = a.team_id
WHERE LEFT(a.season_id, 4)::int BETWEEN 2015 AND 2020
GROUP BY t.team_id, t.abbreviation, t.full_name
HAVING COUNT(*) = 6 AND MIN(a.pct) >= 0.400
ORDER BY pct_promedio DESC;


/* E3.2 ¿Quién domina en diferencial de puntos y no solo en victorias?

   El margen de puntos predice el rendimiento futuro mejor que el
   récord, porque un equipo puede acumular victorias ajustadas por
   suerte. Se compara ambas medidas para detectar equipos cuyo récord
   sobreestima o subestima su nivel real.

   Técnicas: JOIN, GROUP BY, funciones ventana.
*/
SELECT t.abbreviation AS equipo,
       ROUND(AVG(a.margen), 2) AS margen_promedio,
       RANK() OVER (ORDER BY AVG(a.margen) DESC) AS rank_margen,
       ROUND(AVG(a.pct), 4)    AS pct_promedio,
       RANK() OVER (ORDER BY AVG(a.pct) DESC)    AS rank_victorias,
       RANK() OVER (ORDER BY AVG(a.pct) DESC)
         - RANK() OVER (ORDER BY AVG(a.margen) DESC) AS brecha
FROM analysis_team_season a
JOIN team t ON t.team_id = a.team_id
WHERE LEFT(a.season_id, 4)::int BETWEEN 2015 AND 2020
GROUP BY t.team_id, t.abbreviation
ORDER BY margen_promedio DESC
LIMIT 12;


/* E3.3 ¿Qué equipos ganan más de local que de visitante?

   La ventaja de local se traduce en asistencia y venta de boletos, que
   es ingreso directo. Un equipo con fuerte diferencial de local es más
   atractivo desde el punto de vista comercial.

   Técnicas: CTE, agregación condicional, GROUP BY.
*/
WITH local_visita AS (
    SELECT home_team_id AS team_id, 'local' AS condicion,
           (home_result = 'W')::int AS win, season_id
    FROM game
    UNION ALL
    SELECT away_team_id, 'visita', (away_result = 'W')::int, season_id
    FROM game
)
SELECT t.abbreviation AS equipo,
       ROUND(AVG(win) FILTER (WHERE condicion = 'local'), 4)  AS pct_local,
       ROUND(AVG(win) FILTER (WHERE condicion = 'visita'), 4) AS pct_visita,
       ROUND(AVG(win) FILTER (WHERE condicion = 'local')
           - AVG(win) FILTER (WHERE condicion = 'visita'), 4) AS ventaja_local
FROM local_visita lv
JOIN team t ON t.team_id = lv.team_id
WHERE LEFT(season_id, 4)::int BETWEEN 2015 AND 2020
GROUP BY t.team_id, t.abbreviation
ORDER BY ventaja_local DESC
LIMIT 10;


/* ===================================================================
   DIMENSIÓN 2 - VALOR POR EL DINERO
   =================================================================== */

/* E3.4 ¿Cuántas victorias compra cada millón de dólares?

   Es la medida más directa de eficiencia del gasto. Un equipo que gana
   lo mismo con menos nómina tiene mejor gestión y más margen para
   mejorar sin desbordar el presupuesto.

   Técnicas: JOIN de tres tablas, división con protección de nulos.
*/
SELECT t.abbreviation AS equipo,
       t.full_name,
       a.victorias,
       ROUND(ts.total_salary / 1000000.0, 1) AS nomina_millones,
       ROUND(a.victorias / NULLIF(ts.total_salary / 1000000.0, 0), 3)
           AS victorias_por_millon
FROM analysis_team_season a
JOIN team_salary ts ON ts.team_id = a.team_id AND ts.season_id = a.season_id
JOIN team t         ON t.team_id  = a.team_id
WHERE a.season_id = '2020-21'
ORDER BY victorias_por_millon DESC;


/* E3.5 ¿Qué equipos tienen más talento del que su nómina sugiere?

   Compara la posición del equipo en gasto contra su posición en
   talento (PIE de su mejor jugador). Una brecha positiva grande indica
   que el equipo obtuvo talento por debajo de precio de mercado, que es
   exactamente el perfil de una buena inversión.

   Se usa PIE porque all_star_appearances solo tiene dato para 3 de los
   523 jugadores con salario en 2020-21.

   Técnicas: CTEs múltiples, funciones ventana, LEFT JOIN, subconsulta.
*/
WITH gasto AS (
    SELECT ts.team_id,
           ts.total_salary,
           RANK() OVER (ORDER BY ts.total_salary DESC) AS rank_gasto
    FROM team_salary ts
    WHERE ts.season_id = '2020-21'
),
talento AS (
    SELECT ps.team_id,
           MAX(p.pie) AS pie_estrella,
           RANK() OVER (ORDER BY MAX(p.pie) DESC NULLS LAST) AS rank_talento
    FROM player_salary ps
    LEFT JOIN player p ON p.player_id = ps.player_id
    WHERE ps.season_id = '2020-21'
    GROUP BY ps.team_id
)
SELECT t.abbreviation AS equipo,
       ROUND(g.total_salary / 1000000.0, 1) AS nomina_millones,
       g.rank_gasto,
       ROUND(ta.pie_estrella, 4) AS pie_estrella,
       ta.rank_talento,
       g.rank_gasto - ta.rank_talento AS brecha_a_favor
FROM gasto g
JOIN talento ta ON ta.team_id = g.team_id
JOIN team t     ON t.team_id  = g.team_id
ORDER BY brecha_a_favor DESC
LIMIT 12;


/* E3.6 ¿Qué equipos tienen margen financiero para reforzarse?

   Un porcentaje bajo de nómina comprometida hacia 2021-22 significa
   contratos que vencen y por lo tanto capacidad de fichar sin exceder
   el tope salarial. Un equipo bueno pero con la nómina comprometida al
   máximo tiene poco margen de maniobra.

   Técnicas: agregación condicional, GROUP BY, protección de nulos.
*/
SELECT t.abbreviation AS equipo,
       ROUND(MAX(ts.total_salary) FILTER (WHERE ts.season_id = '2020-21')
             / 1000000.0, 1) AS nomina_2020_21,
       ROUND(MAX(ts.total_salary) FILTER (WHERE ts.season_id = '2021-22')
             / 1000000.0, 1) AS comprometido_2021_22,
       ROUND(100 * MAX(ts.total_salary) FILTER (WHERE ts.season_id = '2021-22')
             / NULLIF(MAX(ts.total_salary) FILTER (WHERE ts.season_id = '2020-21'), 0), 1)
           AS pct_comprometido
FROM team_salary ts
JOIN team t ON t.team_id = ts.team_id
WHERE ts.season_id IN ('2020-21', '2021-22')
GROUP BY t.team_id, t.abbreviation
ORDER BY pct_comprometido;


/* ===================================================================
   DIMENSIÓN 3 - CRECIMIENTO Y TALENTO JOVEN
   =================================================================== */

/* E3.7 ¿Qué equipos vienen en trayectoria ascendente?

   Se usa la pendiente de una regresión lineal sobre las seis
   temporadas en lugar de comparar solo la primera contra la última.
   Un equipo que subió y volvió a caer no es lo mismo que uno que sube
   de forma sostenida, y la diferencia solo se ve con la tendencia
   completa.

   Técnicas: regresión lineal, GROUP BY, HAVING.
*/
SELECT t.abbreviation AS equipo,
       t.full_name,
       ROUND(REGR_SLOPE(a.pct, LEFT(a.season_id, 4)::int)::numeric, 4)
           AS pendiente_anual,
       ROUND(AVG(a.pct), 4) AS pct_promedio,
       ROUND(MAX(a.pct) FILTER (WHERE a.season_id = '2020-21'), 4) AS pct_2020_21
FROM analysis_team_season a
JOIN team t ON t.team_id = a.team_id
WHERE LEFT(a.season_id, 4)::int BETWEEN 2015 AND 2020
GROUP BY t.team_id, t.abbreviation, t.full_name
HAVING COUNT(*) = 6
ORDER BY pendiente_anual DESC
LIMIT 12;


/* E3.8 ¿Qué tan bueno es el roster actual? (usa la ingesta del API)

   Mide la calidad del plantel de 2020-21 con estadísticas reales de la
   temporada, no con promedios de carrera. Cuenta anotadores de
   referencia y evalúa la rotación titular.

   Técnicas: JOIN, agregación condicional, GROUP BY, filtro por
   participación mínima.
*/
SELECT t.abbreviation AS equipo,
       COUNT(*) FILTER (WHERE s.points_per_game >= 15) AS anotadores_15plus,
       COUNT(*) FILTER (WHERE s.games_played >= 40)    AS jugadores_rotacion,
       ROUND(MAX(s.points_per_game), 2)                AS mejor_anotador_ppg,
       ROUND(AVG(s.points_per_game) FILTER (WHERE s.games_played >= 40), 2)
           AS ppg_promedio_rotacion
FROM player_season_stat s
JOIN team t ON t.team_id = s.team_id
WHERE s.season_id = '2020-21'
GROUP BY t.team_id, t.abbreviation
ORDER BY anotadores_15plus DESC, mejor_anotador_ppg DESC
LIMIT 12;


/* E3.9 ¿Qué equipos tienen mejor producción combinada de su núcleo?

   Suma puntos, asistencias y rebotes de los cinco jugadores más
   productivos de cada equipo. Un núcleo fuerte y balanceado sostiene
   el rendimiento mejor que una sola estrella.

   Técnicas: CTE, ROW_NUMBER con PARTITION, JOIN, GROUP BY.
*/
WITH ranking_jugadores AS (
    SELECT s.team_id,
           s.player_id,
           s.points_per_game + s.assists_per_game + s.rebounds_per_game
               AS aporte_total,
           ROW_NUMBER() OVER (PARTITION BY s.team_id
                              ORDER BY s.points_per_game DESC) AS posicion
    FROM player_season_stat s
    WHERE s.season_id = '2020-21' AND s.games_played >= 30
)
SELECT t.abbreviation AS equipo,
       COUNT(*)                        AS jugadores_considerados,
       ROUND(SUM(r.aporte_total), 1)   AS aporte_nucleo,
       ROUND(AVG(r.aporte_total), 2)   AS aporte_promedio
FROM ranking_jugadores r
JOIN team t ON t.team_id = r.team_id
WHERE r.posicion <= 5
GROUP BY t.team_id, t.abbreviation
ORDER BY aporte_nucleo DESC
LIMIT 12;


/* E3.10 ¿Qué equipos han sabido construir mediante el draft?

   Cuenta las selecciones de primera ronda entre 2016 y 2020 que ya
   producen en 2020-21. El talento formado en el draft cuesta mucho
   menos que el fichado en agencia libre, así que un buen historial de
   draft es una ventaja financiera sostenida.

   OJO: la tabla registra al equipo que hizo la selección, no al equipo
   donde el jugador terminó. Ejemplo: Luka Doncic aparece con Atlanta
   porque los Hawks lo eligieron y lo traspasaron esa misma noche.

   Técnicas: JOIN de tres tablas, GROUP BY, filtros compuestos.
*/
SELECT t.abbreviation AS equipo,
       COUNT(DISTINCT d.player_id) AS picks_productivos,
       ROUND(AVG(s.points_per_game), 2) AS ppg_promedio,
       ROUND(MAX(s.points_per_game), 2) AS mejor_ppg
FROM draft_selection d
JOIN team t ON t.team_id = d.team_id
JOIN player_season_stat s
  ON s.player_id = d.player_id AND s.season_id = '2020-21'
WHERE d.draft_year BETWEEN 2016 AND 2020
  AND d.round_number = 1
  AND s.points_per_game >= 8
GROUP BY t.team_id, t.abbreviation
ORDER BY picks_productivos DESC, ppg_promedio DESC
LIMIT 12;


/* E3.11 ¿Qué equipos dependen demasiado de un solo jugador?

   Un equipo cuya producción se concentra en una sola figura es más
   frágil: una lesión hunde la temporada. Se calcula qué porcentaje de
   los puntos del núcleo aporta el mejor anotador.

   Técnicas: CTE, subconsulta, funciones ventana, GROUP BY.
*/
WITH produccion AS (
    SELECT s.team_id,
           s.points_per_game,
           MAX(s.points_per_game) OVER (PARTITION BY s.team_id) AS mejor
    FROM player_season_stat s
    WHERE s.season_id = '2020-21' AND s.games_played >= 30
)
SELECT t.abbreviation AS equipo,
       ROUND(MAX(p.mejor), 2)          AS mejor_anotador_ppg,
       ROUND(SUM(p.points_per_game), 2) AS puntos_plantel,
       ROUND(100 * MAX(p.mejor) / NULLIF(SUM(p.points_per_game), 0), 2)
           AS pct_dependencia
FROM produccion p
JOIN team t ON t.team_id = p.team_id
GROUP BY t.team_id, t.abbreviation
ORDER BY pct_dependencia
LIMIT 12;


/* ===================================================================
   E3.12 - ÍNDICE COMPUESTO DE INVERSIÓN
   =================================================================== */

/* Consolida las tres dimensiones en un solo puntaje comparable.

   Cada métrica se normaliza con PERCENT_RANK, que convierte valores en
   posiciones relativas entre 0 y 1. Sin esa normalización no se pueden
   sumar magnitudes de escalas distintas (un margen de 4.45 puntos y una
   eficiencia de 0.345 victorias por millón no son comparables).

   Ponderaciones y su justificación:
     40% RENDIMIENTO  - es la base; sin ganar no hay negocio.
                        Se reparte 50% récord, 30% margen, 20% piso.
     35% VALOR        - eficiencia del gasto; distingue al equipo bien
                        gestionado del que solo compra resultados.
     25% CRECIMIENTO  - trayectoria; se invierte para el futuro, no
                        para el pasado.

   Técnicas: CTEs múltiples, funciones ventana, regresión, JOIN.
*/
WITH historico AS (
    SELECT a.team_id,
           AVG(a.pct)    AS pct_promedio,
           MIN(a.pct)    AS piso,
           AVG(a.margen) AS margen,
           REGR_SLOPE(a.pct, LEFT(a.season_id, 4)::int) AS pendiente
    FROM analysis_team_season a
    WHERE LEFT(a.season_id, 4)::int BETWEEN 2015 AND 2020
    GROUP BY a.team_id
    HAVING COUNT(*) = 6
),
temporada_actual AS (
    SELECT a.team_id,
           a.victorias,
           ts.total_salary,
           a.victorias / NULLIF(ts.total_salary / 1000000.0, 0) AS victorias_por_millon
    FROM analysis_team_season a
    JOIN team_salary ts ON ts.team_id = a.team_id AND ts.season_id = a.season_id
    WHERE a.season_id = '2020-21'
),
normalizado AS (
    SELECT h.team_id,
           h.pct_promedio, h.margen, h.pendiente,
           ac.victorias, ac.victorias_por_millon, ac.total_salary,
           PERCENT_RANK() OVER (ORDER BY h.pct_promedio)          AS n_record,
           PERCENT_RANK() OVER (ORDER BY h.margen)                AS n_margen,
           PERCENT_RANK() OVER (ORDER BY h.piso)                  AS n_piso,
           PERCENT_RANK() OVER (ORDER BY ac.victorias_por_millon) AS n_eficiencia,
           PERCENT_RANK() OVER (ORDER BY h.pendiente)             AS n_tendencia
    FROM historico h
    JOIN temporada_actual ac ON ac.team_id = h.team_id
)
SELECT t.abbreviation AS equipo,
       t.full_name,
       ROUND(n.pct_promedio, 3)              AS pct_seis_temporadas,
       ROUND(n.margen, 2)                    AS margen_promedio,
       n.victorias                           AS victorias_2020_21,
       ROUND(n.total_salary / 1000000.0, 1)  AS nomina_millones,
       ROUND(n.victorias_por_millon::numeric, 3) AS victorias_por_millon,
       ROUND(n.pendiente::numeric, 4)        AS tendencia,
       ROUND((0.40 * (0.5 * n.n_record + 0.3 * n.n_margen + 0.2 * n.n_piso)
            + 0.35 * n.n_eficiencia
            + 0.25 * n.n_tendencia)::numeric, 4) AS indice_inversion
FROM normalizado n
JOIN team t ON t.team_id = n.team_id
ORDER BY indice_inversion DESC;


/* ===================================================================
   E3.13 - ANÁLISIS DE SENSIBILIDAD

   ¿La recomendación depende de las ponderaciones elegidas? Se comparan
   tres esquemas distintos. Si el mismo equipo encabeza los tres, la
   conclusión es robusta y no un artefacto de los pesos.

   Técnicas: CTE, funciones ventana, comparación de rankings.
   =================================================================== */
WITH historico AS (
    SELECT a.team_id, AVG(a.pct) AS pct_promedio, MIN(a.pct) AS piso,
           AVG(a.margen) AS margen,
           REGR_SLOPE(a.pct, LEFT(a.season_id, 4)::int) AS pendiente
    FROM analysis_team_season a
    WHERE LEFT(a.season_id, 4)::int BETWEEN 2015 AND 2020
    GROUP BY a.team_id HAVING COUNT(*) = 6
),
actual AS (
    SELECT a.team_id,
           a.victorias / NULLIF(ts.total_salary / 1000000.0, 0) AS eficiencia
    FROM analysis_team_season a
    JOIN team_salary ts ON ts.team_id = a.team_id AND ts.season_id = a.season_id
    WHERE a.season_id = '2020-21'
),
n AS (
    SELECT h.team_id,
           PERCENT_RANK() OVER (ORDER BY h.pct_promedio) AS n_record,
           PERCENT_RANK() OVER (ORDER BY h.margen)       AS n_margen,
           PERCENT_RANK() OVER (ORDER BY h.piso)         AS n_piso,
           PERCENT_RANK() OVER (ORDER BY ac.eficiencia)  AS n_eficiencia,
           PERCENT_RANK() OVER (ORDER BY h.pendiente)    AS n_tendencia
    FROM historico h JOIN actual ac ON ac.team_id = h.team_id
)
SELECT t.abbreviation AS equipo,
       ROUND((0.40 * (0.5*n_record + 0.3*n_margen + 0.2*n_piso)
            + 0.35 * n_eficiencia + 0.25 * n_tendencia)::numeric, 4) AS mixto,
       RANK() OVER (ORDER BY (0.40 * (0.5*n_record + 0.3*n_margen + 0.2*n_piso)
            + 0.35 * n_eficiencia + 0.25 * n_tendencia) DESC) AS pos_mixto,
       RANK() OVER (ORDER BY (0.70 * (0.5*n_record + 0.3*n_margen + 0.2*n_piso)
            + 0.15 * n_eficiencia + 0.15 * n_tendencia) DESC) AS pos_rendimiento,
       RANK() OVER (ORDER BY (0.20 * (0.5*n_record + 0.3*n_margen + 0.2*n_piso)
            + 0.60 * n_eficiencia + 0.20 * n_tendencia) DESC) AS pos_valor,
       RANK() OVER (ORDER BY (0.20 * (0.5*n_record + 0.3*n_margen + 0.2*n_piso)
            + 0.20 * n_eficiencia + 0.60 * n_tendencia) DESC) AS pos_crecimiento
FROM n JOIN team t ON t.team_id = n.team_id
ORDER BY mixto DESC
LIMIT 10;
