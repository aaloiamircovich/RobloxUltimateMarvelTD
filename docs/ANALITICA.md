# Analítica y rendimiento

Decidido por el usuario el 14/11/2026. Código en `src/server/Analitica.luau` (todo con `pcall`: si Roblox rechaza un
evento, el juego sigue igual). Los gráficos se ven en el **Creator Dashboard → Analytics** del juego publicado; en
Studio sólo aparece «AnalyticsService: … event fired» en la consola.

## Qué se registra
| Panel del Dashboard | Qué | Dónde se llama |
| --- | --- | --- |
| **Onboarding (embudo)** | Los 10 pasos del tutorial (0 elegir héroe … 9 terminado), sólo cuando el paso avanza | remoto `Preferencias` en `Main.server.luau` |
| **Economy** | Gemas, Núcleos, FichasRasgo, Cristales, FichasRaid: diferencia contra el último saldo, como fuente o gasto, con el motivo (`banner2`, `estilo`, `recompensas`, `tutorial`, `rasgos_…`, `acto`, `raid`, `infinito`, …) | `publicarSaldo` y premios de `Partida.luau` |
| **Progression** | Camino `Historia <mapa>` con nivel = acto (o `<modo> <mapa>` para raid/infinito): inicio, victoria y derrota. La derrota lleva `Oleada N` y `Derrota`/`Abandono` (salir con el botón o del juego) | `bucle()`, `terminar()` y `p.salir` de `Partida.luau` |
| **Custom events** | `Unidad colocada` / `Unidad mejorada` con héroe y rareza; `Tutorial salteado` con el paso | `colocar`, `mejorar`, remoto `Preferencias` |

El saldo de referencia se toma al entrar (sin motivo, no registra nada) y se borra al salir.

## Rendimiento (medido en Studio, 14/11/2026)
- Lo peor: `ReplicatedStorage.Retratos` (copia de los 212 modelos para los retratos 3D) eran **103.687 instancias**,
  el 65 % de todo lo cargado en el cliente. Cada modelo traía ~315 piezas que dejó `auto_setup_avatar` y nadie usa:
  carpeta `InitialPoses` (189 CFrameValue), `AnimateScript` con 27 animaciones, `FaceControls` y, en el retrato,
  `NoCollisionConstraint`.
- Arreglo: `Main.server.luau` las borra de las plantillas al arrancar (los `NoCollisionConstraint` sólo del retrato,
  porque las unidades sí tienen física). Retratos: **46.235** instancias (−55 %); total de Studio 161 k → 104 k.
- Verificado: retratos de las tarjetas, unidad colocada con su animación de reposo y mejora, sin errores.
- Queda para más adelante: mandar los retratos al cliente a pedido (sólo los que ve) en vez de todos.

## Sin probar todavía
- Los gráficos del Dashboard: sólo se llenan con el juego publicado y jugadores reales (tarda ~1 día en aparecer).
