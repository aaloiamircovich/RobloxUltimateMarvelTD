# Partida: Historia por actos, salas, mapas caminables e interfaz

Decidido por el usuario el 2026-11-10 tomando como referencia Anime Galaxy y All Star Tower Defense.
Reemplaza el flujo actual (un mapa a la vez para todo el servidor, cámara fija, oleadas con botón).

## Historia por actos
- Cada mapa tiene **5 actos de 10 oleadas**; la oleada 10 es el **jefe** del acto.
- Ganar un acto abre el siguiente; ganar el **acto 5** abre el **Infinito de ese mapa** y el **mapa siguiente**.
  Reemplaza las estrellas.
- Enemigos y dificultad del 2D, escalados por acto.
- **Premios**: primera victoria del acto = 50 gemas × número de acto (50 a 250) + 1 núcleo;
  repetirlo = 10 gemas + XP. Se quitan las gemas por oleada actuales.
- **Pesadilla** (interruptor de la sala, se habilita al ganar el acto en normal): enemigos +50 % vida y
  +10 % velocidad, premios ×2.

## Salas
- Panel de Historia como la captura de Anime Galaxy: lista de mapas (con candado), actos con jefe y premio
  de primera vez, y a la derecha la sala: hasta **4 jugadores**, «Sólo amigos», «Pesadilla», premios,
  **Solo** y **Crear sala**.
- **Ahora**: cada sala juega su propia copia del mapa en el mismo servidor, lejos del HUB (se prueba en Studio).
  **A futuro**: servidores separados (teleport a un servidor reservado por partida).
- **Dinero**: cada jugador tiene el suyo (arranca con 1.200), coloca sus propias unidades y gana por sus bajas;
  el bono por oleada se da a todos.
- **Velocidad x1/x2**: la decide el anfitrión.

## Mapa y cámara
- **Cámara libre**: el jugador camina por el mapa con su personaje (sin cámara fija ni vista aérea).
- **Mapas grandes y decorados**: se rehacen los 4 con el mismo recorrido del 2D a escala ×2 (200×150 studs) y decorado
  temático generado con ForgeGUI (base Vengadores, Manhattan, Wakanda, Sanctum).
- **Colocar donde apunta el mouse**, en cualquier parte del mapa, **sin grilla**: no sobre el camino ni pegado a
  otra unidad. Se mantienen las reglas de terreno del 2D (unidades de montaña/altura y de agua).

## Oleadas y base
- La base tiene **500 de vida** en una barra arriba (mapa · acto · oleada x/10 · temporizador).
- Cada enemigo que llega le quita su **vida restante ÷ 10** (mínimo 5); un **jefe** que llega la destruye.
- La primera oleada arranca cuando todos aprietan **«Listo»** (o a los 60 s). Después hay hasta **60 s** entre
  oleadas; si se limpia antes, arranca la siguiente. **«Saltar»** la adelanta y da **+10 % del bono de oleada**;
  en salas necesita a todos.
- **Juego automático** = saltar oleadas automáticamente.

## Interfaz dentro de partida
- Arriba: barra de vida de la base, mapa · acto, oleada x/10 y temporizador; aviso «¿Listo?».
- Panel lateral: velocidad x1/x2, administrador de unidades (lista para mejorar/vender), juego automático,
  volver al lobby y tarjeta de premios del acto.
- Abajo: escuadrón con costo de colocar y dinero de partida.
- Al tocar una unidad: stats, próxima mejora con precio, **Vender (devuelve 50 % de lo invertido)** y
  **prioridad de objetivo**: Primero / Último / Más fuerte / Más débil.
- Estilo cómic (Comic.luau): viñeta amarilla arriba con barra de vida y círculos de oleada y reloj; tarjetas
  del escuadrón con retrato 3D, borde del color de la rareza y teclas 1–6; panel de la unidad a la izquierda
  con anillo de alcance; cartel «¡OLEADA n!» / «¡JEFE!», pantalla de victoria/derrota con premios, números
  de daño y «+💰» al ganar dinero. Se achica sola en pantallas chicas.
