# Proyecto NBA - CC3088 Base de Datos 1

Diseño, construcción y análisis de una base de datos PostgreSQL a partir de los
CSV de la NBA proporcionados por el curso, complementada con una ingesta desde
el API oficial de la liga.

**Pregunta de negocio:** ¿en qué equipo invertir para la temporada 2021/2022?
**Respuesta:** Utah Jazz. La justificación completa está en el informe final.

## Requisitos

- Python 3.11 o superior
- PostgreSQL 15 o superior instalado localmente
- Git

## Instalación rápida en Windows

### 1. Crear el entorno virtual

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

Si PowerShell bloquea la activación con un error de directivas de ejecución,
ejecute una sola vez:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 2. Configurar las variables

Copie `.env.example` como `.env`:

```powershell
Copy-Item .env.example .env
```

Abra `.env` y reemplace el valor de `DB_PASSWORD` con la contraseña real del
usuario `postgres`. Debe ser exactamente la misma contraseña utilizada para
conectarse al servidor PostgreSQL desde pgAdmin; no deje la contraseña de
ejemplo.

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=nba_project
DB_USER=postgres
DB_PASSWORD=SU_CONTRASEÑA_REAL_DE_POSTGRES
NBA_SEASON=2020-21
```

Si la contraseña no coincide, `load_csv.py` no podrá conectarse y la carga
fallará con un error de autenticación o conexión. No suba `.env` a GitHub,
porque contiene información privada.

### 3. Preparar PostgreSQL local

Inicie el servicio local de PostgreSQL y cree una base llamada `nba_project`
desde pgAdmin. Compruebe que los datos de acceso coincidan con los valores de
su archivo `.env`.

### 4. Colocar los datos

Copie el ZIP entregado en Canvas a `data/Data.zip`. No es necesario
descomprimirlo. El ZIP debe conservar su carpeta interna `Data/`.

### 5. Crear las tablas y cargar los CSV

Primero valide las transformaciones sin conectarse a PostgreSQL:

```powershell
python scripts/load_csv.py --zip data/Data.zip --dry-run
```

Salida esperada:

```text
Equipos: 45 | Jugadores: 8996 | Partidos: 62379
Árbitros: 143 | Salarios de jugadores: 1292
```

Después realice la carga definitiva:

```powershell
python scripts/load_csv.py --zip data/Data.zip
```

Este comando vuelve a crear las tablas, por lo que puede repetirse sin acumular
duplicados. Para cargar sin reconstruir el esquema use `--no-reset`.

### 6. Ejecutar la ingesta de NBA API

```powershell
python scripts/load_api.py --season 2020-21
```

La información se guarda en `player_season_stat`. El script puede repetirse sin
duplicar registros porque utiliza una actualización mediante `ON CONFLICT`.

La consulta 7 de la Etapa 2 y las consultas E3.8 a E3.11 de la Etapa 3 dependen
de esta ingesta. Si el API no responde durante la demostración, documente el
intento y conserve evidencia de una ejecución previa.

### 7. Verificar la carga

Abra `database/verification.sql` en pgAdmin y ejecute sus consultas. Los cuatro
controles de integridad deben devolver cero filas.

**Comprobación crítica:** la última consulta debe reportar **30 equipos** con
nómina en 2020-21 y 2021-22. Si reporta 29, la corrección de abreviaturas
descrita en la sección de calidad de datos no está aplicada.

### 8. Ejecutar el análisis

```text
database/analysis_queries.sql   ->  las 8 preguntas obligatorias (Etapa 2)
database/stage3_queries.sql     ->  las 13 preguntas propias (Etapa 3)
```

`stage3_queries.sql` crea la vista `analysis_team_season` al inicio, por lo que
debe ejecutarse completo y no por fragmentos aislados.

## Modelo de datos

El diagrama Entidad-Relación se encuentra en `diagrams/er_diagram.png`. Las
relaciones más importantes son:

- Una temporada contiene muchos partidos.
- Cada partido tiene un equipo local y un equipo visitante.
- Un equipo y un jugador pueden tener salarios en varias temporadas.
- Partido y árbitro tienen una relación muchos a muchos, resuelta con la tabla
  puente `game_official`.
- Las estadísticas de NBA API se identifican por jugador, equipo y temporada.

## Calidad de los datos

Los ocho hallazgos están documentados con detalle en `AVANCES_ETAPA_1.md` y en
el informe final. Resumen:

- `Player_Attributes.csv` usa `TEAM_ID = 0` como marcador de "sin equipo" en
  lugar de un valor nulo. Afecta a 664 jugadores y viola la llave foránea si no
  se convierte a `NULL`.
- `Team_Salary.csv` abrevia a Phoenix como `PHO` mientras que `Team.csv` usa
  `PHX`, lo que descartaba silenciosamente su nómina.
- Los Washington Wizards comparten la abreviatura `WAS` con los Washington
  Capitols, franquicia extinta en 1951. La nómina se resuelve por nombre
  completo priorizando equipos vigentes.
- `Game.csv` contiene 69 identificadores repetidos. Se conserva el registro con
  mayor cantidad de valores disponibles.
- `Team.state` tiene errores: Atlanta aparece con estado "Atlanta" y Toronto con
  "Ontario", que no es un estado de Estados Unidos.
- `Game_Officials.csv` solo cubre partidos desde 1996 (21,711 de 62,379).
- `all_star_appearances` solo tiene datos para 3 de los 523 jugadores con
  salario en 2020-21. Se utiliza PIE como medida de valor.
- `Player_Salary.csv` no incluye `player_id`; se relaciona por nombre
  normalizado con una resolución del 93.2%.

**Alcance:** el conjunto de datos contiene únicamente temporada regular. No hay
partidos de playoffs ni de pretemporada.

**Archivos excluidos:** `News.csv` por tamaño (772 MB) y falta de relación con
las métricas escogidas. `Game_Inactive_Players.csv` y `Draft_Combine.csv` por
decisión de alcance, ya que las preguntas planteadas no requieren información de
jugadores inactivos por partido ni mediciones de combine.

## Convenciones de interpretación

| Término | Definición adoptada |
|---|---|
| "Temporada 2017" | 2017-18. Las temporadas se nombran por su año de inicio. |
| "Temporada 2018" | 2018-19. |
| "Última temporada" | 2020-21, la última temporada completa en `Game.csv`. |
| "Jugador activo" | Marcado en `Player.csv` o presente en la ingesta del API de 2020-21. |

## Lista de entrega

- `diagrams/er_diagram.png`: diagrama Entidad-Relación.
- `database/schema.sql`: creación reproducible de la base.
- `scripts/load_csv.py`: limpieza y carga de los CSV.
- `scripts/load_api.py`: ingesta oficial del NBA API.
- `database/verification.sql`: controles de integridad y cobertura.
- `database/analysis_queries.sql`: las 8 preguntas obligatorias.
- `database/stage3_queries.sql`: las 13 preguntas propias.
- `AVANCES_ETAPA_1.md`: hallazgos de calidad de datos y decisiones de diseño.
- `documentation/INFORME_FINAL.pdf`: informe con preguntas, SQL, resultados,
  problemas de calidad y justificación de la recomendación de inversión.

## Flujo de trabajo colaborativo

Cada integrante debe trabajar en una rama y realizar commits propios:

```bash
git checkout -b feature/carga-csv
git add .
git commit -m "Implementar carga y limpieza de CSV"
git push -u origin feature/carga-csv
```

El entorno virtual no debe versionarse. `.gitignore` incluye el patrón
`.venv*/` para cubrir cualquier variante de nombre.
