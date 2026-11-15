-- Pantalla de carga (docs/PANTALLAS.md): al entrar al juego y al llegar a un servidor de partida o volver al lobby.
-- Corre desde ReplicatedFirst, antes que el resto: no usa módulos del juego. También se usa como pantalla del
-- teletransporte entre servidores (TeleportService:SetTeleportGui).
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local ROJO = Color3.fromRGB(200, 24, 32)
local ROJO_OSCURO = Color3.fromRGB(110, 10, 18)
local AMARILLO = Color3.fromRGB(255, 214, 40)
local CREMA = Color3.fromRGB(255, 244, 222)
local NEGRO = Color3.new(0, 0, 0)

local CONSEJOS = {
	"Cada unidad pide su terreno: pasto, agua o montaña.",
	"Mejorá tus unidades durante la partida para que aguanten las últimas oleadas.",
	"Con prioridad «fuerte» tus unidades apuntan primero al jefe.",
	"Los Míticos y Legendarios tienen ataques únicos: probalos en partida.",
	"Las raids se juegan en grupo y dan fragmentos para personajes exclusivos.",
	"En Wakanda podés tirar rasgos y grados para tus unidades.",
	"El Banner 1 cambia de destacados cada hora.",
}

local function crear(clase: string, props, padre: Instance?)
	local i = Instance.new(clase)
	for k, v in props do
		i[k] = v
	end
	i.Parent = padre
	return i
end

local function armar(): (ScreenGui, Frame, TextLabel)
	local gui = crear("ScreenGui", { Name = "Carga", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 100 })
	local fondo = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = ROJO_OSCURO, BorderSizePixel = 0 }, gui)
	crear("UIGradient", { Rotation = 60, Color = ColorSequence.new(ROJO, Color3.fromRGB(40, 4, 10)) }, fondo)
	-- Franjas diagonales de viñeta.
	for i = -2, 6 do
		crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(i * 0.18, 0.5), Size = UDim2.new(0, 26, 2, 0), Rotation = 25, BackgroundColor3 = NEGRO, BackgroundTransparency = 0.82, BorderSizePixel = 0 }, fondo)
	end
	local centro = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(760, 300), BackgroundTransparency = 1 }, fondo)
	local cam = workspace.CurrentCamera
	local escala = crear("UIScale", {}, centro)
	local function ajustar()
		local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
		escala.Scale = math.clamp(math.min(v.X / 1280, v.Y / 720), 0.45, 1.3)
	end
	ajustar()
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	end
	local cartel = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(700, 150), BackgroundColor3 = AMARILLO, Rotation = -3 }, centro)
	crear("UIStroke", { Color = NEGRO, Thickness = 8 }, cartel)
	crear("TextLabel", { Size = UDim2.new(1, -30, 0, 96), Position = UDim2.fromOffset(15, 4), BackgroundTransparency = 1, Font = Enum.Font.Bangers, TextScaled = true, TextColor3 = ROJO, TextStrokeTransparency = 0, TextStrokeColor3 = NEGRO, Text = "ULTIMATE MARVEL TD" }, cartel)
	crear("TextLabel", { Size = UDim2.new(1, -30, 0, 40), Position = UDim2.fromOffset(15, 100), BackgroundTransparency = 1, Font = Enum.Font.Bangers, TextScaled = true, TextColor3 = ROJO_OSCURO, Text = "TOWER DEFENSE" }, cartel)
	local marcoBarra = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 190), Size = UDim2.fromOffset(560, 30), BackgroundColor3 = NEGRO }, centro)
	crear("UIStroke", { Color = CREMA, Thickness = 3 }, marcoBarra)
	local barra = crear("Frame", { Size = UDim2.fromScale(0.05, 1), BackgroundColor3 = AMARILLO, BorderSizePixel = 0 }, marcoBarra)
	local consejo = crear("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 236), Size = UDim2.fromOffset(740, 50), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 22, TextWrapped = true, TextColor3 = CREMA, TextStrokeTransparency = 0.4, Text = "Consejo: " .. CONSEJOS[math.random(#CONSEJOS)] }, centro)
	return gui, barra, consejo
end

-- Pantalla del viaje entre servidores (la muestra Roblox mientras teletransporta).
local guiViaje = armar()
pcall(TeleportService.SetTeleportGui, TeleportService, guiViaje)

local gui, barra = armar()
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- La barra avanza con lo que falta descargar; nunca retrocede.
local inicio = os.clock()
local progreso = 0.05
local function avanzar(objetivo: number)
	progreso = math.max(progreso, objetivo)
	barra.Size = UDim2.fromScale(progreso, 1)
end
while not game:IsLoaded() or os.clock() - inicio < 2 do
	local pendientes = ContentProvider.RequestQueueSize
	avanzar(math.min(0.9, 0.05 + (os.clock() - inicio) / 6 + (if game:IsLoaded() then 0.4 else 0) - math.min(0.3, pendientes / 500)))
	task.wait(0.1)
end
if not Players.LocalPlayer.Character then
	Players.LocalPlayer.CharacterAdded:Wait()
end
avanzar(1)
task.wait(0.3)
-- Se va con un barrido hacia arriba.
local fondo = gui:FindFirstChildWhichIsA("Frame")
TweenService:Create(fondo, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(0, -1.1) }):Play()
task.wait(0.55)
gui:Destroy()
