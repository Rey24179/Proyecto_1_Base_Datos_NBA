import argparse

from nba_api.stats.endpoints import leaguedashplayerstats
from psycopg2.extras import execute_values

from db import connect


def clean(value):
    return None if value is None else value


def load_season(season):
    response = leaguedashplayerstats.LeagueDashPlayerStats(
        season=season,
        season_type_all_star="Regular Season",
        per_mode_detailed="PerGame",
        timeout=60,
    )
    data = response.get_data_frames()[0]

    rows = []
    for record in data.to_dict("records"):
        if int(record["TEAM_ID"]) == 0:
            continue
        rows.append((
            int(record["PLAYER_ID"]), int(record["TEAM_ID"]), season,
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
    with connect() as connection:
        with connection.cursor() as cursor:
            execute_values(cursor, sql, rows, page_size=1000)
    print(f"NBA API: {len(rows)} estadísticas cargadas para {season}.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingesta de estadísticas desde NBA API.")
    parser.add_argument("--season", default="2020-21", help="Temporada con formato 2020-21.")
    args = parser.parse_args()
    load_season(args.season)
