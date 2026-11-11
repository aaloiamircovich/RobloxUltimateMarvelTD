-- Misiones diarias y semanales y pase de batalla (sistema propio: no existe en el 2D; docs/TEMPORADA.md).
-- Módulo puro: la hora (segundos UTC) entra como parámetro para poder probarlo.
local Objetos = require(script.Parent.Objetos)
local Unidades = require(script.Parent.Unidades)
local items = require(script.Parent.Data.items)

local Temporada = {}

Temporada.DIA, Temporada.SEMANA = 86400, 7 * 86400
Temporada.LUNES = 4 * 86400 -- el 1/1/1970 fue jueves: las semanas empiezan el lunes 00:00 UTC
Temporada.DURACION = 30 * 86400
Temporada.INICIO = 1794355200 -- miércoles 11/11/2026 00:00 UTC, temporada 1
Temporada.NIVELES, Temporada.XP_NIVEL = 50, 300
Temporada.XP_OLEADA, Temporada.XP_ACTO = 10, 50 -- XP de pase por jugar
Temporada.CANTIDAD = 3 -- misiones por lista
Temporada.PREMIO = { diaria = { gemas = 15, xp = 100 }, semanal = { gemas = 60, xp = 400, fichasRasgo = 1, cristales = 2 } }
Temporada.GEMAS_OBJETO_REPETIDO = 100
-- Unidad del nivel 50: un personaje nuevo que todavía no existe; hasta entonces el nivel 50 no se reclama.
Temporada.EXCLUSIVA = nil :: string?

-- Tareas: evento que las hace avanzar y meta diaria/semanal (nil = no sale en esa lista).
-- `maximo`: cuenta el mejor valor en vez de sumar.
Temporada.TAREAS = {
	{ id = "ganar", evento = "acto", diaria = 2, semanal = 10, texto = "Ganá %d actos" },
	{ id = "derrotar", evento = "derrota", diaria = 150, semanal = 1500, texto = "Derrotá %d enemigos" },
	{ id = "colocar", evento = "colocar", diaria = 15, semanal = 120, texto = "Colocá %d unidades" },
	{ id = "mejorar", evento = "mejorar", diaria = 10, semanal = 80, texto = "Hacé %d mejoras" },
	{ id = "oleadas", evento = "oleada", diaria = 20, semanal = 150, texto = "Superá %d oleadas" },
	{ id = "infinito", evento = "infinito", semanal = 25, texto = "Llegá a la oleada %d en Infinito", maximo = true },
	{ id = "invocar", evento = "invocar", diaria = 5, semanal = 30, texto = "Invocá %d veces" },
}
local TAREA = {}
for _, t in Temporada.TAREAS do
	TAREA[t.id] = t
end

function Temporada.dia(t: number): number
	return t // Temporada.DIA
end
function Temporada.semana(t: number): number
	return (t - Temporada.LUNES) // Temporada.SEMANA
end
function Temporada.numero(t: number): number
	return math.max(1, (t - Temporada.INICIO) // Temporada.DURACION + 1)
end

-- Las mismas misiones para todos ese día/semana.
local function sortear(semilla: number, lista: string)
	local azar = Random.new(semilla)
	local pozo = {}
	for _, t in Temporada.TAREAS do
		if t[lista] then
			table.insert(pozo, t.id)
		end
	end
	local r = {}
	for _ = 1, Temporada.CANTIDAD do
		table.insert(r, { id = table.remove(pozo, azar:NextInteger(1, #pozo)), progreso = 0, reclamada = false })
	end
	return r
end

function Temporada.nuevo()
	return { dia = -1, semana = -1, numero = 0, diarias = {}, semanales = {}, xp = 0, reclamados = {} }
end

-- Frontera de confianza: lo que viene del DataStore.
function Temporada.normalizar(crudo)
	local s = Temporada.nuevo()
	if type(crudo) ~= "table" then
		return s
	end
	local function n(v)
		local x = tonumber(v)
		return if x and x == x and math.abs(x) < 1e12 then math.floor(x) else nil
	end
	s.dia, s.semana, s.numero = n(crudo.dia) or -1, n(crudo.semana) or -1, n(crudo.numero) or 0
	s.xp = math.clamp(n(crudo.xp) or 0, 0, Temporada.NIVELES * Temporada.XP_NIVEL)
	for _, lista in { "diarias", "semanales" } do
		if type(crudo[lista]) == "table" then
			for _, m in crudo[lista] do
				if type(m) == "table" and TAREA[m.id] and #s[lista] < Temporada.CANTIDAD then
					table.insert(s[lista], { id = m.id, progreso = math.max(0, n(m.progreso) or 0), reclamada = m.reclamada == true })
				end
			end
		end
	end
	if type(crudo.reclamados) == "table" then
		for _, nivel in crudo.reclamados do
			local x = n(nivel)
			if x and x >= 1 and x <= Temporada.NIVELES and not table.find(s.reclamados, x) then
				table.insert(s.reclamados, x)
			end
		end
	end
	return s
end

-- Renueva las listas y el pase cuando cambia el día, la semana o la temporada.
function Temporada.actualizar(perfil, t: number)
	local s = perfil.temporada
	local d, w, num = Temporada.dia(t), Temporada.semana(t), Temporada.numero(t)
	if s.dia ~= d or #s.diarias ~= Temporada.CANTIDAD then
		s.dia, s.diarias = d, sortear(d * 31 + 7, "diaria")
	end
	if s.semana ~= w or #s.semanales ~= Temporada.CANTIDAD then
		s.semana, s.semanales = w, sortear(w * 131 + 3, "semanal")
	end
	if s.numero ~= num then
		s.numero, s.xp, s.reclamados = num, 0, {}
	end
	return s
end

function Temporada.meta(lista: string, id: string): number
	return TAREA[id][if lista == "diarias" then "diaria" else "semanal"]
end

-- Un evento de juego (acto, derrota, colocar, mejorar, oleada, infinito, invocar) avanza las misiones.
function Temporada.registrar(perfil, evento: string, cantidad: number, t: number)
	local s = Temporada.actualizar(perfil, t)
	for _, lista in { "diarias", "semanales" } do
		for _, m in s[lista] do
			local tarea = TAREA[m.id]
			if tarea.evento == evento then
				local meta = Temporada.meta(lista, m.id)
				m.progreso = math.min(meta, if tarea.maximo then math.max(m.progreso, cantidad) else m.progreso + cantidad)
			end
		end
	end
end

function Temporada.nivel(perfil): number
	return perfil.temporada.xp // Temporada.XP_NIVEL
end

function Temporada.ganarXP(perfil, xp: number, t: number)
	local s = Temporada.actualizar(perfil, t)
	s.xp = math.min(s.xp + xp, Temporada.NIVELES * Temporada.XP_NIVEL)
end

function Temporada.reclamar(perfil, lista: string, i: number, t: number): string?
	local s = Temporada.actualizar(perfil, t)
	local m = (lista == "diarias" or lista == "semanales") and s[lista][i]
	if not m then
		return "Misión inválida"
	end
	if m.reclamada then
		return "Ya reclamaste esta misión"
	end
	if m.progreso < Temporada.meta(lista, m.id) then
		return "Todavía no completaste esta misión"
	end
	m.reclamada = true
	local premio = Temporada.PREMIO[if lista == "diarias" then "diaria" else "semanal"]
	perfil.gems += premio.gemas
	perfil.fichasRasgo = (perfil.fichasRasgo or 0) + (premio.fichasRasgo or 0)
	perfil.cristales = (perfil.cristales or 0) + (premio.cristales or 0)
	Temporada.ganarXP(perfil, premio.xp, t)
	return nil
end

-- Premio gratis de un nivel del pase (las temporadas cambian qué objetos salen).
function Temporada.premio(numero: number, nivel: number)
	if nivel == Temporada.NIVELES then
		return { tipo = "unidad", id = Temporada.EXCLUSIVA }
	elseif nivel % 10 == 0 then
		return { tipo = "nucleos", cantidad = nivel // 10 }
	elseif nivel % 10 == 3 then
		return { tipo = "fichas", cantidad = 1 + nivel // 20 }
	elseif nivel % 10 == 7 then
		return { tipo = "cristales", cantidad = 2 + nivel // 20 }
	elseif nivel % 5 == 0 then
		local rareza = if nivel < 30 then "Rare" else "Epic"
		local ids = {}
		for id, it in items do
			if it.rarity == rareza then
				table.insert(ids, id)
			end
		end
		table.sort(ids)
		return { tipo = "objeto", id = ids[Random.new(numero * 100 + nivel):NextInteger(1, #ids)] }
	end
	return { tipo = "gemas", cantidad = 20 + 5 * (nivel // 10) }
end

-- Entrega el premio; un objeto que ya tenés se cambia por gemas.
function Temporada.reclamarPase(perfil, nivel: number, t: number): string?
	local s = Temporada.actualizar(perfil, t)
	if type(nivel) ~= "number" or nivel ~= math.floor(nivel) or nivel < 1 or nivel > Temporada.NIVELES then
		return "Nivel inválido"
	end
	if table.find(s.reclamados, nivel) then
		return "Ya reclamaste este nivel"
	end
	if Temporada.nivel(perfil) < nivel then
		return `Llegá al nivel {nivel} del pase`
	end
	local p = Temporada.premio(s.numero, nivel)
	if p.tipo == "unidad" then
		if not p.id then
			return "El personaje exclusivo llega pronto"
		end
		if #perfil.units >= Unidades.MAX_INVENTARIO then
			return "Inventario de unidades lleno"
		end
		Unidades.agregar(perfil, p.id)
	elseif p.tipo == "nucleos" then
		perfil.cores += p.cantidad
	elseif p.tipo == "fichas" then
		perfil.fichasRasgo = (perfil.fichasRasgo or 0) + p.cantidad
	elseif p.tipo == "cristales" then
		perfil.cristales = (perfil.cristales or 0) + p.cantidad
	elseif p.tipo == "objeto" then
		if Objetos.tiene(perfil, p.id) then
			perfil.gems += Temporada.GEMAS_OBJETO_REPETIDO
		else
			table.insert(perfil.ownedItemIds, p.id)
		end
	else
		perfil.gems += p.cantidad
	end
	table.insert(s.reclamados, nivel)
	return nil
end

-- Lo que muestran los paneles de Misiones y Pase.
function Temporada.resumen(perfil, t: number)
	local s = Temporada.actualizar(perfil, t)
	local function lista(nombre)
		local r = {}
		for _, m in s[nombre] do
			local meta = Temporada.meta(nombre, m.id)
			table.insert(r, { texto = string.format(TAREA[m.id].texto, meta), progreso = m.progreso, meta = meta, reclamada = m.reclamada })
		end
		return r
	end
	local premios = {}
	for nivel = 1, Temporada.NIVELES do
		premios[nivel] = Temporada.premio(s.numero, nivel)
	end
	return {
		diarias = lista("diarias"),
		semanales = lista("semanales"),
		premioDiaria = Temporada.PREMIO.diaria,
		premioSemanal = Temporada.PREMIO.semanal,
		finDia = Temporada.DIA - t % Temporada.DIA,
		finSemana = Temporada.SEMANA - (t - Temporada.LUNES) % Temporada.SEMANA,
		pase = {
			numero = s.numero,
			xp = s.xp,
			nivel = Temporada.nivel(perfil),
			xpNivel = Temporada.XP_NIVEL,
			niveles = Temporada.NIVELES,
			reclamados = s.reclamados,
			premios = premios,
			fin = Temporada.INICIO + s.numero * Temporada.DURACION - t,
		},
	}
end

return Temporada
