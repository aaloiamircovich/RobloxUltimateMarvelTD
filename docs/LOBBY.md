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

## Verificado en Play
El personaje aparece y camina sobre el pasto a la misma altura que antes; Viajar deja en el piso de cada isla
(mármol, pasto, concreto, metal, madera); sin errores en la consola.

## Sin probar
- Usar cada estación y sala con el personaje (la distancia para activarlas creció ×1,5).
- Celulares: las caminatas entre islas son un 50 % más largas.
