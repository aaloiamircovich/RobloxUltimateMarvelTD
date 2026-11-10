// Genera src/server/Pruebas/mapas_3d.json: ruta normalizada y terreno de los 4 mapas jugables, tal como
// los arma getMission del 3D (src/game/missions.js).
// Uso: node scripts/referencia-mapas.mjs <ruta al repo UltimateMarvelTD_3D>
import fs from "fs";
import path from "path";
import { pathToFileURL } from "url";

const origen = process.argv[2];
if (!origen) throw new Error("Falta la ruta al repo UltimateMarvelTD_3D");
const { getMission } = await import(pathToFileURL(path.join(origen, "src/game/missions.js")));
const mapas = {};
for (const id of ["level_1", "level_2", "level_3", "level_4"]) {
  const m = getMission(id);
  mapas[id] = { ruta: m.path, terreno: m.terrain, lado: m.gridSize, dificultad: m.difficulty };
}
fs.writeFileSync(new URL("../src/server/Pruebas/mapas_3d.json", import.meta.url), JSON.stringify(mapas));
for (const [id, m] of Object.entries(mapas)) console.log(id, m.terreno.length, "x", m.terreno[0].length, "lado", m.lado, m.dificultad, "ruta", m.ruta.length);
