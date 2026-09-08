/* 15 consultas requeridas. Temporada 2017 = 2017-18. */

/* ===================================================================
   ETAPA 2 - Las 8 preguntas obligatorias
   CC3088 Base de Datos 1 - Proyecto 1

   CONVENCIONES DE INTERPRETACION (documentar en el PDF):
   - "temporada 2017" = 2017-18 ; "temporada 2018" = 2018-19
     (se nombra la temporada por el anio en que inicia)
   - "ultima temporada" = 2020-21, la ultima temporada COMPLETA presente
     en Game.csv. team_salary contiene proyecciones hasta 2025-26, pero
     esas temporadas no tienen partidos ni rosters cargados, por lo que
     no sirven para responder preguntas de desempenio.
   - El dataset contiene UNICAMENTE temporada regular (todos los
     SEASON_ID inician con 2). No hay playoffs.
   =================================================================== */



-- 1. Jugador activo mas alto y mas bajo.
WITH activos AS (
    SELECT full_name, height_inches
    FROM player
    WHERE is_active AND height_inches IS NOT NULL
)
SELECT 'Mas alto' AS categoria, full_name, height_inches
FROM activos
WHERE height_inches = (SELECT MAX(height_inches) FROM activos)
UNION ALL
SELECT 'Mas bajo', full_name, height_inches
FROM activos
WHERE height_inches = (SELECT MIN(height_inches) FROM activos)
ORDER BY categoria DESC, full_name;



-- 2. Promedio de puntos anotados y recibidos por equipo y temporada.

WITH resultados AS (
    SELECT season_id, home_team_id AS team_id, home_points AS favor, away_points AS contra
    FROM game
    UNION ALL
    SELECT season_id, away_team_id, away_points, home_points
    FROM game
)
SELECT r.season_id,
       t.full_name,
       ROUND(AVG(r.favor), 2)  AS puntos_anotados,
       ROUND(AVG(r.contra), 2) AS puntos_recibidos,
       ROUND(AVG(r.favor) - AVG(r.contra), 2) AS diferencial
FROM resultados r
JOIN team t ON t.team_id = r.team_id
WHERE LEFT(r.season_id, 4)::int BETWEEN 2015 AND 2020
GROUP BY r.season_id, t.team_id, t.full_name
ORDER BY r.season_id, puntos_anotados DESC;


-- 3. Top 5 de arbitros en cuyos juegos pierde el equipo visitante.
SELECT o.official_id,
       CONCAT_WS(' ', o.first_name, o.last_name) AS arbitro,
       COUNT(*) FILTER (WHERE g.away_result = 'L') AS derrotas_visitante,
       COUNT(*) AS partidos_arbitrados,
       ROUND(100.0 * COUNT(*) FILTER (WHERE g.away_result = 'L') / COUNT(*), 2) AS pct_derrota_visitante
FROM game_official go
JOIN official o ON o.official_id = go.official_id
JOIN game g     ON g.game_id     = go.game_id
GROUP BY o.official_id, o.first_name, o.last_name
ORDER BY derrotas_visitante DESC
LIMIT 5;


-- 4a. Equipo con la nomina mas alta en la ultima temporada, comparado con los equipos que tienen los jugadores mas valiosos.
WITH nomina AS (
    SELECT ts.team_id,
           t.full_name,
           ts.total_salary,
           RANK() OVER (ORDER BY ts.total_salary DESC) AS rank_nomina
    FROM team_salary ts
    JOIN team t ON t.team_id = ts.team_id
    WHERE ts.season_id = '2020-21'
),
valor AS (
    SELECT ps.team_id,
           MAX(ps.salary_value)      AS salario_mas_alto,
           ROUND(AVG(p.pie), 4)      AS pie_promedio,
           ROUND(MAX(p.pie), 4)      AS pie_estrella,
           RANK() OVER (ORDER BY MAX(p.pie) DESC NULLS LAST) AS rank_valor
    FROM player_salary ps
    LEFT JOIN player p ON p.player_id = ps.player_id
    WHERE ps.season_id = '2020-21'
    GROUP BY ps.team_id
)
SELECT n.full_name,
       n.total_salary,
       n.rank_nomina,
       v.salario_mas_alto,
       v.pie_estrella,
       v.rank_valor,
       n.rank_nomina - v.rank_valor AS brecha
FROM nomina n
LEFT JOIN valor v ON v.team_id = n.team_id
ORDER BY n.rank_nomina;

-- 4b. Medida objetiva de la relacion entre gasto y talento.
WITH n AS (
    SELECT team_id, total_salary FROM team_salary WHERE season_id = '2020-21'
),
v AS (
    SELECT ps.team_id, MAX(p.pie) AS pie_estrella
    FROM player_salary ps
    LEFT JOIN player p ON p.player_id = ps.player_id
    WHERE ps.season_id = '2020-21'
    GROUP BY ps.team_id
)
SELECT ROUND(CORR(n.total_salary, v.pie_estrella)::numeric, 4) AS correlacion_nomina_valor,
       COUNT(*) AS equipos_comparados
FROM n JOIN v ON v.team_id = n.team_id
WHERE v.pie_estrella IS NOT NULL;


-- 5a. Temporada con mas partidos en la historia de la NBA.

WITH s AS (
    SELECT season_id,
           COUNT(*) AS partidos,
           MIN(game_date) AS inicio,
           MAX(game_date) AS fin,
           MAX(game_date) - MIN(game_date) AS dias
    FROM game
    GROUP BY season_id
)
SELECT season_id, partidos, inicio, fin, dias
FROM s
WHERE partidos = (SELECT MAX(partidos) FROM s)
ORDER BY season_id;

-- 5b. Temporada que mas se prolongo en fechas.
WITH s AS (
    SELECT season_id,
           COUNT(*) AS partidos,
           MIN(game_date) AS inicio,
           MAX(game_date) AS fin,
           MAX(game_date) - MIN(game_date) AS dias
    FROM game
    GROUP BY season_id
)
SELECT season_id, partidos, inicio, fin, dias
FROM s
ORDER BY dias DESC
LIMIT 5;


-- 6. Equipo con mayor diferencia de puntos a favor por partido en las temporadas 2017-18 y 2018-19.

WITH margenes AS (
    SELECT season_id, home_team_id AS team_id, home_points - away_points AS margen
    FROM game
    UNION ALL
    SELECT season_id, away_team_id, away_points - home_points
    FROM game
),
promedios AS (
    SELECT season_id,
           team_id,
           ROUND(AVG(margen), 2) AS margen_promedio,
           COUNT(*) AS partidos,
           RANK() OVER (PARTITION BY season_id ORDER BY AVG(margen) DESC) AS posicion
    FROM margenes
    WHERE season_id IN ('2017-18', '2018-19')
    GROUP BY season_id, team_id
)
SELECT p.season_id, t.full_name, p.margen_promedio, p.partidos
FROM promedios p
JOIN team t ON t.team_id = p.team_id
WHERE p.posicion <= 3
ORDER BY p.season_id, p.posicion;



-- 7. Jugador mas valioso del draft 2018 en la ultima temporada.

SELECT d.player_name,
       d.overall_pick,
       t.full_name AS equipo_que_lo_selecciono,
       p.pie       AS pie_carrera,
       s.points_per_game,
       s.assists_per_game,
       s.rebounds_per_game,
       s.season_id AS temporada_api
FROM draft_selection d
JOIN player p ON p.player_id = d.player_id
LEFT JOIN team t ON t.team_id = d.team_id
LEFT JOIN player_season_stat s
       ON s.player_id = p.player_id
      AND s.season_id = (SELECT MAX(season_id) FROM player_season_stat)
WHERE d.draft_year = 2018
ORDER BY s.points_per_game DESC NULLS LAST, p.pie DESC NULLS LAST
LIMIT 10;



--  8. Top 5 de estados que mas salarios pagaron en 2020-21 y 2021-22.

WITH equipo_estado AS (
    SELECT team_id,
           full_name,
           CASE
               WHEN full_name = 'Atlanta Hawks'   THEN 'Georgia'
               WHEN full_name = 'Toronto Raptors' THEN 'Ontario (Canada)'
               ELSE state
           END AS estado
    FROM team
    WHERE is_current
)
SELECT e.estado,
       COUNT(DISTINCT e.team_id)   AS equipos,
       SUM(ts.total_salary)        AS salarios_totales,
       ROUND(SUM(ts.total_salary) / COUNT(DISTINCT e.team_id), 2) AS promedio_por_equipo
FROM team_salary ts
JOIN equipo_estado e ON e.team_id = ts.team_id
WHERE ts.season_id IN ('2020-21', '2021-22')
  AND e.estado IS NOT NULL
GROUP BY e.estado
ORDER BY salarios_totales DESC
LIMIT 5;

/*
Consultas exploratorias conservadas como trabajo preliminar.
La implementacion oficial y completa de la Etapa 3 se encuentra en
database/stage3_queries.sql (E3.1 a E3.13). Para la conclusion final deben
utilizarse los resultados de ese archivo, no el indice preliminar siguiente.
*/

-- Base reutilizada por las consultas exploratorias 9-13 y 15.
DROP VIEW IF EXISTS analysis_team_season;
CREATE TEMP VIEW analysis_team_season AS
WITH r AS (SELECT season_id,home_team_id team_id,(home_result='W')::int gano,home_points-away_points margen FROM game
 UNION ALL SELECT season_id,away_team_id,(away_result='W')::int,away_points-home_points FROM game)
SELECT season_id,team_id,COUNT(*) juegos,SUM(gano) victorias,AVG(gano::numeric) pct,AVG(margen) margen
FROM r GROUP BY season_id,team_id;

-- 9. Equipos mas consistentes en seis temporadas.
SELECT t.full_name,ROUND(AVG(a.pct),4) pct_promedio,ROUND(STDDEV_SAMP(a.pct),4) variabilidad
FROM analysis_team_season a JOIN team t USING(team_id) WHERE LEFT(season_id,4)::int BETWEEN 2015 AND 2020
GROUP BY t.team_id,t.full_name HAVING COUNT(*)=6 ORDER BY variabilidad,pct_promedio DESC LIMIT 10;

-- 10. Equipos que mas mejoraron entre 2015-16 y 2020-21.
SELECT t.full_name,ROUND(MAX(pct) FILTER(WHERE season_id='2020-21')-
 MAX(pct) FILTER(WHERE season_id='2015-16'),4) mejora
FROM analysis_team_season a JOIN team t USING(team_id) WHERE season_id IN('2015-16','2020-21')
GROUP BY t.team_id,t.full_name HAVING COUNT(*)=2 ORDER BY mejora DESC;

-- 11. Eficiencia: victorias por millon de dolares en 2020-21.
SELECT t.full_name,a.victorias,ts.total_salary,
 ROUND(a.victorias/NULLIF(ts.total_salary/1000000.0,0),3) victorias_por_millon
FROM analysis_team_season a JOIN team_salary ts USING(season_id,team_id) JOIN team t USING(team_id)
WHERE a.season_id='2020-21' ORDER BY victorias_por_millon DESC;

-- 12. Mejor diferencial promedio en las seis temporadas.
SELECT t.full_name,ROUND(AVG(a.margen),2) margen_promedio
FROM analysis_team_season a JOIN team t USING(team_id) WHERE LEFT(season_id,4)::int BETWEEN 2015 AND 2020
GROUP BY t.team_id,t.full_name ORDER BY margen_promedio DESC;

-- 13. Equipos con mayor crecimiento salarial 2020-21 a 2021-22.
SELECT t.full_name,ROUND(100*(MAX(total_salary) FILTER(WHERE season_id='2021-22')/
 NULLIF(MAX(total_salary) FILTER(WHERE season_id='2020-21'),0)-1),2) crecimiento_pct
FROM team_salary ts JOIN team t USING(team_id) WHERE season_id IN('2020-21','2021-22')
GROUP BY t.team_id,t.full_name HAVING COUNT(*)=2 ORDER BY crecimiento_pct DESC;

-- 14. Equipos con mas jugadores All-Star activos.
SELECT t.full_name,COUNT(*) FILTER(WHERE p.all_star_appearances>0) jugadores_all_star,
 SUM(COALESCE(p.all_star_appearances,0)) apariciones
FROM team t JOIN player p ON p.current_team_id=t.team_id WHERE p.is_active
GROUP BY t.team_id,t.full_name ORDER BY jugadores_all_star DESC,apariciones DESC;

-- 15. Indice exploratorio anterior; sustituido por E3.12 y E3.13.
WITH m AS (SELECT a.*,a.victorias/NULLIF(ts.total_salary/1000000.0,0) eficiencia
 FROM analysis_team_season a JOIN team_salary ts USING(season_id,team_id) WHERE a.season_id='2020-21'),
n AS (SELECT m.*,PERCENT_RANK() OVER(ORDER BY pct) nv,PERCENT_RANK() OVER(ORDER BY margen) nm,
 PERCENT_RANK() OVER(ORDER BY eficiencia) ne FROM m)
SELECT t.full_name,ROUND(n.pct,4) pct_victorias,ROUND(n.margen,2) margen,
 ROUND(n.eficiencia,3) victorias_por_millon,ROUND((.45*nv+.35*nm+.20*ne)::numeric,4) indice
FROM n JOIN team t USING(team_id) ORDER BY indice DESC LIMIT 10;
