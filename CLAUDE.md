# Ultimate Marvel TD · Roblox

- Port a Roblox (Luau + Rojo) de `aaloiamircovich/UltimateMarvelTD_3D`. Las reglas de referencia están en `src/legacy/src/systems/` de ese repo; sus 2.526 pruebas definen los números esperados.
- `src/shared/Data/*.json` son copias sin editar del origen. Cambios de balance: primero decidir con el usuario si se apartan del 2D.
- El servidor simula el combate; el cliente sólo muestra y envía intenciones (colocar, mejorar, vender). Validar en el servidor todo lo que llega del cliente.
- Interfaz, comentarios y documentación en español.
- Los personajes de Marvel no tienen licencia: no publicar ni monetizar el juego sin que el usuario lo decida explícitamente.
- Imágenes de UI desde ForgeGUI; modelos desde Meshy/Blender del repo 3D, reducidos al límite de polígonos de Roblox.
