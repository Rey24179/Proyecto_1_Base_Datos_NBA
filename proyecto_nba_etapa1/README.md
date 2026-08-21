# Proyecto NBA - Etapa 1

Proyecto de CC3088 Base de Datos 1 para diseñar, construir y alimentar una base
de datos PostgreSQL utilizando los CSV proporcionados y una ingesta desde NBA API.

## Requisitos

- Python 3.11 o superior
- PostgreSQL 15 o superior
- Git
- Docker Desktop, opcional

## Estructura

```text
proyecto_nba_etapa1/
├── data/                       # Aquí se coloca Data.zip
├── database/
│   ├── schema.sql              # Creación del modelo
│   ├── verification.sql        # Comprobaciones de calidad
│   └── preview_queries.sql      # Consultas preliminares
├── diagrams/
│   └── modelo_er.md             # Diagrama Mermaid
├── scripts/
│   ├── db.py                    # Conexión a PostgreSQL
│   ├── load_csv.py              # Limpieza y carga de CSV
│   └── load_api.py              # Ingesta desde NBA API
├── .env.example
├── docker-compose.yml
├── requirements.txt
└── AVANCES_ETAPA_1.md
```

## Instalación rápida en Windows

### 1. Crear el entorno virtual

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configurar las variables

Copie `.env.example` como `.env` y escriba la contraseña real de PostgreSQL.
No suba `.env` a GitHub.

```powershell
Copy-Item .env.example .env
```

### 3. Iniciar PostgreSQL

Opción A: crear manualmente una base llamada `nba_project` desde pgAdmin.

Opción B: utilizar Docker:

```powershell
docker compose up -d
```

### 4. Colocar los datos

Copie el ZIP entregado en Canvas a `data/Data.zip`. No es necesario descomprimirlo.

### 5. Crear las tablas y cargar los CSV

Primero puede validar las transformaciones sin conectarse a PostgreSQL:

```powershell
python scripts/load_csv.py --zip data/Data.zip --dry-run
```

Después realice la carga definitiva:

```powershell
python scripts/load_csv.py --zip data/Data.zip
```

Este comando vuelve a crear las tablas. Para ejecutar una carga sin reconstruir
el esquema use `--no-reset` solamente cuando sea necesario.

### 6. Verificar la carga

Abra `database/verification.sql` en pgAdmin y ejecute sus consultas. Las
consultas de duplicados y registros huérfanos deben devolver cero filas.

### 7. Ejecutar la ingesta de NBA API

```powershell
python scripts/load_api.py --season 2020-21
```

La información se guarda en `player_season_stat`. El script puede repetirse sin
duplicar registros porque utiliza una actualización mediante `ON CONFLICT`.

## Modelo de datos

El modelo completo se encuentra en `diagrams/modelo_er.md`. Las relaciones más
importantes son:

- Una temporada contiene muchos partidos.
- Cada partido tiene un equipo local y un equipo visitante.
- Un equipo y un jugador pueden tener salarios en varias temporadas.
- Partido y árbitro tienen una relación muchos a muchos.
- Las estadísticas de NBA API se identifican por jugador, equipo y temporada.

## Calidad de los datos

- `Game.csv` contiene 69 identificadores repetidos. Se conserva el registro con
  mayor cantidad de valores disponibles.
- `Team_Salary.csv` viene en formato ancho y se normaliza a una fila por equipo
  y temporada.
- `Player_Salary.csv` no incluye `player_id`; el cargador intenta relacionarlo
  mediante el nombre normalizado y conserva el nombre cuando existe ambigüedad.
- Se excluye inicialmente `News.csv` por tamaño y baja relevancia para las
  consultas obligatorias.

## Flujo de trabajo colaborativo

Cada integrante debe trabajar en una rama y realizar commits propios. Ejemplo:

```bash
git checkout -b feature/carga-csv
git add .
git commit -m "Implementar carga y limpieza de CSV"
git push -u origin feature/carga-csv
```
