-- Todos los personajes: los de heroes.json y sus evoluciones del 2D (evolutions.json) como personajes
-- propios, una rareza más alta, que sólo se obtienen por crafteo (docs/INVOCACIONES.md).
local Data = script.Parent.Data
local heroes = require(Data.heroes)
local evoluciones = require(Data.evolutions)

local Personajes = {}

Personajes.RAREZAS = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
Personajes.NOMBRE_RAREZA = { Common = "Común", Rare = "Raro", Epic = "Épico", Legendary = "Legendario", Mythic = "Mítico", Secret = "Secreto" }

local function siguiente(rareza: string): string?
	local i = table.find(Personajes.RAREZAS, rareza)
	return i and Personajes.RAREZAS[i + 1]
end

local todos = {}
local evolucionDe = {} -- [idBase] = id evolucionado
for id, h in heroes do
	todos[id] = h
	local e = evoluciones[id]
	local rareza = siguiente(h.rarity)
	if e and rareza then
		local c = table.clone(h)
		c.id = e.id
		c.base = id
		c.rarity = rareza
		c.name = (e.name:gsub("^Evolucion (.+)$", "%1 Evo"))
		c.damage = h.damage * (1 + (e.stats.damage or 0))
		c.fireRate = h.fireRate * (1 + (e.stats.fireRate or 0))
		c.range = h.range * (1 + (e.stats.range or 0))
		c.critChance = (h.critChance or 5) + (e.stats.critChance or 0)
		c.canSeeStealth = h.canSeeStealth or e.canSeeStealth or e.id == "iron_spider"
		c.evolutionId = nil
		todos[c.id] = c
		evolucionDe[id] = c.id
	end
end

-- Exclusivos (Odin del pase, Knull de la raid): no son invocables (invocables() recorre sólo heroes.json).
for id, h in require(script.Parent.Exclusivos) do
	todos[id] = h
end

Personajes.todos = todos

function Personajes.de(id: string)
	return todos[id]
end

-- Id del personaje evolucionado de `id`, o nil si no evoluciona.
function Personajes.evolucion(id: string): string?
	return evolucionDe[id]
end

-- Id del personaje base (el mismo si no es una evolución): plantilla de modelo y kit de habilidades.
function Personajes.base(id: string): string
	local c = todos[id]
	return c and c.base or id
end

-- Personajes que pueden salir en una invocación (los de heroes.json), por rareza y ordenados por id.
function Personajes.invocables(): { [string]: { string } }
	local r = {}
	for id, h in heroes do
		r[h.rarity] = r[h.rarity] or {}
		table.insert(r[h.rarity], id)
	end
	for _, lista in r do
		table.sort(lista)
	end
	return r
end

return Personajes
