# Lobby (HUB)

Se arma por código en `src/server/Hub.luau` al arrancar el servidor (`Hub.construir`): seis islas flotantes
(central, Asgard, Wakanda, Nueva York, Torre Baxter y Sanctum), puentes, el portal al Sanctum, las estaciones,
las salas, los edificios (`HITOS`, modelos de `ServerStorage.Plantillas.Hub`), árboles y adornos.

## Tamaño (decidido por el usuario el 15/11/2026, dos veces)
- **Islas ×2**: islas, puentes, estaciones, árboles, faroles, bancos y plantas crecen todos juntos (la isla
  central mide 160 studs de ancho).
- **Edificios ×3**: la Torre de los Vengadores pasa de 34 a 102 studs, el Empire State de 40 a 120, el castillo
  de Asgard de 30 a 90.
- Con este tamaño el lobby llega hasta x ≈ 320, así que las **arenas de partida** arrancan en x = 600
  (`origenLibre` en `Main.server.luau`).
- Cómo se hace: todo se arma con las medidas de antes y al final `hub:ScaleTo(ESCALA)` lo agranda alrededor de
  `PIVOTE` (justo debajo de la isla central, para que su piso quede a la misma altura). Los edificios se arman
  `ESCALA_EDIFICIOS / ESCALA` más grandes para terminar en ×3, y los letreros de las islas suben lo mismo.
- Lo que `ScaleTo` no agranda se ajusta a mano: el **pasto de terreno** de las islas de pasto se llena después
  (`pastoDeTerreno`), los **carteles** flotantes (`BillboardGui`) y la **distancia de los ProximityPrompt** se
  multiplican por `ESCALA`, y `Hub.llegada` (Viajar) lleva las posiciones de `ISLAS` a la medida final. El pasto
  viejo se borra sólo alrededor de cada isla de pasto.
- Para cambiar el tamaño alcanza con tocar `ESCALA` y `ESCALA_EDIFICIOS` al principio de `Hub.luau`.

## Estaciones con encargados (decidido por el usuario el 15/11/2026)
Cada estación tiene un **encargado** del lore (el héroe de `Plantillas.Heroes`, con su animación de reposo, sólo
la raíz anclada) y un **puesto** temático generado con la IA de Roblox (`Plantillas.Hub/puesto_*`, se guarda en
el lugar). Las **invocaciones** de Asgard y la **Historia** siguen siendo portales, porque encajan con el lore.
Los encargados no giran ni hablan: sólo su reposo. Se definen con `personaje` y `puesto` en `Hub.ESTACIONES`.

| Estación | Isla | Encargado | Puesto |
| --- | --- | --- | --- |
| Misiones | Central | Nick Fury | Mesa holográfica de S.H.I.E.L.D. |
| Bailes | Central | Star-Lord | Rocola (Awesome Mix) |
| Evento | Central | Korg | Podio del Concurso de Campeones |
| Ranking | Central | Valkyrie | Muro de trofeos (el cartel del Top 10 sigue arriba) |
| Monturas | Central | Ghost Rider | Garaje de motos |
| Banner 1 | Asgard | Heimdall | Portal (Banners 2 y 3 siguen sólo con portal) |
| Rasgos | Wakanda | Shuri | Laboratorio de vibranium |
| Grados | Wakanda | M'Baku | Forja de vibranium |
| Mascotas | Wakanda | Rocket | Puesto de huevos y jaulas |
| Raids | Nueva York | Capitán América | Mesa de guerra con el escudo |
| Misiones de raid | Nueva York | Maria Hill | Kiosco de S.H.I.E.L.D. |
| Tienda | Nueva York | Spider-Man | Almacén de esquina neoyorquino |
| Infinito | **Adentro** de la Torre Baxter | Mister Fantastic | Máquina con portal |
| Historia | **Adentro** del Sanctum | Wong | Portal |

## Interiores (decidido por el usuario el 15/11/2026)
- La **Historia** está dentro del **Sanctum Sanctorum** y el **Infinito** dentro del laboratorio de la **Torre
  Baxter**, cada uno con sus 8 salas para crear partida.
- Se entra por una **puerta de luz** en la fachada del edificio (tecla E, «Entrar») y se sale por otra en la pared
  de atrás de la sala («Salir»). `Hub.llegadas` y `Hub.salidas` son los marcadores; antes de llevar al jugador se
  pide que cargue esa zona (`RequestStreamAroundAsync`).
- Las salas (`INTERIORES` en `Hub.luau`) son cajas cerradas lejos y arriba de las islas (no se ven desde el
  lobby), de 72 × 72 studs y 24 de alto antes de agrandar: piso, paredes con columnas cada 12 studs, techo,
  zócalos de luz, focos (cálido al centro y del color de acento en las esquinas) y polvo flotando. Para las
  estaciones funcionan como una isla más (`lugar()`). Los muebles son modelos generados (`Plantillas.Hub/int_*`).
- **Sanctum Sanctorum** (mejorado el 15/11/2026): Doctor Strange junto a la ventana del sello; círculo mágico
  que gira en el piso (lo gira `Hub.animar` como el sello del portal) con chispas; estanterías de libros, el Ojo
  de Agamotto, la Capa de Levitación, un atril con el Libro de los Vishanti, una alfombra, un candelabro colgante
  y libros flotando con brillo; un **balcón** de madera por tres paredes a 12 studs, con barandas, y una
  **escalera** de 12 escalones contra la pared +X.
- **Laboratorio de la Torre Baxter** (mejorado el 15/11/2026): Sue y Johnny Storm junto a Mister Fantastic;
  **portal a la Zona Negativa** en la pared +X (marco generado y remolino violeta con partículas y luz);
  **ventanal** de vidrio en la pared −X con rascacielos afuera (da al cielo vacío: del otro lado, +X, está el
  salón del Sanctum); consolas, mesas de trabajo, tubos, el Fantasticar, H.E.R.B.I.E. flotando, dos pantallas
  gigantes y el «4» en el piso (`SurfaceGui` por studs: `ScaleTo` divide su `PixelsPerStud`).

## Decorado y cielo (decidido por el usuario el 15/11/2026: el lobby se veía vacío)
- **Decorado por isla** (`DECORADO`): reusa los kits de los mapas de partida del mismo tema más piezas propias.
  Central: fuente con la «A» dorada (con chorro de agua), estatuas de héroes, faroles, arbustos y flores. Asgard:
  piedras rúnicas, braseros y árboles dorados. Wakanda: estatua de pantera, cristales de vibranium con luz,
  helechos y faroles. Nueva York: autos, hidrantes, tachos, faroles y árboles. Torre Baxter: cajas y luces.
  Sanctum: braseros con luz, árboles y faroles, y chispas mágicas flotando.
- Cada pieza se ubica sola en un lugar libre (`ocupar` / `libre`): no tapa estaciones, edificios, salidas de los
  puentes, el portal ni la aparición. El sorteo es fijo: el lobby sale siempre igual.
- **Cielo** (`cielo()`): el **Helicarrier** de S.H.I.E.L.D. flotando, un **Quinjet** que da vueltas y seis
  **islotes** de roca con árboles o cristales. El Quinjet y el vaivén del Helicarrier los mueve cada cliente
  (`CieloHub.client.luau`), así no se manda nada por la red.

## Verificado en Play
El personaje aparece y camina sobre el pasto a la misma altura que antes; Viajar deja en el piso de cada isla
(mármol, pasto, concreto, metal, madera); las 16 estaciones se arman con su puesto o portal y los 14 encargados
están en reposo; se entra y se sale del Sanctum y de la Torre Baxter con la E; una partida se arma en x = 600 y
se vuelve al lobby; sin errores en la consola.

## Sin probar
- Usar cada estación y sala con el personaje (la distancia para activarlas creció ×1,5).
- Celulares: las caminatas entre islas son un 50 % más largas.
