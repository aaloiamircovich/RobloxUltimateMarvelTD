-- Perfil persistente por jugador (DataStore). Parte del estado de ProgressionManager del 2D (credits,
-- mapProgress, shop, modeRecords, ownedItemIds, equippedItems) más el sistema de unidades propio
-- (docs/INVOCACIONES.md): gems, cores, units, nextUnitUid y squad. unlockedHeroIds se deriva de units.
local DataStoreService = game:GetService("DataStoreService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Personajes = require(Shared.Personajes)
local Unidades = require(Shared.Unidades)
local Cuenta = require(Shared.Cuenta)
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
	local p = {
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
		unlockedHeroIds = {},
		shop = { heroPity = 0 },
		modeRecords = { survival = { bestWave = 0, bestScore = 0 } },
		ownedItemIds = {},
		equippedItems = {},
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
				table.insert(p.units, { uid = uid, heroId = u.heroId, level = entero(u.level, 1, Unidades.NIVEL_MAXIMO, 1), xp = entero(u.xp, 0, 1e9, 0) })
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
	local r = type(datos.modeRecords) == "table" and datos.modeRecords.survival
	if type(r) == "table" then
		p.modeRecords.survival.bestWave = math.max(0, math.floor(tonumber(r.bestWave) or 0))
		p.modeRecords.survival.bestScore = math.max(0, math.floor(tonumber(r.bestScore) or 0))
	end
	if type(datos.shop) == "table" then
		p.shop.heroPity = entero(datos.shop.heroPity, 0, 1e6, 0)
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

-- Carga el perfil. Si el DataStore falla, el jugador juega con un perfil nuevo que NO se guarda,
-- para no pisar sus datos reales. Devuelve el perfil y un aviso para mostrar, si corresponde.
function Perfiles.cargar(jugador: Player): ({ any }, string?)
	local ok, res = conReintentos(function()
		almacen = almacen or DataStoreService:GetDataStore("PerfilesUMTD_v1")
		return almacen:GetAsync(clave(jugador))
	end)
	local entrada = { datos = Perfiles.normalizar(if ok then res else nil), guardable = ok, sucio = false }
	perfiles[jugador] = entrada
	if not ok then
		warn(`[UMTD] No se pudo cargar el perfil de {jugador.Name}: {res}`)
		return entrada.datos, "No se pudo cargar tu progreso: esta sesión no se guardará"
	end
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

-- shortcut: sin bloqueo de sesión; si el mismo jugador entra a dos servidores a la vez gana el último guardado.
function Perfiles.guardar(jugador: Player)
	local e = perfiles[jugador]
	if not e or not e.guardable or not e.sucio then
		return
	end
	local copia = table.clone(e.datos)
	local ok, err = conReintentos(function()
		almacen:SetAsync(clave(jugador), copia, { jugador.UserId })
	end)
	if ok then
		e.sucio = false
	else
		warn(`[UMTD] No se pudo guardar el perfil de {jugador.Name}: {err}`)
	end
end

function Perfiles.soltar(jugador: Player)
	Perfiles.guardar(jugador)
	perfiles[jugador] = nil
end

function Perfiles.guardarTodos()
	for jugador in perfiles do
		task.spawn(Perfiles.guardar, jugador)
	end
end

return Perfiles
