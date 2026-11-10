-- Conductas de enemigos, portadas de EnemyBehaviorSystem.js del 2D: curas, invocaciones, órdenes,
-- recarga de escudos, ráfagas, fases de sigilo, afijos regenerador/inestable, fases de jefe y sabotaje.
-- Módulo puro: el mundo se toca a través de `entorno`:
--   entorno.aliados(e, radio) → enemigos vivos a `radio` px de e (sin incluirlo)
--   entorno.invocar(config, origen) · entorno.aviso(texto) · entorno.aturdirHeroes(segundos)
local Combate = require(script.Parent.Combate)

local Conductas = {}

Conductas.SABOTAJE_SEGUNDOS = 2

local function arquetipo(e)
	return e.config.archetype or "soldier"
end

local function esComandante(e)
	return arquetipo(e) == "commander" or e.config.affix == "commander"
end

function Conductas.preparar(e)
	e.conducta = {
		transcurrido = 0,
		accion = e.config.behaviorCooldown or 4,
		invocaciones = e.config.summonLimit or 0,
		velocidadFase = 1,
		fasesActivas = {},
		fasePendiente = nil,
		aviso = 0,
		sabotaje = 0,
		bloqueoSabotaje = 0,
	}
end

-- applyStatus("sabotage") + applySabotage del 2D. Sólo apoyos, invocadores y comandantes no jefes.
function Conductas.sabotear(e, duracion: number): boolean
	local c = e.conducta
	if e.vida <= 0 or not Combate.esApoyo(e) or c.bloqueoSabotaje > 1e-9 then
		return false
	end
	local especifica = (e.config.statusResistances or {}).sabotage or 0
	local ajustada = math.min(Conductas.SABOTAJE_SEGUNDOS, duracion) * math.max(0.2, 1 - (e.config.statusResistance or 0) - especifica)
	if ajustada <= 0 then
		return false
	end
	c.sabotaje = math.min(Conductas.SABOTAJE_SEGUNDOS, ajustada)
	c.bloqueoSabotaje = c.sabotaje + 3
	return true
end

local function activarFase(e, fase, entorno)
	local c = e.conducta
	c.fasePendiente = nil
	if fase.barrier then
		local b = math.floor(e.vidaMax * fase.barrier + 0.5)
		e.barreraMax = math.max(e.barreraMax, b)
		e.barrera += b
	end
	if fase.heal then
		e.vida = math.min(e.vidaMax, e.vida + e.vidaMax * fase.heal)
	end
	if fase.armor then
		e.config.armor = math.min(0.8, (e.config.armor or 0) + fase.armor)
	end
	if fase.speed then
		c.velocidadFase = fase.speed
	end
	if fase.stealth then
		e.sigiloTemporal = fase.stealth
	end
	if fase.summonId then
		for _ = 1, fase.summonCount or 1 do
			entorno.invocar(fase.summonId, e, 1)
		end
	end
	if fase.stunHeroes then
		entorno.aturdirHeroes(fase.stunDuration or fase.heroStunDuration or 4)
	end
	entorno.aviso(`{e.config.name}: {fase.name}`)
end

local function fasesDeJefe(e, dt, entorno)
	local c = e.conducta
	if c.fasePendiente then
		c.aviso -= dt
		if c.aviso <= 0 then
			activarFase(e, c.fasePendiente, entorno)
		end
		return
	end
	local proporcion = e.vida / e.vidaMax
	for i, fase in e.config.phases or {} do
		if proporcion <= fase.threshold and not c.fasesActivas[i] then
			c.fasesActivas[i] = true
			c.fasePendiente = fase
			c.aviso = fase.telegraph or 1.25
			entorno.aviso(`{e.config.name} prepara {fase.name}`)
			return
		end
	end
end

-- update del 2D. Devuelve el multiplicador de velocidad de la conducta (getSpeedMultiplier).
function Conductas.actualizar(e, dt: number, entorno): number
	local c = e.conducta
	local tipo = arquetipo(e)
	c.transcurrido += dt
	-- Un "phaser" con afijo comandante pierde las órdenes, no su cambio de fase.
	local bloqueado = if tipo == "phaser" then 0 else math.min(dt, c.sabotaje)
	c.sabotaje = math.max(0, c.sabotaje - dt)
	c.bloqueoSabotaje = math.max(0, c.bloqueoSabotaje - dt)
	c.accion -= dt - bloqueado
	e.recargaBarrera = math.max(0, e.recargaBarrera - dt)

	if e.config.affix == "regenerator" and e.vida < e.vidaMax then
		e.vida = math.min(e.vidaMax, e.vida + e.vidaMax * 0.012 * dt)
	end
	if e.sigiloTemporal > 0 then
		e.sigiloTemporal = math.max(0, e.sigiloTemporal - dt)
	end
	if tipo == "shield" and e.barrera == 0 and e.recargaBarrera == 0 then
		e.barrera = e.barreraMax
	end

	if c.sabotaje <= 0 then
		if tipo == "support" and c.accion <= 0 then
			for _, a in entorno.aliados(e, 120) do
				if a.vida < a.vidaMax then
					a.vida = math.min(a.vidaMax, a.vida + a.vidaMax * (e.config.healPower or 0.06))
				end
			end
			c.accion = e.config.behaviorCooldown or 4
		end
		if tipo == "summoner" and c.accion <= 0 then
			if c.invocaciones <= 0 then
				c.accion = math.huge
			else
				if entorno.invocar(e.config.summonId, e, 0.7) then
					c.invocaciones -= 1
				end
				c.accion = e.config.behaviorCooldown or 7
			end
		end
		if esComandante(e) and c.accion <= 0 then
			for _, a in entorno.aliados(e, 145) do
				Combate.aplicarEstado(a, { type = "haste", duration = 2.5, power = e.config.commandPower or 0.2 })
			end
			c.accion = e.config.behaviorCooldown or 5
		end
	end
	if tipo == "phaser" and c.accion <= 0 then
		e.sigiloTemporal = 1.4
		c.accion = e.config.behaviorCooldown or 6
	end
	if e.config.isBoss or e.config.isMiniBoss then
		fasesDeJefe(e, dt, entorno)
	end

	local rafaga = if tipo == "runner" and c.transcurrido % 5 < 1.4 then 1.45 else 1
	local fase = if tipo == "phaser" and e.sigiloTemporal > 0 then 1.35 else 1
	local inestable = if e.config.affix == "unstable" and e.vida / e.vidaMax < 0.35 then 1.45 else 1
	return rafaga * fase * inestable * c.velocidadFase
end

return Conductas
