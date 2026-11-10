-- Mapas jugables del 3D (getMission en src/game/missions.js): ruta en píxeles, grilla de terreno
-- numérica y conversión píxeles ↔ mundo. El cliente usa ruta, terreno y conversiones; construir() es del servidor.
local Data = script.Parent.Data

local Mapa = {}

Mapa.ESCALA = 1 / 8 -- studs por píxel del 2D: una baldosa de 32 px mide 4 studs
Mapa.ORIGEN = Vector3.new(300, 0, -40) -- lejos del HUB, que está en el centro
Mapa.ANCHO, Mapa.ALTO = 800, 600 -- tamaño lógico del 2D (combat-data.js)
Mapa.JUGABLES = { "level_1", "level_2", "level_3", "level_4" } -- PLAYABLE_MISSIONS del 3D

-- Códigos de TerrainRules.js del 2D.
local AGUA, PASTO, CAMINO, MONTANA, BOSQUE, BLOQUEADO, VEREDA, DETALLE = 0, 1, 2, 3, 4, 5, 11, 12
local LEYENDA = { W = AGUA, G = PASTO, S = VEREDA, P = CAMINO, M = MONTANA, B = BLOQUEADO, X = BLOQUEADO }

local ASPECTO = {
	[AGUA] = { color = Color3.fromRGB(52, 120, 190), alto = 0.6, material = Enum.Material.Glass },
	[BLOQUEADO] = { color = Color3.fromRGB(150, 150, 158), alto = 2.5, material = Enum.Material.Concrete },
	[CAMINO] = { color = Color3.fromRGB(205, 190, 160), alto = 1, material = Enum.Material.SmoothPlastic },
	[PASTO] = { color = Color3.fromRGB(96, 168, 82), alto = 1, material = Enum.Material.Grass },
	[MONTANA] = { color = Color3.fromRGB(72, 76, 86), alto = 1.2, material = Enum.Material.DiamondPlate },
	[BOSQUE] = { color = Color3.fromRGB(50, 120, 60), alto = 1.4, material = Enum.Material.Grass },
	[VEREDA] = { color = Color3.fromRGB(175, 175, 168), alto = 1.05, material = Enum.Material.Concrete },
	[DETALLE] = { color = Color3.fromRGB(120, 110, 140), alto = 1.1, material = Enum.Material.Slate },
}

-- origen: esquina del mapa en el mundo (cada partida tiene su copia en otro lugar); por defecto ORIGEN.
function Mapa.aMundo(x: number, y: number, origen: Vector3?): Vector3
	return (origen or Mapa.ORIGEN) + Vector3.new(x * Mapa.ESCALA, 1, y * Mapa.ESCALA)
end

function Mapa.aPixeles(p: Vector3, origen: Vector3?): (number, number)
	local d = (p - (origen or Mapa.ORIGEN)) / Mapa.ESCALA
	return d.X, d.Z
end

local function sinRepetidos(puntos)
	local limpia = {}
	for _, p in puntos do
		local u = limpia[#limpia]
		if not u or u.x ~= p.x or u.y ~= p.y then
			table.insert(limpia, p)
		end
	end
	return limpia
end

-- normalizeLevelPath del 2D: ruta "exacta" (Wakanda) o normalizePath, ortogonal con entrada y salida
-- 40 px fuera del mapa.
function Mapa.rutaPixeles(nivel): { { x: number, y: number } }
	local ancho, alto = Mapa.ANCHO, Mapa.ALTO
	local dentro = {}
	for _, p in nivel.path do
		table.insert(dentro, { x = math.clamp(p.x, 0, ancho), y = math.clamp(p.y, 0, alto) })
	end
	if nivel.rendering and nivel.rendering.pathMode == "exact" then
		return sinRepetidos(dentro)
	end
	local margen = 40
	local function fuera(p)
		if p.x <= 0 then
			return { x = -margen, y = p.y }
		elseif p.x >= ancho then
			return { x = ancho + margen, y = p.y }
		elseif p.y <= 0 then
			return { x = p.x, y = -margen }
		elseif p.y >= alto then
			return { x = p.x, y = alto + margen }
		end
		return { x = p.x, y = p.y }
	end
	local ruta = { fuera(dentro[1]), dentro[1] }
	for i = 2, #dentro do
		local prev, sig = ruta[#ruta], dentro[i]
		if prev.x ~= sig.x and prev.y ~= sig.y then
			table.insert(ruta, { x = sig.x, y = prev.y })
		end
		table.insert(ruta, sig)
	end
	table.insert(ruta, fuera(dentro[#dentro]))
	return sinRepetidos(ruta)
end

-- sanctumTerrain del 3D (GameLoop.generateLevelMap del 2D): ruido fijo y la ruta pintada en celdas de 40 px.
local function terrenoSanctum(ruta)
	local lado, cols, filas = 40, 20, 15
	local t = {}
	for y = 0, filas - 1 do
		local fila = {}
		for x = 0, cols - 1 do
			local valor = math.sin((x + 1) * 12.9898 + (y + 1) * 78.233) * 43758.5453
			local ruido = valor - math.floor(valor)
			local celda = if ruido < 0.05 then VEREDA elseif ruido < 0.13 then DETALLE elseif ruido < 0.18 then BOSQUE else PASTO
			if y == 0 or y == filas - 1 or (x < 2 and y < 5) then
				celda = MONTANA
			end
			fila[x + 1] = celda
		end
		t[y + 1] = fila
	end
	for i = 1, #ruta - 1 do
		local x0, y0 = math.floor(ruta[i].x / lado), math.floor(ruta[i].y / lado)
		local x1, y1 = math.floor(ruta[i + 1].x / lado), math.floor(ruta[i + 1].y / lado)
		for x = math.max(0, math.min(x0, x1)), math.min(cols - 1, math.max(x0, x1)) do
			if t[y0 + 1] then
				t[y0 + 1][x + 1] = CAMINO
			end
		end
		for y = math.max(0, math.min(y0, y1)), math.min(filas - 1, math.max(y0, y1)) do
			if t[y + 1] and t[y + 1][x1 + 1] ~= nil then
				t[y + 1][x1 + 1] = CAMINO
			end
		end
	end
	return t
end

local cache = {}
-- Grilla numérica (filas de códigos, 1-indexada) y lado de celda en px, como getMission del 3D.
function Mapa.terreno(nivel): ({ { number } }, number)
	if cache[nivel.id] then
		return cache[nivel.id].grilla, cache[nivel.id].lado
	end
	local grilla
	if nivel.id == "level_2" then
		grilla = require(Data.mapas.manhattan).rows
	elseif nivel.id == "level_4" then
		grilla = terrenoSanctum(Mapa.rutaPixeles(nivel))
	else
		grilla = {}
		for _, texto in nivel.rendering.terrainRows do
			local fila = {}
			for c = 1, #texto do
				fila[c] = LEYENDA[texto:sub(c, c)] or PASTO
			end
			table.insert(grilla, fila)
		end
	end
	local lado = nivel.rendering and nivel.rendering.tileSize or 40
	cache[nivel.id] = { grilla = grilla, lado = lado }
	return grilla, lado
end

-- Construye el terreno, las zonas de la misión y la base en `origen`, dentro de `padre`;
-- devuelve la ruta en el mundo y el modelo.
function Mapa.construir(nivel, origen: Vector3, padre: Instance): ({ Vector3 }, Model)
	local carpeta = Instance.new("Model")
	carpeta.Name = "Mapa"

	local grilla, ladoPx = Mapa.terreno(nivel)
	local lado = ladoPx * Mapa.ESCALA
	for f, fila in grilla do
		for c, codigo in fila do
			local t = ASPECTO[codigo] or ASPECTO[PASTO]
			local p = Instance.new("Part")
			p.Anchored = true
			p.Size = Vector3.new(lado, t.alto, lado)
			p.Position = origen + Vector3.new((c - 0.5) * lado, t.alto / 2, (f - 0.5) * lado)
			p.Color = t.color
			p.Material = t.material
			p.TopSurface = Enum.SurfaceType.Smooth
			p.Parent = carpeta
		end
	end

	-- Zonas de la misión (runas de Sanctum): discos de luz con su radio.
	local mecanica = nivel.mission and nivel.mission.mechanic or {}
	for _, zona in mecanica.landmarks or {} do
		local d = Instance.new("Part")
		d.Name = "Zona"
		d.Anchored, d.CanCollide = true, false
		d.Shape = Enum.PartType.Cylinder
		d.Size = Vector3.new(0.2, zona.radius * 2 * Mapa.ESCALA, zona.radius * 2 * Mapa.ESCALA)
		d.CFrame = CFrame.new(Mapa.aMundo(zona.x, zona.y, origen) + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
		d.Color = Color3.fromHex(zona.color or "#ffd166")
		d.Material = Enum.Material.Neon
		d.Transparency = 0.45
		d.Parent = carpeta
	end

	local ruta = {}
	for _, punto in Mapa.rutaPixeles(nivel) do
		table.insert(ruta, Mapa.aMundo(punto.x, punto.y, origen))
	end

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.Size = Vector3.new(4, 6, 4)
	base.Position = ruta[#ruta] + Vector3.new(0, 3, 0)
	base.Color = Color3.fromRGB(240, 170, 40)
	base.Material = Enum.Material.Neon
	base.Parent = carpeta

	carpeta.Parent = padre
	return ruta, carpeta
end

return Mapa
