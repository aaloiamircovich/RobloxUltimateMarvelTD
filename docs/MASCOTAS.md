# Mascotas

Sistema propio del port (el 2D no lo tiene), con criaturas originales (sin personajes de Marvel). Lógica en
`src/shared/Mascotas.luau`, pruebas en `src/server/Pruebas/Mascotas.spec.luau`; las mascotas que siguen al
jugador las dibuja cada cliente (`src/client/Mascotas.client.luau`). Estación MASCOTAS de Wakanda.

## Mascotas y bonos
| Mascota | Rareza | Bono |
|---|---|---|
| Dron-robot | Común | +5 % dinero de partida |
| Gatito cósmico | Común | +8 % XP (cuenta y unidades) |
| Golem de piedra | Raro | +3 % daño de tus unidades |
| Búho místico | Raro | +5 % gemas de premios |
| Pulpo alienígena | Épico | +12 % dinero |
| Lobo de vibranium | Épico | +6 % daño |
| Dragoncito de fuego | Legendario | +10 % daño |
| Fénix | Mítico | +12 % daño, +12 % dinero, +10 % gemas |

- Se equipan **hasta 3**; los bonos se suman. Las gemas extra valen para actos ganados, raids e Infinito.
- **Fusión:** 3 copias normales iguales → 1 **dorada** con el bono **×2** (usa primero las no equipadas; si usó una
  equipada, la dorada queda equipada). Inventario de hasta 50.
- Los bonos se fijan al empezar la partida; no se equipa ni se abren huevos durante una.

## Huevos (con gemas)
| Huevo | Precio | Común | Raro | Épico | Legendario | Mítico |
|---|---|---|---|---|---|---|
| Básico | 100 💎 | 60 % | 30 % | 9 % | 1 % | — |
| Cósmico | 300 💎 | 25 % | 40 % | 25 % | 8 % | 2 % |

## Modelos
- Generados con el generador de Roblox (ForgeGUI sin créditos) y guardados en `ServerStorage.Plantillas.Mascotas`.
- Siguen al jugador en el lobby y en la partida, flotando detrás (izquierda, centro, derecha). Las doradas llevan
  contorno dorado y destellos.
