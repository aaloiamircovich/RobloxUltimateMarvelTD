# Combate visual (etapa 1 del roadmap estético)

Decidido por el usuario el 14/11/2026: **25 efectos únicos + familias**, intensidad **espectacular**, enemigos que
**se disuelven en partículas**, **entrada de jefe**, **monedas que vuelan** y **sacudida de cámara**. **Sin
onomatopeyas** en ninguna parte del juego (se sacó la que acompañaba al cartel de oleada).

## Cómo funciona
- El servidor ya no crea piezas para los ataques. `Partida.luau` avisa por el remoto no confiable `Ataques`
  (lo crea `Main.server.luau`) **quién atacó** (el id base del personaje), desde dónde, a dónde, si fue crítico y un
  dato extra (munición de Hawkeye, el efecto del modelo o el radio de la salpicadura). Si un aviso se pierde, sólo
  falta un destello: el daño lo sigue calculando el servidor.
- Cada cliente lo dibuja en `src/client/Ataques.client.luau`, en una carpeta local (`workspace.EfectosLocales`).
  No se dibuja lo que está a más de 260 studs de la cámara.
- **Calidad baja** (Ajustes) y más de 220 piezas vivas: menos partículas, sin luces, sin estelas ni copias para
  disolver. `TAMANO` (1,5) agranda todos los ataques; los críticos salen un 50 % más grandes y con destello blanco.

## Efectos únicos (27)
Los 8 Míticos, los 16 Legendarios, Scarlet Witch (Secreta) y los exclusivos Odin y Knull, en `UNICOS`. Ejemplos:
Thor (rayo en cadena + rayo del cielo), Hulk (golpe, onda verde, púas de roca y temblor), Doctor Strange (círculos
mágicos naranjas), Iron Man (doble repulsor; unirrayo en crítico), Jean Grey (bola de fuego Phoenix y columna en
crítico), Magneto (disco de metal con estela violeta), Black Bolt (anillos sónicos), Mister Fantastic (brazo que se
estira), Sentry (haz y columna de luz), Loki (proyectil y copia ilusoria).

## Familias (los otros 80)
`PERSONAJES` asigna a cada uno una familia y un color: **balas**, **flecha** (Hawkeye cambia color y efecto según su
munición), **energía**, **haz**, **eléctrico**, **fuego**, **hielo**, **magia**, **psíquico**, **golpe**, **corte**,
**telaraña**, **simbionte** y **escudo** (el Capitán América: el escudo va y vuelve). Un personaje que no está en la
lista usa el efecto de su modelo (flecha → flecha, rayo → energía, impacto → golpe).
Otros avisos: `cadena` (saltos de rayo), `area` (salpicadura) y `pisoton` (Korg).

## Muertes, monedas y jefes
- Al morir, el servidor marca al enemigo (`Muerto`, y `Asesino` con el id del jugador que cobró) y lo borra 0,25 s
  después. El cliente copia el modelo, lo vuelve luz blanca que pasa al color de su categoría y se deshace en
  partículas. Los jefes, además, onda, columna de luz y temblor.
- **Monedas**: a quien cobró, 4 monedas saltan desde el enemigo y vuelan al contador de dinero (`Main.client.luau`).
- **Entrada de jefe**: el servidor marca al jefe (`Jefe` = nombre). Franjas de cine, viñeta roja con el nombre y una
  frase propia (`FRASES`, 19 jefes), la cámara lo muestra 2,2 s y la pantalla tiembla a cada paso. Una vez cada 20 s.
- **Sacudida de cámara** en golpes fuertes (Hulk, Thor, Sentry, Black Bolt en crítico…), muertes de jefe y entradas;
  se apaga en Ajustes («📳 Sacudida de cámara», `Preferencias.sacudida`).

## Verificado en Play (14/11/2026)
Partida en la Base de los Vengadores: llegan los avisos de ataque (Dagger, con críticos) y se ven; los 45 estilos
(27 únicos, familias de muestra, desconocido, cadena, área y pisotón), con y sin crítico, se dibujan sin errores;
un jefe de prueba hace su entrada (franjas, viñeta, cámara) y al morir se disuelve con las monedas volando. Las 22
pruebas pasan.

## Sin probar
- Ver uno por uno los 27 únicos de cerca (las capturas toman un solo cuadro; se vieron Thor, Hulk, Iron Man,
  Captain Marvel, Doctor Strange y Dagger).
- Una partida larga con muchas unidades a la vez (rendimiento) y en celular.
- La entrada de un jefe real de la oleada 10 (se probó con uno puesto a mano).
