// Genera src/server/Pruebas/oleadas_2d.json con el WaveManager original del 2D.
// Uso: node scripts/referencia-oleadas.mjs <ruta al repo UltimateMarvelTD_3D>
import fs from "fs";
import path from "path";
import { pathToFileURL } from "url";

const origen = process.argv[2];
if (!origen) throw new Error("Falta la ruta al repo UltimateMarvelTD_3D");
const { WaveManager } = await import(pathToFileURL(path.join(origen, "src/legacy/src/systems/WaveManager.js")));
const { getFixedDifficultyKey } = await import(pathToFileURL(path.join(origen, "src/legacy/src/utils/LevelProgression.js")));
const leer = (f) => JSON.parse(fs.readFileSync(new URL(`../src/shared/Data/${f}`, import.meta.url), "utf8"));
const enemies = leer("enemies.json");
const levels = leer("levels.json");
const heroes = leer("heroes.json");

const oleadas = [...Array(30).keys()].map((i) => i + 1).concat([40, 50, 75, 99, 100]);
const casos = [];
// Supervivencia como la arma el 3D (combat.js): modeId "survival" sin start(), así la semilla sigue siendo "campaign".
const supervivencia = { modeId: "survival", getSeed: () => "campaign", buildWave: () => null };
// Como getMission del 3D: dificultad fija según el mapa (Fácil/Difícil…). Mapas jugables: 1 a 4.
const casosNivel = [];
for (const indice of [0, 1, 2, 3]) for (const modo of indice === 0 ? ["campaign", "survival"] : ["campaign"]) for (const equipo of indice === 0 ? [[], ["hawkeye"]] : [["hawkeye"]]) casosNivel.push({ indice, modo, equipo });
for (const { indice, modo, equipo } of casosNivel) {
  const nivel = levels[indice];
  const game = { currentLevel: nivel, levelsData: levels, difficulty: getFixedDifficultyKey(nivel), heroes: equipo.map((id) => ({ config: heroes[id] })), enemies: [], modeSystem: modo === "survival" ? supervivencia : undefined };
  for (const w of modo === "survival" ? oleadas.concat([101, 125, 150]) : indice === 0 ? oleadas : [1, 2, 3, 4, 5, 6, 10, 25, 50, 99, 100]) {
    const wm = new WaveManager(game, enemies);
    if (modo === "survival") wm.maxWaves = Number.MAX_SAFE_INTEGER;
    wm.currentWave = w;
    wm.prepareNextWave();
    casos.push({
      nivel: indice + 1, modo, equipo, oleada: w, modificador: wm.waveModifier.id,
      cola: wm.preparedQueue.map((q) => [q.config.id, q.config.hp, q.config.speed, q.config.reward, +q.config.armor.toFixed(4), q.config.stealth ? 1 : 0, +q.delay.toFixed(4)]),
    });
  }
}
fs.writeFileSync(new URL("../src/server/Pruebas/oleadas_2d.json", import.meta.url), JSON.stringify(casos));
console.log(`${casos.length} casos`);
