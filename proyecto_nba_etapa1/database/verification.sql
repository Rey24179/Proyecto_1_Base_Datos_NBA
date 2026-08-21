-- Conteos básicos después de ejecutar la carga.
SELECT 'team' AS table_name, COUNT(*) AS rows FROM team
UNION ALL SELECT 'season', COUNT(*) FROM season
UNION ALL SELECT 'player', COUNT(*) FROM player
UNION ALL SELECT 'game', COUNT(*) FROM game
UNION ALL SELECT 'official', COUNT(*) FROM official
UNION ALL SELECT 'game_official', COUNT(*) FROM game_official
UNION ALL SELECT 'team_salary', COUNT(*) FROM team_salary
UNION ALL SELECT 'player_salary', COUNT(*) FROM player_salary
UNION ALL SELECT 'draft_selection', COUNT(*) FROM draft_selection
UNION ALL SELECT 'team_history', COUNT(*) FROM team_history
UNION ALL SELECT 'player_season_stat', COUNT(*) FROM player_season_stat
ORDER BY table_name;

-- No deben existir partidos con el mismo identificador.
SELECT game_id, COUNT(*)
FROM game
GROUP BY game_id
HAVING COUNT(*) > 1;

-- No deben existir relaciones huérfanas de árbitros.
SELECT go.*
FROM game_official go
LEFT JOIN game g ON g.game_id = go.game_id
LEFT JOIN official o ON o.official_id = go.official_id
WHERE g.game_id IS NULL OR o.official_id IS NULL;

-- Temporadas mínimas requeridas para el proyecto.
SELECT season_id, COUNT(*) AS games
FROM game
WHERE CAST(SUBSTRING(season_id FROM 1 FOR 4) AS INTEGER) BETWEEN 2015 AND 2020
GROUP BY season_id
ORDER BY season_id;

-- Deben existir las seis temporadas minimas; debe devolver cero filas.
WITH requeridas AS (SELECT generate_series(2015, 2020) AS start_year)
SELECT r.start_year
FROM requeridas r LEFT JOIN season s ON s.start_year=r.start_year
LEFT JOIN game g ON g.season_id=s.season_id
GROUP BY r.start_year HAVING COUNT(g.game_id)=0;

-- Resultados incoherentes; debe devolver cero filas.
SELECT game_id,home_points,away_points,home_result,away_result
FROM game WHERE home_points<0 OR away_points<0
 OR (home_result=away_result AND home_result IN ('W','L'));

-- Cobertura salarial necesaria para las consultas 4 y 8.
SELECT season_id,COUNT(DISTINCT team_id) AS teams
FROM team_salary WHERE season_id IN ('2020-21','2021-22')
GROUP BY season_id ORDER BY season_id;

