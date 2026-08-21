import argparse
import math

from nba_api.stats.endpoints import leaguedashplayerstats
from psycopg2.extras import execute_values

from db import connect


def clean(value):
    if value is None or (isinstance(value, float) and math.isnan(value)):
        return None
    return value


def load_season(season):
    response = leaguedashplayerstats.LeagueDashPlayerStats(
        season=season,
        season_type_all_star="Regular Season",
        per_mode_detailed="PerGame",
        timeout=60,
    )
    data = response.get_data_frames()[0]

    rows = []
    teams = {}
    players = {}
    for record in data.to_dict("records"):
        if int(record["TEAM_ID"]) == 0:
            continue
        team_id = int(record["TEAM_ID"])
        player_id = int(record["PLAYER_ID"])
        teams[team_id] = (team_id, record.get("TEAM_NAME") or record.get("TEAM_ABBREVIATION") or "Equipo NBA",
                          record.get("TEAM_ABBREVIATION"))
        players[player_id] = (player_id, record.get("PLAYER_NAME") or f"Jugador {player_id}", team_id)
        rows.append((
            player_id, team_id, season,
            clean(record.get("GP")), clean(record.get("MIN")), clean(record.get("PTS")),
            clean(record.get("AST")), clean(record.get("REB")), clean(record.get("STL")),
            clean(record.get("BLK")), clean(record.get("TOV")), clean(record.get("FG_PCT")),
            clean(record.get("FG3_PCT")), clean(record.get("FT_PCT")),
        ))

    sql = """
        INSERT INTO player_season_stat (
            player_id, team_id, season_id, games_played, minutes_per_game,
            points_per_game, assists_per_game, rebounds_per_game,
            steals_per_game, blocks_per_game, turnovers_per_game,
            fg_pct, three_pct, ft_pct
        ) VALUES %s
        ON CONFLICT (player_id, team_id, season_id) DO UPDATE SET
            games_played = EXCLUDED.games_played,
            minutes_per_game = EXCLUDED.minutes_per_game,
            points_per_game = EXCLUDED.points_per_game,
            assists_per_game = EXCLUDED.assists_per_game,
            rebounds_per_game = EXCLUDED.rebounds_per_game,
            steals_per_game = EXCLUDED.steals_per_game,
            blocks_per_game = EXCLUDED.blocks_per_game,
            turnovers_per_game = EXCLUDED.turnovers_per_game,
            fg_pct = EXCLUDED.fg_pct,
            three_pct = EXCLUDED.three_pct,
            ft_pct = EXCLUDED.ft_pct,
            loaded_at = CURRENT_TIMESTAMP
    """
    start_year = int(season[:4])
    with connect() as connection:
        with connection.cursor() as cursor:
            # La API puede contener jugadores/equipos posteriores a los CSV de 2021.
            execute_values(cursor, """
                INSERT INTO team (team_id, full_name, abbreviation)
                VALUES %s ON CONFLICT (team_id) DO UPDATE SET
                    full_name=EXCLUDED.full_name, abbreviation=EXCLUDED.abbreviation
            """, list(teams.values()))
            cursor.execute("""
                INSERT INTO season (season_id,start_year,end_year) VALUES (%s,%s,%s)
                ON CONFLICT (season_id) DO NOTHING
            """, (season, start_year, start_year + 1))
            execute_values(cursor, """
                INSERT INTO player (player_id,full_name,current_team_id,is_active)
                VALUES %s ON CONFLICT (player_id) DO UPDATE SET
                    full_name=EXCLUDED.full_name, current_team_id=EXCLUDED.current_team_id,
                    is_active=TRUE
            """, [(p[0], p[1], p[2], True) for p in players.values()])
            execute_values(cursor, sql, rows, page_size=1000)
    print(f"NBA API: {len(rows)} estadísticas cargadas para {season}.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingesta de estadísticas desde NBA API.")
    parser.add_argument("--season", default="2020-21", help="Temporada con formato 2020-21.")
    args = parser.parse_args()
    load_season(args.season)
