# Shiny (fase C del plan estético 2)

Decidido por el usuario el 18/11/2026: **+5 % de daño**, **brillo dorado y chispas**, **Shiny si alguna copia lo era**
al evolucionar, y salen sólo de **los dos banners**.

## Reglas (`src/shared/Unidades.luau`)
- `Unidades.PROB_SHINY = 0.015`: cada invocación del Banner 1 y del Banner 2 tira aparte si sale Shiny
  (`Unidades.tirarShiny`). El héroe inicial, el pase, las raids y los exclusivos salen normales.
- Se guarda en la unidad (`u.shiny = true`); `Perfiles.normalizar` lo conserva sólo si es `true`.
- **Combate**: `Partida.statsUnidad` multiplica el daño por `Unidades.bonoShiny(u)` (×1,05).
- **Evolución**: la nueva unidad es Shiny si alguna de las 3 copias lo era.
- **Intercambio**: la unidad viaja entera, así que conserva el Shiny.
- Pruebas en `Reclutamiento.spec.luau`: frecuencia (~1,5 % en 20.000 tiradas), bono, y evolución con y sin copias
  Shiny.

## Aspecto
- **Tarjetas** (`Comic.marcoShiny`): borde dorado con un brillo que lo recorre y la etiqueta «★ SHINY». En Unidades
  (grilla y ficha, con «+5 % de daño» y el daño ya multiplicado), escuadrón del lobby, perfil y tarjetas de partida
  (el atributo `Escuadron` lleva un quinto campo `:1`).
- **En partida** (`Efectos.client.luau`): el modelo con atributo `Shiny` lleva un contorno dorado (`Highlight`) y
  chispas doradas que flotan.
- **Invocación** (`Cinematica.luau`): un Shiny siempre tiene revelación grande (aunque sea Común), con halo dorado
  extra, destello y «★ SHINY ★» arriba del nombre; en la x10 la carta lleva el marco Shiny.

## Verificado (18/11/2026)
22 pruebas pasan; en Play se vieron la tarjeta con el marco Shiny, la revelación de un Spider-Man Shiny y el brillo
dorado de una unidad Shiny en el mapa.

## Sin probar
- Una unidad Shiny real del perfil en el lobby y en partida (el estado del servidor no se puede tocar desde las
  herramientas de prueba; se probó dibujando el marco y el brillo a mano).
- El límite de Roblox de 31 `Highlight` visibles: si hubiera más Shiny en pantalla, los de más no brillan.
