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
- **Reposo propio del lobby** (`REPOSO_LOBBY`, generado con la IA de Roblox: de pie y con los brazos sueltos), no
  el de combate de `Shared/Reposo.luau`: con aquél la espada de Valkyrie atravesaba la pierna, las manos de Nick
  Fury se metían en el cuerpo y Ghost Rider flotaba. Un segundo después de arrancar la animación, `apoyarPies`
  sube o baja a cada encargado hasta que su pie más bajo toque el piso.
- El **portal** entre la isla central y el Sanctum guarda su destino como una parte invisible (`LlegadaPortal`)
  dentro del lobby, así crece con el agrandado final (antes era un CFrame fijo con la medida vieja y no llevaba).

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
  lobby), de 52 × 52 studs y 24 de alto antes de agrandar (achicadas el 15/11/2026 a pedido del usuario para que
  no queden huecos; las 8 salas de cada modo van en dos filas de 4 contra las paredes de los costados): piso, paredes con columnas cada 12 studs, techo,
  zócalos de luz, focos (cálido al centro y del color de acento en las esquinas) y polvo flotando. Para las
  estaciones funcionan como una isla más (`lugar()`). Los muebles son modelos generados (`Plantillas.Hub/int_*`).
- **Sanctum Sanctorum** (rehecho el 15/11/2026 a partir de tres fotos de referencia que pasó el usuario;
  `extrasSanctum` en `Hub.luau`): paredes de **madera oscura** con molduras doradas y apliques de luz cálida en
  las columnas; **piso lustrado** (refleja) con incrustaciones de bronce (dos anillos y ocho rayos alrededor del
  círculo mágico); **techo artesonado** (vigas cruzadas cada 8 studs con filete dorado); el **ventanal redondo**
  de 18 studs en la pared del fondo, sobre una **tarima** con dos escalones y barandas de bronce, armado con piezas
  según una cuarta foto: vidrio claro y frío, **emplomado** fino (24 rayos desde una roseta central y anillos),
  cuatro **bandas** gruesas oscuras que se cruzan (arcos de círculos corridos, recortados dentro del vidrio) y un
  **marco** grueso en dos escalones; luz fría que entra (`SurfaceLight`) y polvo flotando en el haz; **vitrinas** de vidrio con reliquias a los costados, un **cofre** tallado, un **escritorio** antiguo con
  lámpara, una **estatua** dorada, estanterías, el atril con el Libro de los Vishanti, la alfombra, el candelabro,
  el Ojo de Agamotto y la Capa de Levitación sobre la tarima, libros flotando y Doctor Strange. Balcones con
  **barandas de bronce** en las paredes de los costados (en el fondo no, para no tapar el ventanal) y la escalera.
  El neón del ventanal es de un color medio a propósito: más claro, el resplandor tapa las bandas y el emplomado.
  **Pared del frente** (la de la puerta, a la espalda al entrar): doble puerta de madera tallada con bronce
  (`int_puerta`; `puerta()` acepta un modelo y deja la hoja con la tecla E invisible), dos **ventanales altos con
  arco** a los costados (vidrio de luz cálida, marco de madera oscura, parante y travesaños de bronce, alféizar), una
  **ventana redonda** con el sello sobre la puerta, friso de madera con paneles en relieve, apliques junto a la
  puerta y dos **cuadros** antiguos (`int_cuadro`) en las esquinas.
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

## Salas físicas (fase D, 18/11/2026)
Decidido por el usuario: **pararse y cuenta regresiva**. Las 8 plataformas del Sanctum (Historia) y de la Torre Baxter
(Infinito) están en `Hub.plataformas`. Al pararte en una vacía se abre el panel de Historia; «CREAR SALA» la ata a esa
plataforma. El anillo se pone verde y el cartel muestra mapa, acto, jugadores y «empieza en N s». Los demás se suman
con sólo pararse (respeta «Sólo amigos»); bajarse más de 1 s es salir (si es el anfitrión, la sala se cierra). A los
20 s arranca sola (al sumarse alguien, quedan al menos 8 s); el anfitrión puede empezar antes. Lógica en
`Main.server.luau` (bucle cada 0,25 s). Verificado en Play: el panel se abre al pararse, el cartel cuenta y la
partida empieza sola. Sin probar: sumarse con un segundo jugador y bajarse de la plataforma.

## Resto de la fase D (18/11/2026)
- **Escuadrón que te sigue** (`Seguidores.client.luau`): las 3 primeras del escuadrón (atributo `Seguidores` que
  publica `publicarSaldo`) caminan a los costados y detrás de cada jugador a ×0,7 (más chicas las tapa el pasto 3D),
  apoyadas en el piso, con reposo y caminata; las Shiny con contorno dorado. Hasta 12 jugadores cercanos; en partida
  se esconden.
- **Salón de héroes** (`Hub.salonHeroes`, en la isla central entre el portal del Sanctum y Misiones): 5 pedestales en
  arco con pared de piedra, molduras doradas y el cartel «SALÓN DE HÉROES». Cada cliente pone ahí sus 5 mejores
  unidades (rareza, nivel; `Vitrina.client.luau`) con nombre, rareza, nivel y luz del color de la rareza. Se llega
  caminando, con VIAJAR → «Salón de héroes» o con el botón del perfil.
- **Encargados que hablan** (`Encargados.client.luau`): al acercarte (24 studs) saludan con la mano (animación de la IA
  de Roblox) y muestran un globo con su frase y un dato útil: Nick Fury las misiones listas o pendientes, Heimdall el
  destacado del Banner 1, Wong el próximo acto que te falta, Rocket tus gemas.
- **Día y noche** y **eventos** (`AgendaLobby.luau`, sincronizados con la hora del servidor): un día cada 20 min; de
  noche baja la luz, cielo de estrellas y se refuerzan faroles y braseros (`VidaLobby.client.luau`). Cada 2,5 min un
  evento: el Quinjet aterriza en la azotea de la Torre de los Vengadores (`CieloHub.client.luau`), un rayo arcoíris del
  Bifrost cae sobre Asgard o se abre un portal de Strange sobre la isla del Sanctum.
- **Puentes y caminos**: puentes más anchos (9 el Bifrost, 8 los demás) con faroles cada ~12 studs del color de cada
  puente, y caminos de losas con filo dorado desde cada puente y desde el portal hasta la plaza de la Torre.
- Verificado en Play: los 3 seguidores, el salón con 4 unidades, el diálogo de Nick Fury con su dato y la noche con
  estrellas. 23 pruebas pasan (nueva: `AgendaLobby.spec`). Sin verlo en pantalla: los tres eventos (pasan en momentos
  fijos) y un segundo jugador viendo los seguidores de otro.
