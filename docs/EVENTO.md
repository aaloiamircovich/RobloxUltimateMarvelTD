# Desafío semanal y rankings

Sistema propio del port (el 2D no lo tiene). Lógica en `src/shared/Evento.luau` (pruebas en
`src/server/Pruebas/Evento.spec.luau`), rankings en `src/server/Ranking.luau`.

## Desafío semanal
- Cambia los **lunes 00:00 UTC**. Cada semana: **un mapa** (rota entre los 4) y **2 modificadores** al azar, iguales
  para todos: enemigos veloces (+25 % velocidad), blindados (+50 % vida), presupuesto ajustado (−40 % dinero
  inicial), base frágil (mitad de vida) y sin retirada (no se vende).
- Se juega **solo**, desde el botón EVENTO o la estación EVENTO de la Torre Vengadores, sin necesitar el mapa abierto.
- Oleadas sin fin del 2D hasta **30**. Puntaje: **100 por oleada superada + 1 por enemigo derrotado**; para el
  ranking vale el **mejor intento** de la semana. «Reintentar» al final vuelve a jugar el desafío.

## Fichas y tienda
- **1 ficha cada 100 puntos** de cada intento, hasta **300 fichas por semana**.
- Tienda con stock semanal: 100 gemas (40 🎟, ×5), 1 núcleo (120 🎟, ×2), 300 XP de pase (50 🎟, ×4) y un objeto
  épico que no tengas (150 🎟, ×1), 2 fichas de rasgo (60 🎟, ×3) y 4 cristales de grado (40 🎟, ×3).
- Al cambiar la semana, el puntaje, las fichas y las compras vuelven a cero.

## Rankings
- Top 10 global (OrderedDataStore) de: **puntaje del desafío** (uno por semana), **mejor oleada en Infinito** y
  **nivel de cuenta**. Se suben y refrescan cada 60 s. Sin acceso al DataStore muestra a los jugadores del servidor.
- Se ven en la pestaña RANKING del panel EVENTO y en un **cartel gigante** sobre la estación RANKING (desafío e Infinito).
