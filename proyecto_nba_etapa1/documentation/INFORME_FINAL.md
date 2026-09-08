# Informe final - Proyecto NBA

> Complete los campos `PENDIENTE` con resultados exportados de PostgreSQL. No
> presente cifras que no provengan de una ejecución reproducible.

## 1. Pregunta de negocio

¿En qué equipo invertir para la temporada 2021/2022?

## 2. Datos, modelo y alcance

- Fuente principal: CSV proporcionados por el curso.
- Ventana mínima del análisis: 2015-16 a 2020-21.
- Complemento: NBA API, tabla `player_season_stat`.
- Datos excluidos: `News.csv`, por tamaño y falta de relación directa con las
  métricas escogidas. Esta decisión debe explicarse en la presentación.
- Modelo ER: insertar `diagrams/er_diagram.png` o la versión con notación de
  Chen disponible en `diagrams/der_chen.png`.

## 3. Calidad y transformación

- 69 identificadores duplicados en `Game.csv`: se conserva la fila más completa.
- `Team_Salary.csv`: se normaliza de columnas por temporada a filas.
- `Player_Salary.csv`: se relaciona por nombre normalizado; las coincidencias
  ambiguas conservan nombre y un `player_id` nulo.
- Se incorporan franquicias históricas para satisfacer las llaves foráneas.
- Adjuntar resultados de `database/verification.sql`: PENDIENTE.

## 4. Preguntas obligatorias

Para cada consulta de `database/analysis_queries.sql` (1 a 8), incluir:

1. La pregunta.
2. El SQL ejecutado.
3. Una tabla o gráfica del resultado.
4. Una interpretación breve y orientada al negocio.

Resultados e interpretación: PENDIENTE.

## 5. Preguntas propias

Las consultas E3.1 a E3.13 de `database/stage3_queries.sql` analizan
consistencia, diferencial de puntos, ventaja local, eficiencia salarial,
flexibilidad financiera, crecimiento, profundidad del roster, draft,
dependencia y sensibilidad de la recomendación.

Resultados e interpretación: PENDIENTE.

## 6. Recomendación de inversión

La consulta E3.12 calcula un índice reproducible con estas ponderaciones:

- 40% rendimiento.
- 35% valor por el dinero.
- 25% crecimiento.

La consulta E3.13 comprueba la sensibilidad ante ponderaciones alternativas.

Equipo recomendado según el resultado: PENDIENTE.

Justificación, riesgos y sensibilidad a las ponderaciones: PENDIENTE.

## 7. Reproducibilidad

1. Crear el entorno e instalar `requirements.txt` con Python 3.11-3.13.
2. Iniciar PostgreSQL y configurar `.env`.
3. Ejecutar `python scripts/load_csv.py --zip data/Data.zip`.
4. Ejecutar `python scripts/load_api.py --season 2020-21`.
5. Ejecutar `database/verification.sql`.
6. Ejecutar `database/analysis_queries.sql` y exportar los resultados de Etapa 2.
7. Ejecutar completo `database/stage3_queries.sql` en la misma sesión y exportar
   los trece resultados de Etapa 3.

## 8. Limitaciones

- El salario no equivale por sí solo al valor financiero de una franquicia.
- Los CSV terminan en 2021; cambios posteriores requieren la actualización API.
- PIE y estadísticas por partido son criterios deportivos, no una valoración de mercado.
- La recomendación cambia si el grupo modifica las ponderaciones del índice.
