-- Notificaciones (docs/INTERFAZ.md): tarjetas que entran por la derecha, se apilan y se van solas a los 4 s.
-- Avisos.mostrar(titulo, texto, color?, icono?). Lo usan el HUD (nivel de cuenta, premios listos, amigos) y la
-- partida.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Comic = require(script.Parent:WaitForChild("Comic"))

local Avisos = {}
local jugador = Players.LocalPlayer
local gui = Comic.crear("ScreenGui", { Name = "Avisos", ResetOnSpawn = false, DisplayOrder = 15, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, jugador:WaitForChild("PlayerGui"))
local pila = Comic.crear("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -150), Size = UDim2.fromOffset(300, 400), BackgroundTransparency = 1 }, gui)
Comic.crear("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pila)
Comic.escalar(pila)

local orden = 0
local MAXIMO = 4

function Avisos.mostrar(titulo: string, texto: string?, color: Color3?, icono: string?)
	color = color or Comic.ROJO
	orden += 1
	-- Si hay demasiados, se va el más viejo.
	local actuales = {}
	for _, c in pila:GetChildren() do
		if c:IsA("Frame") then
			table.insert(actuales, c)
		end
	end
	table.sort(actuales, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	if #actuales >= MAXIMO then
		actuales[1]:Destroy()
	end

	local caja = Comic.crear("Frame", { Size = UDim2.fromOffset(300, 64), BackgroundTransparency = 1, LayoutOrder = orden }, pila)
	local tarjeta = Comic.crear("Frame", { Position = UDim2.fromOffset(320, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Comic.FONDO, BackgroundTransparency = Comic.TRANSPARENCIA }, caja)
	Comic.borde(tarjeta)
	-- Franja del color del aviso a la izquierda.
	local franja = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(0, 4, 1, -16), BackgroundColor3 = color, BorderSizePixel = 0 }, tarjeta)
	Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, franja)
	local x = 16
	if icono then
		Comic.texto({ Text = icono, TextSize = 28, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0, 36, 1, 0) }, tarjeta)
		x = 54
	end
	Comic.texto({ Text = titulo, TextSize = 16, TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35), Position = UDim2.fromOffset(x, 10), Size = UDim2.new(1, -x - 10, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, tarjeta)
	if texto and texto ~= "" then
		Comic.texto({ Text = texto, TextSize = 13, Font = Comic.TEXTO, TextColor3 = Comic.TENUE, Position = UDim2.fromOffset(x, 32), Size = UDim2.new(1, -x - 10, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top }, tarjeta)
	end
	TweenService:Create(tarjeta, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, 0) }):Play()
	task.delay(4, function()
		if not caja.Parent then
			return
		end
		local t = TweenService:Create(tarjeta, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromOffset(320, 0) })
		t:Play()
		t.Completed:Wait()
		caja:Destroy()
	end)
end

-- Amigos que entran al servidor.
Players.PlayerAdded:Connect(function(otro)
	local ok, amigo = pcall(jugador.IsFriendsWith, jugador, otro.UserId)
	if ok and amigo then
		Avisos.mostrar("Amigo conectado", `{otro.DisplayName} entró al servidor`, Comic.VERDE, "👋")
	end
end)

return Avisos
