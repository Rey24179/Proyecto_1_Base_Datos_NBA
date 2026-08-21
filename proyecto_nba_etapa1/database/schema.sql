BEGIN;

DROP TABLE IF EXISTS player_season_stat CASCADE;
DROP TABLE IF EXISTS game_official CASCADE;
DROP TABLE IF EXISTS official CASCADE;
DROP TABLE IF EXISTS player_salary CASCADE;
DROP TABLE IF EXISTS team_salary CASCADE;
DROP TABLE IF EXISTS draft_selection CASCADE;
DROP TABLE IF EXISTS team_history CASCADE;
DROP TABLE IF EXISTS game CASCADE;
DROP TABLE IF EXISTS player CASCADE;
DROP TABLE IF EXISTS season CASCADE;
DROP TABLE IF EXISTS team CASCADE;

CREATE TABLE team (
    team_id BIGINT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    abbreviation VARCHAR(10),
    nickname VARCHAR(60),
    city VARCHAR(60),
    state VARCHAR(60),
    year_founded SMALLINT,
    arena VARCHAR(100),
    arena_capacity INTEGER,
    owner_name VARCHAR(100),
    general_manager VARCHAR(100),
    head_coach VARCHAR(100),
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE season (
    season_id VARCHAR(7) PRIMARY KEY,
    start_year SMALLINT NOT NULL,
    end_year SMALLINT NOT NULL,
    CONSTRAINT ck_season_years CHECK (end_year = start_year + 1)
);

CREATE TABLE player (
    player_id BIGINT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    first_name VARCHAR(60),
    last_name VARCHAR(60),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    current_team_id BIGINT REFERENCES team(team_id),
    birthdate DATE,
    school VARCHAR(120),
    country VARCHAR(80),
    height_inches NUMERIC(5,2),
    weight_lbs NUMERIC(6,2),
    position VARCHAR(50),
    roster_status VARCHAR(30),
    from_year SMALLINT,
    to_year SMALLINT,
    draft_year SMALLINT,
    draft_round VARCHAR(10),
    draft_number VARCHAR(10),
    career_pts NUMERIC(8,2),
    career_ast NUMERIC(8,2),
    career_reb NUMERIC(8,2),
    all_star_appearances NUMERIC(5,1),
    pie NUMERIC(8,4)
);

CREATE TABLE game (
    game_id VARCHAR(20) PRIMARY KEY,
    season_id VARCHAR(7) NOT NULL REFERENCES season(season_id),
    game_date DATE NOT NULL,
    home_team_id BIGINT NOT NULL REFERENCES team(team_id),
    away_team_id BIGINT NOT NULL REFERENCES team(team_id),
    home_result CHAR(1),
    away_result CHAR(1),
    home_points SMALLINT,
    away_points SMALLINT,
    home_fg_pct NUMERIC(6,4),
    away_fg_pct NUMERIC(6,4),
    home_three_pct NUMERIC(6,4),
    away_three_pct NUMERIC(6,4),
    home_ft_pct NUMERIC(6,4),
    away_ft_pct NUMERIC(6,4),
    home_rebounds SMALLINT,
    away_rebounds SMALLINT,
    home_assists SMALLINT,
    away_assists SMALLINT,
    home_turnovers SMALLINT,
    away_turnovers SMALLINT,
    attendance INTEGER,
    CONSTRAINT ck_different_teams CHECK (home_team_id <> away_team_id)
);

CREATE TABLE official (
    official_id BIGINT PRIMARY KEY,
    first_name VARCHAR(60),
    last_name VARCHAR(60),
    jersey_number VARCHAR(10)
);

CREATE TABLE game_official (
    game_id VARCHAR(20) NOT NULL REFERENCES game(game_id) ON DELETE CASCADE,
    official_id BIGINT NOT NULL REFERENCES official(official_id),
    PRIMARY KEY (game_id, official_id)
);

CREATE TABLE team_salary (
    team_id BIGINT NOT NULL REFERENCES team(team_id),
    season_id VARCHAR(7) NOT NULL REFERENCES season(season_id),
    total_salary NUMERIC(15,2) NOT NULL CHECK (total_salary >= 0),
    source_url TEXT,
    PRIMARY KEY (team_id, season_id)
);

CREATE TABLE player_salary (
    player_salary_id BIGSERIAL PRIMARY KEY,
    player_id BIGINT REFERENCES player(player_id),
    player_name VARCHAR(120) NOT NULL,
    team_id BIGINT NOT NULL REFERENCES team(team_id),
    season_id VARCHAR(7) NOT NULL REFERENCES season(season_id),
    salary_value NUMERIC(15,2) NOT NULL CHECK (salary_value >= 0),
    player_status VARCHAR(50),
    contract_detail VARCHAR(80),
    is_final_season BOOLEAN,
    is_waived BOOLEAN,
    is_on_roster BOOLEAN,
    is_non_guaranteed BOOLEAN,
    is_team_option BOOLEAN,
    is_player_option BOOLEAN,
    UNIQUE (season_id, team_id, player_name)
);

CREATE TABLE draft_selection (
    draft_selection_id BIGSERIAL PRIMARY KEY,
    draft_year SMALLINT NOT NULL,
    overall_pick SMALLINT,
    round_number SMALLINT,
    round_pick SMALLINT,
    player_id BIGINT REFERENCES player(player_id),
    player_name VARCHAR(120) NOT NULL,
    team_id BIGINT NOT NULL REFERENCES team(team_id),
    organization_from VARCHAR(150),
    organization_type VARCHAR(80)
);

CREATE TABLE team_history (
    team_history_id BIGSERIAL PRIMARY KEY,
    team_id BIGINT NOT NULL REFERENCES team(team_id),
    city VARCHAR(80) NOT NULL,
    nickname VARCHAR(80) NOT NULL,
    active_from SMALLINT NOT NULL,
    active_until SMALLINT,
    UNIQUE (team_id, city, nickname, active_from)
);

CREATE TABLE player_season_stat (
    player_id BIGINT NOT NULL REFERENCES player(player_id),
    team_id BIGINT NOT NULL REFERENCES team(team_id),
    season_id VARCHAR(7) NOT NULL REFERENCES season(season_id),
    games_played SMALLINT,
    minutes_per_game NUMERIC(7,2),
    points_per_game NUMERIC(7,2),
    assists_per_game NUMERIC(7,2),
    rebounds_per_game NUMERIC(7,2),
    steals_per_game NUMERIC(7,2),
    blocks_per_game NUMERIC(7,2),
    turnovers_per_game NUMERIC(7,2),
    fg_pct NUMERIC(7,4),
    three_pct NUMERIC(7,4),
    ft_pct NUMERIC(7,4),
    source VARCHAR(40) NOT NULL DEFAULT 'NBA API',
    loaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (player_id, team_id, season_id)
);

CREATE INDEX idx_game_season ON game(season_id);
CREATE INDEX idx_game_home_team ON game(home_team_id);
CREATE INDEX idx_game_away_team ON game(away_team_id);
CREATE INDEX idx_player_current_team ON player(current_team_id);
CREATE INDEX idx_player_salary_season ON player_salary(season_id);
CREATE INDEX idx_player_salary_team ON player_salary(team_id);
CREATE INDEX idx_draft_year ON draft_selection(draft_year);

COMMIT;

