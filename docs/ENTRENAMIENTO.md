# Entrenamiento (20/11/2026)

Campo de pruebas para probar cualquier héroe y para revisar la estética y las animaciones de los personajes.
Decidido con el usuario: puesto en el lobby + modo en ¡JUGAR!, cualquier héroe configurable, enemigos a pedido,
estadísticas completas, campo de pruebas propio, cámara lenta, cámara sobre la unidad, ocultar interfaz y sin premios.

## Cómo se entra
- **Puesto «ENTRENAMIENTO»** en la isla central (entre RANKING y el Salón de héroes), con Black Widow de encargada.
- **¡JUGAR! → ENTRENAMIENTO** (cuarto modo, primero en la fila).
- Siempre se juega en el servidor del lobby (es individual): no hay teletransporte. `Main.usarEstacion("entrenamiento")`.

## Reglas
- Créditos infinitos (`Entrenamiento.DINERO`, se reponen en cada paso; el HUD muestra «💰 ∞»).
- Hasta 10 unidades por casilla, 6 casillas.
- Sin oleadas ni tiempo: los enemigos los suelta el jugador. La base es inmortal por defecto; si se apaga y la base
  cae, se repone (nunca termina).
- **No da nada**: sin XP, oro, gemas, misiones, logros ni pase (`evento()` no hace nada en el entrenamiento).

## Panel (`src/client/Entrenamiento.client.luau`)
- **Arriba**: velocidad ×1 → ×2 → ×3 → ×0,25 → ×0,5 (cámara lenta), CÁMARA (orbita alrededor de cada unidad propia,
  una por toque, y al final vuelve a la normal), OCULTAR (tecla H: esconde toda la interfaz y la vuelve a mostrar),
  SALIR.
- **HÉROES**: elegir casilla 1–6, buscar cualquier héroe (con evoluciones), nivel (1, 5… 50), mejora (0–5, ya
  comprada al colocar), rasgo, grados de daño, alcance y cadencia, objeto y Shiny → APLICAR. Cambiar una casilla
  quita las unidades que tenía colocadas.
- **ENEMIGOS**: cualquier enemigo o jefe, cantidad (1–60), cada cuántos segundos, vida (la suya o 100 a 1.000.000) y
  velocidad (quietos a ×3). SOLTAR, LIMPIAR y BASE INMORTAL.
- **DATOS**: por unidad, daño total, DPS (por segundo de juego), golpes, % de críticos y estados que aplicó, más el
  desglose de daño, alcance y cadencia (base, objeto, mejora, nivel, Shiny, rasgo y grados, mascotas). Tocar un
  enemigo muestra su vida, armadura, resistencias, estados y el último golpe recibido.

## Servidor (`Partida.luau`, todo detrás de `entrenando`)
- Mapa: `Entrenamiento.NIVEL` (25 × 19 baldosas, camino en S de tres de ancho, estanque y bloques de montaña junto al
  camino). Tema `entrenamiento` en `Mapa.luau`: camino de concreto, pasto plano (sin pasto 3D, no tapa los pies),
  base, portón y bordes de la Base de los Vengadores. Luz de mediodía neutra (`Ambiente.client.luau`).
- Acciones: `configurar`, `enemigos`, `limpiar`, `inmortal`, `reiniciarStats` (firmas en `Main.FIRMAS`; validación en
  `Entrenamiento.validarHeroe` y `validarEnemigos`).
- Daño medido como la vida que la unidad les quita a los enemigos en su turno; los daños en el tiempo se suman a la
  última unidad que golpeó. Se publica cada medio segundo en atributos del modelo (`EstDano`, `EstGolpes`,
  `EstCriticos`, `EstEstados`, `Desglose`) y del estado (`EstSegundos`).

## Pendiente
- Forzar animaciones a pedido (entrada, festejo, ataque) no se pidió; se puede sumar si hace falta para la revisión.
