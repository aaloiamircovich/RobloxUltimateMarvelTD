-- Intercambio de unidades y objetos entre jugadores (docs/INTERCAMBIO.md). Reglas puras: el servidor maneja las
-- sesiones y llama a `aplicar` sólo cuando los dos confirmaron. Pruebas en src/server/Pruebas/Intercambio.spec.luau.
local Personajes = require(script.Parent.Personajes)
local Unidades = require(script.Parent.Unidades)

local Intercambio = {}

Intercambio.NIVEL_MINIMO = 10
Intercambio.MAX_POR_LADO = 8 -- tope técnico por oferta (unidades + objetos)

function Intercambio.puede(perfil): string?
	if (perfil.level or 1) < Intercambio.NIVEL_MINIMO then
		return `Necesitás nivel de cuenta {Intercambio.NIVEL_MINIMO} para intercambiar`
	end
	return nil
end

function Intercambio.ofertaVacia()
	return { unidades = {}, objetos = {} }
end

-- Qué puede ofrecer: unidades fuera del escuadrón que no sean exclusivas y objetos sin equipar.
function Intercambio.ofrecibles(perfil)
	local unidades = {}
	for _, u in perfil.units do
		local h = Personajes.de(u.heroId)
		if h and not h.exclusivo and not table.find(perfil.squad, u.uid) then
			table.insert(unidades, u)
		end
	end
	return unidades, table.clone(perfil.ownedItemIds)
end

-- Frontera de confianza: la oferta viene del cliente. Devuelve la oferta limpia o un error.
function Intercambio.validarOferta(perfil, oferta): (any?, string?)
	if type(oferta) ~= "table" or type(oferta.unidades) ~= "table" or type(oferta.objetos) ~= "table" then
		return nil, "Oferta inválida"
	end
	local limpia = Intercambio.ofertaVacia()
	for _, uid in oferta.unidades do
		if type(uid) ~= "number" or uid ~= uid or table.find(limpia.unidades, uid) then
			return nil, "Oferta inválida"
		end
		local u = Unidades.buscar(perfil, uid)
		local h = u and Personajes.de(u.heroId)
		if not u or not h then
			return nil, "Esa unidad ya no está"
		end
		if h.exclusivo then
			return nil, `{h.name} es exclusivo y no se puede intercambiar`
		end
		if table.find(perfil.squad, uid) then
			return nil, `Sacá a {h.name} del escuadrón para ofrecerlo`
		end
		table.insert(limpia.unidades, uid)
	end
	local usados = {}
	for _, id in oferta.objetos do
		if type(id) ~= "string" then
			return nil, "Oferta inválida"
		end
		usados[id] = (usados[id] or 0) + 1
		local libres = 0
		for _, propio in perfil.ownedItemIds do
			if propio == id then
				libres += 1
			end
		end
		if usados[id] > libres then
			return nil, "Ese objeto no está en tu inventario (desequipalo para ofrecerlo)"
		end
		table.insert(limpia.objetos, id)
	end
	if #limpia.unidades + #limpia.objetos > Intercambio.MAX_POR_LADO then
		return nil, `Hasta {Intercambio.MAX_POR_LADO} cosas por oferta`
	end
	return limpia, nil
end

local function tieneObjeto(perfil, id: string): boolean
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

-- Revisa todo antes de mover nada; si algo falla no cambia ningún perfil.
function Intercambio.aplicar(pa, ofertaA, pb, ofertaB): string?
	local problema = Intercambio.puede(pa) or Intercambio.puede(pb)
	if problema then
		return problema
	end
	local a, errA = Intercambio.validarOferta(pa, ofertaA)
	if not a then
		return errA
	end
	local b, errB = Intercambio.validarOferta(pb, ofertaB)
	if not b then
		return errB
	end
	if #a.unidades + #a.objetos + #b.unidades + #b.objetos == 0 then
		return "Las dos ofertas están vacías"
	end
	if #pa.units - #a.unidades + #b.unidades > Unidades.MAX_INVENTARIO or #pb.units - #b.unidades + #a.unidades > Unidades.MAX_INVENTARIO then
		return `No hay lugar en el inventario (máximo {Unidades.MAX_INVENTARIO} unidades)`
	end
	for _, id in a.objetos do
		if tieneObjeto(pb, id) then
			return "El otro jugador ya tiene uno de esos objetos"
		end
	end
	for _, id in b.objetos do
		if tieneObjeto(pa, id) then
			return "Ya tenés uno de los objetos que te ofrecen"
		end
	end
	-- Mover: se sacan de cada lado y se agregan al otro con uid nuevo (conservan nivel, XP, rasgo y grados).
	local function sacar(perfil, oferta)
		local unidades, objetos = {}, {}
		for _, uid in oferta.unidades do
			local _, i = Unidades.buscar(perfil, uid)
			table.insert(unidades, table.remove(perfil.units, i))
		end
		for _, id in oferta.objetos do
			table.insert(objetos, table.remove(perfil.ownedItemIds, table.find(perfil.ownedItemIds, id)))
		end
		return unidades, objetos
	end
	local function poner(perfil, unidades, objetos)
		for _, u in unidades do
			u.uid = perfil.nextUnitUid
			perfil.nextUnitUid += 1
			table.insert(perfil.units, u)
		end
		for _, id in objetos do
			table.insert(perfil.ownedItemIds, id)
		end
		Unidades.sincronizar(perfil)
	end
	local ua, oa = sacar(pa, a)
	local ub, ob = sacar(pb, b)
	poner(pa, ub, ob)
	poner(pb, ua, oa)
	return nil
end

return Intercambio
