-- Efectos de las unidades en partida (docs/ANIMACION.md), sólo visuales y locales: aparición al colocar,
-- rayo al mejorar, aura con la mejora máxima y humo al vender. «Calidad baja» apaga las partículas (Ajustes.luau).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Comic = require(script.Parent:WaitForChild("Comic"))
local Personajes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personajes"))

local MEJORA_MAXIMA = 5

local function colorDe(modelo: Model): Color3
	local h = Personajes.todos[modelo:GetAttribute("Heroe") or ""]
	return (h and Comic.RAREZA[h.rarity]) or Comic.AMARILLO
end

local function pieza(props): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in props do
		p[k] = v
	end
	p.Parent = workspace
	return p
end

local function animar(objeto: Instance, segundos: number, meta, borrar: boolean?)
	local t = TweenService:Create(objeto, TweenInfo.new(segundos, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), meta)
	if borrar then
		t.Completed:Once(function()
			objeto:Destroy()
		end)
	end
	t:Play()
end

-- Chispas que salen una sola vez desde una pieza.
local function chispas(padre: BasePart, color: Color3, cantidad: number, velocidad: number)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(velocidad * 0.6, velocidad)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = padre
	e:Emit(cantidad)
end

local function piso(modelo: Model): Vector3
	local cf, tam = modelo:GetBoundingBox()
	return cf.Position - Vector3.new(0, tam.Y / 2 - 0.1, 0)
end

local function aparecer(modelo: Model)
	local color = colorDe(modelo)
	local base = piso(modelo)
	-- Anillo que se abre en el piso y destello.
	local anillo = pieza({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = 0.2, Size = Vector3.new(0.15, 1, 1), CFrame = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90)) })
	animar(anillo, 0.45, { Size = Vector3.new(0.15, 9, 9), Transparency = 1 }, true)
	local destello = pieza({ Shape = Enum.PartType.Ball, Color = Color3.new(1, 1, 1), Transparency = 0.3, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(base + Vector3.new(0, 2, 0)) })
	chispas(destello, color, 18, 14)
	animar(destello, 0.35, { Size = Vector3.new(5, 5, 5), Transparency = 1 })
	task.delay(1, function()
		destello:Destroy()
	end)
end

local function mejorar(modelo: Model)
	local color = colorDe(modelo)
	local base = piso(modelo)
	-- Columna de luz que sube y se apaga, con estrellas.
	local rayo = pieza({ Shape = Enum.PartType.Cylinder, Color = color, Transparency = 0.25, Size = Vector3.new(0.5, 3.2, 3.2), CFrame = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90)) })
	animar(rayo, 0.5, { Size = Vector3.new(14, 3.2, 3.2), CFrame = CFrame.new(base + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 1 }, true)
	local centro = pieza({ Transparency = 1, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(base + Vector3.new(0, 3, 0)) })
	chispas(centro, color, 24, 10)
	task.delay(1.2, function()
		centro:Destroy()
	end)
end

-- Aura suave y permanente para la mejora máxima.
local function aura(modelo: Model)
	local raiz = modelo:FindFirstChild("HumanoidRootPart")
	if not raiz or raiz:FindFirstChild("AuraMaxima") then
		return
	end
	local color = colorDe(modelo)
	local e = Instance.new("ParticleEmitter")
	e.Name = "AuraMaxima"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.8
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.9, 1.4)
	e.Speed = NumberRange.new(2, 4)
	e.Acceleration = Vector3.new(0, 3, 0)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 26
	e.Parent = raiz
	local luz = Instance.new("PointLight")
	luz.Name = "AuraLuz"
	luz.Color = color
	luz.Brightness = 2.5
	luz.Range = 10
	luz.Parent = raiz
end

-- Anillo de rareza bajo los pies (Épico para arriba): círculo que gira despacio; Legendario con chispas, Mítico
-- arcoíris con luz, Secreto turquesa. Se dibuja con un SurfaceGui sobre una placa invisible que sigue a la unidad.
local ORDEN = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Secret = 6 }
local ARCOIRIS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 70)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 230, 120)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 110, 255)),
})
local anillos = {} -- [modelo] = { placa, gradientes }
local function anillo(modelo: Model)
	local h = Personajes.todos[modelo:GetAttribute("Heroe") or ""]
	local orden = h and ORDEN[h.rarity] or 1
	if orden < ORDEN.Epic or anillos[modelo] then
		return
	end
	local color = colorDe(modelo)
	local _, tam = modelo:GetBoundingBox()
	local lado = math.clamp(math.max(tam.X, tam.Z) * 1.6, 5, 9)
	local placa = pieza({ Transparency = 1, Size = Vector3.new(lado, 0.05, lado), CFrame = CFrame.new(piso(modelo)) })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.CanvasSize = Vector2.new(200, 200)
	gui.Parent = placa
	local gradientes = {}
	for i, r in { { 0, 10 }, { 30, 4 } } do
		local aro = Instance.new("Frame")
		aro.AnchorPoint = Vector2.new(0.5, 0.5)
		aro.Position = UDim2.fromScale(0.5, 0.5)
		aro.Size = UDim2.new(1, -r[1] * 2 - 12, 1, -r[1] * 2 - 12)
		aro.BackgroundTransparency = 1
		aro.Parent = gui
		local esquina = Instance.new("UICorner")
		esquina.CornerRadius = UDim.new(1, 0)
		esquina.Parent = aro
		local trazo = Instance.new("UIStroke")
		trazo.Color = if h.rarity == "Mythic" then Color3.new(1, 1, 1) else color
		trazo.Thickness = r[2]
		trazo.Transparency = if i == 1 then 0.1 else 0.45
		trazo.Parent = aro
		if h.rarity == "Mythic" then
			local g = Instance.new("UIGradient")
			g.Color = ARCOIRIS
			g.Parent = trazo
			table.insert(gradientes, g)
		end
		-- Cuatro marcas sobre el aro de afuera, que giran con él.
		if i == 1 then
			for k = 0, 3 do
				local marca = Instance.new("Frame")
				marca.AnchorPoint = Vector2.new(0.5, 0.5)
				marca.Size = UDim2.fromOffset(16, 16)
				marca.Rotation = 45
				marca.BackgroundColor3 = color
				marca.BorderSizePixel = 0
				local a = k * math.pi / 2
				marca.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.47, 0.5 + math.sin(a) * 0.47)
				marca.Parent = aro
			end
			table.insert(gradientes, aro)
		end
	end
	if orden >= ORDEN.Legendary then
		local e = Instance.new("ParticleEmitter")
		e.Color = if h.rarity == "Mythic" then ARCOIRIS else ColorSequence.new(color)
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		e.Lifetime = NumberRange.new(0.8, 1.4)
		e.Speed = NumberRange.new(1.5, 3)
		e.EmissionDirection = Enum.NormalId.Top
		e.SpreadAngle = Vector2.new(20, 20)
		e.Rate = if orden >= ORDEN.Mythic then 18 else 10
		e.Parent = placa
	end
	if orden >= ORDEN.Mythic then
		local luz = Instance.new("PointLight")
		luz.Color, luz.Range, luz.Brightness = color, 9, 1.5
		luz.Parent = placa
	end
	anillos[modelo] = { placa = placa, giran = gradientes, raiz = modelo:FindFirstChild("HumanoidRootPart"), suelo = nil, medido = 0 }
	modelo.AncestryChanged:Connect(function()
		if not modelo:IsDescendantOf(workspace) and anillos[modelo] then
			anillos[modelo].placa:Destroy()
			anillos[modelo] = nil
		end
	end)
end
-- Altura del piso bajo la unidad (se vuelve a medir cada segundo: el servidor la reacomoda al apoyar los pies).
local filtro = RaycastParams.new()
filtro.FilterType = Enum.RaycastFilterType.Exclude
local function medirSuelo(modelo: Model, a)
	filtro.FilterDescendantsInstances = { modelo, a.placa }
	local golpe = a.raiz and workspace:Raycast(a.raiz.Position, Vector3.new(0, -40, 0), filtro)
	a.suelo = if golpe then golpe.Position.Y else piso(modelo).Y
	a.medido = os.clock()
end
RunService.RenderStepped:Connect(function(dt)
	for modelo, a in anillos do
		if not a.suelo or os.clock() - a.medido > 1 then
			medirSuelo(modelo, a)
		end
		local p = if a.raiz then a.raiz.Position else piso(modelo)
		-- Un poco arriba del piso: el pasto 3D tapa lo que está al ras.
		a.placa.CFrame = CFrame.new(p.X, a.suelo + 0.5, p.Z) * CFrame.Angles(0, os.clock() * 0.6, 0)
		for _, g in a.giran do
			g.Rotation += dt * 40
		end
	end
end)

local function vender(modelo: Model)
	local base = piso(modelo)
	local humo = pieza({ Transparency = 1, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(base + Vector3.new(0, 2, 0)) })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(180, 180, 190))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.6, 1)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = humo
	e:Emit(20)
	task.delay(1.5, function()
		humo:Destroy()
	end)
	for _, d in modelo:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			animar(d, 0.5, { Transparency = 1 })
		end
	end
end

local function seguir(modelo: Instance)
	if not modelo:IsA("Model") or modelo:GetAttribute("Uid") == nil then
		return
	end
	task.defer(aparecer, modelo)
	task.delay(0.5, anillo, modelo) -- después de que el servidor la apoye
	local mejora = modelo:GetAttribute("Mejora") or 0
	if mejora >= MEJORA_MAXIMA then
		aura(modelo)
	end
	modelo:GetAttributeChangedSignal("Mejora"):Connect(function()
		local nueva = modelo:GetAttribute("Mejora") or 0
		if nueva > mejora then
			mejorar(modelo)
			if nueva >= MEJORA_MAXIMA then
				aura(modelo)
			end
		end
		mejora = nueva
	end)
	modelo:GetAttributeChangedSignal("Vendida"):Connect(function()
		if modelo:GetAttribute("Vendida") then
			vender(modelo)
		end
	end)
end

local partidas = workspace:WaitForChild("Partidas")
partidas.DescendantAdded:Connect(seguir)
for _, d in partidas:GetDescendants() do
	seguir(d)
end
