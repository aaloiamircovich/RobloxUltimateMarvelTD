# Interfaz y audio

Decidido por el usuario el 14/11/2026.

## Interfaz
- **PC primero**: diseño base 1280×720. Cada bloque del HUD tiene su `UIScale` (`Comic.escalar`) entre ×0,55 y ×1,35
  según el lado más corto de la pantalla, así nada se pisa en ventanas chicas.
- **Lobby con barras compactas** (como Anime Defenders):
  - Izquierda: columna de íconos de 84 px (Tienda, Unidades, Inventario, Misiones, Invocar, Pase).
  - Derecha: Viajar, Perfil, Evento, Novedades.
  - Arriba al centro: monedas y barra de nivel de cuenta.
  - Abajo al centro: escuadrón (casillas de 92 px).
  - Abajo a la derecha: **¡JUGAR!** grande; sube por encima del escuadrón si la ventana es angosta.
  - Los botones G (montura) y B (bailes) también se escalan.
- **Colocar unidades**: al elegir una tarjeta aparece el personaje fantasma semitransparente donde apunta el
  mouse, con un disco y el anillo de alcance en verde (se puede) o rojo (no se puede); si no se puede, un cartel
  junto al puntero dice el motivo (camino, terreno, fuera del mapa, otra unidad cerca).

## Audio
- **Todo generado con ForgeGUI** (música y efectos propios) y publicado en la cuenta de Roblox del usuario.
- **Música épica orquestal**: lobby (heroica, tranquila), partida (acción) y jefe (intensa, con coro).
- Efectos previstos: clic, abrir panel, premio, invocación (normal y rara), colocar, mejorar, vender, ataque
  (flecha, rayo, impacto), muerte de enemigo, golpe a la base, inicio de oleada, llegada del jefe, victoria y derrota.
- **Pendiente**: la cuenta de ForgeGUI no tiene créditos suficientes (cada música de 2 min pide 1600 y había 1024).
