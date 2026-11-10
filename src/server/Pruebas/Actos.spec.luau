-- Historia por actos (docs/PARTIDA.md): desbloqueos, Pesadilla, premios y jefe forzado en la oleada 10.
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Actos = require(Shared.Actos)
	local Oleadas = require(Shared.Oleadas)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local enemigos, niveles = require(Shared.Data.enemies), require(Shared.Data.levels)

	local p = Perfiles.normalizar(nil)
	assert(Actos.mapaAbierto(p, "level_1") and not Actos.mapaAbierto(p, "level_2"), "sólo el primer mapa abierto")
	assert(Actos.puedeJugar(p, "level_1", 1) == nil and Actos.puedeJugar(p, "level_1", 2) ~= nil, "acto 2 cerrado")
	assert(Actos.puedeJugar(p, "level_1", 1, true) ~= nil, "Pesadilla cerrada hasta ganar el acto")
	assert(Actos.puedeJugar(p, "level_1", "infinito") ~= nil, "Infinito cerrado")
	assert(Actos.puedeJugar(p, "level_1", 7) == "Acto inválido", "acto fuera de rango")

	-- Primera victoria: 50 × acto gemas + 1 núcleo; repetir: 10 gemas.
	local g0 = p.gems
	local premio = Actos.ganar(p, "level_1", 1)
	assert(premio.primera and premio.gemas == 50 and p.gems == g0 + 50 and p.cores == 1, "primera vez")
	assert(Actos.ganar(p, "level_1", 1).gemas == 10, "repetir")
	assert(Actos.puedeJugar(p, "level_1", 2) == nil and Actos.puedeJugar(p, "level_1", 1, true) == nil, "abre el acto 2 y la Pesadilla del 1")
	local pes = Actos.ganar(p, "level_1", 1, true)
	assert(pes.gemas == 100 and pes.nucleos == 2, "Pesadilla ×2")
	for a = 2, 5 do
		Actos.ganar(p, "level_1", a)
	end
	assert(Actos.mapaAbierto(p, "level_2") and Actos.puedeJugar(p, "level_1", "infinito") == nil, "acto 5 abre mapa siguiente e Infinito")
	assert(Actos.oleada2D(3, 10) == 30, "el acto 3 juega las oleadas 21–30 del 2D")

	-- Oleada 10 del acto: jefe de la facción; con false no hay jefe aunque toque uno del 2D (oleada 25).
	local nivel = niveles[1]
	local cola = Oleadas.preparar(10, enemigos, nivel, 0, {}, "campaign", 1)
	assert(#cola == 1 and cola[1].enemigo.isBoss and cola[1].enemigo.id == Oleadas.jefeDeActo(nivel, 1), "jefe del acto 1")
	local sinJefe = Oleadas.preparar(25, enemigos, nivel, 0, {}, "campaign", false)
	for _, e in sinJefe do
		assert(not e.enemigo.isBoss, "sin jefe a mitad de acto")
	end
	return "OK: actos"
end
