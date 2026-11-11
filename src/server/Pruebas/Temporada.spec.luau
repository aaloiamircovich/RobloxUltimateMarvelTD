-- Misiones diarias/semanales y pase de batalla (docs/TEMPORADA.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Temporada = require(Shared.Temporada)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local T = Temporada.INICIO + 3600 -- miércoles 11/11/2026, temporada 1

	local p = Perfiles.normalizar(nil)
	local s = Temporada.actualizar(p, T)
	assert(#s.diarias == 3 and #s.semanales == 3 and s.numero == 1, "3 diarias, 3 semanales, temporada 1")
	for _, m in s.diarias do
		assert(m.id ~= "infinito", "Infinito no sale en las diarias")
	end
	local otro = Temporada.actualizar(Perfiles.normalizar(nil), T + 60)
	assert(otro.diarias[1].id == s.diarias[1].id, "mismas misiones para todos el mismo día")

	-- Completar y reclamar una diaria: gemas + XP de pase; no se reclama dos veces.
	local m = s.diarias[1]
	local meta = Temporada.meta("diarias", m.id)
	assert(Temporada.reclamar(p, "diarias", 1, T) ~= nil, "incompleta")
	local evento = (function()
		for _, t in Temporada.TAREAS do
			if t.id == m.id then
				return t.evento
			end
		end
	end)()
	Temporada.registrar(p, evento, meta + 50, T)
	assert(m.progreso == meta, "el progreso no pasa la meta")
	local g = p.gems
	assert(Temporada.reclamar(p, "diarias", 1, T) == nil and p.gems == g + 15 and s.xp == 100, "premio diario")
	assert(Temporada.reclamar(p, "diarias", 1, T) ~= nil, "una sola vez")

	-- Infinito cuenta el mejor valor, no la suma.
	p.temporada.semanales[1] = { id = "infinito", progreso = 0, reclamada = false }
	Temporada.registrar(p, "infinito", 12, T)
	Temporada.registrar(p, "infinito", 8, T)
	assert(p.temporada.semanales[1].progreso == 12, "máximo en Infinito")

	-- Al día siguiente cambian las diarias; las semanales siguen hasta el lunes.
	local semanales = p.temporada.semanales
	Temporada.actualizar(p, T + Temporada.DIA)
	assert(not p.temporada.diarias[1].reclamada and p.temporada.semanales == semanales, "renovación diaria")
	assert(Temporada.semana(T + 5 * Temporada.DIA) == Temporada.semana(T) + 1, "el lunes 16/11 empieza otra semana")

	-- Pase: niveles por XP, premios y tope.
	assert(Temporada.reclamarPase(p, 1, T) ~= nil, "nivel 1 sin XP")
	Temporada.ganarXP(p, 5 * Temporada.XP_NIVEL, T)
	assert(Temporada.nivel(p) == 5, "nivel 5")
	g = p.gems
	assert(Temporada.reclamarPase(p, 1, T) == nil and p.gems == g + 20, "nivel 1: 20 gemas")
	assert(Temporada.reclamarPase(p, 1, T) ~= nil, "nivel ya reclamado")
	local obj = Temporada.premio(1, 5)
	assert(obj.tipo == "objeto" and obj.id, "nivel 5: objeto")
	assert(Temporada.reclamarPase(p, 5, T) == nil and table.find(p.ownedItemIds, obj.id), "objeto entregado")
	assert(Temporada.premio(1, 10).tipo == "nucleos" and Temporada.premio(1, 40).cantidad == 4, "núcleos cada 10")
	Temporada.ganarXP(p, 1e6, T)
	assert(Temporada.nivel(p) == Temporada.NIVELES, "tope en 50")
	local antes = #p.units
	assert(Temporada.reclamarPase(p, 50, T) == nil and #p.units == antes + 1 and p.units[#p.units].heroId == "odin", "nivel 50: Odin")

	-- Nueva temporada: el pase vuelve a cero.
	Temporada.actualizar(p, T + Temporada.DURACION)
	assert(p.temporada.numero == 2 and p.temporada.xp == 0 and #p.temporada.reclamados == 0, "temporada 2")

	-- Guardado: sobrevive a normalizar y descarta basura.
	local copia = Perfiles.normalizar({ temporada = p.temporada })
	assert(copia.temporada.numero == 2 and #copia.temporada.diarias == 3, "persistencia")
	local rota = Perfiles.normalizar({ temporada = { xp = "x", diarias = { { id = "hackear" } }, reclamados = { 999 } } })
	assert(rota.temporada.xp == 0 and #rota.temporada.diarias == 0 and #rota.temporada.reclamados == 0, "datos rotos")
	return "OK: temporada"
end
