-- Normalización del perfil guardado (no toca el DataStore).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Perfiles = require(script.Parent.Parent.Perfiles)

	local nuevo = Perfiles.normalizar(nil)
	assert(nuevo.credits == 1200 and nuevo.gems == 500 and nuevo.cores == 0 and #nuevo.units == 0, "perfil nuevo: 1200 créditos y 500 gemas")

	local p = Perfiles.normalizar({
		credits = 5432.7,
		mapProgress = { level_1 = { bestWave = 12, stars = 3 }, level_2 = { bestWave = 400 } },
	})
	assert(p.credits == 5432, "créditos redondeados hacia abajo")
	assert(p.mapProgress.level_1.bestWave == 12 and p.mapProgress.level_1.stars == 12, "estrellas ≥ mejor oleada")
	assert(p.mapProgress.level_2.bestWave == 100, "mejor oleada con tope 100")

	assert(nuevo.modeRecords.survival.bestWave == 0, "récord de Infinito vacío")
	local conRecord = Perfiles.normalizar({ modeRecords = { survival = { bestWave = 31.9, bestScore = -4 } } })
	assert(conRecord.modeRecords.survival.bestWave == 31 and conRecord.modeRecords.survival.bestScore == 0, "récord normalizado")

	for _, roto in { { credits = -5 }, { credits = 0 / 0 }, { credits = math.huge }, { credits = "mucho" } } do
		assert(Perfiles.normalizar(roto).credits == 1200, "créditos inválidos vuelven al inicial")
	end

	-- Migración de la versión 1: una unidad por héroe, escuadrón conservado, objetos equipados se mantienen.
	local v1 = Perfiles.normalizar({
		unlockedHeroIds = { "hawkeye", "korg", "thor", "inexistente", "korg" },
		activeTeamIds = { "korg", "hawkeye" },
		heroUpgrades = { hawkeye = { level = 37 } },
		equippedItems = { hawkeye = { weapon = "tactical_vest" } },
	})
	assert(#v1.units == 3 and v1.units[1].heroId == "hawkeye" and v1.units[1].level == 1, "una unidad por héroe, nivel 1")
	assert(#v1.squad == 2 and v1.nextUnitUid == 4, "escuadrón migrado")
	assert(v1.gems == 500 and v1.heroUpgrades == nil, "gemas iniciales; los niveles viejos se descartan")

	-- Unidades guardadas: se descartan las rotas, uid repetido, personajes inexistentes y escuadrón ajeno.
	local v2 = Perfiles.normalizar({
		gems = 75.5,
		cores = -3,
		units = { { uid = 4, heroId = "korg", level = 80, xp = 12 }, { uid = 4, heroId = "thor" }, { uid = 9, heroId = "nadie" }, "basura", { uid = 6, heroId = "hawkeye_evolution", level = 2 } },
		nextUnitUid = 3,
		squad = { 6, 6, 99, 4 },
	})
	assert(v2.gems == 75 and v2.cores == 0, "gemas y núcleos saneados")
	assert(#v2.units == 2 and v2.units[1].level == 50 and v2.units[2].heroId == "hawkeye_evolution", "unidades válidas, nivel con tope 50")
	assert(v2.nextUnitUid == 7, "el próximo uid no choca con los existentes")
	assert(#v2.squad == 2 and v2.squad[1] == 6 and v2.squad[2] == 4, "escuadrón sin repetidos ni ajenos")
	return "OK: perfiles"
end
