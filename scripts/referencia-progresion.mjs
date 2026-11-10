// Exporta del 2D el catálogo de evoluciones (src/shared/Data/evolutions.json) y la referencia
// de costos y stats por nivel (src/server/Pruebas/progresion_2d.json).
// Uso: node scripts/referencia-progresion.mjs <ruta al repo UltimateMarvelTD_3D>
import fs from "fs";
import path from "path";
import { pathToFileURL } from "url";

const origen = process.argv[2];
if (!origen) throw new Error("Falta la ruta al repo UltimateMarvelTD_3D");
const importar = (f) => import(pathToFileURL(path.join(origen, "src/legacy/src", f)));
const { calculateHeroLevelCost, getHeroDamageAtLevel } = await importar("utils/HeroLevel.js");
const { EVOLUTION_CATALOG, getEvolutionForHero, applyEvolutionStats } = await importar("systems/EvolutionSystem.js");
const salida = (f) => new URL(`../${f}`, import.meta.url);
const heroes = JSON.parse(fs.readFileSync(salida("src/shared/Data/heroes.json"), "utf8"));

// Sólo lo que usan las reglas; las transformaciones por objeto esperan al sistema de objetos.
const evoluciones = {};
for (const e of Object.values(EVOLUTION_CATALOG)) {
  evoluciones[e.baseHeroId] = { id: e.id, name: e.name, requiredLevel: e.requiredLevel, stats: e.stats, canSeeStealth: e.canSeeStealth };
}
fs.writeFileSync(salida("src/shared/Data/evolutions.json"), JSON.stringify(evoluciones, null, 2) + "\n");

const costos = [];
for (let n = 1; n <= 99; n++) costos.push(calculateHeroLevelCost(n));
const niveles = [1, 2, 15, 16, 30, 35, 36, 49, 50, 75, 99, 100];
const stats = [];
for (const h of Object.values(heroes)) {
  for (const nivel of niveles) {
    // Subconjunto de Hero.getEffectiveStats: nivel, evolución y modificadores especiales (sin objetos ni auras).
    const s = { damage: getHeroDamageAtLevel(h.damage, nivel, h.rarity), fireRate: h.fireRate, range: h.range, critChance: h.critChance || 5, canSeeStealth: h.canSeeStealth || false };
    applyEvolutionStats(s, getEvolutionForHero(h, {}, { level: nivel }));
    const sp = h.special?.statModifiers || {};
    s.damage *= 1 + (sp.damagePct || 0);
    s.fireRate *= 1 + (sp.fireRatePct || 0);
    s.range *= 1 + (sp.rangePct || 0);
    s.critChance += sp.critChance || 0;
    if (sp.detectStealth) s.canSeeStealth = true;
    stats.push([h.id, nivel, +s.damage.toFixed(4), +s.fireRate.toFixed(4), +s.range.toFixed(4), +s.critChance.toFixed(4), s.canSeeStealth ? 1 : 0]);
  }
}
fs.writeFileSync(salida("src/server/Pruebas/progresion_2d.json"), JSON.stringify({ costos, stats }));
console.log(`${Object.keys(evoluciones).length} evoluciones, ${costos.length} costos, ${stats.length} stats`);
