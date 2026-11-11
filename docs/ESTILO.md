# Monturas y bailes

Sistema propio del port (el 2D no lo tiene), cosmético. Lógica en `src/shared/Estilo.luau`, pruebas en
`src/server/Pruebas/Estilo.spec.luau`; montar está en `Main.server.luau` y la rueda en `src/client/Estilo.client.luau`.
Estaciones MONTURAS y BAILES de la Torre Vengadores.

## Monturas
- Se compran con gemas y se equipa una. **G** (o el botón 🛹 arriba a la izquierda) sube y baja.
- Sirven en el lobby y en los mapas de partida (son caminables). No dan bonos de combate.

| Montura | Precio | Velocidad |
|---|---|---|
| Patineta flotante | gratis | ×1,5 |
| Moto a reacción | 300 💎 | ×1,7 |
| Disco cósmico | 600 💎 | ×1,9 |
| Pantera de vibranium | 1.000 💎 | ×2,0 |
| Dragón de fuego | 1.500 💎 | ×2,2 |

- El servidor suelda el modelo bajo los pies y sube la cadera del personaje (atributo `Alto` de la plantilla)
  para que quede parado arriba. Modelos en `ServerStorage.Plantillas.Monturas` (generador de Roblox).

## Bailes
- 6 bailes: **Saludo** y **Paso clásico** gratis (emotes públicos de Roblox); **Robot** 100 💎, **¡Victoria!** 200 💎,
  **Pose de poder** 300 💎 y **Giro cósmico** 400 💎 (animaciones generadas con el generador de Roblox).
- Hasta **4 en la rueda**; **B** (o el botón 💃) la abre. Moverse corta el baile.
- El baile lo reproduce el cliente sobre su personaje y Roblox lo replica: todos lo ven.
