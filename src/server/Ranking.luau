-- Rankings globales (OrderedDataStore): puntaje del desafío de la semana, mejor oleada de Infinito y nivel de
-- cuenta (docs/EVENTO.md). Se anota en memoria y se sube cada minuto (cuida el presupuesto de pedidos); el top 10
-- se cachea. Sin acceso al DataStore (Studio sin permisos) muestra a los jugadores de este servidor.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Evento = require(game:GetService("ReplicatedStorage").Shared.Evento)

local Ranking = {}
Ranking.TABLAS = { "evento", "infinito", "nivel" }
Ranking.TOP = 10

local pendientes = {} -- [nombre de la tabla] = { [userId] = valor }
local locales = {} -- [tabla] = { [userId] = valor } (respaldo sin DataStore)
local tops = {} -- [tabla] = { { nombre, valor } }
local nombres = {} -- caché userId → nombre

-- El ranking del evento es uno por semana.
local function almacen(tabla: string): string
	return if tabla == "evento" then `Ranking_evento_{Evento.semana(os.time())}` else "Ranking_" .. tabla
end

local function nombreDe(userId: number): string
	if nombres[userId] then
		return nombres[userId]
	end
	local j = Players:GetPlayerByUserId(userId)
	local ok, n = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	nombres[userId] = if j then j.DisplayName elseif ok then n else "Jugador"
	return nombres[userId]
end

-- Guarda el valor si es mejor que el anotado.
function Ranking.anotar(tabla: string, userId: number, valor: number)
	valor = math.floor(valor)
	local clave = almacen(tabla)
	pendientes[clave] = pendientes[clave] or {}
	pendientes[clave][userId] = math.max(pendientes[clave][userId] or 0, valor)
	locales[tabla] = locales[tabla] or {}
	locales[tabla][userId] = math.max(locales[tabla][userId] or 0, valor)
end

local sinAcceso = false
function Ranking.subir()
	local lote = pendientes
	pendientes = {}
	for clave, valores in lote do
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, clave)
		for userId, valor in valores do
			local subio = ok and pcall(function()
				store:UpdateAsync(tostring(userId), function(viejo)
					return math.max(tonumber(viejo) or 0, valor)
				end)
			end)
			sinAcceso = sinAcceso or not subio
		end
	end
end

function Ranking.refrescar()
	for _, tabla in Ranking.TABLAS do
		local lista = {}
		local ok = not sinAcceso and pcall(function()
			local pagina = DataStoreService:GetOrderedDataStore(almacen(tabla)):GetSortedAsync(false, Ranking.TOP):GetCurrentPage()
			for _, fila in pagina do
				table.insert(lista, { nombre = nombreDe(tonumber(fila.key)), valor = fila.value })
			end
		end)
		if not ok then
			lista = {}
			for userId, valor in locales[tabla] or {} do
				table.insert(lista, { nombre = nombreDe(userId), valor = valor })
			end
			table.sort(lista, function(a, b)
				return a.valor > b.valor
			end)
			while #lista > Ranking.TOP do
				table.remove(lista)
			end
		end
		tops[tabla] = lista
	end
end

function Ranking.top(tabla: string)
	return tops[tabla] or {}
end

-- Vacía el ranking local del evento al cambiar de semana.
local semanaLocal = Evento.semana(os.time())
function Ranking.revisarSemana()
	local w = Evento.semana(os.time())
	if w ~= semanaLocal then
		semanaLocal = w
		locales.evento = {}
	end
end

return Ranking
