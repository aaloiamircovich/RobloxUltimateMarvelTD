-- Rasgos (traits) y grados (grades) de cada unidad (docs/RASGOS.md). Sistema propio del port.
-- Módulo puro: el azar entra como parámetro (función que devuelve [0, 1)).
local Rasgos = {}

Rasgos.RAREZAS = { "Común", "Raro", "Épico", "Mítico" }
-- prob en %, suman 100. Bonos: dano/alcance/cadencia en fracción, critico en puntos, dinero en fracción.
Rasgos.LISTA = {
	{ id = "fuerza1", nombre = "Fuerza I", rareza = "Común", prob = 16, dano = 0.05 },
	{ id = "fuerza2", nombre = "Fuerza II", rareza = "Común", prob = 8, dano = 0.10 },
	{ id = "fuerza3", nombre = "Fuerza III", rareza = "Épico", prob = 3, dano = 0.15 },
	{ id = "vista1", nombre = "Vista I", rareza = "Común", prob = 16, alcance = 0.05 },
	{ id = "vista2", nombre = "Vista II", rareza = "Común", prob = 8, alcance = 0.10 },
	{ id = "vista3", nombre = "Vista III", rareza = "Épico", prob = 3, alcance = 0.15 },
	{ id = "rapidez1", nombre = "Rapidez I", rareza = "Común", prob = 16, cadencia = 0.05 },
	{ id = "rapidez2", nombre = "Rapidez II", rareza = "Común", prob = 8, cadencia = 0.10 },
	{ id = "rapidez3", nombre = "Rapidez III", rareza = "Épico", prob = 3, cadencia = 0.15 },
	{ id = "mercenario", nombre = "Mercenario", rareza = "Raro", prob = 9, dinero = 0.10 },
	{ id = "certero", nombre = "Certero", rareza = "Raro", prob = 7, critico = 8 },
	{ id = "cosmico", nombre = "Cósmico", rareza = "Mítico", prob = 1.5, dano = 0.20, alcance = 0.10, cadencia = 0.10 },
	{ id = "vibranium", nombre = "Vibranium", rareza = "Mítico", prob = 1.5, dano = 0.25, cadencia = 0.15, alcance = 0.05 },
}
local RASGO = {}
for _, r in Rasgos.LISTA do
	RASGO[r.id] = r
end
Rasgos.GARANTIA = 50 -- tiradas sin mítico: la siguiente es mítica

Rasgos.GRADOS = {
	{ id = "C", bono = -0.02, prob = 30 },
	{ id = "B", bono = 0, prob = 35 },
	{ id = "A", bono = 0.04, prob = 22 },
	{ id = "S", bono = 0.08, prob = 10 },
	{ id = "S+", bono = 0.12, prob = 3 },
}
local GRADO = {}
for _, g in Rasgos.GRADOS do
	GRADO[g.id] = g
end
Rasgos.STATS = { "dano", "alcance", "cadencia" }
Rasgos.GRADO_INICIAL = "B"

function Rasgos.de(id: string?)
	return id and RASGO[id]
end

function Rasgos.rango(id: string?): number
	local r = id and RASGO[id]
	return if r then table.find(Rasgos.RAREZAS, r.rareza) or 0 else 0
end

-- Costo en cristales de tirar los grados: 1, ×2 por cada stat bloqueado (máximo 2 bloqueados).
function Rasgos.costoGrados(bloqueados: number): number
	return 2 ^ bloqueados
end

function Rasgos.grados(u)
	local g = {}
	for _, s in Rasgos.STATS do
		g[s] = (u.grados and GRADO[u.grados[s]] and u.grados[s]) or Rasgos.GRADO_INICIAL
	end
	return g
end

-- Frontera de confianza: rasgo y grados de una unidad guardada.
function Rasgos.normalizarUnidad(crudo, u)
	if type(crudo.rasgo) == "string" and RASGO[crudo.rasgo] then
		u.rasgo = crudo.rasgo
	end
	if type(crudo.grados) == "table" then
		local g = {}
		for _, s in Rasgos.STATS do
			if GRADO[crudo.grados[s]] then
				g[s] = crudo.grados[s]
			end
		end
		if next(g) then
			u.grados = g
		end
	end
end

-- Multiplicadores sobre los stats de combate.
function Rasgos.aplicar(stats, u)
	local r = u.rasgo and RASGO[u.rasgo] or {}
	local g = Rasgos.grados(u)
	stats.damage *= (1 + (r.dano or 0)) * (1 + GRADO[g.dano].bono)
	stats.range *= (1 + (r.alcance or 0)) * (1 + GRADO[g.alcance].bono)
	stats.fireRate *= (1 + (r.cadencia or 0)) * (1 + GRADO[g.cadencia].bono)
	stats.critChance = (stats.critChance or 0) + (r.critico or 0)
	return stats
end

-- Bono de dinero por enemigo derrotado por esta unidad.
function Rasgos.dinero(u): number
	local r = u.rasgo and RASGO[u.rasgo]
	return r and r.dinero or 0
end

local function sortear(lista, azar: () -> number)
	local total = 0
	for _, x in lista do
		total += x.prob
	end
	local t = azar() * total
	for _, x in lista do
		t -= x.prob
		if t < 0 then
			return x
		end
	end
	return lista[#lista]
end

-- Tira el rasgo de la unidad con una ficha. Devuelve el rasgo nuevo o un error.
function Rasgos.tirarRasgo(perfil, u, azar: () -> number): (any?, string?)
	if (perfil.fichasRasgo or 0) < 1 then
		return nil, "No tenés fichas de rasgo"
	end
	perfil.fichasRasgo -= 1
	local pozo = Rasgos.LISTA
	if (perfil.pityRasgo or 0) + 1 >= Rasgos.GARANTIA then
		pozo = {}
		for _, r in Rasgos.LISTA do
			if r.rareza == "Mítico" then
				table.insert(pozo, r)
			end
		end
	end
	local r = sortear(pozo, azar)
	perfil.pityRasgo = if r.rareza == "Mítico" then 0 else (perfil.pityRasgo or 0) + 1
	u.rasgo = r.id
	return r, nil
end

-- Tira los grados no bloqueados. bloqueos: { [stat] = true } (hasta 2).
function Rasgos.tirarGrados(perfil, u, bloqueos, azar: () -> number): string?
	local n = 0
	for _, s in Rasgos.STATS do
		if bloqueos[s] then
			n += 1
		end
	end
	if n > 2 then
		return "Se pueden bloquear hasta 2 stats"
	end
	local costo = Rasgos.costoGrados(n)
	if (perfil.cristales or 0) < costo then
		return `Faltan {costo - (perfil.cristales or 0)} cristales`
	end
	perfil.cristales -= costo
	local g = Rasgos.grados(u)
	for _, s in Rasgos.STATS do
		if not bloqueos[s] then
			g[s] = sortear(Rasgos.GRADOS, azar).id
		end
	end
	u.grados = g
	return nil
end

-- Texto corto del rasgo para la interfaz.
function Rasgos.descripcion(id: string?): string
	local r = id and RASGO[id]
	if not r then
		return "Sin rasgo"
	end
	local partes = {}
	if r.dano then
		table.insert(partes, `+{math.floor(r.dano * 100 + 0.5)}% daño`)
	end
	if r.alcance then
		table.insert(partes, `+{math.floor(r.alcance * 100 + 0.5)}% alcance`)
	end
	if r.cadencia then
		table.insert(partes, `+{math.floor(r.cadencia * 100 + 0.5)}% cadencia`)
	end
	if r.critico then
		table.insert(partes, `+{r.critico}% crítico`)
	end
	if r.dinero then
		table.insert(partes, `+{math.floor(r.dinero * 100 + 0.5)}% dinero al derrotar`)
	end
	return table.concat(partes, ", ")
end

return Rasgos
