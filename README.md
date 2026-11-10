# Ultimate Marvel TD · Roblox

Port a Roblox del tower defense de [UltimateMarvelTD_3D](https://github.com/aaloiamircovich/UltimateMarvelTD_3D) (origen de reglas: [TowerDefense_Marvel](https://github.com/aaloiamircovich/TowerDefense_Marvel)).

## Herramientas

- **Rojo**: sincroniza `src/` con Roblox Studio. Instalar [Rokit](https://github.com/rojo-rbx/rokit), luego `rokit install` en esta carpeta, y el plugin de Rojo en Studio.
- **MCP de Roblox Studio**: permite a Claude inspeccionar y probar el juego dentro de Studio.
- **ForgeGUI**: íconos, botones, marcos y miniaturas (PNG). No genera código.

## Desarrollo

```sh
rojo serve
```

En Studio: plugin Rojo → Connect. Al darle Play, la salida debe mostrar `[UMTD] Datos OK: 105 héroes, 49 enemigos, 82 objetos, 11 mapas`.

## Estructura

| Carpeta | En Studio | Contenido |
| --- | --- | --- |
| `src/shared` | ReplicatedStorage.Shared | Datos y módulos compartidos |
| `src/server` | ServerScriptService.Server | Simulación del combate (autoritativa) |
| `src/client` | StarterPlayerScripts.Client | UI, cámara, efectos |

`src/shared/Data/*.json` son copias sin modificar de `src/legacy/data/` de UltimateMarvelTD_3D (commit `eb823fe`); Rojo los convierte en ModuleScripts. `TypeChart.json` sale de `TypeChart.js`. Las oleadas no se copian: la campaña de 100 oleadas la genera el código (`WaveManager.js`, `EncounterDirector.js`) y se porta a Luau.
