/* 15 consultas requeridas. Temporada 2017 = 2017-18. */

-- 1. Jugadores activos mas alto y mas bajo (subquery).
SELECT full_name,height_inches FROM player
WHERE is_active AND height_inches IN
 (SELECT MAX(height_inches) FROM player WHERE is_active UNION SELECT MIN(height_inches) FROM player WHERE is_active)
ORDER BY height_inches DESC,full_name;

-- 2. Promedio anotado/recibido por equipo y temporada.
WITH r AS (
 SELECT season_id,home_team_id team_id,home_points favor,away_points contra FROM game
 UNION ALL SELECT season_id,away_team_id,away_points,home_points FROM game)
SELECT r.season_id,t.full_name,ROUND(AVG(favor),2) anotados,ROUND(AVG(contra),2) recibidos
FROM r JOIN team t ON t.team_id=r.team_id WHERE LEFT(r.season_id,4)::int BETWEEN 2015 AND 2020
GROUP BY r.season_id,t.team_id,t.full_name ORDER BY r.season_id,anotados DESC;

-- 3. Top 5 arbitros cuando pierde el visitante.
SELECT o.official_id,CONCAT_WS(' ',o.first_name,o.last_name) arbitro,COUNT(*) juegos
FROM game_official go JOIN official o USING(official_id) JOIN game g USING(game_id)
WHERE g.away_result='L' GROUP BY o.official_id,o.first_name,o.last_name ORDER BY juegos DESC LIMIT 5;

-- 4. Nomina y jugador mejor pagado en la ultima temporada (subquery).
SELECT ts.season_id,t.full_name,ts.total_salary,MAX(ps.salary_value) mejor_pagado,
 RANK() OVER(ORDER BY ts.total_salary DESC) ranking_nomina
FROM team_salary ts JOIN team t USING(team_id)
LEFT JOIN player_salary ps ON ps.team_id=ts.team_id AND ps.season_id=ts.season_id
WHERE ts.season_id=(SELECT MAX(season_id) FROM team_salary)
GROUP BY ts.season_id,t.team_id,t.full_name,ts.total_salary ORDER BY ranking_nomina;

-- 5. Temporada con mas partidos y la de mayor duracion (subqueries).
WITH s AS (SELECT season_id,COUNT(*) partidos,MIN(game_date) inicio,MAX(game_date) fin,
 MAX(game_date)-MIN(game_date) dias FROM game GROUP BY season_id)
SELECT * FROM s WHERE partidos=(SELECT MAX(partidos) FROM s) OR dias=(SELECT MAX(dias) FROM s)
ORDER BY partidos DESC,dias DESC;

-- 6. Mejor margen promedio en 2017-18 y 2018-19.
WITH m AS (SELECT season_id,home_team_id team_id,home_points-away_points margen FROM game
 UNION ALL SELECT season_id,away_team_id,away_points-home_points FROM game),
x AS (SELECT season_id,team_id,AVG(margen) promedio,
 RANK() OVER(PARTITION BY season_id ORDER BY AVG(margen) DESC) pos FROM m
 WHERE season_id IN('2017-18','2018-19') GROUP BY season_id,team_id)
SELECT x.season_id,t.full_name,ROUND(promedio,2) margen FROM x JOIN team t USING(team_id)
WHERE pos=1 ORDER BY x.season_id;

-- 7. Jugador mas valioso del draft 2018: PIE y PTS de ultima ingesta API.
SELECT d.player_name,d.overall_pick,p.pie,s.points_per_game,s.season_id
FROM draft_selection d JOIN player p USING(player_id)
LEFT JOIN player_season_stat s ON s.player_id=p.player_id
 AND s.season_id=(SELECT MAX(season_id) FROM player_season_stat)
WHERE d.draft_year=2018 ORDER BY p.pie DESC NULLS LAST,s.points_per_game DESC NULLS LAST LIMIT 1;

-- 8. Top 5 estados por salarios 2020-21 y 2021-22.
SELECT t.state,SUM(ps.salary_value) salarios FROM player_salary ps JOIN team t USING(team_id)
WHERE ps.season_id IN('2020-21','2021-22') AND t.state IS NOT NULL
GROUP BY t.state ORDER BY salarios DESC LIMIT 5;

-- Base reutilizada por las preguntas propias 9-13 y la recomendacion 15.
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

-- 15. Indice para invertir: 45% victorias, 35% margen, 20% eficiencia salarial.
WITH m AS (SELECT a.*,a.victorias/NULLIF(ts.total_salary/1000000.0,0) eficiencia
 FROM analysis_team_season a JOIN team_salary ts USING(season_id,team_id) WHERE a.season_id='2020-21'),
n AS (SELECT m.*,PERCENT_RANK() OVER(ORDER BY pct) nv,PERCENT_RANK() OVER(ORDER BY margen) nm,
 PERCENT_RANK() OVER(ORDER BY eficiencia) ne FROM m)
SELECT t.full_name,ROUND(n.pct,4) pct_victorias,ROUND(n.margen,2) margen,
 ROUND(n.eficiencia,3) victorias_por_millon,ROUND((.45*nv+.35*nm+.20*ne)::numeric,4) indice
FROM n JOIN team t USING(team_id) ORDER BY indice DESC LIMIT 10;
