-- Montar (tecla G) y rueda de bailes (tecla B), con botones para celular (docs/ESTILO.md).
-- El baile se reproduce sobre el propio personaje: Roblox replica la animación a los demás jugadores.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Comic = require(script.Parent:WaitForChild("Comic"))
local Estilo = require(ReplicatedStorage:WaitForChild("Shared").Estilo)
local estiloRemoto = ReplicatedStorage:WaitForChild("Estilo")
local jugador = Players.LocalPlayer

local gui = Comic.crear("ScreenGui", { Name = "Estilo", ResetOnSpawn = false, DisplayOrder = 3, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })

-- Baile actual.
local pista: AnimationTrack? = nil
local cache = {}
local function parar()
	if pista then
		pista:Stop(0.2)
		pista = nil
	end
end
local function bailar(id: string)
	local b = Estilo.baile(id)
	local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
	local animator = humanoide and humanoide:FindFirstChildOfClass("Animator")
	if not (b and animator) then
		return
	end
	parar()
	cache[animator] = cache[animator] or {}
	if not cache[animator][id] then
		local a = Instance.new("Animation")
		a.AnimationId = b.animacion
		cache[animator][id] = animator:LoadAnimation(a)
		cache[animator][id].Priority = Enum.AnimationPriority.Action
		cache[animator][id].Looped = true
	end
	pista = cache[animator][id]
	pista:Play(0.2)
end
-- Moverse corta el baile.
RunService.Heartbeat:Connect(function()
	local humanoide = pista and jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
	if humanoide and humanoide.MoveDirection.Magnitude > 0.1 then
		parar()
	end
end)

-- Rueda: hasta 4 bailes alrededor del centro de la pantalla.
local rueda = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 340), BackgroundTransparency = 1, Visible = false }, gui)
local function armarRueda()
	rueda:ClearAllChildren()
	local ids = string.split(jugador:GetAttribute("Rueda") or "", ",")
	local LUGARES = { UDim2.fromScale(0.5, 0.12), UDim2.fromScale(0.88, 0.5), UDim2.fromScale(0.5, 0.88), UDim2.fromScale(0.12, 0.5) }
	local centro = Comic.texto({ Text = "BAILES", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(110, 110), TextSize = 30, TextColor3 = Comic.ROJO_OSCURO, TextStrokeTransparency = 1 }, rueda)
	centro.BackgroundTransparency = 0
	centro.BackgroundColor3 = Comic.AMARILLO
	Comic.crear("UIStroke", { Thickness = 4 }, centro)
	Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, centro)
	for i = 1, Estilo.RUEDA do
		local b = Estilo.baile(ids[i])
		Comic.boton(if b then string.upper(b.nombre) else "—", { AnchorPoint = Vector2.new(0.5, 0.5), Position = LUGARES[i], Size = UDim2.fromOffset(130, 64), TextSize = 22, BackgroundColor3 = if b then Comic.ROJO else Comic.GRIS }, rueda, function()
			rueda.Visible = false
			if b then
				bailar(b.id)
			end
		end)
	end
end
local function alternarRueda()
	rueda.Visible = not rueda.Visible
	if rueda.Visible then
		armarRueda()
	end
end

local function montar()
	local res = estiloRemoto:InvokeServer("montar")
	if res and res.error then
		warn(res.error)
	end
end

-- Botones para celular / mouse (arriba a la izquierda, libre en el lobby y en la partida).
local botones = Comic.crear("Frame", { Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(140, 64), BackgroundTransparency = 1 }, gui)
Comic.escalar(botones)
Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, botones)
local botonMontar = Comic.boton("🛹 G", { Size = UDim2.fromOffset(64, 56), TextSize = 22 }, botones, montar)
Comic.boton("💃 B", { Size = UDim2.fromOffset(64, 56), TextSize = 22, BackgroundColor3 = Color3.fromRGB(150, 30, 90) }, botones, alternarRueda)
jugador:GetAttributeChangedSignal("Montado"):Connect(function()
	botonMontar.BackgroundColor3 = if jugador:GetAttribute("Montado") then Comic.VERDE else Comic.ROJO
end)

UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado then
		return
	end
	if input.KeyCode == Enum.KeyCode.G then
		montar()
	elseif input.KeyCode == Enum.KeyCode.B then
		alternarRueda()
	end
end)

gui.Parent = jugador:WaitForChild("PlayerGui")
