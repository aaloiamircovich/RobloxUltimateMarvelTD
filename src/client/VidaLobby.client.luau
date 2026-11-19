-- Vida del lobby (docs/LOBBY.md, fase D), sólo local y sincronizado con la hora del servidor (AgendaLobby):
--  · Día y noche: un día cada 20 min. De noche baja la luz, aparecen las estrellas y se prenden faroles y braseros.
--  · Eventos: rayo arcoíris del Bifrost sobre Asgard y portal de Strange en la isla del Sanctum (el aterrizaje del
--    Quinjet lo hace CieloHub.client.luau).
-- En partida no toca nada (el ambiente del mapa es de Ambiente.client.luau).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AgendaLobby = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AgendaLobby"))

local jugador = Players.LocalPlayer
local hub = workspace:WaitForChild("Hub", 60)
if not hub then
	return
end

--------------------------------------------------------------------------------
-- Día y noche
--------------------------------------------------------------------------------
-- Luces del lobby (faroles, braseros…): de día tenues, de noche fuertes. Se anotan con su brillo original.
local luces = {}
local function anotarLuz(d: Instance)
	if d:IsA("PointLight") or d:IsA("SpotLight") then
		luces[d] = d.Brightness
	end
end
for _, d in hub:GetDescendants() do
	anotarLuz(d)
end
hub.DescendantAdded:Connect(anotarLuz)

local cieloNoche = Instance.new("Sky")
cieloNoche.Name = "CieloNoche"
cieloNoche.StarCount = 4000
cieloNoche.MoonAngularSize = 16
cieloNoche.CelestialBodiesShown = true
local cieloDia = nil
local base = nil -- valores del lobby de día (Lighting), para volver
local deNoche = false

local function mezclar(a, b, k)
	return a:Lerp(b, k)
end

local acumulado = 0
RunService.Heartbeat:Connect(function(dt)
	acumulado += dt
	if acumulado < 0.5 or jugador:GetAttribute("Partida") then
		return
	end
	acumulado = 0
	base = base or { brillo = Lighting.Brightness, ambiente = Lighting.Ambient, exterior = Lighting.OutdoorAmbient }
	local hora = AgendaLobby.hora(workspace:GetServerTimeNow())
	Lighting.ClockTime = hora
	-- 0 de día, 1 de noche, con atardecer y amanecer de una hora.
	local k = if hora >= 19 or hora < 5 then 1 elseif hora >= 18 then hora - 18 elseif hora < 6 then 6 - hora else 0
	Lighting.Brightness = base.brillo * (1 - 0.45 * k)
	Lighting.OutdoorAmbient = mezclar(base.exterior, Color3.fromRGB(100, 110, 150), k)
	Lighting.Ambient = mezclar(base.ambiente, Color3.fromRGB(85, 92, 130), k)
	for luz, original in luces do
		if luz.Parent then
			luz.Brightness = original * (0.6 + 1.4 * k)
		else
			luces[luz] = nil
		end
	end
	-- Cielo de estrellas de noche (el del lobby es una imagen de día).
	local noche = k > 0.5
	if noche ~= deNoche then
		deNoche = noche
		cieloDia = cieloDia or Lighting:FindFirstChild("CieloHub")
		if noche then
			if cieloDia then
				cieloDia.Parent = nil
			end
			cieloNoche.Parent = Lighting
		else
			cieloNoche.Parent = nil
			if cieloDia then
				cieloDia.Parent = Lighting
			end
		end
	end
end)

-- Al entrar a una partida, el cielo del lobby vuelve a su lugar (Ambiente.client lo guarda y lo restaura).
jugador:GetAttributeChangedSignal("Partida"):Connect(function()
	if jugador:GetAttribute("Partida") then
		cieloNoche.Parent = nil
		if cieloDia then
			cieloDia.Parent = Lighting
		end
		deNoche = false
		if base then
			Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = base.brillo, base.ambiente, base.exterior
		end
	end
end)

--------------------------------------------------------------------------------
-- Eventos: Bifrost y portal de Strange
--------------------------------------------------------------------------------
local carpeta = Instance.new("Folder")
carpeta.Name = "EventosLobby"
carpeta.Parent = workspace

local ARCOIRIS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 70)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 230, 120)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 110, 255)),
})

local function pieza(props): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	for k, v in props do
		p[k] = v
	end
	p.Parent = carpeta
	return p
end

local activo = nil
local partes = {}
local function terminar()
	for _, p in partes do
		p:Destroy()
	end
	table.clear(partes)
	activo = nil
end

local function iniciar(nombre: string)
	terminar()
	activo = nombre
	if nombre == "bifrost" then
		local centro = hub:GetAttribute("Isla_asgard")
		if not centro then
			return
		end
		-- Columna de luz arcoíris del cielo al centro de Asgard, con un anillo que se abre en el piso.
		local alto = 300
		local rayo = pieza({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(alto, 6, 6), CFrame = CFrame.new(centro + Vector3.new(0, alto / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 230, 255), Transparency = 0.2 })
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(alto / 2, 0, 0), Vector3.new(-alto / 2, 0, 0)
		a0.Parent, a1.Parent = rayo, rayo
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Color = ARCOIRIS
		beam.LightEmission = 1
		beam.Width0, beam.Width1 = 14, 14
		beam.FaceCamera = true
		beam.Parent = rayo
		local luz = Instance.new("PointLight")
		luz.Range, luz.Brightness, luz.Color = 60, 5, Color3.fromRGB(200, 220, 255)
		luz.Parent = rayo
		local anillo = pieza({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 10, 10), CFrame = CFrame.new(centro + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 220, 120), Transparency = 0.3 })
		table.insert(partes, rayo)
		table.insert(partes, anillo)
	elseif nombre == "portal" then
		local centro = hub:GetAttribute("Isla_sanctum")
		if not centro then
			return
		end
		-- Portal de Strange: aro de chispas naranjas parado sobre la isla, que gira.
		local pos = centro + Vector3.new(0, 14, 0)
		local aro = pieza({ Transparency = 1, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos) })
		for i = 1, 28 do
			local a = i / 28 * math.pi * 2
			local chispa = pieza({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.1, Color = Color3.fromRGB(255, 160, 50), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 10, math.sin(a) * 10, 0)) })
			chispa:SetAttribute("Angulo", a)
			table.insert(partes, chispa)
		end
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/fire_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 90, 20))
		e.LightEmission = 1
		e.Size = NumberSequence.new(1.6, 0)
		e.Lifetime = NumberRange.new(0.6, 1)
		e.Speed = NumberRange.new(2, 5)
		e.Rate = 80
		e.SpreadAngle = Vector2.new(180, 180)
		e.Parent = aro
		local luz = Instance.new("PointLight")
		luz.Range, luz.Brightness, luz.Color = 50, 4, Color3.fromRGB(255, 150, 60)
		luz.Parent = aro
		table.insert(partes, aro)
	end
end

RunService.RenderStepped:Connect(function()
	local t = workspace:GetServerTimeNow()
	local nombre, p = AgendaLobby.evento(t)
	if jugador:GetAttribute("Partida") or nombre == "quinjet" then
		nombre = nil
	end
	if nombre ~= activo then
		if nombre then
			iniciar(nombre)
		else
			terminar()
		end
	end
	if not activo then
		return
	end
	-- Aparece y se desvanece (10 % al principio y al final).
	local visible = math.clamp(math.min(p, 1 - p) / 0.1, 0, 1)
	if activo == "portal" then
		local centro = hub:GetAttribute("Isla_sanctum")
		for _, parte in partes do
			local a = parte:GetAttribute("Angulo")
			if a and centro then
				a += t * 1.5
				local r = 10 * visible
				parte.CFrame = CFrame.new(centro + Vector3.new(0, 14, 0) + Vector3.new(math.cos(a) * r, math.sin(a) * r, 0))
			end
		end
	else
		for _, parte in partes do
			parte.Transparency = 1 - visible * 0.8
		end
	end
end)
