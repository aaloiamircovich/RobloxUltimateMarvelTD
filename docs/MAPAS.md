# Mapas nuevos (del 5 al 11)

Decidido por el usuario el 15/11/2026: **de a uno, bien hecho**; decorado con la **IA de Roblox** (`generate_mesh`,
sin ForgeGUI); cada mapa con **su mecánica del 2D** portada (`MissionSystem.js` de TowerDefense_Marvel).

## Cómo se arma un mapa
1. **Terreno** (`TERRENOS` en `src/shared/Mapa.luau`): los niveles sin `terrainRows` usan una grilla de 20×15 celdas
   de 40 px; una función elige el código de cada celda (pasto, bosque, agua, montaña…) y el camino del `path` de
   `levels.json` se pinta encima. Las celdas de agua y de montaña tienen que quedar **al alcance del camino**
   (unidades de agua y de altura) y fuera del anillo reservado de las zonas de la misión (radio + 16 px).
2. **Tema** (`TEMAS[theme.id]`): materiales de cada celda, orilla del camino, banda de los edificios, plantas
   sueltas y luciérnagas.
3. **Kit** en `ServerStorage.Plantillas.Mapas/<theme.id>` (se guarda en el lugar, no en Git): `base`, `porton`,
   `barrera`, `borde_1..3`, `arbol`, `farol` (y `estructura_*` si el mapa tiene celdas bloqueadas). El mapa
   reescala cada pieza; el pivote va en el centro. Prompt: "stylized cartoon game asset: …". Si la segmentación
   automática falla, repetir con `segmentation = "none"`.
4. Sumar el id a `Mapa.JUGABLES` y `Actos.MAPAS` (orden de desbloqueo). Enemigos y jefes ya están por facción en
   `Oleadas.luau`.
5. **Probar** en Studio con `workspace.PruebaMapas = true` (abre todos los mapas y actos sin abrirlos en el perfil, aunque una victoria sí se guarda;
   sólo en Studio) y sacarlo al terminar.

## Hechos
| Mapa | Terreno | Mecánica |
| --- | --- | --- |
| **Instituto Xavier** (`level_5`, `x-mansion`) | Jardín con árboles; la mansión de ladrillo arriba, abajo y en dos alas junto a los tramos laterales (altura); estanque pegado al tramo de abajo (agua). Sendero de grava. Kit: Cerebro (cúpula con la X), portón de hierro, cerco de arbustos, ala de la mansión, torre del reloj, sala de entrenamiento, roble y farol. | **Balizas de la Sala de Peligro**: cada una aturde 0,8 s a los 2 primeros enemigos que entran en su radio (54 px), **una vez por oleada** (`academy` en `Partida.luau`). |

## Pendientes
Knowhere, Latveria, Asgard, Dimensión Oscura, Savage Land y The Raft.
