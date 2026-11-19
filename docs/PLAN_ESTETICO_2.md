# Plan estético 2 · 17/11/2026

Sigue a `ROADMAP_ESTETICA.md` (etapas 1–4 hechas). Decidido con el usuario en una entrevista de 20 preguntas,
comparando con All Star Tower Defense, Anime Adventures, Tower Defense Simulator, Anime Defenders y Anime Vanguards.

## Decisiones
| Tema | Decisión |
| --- | --- |
| Qué molesta hoy | La interfaz, el lobby, personajes y animaciones (el sonido ya está planeado para diciembre) |
| Estilo de interfaz | **Limpio estilo Anime Vanguards, en todo**: también cinemáticas, entrada de jefe, invocación, ¡VICTORIA!, transición y pantalla de carga. Reemplaza al cómic rojo |
| Paleta | Paneles gris azulado muy oscuro y semitransparentes, bordes finos; **rojo Marvel** en botones principales, **dorado** en premios |
| Plataforma | **Sólo PC** (sin pasada de celular en este plan) |
| Shiny | **Sí, con un bonus chico**: 1,5 % por invocación, brillo y marco especial, **+5 % de daño** (a confirmar el número al diseñarlo) |
| Skins | **Más adelante** (anotado, fuera de este plan) |
| Tarjetas | **Retrato 3D con marco de rareza** (brillo animado en Mítico, Secreto y Shiny; estrellas de mejora; rol) |
| Menús nuevos | Inventario con filtros y búsqueda, ficha de la unidad, perfil del jugador, notificaciones |
| HUD de partida | Panel de unidad renovado y barra de oleadas |
| Empezar partida | **Botón ¡JUGAR! + salas físicas** mejoradas (plataformas con portal, cartel 3D del mapa, cuenta regresiva) |
| Unidades en el lobby | **Te sigue tu escuadrón** (en chico, como familiares) **y vitrina personal** |
| Vida del lobby | Encargados que hablan, eventos (Quinjet que aterriza, Bifrost, portal de Strange), ciclo de día y noche |
| Lobby | Mejores puentes y caminos entre islas |
| Avatar | El de Roblox (sin transformarse) |
| Animaciones de unidades | Festejo al mejorar, revisar los ataques flojos, reposo propio para los 25 únicos |
| Ultimate con botón | **No**: las habilidades siguen automáticas como en el 2D |
| Enemigos | Reacción al golpe, ataques propios de los jefes en sus fases, estados visibles (congelado, quemado…) |
| Audio (diciembre, ForgeGUI) | Música por mapa (11) + lobby, jefe y victoria; sonido por familia de ataque y por único; sonidos de interfaz; ambiente por mapa |
| Orden | Interfaz → HUD → Shiny → lobby → animaciones → audio |

## Lo que hacen los juegos de referencia (y tomamos)
- **Anime Vanguards**: interfaz oscura y limpia con barra superior animada, filtros de unidades con búsqueda,
  votación para empezar y saltar oleadas, rasgos con un NPC, familiares que te acompañan, Shiny 1,5 %.
- **Anime Defenders / Anime Adventures**: portal de invocación en el lobby, Shiny y cosméticos ligados a la unidad,
  unidades mostradas en el lobby.
- **Tower Defense Simulator**: ascensores físicos en el lobby para empezar partida, skins y emotes, lobby decorado por
  temporada.
- **All Star Tower Defense (X)**: hub caminable con zonas y botón de viaje, animación de invocación que se puede
  saltar, orbes equipables y árbol de habilidades.

## Fase A · Interfaz limpia (primero) — ✅ 18/11/2026
1. **Sistema de estilo nuevo**: reemplazar `Comic.luau` por un módulo de estilo (`Estilo UI`) con paneles oscuros
   semitransparentes, esquinas suaves, borde fino, sombra, tipografía limpia (títulos en una fuente gruesa sin
   inclinación, textos en Gotham/Montserrat), botones con estados (normal, encima, presionado, deshabilitado) y
   animaciones cortas (aparecer, deslizar, rebote suave).
2. **Barra superior** del lobby (monedas, nivel, botones) y columnas laterales rehechas en el estilo nuevo.
3. **Unificar todos los paneles**: Unidades/Banner 1 y Tienda (hoy con el estilo viejo gris), Banner 2, Pase,
   Misiones, Premios, Ajustes, Intercambio, Rasgos, Grados, Mascotas, Monturas, Bailes, Evento, Ranking, Raids.
4. **Tarjetas de unidad**: retrato 3D animado, marco por rareza (brillo animado en Mítico y Secreto), estrellas de
   mejora, nivel y rol.
5. **Inventario con filtros**: búsqueda por nombre, filtro por rareza, rol y estilo, orden por nivel o poder,
   stats al pasar el mouse.
6. **Ficha de la unidad**: modelo grande girando, stats, habilidad, rasgo, grados, evolución, botones de equipar y
   vender.
7. **Perfil del jugador**: nivel, unidades favoritas, logros y estadísticas; visible para otros.
8. **Notificaciones**: avisos que entran por un costado (logro, nivel de cuenta, premio listo, amigo conectado).
9. **Rehacer en el estilo nuevo** lo cómic: invocación (portal, cartas, Mítico), evolución, fin de partida, entrada
   de jefe, transición y pantalla de carga.

## Fase B · HUD de partida — ✅ 18/11/2026
1. **Panel de unidad renovado**: retrato, estrellas de mejora, próximo stat que sube, botón MEJORAR grande, vender
   y prioridad de objetivo.
2. **Barra de oleadas**: las que vienen, el jefe al final y los tipos de enemigo de cada una.
3. Barra superior, tarjetas del escuadrón para colocar, votaciones y carteles de oleada en el estilo nuevo.

## Fase C · Shiny — ✅ 18/11/2026, `docs/SHINY.md`
- Sistema: 1,5 % por invocación (ambos banners), se guarda en la unidad, se ve en todas partes, +5 % de daño.
  Toca perfil, invocación, intercambio y combate: necesita sus pruebas.
- Visual: brillo dorado y partículas en el modelo, marco especial en la tarjeta, revelación propia al invocar.

## Fase D · Lobby — ✅ 18/11/2026, `docs/LOBBY.md`
1. **Salas físicas**: plataformas con portal en el Sanctum y la Torre Baxter (y una sala rápida en la isla
   central), cartel 3D con el mapa y acto elegidos, cuenta regresiva, los jugadores parados encima. El botón
   ¡JUGAR! sigue para ir rápido.
2. **Tu escuadrón te sigue** en chico detrás de tu avatar (como las mascotas), visible para todos.
3. **Vitrina personal**: pedestales con tus mejores unidades posando (dónde: a definir).
4. **Encargados que hablan**: al acercarte saludan con un globo y una animación.
5. **Eventos del lobby**: el Quinjet aterriza en la isla central, pasa el Bifrost en Asgard, se abre un portal de
   Strange en el Sanctum.
6. **Día y noche**: ciclo de unos 20 minutos, faroles y ventanas que se prenden de noche.
7. **Puentes y caminos**: más anchos y decorados, que conecten mejor y llenen los huecos entre islas.

## Fase E · Animaciones
1. **Festejo al mejorar**: animación corta de pose al subir de mejora.
2. **Reposo propio para los 25 únicos** (Thor gira el martillo, Strange flota, Magneto levita…).
3. **Revisión de los 212 ataques**: hoja con capturas en el momento del golpe; rehacer los que no tienen fuerza.
4. **Enemigos**: reacción al golpe (sacudida y destello), **estados visibles** (hielo, fuego, aturdido, veneno,
   lento) y **jefes con ataques propios** en sus fases (invocar, escudo, furia) con animación y efecto.

## Fase F · Audio (diciembre, cuando haya créditos de ForgeGUI)
Música de lobby, jefe, victoria y una por cada uno de los 11 mapas; sonido por familia de ataque y por cada único;
sonidos de interfaz; ambiente por mapa. El reproductor ya está listo en `src/client/Sonido.luau`.

## Fuera de este plan
Skins, celular, ultimate con botón, transformarse en héroe, decoración por temporada, zona del jefe semanal y NPCs
caminando por el lobby.
