-- Niveles y evoluciones de héroes, portados de HeroLevel.js y EvolutionSystem.js del 2D.
-- Módulo puro: se verifica contra Pruebas/progresion_2d.json.
local evoluciones = require(script.Parent.Data.evolutions)

local Progresion = {}

Progresion.NIVEL_MAXIMO = 100

local TOPE_RAREZA = { Common = 18, Rare = 21, Epic = 24, Legendary = 27, Mythic = 30, Secret = 33 }
-- Curva de daño por nivel; desde el 99 el valor se multiplica por el tope de la rareza.
local CURVA = { { 1, 1 }, { 15, 2.8 }, { 16, 3.4 }, { 35, 6.1 }, { 36, 7.4 }, { 99, 0.97 }, { 100, 1 } }

-- Créditos para subir de `nivel` a `nivel + 1`; nil si ya está al máximo.
function Progresion.costo(nivel: number): number?
	if nivel >= Progresion.NIVEL_MAXIMO then
		return nil
	end
	return math.ceil(180 * 1.08 ^ (nivel - 1) / 10) * 10
end

function Progresion.multiplicadorDano(nivel: number, rareza: string?): number
	local tope = TOPE_RAREZA[rareza or ""] or TOPE_RAREZA.Common
	local function valor(i)
		local n, v = CURVA[i][1], CURVA[i][2]
		return if n >= 99 then tope * v else v
	end
	for i = 2, #CURVA do
		if nivel <= CURVA[i][1] then
			local n0, n1 = CURVA[i - 1][1], CURVA[i][1]
			local progreso = (nivel - n0) / math.max(1, n1 - n0) -- mismo orden que el 2D: cambia el redondeo
			return valor(i - 1) + (valor(i) - valor(i - 1)) * progreso
		end
	end
	return tope
end

-- Evolución por nivel activa (sin transformaciones por objeto), o nil.
function Progresion.evolucion(heroeId: string, nivel: number)
	local e = evoluciones[heroeId]
	if e and nivel >= (e.requiredLevel or 50) then
		return e
	end
	return nil
end

-- Subconjunto de Hero.getEffectiveStats: nivel, evolución y modificadores especiales.
-- shortcut: sin objetos, maestrías, auras ni sinergias; se suman cuando existan esos sistemas.
function Progresion.stats(config, nivel: number)
	local s = {
		damage = math.floor(config.damage * Progresion.multiplicadorDano(nivel, config.rarity)),
		fireRate = config.fireRate,
		range = config.range,
		critChance = config.critChance or 5,
		critDamage = 2,
		canSeeStealth = config.canSeeStealth or false,
	}
	local evo = Progresion.evolucion(config.id, nivel)
	if evo then
		s.damage *= 1 + (evo.stats.damage or 0)
		s.fireRate *= 1 + (evo.stats.fireRate or 0)
		s.range *= 1 + (evo.stats.range or 0)
		s.critChance += evo.stats.critChance or 0
		s.canSeeStealth = s.canSeeStealth or evo.canSeeStealth or evo.id == "iron_spider"
	end
	local sp = config.special and config.special.statModifiers or {}
	s.damage *= 1 + (sp.damagePct or 0)
	s.fireRate *= 1 + (sp.fireRatePct or 0)
	s.range *= 1 + (sp.rangePct or 0)
	s.critChance += sp.critChance or 0
	s.canSeeStealth = s.canSeeStealth or sp.detectStealth == true
	return s
end

-- Config con el alcance efectivo, para validar el despliegue como preview() del 3D.
function Progresion.paraDespliegue(config, nivel: number)
	local c = table.clone(config)
	c.range = Progresion.stats(config, nivel).range
	return c
end

return Progresion
