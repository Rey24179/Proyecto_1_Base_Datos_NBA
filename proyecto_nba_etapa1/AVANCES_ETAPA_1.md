# Avances - Etapa 1

## Objetivo

Procesar los archivos CSV de NBA, construir una base de datos PostgreSQL e
incorporar al menos una ingesta adicional mediante NBA API.

## Trabajo completado

- Se inspeccionaron los 14 CSV entregados.
- Se identificaron 62,448 filas en `Game.csv` y 7,069 partidos correspondientes
  a las temporadas mínimas 2015/2016 a 2020/2021.
- Se detectaron 69 identificadores de partido duplicados.
- Se determinó que `Team.csv` contiene 30 equipos actuales, mientras que los
  partidos incluyen 45 identificadores de franquicias actuales e históricas.
- Se diseñó un modelo normalizado de 11 tablas.
- Se incorporó la entidad `season`, que permite comparar partidos y salarios
  de forma consistente.
- Se resolvió la relación muchos a muchos entre partidos y árbitros mediante
  `game_official`.
- Se creó el esquema de PostgreSQL con llaves primarias, llaves foráneas,
  restricciones e índices.
- Se desarrolló un programa de Python para leer directamente el ZIP, limpiar,
  transformar e insertar los datos.
- Se desarrolló una ingesta desde el endpoint `LeagueDashPlayerStats` de NBA
  API hacia `player_season_stat`.

## Decisiones de limpieza

1. Para identificadores de partidos repetidos se conserva la fila con más
   valores no nulos.
2. Los identificadores representados como decimales se convierten a enteros.
3. Las columnas de temporadas de `Team_Salary.csv` se transforman en filas.
4. Los salarios individuales se relacionan con jugadores por nombre normalizado;
   si un nombre es ambiguo se conserva el nombre y el identificador queda nulo.
5. El catálogo de equipos se completa con franquicias históricas encontradas en
   partidos y draft.
6. `News.csv` no se carga inicialmente porque pesa aproximadamente 772 MB y no
   es necesario para las preguntas obligatorias.

## Modelo construido

Las tablas principales son: `team`, `season`, `player`, `game`, `official`,
`game_official`, `team_salary`, `player_salary`, `draft_selection`,
`team_history` y `player_season_stat`.

## Próxima evidencia a obtener

- Ejecutar el esquema en PostgreSQL.
- Cargar el ZIP mediante `load_csv.py`.
- Ejecutar `verification.sql` y guardar capturas de los conteos.
- Ejecutar `load_api.py` para una temporada y verificar la tabla
  `player_season_stat`.
- Agregar el diagrama ER exportado como imagen al repositorio.

## Auditoría contra el enunciado completo

- Se agregó `database/analysis_queries.sql` con las 8 preguntas obligatorias y
  7 consultas propias, para un total de 15.
- Se añadieron controles de cobertura de temporadas y coherencia de resultados.
- La ingesta API ahora crea o actualiza temporadas, equipos y jugadores nuevos,
  lo que permite intentar la ampliación a 2025-26 sin violar llaves foráneas.
- Se agregó `documentation/INFORME_FINAL.md` como guía para documentar resultados
  reales sin inventar cifras.

