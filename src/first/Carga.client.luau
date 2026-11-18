-- Pantalla de carga (docs/PANTALLAS.md, estilo limpio): al entrar al juego y al llegar a un servidor de partida o volver al lobby.
-- Corre desde ReplicatedFirst, antes que el resto: no usa módulos del juego. También se usa como pantalla del
-- teletransporte entre servidores (TeleportService:SetTeleportGui).
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

-- Misma paleta que Comic.luau (estilo limpio, 17/11/2026); acá no se puede usar el módulo porque corre antes.
local ROJO = Color3.fromRGB(226, 38, 52)
local FONDO = Color3.fromRGB(16, 18, 26)
local TENUE = Color3.fromRGB(150, 158, 178)
local CREMA = Color3.fromRGB(236, 240, 248)

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
	local fondo = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = FONDO, BorderSizePixel = 0 }, gui)
	-- Resplandor rojo muy suave desde abajo.
	crear("UIGradient", { Rotation = 90, Color = ColorSequence.new(FONDO, Color3.fromRGB(48, 14, 22)) }, fondo)
	local centro = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(760, 260), BackgroundTransparency = 1 }, fondo)
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
	crear("TextLabel", { Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = CREMA, Text = "ULTIMATE MARVEL TD" }, centro)
	crear("TextLabel", { Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = ROJO, Text = "TOWER DEFENSE" }, centro)
	local marcoBarra = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.fromOffset(420, 4), BackgroundColor3 = Color3.fromRGB(40, 44, 58), BorderSizePixel = 0 }, centro)
	crear("UICorner", { CornerRadius = UDim.new(1, 0) }, marcoBarra)
	local barra = crear("Frame", { Size = UDim2.fromScale(0.05, 1), BackgroundColor3 = ROJO, BorderSizePixel = 0 }, marcoBarra)
	crear("UICorner", { CornerRadius = UDim.new(1, 0) }, barra)
	local consejo = crear("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 176), Size = UDim2.fromOffset(700, 40), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextWrapped = true, TextColor3 = TENUE, Text = "Consejo: " .. CONSEJOS[math.random(#CONSEJOS)] }, centro)
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
-- Se desvanece.
local fondo = gui:FindFirstChildWhichIsA("Frame")
TweenService:Create(fondo, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
for _, d in fondo:GetDescendants() do
	if d:IsA("TextLabel") then
		TweenService:Create(d, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
	elseif d:IsA("Frame") then
		TweenService:Create(d, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	end
end
task.wait(0.55)
gui:Destroy()
