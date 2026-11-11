-- Raids: jefe de la semana, vida y fases, llaves diarias, premios, fragmentos y misiones (docs/RAIDS.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Raid = require(Shared.Raid)
	local Temporada = require(Shared.Temporada)
	local enemigos = require(Shared.Data.enemies)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local T = Temporada.INICIO + 3600

	for _, j in Raid.JEFES do
		assert(enemigos.bosses[j.id], "el jefe existe en el 2D: " .. j.id)
	end
	assert(Raid.jefe(Raid.semana(T)).id ~= Raid.jefe(Raid.semana(T) + 1).id, "rota cada semana")
	assert(Raid.vidaJefe(10000, 1) == 30000 and Raid.vidaJefe(10000, 4) == 84000, "vida de raid por jugadores")
	assert(Raid.fasesCruzadas(0.7, 0.5) == 1 and Raid.fasesCruzadas(0.7, 0.2) == 2 and Raid.fasesCruzadas(0.5, 0.4) == 0, "fases")

	-- Llaves: 3 por día, se renuevan al día siguiente.
	local p = Perfiles.normalizar(nil)
	assert(Raid.llaves(p, T) == 3 and Raid.puedeEntrar(p, T) == nil, "3 llaves")
	local nunca = function()
		return 0.99
	end
	for _ = 1, 3 do
		Raid.terminar(p, false, 1000, T, nunca)
	end
	assert(Raid.llaves(p, T) == 0 and Raid.puedeEntrar(p, T) ~= nil, "sin llaves")
	assert(p.raid.fragmentos == 3 * Raid.FRAGMENTOS_DERROTA, "consuelo por derrota")
	assert(Raid.llaves(p, T + Temporada.DIA) == 3, "nuevo día")

	-- Victoria: gemas, núcleos, fragmentos y objeto con suerte.
	local g, c = p.gems, p.cores
	local premio = Raid.terminar(p, true, 50000, T + Temporada.DIA, function()
		return 0.01
	end)
	assert(p.gems == g + 150 and p.cores == c + 2 and premio.fragmentos == 10, "premio de victoria")
	assert(premio.objeto and require(Shared.Data.items)[premio.objeto].rarity == "Mythic" and table.find(p.ownedItemIds, premio.objeto), "objeto mítico")

	-- Misiones de raid: jugar 5 (llevamos 4), daño acumulado.
	assert(Raid.reclamar(p, "jugar", T + Temporada.DIA) ~= nil, "jugar incompleta")
	Raid.terminar(p, false, 0, T + Temporada.DIA, nunca)
	local f = p.raid.fragmentos
	assert(Raid.reclamar(p, "jugar", T + Temporada.DIA) == nil and p.raid.fragmentos == f + 10, "misión jugar")
	assert(Raid.reclamar(p, "jugar", T + Temporada.DIA) ~= nil, "una sola vez")
	assert(p.raid.progreso.dano == 53000, "daño acumulado")

	-- Semana nueva: misiones a cero, fragmentos se conservan.
	Raid.actualizar(p, T + Temporada.SEMANA)
	assert(p.raid.progreso.jugar == 0 and next(p.raid.reclamadas) == nil and p.raid.fragmentos == f + 10, "nueva semana")

	-- Guardado.
	local copia = Perfiles.normalizar({ raid = p.raid })
	assert(copia.raid.fragmentos == p.raid.fragmentos, "persistencia")
	assert(Perfiles.normalizar({ raid = { usadas = 99, fragmentos = "x" } }).raid.usadas == Raid.LLAVES_DIA, "datos rotos")
	return "OK: raids"
end
