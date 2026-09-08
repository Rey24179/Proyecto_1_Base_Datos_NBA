# Etapa 3 - Justificación del análisis de inversión

## Objetivo

Determinar en qué equipo invertir para la temporada 2021/2022 mediante
resultados reproducibles en PostgreSQL. El análisis utiliza las temporadas
2015-16 a 2020-21 y las estadísticas 2020-21 obtenidas del NBA API.

## Criterio de decisión

La decisión combina tres dimensiones:

1. **Rendimiento (40%)**: récord promedio, diferencial de puntos y piso de
   victorias durante las seis temporadas.
2. **Valor (35%)**: victorias por millón y talento obtenido respecto a la
   posición de la nómina.
3. **Crecimiento (25%)**: tendencia del porcentaje de victorias y producción
   de selecciones recientes de primera ronda.

Las métricas se normalizan mediante `PERCENT_RANK` para llevarlas a una escala
común de 0 a 1. Los pesos no se eligieron para favorecer a un equipo: la
consulta E3.13 prueba cuatro combinaciones diferentes.

## Preguntas propias implementadas

| Consulta | Pregunta | Propósito |
|---|---|---|
| E3.1 | ¿Qué equipos fueron consistentes y mantuvieron al menos 40% de victorias? | Evitar premiar equipos consistentemente malos. |
| E3.2 | ¿El diferencial de puntos confirma el récord obtenido? | Identificar rendimiento subestimado o sobreestimado. |
| E3.3 | ¿Qué equipos poseen mayor ventaja como locales? | Aproximar estabilidad deportiva y atractivo local. |
| E3.4 | ¿Qué equipos consiguieron más victorias por millón de dólares? | Medir eficiencia del gasto. |
| E3.5 | ¿Qué equipos tienen más talento que el sugerido por su nómina? | Encontrar valor por debajo del precio relativo. |
| E3.6 | ¿Qué porcentaje de la nómina está comprometido para 2021-22? | Medir flexibilidad financiera. |
| E3.7 | ¿Qué equipos presentan una trayectoria ascendente? | Medir crecimiento con regresión sobre seis temporadas. |
| E3.8 | ¿Qué equipos tienen anotación y profundidad de roster? | Evaluar el plantel 2020-21 mediante NBA API. |
| E3.9 | ¿Qué producción generan los cinco principales jugadores? | Comparar la fortaleza del núcleo. |
| E3.10 | ¿Qué equipos obtuvieron producción mediante el draft reciente? | Aproximar desarrollo de talento joven. |
| E3.11 | ¿Qué equipos dependen menos de su máximo anotador? | Controlar el riesgo de concentración. |
| E3.12 | ¿Qué equipo lidera el índice compuesto? | Producir la recomendación principal. |
| E3.13 | ¿La recomendación cambia al modificar los pesos? | Evaluar la robustez de la decisión. |

El SQL completo está en `database/stage3_queries.sql` y debe ejecutarse entero
en una misma sesión, porque utiliza vistas temporales.

## Resultados

**Pendiente:** ejecutar E3.1 a E3.13 en pgAdmin, exportar cada resultado y
reemplazar esta sección con los valores obtenidos. No se deben reutilizar
cifras de borradores si no coinciden con la ejecución actual.

## Recomendación

**Pendiente:** seleccionar el primer equipo de E3.12 solamente después de
comprobar los resultados. E3.13 debe confirmar si la recomendación se mantiene
al priorizar rendimiento, valor o crecimiento.

La conclusión final debe incluir al menos dos fortalezas, dos riesgos y una
alternativa de inversión respaldados por las consultas.

## Limitaciones

- Los partidos disponibles corresponden a temporada regular, no playoffs.
- El salario no equivale a la valoración financiera completa de la franquicia.
- PIE y estadísticas por partido representan rendimiento deportivo.
- E3.6 utiliza la proyección de `Team_Salary.csv` como aproximación de salario
  comprometido, no como espacio salarial oficial auditado.
- E3.10 atribuye el jugador al equipo que realizó la selección del draft, aunque
  haya sido intercambiado posteriormente.
