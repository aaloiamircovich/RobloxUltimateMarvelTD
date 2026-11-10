-- HUB de islas flotantes. La isla central (aparición y Torre Vengadores) se conecta con Asgard por el
-- Bifrost, con Wakanda por un puente de selva, con Nueva York por un puente de telarañas, con la Torre
-- Baxter por una pasarela de vidrio y con el Sanctum por un portal.
-- Cada estación tiene un ProximityPrompt (tecla E) que llama a alUsar(jugador, id).
-- Edificios: ServerStorage.Plantillas.Hub/<hito> si existe (modelos generados); si no, un bloque provisorio.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Hub = {}

local ALTO = 1 -- altura del piso de las islas

local ISLAS = {
	central = { pos = Vector3.new(0, ALTO, 0), radio = 40, color = "5f9e57", material = Enum.Material.Grass },
	asgard = { pos = Vector3.new(0, ALTO + 8, -125), radio = 30, color = "c9b37a", material = Enum.Material.Marble },
	wakanda = { pos = Vector3.new(-125, ALTO, -15), radio = 30, color = "3f8a3c", material = Enum.Material.Grass },
	nuevaYork = { pos = Vector3.new(125, ALTO, -15), radio = 32, color = "6b6f78", material = Enum.Material.Asphalt },
	baxter = { pos = Vector3.new(-85, ALTO, 110), radio = 24, color = "8fa3b8", material = Enum.Material.Concrete },
	sanctum = { pos = Vector3.new(85, ALTO, 110), radio = 24, color = "6b4a35", material = Enum.Material.WoodPlanks },
}

-- Estaciones: isla, ángulo (grados, 0 = +X, 90 = +Z) y distancia al centro de la isla. Miran al centro de su isla.
Hub.ESTACIONES = {
	{ id = "misiones", nombre = "MISIONES", subtitulo = "Próximamente", color = "64e5ff", isla = "central", angulo = 112, r = 24 },
	{ id = "bailes", nombre = "BAILES", subtitulo = "Próximamente", color = "ff8fd8", isla = "central", angulo = -135, r = 27 },
	{ id = "evento", nombre = "EVENTO", subtitulo = "Próximamente", color = "ffb347", isla = "central", angulo = -45, r = 27 },
	{ id = "ranking", nombre = "RANKING", subtitulo = "Próximamente", color = "ffe066", isla = "central", angulo = 20, r = 26 },
	{ id = "monturas", nombre = "MONTURAS", subtitulo = "Próximamente", color = "9be37a", isla = "central", angulo = 160, r = 26 },
	{ id = "summon", nombre = "BANNER 1", subtitulo = "Invocaciones", color = "ffcf72", isla = "asgard", angulo = 120, r = 16 },
	{ id = "banner_2", nombre = "BANNER 2", subtitulo = "Próximamente", color = "ffcf72", isla = "asgard", angulo = 90, r = 18 },
	{ id = "banner_3", nombre = "BANNER 3", subtitulo = "Próximamente", color = "ffcf72", isla = "asgard", angulo = 60, r = 16 },
	{ id = "traits", nombre = "TRAITS", subtitulo = "Próximamente", color = "7eefa9", isla = "wakanda", angulo = -40, r = 17 },
	{ id = "grades", nombre = "GRADES", subtitulo = "Próximamente", color = "ff8faa", isla = "wakanda", angulo = 0, r = 19 },
	{ id = "pets", nombre = "PETS", subtitulo = "Próximamente", color = "b69aff", isla = "wakanda", angulo = 40, r = 17 },
	{ id = "raids", nombre = "RAIDS", subtitulo = "Próximamente", color = "ff6b6b", isla = "nuevaYork", angulo = 220, r = 17 },
	{ id = "misiones_raid", nombre = "MISIONES DE RAID", subtitulo = "Próximamente", color = "ff9f6b", isla = "nuevaYork", angulo = 180, r = 20 },
	{ id = "tienda", nombre = "TIENDA", subtitulo = "Objetos", color = "40c9ff", isla = "nuevaYork", angulo = 140, r = 17 },
	{ id = "infinite", nombre = "INFINITO", subtitulo = "Resistí una oleada más", color = "6fb5ff", isla = "baxter", angulo = -52, r = 11 },
	{ id = "story", nombre = "HISTORIA", subtitulo = "Modo campaña", color = "ff8f3d", isla = "sanctum", angulo = 232, r = 11 },
}

-- Edificios: isla, posición relativa (x, z), alto deseado y huella de la caja provisoria.
local HITOS = {
	{ id = "torre_vengadores", isla = "central", x = 0, z = -4, alto = 34, huella = 10, color = "cfd8e3" },
	{ id = "castillo_asgard", isla = "asgard", x = 0, z = -10, alto = 30, huella = 22, color = "e0b84a" },
	{ id = "palacio_wakanda", isla = "wakanda", x = -12, z = 0, alto = 18, huella = 16, color = "4b2d6b" },
	{ id = "empire_state", isla = "nuevaYork", x = 12, z = -10, alto = 40, huella = 9, color = "b7b2a6" },
	{ id = "daily_bugle", isla = "nuevaYork", x = 12, z = 12, alto = 22, huella = 10, color = "8a6f5a" },
	{ id = "torre_baxter", isla = "baxter", x = -5, z = 6, alto = 32, huella = 9, color = "3a6fd8" },
	{ id = "sanctum", isla = "sanctum", x = 5, z = 6, alto = 16, huella = 12, color = "7a3b2e" },
}

local function parte(padre, color, cf: CFrame, tam: Vector3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Color = if typeof(color) == "string" then Color3.fromHex(color) else color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Size = tam
	p.CFrame = cf
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

-- Disco horizontal (cilindro acostado) con la cara superior en y.
local function disco(padre, color, centro: Vector3, diametro: number, alto: number, material: Enum.Material?): Part
	local p = parte(padre, color, CFrame.new(centro - Vector3.new(0, alto / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(alto, diametro, diametro), material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function cartel(padre: BasePart, titulo: string, subtitulo: string?, color: Color3, ancho: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(ancho, ancho / 4)
	gui.LightInfluence = 0
	gui.MaxDistance = 150
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, if subtitulo then 0.65 else 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.4
	t.Text = titulo
	t.Parent = gui
	if subtitulo then
		local s = t:Clone()
		s.Position = UDim2.fromScale(0, 0.65)
		s.Size = UDim2.fromScale(1, 0.35)
		s.Font = Enum.Font.GothamMedium
		s.TextColor3 = Color3.new(1, 1, 1)
		s.Text = subtitulo
		s.Parent = gui
	end
	gui.Parent = padre
end

local function letrero(padre, pos: Vector3, titulo, subtitulo, color: Color3, ancho)
	local ancla = parte(padre, color, CFrame.new(pos), Vector3.new(0.1, 0.1, 0.1))
	ancla.Transparency, ancla.CanCollide, ancla.CanQuery = 1, false, false
	cartel(ancla, titulo, subtitulo, color, ancho)
end

local function enIsla(isla, angulo: number, r: number): Vector3
	local a = math.rad(angulo)
	return isla.pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

-- Isla: tapa de terreno, borde y una raíz de roca que se afina hacia abajo.
local function isla(padre, datos)
	local m = Instance.new("Model")
	disco(m, datos.color, datos.pos, datos.radio * 2, 3, datos.material)
	disco(m, "6d5a48", datos.pos - Vector3.new(0, 3, 0), datos.radio * 2 - 1, 3, Enum.Material.Ground)
	for i, f in { 0.82, 0.62, 0.42, 0.24 } do
		disco(m, if i % 2 == 0 then "5b5249" else "675c50", datos.pos - Vector3.new(0, 2 + i * 5, 0), datos.radio * 2 * f, 5.5, Enum.Material.Rock)
	end
	m.Parent = padre
end

-- Puente entre dos puntos del borde de las islas, con barandas invisibles para no caerse.
local ARCOIRIS = { "ff4d4d", "ff9f40", "ffe14d", "5cff7a", "4dc3ff", "6b6bff", "c46bff" }
local function puente(padre, a: Vector3, b: Vector3, estilo: string)
	local m = Instance.new("Model")
	m.Name = "Puente_" .. estilo
	local largo = (b - a).Magnitude
	local ancho = if estilo == "bifrost" then 7 else 6
	local paso = 2
	local n = math.ceil(largo / paso)
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		local caida = if estilo == "selva" or estilo == "telarana" then -math.sin(math.pi * t) * 2.5 else 0
		local p = a:Lerp(b, t) + Vector3.new(0, caida - 0.25, 0)
		local cf = CFrame.lookAt(p, p + (b - a))
		if estilo == "bifrost" then
			local tabla = parte(m, ARCOIRIS[i % #ARCOIRIS + 1], cf, Vector3.new(ancho, 0.5, paso + 0.05), Enum.Material.Neon)
			tabla.Transparency = 0.15
		elseif estilo == "selva" then
			parte(m, if i % 2 == 0 then "8a5a33" else "7a4e2b", cf, Vector3.new(ancho, 0.4, paso - 0.25), Enum.Material.WoodPlanks)
			if i % 3 == 0 then
				for _, lado in { -1, 1 } do
					parte(m, "5a3b20", cf * CFrame.new(lado * (ancho / 2 + 0.2), 1.6, 0), Vector3.new(0.5, 3.6, 0.5), Enum.Material.Wood)
					parte(m, "3f8a3c", cf * CFrame.new(lado * (ancho / 2 + 0.2), 3, 0), Vector3.new(0.6, 0.6, paso * 3), Enum.Material.Grass)
				end
			end
		elseif estilo == "telarana" then
			-- Hilos a lo largo, travesaños y, cada tanto, hilos en diagonal hacia las barandas.
			for _, x in { -2.4, -1.2, 0, 1.2, 2.4 } do
				parte(m, "f2f2f2", cf * CFrame.new(x, 0, 0), Vector3.new(0.18, 0.18, paso + 0.1))
			end
			parte(m, "e6e6e6", cf, Vector3.new(ancho, 0.15, 0.15))
			for _, lado in { -1, 1 } do
				parte(m, "f2f2f2", cf * CFrame.new(lado * ancho / 2, 2.4, 0), Vector3.new(0.15, 0.15, paso + 0.1))
				if i % 2 == 0 then
					parte(m, "e6e6e6", cf * CFrame.new(lado * ancho / 2, 1.2, 0) * CFrame.Angles(math.rad(45), 0, 0), Vector3.new(0.12, 0.12, 3.4))
				end
			end
			local piso = parte(m, "ffffff", cf, Vector3.new(ancho, 0.3, paso + 0.05))
			piso.Transparency = 1
		elseif estilo == "baxter" then
			local vidrio = parte(m, "bfe4ff", cf, Vector3.new(ancho, 0.4, paso + 0.05), Enum.Material.Glass)
			vidrio.Transparency = 0.35
			for _, lado in { -1, 1 } do
				parte(m, "3a8bff", cf * CFrame.new(lado * ancho / 2, 1.2, 0), Vector3.new(0.15, 0.15, paso + 0.05), Enum.Material.Neon)
				if i % 5 == 0 then
					local poste = parte(m, "dfe8f2", cf * CFrame.new(lado * ancho / 2, 0.6, 0), Vector3.new(0.3, 1.2, 0.3), Enum.Material.Metal)
					if i % 10 == 0 and lado == 1 then
						cartel(poste, "4", nil, Color3.fromHex("3a8bff"), 2)
					end
				end
			end
		end
		for _, lado in { -1, 1 } do
			local baranda = parte(m, "ffffff", cf * CFrame.new(lado * (ancho / 2 + 0.5), 2, 0), Vector3.new(0.4, 4, paso + 0.05))
			baranda.Transparency, baranda.CanQuery = 1, false
		end
	end
	m.Parent = padre
end

-- Punto del borde de la isla `de` en dirección a la isla `a`.
local function borde(de, a): Vector3
	local d = (a.pos - de.pos) * Vector3.new(1, 0, 1)
	return de.pos + d.Unit * (de.radio - 1.5)
end

-- Portal de pie: tocarlo lleva al jugador a `destino`.
local function portal(padre, pos: Vector3, mira: Vector3, destino: CFrame)
	local m = Instance.new("Model")
	m.Name = "Portal"
	local cf = CFrame.lookAt(pos + Vector3.new(0, 5, 0), mira + Vector3.new(0, 5, 0))
	local aro = parte(m, "ff6a00", cf * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.6, 9.5, 9.5), Enum.Material.Neon)
	aro.Shape = Enum.PartType.Cylinder
	local centro = parte(m, "ff7a1a", cf * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.8, 8.6, 8.6), Enum.Material.Neon)
	centro.Shape = Enum.PartType.Cylinder
	centro.Transparency = 0.65
	centro.CanCollide = false
	aro.CanCollide = false
	local chispas = Instance.new("ParticleEmitter")
	chispas.Color = ColorSequence.new(Color3.fromHex("ffb84d"))
	chispas.LightEmission = 1
	chispas.Size = NumberSequence.new(0.25, 0)
	chispas.Lifetime = NumberRange.new(0.5, 1)
	chispas.Rate = 60
	chispas.Speed = NumberRange.new(2, 4)
	chispas.SpreadAngle = Vector2.new(180, 180)
	chispas.Parent = aro
	local recien = {}
	centro.Touched:Connect(function(otro)
		local personaje = otro.Parent
		local jugador = Players:GetPlayerFromCharacter(personaje)
		if not jugador or (recien[jugador] and os.clock() - recien[jugador] < 2) then
			return
		end
		recien[jugador] = os.clock()
		personaje:PivotTo(destino)
	end)
	m.Parent = padre
end

-- Estación: base con luz, marco con portal y orbe que gira, cartel y ProximityPrompt.
local function estacion(padre, e, alUsar)
	local datos = ISLAS[e.isla]
	local pos = enIsla(datos, e.angulo, e.r)
	local cf = CFrame.lookAt(pos, Vector3.new(datos.pos.X, pos.Y, datos.pos.Z))
	local color = Color3.fromHex(e.color)
	local m = Instance.new("Model")
	m.Name = "Estacion_" .. e.id
	local base = disco(m, "152438", pos + Vector3.new(0, 0.36, 0), 3.2, 0.36)
	base.Name = "Base"
	disco(m, color, pos + Vector3.new(0, 0.39, 0), 2.9, 0.035, Enum.Material.Neon)
	-- El marco queda detrás de la base (lejos del centro de la isla) y mira hacia el centro.
	parte(m, "172e48", cf * CFrame.new(0, 2.8, 1.7), Vector3.new(6, 5.6, 0.7))
	for _, lado in { -1, 1 } do
		parte(m, color, cf * CFrame.new(lado * 2.5, 2.6, 1.22), Vector3.new(0.13, 4.7, 0.12), Enum.Material.Neon)
	end
	parte(m, color, cf * CFrame.new(0, 5, 1.22), Vector3.new(5.1, 0.14, 0.12), Enum.Material.Neon)
	local aro = parte(m, color, cf * CFrame.new(0, 2.7, 1.16) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.1, 3.3, 3.3), Enum.Material.Neon)
	aro.Shape = Enum.PartType.Cylinder
	local orbe = parte(m, color, cf * CFrame.new(0, 2.7, 0.9) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Vector3.new(0.9, 0.9, 0.9), Enum.Material.Neon)
	orbe.Name = "Orbe"
	letrero(m, (cf * CFrame.new(0, 6.3, 1)).Position, e.nombre, e.subtitulo, color, 8)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = e.nombre
	prompt.ObjectText = e.subtitulo
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(jugador)
		alUsar(jugador, e.id)
	end)
	prompt.Parent = base
	m.Parent = padre
end

-- 8 plataformas de sala alrededor de la estación del modo.
local function salas(padre, islaId: string, modo: string, anguloCentro: number, alUsar)
	local datos = ISLAS[islaId]
	for i = 1, 8 do
		local angulo = anguloCentro + (i - 4.5) * 22
		local pos = enIsla(datos, angulo, 19)
		local base = disco(padre, "1d2633", pos + Vector3.new(0, 0.3, 0), 4.4, 0.3)
		base.Name = `Sala_{modo}_{i}`
		disco(padre, if modo == "infinite" then "3a7bd5" else "c2571a", pos + Vector3.new(0, 0.33, 0), 4, 0.03)
		letrero(padre, pos + Vector3.new(0, 3, 0), `SALA {i}`, "0/4", Color3.new(1, 1, 1), 4)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Crear sala"
		prompt.ObjectText = `Sala {i}`
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 5
		prompt.RequiresLineOfSight = false
		prompt.Triggered:Connect(function(jugador)
			alUsar(jugador, "sala_" .. modo)
		end)
		prompt.Parent = base
	end
end

-- Edificio: el modelo de ServerStorage.Plantillas.Hub/<id> escalado al alto pedido, o una caja provisoria.
local function hito(padre, h)
	local datos = ISLAS[h.isla]
	local base = datos.pos + Vector3.new(h.x, 0, h.z)
	local mira = CFrame.lookAt(base, Vector3.new(datos.pos.X, base.Y, datos.pos.Z))
	local plantillas = ServerStorage:FindFirstChild("Plantillas")
	local carpeta = plantillas and plantillas:FindFirstChild("Hub")
	local plantilla = carpeta and carpeta:FindFirstChild(h.id)
	if plantilla then
		local m = plantilla:Clone()
		m:ScaleTo(m:GetScale() * h.alto / m:GetExtentsSize().Y)
		-- La plantilla mira a −Z con el pivote en el centro de la caja: apoyarla en el piso.
		m:PivotTo(mira * CFrame.new(0, m:GetExtentsSize().Y / 2, 0))
		m.Name = "Hito_" .. h.id
		m.Parent = padre
		return
	end
	local m = Instance.new("Model")
	m.Name = "Hito_" .. h.id
	parte(m, h.color, mira * CFrame.new(0, h.alto / 2, 0), Vector3.new(h.huella, h.alto, h.huella), Enum.Material.Concrete)
	letrero(m, base + Vector3.new(0, h.alto + 2, 0), (h.id:upper():gsub("_", " ")), nil, Color3.fromHex(h.color), 10)
	m.Parent = padre
end

local function arbol(padre, pos: Vector3, copa: string)
	disco(padre, "5a3b20", pos + Vector3.new(0, 2.5, 0), 0.7, 2.5, Enum.Material.Wood)
	local c = parte(padre, copa, CFrame.new(pos + Vector3.new(0, 3.6, 0)), Vector3.new(3, 3, 3), Enum.Material.Grass)
	c.Shape = Enum.PartType.Ball
end

function Hub.construir(alUsar: (Player, string) -> ())
	local viejo = workspace:FindFirstChild("Hub")
	if viejo then
		viejo:Destroy()
	end
	-- Las islas flotan: sin piso debajo (los mapas de batalla tienen sus propias baldosas).
	local piso = workspace:FindFirstChild("Baseplate")
	if piso then
		piso:Destroy()
	end
	local hub = Instance.new("Model")
	hub.Name = "Hub"

	for _, datos in ISLAS do
		isla(hub, datos)
	end
	local c = ISLAS.central
	puente(hub, borde(c, ISLAS.asgard), borde(ISLAS.asgard, c), "bifrost")
	puente(hub, borde(c, ISLAS.wakanda), borde(ISLAS.wakanda, c), "selva")
	puente(hub, borde(c, ISLAS.nuevaYork), borde(ISLAS.nuevaYork, c), "telarana")
	puente(hub, borde(c, ISLAS.baxter), borde(ISLAS.baxter, c), "baxter")

	-- Portal al Sanctum y de vuelta: cada uno deja al jugador frente al otro.
	local s = ISLAS.sanctum
	local ida = enIsla(c, 52, 33)
	local vuelta = borde(s, c)
	local function frente(p: Vector3, desde: Vector3)
		local d = ((desde - p) * Vector3.new(1, 0, 1)).Unit
		local llegada = p + d * 5 + Vector3.new(0, 3, 0)
		return CFrame.lookAt(llegada, llegada + d)
	end
	portal(hub, ida, c.pos, frente(vuelta, s.pos))
	portal(hub, vuelta, s.pos, frente(ida, c.pos))
	letrero(hub, ida + Vector3.new(0, 11.5, 0), "SANCTUM SANCTORUM", "Portal", Color3.fromHex("ff9a2e"), 12)

	for _, h in HITOS do
		hito(hub, h)
	end
	for _, e in Hub.ESTACIONES do
		estacion(hub, e, alUsar)
	end
	salas(hub, "baxter", "infinite", -52, alUsar)
	salas(hub, "sanctum", "story", 232, alUsar)

	letrero(hub, ISLAS.asgard.pos + Vector3.new(0, 34, -10), "ASGARD", "Invocaciones", Color3.fromHex("ffcf72"), 14)
	letrero(hub, ISLAS.wakanda.pos + Vector3.new(0, 22, 0), "WAKANDA", "Traits · Grades · Pets", Color3.fromHex("b865ff"), 14)
	letrero(hub, ISLAS.nuevaYork.pos + Vector3.new(0, 26, 0), "NUEVA YORK", "Raids · Tienda", Color3.fromHex("40c9ff"), 14)
	letrero(hub, ISLAS.baxter.pos + Vector3.new(0, 36, 0), "TORRE BAXTER", "Modo infinito", Color3.fromHex("6fb5ff"), 14)

	-- Árboles: jardín de la isla central y selva de Wakanda.
	for _, a in { -70, -20, 140, 200 } do
		arbol(hub, enIsla(c, a, 35), "4f9e45")
	end
	for _, a in { 100, 140, 180, 220, 260, 300 } do
		arbol(hub, enIsla(ISLAS.wakanda, a, 25), "2f7a2c")
	end

	-- Aparición al pie de la torre, mirando hacia afuera: las estaciones miran al centro, o sea al jugador.
	local aparicion = Instance.new("SpawnLocation")
	aparicion.Name = "AparicionHub"
	aparicion.Anchored = true
	aparicion.Size = Vector3.new(6, 0.2, 6)
	aparicion.Transparency = 1
	aparicion.CanCollide = false
	aparicion.Neutral = true
	aparicion.Duration = 0
	aparicion.CFrame = CFrame.lookAt(c.pos + Vector3.new(0, 0.1, 10), c.pos + Vector3.new(0, 0.1, 30))
	aparicion.Parent = hub
	Hub.aparicion = aparicion

	hub.Parent = workspace
	Hub.orbes = {}
	for _, d in hub:GetDescendants() do
		if d.Name == "Orbe" then
			table.insert(Hub.orbes, d)
		end
	end
	return hub
end

-- Gira los orbes y devuelve a la aparición a quien cae de las islas (llamar en Heartbeat).
function Hub.animar(_hub: Model, dt: number)
	for _, o in Hub.orbes do
		o.CFrame *= CFrame.Angles(0, dt * 1.5, 0)
	end
	for _, j in Players:GetPlayers() do
		local raiz = j.Character and j.Character:FindFirstChild("HumanoidRootPart")
		if raiz and raiz.Position.Y < -60 then
			j.Character:PivotTo(Hub.aparicion.CFrame + Vector3.new(0, 3, 0))
		end
	end
end

return Hub
