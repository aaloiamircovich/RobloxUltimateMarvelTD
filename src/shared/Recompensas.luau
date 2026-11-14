-- Premio diario (racha de 7 días), códigos canjeables y logros (docs/RECOMPENSAS.md). Módulo puro: el tiempo
-- entra como parámetro. Pruebas en src/server/Pruebas/Recompensas.spec.luau.
local Personajes = require(script.Parent.Personajes)

local Recompensas = {}

local DIA = 86400
local function diaDe(t: number): number
	return math.floor(t / DIA) -- cambia a las 00:00 UTC
end

--------------------------------------------------------------------------------
-- Premios: { gemas, nucleos, fichasRasgo, cristales }
--------------------------------------------------------------------------------
function Recompensas.dar(perfil, premio)
	perfil.gems += premio.gemas or 0
	perfil.cores += premio.nucleos or 0
	perfil.fichasRasgo += premio.fichasRasgo or 0
	perfil.cristales += premio.cristales or 0
end

function Recompensas.texto(premio): string
	local partes = {}
	if premio.gemas then
		table.insert(partes, `{premio.gemas} 💎`)
	end
	if premio.nucleos then
		table.insert(partes, `{premio.nucleos} 🔷`)
	end
	if premio.fichasRasgo then
		table.insert(partes, `{premio.fichasRasgo} 🎫`)
	end
	if premio.cristales then
		table.insert(partes, `{premio.cristales} 💠`)
	end
	return table.concat(partes, " + ")
end

--------------------------------------------------------------------------------
-- Premio diario: racha de 7 días. Faltar un día vuelve al día 1; después del 7 se repite.
--------------------------------------------------------------------------------
Recompensas.DIARIO = {
	{ gemas = 30 },
	{ fichasRasgo = 1, cristales = 2 },
	{ gemas = 50 },
	{ nucleos = 1 },
	{ gemas = 80, fichasRasgo = 2 },
	{ nucleos = 2, cristales = 4 },
	{ gemas = 200, nucleos = 3, fichasRasgo = 2 },
}

-- Qué día de la racha toca hoy y si ya se reclamó.
function Recompensas.estadoDiario(perfil, t: number)
	local d = perfil.diario
	local hoy = diaDe(t)
	local reclamado = d.ultimoDia == hoy
	local siguiente
	if reclamado then
		siguiente = d.racha
	elseif d.ultimoDia == hoy - 1 then
		siguiente = d.racha % #Recompensas.DIARIO + 1
	else
		siguiente = 1
	end
	return { dia = siguiente, reclamado = reclamado, finDia = (hoy + 1) * DIA }
end

function Recompensas.reclamarDiario(perfil, t: number): (any?, string?)
	local e = Recompensas.estadoDiario(perfil, t)
	if e.reclamado then
		return nil, "Ya reclamaste el premio de hoy"
	end
	local premio = Recompensas.DIARIO[e.dia]
	perfil.diario.ultimoDia = diaDe(t)
	perfil.diario.racha = e.dia
	Recompensas.dar(perfil, premio)
	return premio, nil
end

--------------------------------------------------------------------------------
-- Códigos: se agregan acá y se publica el lugar. Cada cuenta canjea cada código una sola vez.
-- vence: os.time() en UTC o nil (sin vencimiento).
--------------------------------------------------------------------------------
Recompensas.CODIGOS = {
	BIENVENIDO = { premio = { gemas = 100 } },
	HEROES2026 = { premio = { gemas = 150, fichasRasgo = 1 }, vence = 1798761600 }, -- hasta el 01/01/2027
}

function Recompensas.canjear(perfil, texto: string, t: number): (any?, string?)
	if type(texto) ~= "string" or #texto > 40 then
		return nil, "Código inválido"
	end
	local codigo = string.upper((string.gsub(texto, "%s", "")))
	local c = Recompensas.CODIGOS[codigo]
	if not c then
		return nil, "Ese código no existe"
	end
	if c.vence and t >= c.vence then
		return nil, "Ese código ya venció"
	end
	if perfil.codigos[codigo] then
		return nil, "Ya canjeaste ese código"
	end
	perfil.codigos[codigo] = true
	Recompensas.dar(perfil, c.premio)
	return c.premio, nil
end

--------------------------------------------------------------------------------
-- Logros: el progreso se calcula del perfil; se reclaman con un botón.
--------------------------------------------------------------------------------
local function actosGanados(perfil): number
	local n = 0
	for _, a in perfil.acts do
		n += a.normal or 0
	end
	return n
end
local function mapasCompletos(perfil): number
	local n = 0
	for _, a in perfil.acts do
		if (a.normal or 0) >= 5 then
			n += 1
		end
	end
	return n
end
local function actosPesadilla(perfil): number
	local n = 0
	for _, a in perfil.acts do
		n += a.pesadilla or 0
	end
	return n
end
local ORDEN_RAREZA = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Secret = 6 }
local function unidadesDe(perfil, rarezaMinima: string): number
	local n = 0
	for _, u in perfil.units do
		local h = Personajes.todos[u.heroId]
		if h and (ORDEN_RAREZA[h.rarity] or 0) >= ORDEN_RAREZA[rarezaMinima] then
			n += 1
		end
	end
	return n
end
local function evoluciones(perfil): number
	local n = 0
	for _, u in perfil.units do
		if Personajes.base(u.heroId) ~= u.heroId then
			n += 1
		end
	end
	return n
end

local function L(id, categoria, nombre, meta, premio, valor)
	return { id = id, categoria = categoria, nombre = nombre, meta = meta, premio = premio, valor = valor }
end
Recompensas.LOGROS = {
	L("acto_1", "Historia", "Ganá tu primer acto", 1, { gemas = 50 }, actosGanados),
	L("actos_10", "Historia", "Ganá 10 actos", 10, { gemas = 150 }, actosGanados),
	L("mapa_1", "Historia", "Completá un mapa (5 actos)", 1, { gemas = 100, nucleos = 1 }, mapasCompletos),
	L("mapas_4", "Historia", "Completá 4 mapas", 4, { gemas = 300, nucleos = 3 }, mapasCompletos),
	L("pesadilla_1", "Historia", "Ganá un acto en Pesadilla", 1, { gemas = 150 }, actosPesadilla),
	L("pesadilla_10", "Historia", "Ganá 10 actos en Pesadilla", 10, { gemas = 400, nucleos = 2 }, actosPesadilla),
	L("unidades_10", "Colección", "Juntá 10 unidades", 10, { gemas = 100 }, function(p)
		return #p.units
	end),
	L("unidades_50", "Colección", "Juntá 50 unidades", 50, { gemas = 250 }, function(p)
		return #p.units
	end),
	L("legendario", "Colección", "Conseguí un Legendario", 1, { gemas = 100 }, function(p)
		return unidadesDe(p, "Legendary")
	end),
	L("mitico", "Colección", "Conseguí un Mítico", 1, { gemas = 300 }, function(p)
		return unidadesDe(p, "Mythic")
	end),
	L("evolucion", "Colección", "Evolucioná una unidad", 1, { nucleos = 2 }, evoluciones),
	L("enemigos_500", "Combate", "Derrotá 500 enemigos", 500, { gemas = 100 }, function(p)
		return p.estadisticas.enemigos
	end),
	L("enemigos_5000", "Combate", "Derrotá 5.000 enemigos", 5000, { gemas = 300 }, function(p)
		return p.estadisticas.enemigos
	end),
	L("enemigos_25000", "Combate", "Derrotá 25.000 enemigos", 25000, { gemas = 500, nucleos = 3 }, function(p)
		return p.estadisticas.enemigos
	end),
	L("jefes_10", "Combate", "Derrotá 10 jefes", 10, { gemas = 150 }, function(p)
		return p.estadisticas.jefes
	end),
	L("jefes_100", "Combate", "Derrotá 100 jefes", 100, { gemas = 500, fichasRasgo = 3 }, function(p)
		return p.estadisticas.jefes
	end),
	L("infinito_25", "Combate", "Llegá a la oleada 25 en Infinito", 25, { gemas = 150 }, function(p)
		return p.modeRecords.survival.bestWave
	end),
	L("infinito_50", "Combate", "Llegá a la oleada 50 en Infinito", 50, { gemas = 400, cristales = 6 }, function(p)
		return p.modeRecords.survival.bestWave
	end),
}
local porId = {}
for _, l in Recompensas.LOGROS do
	porId[l.id] = l
end

-- Lista para la interfaz: progreso, meta, premio y si ya se reclamó.
function Recompensas.estadoLogros(perfil)
	local r = {}
	for _, l in Recompensas.LOGROS do
		table.insert(r, {
			id = l.id,
			categoria = l.categoria,
			nombre = l.nombre,
			meta = l.meta,
			progreso = math.min(l.meta, l.valor(perfil)),
			premio = l.premio,
			reclamado = perfil.logros[l.id] == true,
		})
	end
	return r
end

function Recompensas.reclamarLogro(perfil, id: string): (any?, string?)
	local l = type(id) == "string" and porId[id]
	if not l then
		return nil, "Ese logro no existe"
	end
	if perfil.logros[id] then
		return nil, "Ya reclamaste ese logro"
	end
	if l.valor(perfil) < l.meta then
		return nil, "Todavía no lo completaste"
	end
	perfil.logros[id] = true
	Recompensas.dar(perfil, l.premio)
	return l.premio, nil
end

-- Contadores de combate para los logros (los suma la partida).
function Recompensas.contar(perfil, evento: string, n: number)
	if evento == "derrota" then
		perfil.estadisticas.enemigos += n
	elseif evento == "jefe" then
		perfil.estadisticas.jefes += n
	end
end

--------------------------------------------------------------------------------
-- Normalización (frontera de confianza del DataStore)
--------------------------------------------------------------------------------
local function entero(v, minimo: number, maximo: number): number
	v = tonumber(v)
	if not v or v ~= v then
		return minimo
	end
	return math.clamp(math.floor(v), minimo, maximo)
end

function Recompensas.normalizar(datos)
	local d = if type(datos) == "table" then datos else {}
	local r = {
		diario = { ultimoDia = -1, racha = 0 },
		codigos = {},
		logros = {},
		estadisticas = { enemigos = 0, jefes = 0 },
	}
	if type(d.diario) == "table" then
		r.diario.ultimoDia = entero(d.diario.ultimoDia, -1, 1e7)
		r.diario.racha = entero(d.diario.racha, 0, #Recompensas.DIARIO)
	end
	for _, campo in { "codigos", "logros" } do
		if type(d[campo]) == "table" then
			for k, v in d[campo] do
				if type(k) == "string" and v == true and #k <= 40 then
					r[campo][k] = true
				end
			end
		end
	end
	if type(d.estadisticas) == "table" then
		r.estadisticas.enemigos = entero(d.estadisticas.enemigos, 0, 1e12)
		r.estadisticas.jefes = entero(d.estadisticas.jefes, 0, 1e9)
	end
	return r
end

return Recompensas
