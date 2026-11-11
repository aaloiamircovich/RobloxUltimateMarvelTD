# Raids

Sistema propio del port (el 2D no lo tiene). Lógica en `src/shared/Raid.luau` (pruebas en
`src/server/Pruebas/Raid.spec.luau`); la partida de raid está en `Partida.luau` (acto `"raid"`).

## Formato
- Cooperativa, **hasta 4 jugadores** (sala de raid) o solo. Se entra desde ¡A JUGAR! → RAIDS o la estación RAIDS de Nueva York.
- **5 oleadas de esbirros** (oleadas 18–30 del 2D) y en la **6.ª el jefe de la semana**.
- Jefe que rota cada lunes, en su mapa: Thanos (Guantelete) en la Base Vengadores, Galactus en Nueva York,
  Apocalypse en Wakanda y Dormammu en el Sanctum.
- Vida del jefe: **la del 2D × 3, +60 % por cada jugador extra**; velocidad × 0,45. Al bajar al **66 % y al 33 %**
  llama **6 refuerzos** y se **enfurece** (+30 % de velocidad). Si llega a la base, la destruye.
- Barra de vida del jefe arriba de la pantalla.

## Llaves y premios
- **3 llaves por día** (00:00 UTC, no se acumulan); se gasta una al terminar la raid (ganar o perder).
  Abandonar antes de terminar no la gasta. Para iniciar, todos los de la sala necesitan una llave.
- Victoria: **150 gemas, 2 núcleos, 10 fragmentos** y chance de **objeto Mítico (5 %)** o **Legendario (20 %)** que no tengas.
- Derrota: 2 fragmentos.
- **Fragmentos**: 100 para el personaje exclusivo de raid, que todavía no existe (`Raid.EXCLUSIVA`); se guardan.

## Misiones de raid (semanales, estación MISIONES DE RAID o pestaña del panel)
- Ganá 3 raids · Jugá 5 raids · Hacé 150.000 de daño a jefes de raid. Cada una: **80 gemas + 10 fragmentos**.

## Pendiente de balance
- La vida del jefe es una primera estimación: con 2 unidades de nivel bajo se le hace ~800 de daño de 31.500.
  Ajustar `Raid.VIDA` con partidas reales de 4 jugadores.
