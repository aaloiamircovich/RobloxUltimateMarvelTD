-- Perfil persistente por jugador (DataStore). Subconjunto del estado de ProgressionManager del 2D,
-- con los mismos nombres de campo para poder importar perfiles: credits, heroUpgrades, mapProgress,
-- unlockedHeroIds, activeTeamIds, shop, modeRecords (sólo supervivencia), ownedItemIds y equippedItems.
local DataStoreService = game:GetService("DataStoreService")
local heroes = require(game:GetService("ReplicatedStorage").Shared.Data.heroes)
local items = require(game:GetService("ReplicatedStorage").Shared.Data.items)

local Perfiles = {}

Perfiles.VERSION = 1
Perfiles.CREDITOS_INICIALES = 1200 -- createDefaultState del 2D
local MAX_OLEADAS = 100

local almacen = nil -- se pide al primer uso: falla en Studio sin acceso a API
local perfiles = {} -- [Player] = { datos, guardable, sucio }

local function nivelValido(n)
	return math.clamp(math.floor(tonumber(n) or 1), 1, 100)
end

-- Frontera de confianza: lo que viene del DataStore puede estar viejo o roto.
function Perfiles.normalizar(crudo)
	local datos = if type(crudo) == "table" then crudo else {}
	local p = {
		version = Perfiles.VERSION,
		credits = Perfiles.CREDITOS_INICIALES,
		heroUpgrades = {},
		mapProgress = {},
		unlockedHeroIds = {},
		activeTeamIds = {},
		shop = { heroPity = 0, heroBoxCost = 500 },
		modeRecords = { survival = { bestWave = 0, bestScore = 0 } },
		ownedItemIds = {},
		equippedItems = {},
	}
	local c = tonumber(datos.credits)
	if c and c == c and c >= 0 and c < math.huge then
		p.credits = math.floor(c)
	end
	if type(datos.heroUpgrades) == "table" then
		for id, v in datos.heroUpgrades do
			local nivel = nivelValido(if type(v) == "table" then v.level else v)
			if type(id) == "string" and nivel > 1 then
				p.heroUpgrades[id] = { level = nivel }
			end
		end
	end
	if type(datos.mapProgress) == "table" then
		for id, v in datos.mapProgress do
			if type(id) == "string" and type(v) == "table" then
				local mejor = math.clamp(math.floor(tonumber(v.bestWave) or 0), 0, MAX_OLEADAS)
				p.mapProgress[id] = { bestWave = mejor, stars = math.max(mejor, math.clamp(math.floor(tonumber(v.stars) or 0), 0, MAX_OLEADAS)) }
			end
		end
	end
	-- Colección: sólo ids de héroes existentes, sin repetir; el escuadrón, subconjunto de 1 a 6.
	local function ids(lista, permitido, tope)
		local r = {}
		if type(lista) == "table" then
			for _, id in lista do
				if type(id) == "string" and heroes[id] and permitido(id) and not table.find(r, id) and #r < tope then
					table.insert(r, id)
				end
			end
		end
		return r
	end
	p.unlockedHeroIds = ids(datos.unlockedHeroIds, function()
		return true
	end, math.huge)
	p.activeTeamIds = ids(datos.activeTeamIds, function(id)
		return table.find(p.unlockedHeroIds, id) ~= nil
	end, 6)
	if #p.activeTeamIds == 0 and #p.unlockedHeroIds > 0 then
		p.activeTeamIds = { p.unlockedHeroIds[1] }
	end
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
		p.shop.heroPity = math.max(0, math.floor(tonumber(datos.shop.heroPity) or 0))
		p.shop.heroBoxCost = math.max(500, math.ceil(tonumber(datos.shop.heroBoxCost) or 500))
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
