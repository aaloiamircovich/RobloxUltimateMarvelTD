-- Oleadas de campaña, portadas de WaveManager.js + EncounterDirector.js + Random.js del 2D
-- (dificultad normal, modo campaña, rama "safe"). Módulo puro: se verifica contra el 2D.
local Oleadas = {}

Oleadas.MAX_OLEADAS = 100
local INTERVALO_MINI_JEFE = 25

--------------------------------------------------------------------------------
-- RandomSource (mulberry32 con semilla FNV-1a), idéntico al 2D.
--------------------------------------------------------------------------------
local DOS32 = 4294967296

local function imul(a: number, b: number): number
	local al, ah = a % 65536, a // 65536
	local bl, bh = b % 65536, b // 65536
	return (al * bl + ((ah * bl + al * bh) % 65536) * 65536) % DOS32
end

local Azar = {}
Azar.__index = Azar

function Azar.nuevo(semilla: string)
	local hash = 2166136261
	for i = 1, #semilla do
		hash = imul(bit32.bxor(hash, string.byte(semilla, i)), 16777619)
	end
	return setmetatable({ estado = if hash == 0 then 1 else hash }, Azar)
end

function Azar:siguiente(): number
	self.estado += 0x6d2b79f5
	local v = self.estado % DOS32
	v = imul(bit32.bxor(v, bit32.rshift(v, 15)), bit32.bor(v, 1))
	v = bit32.bxor(v, (v + imul(bit32.bxor(v, bit32.rshift(v, 7)), bit32.bor(v, 61))) % DOS32)
	return bit32.bxor(v, bit32.rshift(v, 14)) / DOS32
end

function Azar:elegir(lista)
	if #lista == 0 then
		return nil
	end
	return lista[math.floor(self:siguiente() * #lista) + 1]
end
Oleadas.Azar = Azar

--------------------------------------------------------------------------------
-- Tablas del 2D
--------------------------------------------------------------------------------
local FACCIONES = {
	["new-york"] = { plantel = { { "hydra_soldier", 1 }, { "aim_scientist", 1 }, { "chitauri_warrior", 6 }, { "chitauri_skimmer", 12 }, { "chitauri_phaser", 18 } }, jefes = { "loki" } },
	avengers = { plantel = { { "ultron_drone", 1 }, { "doombot", 1 }, { "aim_scientist", 4 }, { "chitauri_warrior", 8 }, { "skrull_infiltrator", 14 }, { "sentinel", 20 } }, jefes = { "ultron_prime", "magneto" } },
	wakanda = { plantel = { { "outrider", 1 }, { "mercenary_raider", 1 }, { "chitauri_warrior", 4 }, { "sakaaran_soldier", 8 }, { "symbiote_spawn", 14 }, { "hellfire_guard", 20 } }, jefes = { "killmonger", "loki" } },
	sanctum = { plantel = { { "dark_elf", 1 }, { "hand_ninja", 1 }, { "frost_giant_scout", 5 }, { "symbiote_spawn", 10 }, { "hellfire_guard", 16 }, { "skrull_infiltrator", 22 } }, jefes = { "dormammu", "loki" } },
	["x-mansion"] = { plantel = { { "sentinel", 1 }, { "brotherhood_mutant", 1 }, { "mercenary_raider", 5 }, { "hellfire_guard", 10 }, { "skrull_infiltrator", 16 }, { "doombot", 22 } }, jefes = { "magneto", "apocalypse" } },
	knowhere = { plantel = { { "chitauri_warrior", 1 }, { "chitauri_skimmer", 1 }, { "kree_sentry", 5 }, { "chitauri_phaser", 9 }, { "kree_commander", 14 }, { "black_order_hunter", 19 }, { "black_order_magus", 24 } }, jefes = { "kang", "galactus" } },
	latveria = { plantel = { { "doombot", 1 }, { "aim_scientist", 1 }, { "hydra_soldier", 5 }, { "ultron_drone", 10 }, { "hellfire_guard", 16 }, { "sentinel", 22 } }, jefes = { "doctor_doom", "red_skull" } },
	asgard = { plantel = { { "dark_elf_skirmisher", 1 }, { "frost_giant_scout", 1 }, { "asgardian_traitor", 5 }, { "dark_elf", 9 }, { "hellfire_guard", 15 }, { "mindless_one", 22 } }, jefes = { "malekith", "hela" } },
	["dark-dimension"] = { plantel = { { "dark_zealot", 1 }, { "dark_elf", 1 }, { "mindless_one", 5 }, { "hellfire_guard", 10 }, { "black_order_magus", 16 }, { "symbiote_spawn", 22 } }, jefes = { "baron_mordo", "dormammu" } },
	["savage-land"] = { plantel = { { "savage_raptor", 1 }, { "mercenary_raider", 1 }, { "savage_brute", 5 }, { "brotherhood_mutant", 10 }, { "sakaaran_soldier", 16 }, { "sentinel", 22 } }, jefes = { "sauron", "apocalypse" } },
	["the-raft"] = { plantel = { { "raft_escapee", 1 }, { "raft_saboteur", 1 }, { "mercenary_raider", 5 }, { "symbiote_spawn", 10 }, { "hellfire_guard", 16 }, { "ultron_drone", 22 } }, jefes = { "abomination", "green_goblin" } },
}

local MODIFICADORES = {
	{ id = "standard", nombre = "Patrulla estándar" },
	{ id = "rush", nombre = "Asalto relámpago", velocidad = 1.22 },
	{ id = "shielded", nombre = "Frente protegido", barrera = 0.16 },
	{ id = "covert", nombre = "Operación encubierta", sigilo = true },
	{ id = "swarm", nombre = "Enjambre", cantidad = 1.35, vida = 0.8 },
	{ id = "elite", nombre = "Escuadrón élite", vida = 1.25, armadura = 0.1 },
}

-- DIFFICULTIES del 2D; el 3D fija la dificultad según el mapa (getFixedDifficultyKey).
local DIFICULTADES = {
	easy = { hp = 0.85, speed = 0.95, count = 0.9, reward = 0.9 },
	normal = { hp = 1, speed = 1, count = 1, reward = 1 },
	hard = { hp = 1.3, speed = 1.1, count = 1.15, reward = 1.25 },
}

local function sinTildes(t: string): string
	return (string.lower(t or ""):gsub("á", "a"):gsub("é", "e"):gsub("í", "i"):gsub("ó", "o"):gsub("ú", "u"))
end

function Oleadas.dificultad(nivel): string
	local d = sinTildes(nivel.difficulty)
	return if d:find("facil") then "easy" elseif d:find("normal") or d:find("media") then "normal" else "hard"
end

local AFIJOS = { "regenerator", "reflector", "commander", "unstable", "hunter" }

local APERTURAS = {
	["new-york"] = {
		{ nombre = "Reconocimiento Hydra", enemigos = { { "hydra_soldier", 4 }, { "aim_scientist", 3 } } },
		{ nombre = "Tecnicos A.I.M.", enemigos = { { "aim_scientist", 4 }, { "hydra_soldier", 4 } } },
		{ nombre = "Escudos en la Quinta", enemigos = { { "hydra_soldier", 7 }, { "aim_scientist", 2 } } },
		{ nombre = "Brecha Chitauri", enemigos = { { "chitauri_warrior", 4 }, { "hydra_soldier", 4 }, { "aim_scientist", 2 } } },
		{ nombre = "Bloqueo de la Avenida Stark", enemigos = { { "hydra_soldier", 6 }, { "aim_scientist", 3 }, { "chitauri_warrior", 2 } }, elite = "hydra_soldier" },
	},
	avengers = {
		{ nombre = "Drones de intrusión", enemigos = { { "ultron_drone", 5 }, { "doombot", 2 } } },
		{ nombre = "Doombots de apoyo", enemigos = { { "doombot", 3 }, { "ultron_drone", 4 } } },
		{ nombre = "Red sincronizada", enemigos = { { "ultron_drone", 6 }, { "doombot", 3 } } },
		{ nombre = "Hackeo de hangar", enemigos = { { "doombot", 4 }, { "aim_scientist", 3 }, { "ultron_drone", 3 } } },
		{ nombre = "Nodo Prime menor", enemigos = { { "ultron_drone", 5 }, { "doombot", 4 } }, elite = "doombot" },
	},
}

local PENETRACION = { iron_man = true, vision = true, hawkeye = true, winter_soldier = true, cyclops = true, silver_surfer = true }

--------------------------------------------------------------------------------
-- Utilidades
--------------------------------------------------------------------------------
local function redondear(x: number): number
	return math.floor(x + 0.5) -- Math.round de JS
end

local function copiar(t)
	local c = table.clone(t)
	return c
end


function Oleadas.curvaVida(oleada: number, jefe: boolean?): number
	local w = math.max(1, math.floor(oleada))
	local curva = if w <= 30 then 0.84 + w * 0.045 elseif w <= 79 then 2.2 * 1.046 ^ (w - 30) else 20 * 1.072 ^ (w - 79)
	if not jefe then
		return curva
	end
	return curva * (if w <= 30 then 1.8 elseif w <= 79 then 1.4 + (w - 30) * 0.004 else 1.6 + (w - 79) * 0.006)
end

function Oleadas.factorNivel(dificultad: string, indiceNivel: number): number
	local d = string.lower(dificultad or ""):gsub("í", "i"):gsub("á", "a")
	local base = if d:find("extrema") then 1.42 elseif d:find("dificil") then 1.18 elseif d:find("normal") or d:find("media") then 1 else 0.92
	return base * (1 + math.max(0, indiceNivel) * 0.08)
end

-- getTeamCapabilities del 2D. equipo: lista de configs de héroes.
function Oleadas.capacidades(equipo)
	if #equipo == 0 then
		return { deteccion = true, penetracion = true }
	end
	local c = { deteccion = false, penetracion = false }
	for _, h in equipo do
		if h.canSeeStealth or ((h.teamMetrics and h.teamMetrics.detection) or 0) >= 4 then
			c.deteccion = true
		end
		if PENETRACION[h.id] then
			c.penetracion = true
		end
	end
	return c
end

local function inseguro(e, cap)
	return cap.deteccion == false and (e.stealth or e.archetype == "stealth" or e.archetype == "phaser")
end

local function aplicarAfijo(config, afijo)
	local n = copiar(config)
	n.affix = afijo
	n.threat = math.min(5, (config.threat or 1) + 1)
	n.reward = redondear((config.reward or 10) * 1.35)
	if afijo == "reflector" then
		n.barrierRatio = math.max(n.barrierRatio or 0, 0.2)
	elseif afijo == "commander" then
		n.commandPower = 0.18
	elseif afijo == "hunter" then
		n.stealth = true
		n.speed = redondear(n.speed * 1.12)
	end
	return n
end

local function crearElite(config, afijo, factorBotin)
	local e = copiar(config)
	e.id = config.id .. "_elite"
	e.name = config.name .. " Élite"
	e.hp = redondear(config.hp * 1.55)
	e.speed = math.max(32, redondear(config.speed * 0.92))
	e.reward = redondear((config.reward or 10) * 1.75 * factorBotin)
	e.armor = math.min(0.55, (config.armor or 0) + 0.08)
	e.isElite = true
	e.threat = math.min(5, (config.threat or 1) + 1)
	return aplicarAfijo(e, afijo)
end

--------------------------------------------------------------------------------
-- prepareNextWave
--------------------------------------------------------------------------------
-- datos: enemies.json ({ normal, bosses }); nivel: entrada de levels.json; equipo: configs de héroes.
-- modo: "campaign" (por defecto) o "survival" (Infinito: sin límite, sin aperturas ni jefe final).
-- Devuelve cola { { enemigo = config escalada, espera = segundos } } y el modificador.
function Oleadas.preparar(oleada: number, datos, nivel, indiceNivel: number, equipo, modo: string?)
	local supervivencia = modo == "survival"
	local maximo = if supervivencia then math.huge else Oleadas.MAX_OLEADAS
	if oleada > maximo then
		return nil
	end
	local function esFinal(w)
		return w == maximo
	end
	local function esMiniJefe(w)
		return w < maximo and w % INTERVALO_MINI_JEFE == 0
	end
	local function esJefe(w)
		return esFinal(w) or esMiniJefe(w)
	end
	local tema = nivel.theme and nivel.theme.id or "new-york"
	local faccion = FACCIONES[tema] or FACCIONES["new-york"]
	local cap = Oleadas.capacidades(equipo)
	local factorNivel = Oleadas.factorNivel(nivel.difficulty, indiceNivel)
	local dif = DIFICULTADES[Oleadas.dificultad(nivel)]

	local function pool()
		local p = {}
		for _, par in faccion.plantel do
			if oleada >= par[2] and datos.normal[par[1]] then
				table.insert(p, datos.normal[par[1]])
			end
		end
		return p
	end

	-- getOpeningScript: oleadas 1–5 que no sean de ramas (las de ramas son múltiplos de 4).
	local guion
	local hayRamas = oleada >= 4 and oleada % 4 == 0 and not esJefe(oleada)
	if not supervivencia and oleada <= 5 and not hayRamas then
		guion = (APERTURAS[tema] or {})[oleada]
		if not guion then
			local p1 = faccion.plantel[1][1]
			local p2 = (faccion.plantel[2] or faccion.plantel[1])[1]
			guion = {
				nombre = "Apertura " .. oleada,
				enemigos = { { p1, 4 + oleada }, { p2, 2 + oleada // 2 } },
				elite = if oleada == 5 then p1 else nil,
			}
		end
	end

	-- getWaveModifier + sanitizeModifier
	local mod
	if guion then
		mod = { id = "opening-" .. oleada, nombre = guion.nombre }
	elseif esFinal(oleada) then
		mod = { id = "final-boss", nombre = "Jefe final" }
	elseif esMiniJefe(oleada) then
		mod = { id = "mini-boss", nombre = "Mini boss" }
	else
		mod = MODIFICADORES[(oleada - 1) % #MODIFICADORES + 1]
	end
	if mod.id == "covert" and cap.deteccion == false then
		mod = { id = "standard", nombre = "Patrulla adaptada" }
	end

	local function escalar(config, mult, jefe)
		local m = if jefe then {} else mod
		local vidaOleada = if config.isFinalBoss
			then Oleadas.curvaVida(oleada, false) * 0.095
			else Oleadas.curvaVida(oleada, jefe or config.isBoss)
		local tope = 0.8
		if jefe or config.isBoss then
			tope = if config.isFinalBoss then 0.65 elseif oleada <= 25 then 0.34 elseif oleada <= 50 then 0.46 elseif oleada <= 75 then 0.56 else 0.62
		end
		local e = copiar(config)
		e.hp = redondear(config.hp * mult * vidaOleada * factorNivel * (m.vida or 1) * dif.hp)
		e.speed = redondear(config.speed * (m.velocidad or 1) * dif.speed)
		e.armor = math.min(tope, (config.armor or 0) + (m.armadura or 0))
		e.barrierRatio = math.max(config.barrierRatio or 0, m.barrera or 0)
		e.stealth = m.sigilo or config.stealth or false
		e.reward = redondear((config.reward or 10) * (if jefe then 1 else 1 + oleada * 0.02) * dif.reward)
		e.isBoss = jefe or config.isBoss or false
		return e
	end

	local cola = {}
	if guion then
		-- getScriptedOpeningWave
		local respaldo = faccion.plantel[1][1]
		local function seguro(id)
			local c = datos.normal[id]
			if c and not inseguro(c, cap) then
				return c
			end
			local f = datos.normal[respaldo]
			if f and not inseguro(f, cap) then
				return f
			end
			for _, e in pool() do
				if not inseguro(e, cap) then
					return e
				end
			end
			return nil
		end
		for _, par in guion.enemigos do
			local base = seguro(par[1])
			if base then
				for i = 1, math.max(1, redondear(par[2] * dif.count)) do
					table.insert(cola, {
						enemigo = escalar(base, 0.88 + oleada * 0.035, false),
						espera = if i == 1 and #cola == 0 then 0.2 else math.max(0.52, 1.08 - oleada * 0.04),
					})
				end
			end
		end
		if guion.elite then
			local base = seguro(guion.elite)
			if base then
				-- Igual que el 2D: el élite de apertura no se escala por oleada.
				table.insert(cola, { enemigo = crearElite(base, "commander", 1), espera = 1.15 })
			end
		end
	elseif esFinal(oleada) then
		table.insert(cola, { enemigo = escalar(datos.bosses.thanos_final, 1.25, true), espera = 0 })
	elseif esMiniJefe(oleada) then
		local indice = math.max(0, oleada // INTERVALO_MINI_JEFE - 1)
		local id = faccion.jefes[indice % #faccion.jefes + 1]
		local jefe = datos.bosses[id] or datos.bosses.loki
		local mult = if oleada <= 25 then 0.9 elseif oleada <= 50 then 1 elseif oleada <= 75 then 1.1 else 1.18 + (oleada - 75) * 0.004
		table.insert(cola, { enemigo = escalar(jefe, mult, true), espera = 0 })
	else
		-- EncounterDirector.compose con rama "safe"
		local amenaza = if hayRamas then 0.88 else 1
		local candidatos = {}
		for _, e in pool() do
			if not inseguro(e, cap) then
				table.insert(candidatos, e)
			end
		end
		if cap.penetracion == false then
			local sin = {}
			for _, e in candidatos do
				if e.archetype ~= "shield" and e.archetype ~= "tank" and (e.armor or 0) < 0.3 then
					table.insert(sin, e)
				end
			end
			if #sin > 0 then
				candidatos = sin
			end
		end
		if #candidatos == 0 then
			candidatos = { pool()[1] }
		end
		local azar = Azar.nuevo("campaign:" .. tema .. ":" .. oleada .. ":safe")
		local presupuesto = redondear((8 + oleada * 1.15) * amenaza)
		local encuentro = {}
		local i = 0
		while presupuesto > 0 and #encuentro < 36 do
			local alcanzables = {}
			for _, e in candidatos do
				if (e.threat or 1) <= presupuesto then
					table.insert(alcanzables, e)
				end
			end
			local elegido = azar:elegir(if #alcanzables > 0 then alcanzables else candidatos)
			if not elegido then
				break
			end
			local config = copiar(elegido)
			config.reward = redondear(elegido.reward or 10)
			if oleada >= 5 and (i + oleada) % 5 == 0 then
				config = aplicarAfijo(config, azar:elegir(AFIJOS))
			end
			table.insert(encuentro, config)
			presupuesto -= elegido.threat or 1
			i += 1
		end
		if oleada % 5 == 0 and #encuentro > 0 then
			local base = candidatos[1]
			for _, e in candidatos do
				if (e.threat or 1) > (base.threat or 1) then
					base = e
				end
			end
			table.insert(encuentro, crearElite(base, azar:elegir(AFIJOS), 1))
		end

		local ajustado = table.clone(encuentro)
		local factorCantidad = (mod.cantidad or 1) * dif.count
		if factorCantidad > 1 then
			for k = 1, redondear(#encuentro * (factorCantidad - 1)) do
				table.insert(ajustado, encuentro[k])
			end
		end
		while oleada <= 2 and #ajustado < 7 and #encuentro > 0 do
			table.insert(ajustado, encuentro[#ajustado % #encuentro + 1])
		end
		local intervalo = math.max(0.45, 1.45 - oleada / 65)
		for k, config in ajustado do
			table.insert(cola, { enemigo = escalar(config, 1 + oleada * 0.045, false), espera = if k == 1 then 0.2 else intervalo })
		end
	end
	return cola, mod
end

return Oleadas
