-- Dinero de la partida: costo de colocar y las 5 mejoras con nombre de cada personaje
-- (docs/INVOCACIONES.md). Reemplaza los 100 niveles de partida del 2D. Módulo puro.
local Data = script.Parent.Data
local heroesBase = require(Data.heroes)

local Mejoras = {}

Mejoras.DINERO_INICIAL = 1200
Mejoras.BONO_OLEADA, Mejoras.BONO_VIDA = 100, 25 -- al superar una oleada: +100 y +25 por vida restante
Mejoras.MAXIMO = 5
Mejoras.MEJORA_HABILIDAD = 2 -- la habilidad del personaje se desbloquea con esta mejora
Mejoras.COLOCAR = { Common = 400, Rare = 750, Epic = 1300, Legendary = 2200, Mythic = 3800, Secret = 6000 }
Mejoras.FACTOR_EVOLUCIONADO = 1.5
Mejoras.RECARGO_HABILIDAD = 1.3 -- las mejoras que desbloquean o potencian la habilidad cuestan más

-- Plantilla de las 5 mejoras: suma de daño, alcance y cadencia (fracciones), potencia de la habilidad
-- y multiplicador de precio sobre el costo de colocar.
local PLANTILLA = {
	{ nombre = "Entrenamiento", dano = 0.20, precio = 0.6 },
	{ nombre = "%s", alcance = 0.10, habilidad = true, precio = 0.9 },
	{ nombre = "Equipo avanzado", dano = 0.25, cadencia = 0.10, precio = 1.3 },
	{ nombre = "%s potenciada", dano = 0.15, potencia = 1.25, habilidad = true, precio = 1.8 },
	{ nombre = "Poder máximo", dano = 0.30, alcance = 0.10, cadencia = 0.15, potencia = 1.5, habilidad = true, precio = 2.5 },
}

-- Ajustes de precio por personaje para casos especiales: [id] = { [mejora] = factor }.
-- Ej.: { scarlet_witch = { [5] = 3 } } triplica su quinta mejora. Vacío hasta que el usuario los defina.
Mejoras.AJUSTES = {}

-- Rango del costo del 2D por rareza: indica el poder relativo del personaje dentro de su rareza.
local rango = {}
for _, h in heroesBase do
	local r = rango[h.rarity] or { min = math.huge, max = -math.huge }
	r.min, r.max = math.min(r.min, h.cost), math.max(r.max, h.cost)
	rango[h.rarity] = r
end

-- ±25 % según el costo del 2D dentro de su rareza (0,75 el más barato, 1,25 el más caro).
local function factorPoder(config): number
	local base = heroesBase[config.base or config.id] or config
	local r = rango[base.rarity]
	if not r or r.max == r.min then
		return 1
	end
	return 0.75 + 0.5 * (base.cost - r.min) / (r.max - r.min)
end

local function redondear(n: number): number
	return math.floor(n / 10 + 0.5) * 10
end

function Mejoras.costoColocar(config): number
	local base = Mejoras.COLOCAR[config.rarity] or Mejoras.COLOCAR.Common
	return redondear(base * factorPoder(config) * (if config.base then Mejoras.FACTOR_EVOLUCIONADO else 1))
end

local function nombreHabilidad(config): string
	local a = config.ability
	if type(a) ~= "string" or a == "" then
		return "Habilidad"
	end
	-- "CARCAJ TÁCTICO" → "Carcaj táctico" (string.lower no cambia las letras con tilde)
	local minus = string.lower(a)
	for mayus, min in { ["Á"] = "á", ["É"] = "é", ["Í"] = "í", ["Ó"] = "ó", ["Ú"] = "ú", ["Ñ"] = "ñ", ["Ü"] = "ü" } do
		minus = string.gsub(minus, mayus, min)
	end
	return string.upper(string.sub(minus, 1, 1)) .. string.sub(minus, 2)
end

-- Las 5 mejoras del personaje: { nombre, costo, dano, alcance, cadencia, potencia, habilidad }.
function Mejoras.lista(config)
	local colocar = Mejoras.costoColocar(config)
	local ajustes = Mejoras.AJUSTES[config.id] or Mejoras.AJUSTES[config.base or ""] or {}
	local r = {}
	for i, p in PLANTILLA do
		local m = table.clone(p)
		m.nombre = string.format(p.nombre, nombreHabilidad(config))
		m.costo = redondear(colocar * p.precio * (if p.habilidad then Mejoras.RECARGO_HABILIDAD else 1) * (ajustes[i] or 1))
		r[i] = m
	end
	return r
end

-- Efecto acumulado con `n` mejoras compradas (0 a 5).
function Mejoras.efecto(config, n: number)
	local e = { dano = 0, alcance = 0, cadencia = 0, potencia = 1, habilidad = n >= Mejoras.MEJORA_HABILIDAD }
	for i = 1, math.min(n, Mejoras.MAXIMO) do
		local p = PLANTILLA[i]
		e.dano += p.dano or 0
		e.alcance += p.alcance or 0
		e.cadencia += p.cadencia or 0
		e.potencia = math.max(e.potencia, p.potencia or 1)
	end
	return e
end

-- Descripción corta de una mejora para la interfaz.
function Mejoras.descripcion(m): string
	local partes = {}
	if m.dano then
		table.insert(partes, `+{math.round(m.dano * 100)}% daño`)
	end
	if m.alcance then
		table.insert(partes, `+{math.round(m.alcance * 100)}% alcance`)
	end
	if m.cadencia then
		table.insert(partes, `+{math.round(m.cadencia * 100)}% cadencia`)
	end
	if m.potencia then
		table.insert(partes, `habilidad ×{m.potencia}`)
	elseif m.habilidad then
		table.insert(partes, "desbloquea la habilidad")
	end
	return table.concat(partes, ", ")
end

return Mejoras
