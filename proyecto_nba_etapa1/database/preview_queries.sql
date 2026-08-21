-- 1. Jugador activo más alto y más bajo (consulta preliminar).
(SELECT 'Más alto' AS category, player_id, full_name, height_inches
 FROM player
 WHERE is_active = TRUE AND height_inches IS NOT NULL
 ORDER BY height_inches DESC
 LIMIT 1)
UNION ALL
(SELECT 'Más bajo', player_id, full_name, height_inches
 FROM player
 WHERE is_active = TRUE AND height_inches IS NOT NULL
 ORDER BY height_inches ASC
 LIMIT 1);

-- 2. Cantidad de partidos cargados en las seis temporadas mínimas.
SELECT season_id, COUNT(*) AS games
FROM game
WHERE CAST(SUBSTRING(season_id FROM 1 FOR 4) AS INTEGER) BETWEEN 2015 AND 2020
GROUP BY season_id
ORDER BY season_id;

-- 3. Salario total por equipo y temporada.
SELECT s.season_id, t.full_name, s.total_salary
FROM team_salary s
JOIN team t ON t.team_id = s.team_id
ORDER BY s.season_id, s.total_salary DESC;

