-- Banner 2: Mítico destacado cada 3 horas, pagado con fichas de raid, con garantía (docs/INVOCACIONES.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Banners = require(Shared.Banners)
	local Raid = require(Shared.Raid)
	local Personajes = require(Shared.Personajes)
	local Temporada = require(Shared.Temporada)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local T = Temporada.INICIO + 3600

	local total = 0
	for _, p in Banners.LIMITADO.prob do
		total += p
	end
	assert(total == 100, "probabilidades suman 100")
	local d = Banners.destacado(Banners.periodo(T))
	assert(Personajes.de(d).rarity == "Mythic", "el destacado es Mítico")
	assert(Banners.destacado(Banners.periodo(T + 3 * 3600)) ~= d, "cambia a las 3 horas")
	assert(Banners.periodo(T) == Banners.periodo(T + 3600) or Banners.periodo(T) + 1 == Banners.periodo(T + 3600), "períodos de 3 horas")

	local p = Perfiles.normalizar({ units = { { uid = 1, heroId = "hawkeye" } } })
	assert(select(2, Banners.limitado(p, 1, T, math.random)) ~= nil, "sin fichas de raid no se tira")
	assert(select(2, Banners.limitado(p, 3, T, math.random)) ~= nil, "sólo x1 o x10")

	-- Fichas de raid: victoria 20, derrota 5, misión 10.
	local nunca = function()
		return 0.99
	end
	Raid.terminar(p, true, 0, T, nunca)
	Raid.terminar(p, false, 0, T, nunca)
	assert(p.fichasRaid == 25, "20 por victoria y 5 por derrota")

	-- Garantía a las 80 tiradas sin destacado (azar que nunca da Mítico).
	p.fichasRaid = 10 * 80
	local comun = function()
		return 0.5
	end
	for _ = 1, 7 do
		Banners.limitado(p, 10, T, comun)
	end
	assert(p.shop.limitadoPity == 70 and p.fichasRaid == 100, "70 tiradas, 10 fichas cada una")
	local nuevas = Banners.limitado(p, 10, T, comun)
	assert(nuevas[10].heroId == d and p.shop.limitadoPity == 0 and p.fichasRaid == 0, "la 80 es el destacado")

	assert(Perfiles.normalizar({ fichasRaid = 33, shop = { limitadoPity = 55 } }).shop.limitadoPity == 55, "el contador se guarda")
	assert(Perfiles.normalizar({ fichasRaid = 33 }).fichasRaid == 33, "las fichas de raid se guardan")
	return "OK: banner 2"
end
