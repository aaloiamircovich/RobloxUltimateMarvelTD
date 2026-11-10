-- Inventario de unidades del perfil: copias repetibles con nivel y experiencia, escuadrón, venta
-- y evolución por crafteo. Reglas en docs/INVOCACIONES.md. Módulo puro sobre el perfil.
local Personajes = require(script.Parent.Personajes)
local Cuenta = require(script.Parent.Cuenta)

local Unidades = {}

Unidades.MAX_INVENTARIO = 100
Unidades.MAX_ESCUADRON = 6 -- tope absoluto; las casillas abiertas dependen del nivel de cuenta (Cuenta.casillas)
Unidades.NIVEL_MAXIMO = 50
Unidades.COPIAS_EVOLUCION = 3
Unidades.LIMITE_COLOCACION = { Common = 4, Rare = 3, Epic = 3, Legendary = 2, Mythic = 1, Secret = 1 }
Unidades.VENTA = { Common = 2, Rare = 5, Epic = 10, Legendary = 25, Mythic = 50, Secret = 100 }
Unidades.NUCLEOS = { Rare = 1, Epic = 3, Legendary = 8, Mythic = 20, Secret = 50 } -- según la rareza de destino

-- XP para pasar del nivel n al n+1.
function Unidades.xpParaSubir(n: number): number
	return 50 * n
end

-- +1 % de daño por nivel por encima del 1.
function Unidades.bonoDano(nivel: number): number
	return 1 + (nivel - 1) * 0.01
end

function Unidades.buscar(perfil, uid: number)
	for i, u in perfil.units do
		if u.uid == uid then
			return u, i
		end
	end
	return nil
end

-- Lista de personajes de los que hay al menos una unidad (los objetos se equipan por personaje).
function Unidades.sincronizar(perfil)
	local ids = {}
	for _, u in perfil.units do
		if not table.find(ids, u.heroId) then
			table.insert(ids, u.heroId)
		end
	end
	perfil.unlockedHeroIds = ids
	for heroeId in perfil.equippedItems do
		if not table.find(ids, heroeId) then
			-- El objeto vuelve al inventario si ya no queda ninguna unidad de ese personaje.
			for _, itemId in perfil.equippedItems[heroeId] do
				table.insert(perfil.ownedItemIds, itemId)
			end
			perfil.equippedItems[heroeId] = nil
		end
	end
end

function Unidades.agregar(perfil, heroId: string, nivel: number?)
	local u = { uid = perfil.nextUnitUid, heroId = heroId, level = nivel or 1, xp = 0 }
	perfil.nextUnitUid += 1
	table.insert(perfil.units, u)
	if #perfil.squad < Cuenta.casillas(perfil.level or 1) then
		table.insert(perfil.squad, u.uid)
	end
	Unidades.sincronizar(perfil)
	return u
end

-- Suma XP a la unidad; devuelve cuántos niveles subió.
function Unidades.ganarXP(u, xp: number): number
	local subidos = 0
	u.xp += xp
	while u.level < Unidades.NIVEL_MAXIMO and u.xp >= Unidades.xpParaSubir(u.level) do
		u.xp -= Unidades.xpParaSubir(u.level)
		u.level += 1
		subidos += 1
	end
	if u.level >= Unidades.NIVEL_MAXIMO then
		u.xp = 0
	end
	return subidos
end

-- Escuadrón: de 1 a las casillas abiertas (3 a 6 según el nivel de cuenta), sin repetir la misma unidad.
function Unidades.fijarEscuadron(perfil, uids): string?
	local r = {}
	for _, uid in uids do
		if type(uid) == "number" and Unidades.buscar(perfil, uid) and not table.find(r, uid) then
			table.insert(r, uid)
		end
	end
	if #r == 0 then
		return "El escuadrón necesita al menos una unidad"
	end
	local casillas = Cuenta.casillas(perfil.level or 1)
	if #r > casillas then
		return `Tu escuadrón tiene {casillas} casillas abiertas (subí de nivel para abrir más)`
	end
	perfil.squad = r
	return nil
end

function Unidades.vender(perfil, uid: number): (number?, string?)
	local u, i = Unidades.buscar(perfil, uid)
	if not u then
		return nil, "Esa unidad no existe"
	end
	if table.find(perfil.squad, uid) then
		return nil, "Sacala del escuadrón antes de venderla"
	end
	local c = Personajes.de(u.heroId)
	local gemas = Unidades.VENTA[c.rarity] or 0
	table.remove(perfil.units, i)
	perfil.gems += gemas
	Unidades.sincronizar(perfil)
	return gemas, nil
end

-- Evolución: 3 unidades distintas del mismo personaje + núcleos según la rareza de destino.
-- El resultado hereda el nivel más alto y ocupa el lugar en el escuadrón de la primera que estuviera.
function Unidades.evolucionar(perfil, uids): (any?, string?)
	if type(uids) ~= "table" or #uids ~= Unidades.COPIAS_EVOLUCION then
		return nil, `Elegí {Unidades.COPIAS_EVOLUCION} copias del mismo personaje`
	end
	local elegidas, heroId = {}, nil
	for _, uid in uids do
		local u = type(uid) == "number" and Unidades.buscar(perfil, uid)
		if not u or table.find(elegidas, u) then
			return nil, "Unidades inválidas"
		end
		if heroId and u.heroId ~= heroId then
			return nil, "Las copias tienen que ser del mismo personaje"
		end
		heroId = u.heroId
		table.insert(elegidas, u)
	end
	local destino = Personajes.evolucion(heroId)
	if not destino then
		return nil, "Este personaje no evoluciona"
	end
	local costo = Unidades.NUCLEOS[Personajes.de(destino).rarity] or 0
	if perfil.cores < costo then
		return nil, `Faltan {costo - perfil.cores} núcleos`
	end
	local nivel, lugar = 1, nil
	for _, u in elegidas do
		nivel = math.max(nivel, u.level)
		local enEscuadron = table.find(perfil.squad, u.uid)
		if enEscuadron then
			lugar = lugar or enEscuadron
			table.remove(perfil.squad, enEscuadron)
		end
		table.remove(perfil.units, select(2, Unidades.buscar(perfil, u.uid)))
	end
	perfil.cores -= costo
	local nueva = { uid = perfil.nextUnitUid, heroId = destino, level = nivel, xp = 0 }
	perfil.nextUnitUid += 1
	table.insert(perfil.units, nueva)
	if lugar then
		table.insert(perfil.squad, math.min(lugar, #perfil.squad + 1), nueva.uid)
	end
	Unidades.sincronizar(perfil)
	return nueva, nil
end

return Unidades
