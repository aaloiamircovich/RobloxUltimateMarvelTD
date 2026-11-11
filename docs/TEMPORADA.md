# Misiones y pase de batalla

Sistema propio del port (el 2D no lo tiene). Lógica en `src/shared/Temporada.luau`, pruebas en
`src/server/Pruebas/Temporada.spec.luau`.

## Misiones
- **3 diarias** (se renuevan a las 00:00 UTC) y **3 semanales** (lunes 00:00 UTC), iguales para todos ese día/semana.
- Tareas: ganar actos, derrotar enemigos, colocar unidades, hacer mejoras, superar oleadas, llegar a la oleada X
  en Infinito (sólo semanal; cuenta el mejor valor) e invocar.
- Premio al reclamar: diaria **15 gemas + 100 XP de pase**; semanal **60 gemas + 400 XP de pase + 1 ficha de rasgo + 2 cristales** (docs/RASGOS.md).

## Pase de batalla
- Temporadas de **30 días** desde el 11/11/2026; **50 niveles** de **300 XP**. Al empezar otra temporada el pase vuelve a cero.
- XP de pase: misiones, **+10 por oleada superada** y **+50 por acto ganado**.
- Fila gratis: gemas (20–40) en la mayoría de los niveles, fichas de rasgo en los terminados en 3, cristales de grado en los terminados en 7, **objeto** cada 5 (Raro hasta el 25, Épico después; si ya
  lo tenés, 100 gemas), **núcleos** cada 10 (1–4) y en el **50 un personaje exclusivo** nuevo que todavía no existe
  (`Temporada.EXCLUSIVA`; hasta definirlo, el nivel 50 no se reclama).
- Fila premium: visible con candado «Premium próximamente». No se vende nada hasta que el usuario decida monetizar.
