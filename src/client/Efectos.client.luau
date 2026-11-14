-- Efectos de las unidades en partida (docs/ANIMACION.md), sólo visuales y locales: aparición al colocar,
-- rayo al mejorar, aura con la mejora máxima y humo al vender. «Calidad baja» apaga las partículas (Ajustes.luau).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
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
