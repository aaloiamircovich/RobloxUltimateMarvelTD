# Raids

Sistema propio del port (el 2D no lo tiene). Lógica en `src/shared/Raid.luau` (pruebas en
`src/server/Pruebas/Raid.spec.luau`); la partida de raid está en `Partida.luau` (acto `"raid"`).

## Formato
- Cooperativa, **hasta 4 jugadores** (sala de raid) o solo. Se entra desde ¡A JUGAR! → RAIDS o la estación RAIDS de Nueva York.
- **5 oleadas de esbirros** (oleadas 2, 4, 6, 8 y 10 del 2D: el filtro es el jefe) y en la **6.ª el jefe de la semana**.
- Jefe que rota cada lunes, en su mapa: Thanos (Guantelete) en la Base Vengadores, Galactus en Nueva York,
  Apocalypse en Wakanda y Dormammu en el Sanctum.
- **Dinero inicial 3.000** (una partida normal arranca con 1.200).
- Vida del jefe: **6.000 de daño crudo descontando su armadura** (todos los jefes igual de duros), **+60 % por cada
  jugador extra**; velocidad × 0,45. Pensado para que solo sea difícil y en grupo cómodo. Al bajar al **66 % y al 33 %**
  llama **6 refuerzos** y se **enfurece** (+30 % de velocidad). Si llega a la base, la destruye.
- Barra de vida del jefe arriba de la pantalla.

## Llaves y premios
- **3 llaves por día** (00:00 UTC, no se acumulan); se gasta una al terminar la raid (ganar o perder).
  Abandonar antes de terminar no la gasta. Para iniciar, todos los de la sala necesitan una llave.
- Victoria: **150 gemas, 2 núcleos, 20 fichas de raid (Banner 2), 10 fragmentos, 2 fichas de rasgo y 3 cristales de grado** y chance de **objeto Mítico (5 %)** o **Legendario (20 %)** que no tengas.
- Derrota: 2 fragmentos y 5 fichas de raid.
- **Fragmentos**: 100 se canjean por **Knull**, personaje exclusivo de raid (docs/EXCLUSIVOS.md).

## Misiones de raid (semanales, estación MISIONES DE RAID o pestaña del panel)
- Ganá 3 raids · Jugá 5 raids · Hacé 30.000 de daño a jefes de raid. Cada una: **80 gemas + 10 fichas de raid + 10 fragmentos**.

## Balance
- Medido con los datos del 2D: con ~6.500 de dinero en la raid, un jugador solo arma 3–4 unidades con 1–2 mejoras
  (~55 de daño/s cada una) y cada unidad tiene al jefe en alcance unos 20 s: 4.000–7.000 de daño crudo.
- Vidas resultantes (1 jugador → 4): Thanos 2.700 → 7.600 · Galactus 2.700 → 7.600 · Apocalypse 3.500 → 9.700 ·
  Dormammu 4.800 → 13.400. Se ajusta con `Raid.OBJETIVO`.
- Prueba en partida (11/11/2026, solo, Apocalypse 3.500): escuadrón flojo (Dagger y 2 Triton de nivel 5, mejoras 2–4)
  llegó al jefe con 318 de base, le sacó 2.396 (68 %, cruzó las dos fases) y perdió por poco. Con esbirros de las
  oleadas 18–30 o 6–14 del 2D se perdía antes del jefe; por eso quedaron en 2–10.
