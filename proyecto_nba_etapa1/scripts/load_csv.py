import argparse
import re
import unicodedata
import zipfile
from pathlib import Path

import pandas as pd


def csv_from_zip(archive, filename, **kwargs):
    return pd.read_csv(archive.open(f"Data/{filename}"), low_memory=False, **kwargs)


def integer(value):
    if pd.isna(value):
        return None
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return None


def number(value):
    return None if pd.isna(value) else float(value)


def text(value):
    if pd.isna(value):
        return None
    value = str(value).strip()
    return value or None


def boolean(value):
    if pd.isna(value):
        return None
    return str(value).strip().lower() in {"1", "1.0", "true", "t", "yes", "y"}


def normalized_name(value):
    value = unicodedata.normalize("NFKD", str(value)).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]", "", value.lower())


def season_id(start_year):
    year = int(start_year)
    return f"{year}-{str(year + 1)[-2:]}"


def rows(df, columns):
    return [tuple(None if pd.isna(value) else value for value in row) for row in df[columns].itertuples(index=False, name=None)]


def insert_values(cursor, table, columns, values, conflict=""):
    if not values:
        return
    from psycopg2.extras import execute_values

    sql = f"INSERT INTO {table} ({', '.join(columns)}) VALUES %s {conflict}"
    execute_values(cursor, sql, values, page_size=2000)


def build_teams(archive, game, draft):
    base = csv_from_zip(archive, "Team.csv")
    attributes = csv_from_zip(archive, "Team_Attributes.csv")
    attributes.columns = attributes.columns.str.lower()
    base["id"] = base["id"].map(integer)
    attributes["id"] = attributes["id"].map(integer)
    teams = base.merge(attributes, on="id", how="left", suffixes=("", "_attr"))

    known_ids = set(teams["id"])
    historical = []
    game_home = game[["TEAM_ID_HOME", "TEAM_NAME_HOME", "TEAM_ABBREVIATION_HOME", "TEAM_CITY_NAME_HOME"]].copy()
    game_home.columns = ["id", "full_name", "abbreviation", "city"]
    game_away = game[["TEAM_ID_AWAY", "TEAM_NAME_AWAY", "TEAM_ABBREVIATION_AWAY", "TEAM_CITY_NAME_AWAY"]].copy()
    game_away.columns = ["id", "full_name", "abbreviation", "city"]
    source = pd.concat([game_home, game_away]).dropna(subset=["id"])
    source["id"] = source["id"].map(integer)
    source = source.sort_index().drop_duplicates("id", keep="last")
    for record in source.to_dict("records"):
        if record["id"] not in known_ids:
            historical.append(record)
            known_ids.add(record["id"])

    for record in draft.to_dict("records"):
        team_id = integer(record["idTeam"])
        if team_id not in known_ids:
            historical.append({
                "id": team_id,
                "full_name": record["nameTeam"],
                "abbreviation": record["slugTeam"],
                "city": record["cityTeam"],
            })
            known_ids.add(team_id)

    values = []
    for record in teams.to_dict("records"):
        values.append((
            record["id"], text(record.get("full_name")), text(record.get("abbreviation")),
            text(record.get("nickname")), text(record.get("city")), text(record.get("state")),
            integer(record.get("year_founded")), text(record.get("arena")), integer(record.get("arenacapacity")),
            text(record.get("owner")), text(record.get("generalmanager")), text(record.get("headcoach")), True,
        ))
    for record in historical:
        values.append((record["id"], text(record["full_name"]), text(record["abbreviation"]), None,
                       text(record["city"]), None, None, None, None, None, None, None, False))
    return values


def build_players(archive, draft):
    base = csv_from_zip(archive, "Player.csv")
    attributes = csv_from_zip(archive, "Player_Attributes.csv")
    attributes.columns = attributes.columns.str.lower()
    base["id"] = base["id"].map(integer)
    attributes["id"] = attributes["id"].map(integer)
    players = base.merge(attributes, on="id", how="outer", suffixes=("", "_attr"))
    values = []
    known = set()
    for record in players.to_dict("records"):
        player_id = integer(record["id"])
        known.add(player_id)
        full_name = text(record.get("full_name")) or text(record.get("display_first_last")) or "Unknown Player"
        current_team_id = integer(record.get("team_id"))
        if current_team_id is not None and current_team_id <= 0:
            current_team_id = None
        values.append((
            player_id, full_name, text(record.get("first_name")), text(record.get("last_name")),
            boolean(record.get("is_active")) or False, current_team_id,
            pd.to_datetime(record.get("birthdate"), errors="coerce").date() if pd.notna(record.get("birthdate")) else None,
            text(record.get("school")), text(record.get("country")), number(record.get("height")),
            number(record.get("weight")), text(record.get("position")), text(record.get("rosterstatus")),
            integer(record.get("from_year")), integer(record.get("to_year")), integer(record.get("draft_year")),
            text(record.get("draft_round")), text(record.get("draft_number")), number(record.get("pts")),
            number(record.get("ast")), number(record.get("reb")), number(record.get("all_star_appearances")),
            number(record.get("pie")),
        ))

    for record in draft.to_dict("records"):
        player_id = integer(record["idPlayer"])
        if player_id not in known:
            name = text(record["namePlayer"]) or "Unknown Player"
            first, _, last = name.partition(" ")
            values.append((player_id, name, first, last or None, False, None, None, None, None,
                           None, None, None, None, None, None, integer(record["yearDraft"]),
                           text(record["numberRound"]), text(record["numberPickOverall"]),
                           None, None, None, None, None))
            known.add(player_id)
    return values


def main(zip_path, reset, dry_run=False):
    if reset and not dry_run:
        from db import execute_schema

        execute_schema()

    with zipfile.ZipFile(zip_path) as archive:
        game = csv_from_zip(archive, "Game.csv")
        draft = csv_from_zip(archive, "Draft.csv")
        officials_source = csv_from_zip(archive, "Game_Officials.csv")
        salaries = csv_from_zip(archive, "Player_Salary.csv")
        team_salaries = csv_from_zip(archive, "Team_Salary.csv")
        history = csv_from_zip(archive, "Team_History.csv")

        team_values = build_teams(archive, game, draft)
        player_values = build_players(archive, draft)

        salary_seasons = set(salaries["slugSeason"].dropna().astype(str))
        salary_seasons.update(column[1:].replace(".", "-") for column in team_salaries.columns if column.startswith("X"))
        game_seasons = {season_id(year) for year in game["SEASON"].dropna().astype(int).unique()}
        all_seasons = sorted(salary_seasons | game_seasons)
        season_values = [(sid, int(sid[:4]), int(sid[:4]) + 1) for sid in all_seasons]

        game["nonnull_count"] = game.notna().sum(axis=1)
        game = game.sort_values("nonnull_count").drop_duplicates("GAME_ID", keep="last")
        game_values = []
        for record in game.to_dict("records"):
            game_values.append((
                str(record["GAME_ID"]).zfill(10), season_id(record["SEASON"]), pd.to_datetime(record["GAME_DATE"]).date(),
                integer(record["TEAM_ID_HOME"]), integer(record["TEAM_ID_AWAY"]), text(record["WL_HOME"]),
                text(record["WL_AWAY"]), integer(record["PTS_HOME"]), integer(record["PTS_AWAY"]),
                number(record["FG_PCT_HOME"]), number(record["FG_PCT_AWAY"]), number(record["FG3_PCT_HOME"]),
                number(record["FG3_PCT_AWAY"]), number(record["FT_PCT_HOME"]), number(record["FT_PCT_AWAY"]),
                integer(record["REB_HOME"]), integer(record["REB_AWAY"]), integer(record["AST_HOME"]),
                integer(record["AST_AWAY"]), integer(record["TOV_HOME"]), integer(record["TOV_AWAY"]),
                integer(record["ATTENDANCE"]),
            ))

        officials_source["OFFICIAL_ID"] = officials_source["OFFICIAL_ID"].map(integer)
        official_values = [(
            integer(record["OFFICIAL_ID"]), text(record["FIRST_NAME"]),
            text(record["LAST_NAME"]), text(record["JERSEY_NUM"])
        ) for record in officials_source.drop_duplicates("OFFICIAL_ID").to_dict("records")
           if integer(record["OFFICIAL_ID"]) is not None]
        valid_game_ids = {value[0] for value in game_values}
        game_official_values = []
        for record in officials_source.to_dict("records"):
            game_id = str(record["GAME_ID"]).zfill(10)
            if game_id in valid_game_ids:
                game_official_values.append((game_id, integer(record["OFFICIAL_ID"])))
        game_official_values = list(dict.fromkeys(game_official_values))

        team_by_abbr = {value[2]: value[0] for value in team_values if value[2]}
        team_by_name = {normalized_name(value[1]): value[0] for value in team_values}
        player_ids_by_name = {}
        for value in player_values:
            player_ids_by_name.setdefault(normalized_name(value[1]), []).append(value[0])

        team_salary_values = []
        salary_columns = [column for column in team_salaries.columns if column.startswith("X")]
        melted = team_salaries.melt(
            id_vars=["nameTeam", "slugTeam", "urlTeamSalaryHoopsHype"],
            value_vars=salary_columns, var_name="season", value_name="salary"
        )
        for record in melted.to_dict("records"):
            sid = record["season"][1:].replace(".", "-")
            team_id = team_by_abbr.get(text(record["slugTeam"]))
            if team_id and pd.notna(record["salary"]):
                team_salary_values.append((team_id, sid, number(record["salary"]), text(record["urlTeamSalaryHoopsHype"])))

        player_salary_values = []
        for record in salaries.to_dict("records"):
            team_id = team_by_name.get(normalized_name(record["nameTeam"]))
            matches = player_ids_by_name.get(normalized_name(record["namePlayer"]), [])
            player_id = matches[0] if len(matches) == 1 else None
            if team_id:
                player_salary_values.append((
                    player_id, text(record["namePlayer"]), team_id, text(record["slugSeason"]), number(record["value"]),
                    text(record["statusPlayer"]), text(record["typeContractDetail"]), boolean(record["isFinalSeason"]),
                    boolean(record["isWaived"]), boolean(record["isOnRoster"]), boolean(record["isNonGuaranteed"]),
                    boolean(record["isTeamOption"]), boolean(record["isPlayerOption"]),
                ))

        draft_values = [(
            integer(r["yearDraft"]), integer(r["numberPickOverall"]), integer(r["numberRound"]),
            integer(r["numberRoundPick"]), integer(r["idPlayer"]), text(r["namePlayer"]), integer(r["idTeam"]),
            text(r["nameOrganizationFrom"]), text(r["typeOrganizationFrom"])
        ) for r in draft.to_dict("records")]

        history_values = [(
            integer(r["ID"]), text(r["CITY"]), text(r["NICKNAME"]), integer(r["YEARFOUNDED"]),
            integer(r["YEARACTIVETILL"])
        ) for r in history.to_dict("records")]

    if not dry_run:
        from db import connect

        with connect() as connection:
            with connection.cursor() as cursor:
                insert_values(cursor, "team", ["team_id", "full_name", "abbreviation", "nickname", "city", "state",
                          "year_founded", "arena", "arena_capacity", "owner_name", "general_manager", "head_coach", "is_current"], team_values)
                insert_values(cursor, "season", ["season_id", "start_year", "end_year"], season_values)
                insert_values(cursor, "player", ["player_id", "full_name", "first_name", "last_name", "is_active",
                          "current_team_id", "birthdate", "school", "country", "height_inches", "weight_lbs", "position",
                          "roster_status", "from_year", "to_year", "draft_year", "draft_round", "draft_number", "career_pts",
                          "career_ast", "career_reb", "all_star_appearances", "pie"], player_values)
                insert_values(cursor, "game", ["game_id", "season_id", "game_date", "home_team_id", "away_team_id", "home_result",
                          "away_result", "home_points", "away_points", "home_fg_pct", "away_fg_pct", "home_three_pct",
                          "away_three_pct", "home_ft_pct", "away_ft_pct", "home_rebounds", "away_rebounds", "home_assists",
                          "away_assists", "home_turnovers", "away_turnovers", "attendance"], game_values)
                insert_values(cursor, "official", ["official_id", "first_name", "last_name", "jersey_number"], official_values)
                insert_values(cursor, "game_official", ["game_id", "official_id"], game_official_values)
                insert_values(cursor, "team_salary", ["team_id", "season_id", "total_salary", "source_url"], team_salary_values)
                insert_values(cursor, "player_salary", ["player_id", "player_name", "team_id", "season_id", "salary_value",
                          "player_status", "contract_detail", "is_final_season", "is_waived", "is_on_roster",
                          "is_non_guaranteed", "is_team_option", "is_player_option"], player_salary_values)
                insert_values(cursor, "draft_selection", ["draft_year", "overall_pick", "round_number", "round_pick", "player_id",
                          "player_name", "team_id", "organization_from", "organization_type"], draft_values)
                insert_values(cursor, "team_history", ["team_id", "city", "nickname", "active_from", "active_until"], history_values)

    print("Validación de transformación completada." if dry_run else "Carga completada correctamente.")
    print(f"Equipos: {len(team_values)} | Jugadores: {len(player_values)} | Partidos: {len(game_values)}")
    print(f"Árbitros: {len(official_values)} | Salarios de jugadores: {len(player_salary_values)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Carga y normaliza los CSV de NBA en PostgreSQL.")
    parser.add_argument("--zip", default="data/Data.zip", help="Ruta del ZIP entregado en Canvas.")
    parser.add_argument("--no-reset", action="store_true", help="No volver a crear el esquema.")
    parser.add_argument("--dry-run", action="store_true", help="Transformar y validar sin conectarse a PostgreSQL.")
    args = parser.parse_args()
    main(Path(args.zip), reset=not args.no_reset, dry_run=args.dry_run)
