-- Cliente: HUD, cámara táctica y controles de despliegue. Sólo envía intenciones; el servidor valida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mapa = require(Shared.Mapa)
local Despliegue = require(Shared.Despliegue)
local Progresion = require(Shared.Progresion)
local heroes = require(Shared.Data.heroes)
local NIVEL = require(Shared.Data.levels)[1]
local rutaPx = Mapa.rutaPixeles(NIVEL)

local estado = ReplicatedStorage:WaitForChild("Estado")
local accion = ReplicatedStorage:WaitForChild("Accion")
local jugador = Players.LocalPlayer
local mouse = jugador:GetMouse()

--------------------------------------------------------------------------------
-- Cámara: tercera persona en el HUB, táctica fija sobre el mapa en batalla
--------------------------------------------------------------------------------
local centro = Mapa.aMundo(Mapa.ANCHO / 2, 304)
local camara = workspace.CurrentCamera
local function enBatalla()
	return estado:GetAttribute("Modo") == "batalla"
end
local function fijarCamara()
	if enBatalla() then
		camara.CameraType = Enum.CameraType.Scriptable
		camara.CFrame = CFrame.lookAt(centro + Vector3.new(0, 62, 34), centro + Vector3.new(0, 0, 4))
	else
		camara.CameraType = Enum.CameraType.Custom
		camara.CameraSubject = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
	end
end
fijarCamara()
jugador.CharacterAdded:Connect(function()
	task.defer(fijarCamara)
end)

--------------------------------------------------------------------------------
-- Interfaz
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false

local function etiqueta(props)
	local l = Instance.new("TextLabel")
	l.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	l.BackgroundTransparency = 0.25
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 18
	for k, v in props do
		l[k] = v
	end
	Instance.new("UICorner", l).CornerRadius = UDim.new(0, 10)
	l.Parent = gui
	return l
end

local function boton(texto: string, padre: Instance, alClic: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(150, 44)
	b.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 15
	b.TextWrapped = true
	b.Text = texto
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.Activated:Connect(alClic)
	b.Parent = padre
	return b
end

local panel = etiqueta({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(560, 56) })
local aviso = etiqueta({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 74),
	Size = UDim2.fromOffset(560, 30),
	TextSize = 15,
	TextColor3 = Color3.fromRGB(255, 120, 120),
	Visible = false,
})

-- Saldo del perfil, visible en el HUB.
local saldo = etiqueta({ Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(170, 44), TextSize = 20 })

local barra = Instance.new("Frame")
barra.AnchorPoint = Vector2.new(0.5, 1)
barra.Position = UDim2.new(0.5, 0, 1, -12)
barra.Size = UDim2.fromOffset(1240, 44)
barra.BackgroundTransparency = 1
local lista = Instance.new("UIListLayout")
lista.FillDirection = Enum.FillDirection.Horizontal
lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
lista.Padding = UDim.new(0, 8)
lista.Parent = barra
barra.Parent = gui

local avisoHasta = 0
local function avisar(texto: string?)
	if texto then
		aviso.Text = texto
		aviso.Visible = true
		avisoHasta = os.clock() + 3
	end
end

--------------------------------------------------------------------------------
-- Modo de interacción: nil | { tipo = "colocar", heroe } | { tipo = "seleccion", uid } | { tipo = "mover", uid, heroe }
--------------------------------------------------------------------------------
local modo = nil
local botonesHeroe = {}
local botonMover, botonRetirar, botonMejorar, botonIniciar, botonVolver
local unidadDe

local function refrescar()
	local seleccion = modo and modo.uid and unidadDe(modo.uid)
	if seleccion then
		local nivel = seleccion:GetAttribute("Nivel") or 1
		local costo = Progresion.costo(nivel)
		botonMejorar.Text = if costo then `Mejorar Nv {nivel}→{nivel + 1}\n💰 {costo}` else `Nivel {nivel} (máximo)`
		botonMejorar.AutoButtonColor = costo ~= nil and estado:GetAttribute("Creditos") >= costo
		botonMejorar.BackgroundColor3 = if botonMejorar.AutoButtonColor then Color3.fromRGB(150, 110, 30) else Color3.fromRGB(60, 60, 66)
	end
	botonMejorar.Visible = seleccion ~= nil
	for id, b in botonesHeroe do
		b.BackgroundColor3 = if modo and modo.tipo == "colocar" and modo.heroe == id then Color3.fromRGB(60, 120, 200) else Color3.fromRGB(40, 44, 60)
	end
	local conUnidad = modo ~= nil and (modo.tipo == "seleccion" or modo.tipo == "mover")
	botonMover.Visible, botonRetirar.Visible = conUnidad, conUnidad
	botonMover.BackgroundColor3 = if modo and modo.tipo == "mover" then Color3.fromRGB(60, 120, 200) else Color3.fromRGB(40, 44, 60)
	botonIniciar.Visible = estado:GetAttribute("Fase") == "preparacion"
	panel.Visible, barra.Visible = enBatalla(), enBatalla()
	saldo.Visible = not enBatalla()
	saldo.Text = `💰 {jugador:GetAttribute("Creditos") or "…"}`
	panel.Text = `Oleada {estado:GetAttribute("Oleada")}   ·   ❤ {estado:GetAttribute("Vidas")}   ·   💰 {estado:GetAttribute("Creditos")}\n{estado:GetAttribute("Mensaje")}`
end

for _, id in string.split(estado:GetAttribute("Escuadron") or "", ",") do
	local config = heroes[id]
	if config then
		botonesHeroe[id] = boton(config.name, barra, function()
			modo = if modo and modo.heroe == id and modo.tipo == "colocar" then nil else { tipo = "colocar", heroe = id }
			refrescar()
		end)
	end
end

function unidadDe(uid: number): Model?
	for _, m in workspace:WaitForChild("Unidades"):GetChildren() do
		if m:GetAttribute("Uid") == uid then
			return m
		end
	end
	return nil
end

botonMover = boton("Mover", barra, function()
	if modo and modo.uid then
		local m = unidadDe(modo.uid)
		modo = { tipo = "mover", uid = modo.uid, heroe = m and m:GetAttribute("Heroe") }
		refrescar()
	end
end)
botonRetirar = boton("Retirar (sin reembolso)", barra, function()
	if modo and modo.uid then
		avisar(accion:InvokeServer("retirar", modo.uid))
		modo = nil
		refrescar()
	end
end)
botonMejorar = boton("Mejorar", barra, function()
	if modo and modo.uid then
		avisar(accion:InvokeServer("mejorar", modo.uid))
		refrescar()
	end
end)
botonIniciar = boton("▶ Iniciar oleada", barra, function()
	avisar(accion:InvokeServer("iniciar"))
end)
botonIniciar.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
botonVolver = boton("⌂ Volver al HUB", barra, function()
	avisar(accion:InvokeServer("volver"))
end)

ReplicatedStorage:WaitForChild("Aviso").OnClientEvent:Connect(avisar)
estado:GetAttributeChangedSignal("Modo"):Connect(function()
	modo = nil
	fijarCamara()
end)

estado.AttributeChanged:Connect(refrescar)
jugador:GetAttributeChangedSignal("Creditos"):Connect(refrescar)
refrescar()
gui.Parent = jugador:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- Vista previa de la celda y clics en el mapa
--------------------------------------------------------------------------------
local previa = Instance.new("Part")
previa.Anchored, previa.CanCollide, previa.CanQuery = true, false, false
previa.Size = Vector3.new(4, 0.3, 4)
previa.Material = Enum.Material.Neon
previa.Transparency = 0.4
previa.Parent = workspace
mouse.TargetFilter = previa

local function unidadesActuales()
	local l = {}
	for _, m in workspace:WaitForChild("Unidades"):GetChildren() do
		local x, y = Mapa.aPixeles(m:GetPivot().Position)
		x, y = Despliegue.celda(x, y, NIVEL.rendering.tileSize)
		table.insert(l, { uid = m:GetAttribute("Uid"), heroe = m:GetAttribute("Heroe"), x = x, y = y })
	end
	return l
end

RunService.RenderStepped:Connect(function()
	-- El script de cámara de Roblox puede volver a Custom después del cambio de modo.
	if enBatalla() and camara.CameraType ~= Enum.CameraType.Scriptable then
		fijarCamara()
	end
	if aviso.Visible and os.clock() > avisoHasta then
		aviso.Visible = false
	end
	local heroeId = enBatalla() and modo and (modo.tipo == "colocar" or modo.tipo == "mover") and modo.heroe
	previa.Transparency = if heroeId then 0.4 else 1
	if not heroeId then
		return
	end
	local x, y = Mapa.aPixeles(mouse.Hit.Position)
	local moviendo = modo.tipo == "mover" and unidadDe(modo.uid)
	local config = Progresion.paraDespliegue(heroes[heroeId], if moviendo then moviendo:GetAttribute("Nivel") or 1 else 1)
	local err, cx, cy = Despliegue.error(config, x, y, NIVEL, rutaPx, unidadesActuales(), if moviendo then modo.uid else nil)
	previa.Position = Mapa.aMundo(cx, cy) + Vector3.new(0, 0.4, 0)
	previa.Color = if err then Color3.fromRGB(230, 70, 70) else Color3.fromRGB(70, 230, 110)
end)

UserInputService.InputBegan:Connect(function(input, procesado)
	if input.KeyCode == Enum.KeyCode.Escape then
		modo = nil
		refrescar()
		return
	end
	if procesado or not enBatalla() or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local x, y = Mapa.aPixeles(mouse.Hit.Position)
	if modo and modo.tipo == "colocar" then
		local err = accion:InvokeServer("colocar", modo.heroe, x, y)
		avisar(err)
		if not err then
			modo = nil
		end
	elseif modo and modo.tipo == "mover" then
		local err = accion:InvokeServer("mover", modo.uid, x, y)
		avisar(err)
		if not err then
			modo = nil
		end
	else
		-- Seleccionar una unidad desplegada.
		local m = mouse.Target
		while m and m:GetAttribute("Uid") == nil do
			m = m.Parent
		end
		modo = if m then { tipo = "seleccion", uid = m:GetAttribute("Uid") } else nil
	end
	refrescar()
end)
