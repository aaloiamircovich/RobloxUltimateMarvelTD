-- Raids cooperativas (docs/RAIDS.md): jefe de la semana con fases, llaves diarias, premios, fragmentos y
-- misiones de raid semanales. Sistema propio del port. Módulo puro: la hora y el azar entran como parámetros.
local Temporada = require(script.Parent.Temporada)
local Objetos = require(script.Parent.Objetos)
local items = require(script.Parent.Data.items)

local Raid = {}

Raid.LLAVES_DIA = 3
Raid.OLEADAS_ESBIRROS = 5 -- después viene el jefe (oleada 6)
-- Jefe de cada semana, en el mapa de su tema (Mapa.JUGABLES).
Raid.JEFES = {
	{ id = "thanos_final", mapa = "level_1" },
	{ id = "galactus", mapa = "level_2" },
	{ id = "apocalypse", mapa = "level_3" },
	{ id = "dormammu", mapa = "level_4" },
}
-- Vida del jefe: daño (antes de armadura) que tiene que hacer un jugador solo bien armado, descontando la
-- armadura del jefe para que todos sean igual de duros; +60 % por jugador extra (el daño crece 100 %).
-- Medido: con 1 jugador, 6 oleadas y 3.000 de dinero inicial se hacen ~4.000–7.000 de daño crudo.
Raid.OBJETIVO, Raid.VIDA_POR_JUGADOR = 6000, 0.6
Raid.DINERO = 3000 -- dinero inicial de la raid (una partida normal empieza con 1.200)
Raid.VELOCIDAD_JEFE = 0.45
Raid.FASES = { 0.66, 0.33 } -- al bajar de cada umbral: refuerzos y furia
Raid.REFUERZOS, Raid.FURIA = 6, 1.3
Raid.PREMIO = { gemas = 150, nucleos = 2, fragmentos = 10 }
Raid.FRAGMENTOS_DERROTA = 2
Raid.PROB_OBJETO = { { "Mythic", 0.05 }, { "Legendary", 0.20 } } -- se tira de la más rara a la más común
Raid.FRAGMENTOS_UNIDAD = 100
-- Personaje exclusivo de raid: todavía no existe; los fragmentos se guardan hasta entonces.
Raid.EXCLUSIVA = nil :: string?
Raid.MISIONES = {
	{ id = "ganar", texto = "Ganá %d raids", meta = 3 },
	{ id = "jugar", texto = "Jugá %d raids", meta = 5 },
	{ id = "dano", texto = "Hacé %d de daño a jefes de raid", meta = 30000 }, -- ~3.000 por raid con la vida actual
}
Raid.PREMIO_MISION = { gemas = 80, fragmentos = 10 }

function Raid.semana(t: number): number
	return Temporada.semana(t)
end

function Raid.jefe(semana: number)
	return Raid.JEFES[semana % #Raid.JEFES + 1]
end

function Raid.vidaJefe(armadura: number?, jugadores: number): number
	local a = armadura or 0
	if a > 1 then
		a /= 100 -- como Combate.recibir: algunos datos del 2D la traen en porcentaje
	end
	local vida = Raid.OBJETIVO * (1 - math.clamp(a, 0, 0.85)) * (1 + Raid.VIDA_POR_JUGADOR * (math.max(1, jugadores) - 1))
	return math.floor(vida / 100 + 0.5) * 100
end

-- Umbrales de fase cruzados al pasar de `antes` a `ahora` (fracciones de vida).
function Raid.fasesCruzadas(antes: number, ahora: number): number
	local n = 0
	for _, u in Raid.FASES do
		if antes > u and ahora <= u then
			n += 1
		end
	end
	return n
end

function Raid.nuevo()
	return { dia = -1, usadas = 0, semana = -1, progreso = { ganar = 0, jugar = 0, dano = 0 }, reclamadas = {}, fragmentos = 0 }
end

-- Frontera de confianza: lo que viene del DataStore.
function Raid.normalizar(crudo)
	local r = Raid.nuevo()
	if type(crudo) ~= "table" then
		return r
	end
	local function n(v, maximo)
		local x = tonumber(v)
		return if x and x == x then math.clamp(math.floor(x), 0, maximo) else 0
	end
	r.dia = if tonumber(crudo.dia) then math.floor(crudo.dia) else -1
	r.semana = if tonumber(crudo.semana) then math.floor(crudo.semana) else -1
	r.usadas = n(crudo.usadas, Raid.LLAVES_DIA)
	r.fragmentos = n(crudo.fragmentos, 1e6)
	if type(crudo.progreso) == "table" then
		for _, m in Raid.MISIONES do
			r.progreso[m.id] = n(crudo.progreso[m.id], m.meta)
		end
	end
	if type(crudo.reclamadas) == "table" then
		for _, m in Raid.MISIONES do
			if crudo.reclamadas[m.id] == true then
				r.reclamadas[m.id] = true
			end
		end
	end
	return r
end

-- Renueva las llaves cada día y las misiones cada semana; los fragmentos se conservan.
function Raid.actualizar(perfil, t: number)
	local r = perfil.raid
	local d, w = Temporada.dia(t), Raid.semana(t)
	if r.dia ~= d then
		r.dia, r.usadas = d, 0
	end
	if r.semana ~= w then
		r.semana, r.progreso, r.reclamadas = w, { ganar = 0, jugar = 0, dano = 0 }, {}
	end
	return r
end

function Raid.llaves(perfil, t: number): number
	return Raid.LLAVES_DIA - Raid.actualizar(perfil, t).usadas
end

function Raid.puedeEntrar(perfil, t: number): string?
	return if Raid.llaves(perfil, t) > 0 then nil else "No te quedan llaves de raid hoy (se renuevan a las 00:00 UTC)"
end

local function avanzar(r, id: string, n: number)
	local meta
	for _, m in Raid.MISIONES do
		if m.id == id then
			meta = m.meta
		end
	end
	r.progreso[id] = math.min(meta, (r.progreso[id] or 0) + n)
end

-- Fin de una raid para un jugador: gasta la llave, avanza misiones y entrega premios. azar(): [0, 1).
function Raid.terminar(perfil, gano: boolean, dano: number, t: number, azar: () -> number)
	local r = Raid.actualizar(perfil, t)
	r.usadas = math.min(Raid.LLAVES_DIA, r.usadas + 1)
	avanzar(r, "jugar", 1)
	avanzar(r, "dano", math.floor(dano))
	local premio = { gemas = 0, nucleos = 0, fragmentos = Raid.FRAGMENTOS_DERROTA }
	if gano then
		avanzar(r, "ganar", 1)
		premio.gemas, premio.nucleos, premio.fragmentos = Raid.PREMIO.gemas, Raid.PREMIO.nucleos, Raid.PREMIO.fragmentos
		-- Objeto raro que todavía no tenés.
		for _, par in Raid.PROB_OBJETO do
			if azar() < par[2] then
				local ids = {}
				for id, it in items do
					if it.rarity == par[1] and not Objetos.tiene(perfil, id) then
						table.insert(ids, id)
					end
				end
				if #ids > 0 then
					table.sort(ids)
					premio.objeto = ids[math.floor(azar() * #ids) + 1]
					table.insert(perfil.ownedItemIds, premio.objeto)
				end
				break
			end
		end
	end
	perfil.gems += premio.gemas
	perfil.cores += premio.nucleos
	r.fragmentos += premio.fragmentos
	return premio
end

function Raid.reclamar(perfil, id: string, t: number): string?
	local r = Raid.actualizar(perfil, t)
	local mision
	for _, m in Raid.MISIONES do
		if m.id == id then
			mision = m
		end
	end
	if not mision then
		return "Misión inválida"
	end
	if r.reclamadas[id] then
		return "Ya reclamaste esta misión"
	end
	if (r.progreso[id] or 0) < mision.meta then
		return "Todavía no completaste esta misión"
	end
	r.reclamadas[id] = true
	perfil.gems += Raid.PREMIO_MISION.gemas
	r.fragmentos += Raid.PREMIO_MISION.fragmentos
	return nil
end

-- Lo que muestra el panel de raids.
function Raid.resumen(perfil, t: number)
	local r = Raid.actualizar(perfil, t)
	local jefe = Raid.jefe(r.semana)
	local misiones = {}
	for _, m in Raid.MISIONES do
		table.insert(misiones, { id = m.id, texto = string.format(m.texto, m.meta), progreso = r.progreso[m.id] or 0, meta = m.meta, reclamada = r.reclamadas[m.id] == true })
	end
	return {
		jefe = jefe.id,
		mapa = jefe.mapa,
		llaves = Raid.LLAVES_DIA - r.usadas,
		llavesDia = Raid.LLAVES_DIA,
		fragmentos = r.fragmentos,
		fragmentosUnidad = Raid.FRAGMENTOS_UNIDAD,
		exclusiva = Raid.EXCLUSIVA,
		misiones = misiones,
		premioMision = Raid.PREMIO_MISION,
		premio = Raid.PREMIO,
		finDia = Temporada.DIA - t % Temporada.DIA,
		finSemana = Temporada.SEMANA - (t - Temporada.LUNES) % Temporada.SEMANA,
	}
end

return Raid
