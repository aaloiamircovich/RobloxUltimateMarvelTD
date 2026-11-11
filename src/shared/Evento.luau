-- Desafío semanal: un mapa y 2 modificadores por semana, puntaje, fichas y tienda del evento (docs/EVENTO.md).
-- Sistema propio del port. Módulo puro: la hora (segundos UTC) entra como parámetro.
local Temporada = require(script.Parent.Temporada)
local Objetos = require(script.Parent.Objetos)
local Actos = require(script.Parent.Actos)
local items = require(script.Parent.Data.items)

local Evento = {}

Evento.OLEADAS = 30 -- tope: sobrevivir las 30 es el puntaje máximo
Evento.PUNTOS_OLEADA = 100
Evento.PUNTOS_POR_FICHA = 100
Evento.FICHAS_SEMANA = 300 -- tope semanal de fichas ganadas

-- Efecto de cada modificador sobre la partida (Partida.luau los aplica).
Evento.MODIFICADORES = {
	rapidos = { nombre = "Enemigos veloces", texto = "Los enemigos son 25 % más rápidos", velocidad = 1.25 },
	blindados = { nombre = "Blindados", texto = "Los enemigos tienen 50 % más de vida", vida = 1.5 },
	presupuesto = { nombre = "Presupuesto ajustado", texto = "Empezás con 40 % menos dinero", dinero = 0.6 },
	base_fragil = { nombre = "Base frágil", texto = "La base tiene la mitad de vida", base = 0.5 },
	sin_vender = { nombre = "Sin retirada", texto = "No se pueden vender unidades", sinVender = true },
}
local ORDEN_MODS = { "rapidos", "blindados", "presupuesto", "base_fragil", "sin_vender" }

-- Tienda: precio en fichas y cuántas veces por semana.
Evento.TIENDA = {
	{ id = "gemas", nombre = "100 gemas", precio = 40, limite = 5, gemas = 100 },
	{ id = "nucleo", nombre = "1 núcleo", precio = 120, limite = 2, nucleos = 1 },
	{ id = "xp", nombre = "300 XP de pase", precio = 50, limite = 4, xpPase = 300 },
	{ id = "objeto", nombre = "Objeto épico", precio = 150, limite = 1, objeto = "Epic" },
}
local PRODUCTO = {}
for _, p in Evento.TIENDA do
	PRODUCTO[p.id] = p
end

function Evento.semana(t: number): number
	return Temporada.semana(t)
end

-- Mapa y modificadores de la semana: iguales para todos.
function Evento.desafio(semana: number)
	local azar = Random.new(semana * 977 + 41)
	local pozo = table.clone(ORDEN_MODS)
	local a = table.remove(pozo, azar:NextInteger(1, #pozo))
	local b = table.remove(pozo, azar:NextInteger(1, #pozo))
	return { semana = semana, mapa = Actos.MAPAS[semana % #Actos.MAPAS + 1], modificadores = { a, b } }
end

-- Efectos combinados de los modificadores.
function Evento.efectos(desafio)
	local e = { velocidad = 1, vida = 1, dinero = 1, base = 1, sinVender = false }
	for _, id in desafio.modificadores do
		local m = Evento.MODIFICADORES[id]
		e.velocidad *= m.velocidad or 1
		e.vida *= m.vida or 1
		e.dinero *= m.dinero or 1
		e.base *= m.base or 1
		e.sinVender = e.sinVender or m.sinVender == true
	end
	return e
end

function Evento.puntos(oleadasSuperadas: number, derrotados: number): number
	return oleadasSuperadas * Evento.PUNTOS_OLEADA + derrotados
end

function Evento.nuevo()
	return { semana = -1, mejor = 0, fichas = 0, ganadas = 0, compras = {} }
end

-- Frontera de confianza: lo que viene del DataStore.
function Evento.normalizar(crudo)
	local e = Evento.nuevo()
	if type(crudo) ~= "table" then
		return e
	end
	local function n(v, maximo)
		local x = tonumber(v)
		return if x and x == x then math.clamp(math.floor(x), 0, maximo) else 0
	end
	e.semana = if tonumber(crudo.semana) then math.floor(crudo.semana) else -1
	e.mejor = n(crudo.mejor, 1e7)
	e.fichas = n(crudo.fichas, 1e6)
	e.ganadas = n(crudo.ganadas, Evento.FICHAS_SEMANA)
	if type(crudo.compras) == "table" then
		for id, c in crudo.compras do
			if PRODUCTO[id] then
				e.compras[id] = n(c, PRODUCTO[id].limite)
			end
		end
	end
	return e
end

-- Otra semana: puntaje, fichas y compras vuelven a cero.
function Evento.actualizar(perfil, t: number)
	local e = perfil.evento
	local w = Evento.semana(t)
	if e.semana ~= w then
		perfil.evento = Evento.nuevo()
		perfil.evento.semana = w
	end
	return perfil.evento
end

-- Fin de un intento: guarda el mejor puntaje y entrega fichas (con tope semanal). Devuelve fichas y si es récord.
function Evento.registrar(perfil, puntos: number, t: number): (number, boolean)
	local e = Evento.actualizar(perfil, t)
	local record = puntos > e.mejor
	e.mejor = math.max(e.mejor, puntos)
	local fichas = math.min(puntos // Evento.PUNTOS_POR_FICHA, Evento.FICHAS_SEMANA - e.ganadas)
	e.ganadas += fichas
	e.fichas += fichas
	return fichas, record
end

-- Objeto épico que todavía no tenés (la semana decide cuál); nil si ya los tenés todos.
function Evento.objetoDeLaSemana(perfil, rareza: string, semana: number): string?
	local ids = {}
	for id, it in items do
		if it.rarity == rareza and not Objetos.tiene(perfil, id) then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return if #ids > 0 then ids[semana % #ids + 1] else nil
end

function Evento.comprar(perfil, id: string, t: number): string?
	local e = Evento.actualizar(perfil, t)
	local p = PRODUCTO[id]
	if not p then
		return "Producto inválido"
	end
	if (e.compras[id] or 0) >= p.limite then
		return "Agotado esta semana"
	end
	if e.fichas < p.precio then
		return `Faltan {p.precio - e.fichas} fichas`
	end
	if p.objeto then
		local obj = Evento.objetoDeLaSemana(perfil, p.objeto, e.semana)
		if not obj then
			return "Ya tenés todos los objetos de esa rareza"
		end
		table.insert(perfil.ownedItemIds, obj)
	end
	perfil.gems += p.gemas or 0
	perfil.cores += p.nucleos or 0
	if p.xpPase then
		Temporada.ganarXP(perfil, p.xpPase, t)
	end
	e.fichas -= p.precio
	e.compras[id] = (e.compras[id] or 0) + 1
	return nil
end

-- Lo que muestra el panel del evento.
function Evento.resumen(perfil, t: number)
	local e = Evento.actualizar(perfil, t)
	local d = Evento.desafio(e.semana)
	local mods = {}
	for _, id in d.modificadores do
		table.insert(mods, Evento.MODIFICADORES[id])
	end
	local tienda = {}
	for _, p in Evento.TIENDA do
		local obj = p.objeto and Evento.objetoDeLaSemana(perfil, p.objeto, e.semana)
		table.insert(tienda, { id = p.id, nombre = if obj then items[obj].name else p.nombre, precio = p.precio, quedan = p.limite - (e.compras[p.id] or 0) })
	end
	return {
		mapa = d.mapa,
		modificadores = mods,
		mejor = e.mejor,
		fichas = e.fichas,
		ganadas = e.ganadas,
		topeFichas = Evento.FICHAS_SEMANA,
		oleadas = Evento.OLEADAS,
		tienda = tienda,
		fin = Temporada.SEMANA - (t - Temporada.LUNES) % Temporada.SEMANA,
	}
end

return Evento
