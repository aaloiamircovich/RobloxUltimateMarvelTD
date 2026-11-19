-- Enemigos con más vida (docs/UNIDADES_VISUAL.md, fase E), sólo local:
--  · Golpe: destello blanco corto al perder vida (atributo Vida del bloque raíz).
--  · Estados (atributo Estados, lo publica Partida): efecto en el cuerpo y un ícono chico sobre la barra de vida.
--  · Fases de jefe (atributo FaseJefe "etapa:tipo:n"): al preparar, rugido y anillo de aviso; al activarse, el efecto
--    según el tipo (escudo, refuerzos, furia, sigilo, cura, aturdir).
-- «Calidad baja» (Ajustes) apaga partículas; los íconos quedan.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Ajustes = require(script.Parent:WaitForChild("Ajustes"))

local RUGIDO = "rbxassetid://76750798382441" -- rugido de jefe (IA de Roblox, 2 s)
local MAX_DESTELLOS = 18 -- Roblox dibuja como mucho 31 Highlight a la vez

local ESTADOS = {
	slow = { icono = "❄", color = Color3.fromRGB(120, 200, 255), particula = "nieve" },
	burn = { icono = "🔥", color = Color3.fromRGB(255, 120, 40), particula = "fuego" },
	poison = { icono = "☠", color = Color3.fromRGB(110, 230, 90), particula = "burbujas" },
	stun = { icono = "💫", color = Color3.fromRGB(255, 220, 80), particula = "estrellas" },
	curse = { icono = "🔮", color = Color3.fromRGB(190, 90, 255), particula = "maldicion" },
	mark = { icono = "🎯", color = Color3.fromRGB(255, 70, 70) },
	armorBreak = { icono = "🛡", color = Color3.fromRGB(200, 200, 210) },
	haste = { icono = "⚡", color = Color3.fromRGB(255, 170, 60) },
}

local destellos = 0
local function destello(cuerpo: BasePart)
	local modelo = cuerpo:FindFirstChildWhichIsA("Model") or cuerpo
	if destellos >= MAX_DESTELLOS or modelo:FindFirstChild("Golpe") then
		return
	end
	destellos += 1
	local h = Instance.new("Highlight")
	h.Name = "Golpe"
	h.FillColor, h.FillTransparency = Color3.new(1, 1, 1), 0.35
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = modelo
	TweenService:Create(h, TweenInfo.new(0.12), { FillTransparency = 1 }):Play()
	task.delay(0.13, function()
		h:Destroy()
		destellos -= 1
	end)
end

local function particulas(padre: BasePart, tipo: string): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = "Estado_" .. tipo
	e.LightEmission = 0.6
	e.Rate = 8
	e.Lifetime = NumberRange.new(0.6, 1)
	e.SpreadAngle = Vector2.new(180, 180)
	if tipo == "nieve" then
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
		e.Size = NumberSequence.new(0.35, 0)
		e.Speed = NumberRange.new(0.5, 1)
		e.Acceleration = Vector3.new(0, -3, 0)
	elseif tipo == "fuego" then
		e.Texture = "rbxasset://textures/particles/fire_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 60, 20))
		e.Size = NumberSequence.new(1, 0)
		e.Speed = NumberRange.new(1, 3)
		e.Acceleration = Vector3.new(0, 4, 0)
		e.Rate = 16
		e.LightEmission = 1
	elseif tipo == "burbujas" then
		e.Color = ColorSequence.new(Color3.fromRGB(120, 240, 90))
		e.Size = NumberSequence.new(0.3, 0.1)
		e.Speed = NumberRange.new(0.5, 1.5)
		e.Acceleration = Vector3.new(0, 2, 0)
		e.Transparency = NumberSequence.new(0.2, 1)
	elseif tipo == "estrellas" then
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(255, 230, 100))
		e.Size = NumberSequence.new(0.5, 0)
		e.Speed = NumberRange.new(1.5, 2.5)
		e.SpreadAngle = Vector2.new(10, 180)
		e.EmissionDirection = Enum.NormalId.Top
		e.Rate = 14
		e.LightEmission = 1
	else
		e.Color = ColorSequence.new(Color3.fromRGB(170, 80, 255))
		e.Size = NumberSequence.new(0.6, 0)
		e.Speed = NumberRange.new(0.5, 1.5)
		e.Acceleration = Vector3.new(0, 2, 0)
		e.LightEmission = 1
	end
	e.Parent = padre
	return e
end

-- Íconos de estado sobre la barra de vida.
local function iconos(cuerpo: BasePart): Frame
	local b = cuerpo:FindFirstChild("IconosEstado")
	if b then
		return b:FindFirstChild("Fila")
	end
	b = Instance.new("BillboardGui")
	b.Name = "IconosEstado"
	b.Size = UDim2.fromOffset(120, 20)
	b.StudsOffsetWorldSpace = Vector3.new(0, cuerpo.Size.Y / 2 + 3.2, 0)
	b.MaxDistance = 120
	b.LightInfluence = 0
	local fila = Instance.new("Frame")
	fila.Name = "Fila"
	fila.Size = UDim2.fromScale(1, 1)
	fila.BackgroundTransparency = 1
	fila.Parent = b
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.Padding = UDim.new(0, 3)
	l.Parent = fila
	b.Parent = cuerpo
	return fila
end

local function estados(cuerpo: BasePart)
	local activos = {}
	for _, t in string.split(cuerpo:GetAttribute("Estados") or "", ",") do
		if ESTADOS[t] then
			activos[t] = true
		end
	end
	local fila = iconos(cuerpo)
	for _, c in fila:GetChildren() do
		if c:IsA("TextLabel") and not activos[c.Name] then
			c:Destroy()
		end
	end
	for _, c in cuerpo:GetChildren() do
		local tipo = string.match(c.Name, "^EstadoDe_(.+)$")
		if tipo and not activos[tipo] then
			c:Destroy()
		end
	end
	local baja = Ajustes.valores.calidadBaja
	for tipo in activos do
		local d = ESTADOS[tipo]
		if not fila:FindFirstChild(tipo) then
			local l = Instance.new("TextLabel")
			l.Name = tipo
			l.Size = UDim2.fromOffset(18, 18)
			l.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
			l.BackgroundTransparency = 0.2
			l.Font = Enum.Font.GothamBlack
			l.TextScaled = true
			l.TextColor3 = d.color
			l.Text = d.icono
			Instance.new("UICorner", l).CornerRadius = UDim.new(1, 0)
			l.Parent = fila
		end
		if d.particula and not baja and not cuerpo:FindFirstChild("EstadoDe_" .. tipo) then
			local soporte = Instance.new("Attachment")
			soporte.Name = "EstadoDe_" .. tipo
			soporte.Parent = cuerpo
			particulas(cuerpo, d.particula).Parent = soporte
		end
	end
end

--------------------------------------------------------------------------------
-- Fases de jefe
--------------------------------------------------------------------------------
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

local function rugir(cuerpo: BasePart)
	local modelo = cuerpo:FindFirstChildWhichIsA("Model")
	local hum = modelo and modelo:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator then
		local a = Instance.new("Animation")
		a.AnimationId = RUGIDO
		local ok, pista = pcall(animator.LoadAnimation, animator, a)
		if ok then
			pista.Priority = Enum.AnimationPriority.Action2
			pista:Play(0.1)
		end
	end
	-- Anillo rojo que se cierra hacia el jefe: aviso de que viene algo.
	local anillo = pieza({ Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 60, 60), Transparency = 0.4, Size = Vector3.new(0.2, 30, 30), CFrame = CFrame.new(cuerpo.Position - Vector3.new(0, cuerpo.Size.Y / 2 - 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	TweenService:Create(anillo, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(0.2, 4, 4), Transparency = 0 }):Play()
	task.delay(1.25, anillo.Destroy, anillo)
end

local function activar(cuerpo: BasePart, tipo: string)
	local modelo = cuerpo:FindFirstChildWhichIsA("Model")
	local _, tam = (modelo or cuerpo):GetBoundingBox()
	local radio = math.max(tam.X, tam.Y, tam.Z) * 0.75
	if tipo == "escudo" then
		local burbuja = pieza({ Shape = Enum.PartType.Ball, Material = Enum.Material.ForceField, Color = Color3.fromRGB(110, 190, 255), Size = Vector3.one * radio * 2, CFrame = cuerpo.CFrame })
		local seguir
		seguir = RunService.RenderStepped:Connect(function()
			if not cuerpo.Parent then
				seguir:Disconnect()
				return
			end
			burbuja.CFrame = cuerpo.CFrame
		end)
		task.delay(4, function()
			seguir:Disconnect()
			TweenService:Create(burbuja, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			task.wait(0.4)
			burbuja:Destroy()
		end)
	elseif tipo == "invocar" then
		-- Portales violetas a los costados de donde salen los refuerzos.
		for _, lado in { -1, 1 } do
			local pos = cuerpo.CFrame * CFrame.new(lado * radio * 1.4, 0, 0)
			local portal = pieza({ Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(170, 70, 255), Transparency = 0.2, Size = Vector3.new(0.3, 0.5, 0.5), CFrame = pos * CFrame.Angles(0, math.rad(90), 0) })
			TweenService:Create(portal, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = Vector3.new(0.3, radio * 1.6, radio * 1.6) }):Play()
			task.delay(1.6, function()
				TweenService:Create(portal, TweenInfo.new(0.3), { Size = Vector3.new(0.3, 0.2, 0.2), Transparency = 1 }):Play()
				task.wait(0.3)
				portal:Destroy()
			end)
		end
	elseif tipo == "furia" or tipo == "aturdir" then
		local objetivo = modelo or cuerpo
		local h = Instance.new("Highlight")
		h.FillColor, h.FillTransparency = Color3.fromRGB(255, 40, 40), 0.6
		h.OutlineColor = Color3.fromRGB(255, 80, 60)
		h.Parent = objetivo
		local onda = pieza({ Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 70, 50), Transparency = 0.2, Size = Vector3.new(0.3, 2, 2), CFrame = CFrame.new(cuerpo.Position - Vector3.new(0, cuerpo.Size.Y / 2 - 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
		TweenService:Create(onda, TweenInfo.new(0.6), { Size = Vector3.new(0.3, 40, 40), Transparency = 1 }):Play()
		task.delay(0.6, onda.Destroy, onda)
		task.delay(4, h.Destroy, h)
	elseif tipo == "sigilo" or tipo == "cura" then
		local p = pieza({ Transparency = 1, Size = Vector3.one, CFrame = cuerpo.CFrame })
		local e = Instance.new("ParticleEmitter")
		e.Texture = if tipo == "sigilo" then "rbxasset://textures/particles/smoke_main.dds" else "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(if tipo == "sigilo" then Color3.fromRGB(80, 80, 95) else Color3.fromRGB(120, 255, 140))
		e.Size = NumberSequence.new(if tipo == "sigilo" then radio else 0.8, 0)
		e.Lifetime = NumberRange.new(0.8, 1.4)
		e.Speed = NumberRange.new(2, 6)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Rate = 0
		e.Parent = p
		e:Emit(if tipo == "sigilo" then 30 else 40)
		task.delay(1.5, p.Destroy, p)
	end
end

--------------------------------------------------------------------------------
-- Seguir a los enemigos de las partidas
--------------------------------------------------------------------------------
local function seguir(cuerpo: Instance)
	if not cuerpo:IsA("BasePart") or not cuerpo.Parent or cuerpo.Parent.Name ~= "Enemigos" then
		return
	end
	local vida = cuerpo:GetAttribute("Vida")
	cuerpo:GetAttributeChangedSignal("Vida"):Connect(function()
		local ahora = cuerpo:GetAttribute("Vida")
		if vida and ahora and ahora < vida and ahora > 0 then
			destello(cuerpo)
		end
		vida = ahora
	end)
	cuerpo:GetAttributeChangedSignal("Estados"):Connect(function()
		estados(cuerpo)
	end)
	if cuerpo:GetAttribute("Estados") then
		estados(cuerpo)
	end
	cuerpo:GetAttributeChangedSignal("FaseJefe"):Connect(function()
		local etapa, tipo = string.match(cuerpo:GetAttribute("FaseJefe") or "", "^(%a+):(%a+)")
		if etapa == "prepara" then
			rugir(cuerpo)
		elseif etapa == "activa" and tipo then
			activar(cuerpo, tipo)
		end
	end)
end

local partidas = workspace:WaitForChild("Partidas")
partidas.DescendantAdded:Connect(seguir)
for _, d in partidas:GetDescendants() do
	seguir(d)
end
