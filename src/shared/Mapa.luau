-- Mapas jugables del 3D (getMission en src/game/missions.js): ruta en píxeles, grilla de terreno
-- numérica y conversión píxeles ↔ mundo. El cliente usa ruta, terreno y conversiones; construir() es del servidor.
local Data = script.Parent.Data
local MaterialService = game:GetService("MaterialService")
local RunService = game:GetService("RunService")
local kit, clonarKit, agregarDecorado -- decorado del mapa (más abajo)

local Mapa = {}

Mapa.ESCALA = 1 / 4 -- studs por píxel del 2D: el mapa mide 200×150 studs y una baldosa de 32 px, 8 (docs/PARTIDA.md)
Mapa.ORIGEN = Vector3.new(300, 0, -40) -- lejos del HUB, que está en el centro
Mapa.ANCHO, Mapa.ALTO = 800, 600 -- tamaño lógico del 2D (combat-data.js)
Mapa.JUGABLES = { "level_1", "level_2", "level_3", "level_4" } -- PLAYABLE_MISSIONS del 3D

-- Códigos de TerrainRules.js del 2D.
local AGUA, PASTO, CAMINO, MONTANA, BOSQUE, BLOQUEADO, VEREDA, DETALLE = 0, 1, 2, 3, 4, 5, 11, 12
local LEYENDA = { W = AGUA, G = PASTO, S = VEREDA, P = CAMINO, M = MONTANA, B = BLOQUEADO, X = BLOQUEADO }

-- Relieve real: alto = altura de la superficie (studs). La montaña son edificios de techo plano donde se
-- paran las unidades de altura; el agua es agua de terreno; lo bloqueado lleva estructuras encima.
-- variante: MaterialVariant del HUB (Hub.crearMateriales) si existe; techo: variante de la losa de arriba.
-- terreno: en vez de baldosa, terreno de Roblox (pasto 3D con Terrain.Decoration).
local ASPECTO = {
	[AGUA] = { color = Color3.fromRGB(70, 60, 50), alto = -3, material = Enum.Material.Sand },
	[BLOQUEADO] = { color = Color3.fromRGB(150, 150, 158), alto = 1.4, material = Enum.Material.Concrete, variante = "Hub_vereda" },
	[CAMINO] = { color = Color3.fromRGB(255, 255, 255), alto = 1, material = Enum.Material.Metal, variante = "Hub_hangar" },
	[PASTO] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Grass, terreno = true },
	[MONTANA] = { color = Color3.fromRGB(255, 255, 255), alto = 9, material = Enum.Material.Concrete, variante = "Hub_fachada", techo = "Hub_techo" },
	[BOSQUE] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Grass, terreno = true },
	[VEREDA] = { color = Color3.fromRGB(255, 255, 255), alto = 1.3, material = Enum.Material.Concrete, variante = "Hub_vereda" },
	[DETALLE] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Metal, variante = "Hub_metal" },
}
Mapa.NIVEL_AGUA = 0.6 -- superficie del agua

-- Temas de mapa (nivel.theme.id): aspecto que cambia sobre ASPECTO, orilla del camino ("peligro": franjas
-- amarillas y negras; "cordon": cordón y línea amarilla al medio), banda de color en los edificios,
-- objetos sueltos sobre el pasto { kit, alto, probabilidad en 1000 }, luciérnagas y vapor de alcantarillas.
local TEMAS = {
	avengers = {
		orilla = "peligro",
		banda = Color3.fromRGB(200, 30, 35),
		sueltos = { { "arbusto", 2.4, 150 }, { "flores", 1, 150 }, { "roca", 1.8, 40 } },
		motas = true,
	},
	["new-york"] = {
		aspecto = {
			[CAMINO] = { color = Color3.fromRGB(255, 255, 255), alto = 1, material = Enum.Material.Asphalt, variante = "Hub_asfalto" },
			[PASTO] = { color = Color3.fromRGB(235, 232, 226), alto = 1.4, material = Enum.Material.Concrete, variante = "Hub_vereda" },
			[MONTANA] = { color = Color3.fromRGB(255, 255, 255), alto = 12, material = Enum.Material.Brick, variante = "Mapa_ladrillo1", techo = "Mapa_azotea", techoMaterial = Enum.Material.Slate },
			-- Manzanas: edificios bajos de ladrillo (nadie se para en lo bloqueado).
			[BLOQUEADO] = { color = Color3.fromRGB(230, 215, 200), alto = 7, material = Enum.Material.Brick, variante = "Mapa_ladrillo2", techo = "Mapa_azotea", techoMaterial = Enum.Material.Slate },
		},
		orilla = "cordon",
		banda = Color3.fromRGB(226, 214, 190),
		sueltos = { { "hidrante", 1.8, 50 }, { "basurero", 2, 60 }, { "arbol", 7, 110 }, { "estructura_2", 3.6, 30 }, { "estructura_3", 4, 30 } },
		vapor = true,
	},
	-- Sanctum: Bleecker Street; adoquines con runas, azoteas de ladrillo y el portal de la Dimensión Oscura.
	sanctum = {
		aspecto = {
			[CAMINO] = { color = Color3.fromRGB(125, 118, 112), alto = 1, material = Enum.Material.Cobblestone },
			[MONTANA] = { color = Color3.fromRGB(255, 255, 255), alto = 10, material = Enum.Material.Brick, variante = "Mapa_ladrillo", techo = "Mapa_azotea", techoMaterial = Enum.Material.Slate },
			[VEREDA] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Grass, terreno = true },
			[DETALLE] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Grass, terreno = true },
		},
		orilla = "runas",
		banda = Color3.fromRGB(255, 95, 20),
		bandaMaterial = Enum.Material.Neon,
		sueltos = { { "arbusto", 2.4, 160 }, { "flores", 1, 180 }, { "arbol", 7, 50 } },
		detalle = "brasero", -- un brasero en cada casilla de detalle
		motas = Color3.fromRGB(255, 160, 70),
		vortice = Color3.fromRGB(110, 40, 190),
	},
	-- Wakanda: casi todo es selva (bloqueada); las unidades van en mesetas de roca violeta y en el agua.
	wakanda = {
		aspecto = {
			[CAMINO] = { color = Color3.fromRGB(255, 255, 255), alto = 1, material = Enum.Material.Ground, variante = "Mapa_tierraroja" },
			[BLOQUEADO] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Grass, terreno = true },
			[MONTANA] = { color = Color3.fromRGB(255, 255, 255), alto = 6, material = Enum.Material.Rock, variante = "Mapa_rocavioleta", techo = "Mapa_rocavioleta", techoMaterial = Enum.Material.Rock },
			[PASTO] = { color = Color3.fromRGB(255, 255, 255), alto = 1.4, material = Enum.Material.Grass, terreno = true },
		},
		parapeto = false,
		bancos = false,
		banda = Color3.fromRGB(170, 90, 255), -- veta de vibranium
		bandaMaterial = Enum.Material.Neon,
		sueltosEn = { BLOQUEADO, PASTO },
		sueltos = { { "arbol", 9, 300 }, { "arbusto", 2.8, 220 }, { "helecho", 2.2, 160 }, { "cristal", 2, 50 } },
		motas = Color3.fromRGB(190, 140, 255),
	},
}

local function tema(nivel)
	return TEMAS[nivel.theme and nivel.theme.id or ""] or TEMAS.avengers
end

-- Aspecto de una celda según el tema del nivel.
local function aspecto(nivel, codigo: number?)
	local propio = tema(nivel).aspecto
	return (propio and propio[codigo]) or ASPECTO[codigo] or ASPECTO[PASTO]
end
local DESFASE = 2 -- el pasto de terreno se ve 2 studs más arriba que el tope de su relleno (el agua no; medido en Studio)

-- Altura de la superficie en un punto (px del 2D), relativa al origen: para apoyar unidades y la vista previa.
function Mapa.alturaSuelo(nivel, x: number, y: number): number
	local grilla, lado = Mapa.terreno(nivel)
	local fila = grilla[math.floor(y / lado) + 1]
	local codigo = fila and fila[math.floor(x / lado) + 1]
	if codigo == AGUA then
		return Mapa.NIVEL_AGUA
	end
	return aspecto(nivel, codigo).alto
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
Mapa.MARGEN = 28 -- studs de borde caminable alrededor del área jugable

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

-- Modelo del kit del tema o, si no tiene, de la decoración común (Plantillas.Deco: arbusto, flores, roca, farol, banco).
kit = function(nivel, nombre: string): Model?
	local propio = kits(nivel, nombre)[1]
	if propio or not (RunService:IsServer() or RunService:IsEdit()) then
		return propio
	end
	local p = game:GetService("ServerStorage"):FindFirstChild("Plantillas")
	local comun = p and p:FindFirstChild("Deco")
	return comun and comun:FindFirstChild(nombre)
end

clonarKit = function(m: Model, eje: string, medida: number): Model
	local c = m:Clone()
	c:ScaleTo(c:GetScale() * medida / c:GetExtentsSize()[eje])
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanQuery = false -- el mouse apunta al suelo a través del decorado (colocar unidades)
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


local SELLO = "132807365750031" -- sello de Strange (el mismo del portal del HUB)
local AMARILLO, NEGRO = Color3.fromRGB(255, 196, 0), Color3.fromRGB(25, 25, 28)
local LADOS = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } } -- (fila, columna) vecinas

local function bloque(padre: Instance, cf: CFrame, tam: Vector3, color: Color3, material: Enum.Material, variante: string?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CFrame = cf
	p.Size = tam
	p.Color = color
	p.Material = material
	if variante and MaterialService:FindFirstChild(variante, true) then -- los del generador de Roblox quedan en subcarpetas
		p.MaterialVariant = variante
	end
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

-- Franja de peligro amarilla y negra en el piso, de `a` a `b` (tramos de ~2 studs).
local function franjaPeligro(padre: Instance, a: Vector3, b: Vector3, ancho: number)
	local largo = (b - a).Magnitude
	local n = math.max(1, math.floor(largo / 2))
	for i = 1, n do
		local pos = a + (b - a) * ((i - 0.5) / n)
		local p = bloque(padre, CFrame.lookAt(pos, pos + (b - a)), Vector3.new(ancho, 0.1, largo / n), if i % 2 == 0 then NEGRO else AMARILLO, Enum.Material.SmoothPlastic)
		p.CanCollide = false
	end
end

-- Celda vecina (código) o nil fuera de la grilla.
local function vecina(grilla, f: number, c: number): number?
	return grilla[f] and grilla[f][c]
end

agregarDecorado = function(nivel, carpeta: Model, celdas, lado: number, origen: Vector3, ruta: { Vector3 }, anchoCamino: number, grilla)
	local deco = Instance.new("Model")
	deco.Name = "Decorado"
	local estilo = tema(nivel)
	local sueltos = estilo.sueltos or {}
	local flora = {}
	for _, n in { "farol", "banco", "barrera", "vehiculo" } do
		flora[n] = kit(nivel, n)
	end
	for _, s in sueltos do
		flora[s[1]] = kit(nivel, s[1])
	end
	local estructuras = kits(nivel, "estructura")
	local arbol = kit(nivel, "arbol")
	if not arbol and (RunService:IsServer() or RunService:IsEdit()) then
		local p = game:GetService("ServerStorage"):FindFirstChild("Plantillas")
		local h = p and p:FindFirstChild("Hub")
		arbol = h and h:FindFirstChild("arbol_jardin")
	end
	for _, celda in celdas do
		local h = hash(celda.f, celda.c)
		if celda.codigo == BLOQUEADO and not aspecto(nivel, BLOQUEADO).techo then
			-- Una estructura cada dos celdas (alternadas) para que no quede un bloque macizo.
			if (celda.f + celda.c) % 2 == 0 then
				if #estructuras > 0 then
					local m = clonarKit(estructuras[h % #estructuras + 1], "X", lado * 0.9)
					if m:GetExtentsSize().Z > lado * 0.95 then
						m:ScaleTo(m:GetScale() * lado * 0.9 / m:GetExtentsSize().Z)
					end
					apoyar(m, celda.centro, (h % 4) * math.pi / 2)
					m.Parent = deco
				elseif not table.find(estilo.sueltosEn or {}, BLOQUEADO) then
					local alto = 2 + h % 3
					bloque(deco, CFrame.new(celda.centro + Vector3.new(0, alto / 2, 0)), Vector3.new(lado * 0.7, alto, lado * 0.7), Color3.fromRGB(120, 125, 135), Enum.Material.Concrete)
				end
			end
		elseif celda.codigo == DETALLE and estilo.detalle and kit(nivel, estilo.detalle) then
			local m = clonarKit(kit(nivel, estilo.detalle), "Y", 2.6)
			apoyar(m, celda.centro, h / 1000 * math.pi * 2)
			local luz = Instance.new("PointLight")
			luz.Color, luz.Range, luz.Brightness = Color3.fromRGB(255, 150, 60), 12, 1.5
			luz.Parent = m:FindFirstChildWhichIsA("BasePart", true)
			m.Parent = deco
		elseif celda.codigo == BOSQUE and arbol then
			local m = clonarKit(arbol, "Y", 6 + h % 3)
			apoyar(m, celda.centro, h / 1000 * math.pi * 2)
			m.Parent = deco
		end
		if table.find(estilo.sueltosEn or { PASTO, BOSQUE }, celda.codigo) then
			-- Plantas sueltas y faroles con banco al borde del camino.
			local g = hash(celda.c * 7 + 3, celda.f * 13 + 1)
			local suelto = (g / 1000 - 0.5) * lado * 0.6
			local acumulado = 0
			for _, s in sueltos do
				acumulado += s[3]
				if g < acumulado then
					if flora[s[1]] then
						local m = clonarKit(flora[s[1]], "Y", s[2] * (0.8 + (g % 5) / 10))
						apoyar(m, celda.centro + Vector3.new(suelto, 0, -suelto * 0.7), g / 1000 * math.pi * 2)
						m.Parent = deco
					end
					break
				end
			end
			for _, d in LADOS do
				if vecina(grilla, celda.f + d[1], celda.c + d[2]) == CAMINO and (celda.f * 3 + celda.c) % 4 == 0 and flora.farol then
					local normal = Vector3.new(d[2], 0, d[1])
					local pie = celda.centro + normal * (lado / 2 - 1)
					local m = clonarKit(flora.farol, "Y", 6)
					m:PivotTo(CFrame.lookAt(pie, pie + normal) * CFrame.new(0, m:GetExtentsSize().Y / 2, 0))
					local luz = Instance.new("PointLight")
					luz.Color, luz.Range, luz.Brightness = Color3.fromRGB(255, 226, 170), 14, 1.4
					luz.Parent = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
					m.Parent = deco
					if flora.banco and estilo.bancos ~= false and g % 2 == 0 then
						local b = clonarKit(flora.banco, "X", 3.6)
						local lugar = pie + Vector3.new(d[1], 0, d[2]) * 3 - normal * 0.6
						b:PivotTo(CFrame.lookAt(lugar, lugar + normal) * CFrame.new(0, b:GetExtentsSize().Y / 2, 0))
						b.Parent = deco
					end
					break
				end
			end
		end
	end

	-- Anillo de edificios del tema y árboles alrededor, salvo frente al portón y a la base.
	local ancho, alto = Mapa.ANCHO * Mapa.ESCALA, Mapa.ALTO * Mapa.ESCALA
	local m = Mapa.MARGEN
	local suelo = aspecto(nivel, PASTO)
	local bordes = kits(nivel, "borde")
	local paso = 26
	local i = 0
	local libre = anchoCamino / 2 + 16
	local function ponerBorde(x: number, z: number, mira: Vector3)
		local pos = origen + Vector3.new(x, suelo.alto, z)
		local plano = Vector3.new(1, 0, 1)
		if ((pos - ruta[1]) * plano).Magnitude < libre or ((pos - ruta[#ruta]) * plano).Magnitude < libre then
			return
		end
		i += 1
		local h = hash(math.floor(x), math.floor(z))
		local plantilla = if #bordes > 0 then bordes[h % #bordes + 1] else nil
		if plantilla and i % 3 ~= 0 then
			local b = clonarKit(plantilla, "Y", 14 + h % 8)
			b:PivotTo(CFrame.lookAt(pos, Vector3.new(mira.X, pos.Y, mira.Z)) * CFrame.new(0, b:GetExtentsSize().Y / 2, 0))
			b.Parent = deco
		elseif arbol then
			local t = clonarKit(arbol, "Y", 7 + h % 3)
			apoyar(t, pos, h / 1000 * math.pi * 2)
			t.Parent = deco
		end
		-- Un arbusto o una roca más adentro, en el pasto del borde.
		local s = sueltos[h % math.max(1, #sueltos) + 1]
		local planta = s and flora[s[1]]
		if planta and h % 2 == 0 then
			local hacia = ((mira - pos) * Vector3.new(1, 0, 1)).Unit
			local p = clonarKit(planta, "Y", s[2])
			apoyar(p, pos + hacia * 7 + Vector3.new(hacia.Z, 0, -hacia.X) * (h % 9 - 4), h / 160)
			p.Parent = deco
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

	-- Barreras a los lados de la entrada y de la base; vehículos estacionados junto al portón.
	for k, extremo in { { ruta[1], ruta[2] }, { ruta[#ruta], ruta[#ruta - 1] } } do
		local dir = ((extremo[2] - extremo[1]) * Vector3.new(1, 0, 1)).Unit
		local costado = Vector3.new(-dir.Z, 0, dir.X)
		local piso = Vector3.new(extremo[1].X, origen.Y + suelo.alto, extremo[1].Z)
		for _, s in { -1, 1 } do
			if flora.barrera then
				for j = 0, 1 do
					local p = piso + dir * (8 + j * 5) + costado * s * (anchoCamino / 2 + 2)
					local b = clonarKit(flora.barrera, "X", 4)
					b:PivotTo(CFrame.lookAt(p, p + dir) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(0, b:GetExtentsSize().Y / 2, 0))
					b.Parent = deco
				end
			end
			if flora.vehiculo and k == 1 then
				local p = piso - dir * 4 + costado * s * (anchoCamino / 2 + 15)
				local v = clonarKit(flora.vehiculo, "Z", 8)
				v:PivotTo(CFrame.lookAt(p, p + dir + costado * s * 0.4) * CFrame.new(0, v:GetExtentsSize().Y / 2, 0))
				v.Parent = deco
			end
		end
	end

	-- Luciérnagas sobre el mapa (partículas suaves), si el tema las tiene.
	if not estilo.motas then
		deco.Parent = carpeta
		return
	end
	local aire = bloque(deco, CFrame.new(centro + Vector3.new(0, 5, 0)), Vector3.new(ancho, 1, alto), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	aire.Name = "Ambiente"
	aire.Transparency, aire.CanCollide, aire.CanQuery, aire.CanTouch = 1, false, false, false
	local motas = Instance.new("ParticleEmitter")
	motas.Color = ColorSequence.new(if typeof(estilo.motas) == "Color3" then estilo.motas else Color3.fromRGB(255, 236, 150))
	motas.LightEmission = 0.8
	motas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0) })
	motas.Lifetime = NumberRange.new(6, 10)
	motas.Rate = 8
	motas.Speed = NumberRange.new(0.3, 1)
	motas.SpreadAngle = Vector2.new(180, 180)
	motas.Parent = aire
	deco.Parent = carpeta
end

-- Portón de hangar por donde entran los enemigos: frente en `pos` + 2 studs hacia el mapa, mirando a `dir`.
-- Con el modelo "porton" del kit lo usa (la abertura ocupa ~60% del ancho); si no, lo arma con bloques.
local function porton(nivel, padre: Instance, pos: Vector3, dir: Vector3, ancho: number)
	local cf = CFrame.lookAt(pos, pos + dir) * CFrame.new(0, 0, -2) -- cara del frente, a la altura del piso
	local modelo = kit(nivel, "porton")
	if modelo then
		local m = clonarKit(modelo, "X", ancho * 1.6)
		m.Name = "Porton"
		local tam = m:GetExtentsSize()
		m:PivotTo(cf * CFrame.new(0, tam.Y / 2, tam.Z / 2))
		local vortice = tema(nivel).vortice
		if vortice then
			-- Portal: disco de energía con el sello de Strange, de donde salen los enemigos.
			local d = bloque(m, cf * CFrame.new(0, tam.Y * 0.4, tam.Z * 0.6) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.3, tam.Y * 0.7, ancho * 0.95), vortice, Enum.Material.Neon)
			d.Shape = Enum.PartType.Cylinder
			d.Transparency, d.CanCollide, d.CanQuery = 0.15, false, false
			for _, cara in { Enum.NormalId.Left, Enum.NormalId.Right } do
				local sello = Instance.new("Decal")
				sello.Texture = "rbxassetid://" .. SELLO
				sello.Color3 = Color3.fromRGB(255, 150, 50)
				sello.Face = cara
				sello.Parent = d
			end
			local chispas = Instance.new("ParticleEmitter")
			chispas.Color = ColorSequence.new(Color3.fromRGB(255, 150, 50))
			chispas.LightEmission = 1
			chispas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
			chispas.Lifetime = NumberRange.new(0.6, 1.2)
			chispas.Rate = 30
			chispas.Speed = NumberRange.new(2, 5)
			chispas.SpreadAngle = Vector2.new(180, 180)
			chispas.Parent = d
			local luz = Instance.new("PointLight")
			luz.Color, luz.Range, luz.Brightness = vortice, 18, 2
			luz.Parent = d
		else
			-- Fondo oscuro para que los enemigos salgan de adentro y no se vea el pasto de atrás.
			local fondo = bloque(m, cf * CFrame.new(0, tam.Y * 0.35, tam.Z - 1), Vector3.new(ancho, tam.Y * 0.7, 1), NEGRO, Enum.Material.SmoothPlastic)
			fondo.CanQuery = false
		end
		m.Parent = padre
		return m
	end
	local m = Instance.new("Model")
	m.Name = "Porton"
	local H, D = 12, 14
	local gris = Color3.fromRGB(200, 205, 212)
	local function local_(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	for _, lado in { -1, 1 } do
		bloque(m, local_(lado * (ancho / 2 + 2), H / 2, D / 2), Vector3.new(4, H, D), gris, Enum.Material.Metal, "Hub_metal")
		-- Baliza roja arriba de cada columna.
		local luz = bloque(m, local_(lado * (ancho / 2 + 2), H + 3.6, -0.2), Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(255, 40, 30), Enum.Material.Neon)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 60, 40), 16, 2
		l.Parent = luz
	end
	bloque(m, local_(0, H + 1.5, D / 2), Vector3.new(ancho + 8, 3, D), gris, Enum.Material.Metal, "Hub_metal")
	bloque(m, local_(0, H / 2, D - 0.5), Vector3.new(ancho, H, 1), NEGRO, Enum.Material.SmoothPlastic)
	bloque(m, local_(0, -0.5, D / 2), Vector3.new(ancho, 1, D), Color3.new(1, 1, 1), Enum.Material.Metal, "Hub_hangar")
	-- Cortina a medio subir con franjas de peligro.
	local n = math.max(2, math.floor(ancho / 2))
	for k = 1, n do
		bloque(m, local_(-ancho / 2 + (k - 0.5) * ancho / n, H - 1.5, 0.3), Vector3.new(ancho / n, 3, 0.4), if k % 2 == 0 then NEGRO else AMARILLO, Enum.Material.SmoothPlastic)
	end
	-- Cartel sobre el portón.
	local frente = bloque(m, local_(0, H + 1.5, -0.05), Vector3.new(ancho + 8, 3, 0.1), Color3.fromRGB(190, 25, 30), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "HANGAR"
	t.TextScaled = true
	t.Font = Enum.Font.Bangers
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Parent = gui
	gui.Parent = frente
	m.Parent = padre
	return m
end

-- Construye el terreno, las zonas de la misión y la base en `origen`, dentro de `padre`;
-- devuelve la ruta en el mundo y el modelo.
function Mapa.construir(nivel, origen: Vector3, padre: Instance): ({ Vector3 }, Model)
	local carpeta = Instance.new("Model")
	carpeta.Name = "Mapa"
	local agua, pasto, huecos, celdas = {}, {}, {}, {}
	local fondo = -6 -- cada baldosa es un bloque desde 6 studs bajo el piso hasta su superficie

	local grilla, ladoPx = Mapa.terreno(nivel)
	local lado = ladoPx * Mapa.ESCALA
	local filas, cols = #grilla, #grilla[1]
	local blanco = Color3.new(1, 1, 1)
	local estilo = tema(nivel)
	-- Orilla del camino de `a` a `b` (a la altura del piso del camino) según el tema.
	local function orilla(padre: Instance, a: Vector3, b: Vector3)
		if estilo.orilla == "cordon" then
			local medio = (a + b) / 2 + Vector3.new(0, 0.2, 0)
			bloque(padre, CFrame.lookAt(medio, medio + (b - a)), Vector3.new(0.6, 0.5, (b - a).Magnitude), Color3.fromRGB(205, 205, 200), Enum.Material.Concrete)
		elseif estilo.orilla == "runas" then
			-- Filo de luz naranja embutido en los adoquines.
			local medio = (a + b) / 2 + Vector3.new(0, 0.02, 0)
			local p = bloque(padre, CFrame.lookAt(medio, medio + (b - a)), Vector3.new(0.25, 0.06, (b - a).Magnitude), Color3.fromRGB(255, 95, 20), Enum.Material.Neon)
			p.CanCollide = false
		elseif estilo.orilla == "peligro" then
			franjaPeligro(padre, a, b, 0.8)
		end
	end
	for f, fila in grilla do
		for c, codigo in fila do
			local t = aspecto(nivel, codigo)
			local centro = origen + Vector3.new((c - 0.5) * lado, 0, (f - 0.5) * lado)
			if t.terreno then
				table.insert(pasto, { CFrame.new(centro + Vector3.new(0, (t.alto - DESFASE + fondo) / 2, 0)), Vector3.new(lado, t.alto - DESFASE - fondo, lado), t.terrenoMaterial })
			else
				local tope = if t.techo then t.alto - 0.4 else t.alto
				bloque(carpeta, CFrame.new(centro + Vector3.new(0, (tope + fondo) / 2, 0)), Vector3.new(lado, tope - fondo, lado), t.color, t.material, t.variante)
			end
			if t.techo then
				-- Edificio: losa del techo, y en cada lado que da afuera un parapeto y una banda roja.
				bloque(carpeta, CFrame.new(centro + Vector3.new(0, t.alto - 0.2, 0)), Vector3.new(lado, 0.4, lado), blanco, t.techoMaterial or Enum.Material.Metal, t.techo)
				for _, d in LADOS do
					if vecina(grilla, f + d[1], c + d[2]) ~= codigo then
						local normal = Vector3.new(d[2], 0, d[1])
						local tangente = Vector3.new(math.abs(d[1]), 0, math.abs(d[2]))
						local borde = centro + normal * (lado / 2)
						local p1 = borde - normal * 0.2 + Vector3.new(0, t.alto + 0.6, 0)
						if estilo.parapeto ~= false then
							bloque(carpeta, CFrame.lookAt(p1, p1 + tangente), Vector3.new(0.4, 1.2, lado), Color3.fromRGB(225, 228, 232), Enum.Material.Concrete)
						end
						local p2 = borde + normal * 0.05 + Vector3.new(0, t.alto - 1.2, 0)
						bloque(carpeta, CFrame.lookAt(p2, p2 + tangente), Vector3.new(0.1, 0.6, lado), estilo.banda, estilo.bandaMaterial or Enum.Material.SmoothPlastic)
					end
				end
			elseif codigo == CAMINO then
				-- Piso de hangar: franjas de peligro donde termina el camino; en el borde del mapa sigue hasta el portón y la base.
				for _, d in LADOS do
					local otra = vecina(grilla, f + d[1], c + d[2])
					local normal = Vector3.new(d[2], 0, d[1])
					local tangente = Vector3.new(math.abs(d[1]), 0, math.abs(d[2]))
					local y = Vector3.new(0, t.alto + 0.05, 0)
					if otra ~= nil and otra ~= CAMINO then
						local b = centro + normal * (lado / 2 - 0.5) + y
						orilla(carpeta, b - tangente * lado / 2, b + tangente * lado / 2)
					elseif otra == nil then
						local m = Mapa.MARGEN
						local ext = centro + normal * (lado / 2 + m / 2)
						bloque(carpeta, CFrame.lookAt(ext + Vector3.new(0, (t.alto + fondo) / 2, 0), ext + Vector3.new(0, (t.alto + fondo) / 2, 0) + normal), Vector3.new(lado, t.alto - fondo, m), t.color, t.material, t.variante)
						table.insert(huecos, { CFrame.new(ext + Vector3.new(0, 1, 0)), Vector3.new(if d[2] ~= 0 then m else lado, 14, if d[1] ~= 0 then m else lado) })
						for _, s in { -1, 1 } do
							if vecina(grilla, f + s * math.abs(d[2]), c + s * math.abs(d[1])) ~= CAMINO then
								local b = centro + tangente * s * (lado / 2 - 0.5) + y
								orilla(carpeta, b + normal * lado / 2, b + normal * (lado / 2 + m))
							end
						end
					end
				end
				if estilo.orilla == "cordon" then
					-- Línea amarilla discontinua al medio en los tramos rectos (no en las esquinas).
					local h = vecina(grilla, f, c - 1) ~= CAMINO and vecina(grilla, f, c - 1) ~= nil or vecina(grilla, f, c + 1) ~= CAMINO and vecina(grilla, f, c + 1) ~= nil
					local v = vecina(grilla, f - 1, c) ~= CAMINO and vecina(grilla, f - 1, c) ~= nil or vecina(grilla, f + 1, c) ~= CAMINO and vecina(grilla, f + 1, c) ~= nil
					if h ~= v then
						local eje = if h then Vector3.new(0, 0, 1) else Vector3.new(1, 0, 0)
						local p = centro + Vector3.new(0, t.alto + 0.03, 0)
						local raya = bloque(carpeta, CFrame.lookAt(p, p + eje), Vector3.new(0.35, 0.06, lado * 0.45), AMARILLO, Enum.Material.SmoothPlastic)
						raya.CanCollide = false
					end
				end
				if estilo.orilla == "runas" and hash(f * 3 + 2, c * 7) % 3 == 0 then
					-- Runa en el piso: el sello de Strange, tenue.
					local p = centro + Vector3.new(0, t.alto + 0.03, 0)
					local runa = bloque(carpeta, CFrame.new(p), Vector3.new(lado * 0.7, 0.05, lado * 0.7), blanco, Enum.Material.SmoothPlastic)
					runa.Transparency, runa.CanCollide, runa.CanQuery = 1, false, false
					local sello = Instance.new("Decal")
					sello.Texture = "rbxassetid://" .. SELLO
					sello.Color3 = Color3.fromRGB(255, 150, 50)
					sello.Transparency = 0.35
					sello.Face = Enum.NormalId.Top
					sello.Parent = runa
				end
				if estilo.vapor and hash(f * 5 + 1, c * 3) % 7 == 0 then
					-- Alcantarilla con vapor.
					local p = centro + Vector3.new(lado * 0.2, t.alto + 0.04, 0)
					local tapa = bloque(carpeta, CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.08, 2.2, 2.2), Color3.fromRGB(60, 58, 55), Enum.Material.DiamondPlate)
					tapa.Shape = Enum.PartType.Cylinder
					tapa.CanCollide = false
					local humo = Instance.new("ParticleEmitter")
					humo.Color = ColorSequence.new(Color3.fromRGB(235, 235, 235))
					humo.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
					humo.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4) })
					humo.Lifetime = NumberRange.new(2, 3.5)
					humo.Rate = 6
					humo.Speed = NumberRange.new(2, 4)
					humo.SpreadAngle = Vector2.new(12, 12)
					humo.EmissionDirection = Enum.NormalId.Right -- el cilindro está acostado: +X local es hacia arriba
					humo.Parent = tapa
				end
			end
			if codigo == AGUA then
				table.insert(agua, { CFrame.new(centro + Vector3.new(0, (t.alto + Mapa.NIVEL_AGUA) / 2, 0)), Vector3.new(lado, Mapa.NIVEL_AGUA - t.alto, lado) })
			end
			table.insert(celdas, { codigo = codigo, centro = centro + Vector3.new(0, t.alto, 0), f = f, c = c })
		end
	end

	local ruta = {}
	for _, punto in Mapa.rutaPixeles(nivel) do
		table.insert(ruta, Mapa.aMundo(punto.x, punto.y, origen))
	end
	-- Ancho del camino donde entra: celdas de camino contiguas en el borde, a lo ancho de la entrada.
	local rp = Mapa.rutaPixeles(nivel)
	local fe = math.clamp(math.floor((rp[1].y + rp[2].y) / 2 / ladoPx) + 1, 1, filas)
	local ce = math.clamp(math.floor((rp[1].x + rp[2].x) / 2 / ladoPx) + 1, 1, cols)
	local horizontal = ruta[2].X ~= ruta[1].X
	local anchoCeldas = if vecina(grilla, fe, ce) == CAMINO then 1 else 0
	for _, s in { -1, 1 } do
		local k = s
		while vecina(grilla, if horizontal then fe + k else fe, if horizontal then ce else ce + k) == CAMINO do
			anchoCeldas += 1
			k += s
		end
	end
	local anchoCamino = math.max(1, anchoCeldas) * lado

	-- Terreno: pasto 3D en el mapa y en el borde caminable, agua, y huecos donde el hangar sale del mapa.
	local ancho, alto = Mapa.ANCHO * Mapa.ESCALA, Mapa.ALTO * Mapa.ESCALA
	local m = Mapa.MARGEN
	local suelo = aspecto(nivel, PASTO)
	for _, franja in {
		{ Vector3.new(ancho / 2, 0, -m / 2), Vector3.new(ancho + 2 * m, 0, m) },
		{ Vector3.new(ancho / 2, 0, alto + m / 2), Vector3.new(ancho + 2 * m, 0, m) },
		{ Vector3.new(-m / 2, 0, alto / 2), Vector3.new(m, 0, alto) },
		{ Vector3.new(ancho + m / 2, 0, alto / 2), Vector3.new(m, 0, alto) },
	} do
		if suelo.terreno then
			table.insert(pasto, { CFrame.new(origen + franja[1] + Vector3.new(0, (suelo.alto - DESFASE + fondo) / 2, 0)), franja[2] + Vector3.new(0, suelo.alto - DESFASE - fondo, 0), suelo.terrenoMaterial })
		else
			-- Vereda de bloques: rectángulos de la franja menos los huecos por donde sale el camino.
			local c0 = origen + franja[1]
			local trozos = { { c0.X - franja[2].X / 2, c0.Z - franja[2].Z / 2, c0.X + franja[2].X / 2, c0.Z + franja[2].Z / 2 } }
			for _, h in huecos do
				local hp, ht = h[1].Position, h[2]
				local a = { hp.X - ht.X / 2, hp.Z - ht.Z / 2, hp.X + ht.X / 2, hp.Z + ht.Z / 2 }
				local nuevos = {}
				for _, q in trozos do
					if a[1] >= q[3] or a[3] <= q[1] or a[2] >= q[4] or a[4] <= q[2] then
						table.insert(nuevos, q)
					else
						for _, k in {
							{ q[1], q[2], a[1], q[4] }, -- izquierda
							{ a[3], q[2], q[3], q[4] }, -- derecha
							{ math.max(q[1], a[1]), q[2], math.min(q[3], a[3]), a[2] }, -- arriba
							{ math.max(q[1], a[1]), a[4], math.min(q[3], a[3]), q[4] }, -- abajo
						} do
							if k[3] - k[1] > 0.05 and k[4] - k[2] > 0.05 then
								table.insert(nuevos, k)
							end
						end
					end
				end
				trozos = nuevos
			end
			for _, q in trozos do
				bloque(carpeta, CFrame.new((q[1] + q[3]) / 2, origen.Y + (suelo.alto + fondo) / 2, (q[2] + q[4]) / 2), Vector3.new(q[3] - q[1], suelo.alto - fondo, q[4] - q[2]), suelo.color, suelo.material, suelo.variante)
			end
		end
	end
	local terreno = workspace.Terrain
	for _, r in pasto do
		terreno:FillBlock(r[1], r[2], r[3] or Enum.Material.Grass)
	end
	for _, r in huecos do
		terreno:FillBlock(r[1], r[2], Enum.Material.Air)
	end
	for _, r in agua do
		terreno:FillBlock(r[1], r[2], Enum.Material.Water)
	end
	carpeta:SetAttribute("Agua", #agua)
	agregarDecorado(nivel, carpeta, celdas, lado, origen, ruta, anchoCamino, grilla)
	porton(nivel, carpeta, ruta[1] - Vector3.new(0, 1 - aspecto(nivel, CAMINO).alto, 0), ((ruta[2] - ruta[1]) * Vector3.new(1, 0, 1)).Unit, anchoCamino)

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

	-- Base que defienden: modelo "base" del kit del mapa o un bloque de luz.
	local kitBase = kit(nivel, "base")
	if kitBase then
		local b = clonarKit(kitBase, "Y", 11)
		b:PivotTo(CFrame.lookAt(ruta[#ruta], ruta[#ruta - 1] * Vector3.new(1, 0, 1) + Vector3.new(0, ruta[#ruta].Y, 0)) * CFrame.new(0, b:GetExtentsSize().Y / 2 - 1, 0))
		b.Name = "Base"
		b.Parent = carpeta
	else
		local base = bloque(carpeta, CFrame.new(ruta[#ruta] + Vector3.new(0, 5, 0)), Vector3.new(6, 10, 6), Color3.fromRGB(240, 170, 40), Enum.Material.Neon)
		base.Name = "Base"
	end

	carpeta.Parent = padre
	return ruta, carpeta
end

-- Borra el terreno (pasto y agua) de un mapa construido; el resto se borra con el modelo.
function Mapa.limpiar(_nivel, origen: Vector3)
	local m = Mapa.MARGEN + 8
	local ancho, alto = Mapa.ANCHO * Mapa.ESCALA, Mapa.ALTO * Mapa.ESCALA
	workspace.Terrain:FillBlock(CFrame.new(origen + Vector3.new(ancho / 2, 0, alto / 2)), Vector3.new(ancho + 2 * m, 24, alto + 2 * m), Enum.Material.Air)
end

return Mapa
