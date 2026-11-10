# Invocaciones, unidades y evoluciones

Reglas decididas por el usuario el 2026-11-10. **Reemplazan** al reclutamiento sin repetidos y a la
evolución por nivel del 2D (ShopSystem.recruitHero / EvolutionSystem). El resto del combate sigue el 2D.

## Unidades
- Cada invocación da una **unidad**: una copia propia de un personaje, con nivel y experiencia. Se pueden repetir.
- Inventario de hasta **100 unidades**. Vender una unidad (fuera del escuadrón) devuelve gemas:
  Común 2, Raro 5, Épico 10, Legendario 25, Mítico 50, Secreto 100.
- Escuadrón de hasta 6 unidades (pueden ser copias del mismo personaje).

## Nivel fuera de partida
- Máximo **50**. Cada nivel da **+1 % de daño** (nivel 50 = +49 %).
- Cada unidad del escuadrón gana **10 XP por oleada superada** (×1,5 en mapas Difíciles).
- Subir del nivel N al N+1 pide **50 × N** XP.

## Dentro de la partida
- Las mejoras con créditos de la partida **se reinician en cada partida** (vuelven a nivel 1) y ya no evolucionan al personaje.
- Cada unidad se puede colocar varias veces según su rareza: Común 4, Raro 3, Épico 3, Legendario 2, Mítico 1, Secreto 1.

## Invocar (banner)
- Moneda: **gemas**. **50 por tirada**, x1 o x10 (500). Se empieza con 500.
- Rareza de cada tirada por los pesos del 2D: Común 48, Raro 30, Épico 15, Legendario 6, Mítico 2, Secreto 1
  (suman 102: Común 47,1 %, Raro 29,4 %, Épico 14,7 %, Legendario 5,9 %, Mítico 2 %, Secreto 1 %). Se mantiene la garantía del 2D: tras 4 comunes seguidos, la siguiente no es común.
- **Banner 1** cambia cada hora (igual en todos los servidores): **1 estrella** (Legendario o Mítico) y **2 apoyos** (Épicos).
  Cuando sale la rareza de un destacado, hay **50 %** de que sea él (repartido si hay varios de esa rareza).
- Los personajes evolucionados no salen en invocaciones: sólo se craftean. Banners 2 y 3: a definir.

## Gemas y núcleos
- Gemas: +10 por cada oleada de historia superada por primera vez en ese mapa, +25 al completar un mapa,
  +15 cada 5 oleadas de infinito.
- Núcleos: +1 al completar un mapa, +1 cada 10 oleadas de infinito.

## Evolución por crafteo
- **3 copias** del mismo personaje + núcleos según la rareza de destino: Raro 1, Épico 3, Legendario 8, Mítico 20, Secreto 50.
- El resultado es un **personaje nuevo**: la evolución del 2D (evolutions.json) como héroe propio, **una rareza más alta**
  que el original, con los bonos de su evolución aplicados a sus stats base. Hereda el **nivel más alto** de las 3 copias.
- Un personaje Secreto no evoluciona.
