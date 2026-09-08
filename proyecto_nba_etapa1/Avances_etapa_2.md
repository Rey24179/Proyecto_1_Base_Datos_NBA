# Evidencia consolidada - Etapa 1

## Objetivo

Procesar los archivos CSV de NBA, construir una base de datos PostgreSQL e
incorporar al menos una ingesta adicional mediante NBA API.

## Estado: COMPLETADA

La carga se ejecutó contra PostgreSQL, `verification.sql` pasa todos los
controles y la ingesta desde NBA API está funcionando. La evidencia de
ejecución está en `documentation/`.

---

## 1. Trabajo realizado

- Se inspeccionaron los 14 CSV entregados.
- Se identificaron 62,448 filas en `Game.csv`, de las cuales 7,059
  corresponden a las temporadas mínimas 2015/2016 a 2020/2021.
- Se diseñó un modelo normalizado de 11 tablas.
- Se incorporó la entidad `season`, que permite relacionar partidos y salarios
  de forma consistente pese a que provienen de archivos con formatos distintos.
- Se resolvió la relación muchos a muchos entre partidos y árbitros mediante
  la tabla puente `game_official`.
- Se creó el esquema de PostgreSQL con llaves primarias, llaves foráneas,
  restricciones CHECK e índices.
- Se desarrolló un script de Python que lee directamente el ZIP, limpia,
  transforma e inserta los datos, con modo `--dry-run` para validar sin
  conectarse a la base.
- Se desarrolló una ingesta desde el endpoint `LeagueDashPlayerStats` de NBA
  API hacia `player_season_stat`, idempotente mediante `ON CONFLICT`.

---

## 2. Problemas de calidad de datos encontrados

Esta sección documenta los defectos hallados en el conjunto de datos y el
criterio adoptado para cada uno.

### 2.1 `TEAM_ID = 0` como marcador de "sin equipo"

`Player_Attributes.csv` no usa valores nulos para los jugadores sin equipo:
usa el identificador `0`. Afecta a **664 jugadores** retirados o agentes
libres.

Como ningún equipo real de la NBA tiene ese identificador, insertarlo tal cual viola la llave foránea
`player.current_team_id -> team` y **aborta la carga completa**.

**Decisión:** se convierte a `NULL` durante la transformación. No se filtran
esos jugadores, porque son necesarios para responder preguntas históricas.

### 2.2 Phoenix Suns con dos abreviaturas distintas

`Team_Salary.csv` abrevia a los Suns como `PHO`, mientras que `Team.csv` usa
`PHX`. El cruce por abreviatura no encontraba correspondencia y **descartaba
silenciosamente las 6 filas de nómina de Phoenix**.

**Decisión:** la nómina se resuelve primero por nombre completo normalizado,
que sí coincide en ambos archivos, y solo se recurre a la abreviatura como
respaldo.

### 2.3 Colisión de abreviatura entre franquicias

Los Washington Wizards (`WAS`, activos) y los Washington Capitols (`WAS`,
desaparecidos en 1951) comparten abreviatura. El diccionario de búsqueda
sobrescribía la entrada y, como las franquicias históricas se agregan al
final del catálogo, `WAS` terminaba apuntando a los Capitols. En
consecuencia, **los 131 millones de nómina de los Wizards en 2020-21 quedaban
registrados en un equipo extinto**, y ese equipo no tiene estado asignado, lo
que distorsionaba el cálculo de salarios por estado.

**Decisión:** los diccionarios de búsqueda se construyen priorizando los
equipos vigentes, de modo que una abreviatura ambigua nunca resuelva hacia una
franquicia desaparecida.

Los defectos 2.2 y 2.3 solo son detectables ejecutando la carga y
contrastando los conteos: ambos producen resultados que parecen razonables a
simple vista. El síntoma fue que `verification.sql` reportaba 29 equipos con
nómina en lugar de 30.

### 2.4 Identificadores de partido duplicados

`Game.csv` contiene **69 `GAME_ID` repetidos** (138 filas). Las filas
duplicadas no son idénticas entre sí: difieren en algunas columnas de
estadísticas. Esto hacía que temporadas como 2016-17 mostraran 1,231 partidos
en lugar de 1,230.

**Decisión:** se conserva la fila con mayor cantidad de valores no nulos, por
ser la más completa. Resultado: 62,379 partidos únicos.

### 2.5 Errores en `Team.state`

- Atlanta Hawks tiene `state = 'Atlanta'`, que es la ciudad y no el estado.
  El valor correcto es Georgia.
- Toronto Raptors tiene `state = 'Ontario'`, que es una provincia canadiense
  y no un estado de Estados Unidos.

**Decisión:** se corrige Atlanta a Georgia y se etiqueta Toronto como
`Ontario (Canada)` en las consultas de agregación por estado, para no
mezclarlo con los estados estadounidenses sin advertirlo.

### 2.6 Cobertura parcial de árbitros

`Game_Officials.csv` solo cubre partidos a partir de 1996: **21,711 de los
62,379 partidos** tienen árbitro asignado. Un `JOIN` sin advertencia descarta
silenciosamente dos tercios del historial.

**Decisión:** se documenta la limitación. Para las seis temporadas relevantes
del proyecto la cobertura es completa, por lo que no afecta el análisis.

### 2.7 `all_star_appearances` prácticamente vacía

De los 523 jugadores con salario registrado en 2020-21, únicamente **3**
tienen un valor mayor que cero en esta columna.

**Decisión:** la columna es inservible como medida de valor de un jugador. Se
utiliza PIE (Player Impact Estimate), disponible para 401 de esos 523
jugadores, y en segundo lugar el salario máximo.

### 2.8 `Player_Salary.csv` sin identificador de jugador

El archivo solo trae el nombre en texto. El cruce directo contra
`Player.full_name` solo resuelve el 74% de los registros, porque los nombres
vienen con acentos y guiones eliminados (`Timothe LuwawuCabarrot`), con
sufijos (`Bruce Brown Jr`) y con marcas pegadas al nombre (`Noah Vonleh  W`).

**Decisión:** se normalizan los nombres eliminando acentos y caracteres no
alfanuméricos antes de cruzar, lo que eleva la resolución al **93.2%**
(1,204 de 1,292). De los 88 restantes, 8 son ambiguos y 80 corresponden a
novatos de 2020 que no existen en el catálogo (`LaMelo Ball`,
`Facundo Campazzo`). En esos casos se conserva el nombre y el
`player_id` queda nulo, en lugar de asignar una correspondencia incorrecta.

---

## 3. Alcance del conjunto de datos

### 3.1 Solo temporada regular

Todos los `SEASON_ID` de `Game.csv` inician con el dígito `2`, que en la
codificación de la NBA corresponde a temporada regular. **No hay un solo
partido de playoffs ni de pretemporada.**

Es la limitación más relevante del conjunto de datos para la pregunta de
negocio: no es posible sustentar una decisión de inversión en el desempeño de
postemporada. Todo el análisis se basa en temporada regular y así se declara.

### 3.2 Franquicias históricas

`Team.csv` contiene los 30 equipos actuales, pero los partidos hacen
referencia a **45 identificadores** de franquicia. Los 15 restantes
corresponden a equipos desaparecidos.

**Decisión:** se incorporan al catálogo con el campo `is_current = FALSE`, en
lugar de descartar los partidos que los referencian. Esto preserva el
historial completo y satisface las llaves foráneas.

### 3.3 Archivos excluidos

- `News.csv` (772 MB) se excluye por tamaño y porque no aporta a ninguna de
  las preguntas del proyecto. Representa el 93% del peso del ZIP.
- `Game_Inactive_Players.csv` se excluye porque ninguna pregunta utiliza la
  condición de inactividad por partido y cargarlo ampliaría el modelo sin
  aportar a las métricas escogidas.
- `Draft_Combine.csv` se excluye porque las medidas físicas del combine no
  intervienen en el criterio de inversión; el análisis del draft usa selección
  y producción NBA observada en 2020-21.

---

## 4. Convenciones de interpretación

Estas definiciones se aplican de forma consistente en todas las consultas:

| Término | Definición adoptada |
|---|---|
| "Temporada 2017" | 2017-18 (se nombra por el año de inicio) |
| "Temporada 2018" | 2018-19 |
| "Última temporada" | 2020-21, la última temporada completa en `Game.csv` |
| "Jugador activo" | Marcado en `Player.csv` o presente en la ingesta del API de 2020-21 |

Sobre "última temporada": `team_salary` contiene proyecciones hasta 2025-26,
pero esas temporadas no tienen partidos ni rosters cargados. Usar
`MAX(season_id)` devuelve 2025-26 y produce respuestas sin sentido, con
nóminas parciales y sin jugadores asociados.

---

## 5. Validación de integridad

Antes de insertar, el cargador reproduce en memoria las restricciones del
esquema: verifica que ninguna llave primaria sea nula o duplicada y que las
14 llaves foráneas apunten a registros existentes. Si detecta un problema,
reporta todos los casos y aborta sin insertar nada.

Esto cubre un hueco del modo `--dry-run`: sin la validación, ese modo podía
pasar limpio y aun así la carga real fallaba al llegar a PostgreSQL.

---

## 6. Evidencia de ejecución

Carga ejecutada sobre PostgreSQL. Conteos obtenidos con `verification.sql`:

| Tabla | Filas |
|---|---|
| draft_selection | 7,890 |
| game | 62,379 |
| game_official | 65,158 |
| official | 143 |
| player | 9,035 |
| player_salary | 1,292 |
| player_season_stat | 540 |
| season | 80 |
| team | 45 |
| team_history | 60 |
| team_salary | 180 |

Controles de integridad, todos con cero filas como se esperaba:

- Partidos con identificador duplicado: 0
- Relaciones huérfanas de árbitros: 0
- Temporadas mínimas faltantes: 0
- Resultados incoherentes (puntajes negativos o ganador ambiguo): 0

Cobertura de las seis temporadas mínimas:

| Temporada | Partidos |
|---|---|
| 2015-16 | 1,230 |
| 2016-17 | 1,230 |
| 2017-18 | 1,230 |
| 2018-19 | 1,230 |
| 2019-20 | 1,059 |
| 2020-21 | 1,080 |

Las temporadas 2019-20 y 2020-21 tienen menos partidos por la interrupción y
el calendario reducido derivados de la pandemia.

Cobertura salarial: **30 equipos** en 2020-21 y 2021-22. Este conteo es la
comprobación directa de que las correcciones 2.2 y 2.3 están aplicadas; antes
de corregirlas devolvía 29.

`team_salary` con 180 filas corresponde a 30 equipos por 6 temporadas
(2020-21 a 2025-26).

### Ingesta desde NBA API

```
python scripts/load_api.py --season 2020-21
NBA API: 540 estadísticas cargadas para 2020-21.
```

La ingesta agregó 39 jugadores que no existían en los CSV, elevando la tabla
`player` de 8,996 a 9,035 registros. `player_season_stat` habilita responder
la pregunta 7 de la Etapa 2 con estadísticas de la temporada en curso y no
solo con promedios de carrera.

---

## 7. Trabajo opcional

- Ampliar `load_api.py` con reintentos, control de límite de peticiones y un
  ciclo hasta 2025-26 corresponde a puntos extra, no al alcance obligatorio.
