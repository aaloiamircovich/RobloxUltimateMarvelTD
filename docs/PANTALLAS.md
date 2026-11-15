# Invocaciones y pantallas (etapa 3 del roadmap estético)

Decidido por el usuario el 14/11/2026: invocación **cinemática completa**, el Mítico con **momento propio**, fin de
partida con el **escuadrón posando y los premios** (sin estrellas), **transición de viñeta**, **pantalla de carga**,
**evolución animada** y **subidas de nivel**.

## Invocación (`src/client/Cinematica.luau`)
- Se dispara al invocar en el Banner 1 (`Coleccion.client.luau`) y en el Banner 2 (`Hud.client.luau`), después de
  que el servidor ya decidió qué salió: es sólo visual.
- Pantalla completa con un **portal** que gira; su color insinúa la mejor rareza de la tirada (gris, azul, violeta,
  dorado). Los Míticos y el Secreto se disfrazan de azul.
- **x1**: revelación grande. **x10**: 10 cartas boca abajo que se dan vuelta de a una; si sale Épico o más se detiene
  y lo muestra en grande. **SALTAR** da vuelta todas sin pausas; al final, **LISTO**.
- **Revelación**: el personaje de cuerpo entero en 3D (modelo de `ReplicatedStorage.Retratos`, con su reposo),
  rayos del color de la rareza y un cartel con nombre, rareza y habilidad. Se sigue con un clic (o solo, a los 4 s).
- **Mítico y Secreto**: el portal azul tiembla y se «rompe», la pantalla se pone dorada, rayos, la cámara gira
  alrededor del personaje y su habilidad aparece como grito («TORMENTA DIVINA»). Hasta 7 s.
- Si algo falla a mitad de camino, la pantalla se limpia igual (`correr`), para no dejar el juego tapado.

## Evolución
Al evolucionar (Unidades → Evolucionar): el modelo viejo se llena de luz del color de la nueva rareza, aparece el
nuevo girando con rayos y el cartel «¡EVOLUCIONÓ!» con su nombre.

## Fin de partida (`Main.client.luau`)
- **Victoria**: cartel ¡VICTORIA!, el escuadrón en 3D que salta de a uno, los premios del acto como fichas que caen
  de a una («+50 gemas», «+1 núcleo», «+30 XP») y las **subidas de nivel** («Hawkeye Nv 7 → 8»).
- **Derrota**: escuadrón gris e inclinado y un consejo de juego.
- Las subidas las junta el servidor durante la partida (`d.subidas` en `Partida.luau`, cada vez que una unidad sube al
  ganar XP en una oleada) y las manda al terminar en el atributo `Subidas` del jugador (`heroId:desde:hasta,…`).

## Transición de viñeta (`src/client/Transicion.client.luau`)
Cuando el personaje aparece a más de 60 studs de golpe (entrar o salir de una partida, Viajar, puertas de los
interiores, portal del Sanctum, reaparecer), una viñeta roja tapa la pantalla y se barre hacia la derecha.

## Pantalla de carga (`src/first/Carga.client.luau`, en ReplicatedFirst)
Al entrar al juego: fondo rojo con franjas, cartel «ULTIMATE MARVEL TD», barra de carga y un consejo. Se va hacia
arriba cuando el juego cargó y el personaje apareció (mínimo 2 s). La misma pantalla se usa para el viaje entre el
lobby y los servidores de partida (`TeleportService:SetTeleportGui`). `default.project.json` ahora mapea
`ReplicatedFirst` (si se cambia el proyecto hay que reiniciar `rojo serve`).

## Verificado en Play (14/11/2026)
Invocación x1 de Thor (portal falso azul, pantalla dorada, rayos, Thor girando y el grito) y x10 (cartas, Spider-Man
Épico en grande, mesa final con LISTO); evolución de Thor a King Thor; pantalla de victoria (escuadrón, 3 premios y 2
subidas) y de derrota (escuadrón gris y consejo) forzando el final desde el servidor; transición al mover al
personaje 120 studs; pantalla de carga. Sin errores en la consola.

## Sin probar
- Una invocación real desde el botón del Banner 1 y del Banner 2 (se probó llamando a la cinemática directamente) y una
  partida terminada de verdad (el final se forzó).
- La pantalla del viaje entre servidores: sólo se ve en el juego publicado.
- Celular (los tamaños se escalan con la pantalla, pero no se probó en 375 px).
