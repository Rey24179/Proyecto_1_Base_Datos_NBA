/*
ETAPA 3 - Preguntas propias y recomendacion de inversion para 2021-22

Ejecucion:
  1. Cargar los CSV y la ingesta API de 2020-21.
  2. Ejecutar este archivo completo en una misma sesion de pgAdmin.

Todas las metricas deportivas usan 2015-16 a 2020-21. Los resultados se
deben exportar desde PostgreSQL antes de redactar la conclusion final.
*/

DROP VIEW IF EXISTS e3_team_dimensions;
DROP VIEW IF EXISTS e3_team_six;
DROP VIEW IF EXISTS e3_team_season;

CREATE TEMP VIEW e3_team_season AS
WITH resultados AS (
    SELECT season_id, home_team_id AS team_id,
           (home_result = 'W')::integer AS gano,
           home_points - away_points AS margen
    FROM game
    UNION ALL
    SELECT season_id, away_team_id,
           (away_result = 'W')::integer,
           away_points - home_points
    FROM game
)
SELECT season_id, team_id, COUNT(*) AS partidos, SUM(gano) AS victorias,
       AVG(gano::numeric) AS pct_victorias, AVG(margen::numeric) AS margen
FROM resultados
WHERE LEFT(season_id, 4)::integer BETWEEN 2015 AND 2020
GROUP BY season_id, team_id;

CREATE TEMP VIEW e3_team_six AS
SELECT team_id, COUNT(*) AS temporadas,
       AVG(pct_victorias) AS pct_promedio,
       MIN(pct_victorias) AS piso_victorias,
       STDDEV_SAMP(pct_victorias) AS variabilidad,
       AVG(margen) AS margen_promedio,
       REGR_SLOPE(pct_victorias, LEFT(season_id, 4)::numeric) AS tendencia
FROM e3_team_season
GROUP BY team_id
HAVING COUNT(*) = 6;

-- E3.1 Consistencia con un piso alto.
SELECT t.full_name, ROUND(s.pct_promedio, 4) AS pct_promedio,
       ROUND(s.piso_victorias, 4) AS peor_temporada,
       ROUND(s.variabilidad, 4) AS variabilidad
FROM e3_team_six s JOIN team t USING (team_id)
WHERE s.piso_victorias >= 0.40
ORDER BY s.pct_promedio DESC, s.variabilidad ASC;

-- E3.2 Diferencial de puntos frente al porcentaje de victorias.
WITH rankings AS (
    SELECT s.*,
           RANK() OVER (ORDER BY pct_promedio DESC) AS rank_victorias,
           RANK() OVER (ORDER BY margen_promedio DESC) AS rank_margen
    FROM e3_team_six s
)
SELECT t.full_name, ROUND(r.pct_promedio, 4) AS pct_victorias,
       ROUND(r.margen_promedio, 2) AS margen,
       r.rank_victorias, r.rank_margen,
       r.rank_victorias - r.rank_margen AS ventaja_margen
FROM rankings r JOIN team t USING (team_id)
ORDER BY ventaja_margen DESC, margen DESC;

-- E3.3 Ventaja de local durante las seis temporadas.
WITH tasas AS (
    SELECT t.team_id, t.full_name,
           AVG(CASE WHEN g.home_team_id=t.team_id THEN (g.home_result='W')::int END) AS pct_local,
           AVG(CASE WHEN g.away_team_id=t.team_id THEN (g.away_result='W')::int END) AS pct_visitante
    FROM team t JOIN game g ON t.team_id IN (g.home_team_id,g.away_team_id)
    WHERE LEFT(g.season_id,4)::integer BETWEEN 2015 AND 2020
    GROUP BY t.team_id,t.full_name
)
SELECT full_name, ROUND(pct_local::numeric,4) AS pct_local,
       ROUND(pct_visitante::numeric,4) AS pct_visitante,
       ROUND((pct_local-pct_visitante)::numeric,4) AS ventaja_local
FROM tasas ORDER BY ventaja_local DESC;

-- E3.4 Victorias por millon de dolares en 2020-21.
SELECT t.full_name, s.victorias, ts.total_salary,
       ROUND(s.victorias/NULLIF(ts.total_salary/1000000.0,0),3) AS victorias_por_millon
FROM e3_team_season s
JOIN team_salary ts USING (team_id,season_id)
JOIN team t USING (team_id)
WHERE s.season_id='2020-21'
ORDER BY victorias_por_millon DESC;

-- E3.5 Talento por encima de la posicion de nomina.
WITH base AS (
    SELECT ts.team_id, ts.total_salary, MAX(p.pie) AS pie_estrella
    FROM team_salary ts
    LEFT JOIN player_salary ps ON ps.team_id=ts.team_id AND ps.season_id=ts.season_id
    LEFT JOIN player p ON p.player_id=ps.player_id
    WHERE ts.season_id='2020-21'
    GROUP BY ts.team_id,ts.total_salary
), rankings AS (
    SELECT base.*,
           RANK() OVER (ORDER BY total_salary DESC) AS rank_nomina,
           RANK() OVER (ORDER BY pie_estrella DESC NULLS LAST) AS rank_talento
    FROM base
)
SELECT t.full_name,r.total_salary,ROUND(r.pie_estrella,4) AS pie_estrella,
       r.rank_nomina,r.rank_talento,r.rank_nomina-r.rank_talento AS ventaja_valor
FROM rankings r JOIN team t USING(team_id)
ORDER BY ventaja_valor DESC, pie_estrella DESC NULLS LAST;

-- E3.6 Porcentaje de nomina 2020-21 ya comprometido para 2021-22.
SELECT t.full_name,
       MAX(ts.total_salary) FILTER (WHERE season_id='2020-21') AS nomina_2020_21,
       MAX(ts.total_salary) FILTER (WHERE season_id='2021-22') AS comprometido_2021_22,
       ROUND(100*MAX(ts.total_salary) FILTER (WHERE season_id='2021-22') /
             NULLIF(MAX(ts.total_salary) FILTER (WHERE season_id='2020-21'),0),2) AS pct_comprometido
FROM team_salary ts JOIN team t USING(team_id)
WHERE season_id IN ('2020-21','2021-22')
GROUP BY t.team_id,t.full_name HAVING COUNT(*)=2
ORDER BY pct_comprometido ASC;

-- E3.7 Trayectoria: pendiente de regresion del porcentaje de victorias.
SELECT t.full_name, ROUND(s.tendencia::numeric,5) AS cambio_anual,
       ROUND(s.pct_promedio,4) AS pct_promedio,
       ROUND(s.piso_victorias,4) AS piso
FROM e3_team_six s JOIN team t USING(team_id)
ORDER BY cambio_anual DESC;

-- E3.8 Calidad y profundidad del roster 2020-21 obtenida del NBA API.
SELECT t.full_name,
       COUNT(*) FILTER (WHERE s.points_per_game>=15) AS anotadores_15_pts,
       COUNT(*) FILTER (WHERE s.games_played>=40) AS jugadores_40_partidos,
       ROUND(AVG(s.points_per_game),2) AS pts_promedio_roster
FROM player_season_stat s JOIN team t USING(team_id)
WHERE s.season_id='2020-21'
GROUP BY t.team_id,t.full_name
ORDER BY anotadores_15_pts DESC,jugadores_40_partidos DESC;

-- E3.9 Produccion combinada de los cinco jugadores con mas puntos por equipo.
WITH ordenados AS (
    SELECT s.*,ROW_NUMBER() OVER(PARTITION BY team_id ORDER BY points_per_game DESC NULLS LAST) AS posicion
    FROM player_season_stat s WHERE season_id='2020-21'
)
SELECT t.full_name,ROUND(SUM(o.points_per_game),2) AS puntos_top5,
       ROUND(SUM(o.assists_per_game),2) AS asistencias_top5,
       ROUND(SUM(o.rebounds_per_game),2) AS rebotes_top5
FROM ordenados o JOIN team t USING(team_id)
WHERE o.posicion<=5 GROUP BY t.team_id,t.full_name
ORDER BY puntos_top5 DESC;

-- E3.10 Produccion 2020-21 de selecciones de primera ronda de 2016-2020.
SELECT t.full_name AS equipo_que_selecciono,
       COUNT(DISTINCT d.player_id) AS selecciones_productivas,
       ROUND(AVG(s.points_per_game),2) AS pts_promedio,
       ROUND(AVG(s.assists_per_game),2) AS ast_promedio,
       ROUND(AVG(s.rebounds_per_game),2) AS reb_promedio
FROM draft_selection d
JOIN team t ON t.team_id=d.team_id
JOIN player_season_stat s ON s.player_id=d.player_id AND s.season_id='2020-21'
WHERE d.draft_year BETWEEN 2016 AND 2020 AND d.round_number=1
GROUP BY t.team_id,t.full_name
ORDER BY selecciones_productivas DESC,pts_promedio DESC;

-- E3.11 Dependencia: participacion del maximo anotador en la suma de PPG del roster.
SELECT t.full_name,MAX(s.points_per_game) AS pts_lider,
       ROUND(SUM(s.points_per_game),2) AS pts_suma_roster,
       ROUND(100*MAX(s.points_per_game)/NULLIF(SUM(s.points_per_game),0),2) AS dependencia_pct
FROM player_season_stat s JOIN team t USING(team_id)
WHERE s.season_id='2020-21'
GROUP BY t.team_id,t.full_name
ORDER BY dependencia_pct ASC;

/* Componentes del indice. Valor combina eficiencia (60%) y ventaja de talento
   sobre nomina (40%). Crecimiento combina tendencia (60%) y produccion de
   selecciones recientes del draft (40%). */
CREATE TEMP VIEW e3_team_dimensions AS
WITH valor_base AS (
    SELECT s.team_id,s.victorias/NULLIF(ts.total_salary/1000000.0,0) AS eficiencia,
           ts.total_salary,MAX(p.pie) AS pie_estrella
    FROM e3_team_season s JOIN team_salary ts USING(team_id,season_id)
    LEFT JOIN player_salary ps ON ps.team_id=s.team_id AND ps.season_id=s.season_id
    LEFT JOIN player p ON p.player_id=ps.player_id
    WHERE s.season_id='2020-21'
    GROUP BY s.team_id,s.victorias,ts.total_salary
), valor_rank AS (
    SELECT v.*,
      RANK() OVER(ORDER BY total_salary DESC)-RANK() OVER(ORDER BY pie_estrella DESC NULLS LAST) AS ventaja
    FROM valor_base v
), draft AS (
    SELECT d.team_id,COUNT(DISTINCT d.player_id)*COALESCE(AVG(s.points_per_game),0) AS aporte_draft
    FROM draft_selection d LEFT JOIN player_season_stat s
      ON s.player_id=d.player_id AND s.season_id='2020-21'
    WHERE d.draft_year BETWEEN 2016 AND 2020 AND d.round_number=1 GROUP BY d.team_id
), raw AS (
    SELECT x.*,v.eficiencia,v.ventaja,COALESCE(d.aporte_draft,0) aporte_draft
    FROM e3_team_six x JOIN valor_rank v USING(team_id) LEFT JOIN draft d USING(team_id)
), n AS (
    SELECT raw.*,
      PERCENT_RANK() OVER(ORDER BY pct_promedio) n_record,
      PERCENT_RANK() OVER(ORDER BY margen_promedio) n_margen,
      PERCENT_RANK() OVER(ORDER BY piso_victorias) n_piso,
      PERCENT_RANK() OVER(ORDER BY eficiencia) n_eficiencia,
      PERCENT_RANK() OVER(ORDER BY ventaja) n_ventaja,
      PERCENT_RANK() OVER(ORDER BY tendencia) n_tendencia,
      PERCENT_RANK() OVER(ORDER BY aporte_draft) n_draft
    FROM raw
)
SELECT team_id,
       .50*n_record+.30*n_margen+.20*n_piso AS rendimiento,
       .60*n_eficiencia+.40*n_ventaja AS valor,
       .60*n_tendencia+.40*n_draft AS crecimiento
FROM n;

-- E3.12 Indice compuesto: rendimiento 40%, valor 35%, crecimiento 25%.
SELECT t.full_name,ROUND(d.rendimiento::numeric,4) AS rendimiento,
       ROUND(d.valor::numeric,4) AS valor,ROUND(d.crecimiento::numeric,4) AS crecimiento,
       ROUND((.40*d.rendimiento+.35*d.valor+.25*d.crecimiento)::numeric,4) AS indice_inversion
FROM e3_team_dimensions d JOIN team t USING(team_id)
ORDER BY indice_inversion DESC LIMIT 10;

-- E3.13 Sensibilidad con cuatro esquemas de ponderacion.
WITH escenarios(nombre,p_rendimiento,p_valor,p_crecimiento) AS (
    VALUES ('Mixto',.40,.35,.25),('Prioriza rendimiento',.60,.20,.20),
           ('Prioriza valor',.20,.60,.20),('Prioriza crecimiento',.20,.20,.60)
), puntuaciones AS (
    SELECT e.nombre,t.full_name,
      e.p_rendimiento*d.rendimiento+e.p_valor*d.valor+e.p_crecimiento*d.crecimiento AS indice
    FROM escenarios e CROSS JOIN e3_team_dimensions d JOIN team t USING(team_id)
), posiciones AS (
    SELECT *,RANK() OVER(PARTITION BY nombre ORDER BY indice DESC) AS posicion FROM puntuaciones
)
SELECT nombre,posicion,full_name,ROUND(indice::numeric,4) AS indice
FROM posiciones WHERE posicion<=5 ORDER BY nombre,posicion,full_name;
