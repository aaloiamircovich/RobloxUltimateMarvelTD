-- Cliente de batalla: controles de la partida en la que está el jugador (atributo Partida). Cámara libre:
-- el jugador camina por el mapa y coloca donde apunta el mouse. Sólo envía intenciones; el servidor valida.
-- shortcut: interfaz funcional sin el estilo cómic; la interfaz final de partida es la etapa siguiente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mapa = require(Shared.Mapa)
local Despliegue = require(Shared.Despliegue)
local Progresion = require(Shared.Progresion)
local Mejoras = require(Shared.Mejoras)
local Kits = require(Shared.Kits)
local heroes = require(Shared.Personajes).todos
local niveles = require(Shared.Data.levels)

local accion = ReplicatedStorage:WaitForChild("Accion")
local jugador = Players.LocalPlayer
local mouse = jugador:GetMouse()

-- Partida actual: su estado (ReplicatedStorage.Partidas/<id>), su carpeta en el mundo y el mapa.
local estado: Folder? = nil
local carpeta: Model? = nil
local NIVEL, rutaPx, origen

local function enBatalla(): boolean
	return estado ~= nil and estado.Parent ~= nil
end

local function unidadesDelMapa(): { Instance }
	local u = carpeta and carpeta:FindFirstChild("Unidades")
	return if u then u:GetChildren() else {}
end

--------------------------------------------------------------------------------
-- Interfaz
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false

local function etiqueta(props)
	local l = Instance.new("TextLabel")
	l.BackgroundColor3 = Color3.fromRGB(28, 8, 12)
	l.BackgroundTransparency = 0.15
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 18
	for k, v in props do
		l[k] = v
	end
	Instance.new("UICorner", l).CornerRadius = UDim.new(0, 8)
	l.Parent = gui
	return l
end

local function boton(texto: string, padre: Instance, alClic: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(150, 44)
	b.BackgroundColor3 = Color3.fromRGB(150, 25, 32)
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

local panel = etiqueta({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(720, 60) })
local barraBase = Instance.new("Frame")
barraBase.Position = UDim2.new(0, 10, 1, -8)
barraBase.Size = UDim2.new(1, -20, 0, 5)
barraBase.BackgroundColor3 = Color3.fromRGB(80, 220, 90)
barraBase.BorderSizePixel = 0
barraBase.Parent = panel
local aviso = etiqueta({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 80),
	Size = UDim2.fromOffset(720, 30),
	TextSize = 15,
	TextColor3 = Color3.fromRGB(255, 220, 120),
	Visible = false,
})

-- Barra inferior: escuadrón y acciones sobre la unidad elegida.
local barra = Instance.new("Frame")
barra.AnchorPoint = Vector2.new(0.5, 1)
barra.Position = UDim2.new(0.5, 0, 1, -12)
barra.Size = UDim2.fromOffset(1700, 44)
barra.BackgroundTransparency = 1
local lista = Instance.new("UIListLayout")
lista.FillDirection = Enum.FillDirection.Horizontal
lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
lista.Padding = UDim.new(0, 8)
lista.SortOrder = Enum.SortOrder.LayoutOrder
lista.Parent = barra
barra.Parent = gui

-- Panel lateral: Listo, Saltar, Automático, Velocidad y Volver.
local lateral = Instance.new("Frame")
lateral.AnchorPoint = Vector2.new(1, 0.5)
lateral.Position = UDim2.new(1, -16, 0.5, 0)
lateral.Size = UDim2.fromOffset(180, 300)
lateral.BackgroundTransparency = 1
local listaLateral = Instance.new("UIListLayout")
listaLateral.Padding = UDim.new(0, 8)
listaLateral.Parent = lateral
lateral.Parent = gui

local avisoHasta = 0
local function avisar(texto: string?)
	if texto then
		aviso.Text = texto
		aviso.Visible = true
		avisoHasta = os.clock() + 4
	end
end

--------------------------------------------------------------------------------
-- Modo de interacción: nil | { tipo = "colocar", heroe, ranura } | { tipo = "seleccion", uid } | { tipo = "mover", uid, heroe }
--------------------------------------------------------------------------------
local modo = nil
local botonesHeroe = {}
local botonMover, botonVender, botonMejorar, botonPrioridad, botonMunicion
local botonListo, botonSaltar, botonAuto, botonVelocidad, botonVolver

local NOMBRE_PRIORIDAD = { primero = "Primero", ultimo = "Último", fuerte = "Más fuerte", debil = "Más débil" }

local function unidadDe(uid: number): Model?
	for _, m in unidadesDelMapa() do
		if m:GetAttribute("Uid") == uid then
			return m
		end
	end
	return nil
end

local function reloj(): string
	local fin = estado and estado:GetAttribute("FinTemporizador") or 0
	local s = math.max(0, math.floor(fin - workspace:GetServerTimeNow()))
	return string.format("%d:%02d", s // 60, s % 60)
end

local function refrescar()
	local batalla = enBatalla()
	panel.Visible, barra.Visible, lateral.Visible = batalla, batalla, batalla
	if not batalla then
		return
	end
	local dinero = jugador:GetAttribute("Dinero") or 0
	local seleccion = modo and modo.uid and unidadDe(modo.uid)
	if seleccion then
		local hecho = seleccion:GetAttribute("Mejora") or 0
		local config = heroes[seleccion:GetAttribute("Heroe")]
		local siguiente = config and Mejoras.lista(config)[hecho + 1]
		botonMejorar.Text = if siguiente then `Mejora {hecho + 1}/{Mejoras.MAXIMO}: {siguiente.nombre} · 💰 {siguiente.costo}\n{Mejoras.descripcion(siguiente)}` else `Mejoras completas ({Mejoras.MAXIMO}/{Mejoras.MAXIMO})`
		botonMejorar.AutoButtonColor = siguiente ~= nil and dinero >= siguiente.costo
		botonMejorar.BackgroundColor3 = if botonMejorar.AutoButtonColor then Color3.fromRGB(190, 130, 20) else Color3.fromRGB(60, 60, 66)
		botonVender.Text = `Vender · +💰 {math.floor((seleccion:GetAttribute("Invertido") or 0) * 0.5)}`
		botonPrioridad.Text = `Objetivo: {NOMBRE_PRIORIDAD[seleccion:GetAttribute("Prioridad")] or "Primero"}`
	end
	local conUnidad = seleccion ~= nil
	botonMejorar.Visible, botonVender.Visible, botonPrioridad.Visible, botonMover.Visible = conUnidad, conUnidad, conUnidad, conUnidad
	local municion = seleccion and seleccion:GetAttribute("Municion")
	botonMunicion.Visible = municion ~= nil
	botonMunicion.Text = `Munición: {Kits.NOMBRE_MODO[municion] or ""}`
	botonMover.BackgroundColor3 = if modo and modo.tipo == "mover" then Color3.fromRGB(60, 120, 200) else Color3.fromRGB(150, 25, 32)
	for ranura, b in botonesHeroe do
		b.BackgroundColor3 = if modo and modo.tipo == "colocar" and modo.ranura == ranura then Color3.fromRGB(60, 120, 200) else Color3.fromRGB(150, 25, 32)
		local puestas = 0
		for _, m in unidadesDelMapa() do
			if m:GetAttribute("Dueno") == jugador.UserId and m:GetAttribute("Ranura") == ranura then
				puestas += 1
			end
		end
		b.Text = `{b:GetAttribute("Nombre")} · 💰 {b:GetAttribute("Costo")}\nNv {b:GetAttribute("NivelUnidad")} · {puestas}/{b:GetAttribute("Limite")}`
	end

	local fase = estado:GetAttribute("Fase")
	local total = estado:GetAttribute("OleadasTotal")
	local oleada = estado:GetAttribute("Oleada")
	botonListo.Visible = fase == "listo" and not jugador:GetAttribute("Listo")
	botonSaltar.Visible = fase == "combate" and (total == 0 or oleada < total)
	botonAuto.Text = `Automático: {if jugador:GetAttribute("Auto") then "SÍ" else "NO"}`
	botonVelocidad.Visible = estado:GetAttribute("Anfitrion") == jugador.UserId
	botonVelocidad.Text = `Velocidad x{estado:GetAttribute("Velocidad")}`
	botonVolver.Text = if fase == "fin" then "⌂ Volver al lobby" else "⌂ Abandonar"
	local base, baseMax = estado:GetAttribute("Base"), estado:GetAttribute("BaseMax")
	barraBase.Size = UDim2.new(math.clamp(base / baseMax, 0, 1), -20, 0, 5)
	local acto = estado:GetAttribute("Acto")
	local titulo = `{estado:GetAttribute("NombreNivel")} · {if acto == "Infinito" then "Infinito" else "Acto " .. acto}{if estado:GetAttribute("Pesadilla") then " · PESADILLA" else ""}`
	local textoOleada = if total == 0 then `Oleada {oleada}` else `Oleada {oleada}/{total}`
	local temporizador = if fase == "fin" then "" else `  ·  ⏱ {reloj()}`
	panel.Text = `{titulo}  ·  🛡 {base}/{baseMax}  ·  {textoOleada}{temporizador}  ·  💰 {dinero}\n{estado:GetAttribute("Mensaje")}`
end

-- Botones del escuadrón (atributo Escuadron del jugador: "uid:personaje:nivel:límite").
local function armarEscuadron()
	for _, b in botonesHeroe do
		b:Destroy()
	end
	table.clear(botonesHeroe)
	for i, texto in string.split(jugador:GetAttribute("Escuadron") or "", ",") do
		local partes = string.split(texto, ":")
		local ranura, id = tonumber(partes[1]), partes[2]
		local config = id and heroes[id]
		if ranura and config then
			local b = boton(config.name, barra, function()
				modo = if modo and modo.ranura == ranura and modo.tipo == "colocar" then nil else { tipo = "colocar", heroe = id, ranura = ranura }
				refrescar()
			end)
			b:SetAttribute("Nombre", config.name)
			b:SetAttribute("NivelUnidad", tonumber(partes[3]) or 1)
			b:SetAttribute("Limite", tonumber(partes[4]) or 1)
			b:SetAttribute("Costo", Mejoras.costoColocar(config))
			b.LayoutOrder = i - 100
			b.Size = UDim2.fromOffset(150, 44)
			botonesHeroe[ranura] = b
		end
	end
end

local function pedir(nombre: string, a: any?)
	avisar(accion:InvokeServer(nombre, a))
	refrescar()
end

botonMover = boton("Mover", barra, function()
	if modo and modo.uid then
		local m = unidadDe(modo.uid)
		modo = { tipo = "mover", uid = modo.uid, heroe = m and m:GetAttribute("Heroe") }
		refrescar()
	end
end)
botonVender = boton("Vender", barra, function()
	if modo and modo.uid then
		pedir("vender", modo.uid)
		modo = nil
		refrescar()
	end
end)
botonMejorar = boton("Mejorar", barra, function()
	if modo and modo.uid then
		pedir("mejorar", modo.uid)
	end
end)
botonMejorar.Size = UDim2.fromOffset(280, 44)
botonMejorar.TextSize = 13
botonPrioridad = boton("Objetivo", barra, function()
	if modo and modo.uid then
		pedir("prioridad", modo.uid)
	end
end)
botonMunicion = boton("Munición", barra, function()
	if modo and modo.uid then
		pedir("municion", modo.uid)
	end
end)

botonListo = boton("✔ LISTO", lateral, function()
	pedir("listo")
end)
botonListo.BackgroundColor3 = Color3.fromRGB(40, 150, 60)
botonSaltar = boton("⏩ Saltar oleada (+10%)", lateral, function()
	pedir("saltar")
end)
botonAuto = boton("Automático", lateral, function()
	pedir("auto")
end)
botonVelocidad = boton("Velocidad", lateral, function()
	pedir("velocidad")
end)
botonVolver = boton("⌂ Volver", lateral, function()
	modo = nil
	accion:InvokeServer("volver")
end)
for _, b in { botonListo, botonSaltar, botonAuto, botonVelocidad, botonVolver } do
	b.Size = UDim2.fromOffset(180, 44)
end

ReplicatedStorage:WaitForChild("Aviso").OnClientEvent:Connect(avisar)

-- Entrar y salir de una partida (el servidor fija el atributo Partida del jugador).
local conexiones = {}
local function cambiarPartida()
	for _, c in conexiones do
		c:Disconnect()
	end
	table.clear(conexiones)
	modo = nil
	estado, carpeta = nil, nil
	local id = jugador:GetAttribute("Partida")
	if id then
		estado = ReplicatedStorage:WaitForChild("Partidas"):WaitForChild(id)
		carpeta = workspace:WaitForChild("Partidas"):WaitForChild("Partida_" .. id)
		origen = estado:GetAttribute("Origen")
		for _, n in niveles do
			if n.id == estado:GetAttribute("Nivel") then
				NIVEL, rutaPx = n, Mapa.rutaPixeles(n)
			end
		end
		table.insert(conexiones, estado.AttributeChanged:Connect(refrescar))
		local u = carpeta:WaitForChild("Unidades")
		table.insert(conexiones, u.ChildAdded:Connect(refrescar))
		table.insert(conexiones, u.ChildRemoved:Connect(refrescar))
	end
	armarEscuadron()
	refrescar()
end
jugador:GetAttributeChangedSignal("Partida"):Connect(cambiarPartida)
for _, a in { "Dinero", "Listo", "Auto", "Escuadron" } do
	jugador:GetAttributeChangedSignal(a):Connect(function()
		if a == "Escuadron" then
			armarEscuadron()
		end
		refrescar()
	end)
end
gui.Parent = jugador:WaitForChild("PlayerGui")
cambiarPartida()

--------------------------------------------------------------------------------
-- Vista previa donde apunta el mouse y clics en el mapa
--------------------------------------------------------------------------------
local previa = Instance.new("Part")
previa.Anchored, previa.CanCollide, previa.CanQuery = true, false, false
previa.Size = Vector3.new(4, 0.3, 4)
previa.Material = Enum.Material.Neon
previa.Transparency = 1
previa.Parent = workspace
mouse.TargetFilter = previa

local function unidadesActuales()
	local l = {}
	for _, m in unidadesDelMapa() do
		local x, y = Mapa.aPixeles(m:GetPivot().Position, origen)
		x, y = Despliegue.celda(x, y, select(2, Mapa.terreno(NIVEL)))
		table.insert(l, { uid = m:GetAttribute("Uid"), heroe = m:GetAttribute("Heroe"), x = x, y = y })
	end
	return l
end

local ultimoReloj = 0
RunService.RenderStepped:Connect(function()
	if aviso.Visible and os.clock() > avisoHasta then
		aviso.Visible = false
	end
	if enBatalla() and os.clock() - ultimoReloj > 0.5 then
		ultimoReloj = os.clock()
		refrescar() -- temporizador
	end
	local heroeId = enBatalla() and modo and (modo.tipo == "colocar" or modo.tipo == "mover") and modo.heroe
	previa.Transparency = if heroeId then 0.4 else 1
	if not heroeId then
		return
	end
	local x, y = Mapa.aPixeles(mouse.Hit.Position, origen)
	local moviendo = modo.tipo == "mover" and modo.uid
	local config = Progresion.paraDespliegue(heroes[heroeId], 1)
	local err, cx, cy = Despliegue.error(config, x, y, NIVEL, rutaPx, unidadesActuales(), moviendo or nil, true)
	previa.Position = Mapa.aMundo(cx, cy, origen) + Vector3.new(0, 0.4, 0)
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
	local x, y = Mapa.aPixeles(mouse.Hit.Position, origen)
	if modo and modo.tipo == "colocar" then
		local err = accion:InvokeServer("colocar", modo.ranura, x, y)
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
		-- Seleccionar una unidad propia.
		local m = mouse.Target
		while m and m:GetAttribute("Uid") == nil do
			m = m.Parent
		end
		modo = if m and m:GetAttribute("Dueno") == jugador.UserId then { tipo = "seleccion", uid = m:GetAttribute("Uid") } else nil
	end
	refrescar()
end)
