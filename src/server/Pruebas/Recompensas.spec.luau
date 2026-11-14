-- Premio diario, códigos y logros (docs/RECOMPENSAS.md). Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Recompensas = require(game:GetService("ReplicatedStorage").Shared.Recompensas)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local DIA = 86400
	local t0 = 1794355200 + 3600 -- 11/11/2026 01:00 UTC

	-- Racha diaria
	local p = Perfiles.normalizar(nil)
	local gemas = p.gems
	local premio = Recompensas.reclamarDiario(p, t0)
	assert(premio and premio.gemas == 30 and p.gems == gemas + 30 and p.diario.racha == 1, "día 1: 30 gemas")
	local _, err = Recompensas.reclamarDiario(p, t0 + 3600)
	assert(err, "una vez por día")
	assert(Recompensas.estadoDiario(p, t0 + DIA).dia == 2, "al día siguiente toca el 2")
	for i = 1, 6 do
		Recompensas.reclamarDiario(p, t0 + i * DIA)
	end
	assert(p.diario.racha == 7, "llegó al día 7")
	assert(Recompensas.estadoDiario(p, t0 + 7 * DIA).dia == 1, "después del 7 vuelve al 1")
	assert(Recompensas.estadoDiario(p, t0 + 9 * DIA).dia == 1, "faltar un día reinicia la racha")
	local p2 = Perfiles.normalizar(nil)
	Recompensas.reclamarDiario(p2, t0)
	Recompensas.reclamarDiario(p2, t0 + DIA)
	assert(Recompensas.estadoDiario(p2, t0 + 3 * DIA).dia == 1, "saltear un día vuelve al 1")

	-- Códigos
	local p3 = Perfiles.normalizar(nil)
	local g = p3.gems
	assert(Recompensas.canjear(p3, " bienvenido ", t0) and p3.gems == g + 100, "código sin mayúsculas ni espacios")
	assert(select(2, Recompensas.canjear(p3, "BIENVENIDO", t0)), "un canje por cuenta")
	assert(select(2, Recompensas.canjear(p3, "NOEXISTE", t0)), "código inexistente")
	assert(select(2, Recompensas.canjear(p3, "HEROES2026", 1798761600)), "código vencido")
	assert(select(2, Recompensas.canjear(p3, string.rep("A", 100), t0)), "texto muy largo")

	-- Logros
	local p4 = Perfiles.normalizar(nil)
	assert(select(2, Recompensas.reclamarLogro(p4, "acto_1")), "sin completar no se reclama")
	p4.acts.level_1 = { normal = 1, pesadilla = 0 }
	local g4 = p4.gems
	assert(Recompensas.reclamarLogro(p4, "acto_1") and p4.gems == g4 + 50, "primer acto: 50 gemas")
	assert(select(2, Recompensas.reclamarLogro(p4, "acto_1")), "no se repite")
	Recompensas.contar(p4, "derrota", 600)
	Recompensas.contar(p4, "jefe", 3)
	local e
	for _, l in Recompensas.estadoLogros(p4) do
		if l.id == "enemigos_500" then
			e = l
		end
	end
	assert(e.progreso == 500 and p4.estadisticas.jefes == 3, "contadores de combate")

	-- Normalización
	local n = Perfiles.normalizar({ diario = { ultimoDia = "x", racha = 99 }, codigos = { BIENVENIDO = true, [5] = true }, estadisticas = { enemigos = -3 } })
	assert(n.diario.ultimoDia == -1 and n.diario.racha == 7 and n.codigos.BIENVENIDO and n.codigos[5] == nil and n.estadisticas.enemigos == 0, "datos rotos normalizados")
	return "ok"
end
