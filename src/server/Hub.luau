-- Plaza del HUB, portada de src/render/hub.js y src/game/hub.js del 3D: piso de 42×42,
-- emblema central, cinco estaciones-portal, árboles, borde de luz y horizonte de edificios.
-- Cada estación tiene un ProximityPrompt (tecla E) que llama a alUsar(jugador, id).
local Hub = {}

Hub.ESTACIONES = {
	{ id = "story", nombre = "HISTORIA", subtitulo = "Base Avengers", color = Color3.fromHex("64e5ff"), x = -9, z = -8 },
	{ id = "infinite", nombre = "INFINITO", subtitulo = "Resistí una oleada más", color = Color3.fromHex("b69aff"), x = 9, z = -8 },
	{ id = "summon", nombre = "INVOCACIONES", subtitulo = "Centro de reclutamiento", color = Color3.fromHex("ffcf72"), x = -14, z = 3 },
	{ id = "traits", nombre = "TRAITS", subtitulo = "Laboratorio de habilidades", color = Color3.fromHex("7eefa9"), x = 14, z = 3 },
	{ id = "grades", nombre = "GRADES", subtitulo = "Centro de entrenamiento", color = Color3.fromHex("ff8faa"), x = 10, z = 14 },
}

local ALTO_PISO = 1 -- la plaza se apoya sobre el Baseplate (y = 0)

local function bloque(padre, color: string | Color3, pos: Vector3, tam: Vector3, neon: boolean?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Color = if typeof(color) == "string" then Color3.fromHex(color) else color
	p.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Size = tam
	p.Position = pos + Vector3.new(0, ALTO_PISO, 0)
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

local function disco(padre, color, pos: Vector3, diametro: number, alto: number, neon: boolean?): Part
	local p = bloque(padre, color, pos, Vector3.new(alto, diametro, diametro), neon)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, 0, math.rad(90))
	return p
end

local function cartel(padre: BasePart, titulo: string, subtitulo: string?, color: Color3, ancho: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(ancho, ancho / 4)
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, if subtitulo then 0.65 else 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = color
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

function Hub.construir(alUsar: (Player, string) -> ())
	local viejo = workspace:FindFirstChild("Hub")
	if viejo then
		viejo:Destroy()
	end
	local hub = Instance.new("Model")
	hub.Name = "Hub"

	-- Piso, caminos en cruz y borde de luz.
	bloque(hub, "233b53", Vector3.new(0, -0.6, 0), Vector3.new(42, 1.2, 42))
	bloque(hub, "496275", Vector3.new(0, 0.015, 0), Vector3.new(6, 0.03, 39))
	bloque(hub, "496275", Vector3.new(0, 0.02, 3), Vector3.new(39, 0.03, 5))
	for _, x in { -20, 20 } do
		bloque(hub, "93e6ed", Vector3.new(x, 0.3, 0), Vector3.new(0.12, 0.12, 40), true)
		bloque(hub, "93e6ed", Vector3.new(0, 0.3, x), Vector3.new(40, 0.12, 0.12), true)
	end

	-- Emblema central.
	disco(hub, "102b44", Vector3.new(0, 0.1, -3), 3.4, 0.2)
	disco(hub, "64e5ff", Vector3.new(0, 0.22, -3), 3, 0.035, true)
	local centro = disco(hub, "18374e", Vector3.new(0, 0.26, -3), 2.85, 0.04)
	cartel(centro, "A", nil, Color3.fromHex("a4f1ff"), 3)

	-- Estaciones.
	for _, e in Hub.ESTACIONES do
		local x, z = e.x, e.z
		local base = disco(hub, "152438", Vector3.new(x, 0.18, z), 3.2, 0.36)
		base.Name = "Estacion_" .. e.id
		disco(hub, e.color, Vector3.new(x, 0.38, z), 2.9, 0.035, true)
		disco(hub, "23354b", Vector3.new(x, 0.41, z), 2.75, 0.04)
		bloque(hub, "172e48", Vector3.new(x, 2.8, z - 1.7), Vector3.new(6, 5.6, 0.7))
		for _, lado in { -1, 1 } do
			bloque(hub, e.color, Vector3.new(x + lado * 2.5, 2.6, z - 1.22), Vector3.new(0.13, 4.7, 0.12), true)
		end
		bloque(hub, e.color, Vector3.new(x, 5, z - 1.22), Vector3.new(5.1, 0.14, 0.12), true)
		-- Portal: anillo de luz y orbe que gira.
		for _, aro in { disco(hub, e.color, Vector3.new(x, 2.7, z - 1.16), 3.3, 0.1, true), disco(hub, "172e48", Vector3.new(x, 2.7, z - 1.12), 3.05, 0.1) } do
			aro.CFrame = CFrame.new(aro.Position) * CFrame.Angles(0, math.rad(90), 0) -- de pie, mirando a +Z
		end
		local orbe = bloque(hub, e.color, Vector3.new(x, 2.7, z - 0.9), Vector3.new(0.9, 0.9, 0.9), true)
		orbe.Name = "Orbe"
		orbe.CFrame = CFrame.new(orbe.Position) * CFrame.Angles(math.rad(45), 0, math.rad(45))
		local letrero = bloque(hub, e.color, Vector3.new(x, 6.1, z - 1), Vector3.new(0.1, 0.1, 0.1))
		letrero.Transparency = 1
		cartel(letrero, e.nombre, e.subtitulo, e.color, 8)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = e.nombre
		prompt.ObjectText = e.subtitulo
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = false
		prompt.Triggered:Connect(function(jugador)
			alUsar(jugador, e.id)
		end)
		prompt.Parent = base
	end

	-- Árboles.
	for _, x in { -6, 6 } do
		for _, z in { 5, 11 } do
			disco(hub, "14283a", Vector3.new(x, 0.3, z), 0.8, 0.6)
			disco(hub, "506360", Vector3.new(x, 1.3, z), 0.26, 2)
			local copa = bloque(hub, "479586", Vector3.new(x, 2.7, z), Vector3.new(1.6, 1.6, 1.6))
			copa.Shape = Enum.PartType.Ball
		end
	end

	-- Horizonte: 24 edificios en círculo con franjas de ventanas.
	for i = 0, 23 do
		local angulo = i / 24 * math.pi * 2
		local x, z = math.cos(angulo) * 38, math.sin(angulo) * 38
		local alto = 7 + (i * 7 % 17)
		bloque(hub, if i % 2 == 1 then "243d57" else "1c324c", Vector3.new(x, alto / 2 - 1, z), Vector3.new(4, alto, 4))
		for y = 0, alto - 3, 2 do
			bloque(hub, "56889c", Vector3.new(x, y + 0.5, z + (if z < 0 then 2.02 else -2.02)), Vector3.new(2.7, 0.35, 0.04), true)
		end
	end

	-- Aparición frente al emblema, mirando a las estaciones.
	local aparicion = Instance.new("SpawnLocation")
	aparicion.Name = "AparicionHub"
	aparicion.Anchored = true
	aparicion.Size = Vector3.new(4, 0.2, 4)
	aparicion.Transparency = 1
	aparicion.CanCollide = false
	aparicion.Neutral = true
	aparicion.Duration = 0
	aparicion.CFrame = CFrame.lookAt(Vector3.new(0, ALTO_PISO + 0.1, 7), Vector3.new(0, ALTO_PISO + 0.1, 0))
	aparicion.Parent = hub

	hub.Parent = workspace
	return hub
end

-- Gira los orbes de las estaciones (llamar en Heartbeat).
function Hub.animar(hub: Model, dt: number)
	for _, o in hub:GetChildren() do
		if o.Name == "Orbe" then
			o.CFrame *= CFrame.Angles(0, dt * 1.5, 0)
		end
	end
end

return Hub
