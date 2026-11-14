# Tutorial y ajustes

Decidido por el usuario el 14/11/2026. Lógica compartida en `src/shared/Preferencias.luau` (pruebas en
`src/server/Pruebas/Preferencias.spec.luau`); se guarda en el perfil (`ajustes` y `tutorial`).

## Tutorial de primera sesión
Guiado con flecha amarilla que rebota, recuadro sobre el botón y cartel arriba con la instrucción
(`src/client/Tutorial.client.luau`). Se puede **saltear** en cualquier momento (sin premio).

| Paso | Qué pide | Pasa cuando |
|---|---|---|
| 0 | Tocar UNIDADES y elegir el héroe inicial | Tiene al menos una unidad |
| 1 | ¡JUGAR! y después HISTORIA | Aparece el botón SOLO (o ya está en partida) |
| 2 | Base de los Vengadores · Acto 1 → SOLO | Entra a la partida |
| 3 | Elegir la tarjeta (o tecla 1) y colocar | Tiene una unidad en el mapa |
| 4 | ¡LISTO! | Empiezan las oleadas |
| 5 | Tocar al héroe y MEJORAR | Alguna unidad con mejora 1 (o termina la partida) |
| 6 | Aguantar las 10 oleadas | Victoria (si pierde, pide REINTENTAR) |
| 7 | Volver al lobby | Sale de la partida |
| 8 | Premio y tocar INVOCAR | Abre las invocaciones → fin |

- **Premio: 500 gemas** (10 invocaciones), una sola vez y **sólo si ganó el Acto 1** del primer mapa: lo valida el
  servidor (`Preferencias.terminar`), no alcanza con que el cliente diga «terminé».
- El paso se guarda en el perfil. Si vuelve al lobby a mitad de la partida del tutorial: al premio si ya ganó
  el acto, si no otra vez desde ¡JUGAR!. Al reconectarse fuera de partida en los pasos 2–6, retoma desde ¡JUGAR!.
- Las cuentas que ya jugaban antes (tienen unidades y no tenían tutorial guardado) no lo ven ni cobran el premio.
- **Prueba en Studio:** `workspace.TutorialPrueba = true` muestra el tutorial desde cero a cualquier cuenta sin
  guardar nada ni dar premio; `TutorialPruebaGano = true` simula que ganó el acto. Sacarlos antes de guardar el lugar.

## Ajustes (botón ⚙ AJUSTES, columna derecha del lobby)
- Volumen de música y de efectos (de a 10 %), multiplican los volúmenes base de `Sonido.luau`.
- **Calidad baja**: sin sombras globales, sin efectos de post-proceso, partículas, estelas ni rayos (también los
  que aparecen después, como los mapas de partida). Al desactivarla vuelve todo como estaba.
- **Números de daño**: mostrar u ocultar.
- **Juego automático al empezar**: al entrar a una partida activa el «Auto» solo.
- Se guardan en la cuenta (el servidor los normaliza: volúmenes 0–1, sólo booleanos).
