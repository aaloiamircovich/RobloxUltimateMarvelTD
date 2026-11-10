// Genera src/server/Pruebas/objetos_2d.json: orden de la tienda (sortItemsWeakestFirst del 2D).
// Uso: node scripts/referencia-objetos.mjs <ruta al repo UltimateMarvelTD_3D>
import fs from "fs";
import path from "path";
import { pathToFileURL } from "url";

const origen = process.argv[2];
if (!origen) throw new Error("Falta la ruta al repo UltimateMarvelTD_3D");
const { sortItemsWeakestFirst } = await import(pathToFileURL(path.join(origen, "src/legacy/src/systems/ShopSystem.js")));
const items = JSON.parse(fs.readFileSync(new URL("../src/shared/Data/items.json", import.meta.url), "utf8"));
const orden = sortItemsWeakestFirst(Object.values(items)).map((i) => i.id);
fs.writeFileSync(new URL("../src/server/Pruebas/objetos_2d.json", import.meta.url), JSON.stringify({ orden }));
console.log(`${orden.length} objetos; primeros: ${orden.slice(0, 5).join(", ")}`);
