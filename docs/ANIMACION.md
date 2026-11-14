# Reposo y efectos de las unidades

Decidido por el usuario el 14/11/2026.

## Animaciones de reposo (`src/shared/Reposo.luau`)
- **8 estilos** generados con la IA de Roblox (4 s, en bucle): guerrero, luchador, tirador, místico, bestia,
  pequeño, armadura y comandante.
- Cada personaje usa el estilo de su **base** (las evoluciones heredan): primero la lista `POR_PERSONAJE`
  (bestias, animales chicos, armaduras, los que no atacan y los de armas cuerpo a cuerpo); si no está, según su
  efecto de ataque: flecha → tirador, rayo → místico, impacto → luchador.
- **En partida** (servidor, `Partida.crearModelo`): el reposo corre con prioridad Idle y el ataque con prioridad
  Action, que lo tapa mientras ataca.
- **Retratos 3D** (`Comic.retrato`): el modelo va dentro de un `WorldModel` del ViewportFrame y reproduce el mismo
  reposo, así las tarjetas del escuadrón y la colección se ven vivas.

## Efectos (`src/client/Efectos.client.luau`, sólo visuales y locales)
- **Aparición** al colocar: anillo que se abre en el piso, destello y chispas del color de la rareza.
- **Mejora**: columna de luz que sube y estrellas del color de la rareza.
- **Mejora máxima (5)**: aura permanente de partículas y luz del color de la rareza.
- **Venta**: humo y la unidad se desvanece (el servidor marca `Vendida` y la borra a los 0,7 s).
- «Calidad baja» en Ajustes apaga estas partículas.
