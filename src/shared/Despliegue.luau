-- Reglas de despliegue del 2D/3D (TerrainRules.js, RangePattern.js y placementError de combat.js).
-- Módulo puro en píxeles del 2D: el servidor valida con él y el cliente lo usa para la vista previa.
local Despliegue = {}

local AGUA, PASTO, CAMINO, MONTANA, BOSQUE, BLOQUEADO, VEREDA, DETALLE = 0, 1, 2, 3, 4, 5, 11, 12
local LEYENDA = { W = AGUA, G = PASTO, S = VEREDA, P = CAMINO, M = MONTANA, B = BLOQUEADO, X = BLOQUEADO }
local NOMBRES = {
	[AGUA] = "Agua",
	[PASTO] = "Pasto",
	[CAMINO] = "Camino",
	[MONTANA] = "Montaña",
	[BOSQUE] = "Bosque",
	[BLOQUEADO] = "Bloqueado",
	[VEREDA] = "Vereda",
	[DETALLE] = "Detalle urbano",
}
local ALIAS = { [VEREDA] = PASTO, [DETALLE] = PASTO, [BOSQUE] = PASTO }

local function nombreTerreno(t)
	return NOMBRES[t] or ("Terreno " .. tostring(t))
end

-- Centro de la celda que contiene el punto.
function Despliegue.celda(x: number, y: number, lado: number): (number, number)
	return math.floor(x / lado) * lado + lado / 2, math.floor(y / lado) * lado + lado / 2
end

function Despliegue.terreno(nivel, x: number, y: number): number?
	local lado = nivel.rendering.tileSize
	local fila = nivel.rendering.terrainRows[math.floor(y / lado) + 1]
	local col = math.floor(x / lado) + 1
	if not fila or x < 0 or col > #fila then
		return nil
	end
	return LEYENDA[fila:sub(col, col)] or PASTO
end

function Despliegue.puedeEnTerreno(config, t: number?): boolean
	if t == nil or t == CAMINO or t == BLOQUEADO then
		return false
	end
	return table.find(config.allowedTerrains or { PASTO }, ALIAS[t] or t) ~= nil
end

-- isPointInRangePattern del 2D.
function Despliegue.enAlcance(ox: number, oy: number, px: number, py: number, alcance: number, patron: string?, escala: number?): boolean
	local dx, dy = px - ox, py - oy
	local distancia = math.sqrt(dx * dx + dy * dy)
	if distancia > alcance then
		return false
	end
	local geo = alcance * (escala or 1)
	local carril = math.max(18, geo * 0.16)
	if patron == "ring" then
		return distancia >= geo * 0.38
	elseif patron == "cross" then
		return math.abs(dx) <= carril or math.abs(dy) <= carril
	elseif patron == "x" then
		return math.abs(math.abs(dx) - math.abs(dy)) <= carril
	end
	return true
end

local function puntoMasCercano(x, y, ruta)
	local mejor, mejorD = nil, math.huge
	for i = 2, #ruta do
		local a, b = ruta[i - 1], ruta[i]
		local dx, dy = b.x - a.x, b.y - a.y
		local t = math.clamp(((x - a.x) * dx + (y - a.y) * dy) / (dx * dx + dy * dy), 0, 1)
		local qx, qy = a.x + t * dx, a.y + t * dy
		local d = math.sqrt((x - qx) ^ 2 + (y - qy) ^ 2)
		if d < mejorD then
			mejor, mejorD = { x = qx, y = qy }, d
		end
	end
	return mejor
end

-- placementError del 3D. unidades: { { uid, heroe, x, y } } en píxeles.
-- Devuelve nil si se puede, o el mensaje de error y la celda ajustada.
function Despliegue.error(config, x: number, y: number, nivel, ruta, unidades, moviendoUid: number?): (string?, number, number)
	local lado = nivel.rendering.tileSize
	local cx, cy = Despliegue.celda(x, y, lado)
	local t = Despliegue.terreno(nivel, cx, cy)
	if t == nil then
		return "Fuera del mapa", cx, cy
	end
	if not Despliegue.puedeEnTerreno(config, t) then
		local permitidos = {}
		for _, p in config.allowedTerrains or { PASTO } do
			local n = nombreTerreno(p)
			if not table.find(permitidos, n) then
				table.insert(permitidos, n)
			end
		end
		return `Requiere {table.concat(permitidos, ", ")}; esta celda es {nombreTerreno(t)}`, cx, cy
	end
	for _, u in unidades do
		if not moviendoUid and u.heroe == config.id then
			return "Este héroe ya está desplegado", cx, cy
		end
	end
	for _, u in unidades do
		if u.uid ~= moviendoUid and math.sqrt((u.x - cx) ^ 2 + (u.y - cy) ^ 2) < lado * 0.8 then
			return "Este espacio ya está ocupado", cx, cy
		end
	end
	local q = puntoMasCercano(cx, cy, ruta)
	if not q or not Despliegue.enAlcance(cx, cy, q.x, q.y, config.range, config.rangePattern) then
		return "El camino está fuera del alcance de este héroe", cx, cy
	end
	return nil, cx, cy
end

return Despliegue
