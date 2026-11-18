-- Transición (docs/PANTALLAS.md): cuando el personaje aparece lejos de golpe (entrar o salir de una partida,
-- Viajar, puertas de los interiores, portal del Sanctum), la pantalla se cubre de oscuro con una línea roja que la
-- cruza y se aclara enseguida. Estilo limpio (17/11/2026). Un solo mecanismo para todos los teletransportes.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Comic = require(script.Parent:WaitForChild("Comic"))

local jugador = Players.LocalPlayer
local SALTO = 60 -- studs en un cuadro: más que esto es un teletransporte

local pantalla = Comic.crear("ScreenGui", { Name = "Transicion", ResetOnSpawn = false, DisplayOrder = 30, IgnoreGuiInset = true, Enabled = false }, jugador:WaitForChild("PlayerGui"))
local velo = Comic.crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Comic.FONDO, BorderSizePixel = 0 }, pantalla)
local linea = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 0, 0, 3), BackgroundColor3 = Comic.ROJO, BorderSizePixel = 0 }, velo)
Comic.crear("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, linea)

local enCurso = 0
local function barrer()
	enCurso += 1
	local mio = enCurso
	pantalla.Enabled = true
	velo.BackgroundTransparency = 0
	linea.Size = UDim2.new(0, 0, 0, 3)
	linea.BackgroundTransparency = 0
	TweenService:Create(linea, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = UDim2.new(0.7, 0, 0, 3) }):Play()
	task.wait(0.25)
	if mio ~= enCurso then
		return
	end
	TweenService:Create(linea, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	local tw = TweenService:Create(velo, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
	tw:Play()
	tw.Completed:Wait()
	if mio == enCurso then
		pantalla.Enabled = false
	end
end

local anterior = nil
RunService.Heartbeat:Connect(function()
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if not raiz then
		anterior = nil
		return
	end
	local pos = raiz.Position
	if anterior and (pos - anterior).Magnitude > SALTO then
		task.spawn(barrer)
	end
	anterior = pos
end)
