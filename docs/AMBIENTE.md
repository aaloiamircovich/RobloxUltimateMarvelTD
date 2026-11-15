# Ambiente de los mapas (etapa 2 del roadmap estético)

Decidido por el usuario el 14/11/2026: estilo **cine vibrante**; clima con **lluvia y relámpagos**, **ceniza y
polvo**, **naturaleza** y **nieve**; detalles con **agua que se mueve**, **humo y fuego**, **cosas que pasan por el
cielo** y **luces que parpadean**; **paneo del recorrido** al empezar.

## Cómo funciona
Todo lo hace cada cliente en `src/client/Ambiente.client.luau` al entrar a una partida (atributo `Partida`), así
funciona igual en Studio (partidas en el mismo servidor que el lobby) y en los servidores de partida. Guarda la luz,
el cielo, los efectos y el agua del lobby, los cambia por los del mapa y los **restaura al volver**. La tabla
`AMBIENTES` tiene un ambiente por mapa (`level_1` … `level_11`).

| Mapa | Luz | Clima | Detalles |
| --- | --- | --- | --- |
| Base de los Vengadores | Día de sol | — | Quinjet dando vueltas, pájaros, neón que parpadea |
| Nueva York | Atardecer naranja | — | Pájaros, neón |
| Wakanda | Tarde dorada | Hojas y luciérnagas | Agua turquesa con olas, pájaros |
| Sanctum | Noche de luna con estrellas | Chispas místicas | Fuego en los braseros |
| Instituto Xavier | Mañana suave | Pétalos | Estanque azul, pájaros |
| Knowhere | Espacio (estrellas, niebla violeta) | Polvo cósmico | Naves cruzando al fondo, vapor, neón |
| Latveria | Nublado verdoso | Nieve | Fuego verde en los faroles, humo en fábricas y chimeneas, foso verde |
| Asgard | Dorado | Chispas | Dragón volando, fuego en los braseros, mar cósmico |
| Dimensión Oscura | Violeta | Brasas rosas | Charcos del vacío, neón |
| Savage Land | Selva de mediodía | Hojas y luciérnagas | Pterodáctilos, pájaros, antorchas con fuego, río |
| The Raft | Noche de tormenta | Lluvia y relámpagos | Mar agitado, luces rojas de emergencia que prenden y apagan |

- **Luz**: hora, brillo, ambiente, `Atmosphere`, corrección de color, `Bloom` y `SunRays`. El cielo del lobby se
  mantiene de día; de noche y nublado se usa un cielo propio (estrellas o sin sol).
- **Clima**: cajas invisibles que siguen a la cámara y sueltan partículas (lluvia y nieve desde arriba; polvo,
  brasas, chispas y luciérnagas flotando). La tormenta aclara la pantalla y dibuja un rayo a lo lejos cada 5–13 s.
- **Agua**: color, tamaño y velocidad de las olas del agua de terreno de cada mapa.
- **Fuego y humo**: en las piezas del kit que dice el ambiente (`fuego`, `humo`). El decorado llega por partes
  (streaming): se agregan también a las piezas que llegan después.
- **Luces**: cálidas titilan apenas, el neón parpadea de vez en cuando, las de emergencia prenden y apagan.
- **Cielo**: bandadas de pájaros hechas con piezas; Quinjet, nave, dragón y pterodáctilo son modelos de
  `ReplicatedStorage.Cielo` (generados con la IA de Roblox, se guardan en el lugar, no en Git; el Quinjet es copia
  del del lobby). El pterodáctilo tiene el pivote girado 180° para que vuele hacia adelante.
- **Paneo**: en la oleada 0, la cámara recorre el camino del portón a la base en 3,6 s con un cartel del mapa y el
  acto; un clic lo salta.
- **Calidad baja**: sin `Bloom`, `SunRays` ni humo, y el clima con la quinta parte de las partículas.

## Verificado en Play (14/11/2026)
Se entró a los 11 mapas con `PruebaMapas`/`PerfilDePrueba` (después se sacaron) y se vio cada ambiente; el paneo
arranca en el portón con el cartel; fuego en los 17 braseros del Sanctum y 13 fuegos y 14 humos en Latveria; al
volver al lobby se restauran la luz, el cielo y el agua y no quedan restos.

## Sin probar
- Rendimiento en celular con lluvia o nieve (900 y 180 partículas por segundo).
- Los modelos voladores de cerca (se vieron el dragón y los pájaros en las capturas; la nave se movió más arriba y
  al fondo después de verla demasiado cerca).
- Relámpagos de The Raft (las capturas no los agarraron).
