-- Cliente de batalla: interfaz de partida estilo cómic (docs/PARTIDA.md) y controles. Cámara libre:
-- el jugador camina por el mapa y coloca donde apunta el mouse. Sólo envía intenciones; el servidor valida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Comic = require(script.Parent:WaitForChild("Comic"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mapa = require(Shared.Mapa)
local Despliegue = require(Shared.Despliegue)
local Progresion = require(Shared.Progresion)
local Mejoras = require(Shared.Mejoras)
local Kits = require(Shared.Kits)
local Personajes = require(Shared.Personajes)
local heroes = Personajes.todos
local niveles = require(Shared.Data.levels)

local accion = ReplicatedStorage:WaitForChild("Accion")
local jugador = Players.LocalPlayer
local mouse = jugador:GetMouse()
local crear, texto = Comic.crear, Comic.texto

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

local function miles(n: number): string
	local s = tostring(math.floor(n))
	return (string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1."))):gsub("^%.", ""))
end

local function animar(objeto: Instance, segundos: number, meta, estilo: Enum.EasingStyle?)
	local t = TweenService:Create(objeto, TweenInfo.new(segundos, estilo or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), meta)
	t:Play()
	return t
end

--------------------------------------------------------------------------------
-- Interfaz
--------------------------------------------------------------------------------
local gui = crear("ScreenGui", { Name = "HUD", ResetOnSpawn = false, DisplayOrder = 2 })

-- Arriba: viñeta amarilla inclinada con mapa · acto y la vida de la base; a los lados, oleada y reloj.
local arriba = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(500, 84), BackgroundTransparency = 1 }, gui)
local vineta = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Comic.AMARILLO, Rotation = -1.5 }, arriba)
Comic.borde(vineta, 4)
local titulo = texto({ TextColor3 = Comic.ROJO_OSCURO, TextStrokeTransparency = 1, Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -28, 0, 32) }, vineta)
local fondoVida = crear("Frame", { Position = UDim2.fromOffset(14, 40), Size = UDim2.new(1, -28, 0, 32), BackgroundColor3 = Comic.FONDO }, vineta)
Comic.borde(fondoVida, 3)
local barraVida = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Comic.ROJO, BorderSizePixel = 0 }, fondoVida)
crear("UICorner", { CornerRadius = UDim.new(0, 6) }, barraVida)
crear("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)) }, barraVida)
local textoVida = texto({ Size = UDim2.fromScale(1, 1), TextSize = 24 }, fondoVida)

local function circulo(lado: number): (Frame, TextLabel, TextLabel)
	local c = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(lado, lado == 0 and -54 or 54, 0.5, 0), Size = UDim2.fromOffset(92, 92), BackgroundColor3 = Comic.ROJO }, arriba)
	crear("UIStroke", { Thickness = 4 }, c)
	crear("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
	local arribaTxt = texto({ TextSize = 16, Font = Comic.TEXTO, Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 16) }, c)
	local grande = texto({ TextSize = 32, TextColor3 = Comic.AMARILLO, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 36) }, c)
	return c, arribaTxt, grande
end
local _, rotuloOleada, textoOleada = circulo(0)
rotuloOleada.Text = "OLEADA"
local circuloReloj, rotuloReloj, textoReloj = circulo(1)
rotuloReloj.Text = "⏱"

-- Mensaje de la partida (fase, modificador de oleada) en una franja oscura debajo.
local mensaje = texto({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 10), Size = UDim2.fromOffset(560, 26), TextSize = 18, Font = Comic.TEXTO }, arriba)
mensaje.BackgroundTransparency = 0.3
mensaje.BackgroundColor3 = Comic.FONDO
crear("UICorner", { CornerRadius = UDim.new(0, 6) }, mensaje)

-- Avisos (errores, premios): globo de diálogo blanco.
local aviso = texto({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 46), Size = UDim2.fromOffset(560, 40), TextSize = 20, Font = Comic.TEXTO, TextColor3 = Comic.NEGRO, TextStrokeTransparency = 1, TextWrapped = true, Visible = false, ZIndex = 5 }, arriba)
aviso.BackgroundTransparency = 0
aviso.BackgroundColor3 = Comic.CREMA
Comic.borde(aviso, 3)
crear("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, aviso)

-- Abajo: dinero de partida y escuadrón en tarjetas con retrato.
local abajo = crear("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(800, 186), BackgroundTransparency = 1 }, gui)
local dinero = texto({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(220, 46), TextSize = 34, TextColor3 = Comic.AMARILLO, Rotation = -2 }, abajo)
dinero.BackgroundTransparency = 0
dinero.BackgroundColor3 = Comic.ROJO_OSCURO
Comic.borde(dinero, 4)
local tarjetas = crear("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 126), BackgroundTransparency = 1 }, abajo)
crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, tarjetas)

-- Derecha: controles de la partida.
local lateral = crear("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(190, 320), BackgroundTransparency = 1 }, gui)
crear("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, lateral)

-- Izquierda: panel de la unidad elegida.
local panelUnidad = crear("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 10), Size = UDim2.fromOffset(300, 470), BackgroundColor3 = Comic.FONDO, Visible = false }, gui)
Comic.borde(panelUnidad, 5)
local franjaUnidad = crear("Frame", { Position = UDim2.fromOffset(-8, -20), Size = UDim2.new(1, -30, 0, 46), BackgroundColor3 = Comic.AMARILLO, Rotation = -2 }, panelUnidad)
Comic.borde(franjaUnidad, 4)
local nombreUnidad = texto({ TextColor3 = Comic.ROJO_OSCURO, TextStrokeTransparency = 1, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 1, -8), TextXAlignment = Enum.TextXAlignment.Left }, franjaUnidad)
local marcoRetrato = crear("Frame", { Position = UDim2.fromOffset(14, 36), Size = UDim2.fromOffset(110, 110), BackgroundColor3 = Comic.ROJO_OSCURO }, panelUnidad)
Comic.borde(marcoRetrato, 3)
local statsUnidad = texto({ Position = UDim2.fromOffset(134, 36), Size = UDim2.fromOffset(152, 110), TextSize = 16, Font = Comic.TEXTO, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = true }, panelUnidad)
local pips = crear("Frame", { Position = UDim2.fromOffset(14, 156), Size = UDim2.new(1, -28, 0, 16), BackgroundTransparency = 1 }, panelUnidad)
crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, pips)
for i = 1, Mejoras.MAXIMO do
	Comic.borde(crear("Frame", { Name = tostring(i), LayoutOrder = i, Size = UDim2.fromOffset(48, 16), BackgroundColor3 = Comic.GRIS }, pips), 2)
end
local accionesUnidad = crear("Frame", { Position = UDim2.fromOffset(14, 184), Size = UDim2.new(1, -28, 1, -196), BackgroundTransparency = 1 }, panelUnidad)
crear("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, accionesUnidad)

-- Todo se achica en pantallas chicas (diseñado para 1280×760).
local escalaGlobal = 1
local escalas = {}
for _, f in { arriba, abajo, lateral, panelUnidad } do
	table.insert(escalas, crear("UIScale", {}, f))
end
local function reescalar()
	local v = workspace.CurrentCamera.ViewportSize
	escalaGlobal = math.clamp(math.min(v.X / 1280, v.Y / 760), 0.5, 1)
	for _, e in escalas do
		e.Scale = escalaGlobal
	end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(reescalar)
reescalar()

local avisoHasta = 0
local function avisar(t: string?)
	if t then
		aviso.Text = t
		aviso.Visible = true
		avisoHasta = os.clock() + 4
	end
end

--------------------------------------------------------------------------------
-- Modo de interacción: nil | { tipo = "colocar", heroe, ranura } | { tipo = "seleccion", uid } | { tipo = "mover", uid, heroe }
--------------------------------------------------------------------------------
local modo = nil
local tarjetasHeroe = {} -- [ranura] = tarjeta
local ordenRanuras = {} -- ranuras en orden, para las teclas 1–6
local botonMover, botonVender, botonMejorar, botonPrioridad, botonMunicion
local botonListo, botonSaltar, botonAuto, botonVelocidad, botonVolver
local retratoUid = nil

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

local function pintarBoton(b: TextButton, activo: boolean, color: Color3)
	b.AutoButtonColor = activo
	b.BackgroundColor3 = if activo then color else Comic.GRIS
end

local resultado -- pantalla de victoria/derrota (más abajo)

local function refrescar()
	local batalla = enBatalla()
	arriba.Visible, abajo.Visible, lateral.Visible = batalla, batalla, batalla
	if not batalla then
		panelUnidad.Visible = false
		resultado.Visible = false
		return
	end
	local plata = jugador:GetAttribute("Dinero") or 0
	dinero.Text = `💰 {miles(plata)}`

	-- Panel de la unidad elegida.
	local seleccion = modo and modo.uid and unidadDe(modo.uid)
	panelUnidad.Visible = seleccion ~= nil
	if seleccion then
		local id = seleccion:GetAttribute("Heroe")
		local config = heroes[id]
		local hecho = seleccion:GetAttribute("Mejora") or 0
		if retratoUid ~= modo.uid then
			retratoUid = modo.uid
			marcoRetrato:ClearAllChildren()
			Comic.borde(marcoRetrato, 3)
			Comic.retrato(marcoRetrato, Personajes.base(id), config.name, Comic.AMARILLO)
		end
		nombreUnidad.Text = string.upper(config.name)
		marcoRetrato:FindFirstChildOfClass("UIStroke").Color = Comic.RAREZA[config.rarity] or Comic.NEGRO
		statsUnidad.Text = `Nv {seleccion:GetAttribute("NivelUnidad") or 1}\n⚔ Daño <font color="#ffd628">{seleccion:GetAttribute("Dano") or "?"}</font>\n◎ Alcance <font color="#ffd628">{seleccion:GetAttribute("Alcance") or "?"}</font>\n⚡ Ataques/s <font color="#ffd628">{seleccion:GetAttribute("Cadencia") or "?"}</font>`
		for _, pip in pips:GetChildren() do
			if pip:IsA("Frame") then
				pip.BackgroundColor3 = if tonumber(pip.Name) <= hecho then Comic.AMARILLO else Comic.GRIS
			end
		end
		local siguiente = config and Mejoras.lista(config)[hecho + 1]
		botonMejorar.Text = if siguiente then `▲ MEJORA {hecho + 1}: {string.upper(siguiente.nombre)}  💰 {miles(siguiente.costo)}\n<font face="GothamBold" size="13">{Mejoras.descripcion(siguiente)}</font>` else "MEJORAS COMPLETAS"
		pintarBoton(botonMejorar, siguiente ~= nil and plata >= siguiente.costo, Color3.fromRGB(200, 130, 20))
		botonVender.Text = `VENDER  +💰 {miles((seleccion:GetAttribute("Invertido") or 0) * 0.5)}`
		botonPrioridad.Text = `🎯 OBJETIVO: {string.upper(NOMBRE_PRIORIDAD[seleccion:GetAttribute("Prioridad")] or "Primero")}`
		local municion = seleccion:GetAttribute("Municion")
		botonMunicion.Visible = municion ~= nil
		botonMunicion.Text = `MUNICIÓN: {string.upper(Kits.NOMBRE_MODO[municion] or "")}`
		botonMover.BackgroundColor3 = if modo.tipo == "mover" then Color3.fromRGB(60, 120, 200) else Comic.ROJO
	end

	-- Tarjetas del escuadrón.
	for ranura, t in tarjetasHeroe do
		local puestas = 0
		for _, m in unidadesDelMapa() do
			if m:GetAttribute("Dueno") == jugador.UserId and m:GetAttribute("Ranura") == ranura then
				puestas += 1
			end
		end
		local elegida = modo and modo.tipo == "colocar" and modo.ranura == ranura
		local alcanza = plata >= t:GetAttribute("Costo") and puestas < t:GetAttribute("Limite")
		t.UIScale.Scale = if elegida then 1.1 else 1
		t.UIStroke.Color = if elegida then Comic.AMARILLO else t:GetAttribute("ColorRareza")
		t.Costo.BackgroundColor3 = if alcanza then Comic.VERDE else Comic.GRIS
		t.Puestas.Text = `{puestas}/{t:GetAttribute("Limite")}`
	end

	-- Barra superior.
	local fase = estado:GetAttribute("Fase")
	local total = estado:GetAttribute("OleadasTotal")
	local oleada = estado:GetAttribute("Oleada")
	local base, baseMax = estado:GetAttribute("Base"), estado:GetAttribute("BaseMax")
	local acto = estado:GetAttribute("Acto")
	titulo.Text = string.upper(`{estado:GetAttribute("NombreNivel")} · {if acto == "Infinito" or acto == "Evento" then acto else "Acto " .. acto}{if estado:GetAttribute("Pesadilla") then " · Pesadilla" else ""}`)
	barraVida.Size = UDim2.fromScale(math.clamp(base / baseMax, 0, 1), 1)
	textoVida.Text = `🛡 {base} / {baseMax}`
	textoOleada.Text = if total == 0 then tostring(oleada) else `{oleada}/{total}`
	circuloReloj.Visible = fase ~= "fin"
	textoReloj.Text = reloj()
	mensaje.Text = estado:GetAttribute("Mensaje")
	mensaje.Visible = mensaje.Text ~= "" and fase ~= "fin"

	-- Controles.
	botonListo.Visible = fase == "listo" and not jugador:GetAttribute("Listo")
	botonSaltar.Visible = fase == "combate" and (total == 0 or oleada < total)
	local auto = jugador:GetAttribute("Auto")
	botonAuto.Text = `AUTO: {if auto then "SÍ" else "NO"}`
	botonAuto.BackgroundColor3 = if auto then Comic.VERDE else Comic.GRIS
	botonVelocidad.Visible = estado:GetAttribute("Anfitrion") == jugador.UserId
	botonVelocidad.Text = `VELOCIDAD x{estado:GetAttribute("Velocidad")}`
	botonVolver.Visible = fase ~= "fin"
	abajo.Visible, lateral.Visible = fase ~= "fin", fase ~= "fin"
end

local function pedir(nombre: string, a: any?)
	avisar(accion:InvokeServer(nombre, a))
	refrescar()
end

local function elegirTarjeta(ranura: number, id: string)
	modo = if modo and modo.ranura == ranura and modo.tipo == "colocar" then nil else { tipo = "colocar", heroe = id, ranura = ranura }
	refrescar()
end

-- Tarjeta del escuadrón: retrato 3D, nivel, colocadas/límite, costo y tecla.
local function tarjeta(i: number, ranura: number, id: string, nivel: number, limite: number)
	local config = heroes[id]
	local color = Comic.RAREZA[config.rarity] or Comic.CREMA
	local t = crear("TextButton", { Text = "", Size = UDim2.fromOffset(106, 120), BackgroundColor3 = Comic.FONDO, AutoButtonColor = true, LayoutOrder = i }, tarjetas)
	crear("UIStroke", { Color = color, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, t)
	crear("UICorner", { CornerRadius = UDim.new(0, 8) }, t)
	crear("UIScale", {}, t)
	crear("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), color:Lerp(Color3.new(0, 0, 0), 0.4)) }, t)
	local foto = crear("Frame", { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 80), BackgroundTransparency = 1, ClipsDescendants = true }, t)
	Comic.retrato(foto, Personajes.base(id), config.name, color)
	texto({ Text = config.name, Position = UDim2.fromOffset(4, 66), Size = UDim2.new(1, -8, 0, 18), TextSize = 16 }, t)
	texto({ Text = `Nv {nivel}`, Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(50, 16), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left }, t)
	texto({ Name = "Puestas", Position = UDim2.new(1, -46, 0, 4), Size = UDim2.fromOffset(40, 16), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right }, t)
	local costo = Mejoras.costoColocar(config)
	local barra = texto({ Name = "Costo", Text = `💰 {miles(costo)}`, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(1, -8, 0, 26), TextSize = 20, TextColor3 = Comic.CREMA }, t)
	barra.BackgroundTransparency = 0
	Comic.borde(barra, 2)
	local tecla = texto({ Text = tostring(i), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.fromOffset(26, 26), TextSize = 18, TextColor3 = Comic.ROJO_OSCURO, TextStrokeTransparency = 1 }, t)
	tecla.BackgroundTransparency = 0
	tecla.BackgroundColor3 = Comic.AMARILLO
	crear("UIStroke", { Thickness = 2 }, tecla)
	crear("UICorner", { CornerRadius = UDim.new(1, 0) }, tecla)
	t:SetAttribute("Costo", costo)
	t:SetAttribute("Limite", limite)
	t:SetAttribute("ColorRareza", color)
	t:SetAttribute("Heroe", id)
	t.Activated:Connect(function()
		elegirTarjeta(ranura, id)
	end)
	return t
end

-- Tarjetas del escuadrón (atributo Escuadron del jugador: "uid:personaje:nivel:límite").
local function armarEscuadron()
	for _, t in tarjetasHeroe do
		t:Destroy()
	end
	table.clear(tarjetasHeroe)
	table.clear(ordenRanuras)
	for i, entrada in string.split(jugador:GetAttribute("Escuadron") or "", ",") do
		local partes = string.split(entrada, ":")
		local ranura, id = tonumber(partes[1]), partes[2]
		if ranura and id and heroes[id] then
			tarjetasHeroe[ranura] = tarjeta(i, ranura, id, tonumber(partes[3]) or 1, tonumber(partes[4]) or 1)
			table.insert(ordenRanuras, ranura)
		end
	end
end

local function botonUnidad(txt: string, color: Color3, orden: number, alClic): TextButton
	local b = Comic.boton(txt, { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = color, TextSize = 20, LayoutOrder = orden }, accionesUnidad, function()
		if modo and modo.uid then
			alClic()
		end
	end)
	return b
end
botonMejorar = botonUnidad("MEJORAR", Color3.fromRGB(200, 130, 20), 1, function()
	pedir("mejorar", modo.uid)
end)
botonMejorar.Size = UDim2.new(1, 0, 0, 74)
botonMejorar.RichText = true
botonMejorar.TextSize = 19
botonPrioridad = botonUnidad("OBJETIVO", Comic.ROJO, 2, function()
	pedir("prioridad", modo.uid)
end)
botonMunicion = botonUnidad("MUNICIÓN", Comic.ROJO, 3, function()
	pedir("municion", modo.uid)
end)
botonMover = botonUnidad("✥ MOVER", Comic.ROJO, 4, function()
	local m = unidadDe(modo.uid)
	modo = { tipo = "mover", uid = modo.uid, heroe = m and m:GetAttribute("Heroe") }
	refrescar()
end)
botonVender = botonUnidad("VENDER", Comic.GRIS, 5, function()
	pedir("vender", modo.uid)
	modo = nil
	refrescar()
end)
botonVender.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
Comic.boton("X", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 14, 0, -18), Size = UDim2.fromOffset(42, 42), TextSize = 26 }, panelUnidad, function()
	modo = nil
	refrescar()
end)

local function botonLateral(txt: string, color: Color3, orden: number, alClic): TextButton
	return Comic.boton(txt, { Size = UDim2.fromOffset(190, 50), BackgroundColor3 = color, TextSize = 24, LayoutOrder = orden }, lateral, alClic)
end
botonListo = botonLateral("✔ ¡LISTO!", Comic.VERDE, 1, function()
	pedir("listo")
end)
botonListo.Size = UDim2.fromOffset(190, 70)
botonListo.TextSize = 36
botonSaltar = botonLateral("⏩ SALTAR (+10%)", Color3.fromRGB(200, 130, 20), 2, function()
	pedir("saltar")
end)
botonAuto = botonLateral("AUTO", Comic.GRIS, 3, function()
	pedir("auto")
end)
botonVelocidad = botonLateral("VELOCIDAD", Color3.fromRGB(60, 120, 200), 4, function()
	pedir("velocidad")
end)
botonVolver = botonLateral("⌂ ABANDONAR", Comic.ROJO_OSCURO, 5, function()
	modo = nil
	accion:InvokeServer("volver")
end)

--------------------------------------------------------------------------------
-- Efectos de cómic: cartel de oleada, victoria/derrota, números de daño y dinero que salta
--------------------------------------------------------------------------------
local ONOMATOPEYAS = { "¡BAM!", "¡KRAK!", "¡POW!", "¡WHAM!", "¡ZAP!", "¡BOOM!" }

-- Cartel grande al empezar cada oleada (o «¡JEFE!» en la última de un acto).
local function cartelOleada(n: number, jefe: boolean)
	local c = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromOffset(520, 150), BackgroundTransparency = 1, ZIndex = 8 }, gui)
	local escala = crear("UIScale", { Scale = 0.2 }, c)
	local estallido = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(420, 120), BackgroundColor3 = if jefe then Comic.ROJO_OSCURO else Comic.ROJO, Rotation = -4, ZIndex = 8 }, c)
	Comic.borde(estallido, 6)
	texto({ Text = if jefe then "¡JEFE!" else `¡OLEADA {n}!`, Size = UDim2.fromScale(1, 1), TextColor3 = Comic.AMARILLO, ZIndex = 9, Rotation = -4 }, c)
	local ono = texto({ Text = ONOMATOPEYAS[math.random(#ONOMATOPEYAS)], AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -20, 0, 6), Size = UDim2.fromOffset(150, 56), TextColor3 = Comic.ROJO_OSCURO, Rotation = 12, ZIndex = 10 }, c)
	ono.TextStrokeTransparency = 1
	ono.BackgroundTransparency = 0
	ono.BackgroundColor3 = Comic.AMARILLO
	Comic.borde(ono, 4)
	animar(escala, 0.35, { Scale = escalaGlobal }, Enum.EasingStyle.Back)
	task.delay(1.8, function()
		animar(escala, 0.25, { Scale = 0 }, Enum.EasingStyle.Quad)
		task.wait(0.3)
		c:Destroy()
	end)
end

-- Pantalla de victoria/derrota.
resultado = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Comic.NEGRO, BackgroundTransparency = 0.45, Visible = false, ZIndex = 20 }, gui)
local panelFin = crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 340), BackgroundColor3 = Comic.FONDO, ZIndex = 20 }, resultado)
Comic.borde(panelFin, 6)
local escalaFin = crear("UIScale", {}, panelFin)
table.insert(escalas, escalaFin)
local tituloFin = texto({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(460, 110), TextColor3 = Comic.AMARILLO, Rotation = -4, ZIndex = 22 }, panelFin)
tituloFin.BackgroundTransparency = 0
Comic.borde(tituloFin, 6)
local detalleFin = texto({ Position = UDim2.fromOffset(24, 80), Size = UDim2.new(1, -48, 0, 70), TextSize = 22, Font = Comic.TEXTO, TextWrapped = true, ZIndex = 21 }, panelFin)
local premioFin = texto({ Position = UDim2.fromOffset(24, 156), Size = UDim2.new(1, -48, 0, 70), TextSize = 30, TextColor3 = Comic.AMARILLO, TextWrapped = true, ZIndex = 21 }, panelFin)
local botonesFin = crear("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -22), Size = UDim2.new(1, -40, 0, 60), BackgroundTransparency = 1, ZIndex = 21 }, panelFin)
crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, botonesFin)
local votosFin = texto({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -88), Size = UDim2.new(1, -48, 0, 22), TextSize = 17, Font = Comic.TEXTO, ZIndex = 21 }, panelFin)

-- Botones de la pantalla final: las opciones que da el servidor se votan; el lobby es inmediato.
local NOMBRE_OPCION = { siguiente = "SIGUIENTE ACTO ▶", mapa = "SIGUIENTE MAPA ▶", repetir = "REPETIR" }
local function armarBotonesFin()
	for _, b in botonesFin:GetChildren() do
		if b:IsA("GuiObject") then
			b:Destroy()
		end
	end
	local gano = estado:GetAttribute("Resultado") == "victoria"
	local miVoto = jugador:GetAttribute("Voto")
	for i, o in string.split(estado:GetAttribute("Opciones") or "", ",") do
		if NOMBRE_OPCION[o] then
			local votos = estado:GetAttribute("Votos_" .. o)
			local txt = if o == "repetir" and not gano then "REINTENTAR" else NOMBRE_OPCION[o]
			local b = Comic.boton(txt .. (if votos then ` ({votos}/{estado:GetAttribute("VotosTotal")})` else ""), { Size = UDim2.fromOffset(if i == 1 then 210 else 160, 60), TextSize = 22, BackgroundColor3 = if i == 1 then Comic.VERDE else Color3.fromRGB(200, 130, 20), LayoutOrder = i, ZIndex = 22 }, botonesFin, function()
				avisar(accion:InvokeServer("votar", o))
			end)
			if miVoto == o then
				local borde = b:FindFirstChildOfClass("UIStroke")
				borde.Color, borde.Thickness = Comic.AMARILLO, 5
			end
		end
	end
	Comic.boton("⌂ LOBBY", { Size = UDim2.fromOffset(120, 60), TextSize = 24, BackgroundColor3 = Comic.ROJO, LayoutOrder = 10, ZIndex = 22 }, botonesFin, function()
		modo = nil
		accion:InvokeServer("volver")
	end)
	votosFin.Text = if miVoto then "Esperando a los demás…" else ""
end

local function mostrarResultado()
	local gano = estado:GetAttribute("Resultado") == "victoria"
	tituloFin.Text = if gano then "¡VICTORIA!" else "DERROTA"
	tituloFin.BackgroundColor3 = if gano then Comic.ROJO else Comic.GRIS
	detalleFin.Text = estado:GetAttribute("Mensaje")
	premioFin.Text = jugador:GetAttribute("PremioActo") or (if gano then "" else "¡Los héroes volverán más fuertes!")
	armarBotonesFin()
	resultado.Visible = true
	modo = nil
	escalaFin.Scale = 0.3
	animar(escalaFin, 0.4, { Scale = escalaGlobal }, Enum.EasingStyle.Back)
end

-- Números de daño sobre los enemigos (atributo Vida del bloque raíz, lo fija el servidor).
local numerosActivos = 0
local function numeroDano(cuerpo: BasePart, cantidad: number)
	local camara = workspace.CurrentCamera
	if numerosActivos >= 40 or (camara.CFrame.Position - cuerpo.Position).Magnitude > 160 then
		return
	end
	numerosActivos += 1
	local punto = crear("Attachment", { Position = cuerpo.Position + Vector3.new(math.random(-10, 10) / 10, cuerpo.Size.Y / 2 + 1, 0) }, workspace.Terrain)
	local b = crear("BillboardGui", { Size = UDim2.fromOffset(90, 40), AlwaysOnTop = true, Adornee = punto }, punto)
	local grande = cantidad >= 100
	local l = texto({ Text = miles(cantidad), Size = UDim2.fromScale(1, 1), TextSize = if grande then 34 else 26, TextColor3 = if grande then Comic.AMARILLO else Comic.CREMA, Rotation = math.random(-12, 12) }, b)
	animar(punto, 0.7, { Position = punto.Position + Vector3.new(0, 3, 0) })
	animar(l, 0.7, { TextTransparency = 1, TextStrokeTransparency = 1 }, Enum.EasingStyle.Quint)
	task.delay(0.7, function()
		punto:Destroy()
		numerosActivos -= 1
	end)
end

local function seguirEnemigo(cuerpo: Instance)
	if not cuerpo:IsA("BasePart") then
		return
	end
	local antes = cuerpo:GetAttribute("Vida")
	cuerpo:GetAttributeChangedSignal("Vida"):Connect(function()
		local ahora = cuerpo:GetAttribute("Vida")
		if antes and ahora and ahora < antes then
			numeroDano(cuerpo, antes - ahora)
		end
		antes = ahora
	end)
end

-- Dinero que salta: «+💰 n» sobre el contador al ganar.
local dineroAntes = jugador:GetAttribute("Dinero")
local function dineroSalta()
	local ahora = jugador:GetAttribute("Dinero")
	if enBatalla() and dineroAntes and ahora and ahora > dineroAntes then
		local l = texto({ Text = `+💰 {miles(ahora - dineroAntes)}`, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, math.random(-40, 40), 0, -4), Size = UDim2.fromOffset(160, 34), TextSize = 30, TextColor3 = Comic.AMARILLO, Rotation = math.random(-8, 8) }, abajo)
		animar(l, 0.9, { Position = l.Position - UDim2.fromOffset(0, 50), TextTransparency = 1, TextStrokeTransparency = 1 })
		task.delay(0.9, l.Destroy, l)
	end
	dineroAntes = ahora
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
	resultado.Visible = false
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
		table.insert(conexiones, estado.AttributeChanged:Connect(function(nombre)
			if nombre == "Oleada" and (estado:GetAttribute("Oleada") or 0) > 0 then
				local n, total = estado:GetAttribute("Oleada"), estado:GetAttribute("OleadasTotal")
				cartelOleada(n, total > 0 and n == total and estado:GetAttribute("Acto") ~= "Evento")
			elseif nombre == "Fase" and estado:GetAttribute("Fase") == "fin" then
				task.delay(0.5, mostrarResultado) -- da tiempo a que llegue el premio del acto
			elseif nombre == "Fase" then
				resultado.Visible = false -- reinicio en el mismo mapa (repetir o siguiente acto)
			elseif string.sub(nombre, 1, 5) == "Votos" and resultado.Visible then
				armarBotonesFin()
			end
			refrescar()
		end))
		local u = carpeta:WaitForChild("Unidades")
		table.insert(conexiones, u.ChildAdded:Connect(refrescar))
		table.insert(conexiones, u.ChildRemoved:Connect(refrescar))
		local enemigos = carpeta:WaitForChild("Enemigos")
		table.insert(conexiones, enemigos.ChildAdded:Connect(seguirEnemigo))
		for _, e in enemigos:GetChildren() do
			seguirEnemigo(e)
		end
		if estado:GetAttribute("Fase") == "fin" then
			mostrarResultado()
		end
	end
	dineroAntes = jugador:GetAttribute("Dinero")
	armarEscuadron()
	refrescar()
end
jugador:GetAttributeChangedSignal("Partida"):Connect(cambiarPartida)
for _, a in { "Dinero", "Listo", "Auto", "Escuadron", "PremioActo", "Voto" } do
	jugador:GetAttributeChangedSignal(a):Connect(function()
		if a == "Escuadron" then
			armarEscuadron()
		elseif a == "Dinero" then
			dineroSalta()
		elseif a == "PremioActo" and resultado.Visible then
			premioFin.Text = jugador:GetAttribute("PremioActo") or ""
		elseif a == "Voto" and resultado.Visible then
			armarBotonesFin()
		end
		refrescar()
	end)
end
gui.Parent = jugador:WaitForChild("PlayerGui")
cambiarPartida()

--------------------------------------------------------------------------------
-- Vista previa donde apunta el mouse, alcance de la unidad elegida y clics en el mapa
--------------------------------------------------------------------------------
local function disco(): Part
	local d = crear("Part", { Anchored = true, CanCollide = false, CanQuery = false, CastShadow = false, Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 1 }, workspace)
	return d
end
local previa = disco()
previa.Size = Vector3.new(0.3, 4, 4)
local anillo = disco()
anillo.Color = Comic.AMARILLO
mouse.TargetFilter = previa

local function unidadesActuales()
	local l = {}
	for _, m in unidadesDelMapa() do
		local x, y = Mapa.aPixeles(m:GetPivot().Position, origen)
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
	-- Anillo de alcance bajo la unidad elegida.
	local elegida = enBatalla() and modo and modo.uid and unidadDe(modo.uid)
	local alcance = elegida and elegida:GetAttribute("Alcance")
	anillo.Transparency = if alcance then 0.75 else 1
	if alcance then
		local x, y = Mapa.aPixeles(elegida:GetPivot().Position, origen)
		local suelo = origen + Vector3.new(x * Mapa.ESCALA, Mapa.alturaSuelo(NIVEL, x, y) + 0.3, y * Mapa.ESCALA)
		anillo.Size = Vector3.new(0.1, alcance * 2, alcance * 2)
		anillo.CFrame = CFrame.new(suelo) * CFrame.Angles(0, 0, math.rad(90))
	end

	local heroeId = enBatalla() and modo and (modo.tipo == "colocar" or modo.tipo == "mover") and modo.heroe
	previa.Transparency = if heroeId then 0.4 else 1
	if not heroeId then
		return
	end
	local x, y = Mapa.aPixeles(mouse.Hit.Position, origen)
	local moviendo = modo.tipo == "mover" and modo.uid
	local config = Progresion.paraDespliegue(heroes[heroeId], 1)
	local err, cx, cy = Despliegue.error(config, x, y, NIVEL, rutaPx, unidadesActuales(), moviendo or nil, true, true)
	local suelo = origen + Vector3.new(cx * Mapa.ESCALA, Mapa.alturaSuelo(NIVEL, cx, cy) + 0.2, cy * Mapa.ESCALA)
	previa.CFrame = CFrame.new(suelo) * CFrame.Angles(0, 0, math.rad(90))
	previa.Color = if err then Color3.fromRGB(230, 70, 70) else Color3.fromRGB(70, 230, 110)
end)

local TECLAS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six }

UserInputService.InputBegan:Connect(function(input, procesado)
	if input.KeyCode == Enum.KeyCode.Escape then
		modo = nil
		refrescar()
		return
	end
	if procesado or not enBatalla() then
		return
	end
	-- Teclas 1–6: elegir la tarjeta del escuadrón.
	local n = table.find(TECLAS, input.KeyCode)
	if n and ordenRanuras[n] then
		elegirTarjeta(ordenRanuras[n], tarjetasHeroe[ordenRanuras[n]]:GetAttribute("Heroe"))
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
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
			modo = { tipo = "seleccion", uid = modo.uid }
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
