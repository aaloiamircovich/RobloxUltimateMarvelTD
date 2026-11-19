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

## Arreglos (17/11/2026)
- **Nightcrawler en pose T**: tiene el mismo esqueleto que los demás; su retrato llegaba sin `Animator` y el reposo
  no se reproducía. `Comic.retrato` y `Cinematica.modelo3D` ahora lo crean si falta. En partida ya se creaba.
- **Armas que atraviesan**: estilo de reposo `espadachin` para Valkyrie, Lady Sif, Heimdall y Magik (sus evoluciones
  lo heredan). Es el mismo reposo de pie de los encargados del lobby: uno generado «con la espada al costado» los
  dejaba agachados y a Heimdall y Magik evolucionados la hoja les seguía cruzando el cuerpo. Verificado en Play.
- **Los «más chicos»** miden lo mismo que el resto (3,97 studs de pies a cabeza; evoluciones ×1,1): en la foto los
  achicaba la caja que suman espada, capa o alas. No hace falta tocarlos.
- **Los 5 grises**, vistos en 3D tras reiniciar Studio: Profesor X, Capitán América, Mister Fantastic y Nick Fury
  evolucionados están bien (en la foto no habían terminado de cargar). **Cable evolucionado** sí estaba roto (sin
  textura): se rehizo con la IA de Roblox (armadura azul y gris con hombreras amarillas, pelo blanco, brazo de metal),
  `auto_setup_avatar`, 4,37 studs de pies a cabeza y los atributos del viejo; el viejo quedó en
  `ServerStorage.Borradores/cable_evolution_roto`.
- **Nightcrawler** verificado en Play: ya no queda en pose T.

## Verificado en Play
Dagger colocada queda con los pies a 0,09 studs del suelo; un Thor de prueba muestra el anillo arcoíris (visto desde
arriba) y su entrada; las 27 animaciones se generaron y publicaron.

## Sin probar
- La entrada de un único colocado de verdad en partida (el perfil de prueba no tiene Míticos ni Legendarios).

## Fase E: animaciones y ataques (18/11/2026)
- **Festejo al mejorar**: uno por estilo de reposo (`Reposo.FESTEJOS`), prioridad Action, lo carga `Partida.cargarFestejo`.
- **Reposo propio** para los 25 únicos + Odin y Knull (`Reposo.PROPIOS`, generados con la IA de Roblox).
- **Enemigos** (`src/client/EnemigosVisual.client.luau`): destello blanco al perder vida (máx. 18 a la vez);
  `Estados` → partículas en el cuerpo (lento, quemadura, veneno, aturdido, maldición) e íconos sobre la barra;
  `FaseJefe` → al preparar, rugido (rbxassetid://76750798382441) y anillo rojo; al activar, escudo, portales de
  refuerzos, furia/aturdir (tinte rojo + onda), sigilo (humo) o cura (chispas verdes). Sólo visual.
- **Revisión de ataques**: 41 efectos fotografiados en una pista de prueba. Únicos: bien. Rehechos por flojos:
  balas (ráfaga de 3), energía, magia, psíquico, golpe, corte (en cruz) y escudo; todos con `remate()` en el blanco.
