-- Arranque del servidor. Por ahora sólo verifica que los datos del 2D llegaron completos.
local Data = game:GetService("ReplicatedStorage").Shared.Data

local function count(t)
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local heroes = require(Data.heroes)
local enemies = require(Data.enemies)
local items = require(Data.items)
local levels = require(Data.levels)
local typeChart = require(Data.TypeChart)

assert(count(heroes) == 105, "héroes: se esperaban 105")
assert(count(enemies.normal) + count(enemies.bosses) == 49, "enemigos: se esperaban 49")
assert(count(items) == 82, "objetos: se esperaban 82")
assert(#levels == 11, "mapas: se esperaban 11")
assert(typeChart["Tecnológico"]["Urbano"] == 1.5, "tabla de tipos ilegible")
assert(heroes.iron_man.name == "Iron Man", "héroe de control ilegible")

print(`[UMTD] Datos OK: {count(heroes)} héroes, 49 enemigos, {count(items)} objetos, {#levels} mapas`)
