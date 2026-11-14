# Intercambio entre jugadores

Decidido por el usuario el 15/11/2026. Reglas en `src/shared/Intercambio.luau` (pruebas en
`src/server/Pruebas/Intercambio.spec.luau`); sesiones en `Main.server.luau`; panel **INTERCAMBIO** (🔁 CAMBIAR,
columna derecha del lobby).

## Cómo funciona
1. En el panel se ve la lista de jugadores del servidor; **PEDIR** le manda un pedido a uno.
2. Al otro se le abre el panel con **ACEPTAR / RECHAZAR**.
3. Cada uno toca cosas de **su inventario** para agregarlas o sacarlas de **su oferta**; ve la oferta del otro.
4. Los dos aprietan **CONFIRMAR**. Si cualquiera cambia su oferta, las confirmaciones se borran.
5. Con las dos confirmaciones el servidor revisa todo de nuevo y hace el cambio **de una vez** (o nada si algo
   falla). Los perfiles se guardan enseguida.

## Qué se puede intercambiar
- **Unidades** (conservan nivel, XP, rasgo y grados; reciben un número nuevo en el perfil que las recibe).
- **Objetos** del inventario (no equipados: hay que desequiparlos primero).

## Restricciones
- **Nivel de cuenta 10** los dos.
- **Sin exclusivos** (Odin, Knull).
- Unidades del **escuadrón** no se ofrecen (hay que sacarlas primero).
- Hasta 8 cosas por oferta; quien recibe tiene que tener lugar (100 unidades) y no tener ya ese objeto.
- No se puede intercambiar dentro de una partida. Si alguien se va del servidor, el intercambio se cancela.

## Sin probar todavía
- Un intercambio real entre dos jugadores (en Studio con un solo jugador sólo se vio el panel y la regla de nivel).
  Se puede probar con **Test → Clients and Servers** (2 jugadores) en Studio o con dos cuentas en el juego.
