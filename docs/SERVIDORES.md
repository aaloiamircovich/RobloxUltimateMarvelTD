# Guardado y servidores de partida

Decidido por el usuario el 14/11/2026.

## Guardado (ProfileStore)
- `src/server/ProfileStore.luau` es la librería de MadStudioRoblox (Apache 2.0, licencia en `licencias/`), sin
  modificar. `Perfiles.luau` la usa por dentro; el resto del código sigue con `Perfiles.cargar/de/marcar/guardar/soltar`.
- **Bloqueo de sesión:** el perfil pertenece a un solo servidor por vez. Si otro servidor lo toma, este deja de
  guardar y saca al jugador con un aviso. Al salir se libera la sesión (`EndSession`).
- Almacén **`PerfilesUMTD_v2`**. La primera vez que un jugador entra, se copian sus datos de `PerfilesUMTD_v1`
  (que queda intacto como respaldo). Si v1 no responde, la sesión no se guarda en vez de empezar de cero.
- ProfileStore autoguarda cada 5 min y al cerrar el servidor; además se guarda al toque cuando hay cambios
  importantes (fin de partida, compras) cada 60 s.
- Probado en Studio: migración (mismas gemas, nivel y unidades) y un cambio que persiste al cerrar y abrir.

## Servidores de partida (mismo lugar)
- **Lobby (servidor público):** al empezar una partida (solo, sala, raid o evento) el grupo se teletransporta a un
  **servidor reservado** de este mismo lugar con los datos del viaje (mapa, acto, pesadilla, anfitrión y jugadores).
- **Servidor de partida** (`game.PrivateServerId ~= ""` y sin dueño): valida los datos del viaje y los perfiles,
  espera a todos (o 20 s) y arranca. «Siguiente acto», «Repetir» y «Siguiente mapa» siguen en ese servidor.
  «Volver al lobby» teletransporta al jugador al lobby público. Quien llega tarde vuelve al lobby.
- **En Studio** no hay teletransporte: todo se juega en el mismo servidor, como antes.
- **Sin probar todavía:** el viaje real. Se prueba entrando al juego desde Roblox (el lugar es privado, sólo para
  quien tiene acceso): crear una partida solo, ver que viaja, jugar y volver al lobby.
