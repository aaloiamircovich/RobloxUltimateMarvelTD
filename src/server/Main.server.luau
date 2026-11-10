-- Arranque del servidor.
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

local enemyCount = count(enemies.normal) + count(enemies.bosses)

-- warn en vez de assert: datos incompletos no deben impedir que arranque el resto del servidor.
if count(heroes) == 0 or enemyCount == 0 or count(items) == 0 or #levels == 0 or not typeChart["Tecnológico"] then
	warn("[UMTD] Datos incompletos: revisar src/shared/Data")
end

print(`[UMTD] Datos OK: {count(heroes)} héroes, {enemyCount} enemigos, {count(items)} objetos, {#levels} mapas`)
