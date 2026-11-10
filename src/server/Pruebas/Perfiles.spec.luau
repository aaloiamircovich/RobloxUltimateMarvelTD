-- Normalización del perfil guardado (no toca el DataStore).
-- Ejecutar en Studio: require(game.ServerScriptService.Server.Pruebas["Perfiles.spec"])()
return function()
	local Perfiles = require(script.Parent.Parent.Perfiles)

	local nuevo = Perfiles.normalizar(nil)
	assert(nuevo.credits == 1200 and next(nuevo.heroUpgrades) == nil, "perfil nuevo: 1200 créditos y sin niveles")

	local p = Perfiles.normalizar({
		credits = 5432.7,
		heroUpgrades = { hawkeye = { level = 37 }, korg = 150, black_widow = { level = 1 }, [5] = { level = 9 } },
		mapProgress = { level_1 = { bestWave = 12, stars = 3 }, level_2 = { bestWave = 400 } },
	})
	assert(p.credits == 5432, "créditos redondeados hacia abajo")
	assert(p.heroUpgrades.hawkeye.level == 37, "nivel guardado")
	assert(p.heroUpgrades.korg.level == 100, "nivel numérico del 2D, con tope 100")
	assert(p.heroUpgrades.black_widow == nil, "nivel 1 no se guarda, como el 2D")
	assert(p.heroUpgrades[5] == nil, "claves que no son id se descartan")
	assert(p.mapProgress.level_1.bestWave == 12 and p.mapProgress.level_1.stars == 12, "estrellas ≥ mejor oleada")
	assert(p.mapProgress.level_2.bestWave == 100, "mejor oleada con tope 100")

	for _, roto in { { credits = -5 }, { credits = 0 / 0 }, { credits = math.huge }, { credits = "mucho" } } do
		assert(Perfiles.normalizar(roto).credits == 1200, "créditos inválidos vuelven al inicial")
	end
	return "OK: perfiles"
end
