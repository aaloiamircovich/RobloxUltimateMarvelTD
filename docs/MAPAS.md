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
5. **Probar** en Studio con `workspace.PruebaMapas = true` (abre todos los mapas y actos sin abrirlos en el perfil)
   y `workspace.PerfilDePrueba = true` (juega con una copia en memoria del perfil real: ganar, gastar o abrir mapas
   no llega al DataStore). Los dos son sólo de Studio; sacarlos al terminar.

## Hechos
| Mapa | Terreno | Mecánica |
| --- | --- | --- |
| **Instituto Xavier** (`level_5`, `x-mansion`) | Jardín con árboles; la mansión de ladrillo arriba, abajo y en dos alas junto a los tramos laterales (altura); estanque pegado al tramo de abajo (agua). Sendero de grava. Kit: Cerebro (cúpula con la X), portón de hierro, cerco de arbustos, ala de la mansión, torre del reloj, sala de entrenamiento, roble y farol. | **Balizas de la Sala de Peligro**: cada una aturde 0,8 s a los 2 primeros enemigos que entran en su radio (54 px), **una vez por oleada** (`academy` en `Partida.luau`). |
| **Knowhere** (`level_6`, `knowhere`) | Colonia minera en un cráneo Celestial: piso de roca oscura con vetas de cristal rosa y cian, piso metálico con filo de neón rosa, tres plataformas mineras de metal oxidado junto a las curvas (altura), vacío con maquinaria y contenedores en dos esquinas. Sin agua. Kit: nave en su plataforma, túnel en roca de hueso, cajones, mercado de chapas con neón, torre de perforación, aguja de hueso fosilizado, máquina minera, contenedores, farol de neón y cristales. | **Puerto de extracción**: como en el 2D, no tiene efecto activo; las zonas CARGA y NAVE reservan su lugar (34 + 16 px; el 2D no les da radio) y se ven en el piso. |
| **Latveria** (`level_7`, `latveria`) | Patio de adoquines con losas oscuras de Castle Doom; muralla arriba y tres torres junto a los tramos (altura); foso a la izquierda y abajo a la derecha (agua); fábricas y chatarra en dos esquinas; vapor en el camino y filo de energía verde. Kit: torre del homenaje con reactor verde, puerta con rastrillo, barricada con pinchos, torre gótica, fábrica de guerra, estatua del rey enmascarado, maquinaria, chatarra de robots, pino, farol de llama verde y barril tóxico. | **Asedio a Castle Doom**: cada 10 bajas, todos los enemigos del mapa pierden 16 % de blindaje por 5 s y avisa «Sabotaje S.H.I.E.L.D.» (`fortress` en `Partida.luau`). **Sin verlo en partida**: con unidades de prueba débiles no se llegó a 10 bajas. |
| **Asgard** (`level_8`, `asgard`) | Piso de mármol cálido; el Bifrost es un puente de cristal azul con filo dorado; palacios dorados entre las dos rutas y una torre a la derecha (altura); mar cósmico abajo (agua); ruinas de columnas y rocas rúnicas en el vacío de arriba. Kit: palacio dorado (base), observatorio con portal arcoíris (portón), escudos, torres doradas, salón vikingo, estatua del rey guerrero, ruinas, roca rúnica, árbol dorado, brasero y piedra rúnica. | **Anclas del Bifrost** (decidido por el usuario: fiel al 2D): **dos rutas** que se turnan por oleada (impares entran por la izquierda y salen por la derecha; pares bajan desde arriba y salen abajo), con un portón y una base en cada punta, y las dos le quitan vida a la base. Los **dos portales** adelantan 145 px por su ruta, una vez a cada enemigo, con un destello arcoíris donde entra y donde sale. |
| **Dimensión Oscura** (`level_9`, `dark-dimension`) | Piso de pizarra violeta con grietas de neón carmesí, camino de obsidiana con filo rosa, tres plataformas flotantes de obsidiana sin parapetos (altura), dos charcos del vacío (agua) y cubos de geometría imposible arriba y abajo a la izquierda. Kit: santuario de obsidiana con círculo mágico (base), portal entre púas de obsidiana (portón), muro de esquirlas, torre espiral de cubos, cabeza de fuego sobre un pilar, arco invertido con escaleras, figuras flotantes, escalera rota, farol de púas y cristales de obsidiana. | **Ciclo de inversión**: cada 6 s las dos runas (radio 72) pasan de **frenar 42 %** a **acelerar 24 %** a los enemigos dentro, con el aviso de la paradoja (`inversion` en `Partida.luau`). **Agregado sobre el 2D**: la zona del piso se pone roja mientras está invertida. Cada oleada arranca en «realidad estable». |
| **Savage Land** (`level_10`, `savage-land`) | Selva de pasto 3D con palmeras, helechos y fósiles; senderos de tierra; templo en ruinas de roca entre los dos senderos (altura); río abajo (agua); grietas de lava sueltas; selva cerrada arriba. Kit: fuerte de troncos sobre ruinas (base), arco de piedra con lianas (portón), cerco de bambú, árbol prehistórico gigante, volcán, pirámide del templo, palmera, helecho, cráneo de dinosaurio y antorcha tiki. | **Vegetación destructible**: **dos senderos** que se turnan **cada tres oleadas** (1–3 arriba, 4–6 abajo, 7–9 arriba, 10 abajo), cada uno con su portón y su base; las zonas LIANA y RUINA frenan 3 s (−62 %) a un enemigo nuevo cada una hasta gastar **5 masas por oleada**, y avisan cuando la selva queda destruida (`jungle` en `Partida.luau`). |
| **The Raft** (`level_11`, `the-raft`) | Cubierta de acero de la prisión en el mar, pasillo de hangar con franjas de peligro, bloques de celdas entre los tramos y a la derecha (altura), mar arriba a la izquierda y abajo (agua), celdas de energía y contenedores arriba a la derecha, luces rojas de emergencia. Kit: torre de control con reflectores (base), compuerta blindada (portón), barricada con luz roja, bloque de celdas, torre de vigilancia, plataforma marina con grúa, cápsula de contención, contenedores, poste con sirena y cajas. | **Celdas inestables**: si un enemigo herido entra en una de las tres celdas (A-1, B-2, C-3; radio 58), la celda se rompe y libera al **Prisionero Gamma** (620 de vida, blindaje 38 %, tanque) 24 px detrás, por la misma ruta; cada celda una vez por oleada (`raft` en `Partida.luau`). El prisionero usa el modelo de Abominación (`config.modelo`). |

## Rutas alternas (Asgard y Savage Land)
- `Mapa.rutasPixeles(nivel)` devuelve todas las rutas: las de `alternatePaths` si la mecánica es `bifrost` (cambia cada oleada) o `jungle` (cada tres); en los
  demás mapas, sólo la principal (los `alternatePaths` de los mapas 1–3 del 2D siguen sin usarse).
- El terreno pinta todas como camino; `Mapa.construir` arma un portón y una base por ruta y devuelve la lista.
- `Despliegue.error` acepta la lista: el alcance vale contra la ruta más cercana.
- En `Partida.luau` cada enemigo guarda su ruta (`e.ruta`): la de la oleada en la que salió; los refuerzos y las
  invocaciones salen por la ruta de quien los llama.

## Opciones nuevas de tema
- `orilla = "neon"` con `orillaColor`: filo de luz a los lados del camino, sin las runas del Sanctum.
- `arboles = false`: no usa el árbol del jardín del HUB cuando el kit no trae `arbol`.
- `techoColor` en el aspecto de la montaña: color de la losa del techo (por defecto blanca).

## Estado
Los 11 mapas del 2D son jugables (15/11/2026).

## Dificultad (prueba del 15/11/2026)
Acto 1 de los 11 mapas con el escuadrón de la cuenta de prueba (Hawkeye, Triton y Dagger nivel 6; cuenta nivel 3),
a ×3, con un script que coloca en la primera celda válida más cerca del camino y mejora con lo que gana.
- **Originales**: Base de los Vengadores y Nueva York llegan a la oleada 10 (jefe); Wakanda y Sanctum caen en la 5.
- **Nuevos**: caen entre la oleada 1 (Instituto Xavier) y la 3 (Knowhere). No es un problema de los mapas: la vida
  de las oleadas viene del 2D y crece con la posición del mapa. El **acto 1 de cada mapa nuevo es ~10 veces más
  fácil que el acto 5 del anterior** (oleada 5: Sanctum acto 5 = 147.227 de vida; Xavier acto 1 = 15.543), así que
  quien llega ahí lo pasa. Rareza heredada del 2D: el acto 1 del Instituto Xavier (15.543) es un poco más difícil
  que su acto 2 (13.889) por las aperturas con Centinelas.
- Con dinero de partida ilimitado (unidades al máximo): Latveria llega a la oleada 9 y su **sabotaje se disparó 8
  veces** (verificado); la Dimensión Oscura cae en la 3. Ahí las dos runas (radio 72 + 16 de reserva) ocupan las
  curvas del camino, que son los mejores lugares, y la paradoja acelera la mitad del tiempo: las dos cosas son del 2D.
- **Sin probar**: un escuadrón realista de quien ya pasó el mapa anterior (habría que armar un perfil de prueba
  con unidades de ese nivel).
