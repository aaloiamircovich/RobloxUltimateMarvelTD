-- Transición de viñeta (docs/PANTALLAS.md): cuando el personaje aparece lejos de golpe (entrar o salir de una
-- partida, Viajar, puertas de los interiores, portal del Sanctum), una viñeta de cómic tapa la pantalla y se va
-- barriendo hacia un costado. Un solo mecanismo para todos los teletransportes, sin tocar el servidor.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Comic = require(script.Parent:WaitForChild("Comic"))

local jugador = Players.LocalPlayer
local SALTO = 60 -- studs en un cuadro: más que esto es un teletransporte

local pantalla = Comic.crear("ScreenGui", { Name = "Transicion", ResetOnSpawn = false, DisplayOrder = 30, IgnoreGuiInset = true, Enabled = false }, jugador:WaitForChild("PlayerGui"))
local vineta = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromScale(1.7, 1.7), BackgroundColor3 = Comic.ROJO, Rotation = -8, BorderSizePixel = 0 }, pantalla)
Comic.crear("UIStroke", { Color = Comic.NEGRO, Thickness = 14 }, vineta)
Comic.crear("UIGradient", { Rotation = 90, Color = ColorSequence.new(Comic.ROJO, Comic.ROJO_OSCURO) }, vineta)
-- Franja amarilla cruzada, como el borde de una viñeta.
local franja = Comic.crear("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0.08, 0, 1, 0), BackgroundColor3 = Comic.AMARILLO, BorderSizePixel = 0 }, vineta)
Comic.crear("UIStroke", { Color = Comic.NEGRO, Thickness = 8 }, franja)

local enCurso = 0
local function barrer()
	enCurso += 1
	local mio = enCurso
	pantalla.Enabled = true
	vineta.Position = UDim2.fromScale(0.5, 0.5)
	task.wait(0.12)
	if mio ~= enCurso then
		return
	end
	local tw = TweenService:Create(vineta, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(2.4, 0.5) })
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
