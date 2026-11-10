-- Objetos: tienda progresiva, inventario y equipo (uno por héroe), portados de ShopSystem.js,
-- ItemEffectSystem.js y ProgressionManager.equipItem del 2D. Módulo puro sobre el perfil.
local items = require(script.Parent.Data.items)

local Objetos = {}

-- getItemShopPowerScore del 2D.
local function poder(item): number
	local efecto = 0
	for _, v in item.effects or {} do
		if type(v) == "number" then
			efecto += math.abs(v) * 1000
		elseif v == true then
			efecto += 250
		end
	end
	return (tonumber(item.tier) or 1) * 100000 + (tonumber(item.price) or 0) + efecto
end

-- sortItemsWeakestFirst del 2D: poder, precio y nombre (localeCompare ≈ comparación de cadenas).
local ordenados = {}
for _, it in items do
	table.insert(ordenados, it)
end
table.sort(ordenados, function(a, b)
	local pa, pb = poder(a), poder(b)
	if pa ~= pb then
		return pa < pb
	end
	if (a.price or 0) ~= (b.price or 0) then
		return (a.price or 0) < (b.price or 0)
	end
	return tostring(a.name or a.id) < tostring(b.name or b.id)
end)

-- hasItem del 2D: en el inventario o equipado en algún héroe.
function Objetos.tiene(perfil, id: string): boolean
	if table.find(perfil.ownedItemIds, id) then
		return true
	end
	for _, ranuras in perfil.equippedItems do
		for _, equipado in ranuras do
			if equipado == id then
				return true
			end
		end
	end
	return false
end

-- getShowcase del 2D: los tres más débiles que todavía no tenés.
function Objetos.vitrina(perfil): { any }
	local r = {}
	for _, it in ordenados do
		if not Objetos.tiene(perfil, it.id) then
			table.insert(r, it)
			if #r == 3 then
				break
			end
		end
	end
	return r
end

function Objetos.comprar(perfil, id: string): string?
	local it = items[id]
	local visible = false
	for _, v in Objetos.vitrina(perfil) do
		visible = visible or v.id == id
	end
	if not it or not visible or Objetos.tiene(perfil, id) then
		return "Objeto no disponible"
	end
	if perfil.credits < it.price then
		return "Créditos insuficientes"
	end
	perfil.credits -= it.price
	table.insert(perfil.ownedItemIds, id)
	return nil
end

-- Objeto equipado en un héroe (uno solo cuenta, como aggregateItemEffects del 2D).
function Objetos.de(perfil, heroeId: string)
	for _, id in perfil.equippedItems[heroeId] or {} do
		return items[id]
	end
	return nil
end

-- equipItem del 2D: desde el inventario o pasándolo desde otro héroe; el anterior vuelve al inventario.
function Objetos.equipar(perfil, heroeId: string, id: string): string?
	if not table.find(perfil.unlockedHeroIds, heroeId) then
		return "No tenés ese héroe"
	end
	local it = items[id]
	if not it or not it.slot then
		return "Objeto inválido"
	end
	local libre = table.find(perfil.ownedItemIds, id)
	local origen
	for h, ranuras in perfil.equippedItems do
		for _, equipado in ranuras do
			if equipado == id then
				origen = h
			end
		end
	end
	if not libre and not origen then
		return "No tenés ese objeto"
	end
	local anteriores = {}
	for _, equipado in perfil.equippedItems[heroeId] or {} do
		table.insert(anteriores, equipado)
	end
	if table.find(anteriores, id) then
		return nil
	end
	if libre then
		table.remove(perfil.ownedItemIds, libre)
	elseif origen ~= heroeId then
		perfil.equippedItems[origen] = nil
	end
	for _, a in anteriores do
		table.insert(perfil.ownedItemIds, a)
	end
	perfil.equippedItems[heroeId] = { [it.slot] = id }
	return nil
end

function Objetos.quitar(perfil, heroeId: string): string?
	local previo = perfil.equippedItems[heroeId]
	if not previo then
		return "Ese héroe no tiene objeto"
	end
	for _, id in previo do
		table.insert(perfil.ownedItemIds, id)
	end
	perfil.equippedItems[heroeId] = nil
	return nil
end

return Objetos
