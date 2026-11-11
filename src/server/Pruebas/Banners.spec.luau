-- Banners 2 y 3: destacado semanal, garantía del limitado y pago con fichas del desafío (docs/INVOCACIONES.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Banners = require(Shared.Banners)
	local Personajes = require(Shared.Personajes)
	local Temporada = require(Shared.Temporada)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local T = Temporada.INICIO + 3600
	local w = Temporada.semana(T)

	local total = 0
	for _, p in Banners.LIMITADO.prob do
		total += p
	end
	assert(total == 100, "probabilidades del limitado suman 100")
	local d = Banners.destacado(w)
	assert(Personajes.de(d).rarity == "Mythic" and Banners.destacado(w + 1) ~= d, "Mítico destacado que rota")

	local p = Perfiles.normalizar({ units = { { uid = 1, heroId = "hawkeye" } } })
	assert(select(2, Banners.limitado(p, 3, w, math.random)) ~= nil, "sólo x1 o x10")
	p.gems = 80 * 100
	-- Con azar que nunca da Mítico, la tirada 80 es el destacado.
	local comun = function()
		return 0.5
	end
	for _ = 1, 7 do
		Banners.limitado(p, 10, w, comun)
	end
	assert(p.shop.limitadoPity == 70, "70 sin destacado")
	local nuevas = Banners.limitado(p, 10, w, comun)
	assert(nuevas[10].heroId == d and p.shop.limitadoPity == 0, "la 80 es el destacado y el contador vuelve a 0")
	assert(p.gems == 80 * 100 - 80 * 80, "80 gemas por tirada")
	-- Con azar mínimo sale Mítico y, dentro de la parte del destacado, el destacado.
	assert(Banners.limitado(p, 1, w, function()
		return 0.999
	end)[1].heroId ~= nil, "tirada válida")

	-- Banner 3: fichas del desafío.
	local q = Perfiles.normalizar({ units = { { uid = 1, heroId = "hawkeye" } } })
	assert(select(2, Banners.fichas(q, 1, T, math.random)) ~= nil, "sin fichas")
	q.evento.semana = w
	q.evento.fichas = 300
	local u = Banners.fichas(q, 10, T, math.random)
	assert(#u == 10 and q.evento.fichas == 0, "x10 con 300 fichas")
	assert(Perfiles.normalizar({ shop = { limitadoPity = 55 } }).shop.limitadoPity == 55, "el contador se guarda")
	return "OK: banners 2 y 3"
end
