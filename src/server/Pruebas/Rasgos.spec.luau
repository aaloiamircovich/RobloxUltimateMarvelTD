-- Rasgos y grados: probabilidades, garantía de mítico, bloqueo de grados, bonos en combate y guardado (docs/RASGOS.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Rasgos = require(Shared.Rasgos)
	local Unidades = require(Shared.Unidades)
	local Perfiles = require(script.Parent.Parent.Perfiles)

	local total = 0
	for _, r in Rasgos.LISTA do
		total += r.prob
	end
	assert(math.abs(total - 100) < 1e-9, "las probabilidades de rasgo suman 100")
	total = 0
	for _, g in Rasgos.GRADOS do
		total += g.prob
	end
	assert(total == 100, "las de grado también")

	local p = Perfiles.normalizar(nil)
	local u = Unidades.agregar(p, "hawkeye")
	assert(Rasgos.tirarRasgo(p, u, math.random) == nil, "sin fichas no se tira")

	-- Garantía: 49 tiradas comunes y la 50.ª es mítica.
	p.fichasRasgo = 60
	local comun = function()
		return 0
	end
	for _ = 1, Rasgos.GARANTIA - 1 do
		Rasgos.tirarRasgo(p, u, comun)
	end
	assert(u.rasgo == "fuerza1" and p.pityRasgo == Rasgos.GARANTIA - 1, "49 sin mítico")
	local r = Rasgos.tirarRasgo(p, u, comun)
	assert(r.rareza == "Mítico" and p.pityRasgo == 0 and p.fichasRasgo == 10, "la 50 es mítica")

	-- Grados: costo 1/2/4 y los bloqueados no cambian.
	p.cristales = 7
	assert(Rasgos.tirarGrados(p, u, {}, function()
		return 0.999
	end) == nil and Rasgos.grados(u).dano == "S+" and p.cristales == 6, "tirada sin bloqueo")
	assert(Rasgos.tirarGrados(p, u, { dano = true, alcance = true }, comun) == nil and p.cristales == 2, "2 bloqueos cuestan 4")
	local g = Rasgos.grados(u)
	assert(g.dano == "S+" and g.alcance == "S+" and g.cadencia == "C", "bloqueados se mantienen")
	assert(Rasgos.tirarGrados(p, u, { dano = true, alcance = true, cadencia = true }, comun) ~= nil, "máximo 2 bloqueos")

	-- Bonos en combate: Vibranium (+25 % daño, +5 % alcance, +15 % cadencia) con S+/S+/C.
	u.rasgo = "vibranium"
	local s = Rasgos.aplicar({ damage = 100, range = 100, fireRate = 1, critChance = 5 }, u)
	assert(math.abs(s.damage - 100 * 1.25 * 1.12) < 1e-6 and math.abs(s.range - 100 * 1.05 * 1.12) < 1e-6, "daño y alcance")
	assert(math.abs(s.fireRate - 1.15 * 0.98) < 1e-9 and s.critChance == 5, "cadencia con grado C")
	assert(Rasgos.dinero({ rasgo = "mercenario" }) == 0.10, "mercenario")

	-- Guardado: se conservan y se descarta basura.
	local copia = Perfiles.normalizar({ units = { { uid = 1, heroId = "hawkeye", rasgo = "vibranium", grados = { dano = "S+", alcance = "X" } } }, fichasRasgo = 3 })
	assert(copia.units[1].rasgo == "vibranium" and copia.units[1].grados.dano == "S+" and copia.units[1].grados.alcance == nil and copia.fichasRasgo == 3, "persistencia")
	assert(Rasgos.grados(copia.units[1]).alcance == "B", "grado faltante = B")
	return "OK: rasgos y grados"
end
