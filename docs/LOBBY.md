# Lobby (HUB)

Se arma por código en `src/server/Hub.luau` al arrancar el servidor (`Hub.construir`): seis islas flotantes
(central, Asgard, Wakanda, Nueva York, Torre Baxter y Sanctum), puentes, el portal al Sanctum, las estaciones,
las salas, los edificios (`HITOS`, modelos de `ServerStorage.Plantillas.Hub`), árboles y adornos.

## Tamaño (decidido por el usuario el 15/11/2026)
- **Islas ×1,5**: islas, puentes, estaciones, árboles, faroles, bancos y plantas crecen todos juntos.
- **Edificios ×2**: la Torre de los Vengadores pasa de 34 a 68 studs, el Empire State de 40 a 80, el castillo de
  Asgard de 30 a 60.
- Cómo se hace: todo se arma con las medidas de antes y al final `hub:ScaleTo(ESCALA)` lo agranda alrededor de
  `PIVOTE` (justo debajo de la isla central, para que su piso quede a la misma altura). Los edificios se arman
  `ESCALA_EDIFICIOS / ESCALA` más grandes para terminar en ×2, y los letreros de las islas suben lo mismo.
- Lo que `ScaleTo` no agranda se ajusta a mano: el **pasto de terreno** de las islas de pasto se llena después
  (`pastoDeTerreno`), los **carteles** flotantes (`BillboardGui`) y la **distancia de los ProximityPrompt** se
  multiplican por `ESCALA`, y `Hub.llegada` (Viajar) lleva las posiciones de `ISLAS` a la medida final.
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
| Infinito | Torre Baxter | Mister Fantastic | Máquina con portal |
| Historia | Sanctum | Wong | Portal |

## Verificado en Play
El personaje aparece y camina sobre el pasto a la misma altura que antes; Viajar deja en el piso de cada isla
(mármol, pasto, concreto, metal, madera); las 16 estaciones se arman con su puesto o portal y los 14 encargados
están en reposo (vistos: tienda, misiones, bailes, banner 1); sin errores en la consola.

## Sin probar
- Usar cada estación y sala con el personaje (la distancia para activarlas creció ×1,5).
- Celulares: las caminatas entre islas son un 50 % más largas.
