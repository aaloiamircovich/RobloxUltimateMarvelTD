# Rasgos y grados

Sistema propio del port (el 2D no lo tiene). Lógica en `src/shared/Rasgos.luau`, pruebas en
`src/server/Pruebas/Rasgos.spec.luau`. Se usan en las estaciones RASGOS y GRADOS de Wakanda.

## Rasgos (traits)
- Cada unidad tiene **un rasgo** (empieza sin rasgo). Se cambia con **1 ficha de rasgo** por tirada.

| Rasgo | Rareza | Prob. | Bono |
|---|---|---|---|
| Fuerza I / II / III | Común / Común / Épico | 16 / 8 / 3 % | +5 / +10 / +15 % daño |
| Vista I / II / III | Común / Común / Épico | 16 / 8 / 3 % | +5 / +10 / +15 % alcance |
| Rapidez I / II / III | Común / Común / Épico | 16 / 8 / 3 % | +5 / +10 / +15 % cadencia |
| Mercenario | Raro | 9 % | +10 % de dinero por enemigo que derrota |
| Certero | Raro | 7 % | +8 % de probabilidad de crítico |
| Cósmico | Mítico | 1,5 % | +20 % daño, +10 % alcance, +10 % cadencia |
| Vibranium | Mítico | 1,5 % | +25 % daño, +15 % cadencia, +5 % alcance |

- **Garantía:** tras 49 tiradas sin mítico, la 50.ª es mítica (contador por cuenta).
- Antes de tirar sobre un rasgo **Épico o Mítico** se pide confirmación.

## Grados (grades)
- Un grado por stat: **Daño, Alcance y Cadencia**. Empiezan en B.
- C −2 % (30 %) · B 0 % (35 %) · A +4 % (22 %) · S +8 % (10 %) · S+ +12 % (3 %).
- Se tiran los tres juntos con **cristales de grado**: 1 cristal; **bloquear** un stat duplica el costo (2), dos stats → 4. Máximo 2 bloqueados.

## De dónde salen
- **Raid ganada:** 2 fichas y 3 cristales.
- **Misiones semanales:** cada una da además 1 ficha y 2 cristales.
- **Pase de batalla:** los niveles terminados en 3 dan fichas (1–3) y los terminados en 7, cristales (2–4).
- **Tienda del desafío semanal:** 2 fichas por 60 🎟 (×3) y 4 cristales por 40 🎟 (×3).

## Otros
- Al **evolucionar**, la unidad nueva hereda el rasgo y los grados de la copia con el mejor rasgo.
- Los bonos se aplican en combate después de las mejoras; el panel de la unidad en partida muestra rasgo y grados.
- No se pueden tirar durante una partida (el escuadrón ya está fijado).
