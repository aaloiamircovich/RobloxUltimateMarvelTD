-- Reglas de colección del 2D: elección inicial, costo creciente, sin repetidos, garantía tras
-- cuatro comunes y escuadrón de 1 a 6.
-- Ejecutar en Studio: require(game.ServerScriptService.Server.Pruebas["Reclutamiento.spec"])()
return function()
	local Reclutamiento = require(script.Parent.Parent.Reclutamiento)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local heroes = require(game:GetService("ReplicatedStorage").Shared.Data.heroes)

	local p = Perfiles.normalizar(nil)
	local _, motivo = Reclutamiento.reclutar(p, heroes, math.random)
	assert(motivo == "Elegí tu héroe inicial primero.", "sin inicial no se recluta")
	assert(Reclutamiento.elegirInicial(p, "thor") == "Ese no es un héroe inicial", "sólo los tres iniciales")
	assert(Reclutamiento.elegirInicial(p, "korg") == nil and p.unlockedHeroIds[1] == "korg" and p.activeTeamIds[1] == "korg", "elegir inicial")
	assert(Reclutamiento.elegirInicial(p, "hawkeye") ~= nil, "no se elige dos veces")

	-- Costo: 500, 560, 628… (×1.12 redondeado hacia arriba).
	p.credits = 1e9
	local costos = {}
	for _ = 1, 3 do
		table.insert(costos, Reclutamiento.costo(p))
		Reclutamiento.reclutar(p, heroes, math.random)
	end
	assert(costos[1] == 500 and costos[2] == 560 and costos[3] == 628, `costos {table.concat(costos, ",")}`)
	assert(p.credits == 1e9 - 1688, "descuenta el costo")

	-- Sin repetidos hasta agotar los 105; después avisa.
	local Rng = Random.new(7)
	for _ = 1, 200 do
		if not Reclutamiento.reclutar(p, heroes, function()
			return Rng:NextNumber()
		end) then
			break
		end
	end
	local vistos = {}
	for _, id in p.unlockedHeroIds do
		assert(not vistos[id], "repetido: " .. id)
		vistos[id] = true
	end
	local total = 0
	for _ in heroes do
		total += 1
	end
	assert(#p.unlockedHeroIds == total, "se pueden reclutar todos")
	assert(select(2, Reclutamiento.reclutar(p, heroes, math.random)) == "Ya tenés todos los héroes", "colección completa")
	assert(#p.activeTeamIds == 6, "los reclutados llenan el escuadrón hasta 6")

	-- Garantía: con 4 comunes seguidos el siguiente no es común.
	local q = Perfiles.normalizar({ credits = 1e9, unlockedHeroIds = { "korg" }, shop = { heroPity = 4 } })
	local h = Reclutamiento.reclutar(q, heroes, function()
		return 0
	end)
	assert(h.rarity ~= "Common" and q.shop.heroPity == 0, "garantía de rareza superior")
	local odds = Reclutamiento.probabilidades(Perfiles.normalizar({ unlockedHeroIds = { "korg" }, shop = { heroPity = 4 } }), heroes)
	assert(odds.Common == nil, "con garantía no hay comunes en las probabilidades")

	local sinPlata = Perfiles.normalizar({ credits = 499, unlockedHeroIds = { "korg" } })
	assert(select(2, Reclutamiento.reclutar(sinPlata, heroes, math.random)) == "Créditos insuficientes", "sin créditos")

	-- Escuadrón.
	local r = Perfiles.normalizar({ unlockedHeroIds = { "korg" } })
	assert(Reclutamiento.fijarEquipo(r, {}) ~= nil, "vacío no")
	assert(Reclutamiento.fijarEquipo(r, { "thor" }) ~= nil, "sólo desbloqueados")
	assert(Reclutamiento.fijarEquipo(r, { "korg", "korg" }) == nil and #r.activeTeamIds == 1, "sin repetidos")
	return "OK: reclutamiento"
end
