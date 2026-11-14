# Premio diario, códigos y logros

Decidido por el usuario el 14/11/2026. Lógica en `src/shared/Recompensas.luau` (pruebas en
`src/server/Pruebas/Recompensas.spec.luau`); se guarda en el perfil (`diario`, `codigos`, `logros`, `estadisticas`).
Panel **PREMIOS** (🎁, columna derecha del lobby) con pestañas Diario, Logros y Códigos; el botón muestra un globo
«!» cuando el premio del día está listo.

## Premio diario: racha de 7 días
| Día | Premio |
|---|---|
| 1 | 30 💎 |
| 2 | 1 ficha de rasgo + 2 cristales |
| 3 | 50 💎 |
| 4 | 1 núcleo |
| 5 | 80 💎 + 2 fichas de rasgo |
| 6 | 2 núcleos + 4 cristales |
| 7 | 200 💎 + 3 núcleos + 2 fichas de rasgo |

- Uno por día (cambia a las 00:00 UTC). Si faltás un día la racha vuelve al día 1; después del 7 vuelve a empezar.

## Códigos
- Se agregan en `Recompensas.CODIGOS` (código en mayúsculas, premio y vencimiento opcional en `os.time()` UTC) y se
  **publica el lugar**. Cada cuenta canjea cada código una vez; no distingue mayúsculas ni espacios.
- El servidor deja probar un código cada 2 s por jugador (para que no se puedan adivinar a fuerza bruta).
- Ejemplos cargados: `BIENVENIDO` (100 💎, sin vencimiento) y `HEROES2026` (150 💎 + 1 ficha, hasta el 01/01/2027).

## Logros (18, se reclaman con un botón)
- **Historia:** primer acto (50 💎), 10 actos (150), completar un mapa (100 + 1 núcleo), 4 mapas (300 + 3 núcleos),
  un acto en Pesadilla (150), 10 en Pesadilla (400 + 2 núcleos).
- **Colección:** 10 unidades (100), 50 unidades (250), un Legendario (100), un Mítico (300), una evolución (2 núcleos).
- **Combate:** 500 / 5.000 / 25.000 enemigos (100 / 300 / 500 + 3 núcleos), 10 / 100 jefes (150 / 500 + 3 fichas),
  oleada 25 / 50 en Infinito (150 / 400 + 6 cristales).
- El progreso sale del perfil (actos, unidades, récord de Infinito) y de dos contadores nuevos que suma la partida:
  enemigos y jefes derrotados (empiezan en cero para todos).
