-- Daño y estados de enemigos, portados de Enemy.js, CombatSystem.applyImpact, PoisonStatus.js y
-- StatusDamage.js del 2D. Módulo puro: opera sobre la tabla del enemigo, sin tocar el mundo.
--
-- Enemigo: { config, vida, vidaMax, barrera, barreraMax, recargaBarrera, sigiloTemporal,
--           estados = { slow?, armorBreak?, haste?, poison = { capas } } }
local Combate = {}

local MAX_CAPAS_VENENO, TIC_VENENO, EPS = 12, 0.5, 1e-10

function Combate.nuevoEnemigo(config)
	local barrera = math.floor(config.hp * (config.barrierRatio or 0) + 0.5)
	return {
		config = config,
		vida = config.hp,
		vidaMax = config.hp,
		barrera = barrera,
		barreraMax = barrera,
		recargaBarrera = 0,
		sigiloTemporal = 0,
		estados = { poison = {} },
	}
end

-- Sigilo efectivo: el propio del enemigo o el temporal de una fase (stealth del 2D).
function Combate.sigilo(e): boolean
	return e.config.stealth == true or e.sigiloTemporal > 0
end

-- takeDamage del 2D. op: { tipo, penetracion, ignorarArmadura, fraccional }. Devuelve daño hecho y si murió.
function Combate.recibir(e, cantidad: number, op): (number, boolean)
	op = op or {}
	local romper = e.estados.armorBreak and e.estados.armorBreak.power or 0
	local base = e.config.armor or 0
	if base > 1 then
		base /= 100
	end
	local pen = math.clamp(op.penetracion or 0, 0, 1)
	local armadura = if op.ignorarArmadura then 0 else math.clamp(base - romper, 0, 0.85) * (1 - pen)
	local resistencia = math.clamp(((e.config.resistances or {})[op.tipo or ""] or 0), 0, 0.8)
	local final = math.max(if op.fraccional then 0 else 1, cantidad * (1 - resistencia) * (1 - armadura))
	local absorbido = math.min(e.barrera, final)
	e.barrera -= absorbido
	if absorbido > 0 then
		e.recargaBarrera = 5 -- absorbDamage del 2D
	end
	local aplicado = math.min(e.vida, final - absorbido)
	e.vida -= aplicado
	if e.vida <= 0 then
		e.vida = 0
	end
	return aplicado + absorbido, e.vida <= 0
end

-- applyDamage del 2D: tabla de tipos × factor, después recibir().
function Combate.danar(e, golpe, factor: number, tablaTipos): (number, boolean)
	local mult = (tablaTipos[golpe.tipo] or {})[e.config.category] or 1
	return Combate.recibir(e, golpe.dano * factor * mult, { tipo = golpe.tipo, penetracion = golpe.penetracion })
end

local function duracionAjustada(e, tipo, duracion)
	local especifica = (e.config.statusResistances or {})[tipo] or 0
	return duracion * math.max(0.2, 1 - (e.config.statusResistance or 0) - especifica)
end

-- applyStatus del 2D para slow, armorBreak y poison.
-- shortcut: "sabotage" (inhibir curas e invocaciones) espera a que los enemigos tengan esas conductas.
function Combate.aplicarEstado(e, efecto): boolean
	local tipo = efecto.type
	if e.vida <= 0 then
		return false
	end
	if tipo == "slow" and e.config.immuneToSlow then
		return false
	end
	local duracion = duracionAjustada(e, tipo, efecto.duration or 1)
	if tipo == "poison" then
		local dps = e.vidaMax * (efecto.power or 0.5) -- base "maxHealth" de resolveStatusDamage
		local capas = e.estados.poison
		local capa = { dps = dps, duracion = duracion, tic = 0 }
		if #capas < MAX_CAPAS_VENENO then
			table.insert(capas, capa)
			return true
		end
		local debil = 1
		for i, c in capas do
			if c.dps < capas[debil].dps or (c.dps == capas[debil].dps and c.duracion < capas[debil].duracion) then
				debil = i
			end
		end
		if dps <= capas[debil].dps then
			-- En el tope, un golpe igual sólo renueva su propia contribución (la capa equivalente más corta).
			capas[debil].duracion = math.max(capas[debil].duracion, duracion)
			return true
		end
		if capas[debil].tic > 0 then
			Combate.recibir(e, capas[debil].dps * capas[debil].tic, { ignorarArmadura = true, fraccional = true })
		end
		capas[debil] = capa
		return true
	end
	local actual = e.estados[tipo]
	if actual then
		actual.duration = math.max(actual.duration, duracion)
		actual.power = math.max(actual.power, efecto.power or 0.5)
	else
		e.estados[tipo] = { duration = duracion, power = efecto.power or 0.5 }
	end
	return true
end

-- updateDebuffs del 2D: avanza estados y veneno. Devuelve el multiplicador de velocidad y si murió por veneno.
function Combate.actualizar(e, dt: number): (number, boolean)
	local capas = e.estados.poison
	local resto = dt
	-- Igual que updatePoisonStacks: en orden cronológico para que un cuadro largo no adelante el tic que mata.
	while resto > EPS and #capas > 0 and e.vida > 0 do
		local paso = resto
		for _, c in capas do
			paso = math.min(paso, math.max(0, math.min(c.duracion, TIC_VENENO - c.tic)))
		end
		for _, c in capas do
			c.duracion -= paso
			c.tic += paso
		end
		resto -= paso
		for _, c in capas do
			if c.tic >= TIC_VENENO - EPS or c.duracion <= EPS then
				if c.tic > 0 then
					Combate.recibir(e, c.dps * c.tic, { ignorarArmadura = true, fraccional = true })
				end
				c.tic = 0
				if e.vida <= 0 then
					break
				end
			end
		end
		for i = #capas, 1, -1 do
			if capas[i].duracion <= EPS then
				table.remove(capas, i)
			end
		end
	end
	for _, tipo in { "slow", "armorBreak", "haste" } do
		local s = e.estados[tipo]
		if s then
			s.duration -= dt
			if s.duration <= 0 then
				e.estados[tipo] = nil
			end
		end
	end
	local lento = e.estados.slow and e.estados.slow.power or 0
	local mult = if lento > 0 then math.max(0.2, 1 - lento) else 1
	if e.estados.haste then
		mult *= 1 + e.estados.haste.power
	end
	return mult, e.vida <= 0
end

-- applyImpact del 2D: daño principal, efectos (con probabilidad) y splash sin efectos.
-- golpe: { tipo, dano, penetracion, efectos, radioSplash, factorSplash }; cercanos(radio) → enemigos.
-- Devuelve la lista de enemigos que murieron.
function Combate.impacto(objetivo, golpe, tablaTipos, azar: () -> number, cercanos)
	local muertos = {}
	local _, murio = Combate.danar(objetivo, golpe, 1, tablaTipos)
	if murio then
		table.insert(muertos, objetivo)
	else
		for _, ef in golpe.efectos or {} do
			if azar() < (ef.chance or 1) then
				Combate.aplicarEstado(objetivo, ef)
			end
		end
	end
	if (golpe.radioSplash or 0) > 0 then
		for _, otro in cercanos(golpe.radioSplash) do
			if otro ~= objetivo and otro.vida > 0 then
				local _, m = Combate.danar(otro, golpe, golpe.factorSplash or 0.5, tablaTipos)
				if m then
					table.insert(muertos, otro)
				end
			end
		end
	end
	return muertos
end

-- isSabotageTarget del 2D: apoyos, invocadores y comandantes que no sean jefes.
function Combate.esApoyo(e): boolean
	local c = e.config
	if c.isBoss or c.isFinalBoss or c.isMiniBoss then
		return false
	end
	return c.archetype == "support" or c.archetype == "summoner" or c.archetype == "commander" or c.affix == "commander"
end

return Combate
