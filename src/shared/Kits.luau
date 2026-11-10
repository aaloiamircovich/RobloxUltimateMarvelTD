-- Kits de habilidad de los héroes iniciales, portados de AvengerKitSystem.js (Hawkeye, Black Widow)
-- y StreetKitSystem.js (Korg) del 2D, más el perfil de proyectil y efectos genéricos de config.special.
-- Módulo puro: recibe posiciones en píxeles del 2D y devuelve qué golpes aplicar.
local Combate = require(script.Parent.Combate)
local Despliegue = require(script.Parent.Despliegue)

local Kits = {}

Kits.MODOS_HAWKEYE = { "explosive", "cryo", "piercing" }
Kits.NOMBRE_MODO = { explosive = "Explosiva", cryo = "Criogénica", piercing = "Perforante" }

function Kits.nuevo(heroeId: string)
	return {
		heroe = heroeId,
		ataques = 0,
		modo = if heroeId == "hawkeye" then "explosive" else nil,
		enfriamiento = if heroeId == "korg" then 5 else 0,
	}
end

-- getPowerScale del 2D (sin bonus de maestrías ni sinergias todavía).
function Kits.escalaPoder(nivel: number): number
	return 1 + math.min(0.35, math.max(0, nivel - 1) * 0.035)
end

local function flechaPreparada(kit)
	return kit.heroe == "hawkeye" and kit.ataques % 4 == 3
end

-- getConditionalItemDamageMultiplier del 2D: bonus del objeto según el blanco y la distancia (px).
local function multiplicadorObjeto(ef, objetivo, distancia: number): number
	local m = 1
	local function tiene(tipos)
		for _, t in tipos do
			if objetivo.estados[t] then
				return true
			end
		end
		return false
	end
	if ef.bossDamagePct and objetivo.config.isBoss then
		m *= 1 + ef.bossDamagePct
	end
	if ef.armorDamagePct and ((objetivo.config.armor or 0) > 0 or objetivo.barrera > 0) then
		m *= 1 + ef.armorDamagePct
	end
	if ef.damageToControlledPct and tiene({ "slow", "stun", "web" }) then
		m *= 1 + ef.damageToControlledPct
	end
	if ef.damageToBurnedPct and tiene({ "burn" }) then
		m *= 1 + ef.damageToBurnedPct
	end
	if ef.damageToCursedPct and tiene({ "curse" }) then
		m *= 1 + ef.damageToCursedPct
	end
	local estados = Combate.cantidadEstados(objetivo)
	if ef.statusDamagePct and estados > 0 then
		m *= 1 + math.min(ef.statusDamageCap or 0.5, ef.statusDamagePct * estados)
	end
	if ef.longRangeDamagePct and distancia >= (ef.longRangeThreshold or 150) then
		m *= 1 + ef.longRangeDamagePct
	end
	if ef.closeRangeDamagePenaltyPct and distancia < (ef.closeRangeThreshold or 120) then
		m *= 1 - ef.closeRangeDamagePenaltyPct
	end
	return math.max(0.1, m)
end

-- Efectos al golpear que agrega el objeto (getProjectileEffects del 2D).
local function efectosObjeto(ef, stats)
	local r = {}
	if ef.slowChance then
		table.insert(r, { type = "slow", duration = 1.2, power = ef.slowPower or 0.2, chance = ef.slowChance })
	end
	if ef.armorBreakChance then
		table.insert(r, { type = "armorBreak", duration = 3, power = ef.armorBreakPower or 0.15, chance = ef.armorBreakChance })
	end
	if ef.burnChance then
		local escala = ef.burnAttackDamagePct ~= nil
		table.insert(r, {
			type = "burn",
			duration = ef.burnDuration or 4,
			chance = ef.burnChance,
			power = if escala then ef.burnAttackDamagePct else (ef.burnPower or 0.018),
			damageBasis = if escala then "attackDamage" else nil,
			attackDamageSnapshot = if escala then stats.damage else nil,
		})
	end
	if ef.poisonChance then
		table.insert(r, { type = "poison", duration = ef.poisonDuration or 4, power = ef.poisonPower or 0.01, stacks = ef.poisonStacks or 1, chance = ef.poisonChance })
	end
	if ef.curseChance then
		table.insert(r, { type = "curse", duration = ef.curseDuration or 4, power = ef.cursePower or 0.01, chance = ef.curseChance })
	end
	if ef.stunChance then
		table.insert(r, { type = "stun", duration = ef.stunDuration or 0.25, power = 1, chance = ef.stunChance })
	end
	return r
end

-- Golpe del disparo principal, armado ANTES de contar el ataque (como Hero.shoot del 2D).
-- danoBase ya incluye el crítico; objeto: items.json o nil; distancia: héroe→blanco en px.
-- Devuelve { tipo, dano, penetracion, efectos, radioSplash, factorSplash, rebotes, rangoRebote, factorRebote }.
function Kits.golpe(kit, config, objetivo, danoBase: number, stats, objeto, distancia: number?)
	local especial = config.special or {}
	local perfil = especial.projectileProfile or {}
	local ef = objeto and objeto.effects or {}
	local golpe = {
		tipo = config.category,
		dano = danoBase,
		penetracion = perfil.armorPenetration,
		radioSplash = perfil.splashRadius,
		factorSplash = perfil.splashFactor,
		efectos = {},
	}
	if kit.heroe == "hawkeye" then
		local preparada = flechaPreparada(kit)
		golpe.dano *= if preparada then 1.35 else 1
		if kit.modo == "explosive" then
			golpe.radioSplash, golpe.factorSplash = if preparada then 85 else 68, 0.58
		elseif kit.modo == "piercing" then
			golpe.penetracion = if preparada then 0.8 else 0.65
		elseif kit.modo == "cryo" then
			table.insert(golpe.efectos, { type = "slow", duration = 2.4, power = if preparada then 0.6 else 0.48, chance = 1 })
		end
	elseif kit.heroe == "black_widow" and Combate.esApoyo(objetivo) then
		table.insert(golpe.efectos, { type = "armorBreak", duration = 4, power = 0.3, chance = 1 })
	end
	-- Orden del 2D: efectos del kit, efectos especiales del héroe y efectos del objeto.
	for _, e in especial.attackEffects or {} do
		table.insert(golpe.efectos, e)
	end
	if objeto then
		for _, e in efectosObjeto(ef, stats) do
			table.insert(golpe.efectos, e)
		end
		golpe.dano *= multiplicadorObjeto(ef, objetivo, distancia or 0)
		-- consecutiveDamagePct: golpes seguidos al mismo blanco.
		if ef.consecutiveDamagePct then
			if kit.ultimoBlanco == objetivo then
				kit.seguidos = (kit.seguidos or 0) + 1
				golpe.dano *= 1 + kit.seguidos * ef.consecutiveDamagePct
			else
				kit.seguidos, kit.ultimoBlanco = 0, objetivo
			end
		end
	end
	-- getProjectileProfile del 2D: rebotes y splash toman el máximo; la penetración suma con tope 0.85.
	golpe.rebotes = math.floor((ef.chainCount or 0) + 0.5)
	golpe.rangoRebote = ef.chainRange or 0
	golpe.factorRebote = ef.chainFactor or 0
	golpe.radioSplash = math.max(golpe.radioSplash or 0, ef.splashRadius or 0)
	golpe.factorSplash = math.max(golpe.factorSplash or 0, ef.splashFactor or 0)
	golpe.penetracion = math.min(0.85, (golpe.penetracion or 0) + (ef.armorPenetration or 0))
	return golpe
end

-- onAttack del 2D. Cuenta el ataque y devuelve golpes extra { enemigo, golpe } (Sabotaje Widow).
-- enemigos: { { e, x, y } } en píxeles; heroe: { x, y, alcance, ve } con ve = detecta sigilo.
function Kits.alAtacar(kit, config, stats, nivel: number, objetivo, heroe, enemigos)
	kit.ataques += 1
	if kit.heroe ~= "black_widow" or kit.ataques % 4 ~= 0 then
		return {}
	end
	local function valido(c)
		return c.e.vida > 0 and (not Combate.sigilo(c.e) or heroe.ve) and math.sqrt((c.x - heroe.x) ^ 2 + (c.y - heroe.y) ^ 2) <= heroe.alcance
	end
	local blanco
	for _, c in enemigos do
		if c.e == objetivo then
			blanco = c
		end
	end
	if not blanco or not valido(blanco) then
		return {}
	end
	local cercanos = {}
	for _, c in enemigos do
		if c ~= blanco and valido(c) and math.sqrt((c.x - blanco.x) ^ 2 + (c.y - blanco.y) ^ 2) <= 125 then
			table.insert(cercanos, c)
		end
	end
	-- Orden estable: primero los apoyos (sort de JS es estable; table.sort no, así que se separa).
	local apoyos, resto = {}, {}
	for _, c in cercanos do
		table.insert(if Combate.esApoyo(c.e) then apoyos else resto, c)
	end
	-- sabotaje = true: el servidor inhibe curas, invocaciones y órdenes de los apoyos alcanzados.
	local golpes = { { enemigo = objetivo, sabotaje = true, golpe = { tipo = config.category, dano = stats.damage * 0.55 * Kits.escalaPoder(nivel) } } }
	for _, c in table.move(resto, 1, #resto, #apoyos + 1, apoyos) do
		if #golpes >= 4 then
			break
		end
		table.insert(golpes, { enemigo = c.e, sabotaje = true, golpe = { tipo = config.category, dano = stats.damage * 0.55 * Kits.escalaPoder(nivel) } })
	end
	return golpes
end

-- update del kit. Korg: pisotón cada 5 s si hay 3+ terrestres a 65 px dentro de su alcance.
-- enemigos: { { e, x, y, avance } }. Devuelve { { enemigo, golpe, efecto } } o nil.
function Kits.actualizar(kit, dt: number, config, stats, heroe, enemigos)
	kit.enfriamiento = math.max(0, kit.enfriamiento - dt)
	if kit.heroe ~= "korg" or kit.enfriamiento > 0 then
		return nil
	end
	local victimas = {}
	for _, c in enemigos do
		local cubierto = c.e.vida > 0
			and (not Combate.sigilo(c.e) or heroe.ve)
			and Despliegue.enAlcance(heroe.x, heroe.y, c.x, c.y, stats.range, config.rangePattern)
		if cubierto and not c.e.config.flying and math.sqrt((c.x - heroe.x) ^ 2 + (c.y - heroe.y) ^ 2) <= 65 then
			table.insert(victimas, c)
		end
	end
	if #victimas < 3 then
		return nil
	end
	table.sort(victimas, function(a, b)
		return a.avance > b.avance
	end)
	kit.enfriamiento = 5
	local golpes = {}
	for i = 1, math.min(5, #victimas) do
		table.insert(golpes, {
			enemigo = victimas[i].e,
			golpe = { tipo = config.category, dano = stats.damage * 0.5 },
			efecto = { type = "slow", duration = 1.5, power = 0.35 },
		})
	end
	return golpes
end

return Kits
