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
| **Knowhere** (`level_6`, `knowhere`) | Colonia minera en un cráneo Celestial: piso de roca oscura con vetas de cristal rosa y cian, piso metálico con filo de neón rosa, tres plataformas mineras de metal oxidado junto a las curvas (altura), vacío con maquinaria y contenedores en dos esquinas. Sin agua. Kit: nave en su plataforma, túnel en roca de hueso, cajones, mercado de chapas con neón, torre de perforación, aguja de hueso fosilizado, máquina minera, contenedores, farol de neón y cristales. | **Puerto de extracción**: como en el 2D, no tiene efecto activo; las zonas CARGA y NAVE reservan su lugar (34 + 16 px; el 2D no les da radio) y se ven en el piso. |
| **Latveria** (`level_7`, `latveria`) | Patio de adoquines con losas oscuras de Castle Doom; muralla arriba y tres torres junto a los tramos (altura); foso a la izquierda y abajo a la derecha (agua); fábricas y chatarra en dos esquinas; vapor en el camino y filo de energía verde. Kit: torre del homenaje con reactor verde, puerta con rastrillo, barricada con pinchos, torre gótica, fábrica de guerra, estatua del rey enmascarado, maquinaria, chatarra de robots, pino, farol de llama verde y barril tóxico. | **Asedio a Castle Doom**: cada 10 bajas, todos los enemigos del mapa pierden 16 % de blindaje por 5 s y avisa «Sabotaje S.H.I.E.L.D.» (`fortress` en `Partida.luau`). **Sin verlo en partida**: con unidades de prueba débiles no se llegó a 10 bajas. |

## Opciones nuevas de tema
- `orilla = "neon"` con `orillaColor`: filo de luz a los lados del camino, sin las runas del Sanctum.
- `arboles = false`: no usa el árbol del jardín del HUB cuando el kit no trae `arbol`.

## Pendientes
Asgard, Dimensión Oscura, Savage Land y The Raft.
