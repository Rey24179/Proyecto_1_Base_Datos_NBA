# Proyecto NBA - Etapa 1

Proyecto de CC3088 Base de Datos 1 para diseñar, construir y alimentar una base
de datos PostgreSQL utilizando los CSV proporcionados y una ingesta desde NBA API.

## Requisitos

- Python 3.11 a 3.13 (las dependencias fijadas no son compatibles con Python 3.14)
- PostgreSQL 15 o superior instalado localmente
- Git

## Instalación rápida en Windows

### 1. Crear el entorno virtual

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
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

Copie el ZIP entregado en Canvas a `data/Data.zip`. No es necesario descomprimirlo.

### 5. Crear las tablas y cargar los CSV

Todos los comandos del proyecto se ejecutan con Python. Primero puede validar
las transformaciones sin conectarse a PostgreSQL:

```powershell
python scripts/load_csv.py --zip data/Data.zip --dry-run
```

Después realice la carga definitiva:

```powershell
python scripts/load_csv.py --zip data/Data.zip
```

Este comando vuelve a crear las tablas. Para ejecutar una carga sin reconstruir
el esquema use `--no-reset` solamente cuando sea necesario.

### 6. Verificar la carga y ejecutar el análisis

Abra `database/verification.sql` en pgAdmin y ejecute sus consultas. Las
consultas de duplicados y registros huérfanos deben devolver cero filas.

Después ejecute `database/analysis_queries.sql` para las 8 preguntas
obligatorias. El archivo conserva además algunas consultas exploratorias,
incluyendo agrupaciones, joins y subconsultas.

Para la Etapa 3 ejecute completo `database/stage3_queries.sql` en una misma
sesión de pgAdmin. Contiene las 13 preguntas propias, el índice de inversión y
el análisis de sensibilidad. Los resultados ejecutados y su interpretación se
encuentran en `documentation/Fase_3_queries.pdf` y
`documentation/JUSTIFICACION_ETAPA_3.md`.

### 7. Ejecutar la ingesta de NBA API

```powershell
python scripts/load_api.py --season 2020-21
```

La información se guarda en `player_season_stat`. El script puede repetirse sin
duplicar registros porque utiliza una actualización mediante `ON CONFLICT`.
La carga también restaura los nombres completos de los equipos usando el
catálogo incluido en `nba_api`, evitando que queden sustituidos por abreviaturas.

La consulta 7 utiliza esta ingesta. Si el API no responde durante la
demostración, documente el intento y conserve evidencia de una ejecución previa.

## Modelo de datos

El modelo completo se encuentra en `diagrams/er_diagram.png`. También se
incluye una versión con notación de Chen en `diagrams/der_chen.png`. Las
relaciones más importantes son:

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

## Lista de entrega

- `database/schema.sql`: creación reproducible de la base.
- `scripts/load_csv.py`: limpieza y carga de CSV.
- `scripts/load_api.py`: ingesta oficial del NBA API.
- `database/verification.sql`: controles de integridad y cobertura.
- `database/analysis_queries.sql`: las 15 consultas requeridas.
- `database/stage3_queries.sql`: análisis completo y recomendación de Etapa 3.
- `documentation/Fase_3_queries.pdf`: evidencia de ejecución de las 13 consultas.
- `documentation/JUSTIFICACION_ETAPA_3.md`: interpretación y recomendación.
- `diagrams/er_diagram.png` y `diagrams/der_chen.png`: diagramas ER exportados.
- PDF final con preguntas, SQL, resultados reales, problemas de calidad y
  justificación de la recomendación de inversión.

## Flujo de trabajo colaborativo

Cada integrante debe trabajar en una rama y realizar commits propios. Ejemplo:

```bash
git checkout -b feature/carga-csv
git add .
git commit -m "Implementar carga y limpieza de CSV"
git push -u origin feature/carga-csv
```
