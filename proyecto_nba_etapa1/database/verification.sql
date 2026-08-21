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

