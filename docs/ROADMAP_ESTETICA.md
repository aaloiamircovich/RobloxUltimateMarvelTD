# Roadmap estético · 14/11/2026

Las mecánicas están completas (ver `AUDITORIA_Y_ROADMAP.md`, sección 0). Este roadmap es para que el juego **se vea y
se sienta** como Anime Galaxy o ASTD: el espectáculo está en los ataques, las invocaciones y los mapas.
Cada etapa se decide con el usuario antes de empezar. Herramientas: IA de Roblox (mallas, texturas, materiales,
animaciones) ahora; ForgeGUI (audio, íconos, imágenes de UI) cuando vuelvan los créditos (~diciembre 2026).

## Etapa 1 · Combate que impresione (lo que más se mira) — ✅ 14/11/2026, `docs/COMBATE_VISUAL.md`
1. **Habilidades con efecto propio**, empezando por Míticos y Legendarios: Mjolnir con rayos, Gungnir, escudo
   del Capitán que rebota, garras, telarañas, portales de Strange, chasquido… Partículas, rayos (`Beam`), ondas y
   sacudida de cámara cortita.
2. **Ataques básicos por personaje**: hoy hay 3 genéricos (flecha, rayo, impacto). Proyectil, estela e impacto con
   el color y la forma de cada héroe.
3. **Golpes y muertes**: destello blanco al recibir daño, enemigo que se desarma o se disuelve al morir, monedas
   que vuelan al dinero (sin onomatopeyas: el usuario no las quiere).
4. **Entrada de jefe**: viñeta de cómic con su nombre y frase, cámara que lo muestra 2 s y temblor al pisar.

## Etapa 2 · Mapas con ambiente
1. **Iluminación por mapa**: hora del día, niebla (`Atmosphere`), brillo (`Bloom`), corrección de color y cielo
   propio. Hoy todos comparten la luz del lobby: Dimensión Oscura violeta, The Raft de noche con tormenta, Asgard
   dorado al atardecer, Knowhere en el espacio.
2. **Clima y partículas**: lluvia y relámpagos en The Raft, nieve o ceniza en Latveria, hojas y luciérnagas en
   Savage Land, polvo cósmico en Knowhere.
3. **Detalle vivo**: agua que se mueve, banderas, humo de chimeneas, luces que parpadean, pájaros o naves pasando.
4. **Cámara de partida**: ángulo y zoom elegidos por mapa, y paneo al iniciar mostrando el recorrido.

## Etapa 3 · Invocaciones y pantallas (los momentos que se recuerdan)
1. **Invocación cinemática**: portal o cápsula, color por rareza que se insinúa antes de revelar, el personaje
   aparece en 3D con pose y destellos; Mítico con efecto especial y pantalla dorada.
2. **Victoria y derrota**: escuadrón posando, premios que caen uno por uno, estrellas del acto.
3. **Transiciones**: viñeta de cómic que barre la pantalla al entrar a partida o teletransportarse; pantalla de
   carga con ilustración y consejos.
4. **Subir de nivel / evolucionar**: animación de la tarjeta, luz y cambio de modelo en vivo.

## Etapa 4 · Unidades con presencia
1. **Aura por rareza** en el piso (anillo o partículas: épico violeta, legendario dorado, mítico arcoíris) y
   efecto distinto al máximo de mejoras.
2. **Revisión de los 212 modelos** en partida (script que coloca y saca foto de cada uno) y arreglo de los que se
   ven mal: armas que atraviesan, flotan o miran para otro lado.
3. **Animación de colocación** propia (aterrizaje de Thor, telaraña de Spider-Man, portal de Strange) para los más
   invocados.

## Etapa 5 · Interfaz con identidad (con ForgeGUI, desde ~diciembre)
1. Íconos y marcos dibujados estilo cómic en lugar de los generados por código.
2. Tarjetas de personaje con arte, fondo por rareza y brillo animado.
3. Audio: música orquestal y efectos (el reproductor ya está listo en `src/client/Sonido.luau`).

## Orden sugerido
Etapa 1 → 2 → 3 → 4, y la 5 cuando haya créditos. La 1 es la que más se nota en una partida; la 2 es la más
barata para que cada mapa se sienta distinto.
