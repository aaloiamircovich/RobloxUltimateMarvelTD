-- Perfil persistente por jugador (DataStore). Parte del estado de ProgressionManager del 2D (credits,
-- mapProgress, shop, modeRecords, ownedItemIds, equippedItems) más el sistema de unidades propio
-- (docs/INVOCACIONES.md): gems, cores, units, nextUnitUid y squad. unlockedHeroIds se deriva de units.
local DataStoreService = game:GetService("DataStoreService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Personajes = require(Shared.Personajes)
local Unidades = require(Shared.Unidades)
local Cuenta = require(Shared.Cuenta)
local Temporada = require(Shared.Temporada)
local Evento = require(Shared.Evento)
local Raid = require(Shared.Raid)
local Rasgos = require(Shared.Rasgos)
local Mascotas = require(Shared.Mascotas)
local Estilo = require(Shared.Estilo)
local Preferencias = require(Shared.Preferencias)
local Recompensas = require(Shared.Recompensas)
local items = require(Shared.Data.items)

local Perfiles = {}

Perfiles.VERSION = 2
Perfiles.CREDITOS_INICIALES = 1200 -- createDefaultState del 2D
Perfiles.GEMAS_INICIALES = 500
local MAX_OLEADAS = 100

local almacen = nil -- se pide al primer uso: falla en Studio sin acceso a API
local perfiles = {} -- [Player] = { datos, guardable, sucio }

local function entero(v, minimo, maximo, defecto)
	local n = tonumber(v)
	if not n or n ~= n then
		return defecto
	end
	return math.clamp(math.floor(n), minimo, maximo)
end

-- Frontera de confianza: lo que viene del DataStore puede estar viejo o roto.
function Perfiles.normalizar(crudo)
	local datos = if type(crudo) == "table" then crudo else {}
	local rec = Recompensas.normalizar(datos) -- premio diario, códigos, logros y contadores (docs/RECOMPENSAS.md)
	local p = {
		diario = rec.diario,
		codigos = rec.codigos,
		logros = rec.logros,
		estadisticas = rec.estadisticas,
		version = Perfiles.VERSION,
		credits = Perfiles.CREDITOS_INICIALES,
		gems = entero(datos.gems, 0, 1e9, Perfiles.GEMAS_INICIALES),
		cores = entero(datos.cores, 0, 1e6, 0),
		level = entero(datos.level, 1, 10000, 1), -- nivel de cuenta
		xp = entero(datos.xp, 0, 1e9, 0),
		units = {},
		nextUnitUid = 1,
		squad = {},
		mapProgress = {},
		acts = {}, -- [mapa] = { normal = último acto ganado, pesadilla = ídem en Pesadilla } (docs/PARTIDA.md)
		unlockedHeroIds = {},
		shop = { heroPity = 0, limitadoPity = 0 }, -- limitadoPity: Banner 2 (Banners.luau)
		modeRecords = { survival = { bestWave = 0, bestScore = 0 } },
		ownedItemIds = {},
		equippedItems = {},
		temporada = Temporada.normalizar(datos.temporada), -- misiones y pase (docs/TEMPORADA.md)
		evento = Evento.normalizar(datos.evento), -- desafío semanal (docs/EVENTO.md)
		raid = Raid.normalizar(datos.raid), -- llaves, misiones y fragmentos de raid (docs/RAIDS.md)
		fichasRasgo = entero(datos.fichasRasgo, 0, 1e6, 0), -- docs/RASGOS.md
		cristales = entero(datos.cristales, 0, 1e6, 0),
		fichasRaid = entero(datos.fichasRaid, 0, 1e6, 0), -- Banner 2 (docs/INVOCACIONES.md)
		pityRasgo = entero(datos.pityRasgo, 0, 1000, 0),
		mascotas = Mascotas.normalizar(datos.mascotas), -- docs/MASCOTAS.md
		estilo = Estilo.normalizar(datos.estilo), -- monturas y bailes (docs/ESTILO.md)
		ajustes = Preferencias.normalizarAjustes(datos.ajustes), -- docs/TUTORIAL.md
		-- Las cuentas que ya jugaban antes del tutorial no lo ven (ni cobran su premio).
		tutorial = Preferencias.normalizarTutorial(datos.tutorial or (if type(datos.units) == "table" and next(datos.units) ~= nil then { terminado = true, premiado = true, paso = Preferencias.PASOS } else nil)),
	}
	local c = tonumber(datos.credits)
	if c and c == c and c >= 0 and c < math.huge then
		p.credits = math.floor(c)
	end
	if type(datos.mapProgress) == "table" then
		for id, v in datos.mapProgress do
			if type(id) == "string" and type(v) == "table" then
				local mejor = math.clamp(math.floor(tonumber(v.bestWave) or 0), 0, MAX_OLEADAS)
				p.mapProgress[id] = { bestWave = mejor, stars = math.max(mejor, math.clamp(math.floor(tonumber(v.stars) or 0), 0, MAX_OLEADAS)) }
			end
		end
	end
	-- Unidades: personaje existente, uid único, nivel 1–50, hasta 100.
	if type(datos.units) == "table" then
		local usados = {}
		for _, u in datos.units do
			local uid = type(u) == "table" and entero(u.uid, 1, 1e9, nil)
			if uid and not usados[uid] and type(u.heroId) == "string" and Personajes.de(u.heroId) and #p.units < Unidades.MAX_INVENTARIO then
				usados[uid] = true
				local nueva = { uid = uid, heroId = u.heroId, level = entero(u.level, 1, Unidades.NIVEL_MAXIMO, 1), xp = entero(u.xp, 0, 1e9, 0) }
				Rasgos.normalizarUnidad(u, nueva) -- rasgo y grados (docs/RASGOS.md)
				table.insert(p.units, nueva)
				p.nextUnitUid = math.max(p.nextUnitUid, uid + 1)
			end
		end
		p.nextUnitUid = math.max(p.nextUnitUid, entero(datos.nextUnitUid, 1, 1e9, 1))
		if type(datos.squad) == "table" then
			for _, uid in datos.squad do
				if type(uid) == "number" and Unidades.buscar(p, uid) and not table.find(p.squad, uid) and #p.squad < Unidades.MAX_ESCUADRON then
					table.insert(p.squad, uid)
				end
			end
		end
	elseif type(datos.unlockedHeroIds) == "table" then
		-- Perfil de la versión 1 (héroes sin repetir): una unidad de nivel 1 por héroe; el escuadrón se conserva.
		local equipo = if type(datos.activeTeamIds) == "table" then datos.activeTeamIds else {}
		for _, id in datos.unlockedHeroIds do
			if type(id) == "string" and Personajes.de(id) and not table.find(p.unlockedHeroIds, id) and #p.units < Unidades.MAX_INVENTARIO then
				table.insert(p.unlockedHeroIds, id)
				local u = { uid = p.nextUnitUid, heroId = id, level = 1, xp = 0 }
				p.nextUnitUid += 1
				table.insert(p.units, u)
				if table.find(equipo, id) and #p.squad < Unidades.MAX_ESCUADRON then
					table.insert(p.squad, u.uid)
				end
			end
		end
	end
	-- El escuadrón no puede pasar de las casillas abiertas por el nivel de cuenta.
	while #p.squad > Cuenta.casillas(p.level) do
		table.remove(p.squad)
	end
	if #p.squad == 0 and #p.units > 0 then
		p.squad = { p.units[1].uid }
	end
	Unidades.sincronizar(p)
	-- Objetos: cada id existe una sola vez, en el inventario o equipado en un héroe desbloqueado.
	local vistos = {}
	if type(datos.equippedItems) == "table" then
		for heroeId, ranuras in datos.equippedItems do
			if type(heroeId) == "string" and table.find(p.unlockedHeroIds, heroeId) and type(ranuras) == "table" then
				for _, id in ranuras do
					if type(id) == "string" and items[id] and not vistos[id] then
						vistos[id] = true
						p.equippedItems[heroeId] = { [items[id].slot] = id }
						break -- un objeto por héroe, como el 2D
					end
				end
			end
		end
	end
	if type(datos.ownedItemIds) == "table" then
		for _, id in datos.ownedItemIds do
			if type(id) == "string" and items[id] and not vistos[id] then
				vistos[id] = true
				table.insert(p.ownedItemIds, id)
			end
		end
	end
	if type(datos.acts) == "table" then
		for id, v in datos.acts do
			if type(id) == "string" and type(v) == "table" then
				p.acts[id] = { normal = entero(v.normal, 0, 5, 0), pesadilla = entero(v.pesadilla, 0, 5, 0) }
			end
		end
	end
	local r = type(datos.modeRecords) == "table" and datos.modeRecords.survival
	if type(r) == "table" then
		p.modeRecords.survival.bestWave = math.max(0, math.floor(tonumber(r.bestWave) or 0))
		p.modeRecords.survival.bestScore = math.max(0, math.floor(tonumber(r.bestScore) or 0))
	end
	if type(datos.shop) == "table" then
		p.shop.heroPity = entero(datos.shop.heroPity, 0, 1e6, 0)
		p.shop.limitadoPity = entero(datos.shop.limitadoPity, 0, 1000, 0)
	end
	return p
end

local function clave(jugador: Player)
	return "jugador_" .. jugador.UserId
end

local function conReintentos(f)
	local ok, res
	for intento = 1, 3 do
		ok, res = pcall(f)
		if ok then
			return true, res
		end
		task.wait(intento)
	end
	return false, res
end

-- Guardado con ProfileStore (src/server/ProfileStore.luau, Apache 2.0, licencias/): bloqueo de sesión, así el
-- mismo jugador en dos servidores (p. ej. al teletransportarse a una partida) no pisa ni duplica sus datos.
-- Almacén v2; la primera vez se copia lo que había en v1 (que queda intacto como respaldo).
local ALMACEN_NUEVO, ALMACEN_VIEJO = "PerfilesUMTD_v2", "PerfilesUMTD_v1"
local tienda -- se crea al primer uso: requerir ProfileStore arranca tareas de DataStore (no en las pruebas)

-- Lee el perfil del almacén viejo para migrarlo. Devuelve (ok, datos o nil).
local function leerViejo(jugador: Player)
	return conReintentos(function()
		almacen = almacen or DataStoreService:GetDataStore(ALMACEN_VIEJO)
		return almacen:GetAsync(clave(jugador))
	end)
end

-- Carga el perfil y toma la sesión. Si no se puede, el jugador juega con un perfil nuevo que NO se guarda,
-- para no pisar sus datos reales. Devuelve el perfil y un aviso para mostrar, si corresponde.
function Perfiles.cargar(jugador: Player): ({ any }, string?)
	local ProfileStore = require(script.Parent:WaitForChild("ProfileStore"))
	tienda = tienda or ProfileStore.New(ALMACEN_NUEVO, {})
	local perfil = tienda:StartSessionAsync(clave(jugador), {
		Cancel = function()
			return jugador.Parent == nil
		end,
	})
	if not perfil then
		local entrada = { datos = Perfiles.normalizar(nil), guardable = false, sucio = false }
		perfiles[jugador] = entrada
		warn(`[UMTD] No se pudo abrir la sesión del perfil de {jugador.Name}`)
		return entrada.datos, "No se pudo cargar tu progreso: esta sesión no se guardará"
	end
	if jugador.Parent == nil then
		perfil:EndSession()
		return Perfiles.normalizar(nil), nil
	end
	perfil:AddUserId(jugador.UserId)
	-- Primera vez en v2: traer los datos de v1. Si v1 no responde, no se arranca de cero (se perdería todo al guardar).
	local crudo = perfil.Data
	if next(crudo) == nil then
		local ok, viejo = leerViejo(jugador)
		if not ok then
			perfil:EndSession()
			local entrada = { datos = Perfiles.normalizar(nil), guardable = false, sucio = false }
			perfiles[jugador] = entrada
			return entrada.datos, "No se pudo cargar tu progreso: esta sesión no se guardará"
		end
		crudo = viejo
	end
	perfil.Data = Perfiles.normalizar(crudo)
	local entrada = { datos = perfil.Data, guardable = true, sucio = false, sesion = perfil }
	perfiles[jugador] = entrada
	-- Si otro servidor se queda con la sesión, este deja de guardar y saca al jugador.
	perfil.OnSessionEnd:Connect(function()
		if perfiles[jugador] == entrada then
			perfiles[jugador] = nil
		end
		if jugador.Parent then
			jugador:Kick("Tu partida se abrió en otro servidor. Volvé a entrar.")
		end
	end)
	return entrada.datos, nil
end

function Perfiles.de(jugador: Player)
	local e = perfiles[jugador]
	return e and e.datos
end

function Perfiles.marcar(jugador: Player)
	local e = perfiles[jugador]
	if e then
		e.sucio = true
	end
end

-- ProfileStore autoguarda cada 5 min y al cerrar; esto adelanta el guardado cuando hubo cambios (fin de partida,
-- compras) para perder lo menos posible si el servidor se cae.
function Perfiles.guardar(jugador: Player)
	local e = perfiles[jugador]
	if not e or not e.guardable or not e.sucio or not e.sesion or not e.sesion:IsActive() then
		return
	end
	e.sucio = false
	e.sesion:Save()
end

-- Al salir: último guardado y se libera la sesión para que otro servidor pueda tomarla.
function Perfiles.soltar(jugador: Player)
	local e = perfiles[jugador]
	perfiles[jugador] = nil
	if e and e.sesion and e.sesion:IsActive() then
		e.sesion:EndSession()
	end
end

function Perfiles.guardarTodos()
	for jugador in perfiles do
		task.spawn(Perfiles.guardar, jugador)
	end
end

return Perfiles
