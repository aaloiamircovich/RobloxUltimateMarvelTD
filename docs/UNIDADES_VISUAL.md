# Unidades con presencia (etapa 4 del roadmap estético)

Decidido por el usuario el 14/11/2026: **anillo en el piso de Épico para arriba**, **medir, arreglar y hoja de fotos**
de los 212 modelos, y **entrada propia para los 25 únicos** (más Odin y Knull).

## Anillo de rareza (`src/client/Efectos.client.luau`)
- Bajo los pies de cada unidad Épica o mejor: dos aros con cuatro marcas que giran despacio, dibujados con un
  `SurfaceGui` sobre una placa invisible. Épico violeta; Legendario dorado con chispas que suben; Mítico arcoíris con
  chispas y luz; Secreto turquesa con chispas y luz. Comunes y Raros no tienen anillo.
- La placa sigue a la raíz de la unidad y se apoya en el piso real (rayo hacia abajo, se vuelve a medir cada
  segundo), medio stud arriba porque el pasto 3D tapa lo que está al ras. Se borra con la unidad.

## Entradas de los únicos
- `src/shared/Entradas.luau`: 27 animaciones de 2,5 s generadas con la IA de Roblox (Thor aterriza y golpea con el
  martillo, Hulk cae y golpea el piso, Strange dibuja un círculo, Ghost Rider revolea la cadena, Loki hace una
  reverencia…). Las evoluciones usan la de su base.
- `Partida.crearModelo` la reproduce una vez al colocar, con prioridad `Action2` (encima del reposo) y marca el
  modelo con el atributo `Entrada`.
- `Ataques.client.luau`: al aparecer un único, su efecto de ataque cae del cielo sobre él (rayo de Thor, onda y púas
  de Hulk, círculos de Strange…) con una onda blanca y un temblor corto.

## Pies apoyados (`Partida.apoyarPies`)
Un segundo después de colocar (tres si tiene entrada) se mide el pie más bajo y se corrige la altura de la unidad
hasta tocar el suelo (`u.ajustePies`, que también respeta `ubicar` al mover). Medición de los 212 modelos con su
reposo: **ninguno flota ni se hunde** con la ubicación de partida (lo de Ghost Rider era sólo del lobby, que ubicaba
por la caja del modelo); queda como resguardo.

## Hoja de fotos (17/11/2026)
Los 212 retratos de cuerpo entero con su reposo, de a 16 por página (14 páginas). Hallazgos:
- **Rotos** (gris o casi invisibles; las texturas o mallas no cargan, la consola muestra assets «pending moderation»
  o «no content»): Cable evolucionado (sin `SurfaceAppearance`), Capitán América evolucionado (sólo se ve una pieza),
  Mister Fantastic evolucionado, Nick Fury evolucionado y Profesor X.
- **Nightcrawler** queda en pose T: su reposo no se reproduce.
- **Armas que atraviesan el cuerpo** con el reposo de guerrero: Valkyrie, Lady Sif, Heimdall evolucionado y Magik
  evolucionado.
- **Más chicos que el resto en la foto** (algo agranda su caja): Gamora, Heimdall, Lady Sif evolucionado,
  Nightcrawler evolucionado y Elsa Bloodstone.

## Verificado en Play
Dagger colocada queda con los pies a 0,09 studs del suelo; un Thor de prueba muestra el anillo arcoíris (visto desde
arriba) y su entrada; las 27 animaciones se generaron y publicaron.

## Sin probar
- La entrada de un único colocado de verdad en partida (el perfil de prueba no tiene Míticos ni Legendarios).
- Los arreglos de la hoja de fotos: esperan la decisión del usuario.
