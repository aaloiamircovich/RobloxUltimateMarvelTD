# Interfaz y audio

Decidido por el usuario el 14/11/2026.

## Estilo limpio (decidido el 17/11/2026, reemplaza al cómic)
Como Anime Vanguards, en todo el juego (también cinemáticas, carteles, transición y pantalla de carga):
- **Base en `src/client/Comic.luau`** (conserva el nombre y las funciones): paneles de vidrio oscuro
  (`FONDO` al 10 % de transparencia), esquinas de 10–12 px, borde fino gris (`BORDE`), títulos en **Gotham Black**
  sin inclinar, texto en Gotham Bold, sin contornos gruesos. Rojo Marvel (`ROJO`) para lo principal, dorado
  (`AMARILLO`) para premios, `ROJO_OSCURO` (ahora gris azulado) para tarjetas y filas, `TENUE` para texto secundario.
- **Botones** (`Comic.boton`): relleno con degradado suave, se agrandan al pasar el mouse y se hunden al apretar.
  **Baldosas del lobby** (`Comic.botonIcono`): vidrio oscuro con una franja del color de la sección abajo; el borde
  toma ese color al pasar el mouse. **¡JUGAR!** va relleno de rojo. `Comic.resaltar` pinta el borde de rareza.
- **Paneles** (`Comic.panel`): título arriba a la izquierda con una línea roja debajo, ✕ gris, aparecen creciendo.
- Lobby: columna izquierda de 6 baldosas; derecha en **grilla de 2 columnas** arriba (en una columna tapaba
  ¡JUGAR!); monedas en vidrio con el borde del color de cada moneda; escuadrón con **tarjetas de retrato 3D**.
- **Unidades** (`Coleccion.client.luau`): buscador, filtro por rareza, orden (rareza, nivel, nombre), tarjetas con
  retrato 3D y marco de rareza (brillo que recorre el marco en Mítico y Secreto, tilde verde si está en el
  escuadrón) y **ficha**: modelo girando, rareza, categoría, nivel y XP, daño, alcance, ataques/s, rasgo, grados,
  habilidad, y botones Equipar/Sacar, Vender y Evolucionar.
- **Perfil**: avatar, nombre, nivel, unidades, actos ganados, logros, enemigos y jefes derrotados y las 3 mejores
  unidades; a la derecha, los jugadores del servidor para ver su tarjeta (remoto `PerfilPublico`, sólo jugadores de
  este servidor).
- **Avisos** (`src/client/Avisos.luau`): tarjetas que entran por la derecha y se van a los 4 s (nivel de cuenta,
  premio diario listo, amigo conectado, mensajes del servidor fuera de partida).
- Cinemáticas limpias: invocación (halo de luz en vez de rayos, cartas con dorso oscuro y rombo rojo, nombre grande
  con línea de la rareza), evolución, entrada de jefe (vidrio con franja roja), carteles de oleada («OLEADA 3»,
  «LLEGA EL JEFE»), fin de partida (VICTORIA en dorado, DERROTA en gris), cartel del mapa, transición (velo oscuro con
  una línea roja) y pantalla de carga (fondo oscuro, título blanco, barra roja fina).

## HUD del lobby con identidad Marvel (18/11/2026)
Pedido: «se ve genérica» y «le falta movimiento». Decidido: retratos de héroes, cortes en diagonal, tarjeta de
jugador, movimiento medio y botones agrupados.
- **Tarjeta de jugador** arriba a la izquierda (avatar, nombre, nivel y XP; al tocarla abre el perfil). La barra de
  nivel suelta del centro desaparece.
- **Botones agrupados**: izquierda UNIDADES, INVOCAR, INVENTARIO, TIENDA; derecha VIAJAR, MISIONES, PASE, EVENTO,
  PREMIOS y **MÁS**, que abre una fila con PERFIL, NOVEDADES, CAMBIAR y AJUSTES.
- **Sin retratos en los botones** (se probaron en UNIDADES, INVOCAR y ¡JUGAR! y se sacaron a pedido): vuelven los
  íconos.
- **Monedas** abajo de TIENDA, en la misma columna; la columna arranca justo debajo de la tarjeta de jugador.
  Íconos 3D generados con la IA de Roblox (gema violeta, moneda dorada con estrella, núcleo azul) en
  `ReplicatedStorage.IconosMonedas` (vive en la place, no en el repo, como `Retratos`); se balancean ±35°. Sin el
  modelo vuelve el emoji. Al pasar el mouse, cartel al costado con qué es, para qué sirve y dónde se consigue.
- **G y B** con la misma baldosa que el resto (`Comic.botonIcono`); la franja de G se pone verde al montar.
- **Corte en diagonal** (`Comic.diagonal`) arriba a la derecha en botones, casillas del escuadrón y ¡JUGAR!, con la
  esquina del color de acento (al pasar el mouse se pinta todo el borde). Sólo piezas casi cuadradas: en las anchas
  el degradado girado de Roblox se come un tercio; para eso haría falta una imagen 9-slice (ForgeGUI, diciembre).
- **Movimiento**: botones crecen 7 % y el ícono sube al pasar el mouse; las ventanas entran subiendo con rebote;
  las monedas suben contando (`Comic.contar`); la XP se llena animada; ¡JUGAR! tiene un brillo que lo cruza cada
  3,5 s (`Comic.brillo`).
- Referencias: el repositorio `izzyfrm/roblox-ai` no sirvió (maquetas planas y miniaturas promocionales).

## Ventanas del lobby (19/11/2026)
Decidido: fondo desenfocado y oscuro, tarjetas oscuras con acento, un molde común para todas.
- **Fondo**: con cualquier ventana abierta (paneles del HUD o Colección) el mundo se desenfoca (`BlurVentanas`, 16) y
  oscurece (`VeloVentanas`), y se esconden tarjeta de jugador, columnas, escuadrón, ¡JUGAR! y G/B
  (`Comic.registrarVentana`, evento `Comic.ventanas`). Al entrar a una partida se cierran todas.
- **Una ventana a la vez**: abrir un panel del HUD cierra Colección y al revés.
- **Molde** (`Comic.moldear`, aplicado al cuerpo de cada panel y de Colección): todo bloque de color fuerte de
  60×60 o más con contenido pasa a tarjeta oscura con el color en el borde y una franja abajo; el texto oscuro se
  aclara. Los botones de acción chicos, las barras y sus rellenos quedan igual. Se repasa al abrir cada ventana. Una
  pieza que no deba moldearse lleva el atributo `SinMolde`.
- Los títulos de Colección van en mayúsculas como los demás. El oro se escribe 🟡 (Roblox no dibuja 🪙).

## HUD de partida (fase B, 18/11/2026)
- **Panel de unidad** (izquierda, decidido por el usuario): retrato con marco de rareza, nombre, rareza y nivel,
  rasgo y grados; **5 estrellas** de mejora; daño, alcance y ataques/s con **lo que queda tras la próxima mejora en
  verde** (`27 → 32`, calculado con `Mejoras.efecto`); qué trae la próxima mejora; botón **MEJORAR** grande con el
  costo (dorado si alcanza la plata); objetivo, munición (Hawkeye) y Mover / Vender en una fila.
- **Barra de oleadas**: un segmento por oleada (pasadas tenues, la actual roja, el jefe al final con ☠) y una franja
  con **AHORA** y **PRÓXIMA**: los enemigos de esta oleada y de la siguiente con su cantidad. El servidor los publica
  en los atributos `Composicion` y `Proxima` de la partida al empezar cada oleada (`Partida.luau`). En Infinito no hay
  segmentos (no tiene total).
- Tarjetas del escuadrón con degradado de rareza y la tecla 1–6 en un círculo oscuro.

## Interfaz (diseño anterior, 14/11/2026)
- **PC primero**: diseño base 1280×720. Cada bloque del HUD tiene su `UIScale` (`Comic.escalar`) entre ×0,55 y ×1,35
  según el lado más corto de la pantalla, así nada se pisa en ventanas chicas.
- **Lobby con barras compactas** (como Anime Defenders):
  - Izquierda: columna de íconos de 84 px (Tienda, Unidades, Inventario, Misiones, Invocar, Pase).
  - Derecha: Viajar, Perfil, Evento, Novedades.
  - Arriba al centro: monedas y barra de nivel de cuenta.
  - Abajo al centro: escuadrón (casillas de 92 px).
  - Abajo a la derecha: **¡JUGAR!** grande; sube por encima del escuadrón si la ventana es angosta.
  - Los botones G (montura) y B (bailes) también se escalan.
- **Colocar unidades**: al elegir una tarjeta aparece el personaje fantasma semitransparente donde apunta el
  mouse, con un disco y el anillo de alcance en verde (se puede) o rojo (no se puede); si no se puede, un cartel
  junto al puntero dice el motivo (camino, terreno, fuera del mapa, otra unidad cerca).

## Audio
- **Todo generado con ForgeGUI** (música y efectos propios) y publicado en la cuenta de Roblox del usuario.
- **Música épica orquestal**: lobby (heroica, tranquila), partida (acción) y jefe (intensa, con coro).
- Efectos previstos: clic, abrir panel, premio, invocación (normal y rara), colocar, mejorar, vender, ataque
  (flecha, rayo, impacto), muerte de enemigo, golpe a la base, inicio de oleada, llegada del jefe, victoria y derrota.
- **Sistema listo, sin pistas todavía.** `src/client/Sonido.luau` tiene la tabla de IDs (`MUSICA` y `EFECTOS`) y el
  reproductor; con el ID vacío no suena nada. `Musica.client.luau` pone música de lobby, de partida o de jefe (cuando
  el mensaje de la oleada dice JEFE o hay jefe de raid) y suena oleada, jefe, golpe a la base, bajas (cuando sube el
  dinero), victoria y derrota. Clic en todos los botones de `Comic`; colocar, mejorar y vender en la partida;
  invocar en el banner. Falta: sonido por tipo de ataque (flecha, rayo, impacto).
- **Pendiente**: ForgeGUI cobra un mínimo de **1600 créditos por pedido** (música de cualquier duración y también
  efectos) y la cuenta tiene 1024. Al tener créditos: generar, publicar y pegar los IDs en `Sonido.luau`.
