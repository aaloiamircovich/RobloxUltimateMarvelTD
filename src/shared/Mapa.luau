-- Mapas jugables del 3D (getMission en src/game/missions.js): ruta en píxeles, grilla de terreno
-- numérica y conversión píxeles ↔ mundo. El cliente usa ruta, terreno y conversiones; construir() es del servidor.
local Data = script.Parent.Data
local MaterialService = game:GetService("MaterialService")
local RunService = game:GetService("RunService")
local kit, clonarKit, agregarDecorado -- decorado del mapa (más abajo)

local Mapa = {}

Mapa.ESCALA = 3 / 8 -- studs por píxel del 2D: una baldosa de 32 px mide 12 studs (mapas caminables, docs/PARTIDA.md)
Mapa.ORIGEN = Vector3.new(300, 0, -40) -- lejos del HUB, que está en el centro
Mapa.ANCHO, Mapa.ALTO = 800, 600 -- tamaño lógico del 2D (combat-data.js)
Mapa.JUGABLES = { "level_1", "level_2", "level_3", "level_4" } -- PLAYABLE_MISSIONS del 3D

-- Códigos de TerrainRules.js del 2D.
local AGUA, PASTO, CAMINO, MONTANA, BOSQUE, BLOQUEADO, VEREDA, DETALLE = 0, 1, 2, 3, 4, 5, 11, 12
local LEYENDA = { W = AGUA, G = PASTO, S = VEREDA, P = CAMINO, M = MONTANA, B = BLOQUEADO, X = BLOQUEADO }

-- Relieve real: alto = altura de la superficie (studs). La montaña es una plataforma elevada (techos,
-- rocas) a la que se suben las unidades de altura; el agua es agua de terreno; lo bloqueado lleva
-- estructuras encima. variante: MaterialVariant del HUB (Hub.crearMateriales) si existe.
local ASPECTO = {
	[AGUA] = { color = Color3.fromRGB(70, 60, 50), alto = -3, material = Enum.Material.Sand },
	[BLOQUEADO] = { color = Color3.fromRGB(150, 150, 158), alto = 1.4, material = Enum.Material.Concrete, variante = "Hub_vereda" },
	[CAMINO] = { color = Color3.fromRGB(150, 145, 140), alto = 1, material = Enum.Material.Concrete, variante = "Hub_vereda" },
	[PASTO] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Grass, variante = "Hub_pasto" },
	[MONTANA] = { color = Color3.fromRGB(255, 255, 255), alto = 6, material = Enum.Material.Metal, variante = "Hub_metal" },
	[BOSQUE] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Grass, variante = "Hub_selva" },
	[VEREDA] = { color = Color3.fromRGB(255, 255, 255), alto = 1.3, material = Enum.Material.Concrete, variante = "Hub_vereda" },
	[DETALLE] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Metal, variante = "Hub_metal" },
}
Mapa.NIVEL_AGUA = 0.6 -- superficie del agua

-- Altura de la superficie en un punto (px del 2D), relativa al origen: para apoyar unidades y la vista previa.
function Mapa.alturaSuelo(nivel, x: number, y: number): number
	local grilla, lado = Mapa.terreno(nivel)
	local fila = grilla[math.floor(y / lado) + 1]
	local codigo = fila and fila[math.floor(x / lado) + 1]
	if codigo == AGUA then
		return Mapa.NIVEL_AGUA
	end
	return (ASPECTO[codigo] or ASPECTO[PASTO]).alto
end

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

--------------------------------------------------------------------------------
-- Decorado (sólo servidor): modelos de ServerStorage.Plantillas.Mapas/<tema del nivel>:
-- "estructura_*" sobre lo bloqueado, "borde_*" alrededor del mapa, "arbol" y "base".
-- Sin kit, bloques simples. Las plantillas miran a −Z con el pivote en el centro de su caja.
--------------------------------------------------------------------------------
Mapa.MARGEN = 40 -- studs de borde caminable alrededor del área jugable

local function kits(nivel, prefijo: string): { Model }
	if not (RunService:IsServer() or RunService:IsEdit()) then -- el cliente no ve ServerStorage
		return {}
	end
	local p = game:GetService("ServerStorage"):FindFirstChild("Plantillas")
	local mapas = p and p:FindFirstChild("Mapas")
	local tema = mapas and mapas:FindFirstChild(nivel.theme and nivel.theme.id or "")
	local r = {}
	for _, m in if tema then tema:GetChildren() else {} do
		if m:IsA("Model") and (m.Name == prefijo or m.Name:sub(1, #prefijo + 1) == prefijo .. "_") then
			table.insert(r, m)
		end
	end
	table.sort(r, function(x, y)
		return x.Name < y.Name
	end)
	return r
end

kit = function(nivel, nombre: string): Model?
	return kits(nivel, nombre)[1]
end

clonarKit = function(m: Model, eje: string, medida: number): Model
	local c = m:Clone()
	c:ScaleTo(c:GetScale() * medida / c:GetExtentsSize()[eje])
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return c
end

-- Coloca un modelo apoyado en `suelo` (Vector3), girado `giro` radianes.
local function apoyar(m: Model, suelo: Vector3, giro: number)
	m:PivotTo(CFrame.new(suelo + Vector3.new(0, m:GetExtentsSize().Y / 2, 0)) * CFrame.Angles(0, giro, 0))
end

local function hash(a: number, b: number): number
	return (a * 73856093 + b * 19349663) % 1000
end

agregarDecorado = function(nivel, carpeta: Model, celdas, lado: number, origen: Vector3, grilla)
	local deco = Instance.new("Model")
	deco.Name = "Decorado"
	local estructuras = kits(nivel, "estructura")
	local arbol = kit(nivel, "arbol")
	if not arbol and (RunService:IsServer() or RunService:IsEdit()) then
		local p = game:GetService("ServerStorage"):FindFirstChild("Plantillas")
		local h = p and p:FindFirstChild("Hub")
		arbol = h and h:FindFirstChild("arbol_jardin")
	end
	for _, celda in celdas do
		local h = hash(celda.f, celda.c)
		if celda.codigo == BLOQUEADO then
			-- Una estructura cada dos celdas (alternadas) para que no quede un bloque macizo.
			if (celda.f + celda.c) % 2 == 0 then
				if #estructuras > 0 then
					local m = clonarKit(estructuras[h % #estructuras + 1], "X", lado * 0.9)
					if m:GetExtentsSize().Z > lado * 0.95 then
						m:ScaleTo(m:GetScale() * lado * 0.9 / m:GetExtentsSize().Z)
					end
					apoyar(m, celda.centro, (h % 4) * math.pi / 2)
					m.Parent = deco
				else
					local b = Instance.new("Part")
					b.Anchored = true
					b.Size = Vector3.new(lado * 0.7, 3 + h % 4, lado * 0.7)
					b.Position = celda.centro + Vector3.new(0, b.Size.Y / 2, 0)
					b.Color = Color3.fromRGB(120, 125, 135)
					b.Material = Enum.Material.Concrete
					b.Parent = deco
				end
			end
		elseif celda.codigo == BOSQUE and arbol then
			local m = clonarKit(arbol, "Y", 8 + h % 4)
			apoyar(m, celda.centro, h / 1000 * math.pi * 2)
			m.Parent = deco
		end
	end

	-- Borde caminable alrededor del área jugable y un anillo de edificios del tema.
	local ancho, alto = Mapa.ANCHO * Mapa.ESCALA, Mapa.ALTO * Mapa.ESCALA
	local m = Mapa.MARGEN
	local suelo = ASPECTO[PASTO]
	for _, franja in {
		{ Vector3.new(ancho / 2, 0, -m / 2), Vector3.new(ancho + 2 * m, 0, m) },
		{ Vector3.new(ancho / 2, 0, alto + m / 2), Vector3.new(ancho + 2 * m, 0, m) },
		{ Vector3.new(-m / 2, 0, alto / 2), Vector3.new(m, 0, alto) },
		{ Vector3.new(ancho + m / 2, 0, alto / 2), Vector3.new(m, 0, alto) },
	} do
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = franja[2] + Vector3.new(0, suelo.alto + 6, 0)
		p.Position = origen + franja[1] + Vector3.new(0, (suelo.alto - 6) / 2, 0)
		p.Material = suelo.material
		p.Color = suelo.color
		if MaterialService:FindFirstChild(suelo.variante) then
			p.MaterialVariant = suelo.variante
		end
		p.Parent = deco
	end
	local bordes = kits(nivel, "borde")
	local paso = 34
	local i = 0
	local function ponerBorde(x: number, z: number, mira: Vector3)
		i += 1
		local pos = origen + Vector3.new(x, suelo.alto, z)
		local h = hash(math.floor(x), math.floor(z))
		local plantilla = if #bordes > 0 then bordes[h % #bordes + 1] else nil
		if plantilla and i % 3 ~= 0 then
			local b = clonarKit(plantilla, "Y", 18 + h % 12)
			b:PivotTo(CFrame.lookAt(pos, Vector3.new(mira.X, pos.Y, mira.Z)) * CFrame.new(0, b:GetExtentsSize().Y / 2, 0))
			b.Parent = deco
		elseif arbol then
			local t = clonarKit(arbol, "Y", 9 + h % 4)
			apoyar(t, pos, h / 1000 * math.pi * 2)
			t.Parent = deco
		end
	end
	local centro = origen + Vector3.new(ancho / 2, 0, alto / 2)
	for x = 0, ancho, paso do
		ponerBorde(x, -m * 0.6, centro)
		ponerBorde(x, alto + m * 0.6, centro)
	end
	for z = paso, alto - paso, paso do
		ponerBorde(-m * 0.6, z, centro)
		ponerBorde(ancho + m * 0.6, z, centro)
	end
	deco.Parent = carpeta
end

-- Construye el terreno, las zonas de la misión y la base en `origen`, dentro de `padre`;
-- devuelve la ruta en el mundo y el modelo.
function Mapa.construir(nivel, origen: Vector3, padre: Instance): ({ Vector3 }, Model)
	local carpeta = Instance.new("Model")
	carpeta.Name = "Mapa"
	local agua, celdas = {}, {}

	local grilla, ladoPx = Mapa.terreno(nivel)
	local lado = ladoPx * Mapa.ESCALA
	for f, fila in grilla do
		for c, codigo in fila do
			local t = ASPECTO[codigo] or ASPECTO[PASTO]
			-- Cada baldosa es un bloque desde 6 studs bajo el piso hasta su superficie (sin huecos entre alturas).
			local fondo = -6
			local p = Instance.new("Part")
			p.Anchored = true
			p.Size = Vector3.new(lado, t.alto - fondo, lado)
			p.Position = origen + Vector3.new((c - 0.5) * lado, (t.alto + fondo) / 2, (f - 0.5) * lado)
			p.Color = t.color
			p.Material = t.material
			if t.variante and MaterialService:FindFirstChild(t.variante) then
				p.MaterialVariant = t.variante
			end
			p.TopSurface = Enum.SurfaceType.Smooth
			p.Parent = carpeta
			if codigo == AGUA then
				table.insert(agua, { CFrame.new(origen + Vector3.new((c - 0.5) * lado, (t.alto + Mapa.NIVEL_AGUA) / 2, (f - 0.5) * lado)), Vector3.new(lado, Mapa.NIVEL_AGUA - t.alto, lado) })
			end
			table.insert(celdas, { codigo = codigo, centro = origen + Vector3.new((c - 0.5) * lado, t.alto, (f - 0.5) * lado), f = f, c = c })
		end
	end
	-- Agua de terreno (se borra con Mapa.limpiar).
	for _, r in agua do
		workspace.Terrain:FillBlock(r[1], r[2], Enum.Material.Water)
	end
	carpeta:SetAttribute("Agua", #agua)
	agregarDecorado(nivel, carpeta, celdas, lado, origen, grilla)

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

	-- Base que defienden: modelo "base" del kit del mapa o un bloque de luz.
	local kitBase = kit(nivel, "base")
	if kitBase then
		local m = clonarKit(kitBase, "Y", 14)
		m:PivotTo(CFrame.lookAt(ruta[#ruta], ruta[#ruta - 1] * Vector3.new(1, 0, 1) + Vector3.new(0, ruta[#ruta].Y, 0)) * CFrame.new(0, m:GetExtentsSize().Y / 2 - 1, 0))
		m.Name = "Base"
		m.Parent = carpeta
	else
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Anchored = true
		base.Size = Vector3.new(8, 12, 8)
		base.Position = ruta[#ruta] + Vector3.new(0, 6, 0)
		base.Color = Color3.fromRGB(240, 170, 40)
		base.Material = Enum.Material.Neon
		base.Parent = carpeta
	end

	carpeta.Parent = padre
	return ruta, carpeta
end

-- Borra el agua de terreno de un mapa construido (el resto se borra con el modelo).
function Mapa.limpiar(nivel, origen: Vector3)
	local grilla, ladoPx = Mapa.terreno(nivel)
	local lado = ladoPx * Mapa.ESCALA
	for f, fila in grilla do
		for c, codigo in fila do
			if codigo == AGUA then
				local t = ASPECTO[AGUA]
				workspace.Terrain:FillBlock(CFrame.new(origen + Vector3.new((c - 0.5) * lado, (t.alto + Mapa.NIVEL_AGUA) / 2, (f - 0.5) * lado)), Vector3.new(lado, Mapa.NIVEL_AGUA - t.alto + 0.2, lado), Enum.Material.Air)
			end
		end
	end
end

return Mapa
