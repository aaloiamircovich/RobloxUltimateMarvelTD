-- HUD del lobby estilo cómic: botones a izquierda y derecha, monedas, escuadrón y nivel de cuenta abajo
-- (inspirado en Anime Galaxy y All Star Tower Defense). Sólo muestra y pide; el servidor valida.
-- Se oculta durante la batalla.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comic = require(script.Parent:WaitForChild("Comic"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Iconos = require(Shared.Iconos)
local Personajes = require(Shared.Personajes)
local Cuenta = require(Shared.Cuenta)
local Mejoras = require(Shared.Mejoras)
local coleccion = ReplicatedStorage:WaitForChild("Coleccion")
local usarHud = ReplicatedStorage:WaitForChild("UsarHud")
local teletransportar = ReplicatedStorage:WaitForChild("Teletransportar")
local jugador = Players.LocalPlayer

local COLOR_RAREZA = Comic.RAREZA

local gui = Comic.crear("ScreenGui", { Name = "Hud", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 1 })

--------------------------------------------------------------------------------
-- Paneles propios del HUD
--------------------------------------------------------------------------------
local paneles = {}
local function abrir(nombre)
	for n, p in paneles do
		p.Visible = n == nombre and not p.Visible
	end
end

-- Jugar: submenú de modos.
do
	local p, cuerpo = Comic.panel(gui, "¡A JUGAR!", UDim2.fromOffset(560, 300))
	paneles.jugar = p
	Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, cuerpo)
	for _, m in { { "HISTORIA", "story", Comic.ROJO }, { "INFINITO", "infinite", Color3.fromRGB(90, 60, 190) }, { "RAIDS", nil, Color3.fromRGB(70, 70, 80) } } do
		local b = Comic.boton(m[1], { Size = UDim2.fromOffset(150, 170), BackgroundColor3 = m[3], TextSize = 34 }, cuerpo, function()
			if m[2] then
				p.Visible = false
				usarHud:FireServer(m[2])
			end
		end)
		if not m[2] then
			Comic.texto({ Text = "Próximamente", TextSize = 16, Font = Comic.TEXTO, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, 0, 0, 20) }, b)
		end
	end
end

-- Teletransporte entre islas.
do
	local p, cuerpo = Comic.panel(gui, "VIAJAR", UDim2.fromOffset(520, 360))
	paneles.teleport = p
	Comic.crear("UIGridLayout", { CellSize = UDim2.fromOffset(150, 70), CellPadding = UDim2.fromOffset(12, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center }, cuerpo)
	for _, isla in {
		{ "central", "Torre Vengadores" },
		{ "asgard", "Asgard" },
		{ "wakanda", "Wakanda" },
		{ "nuevaYork", "Nueva York" },
		{ "baxter", "Torre Baxter" },
		{ "sanctum", "Sanctum" },
	} do
		Comic.boton(isla[2], { TextSize = 22 }, cuerpo, function()
			teletransportar:FireServer(isla[1])
			p.Visible = false
		end)
	end
end

-- Perfil.
local textoPerfil
do
	local p, cuerpo = Comic.panel(gui, "PERFIL", UDim2.fromOffset(460, 320))
	paneles.perfil = p
	textoPerfil = Comic.texto({ Font = Comic.TEXTO, TextSize = 20, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }, cuerpo)
end

-- Novedades.
do
	local p, cuerpo = Comic.panel(gui, "NOVEDADES", UDim2.fromOffset(560, 420))
	paneles.log = p
	local lista = Comic.crear("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, cuerpo)
	Comic.texto({
		Font = Comic.TEXTO,
		TextSize = 17,
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Text = table.concat({
			"ACTUALIZACIÓN 1",
			"• HUB de islas flotantes: Torre Vengadores, Asgard, Wakanda, Nueva York, Torre Baxter y Sanctum.",
			"• Banner por hora con 1 estrella y 2 destacados. Invocá con gemas (x1 y x10).",
			"• Unidades repetibles con nivel y experiencia; evolucioná 3 copias en un personaje nuevo.",
			"• Dinero de partida y 5 mejoras por personaje; la habilidad se desbloquea en la mejora 2.",
			"• Nivel de cuenta: abrí más casillas del escuadrón en los niveles 10, 25 y 40.",
			"• 4 mapas de Historia y modo Infinito.",
		}, "\n"),
	}, lista)
end

-- Tienda (microtransacciones): ejemplos sin compra real hasta que se decida publicar.
do
	local p, cuerpo = Comic.panel(gui, "TIENDA", UDim2.fromOffset(640, 360))
	paneles.tienda = p
	Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, cuerpo)
	for _, paquete in { { "500 GEMAS", "10 invocaciones" }, { "1.200 GEMAS", "+20% de regalo" }, { "PASE DE BATALLA", "Recompensas por nivel" } } do
		local f = Comic.crear("Frame", { Size = UDim2.fromOffset(180, 230), BackgroundColor3 = Comic.ROJO_OSCURO }, cuerpo)
		Comic.borde(f, 4)
		Comic.texto({ Text = paquete[1], TextColor3 = Comic.AMARILLO, Position = UDim2.fromOffset(8, 12), Size = UDim2.new(1, -16, 0, 44) }, f)
		Comic.texto({ Text = paquete[2], Font = Comic.TEXTO, TextSize = 16, Position = UDim2.fromOffset(8, 66), Size = UDim2.new(1, -16, 0, 60), TextWrapped = true }, f)
		Comic.boton("PRÓXIMAMENTE", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -24, 0, 44), BackgroundColor3 = Color3.fromRGB(70, 70, 80), TextSize = 20 }, f, function() end)
	end
end

-- Funciones que todavía no existen.
local textoPronto
do
	local p, cuerpo = Comic.panel(gui, "PRÓXIMAMENTE", UDim2.fromOffset(420, 220))
	paneles.pronto = p
	textoPronto = Comic.texto({ Font = Comic.TEXTO, TextSize = 20, Size = UDim2.fromScale(1, 1), TextWrapped = true }, cuerpo)
end
local function pronto(que: string)
	textoPronto.Text = `{que} llega en una próxima actualización.`
	abrir("pronto")
end

--------------------------------------------------------------------------------
-- Botones: columna izquierda (como Anime Galaxy) y derecha
--------------------------------------------------------------------------------
local izquierda = Comic.crear("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 20), Size = UDim2.fromOffset(232, 470), BackgroundTransparency = 1 }, gui)
Comic.botonIcono("TIENDA", Iconos.tienda, { Size = UDim2.fromOffset(232, 120), BackgroundColor3 = Color3.fromRGB(40, 150, 60) }, izquierda, function()
	abrir("tienda")
end)
local grilla = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 132), Size = UDim2.fromOffset(232, 338), BackgroundTransparency = 1 }, izquierda)
Comic.crear("UIGridLayout", { CellSize = UDim2.fromOffset(110, 104), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, grilla)
local BOTONES_IZQ = {
	{ "UNIDADES", "unidades", function()
		usarHud:FireServer("unidades")
	end },
	{ "INVENTARIO", "inventario", function()
		usarHud:FireServer("inventario")
	end },
	{ "MISIONES", "misiones", function()
		pronto("Misiones")
	end },
	{ "INVOCAR", "invocar", function()
		usarHud:FireServer("summon")
	end },
	{ "PASE", "pase", function()
		pronto("El pase de batalla")
	end },
	{ "¡JUGAR!", "jugar", function()
		abrir("jugar")
	end },
}
for i, b in BOTONES_IZQ do
	local boton = Comic.botonIcono(b[1], Iconos[b[2]], { LayoutOrder = i, BackgroundColor3 = if b[2] == "jugar" then Color3.fromRGB(230, 150, 20) else Comic.ROJO }, grilla, b[3])
	boton.Name = b[2]
end

local derecha = Comic.crear("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(104, 452), BackgroundTransparency = 1 }, gui)
Comic.crear("UIListLayout", { Padding = UDim.new(0, 12) }, derecha)
for _, b in {
	{ "VIAJAR", "teleport", function()
		abrir("teleport")
	end },
	{ "PERFIL", "perfil", function()
		abrir("perfil")
	end },
	{ "EVENTO", "evento", function()
		pronto("El evento")
	end },
	{ "NOVEDADES", "log", function()
		abrir("log")
	end },
} do
	Comic.botonIcono(b[1], Iconos[b[2]], { Size = UDim2.fromOffset(104, 104) }, derecha, b[3])
end

--------------------------------------------------------------------------------
-- Abajo: monedas, escuadrón y nivel de cuenta
--------------------------------------------------------------------------------
local abajo = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.fromOffset(780, 230), BackgroundTransparency = 1 }, gui)

local monedas = Comic.crear("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, abajo)
Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 18), HorizontalAlignment = Enum.HorizontalAlignment.Center }, monedas)
local etiquetas = {}
for _, m in { { "Gemas", "💎", Color3.fromRGB(120, 60, 200) }, { "Creditos", "💰", Color3.fromRGB(190, 130, 20) }, { "Nucleos", "🔷", Color3.fromRGB(30, 110, 200) } } do
	local f = Comic.crear("Frame", { Size = UDim2.fromOffset(170, 44), BackgroundColor3 = m[3], Rotation = -2 }, monedas)
	Comic.borde(f, 3)
	etiquetas[m[1]] = Comic.texto({ Text = m[2] .. " …", Size = UDim2.new(1, -16, 1, -6), Position = UDim2.fromOffset(8, 3) }, f)
	etiquetas[m[1]]:SetAttribute("Simbolo", m[2])
end

local casillas = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1 }, abajo)
Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center }, casillas)

local barraNivel = Comic.crear("Frame", { Position = UDim2.fromOffset(60, 190), Size = UDim2.new(1, -120, 0, 30), BackgroundColor3 = Comic.FONDO }, abajo)
Comic.borde(barraNivel, 3)
local relleno = Comic.crear("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Comic.AMARILLO }, barraNivel)
Comic.crear("UICorner", { CornerRadius = UDim.new(0, 6) }, relleno)
local textoNivel = Comic.texto({ Text = "Nivel …", Size = UDim2.new(1, -16, 1, -4), Position = UDim2.fromOffset(8, 2) }, barraNivel)

-- Escuadrón: 6 casillas; las cerradas muestran el nivel de cuenta que las abre.
local ultimoEstado = nil
local function dibujarEscuadron()
	for _, c in casillas:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local e = ultimoEstado
	local abiertas = if e then e.casillas else 3
	for i = 1, 6 do
		local uid = e and e.escuadron[i]
		local u
		for _, x in (e and e.unidades) or {} do
			if x.uid == uid then
				u = x
			end
		end
		local h = u and Personajes.de(u.heroId)
		local cerrada = i > abiertas
		local c = Comic.crear("TextButton", { Text = "", Size = UDim2.fromOffset(118, 118), BackgroundColor3 = if h then Comic.ROJO_OSCURO elseif cerrada then Color3.fromRGB(45, 45, 52) else Color3.fromRGB(70, 22, 28) }, casillas)
		Comic.borde(c, 3)
		if h then
			c:FindFirstChildOfClass("UIStroke").Color = COLOR_RAREZA[h.rarity] or Comic.NEGRO
			Comic.texto({ Text = h.name, Position = UDim2.fromOffset(6, 8), Size = UDim2.new(1, -12, 0, 40), TextWrapped = true }, c)
			Comic.texto({ Text = `Nv {u.level}`, TextColor3 = Comic.AMARILLO, Position = UDim2.fromOffset(6, 52), Size = UDim2.new(1, -12, 0, 24) }, c)
			Comic.texto({ Text = `💰 {Mejoras.costoColocar(h)}`, Font = Comic.TEXTO, TextSize = 15, Position = UDim2.fromOffset(6, 84), Size = UDim2.new(1, -12, 0, 22) }, c)
		elseif cerrada then
			Comic.texto({ Text = `🔒 Nv {Cuenta.nivelCasilla(i) or "?"}`, Size = UDim2.new(1, -12, 0, 40), Position = UDim2.new(0, 6, 0.5, -20) }, c)
		else
			Comic.texto({ Text = "+ Vacía", Size = UDim2.new(1, -12, 0, 40), Position = UDim2.new(0, 6, 0.5, -20) }, c)
		end
		c.Activated:Connect(function()
			if not cerrada then
				usarHud:FireServer("unidades")
			end
		end)
	end
end

local function refrescar()
	for nombre, l in etiquetas do
		local v = jugador:GetAttribute(nombre)
		l.Text = `{l:GetAttribute("Simbolo")} {if v then v else "…"}`
	end
	local nivel, xp = jugador:GetAttribute("Nivel") or 1, jugador:GetAttribute("XP") or 0
	local meta = Cuenta.xpParaSubir(nivel)
	textoNivel.Text = `NIVEL {nivel}   ·   {xp}/{meta} XP`
	relleno.Size = UDim2.fromScale(math.clamp(xp / meta, 0, 1), 1)
	if ultimoEstado and textoPerfil then
		local e = ultimoEstado
		textoPerfil.Text = table.concat({
			jugador.DisplayName,
			`Nivel de cuenta {nivel} ({xp}/{meta} XP)`,
			`Casillas del escuadrón: {e.casillas}/6`,
			`Unidades: {#e.unidades}/100`,
			`💎 {e.gemas}   💰 {e.creditos}   🔷 {e.nucleos}`,
		}, "\n")
	end
end

-- Pide el estado del perfil (unidades y escuadrón) al servidor.
local function pedirEstado()
	local ok, res = pcall(function()
		return coleccion:InvokeServer("estado")
	end)
	if ok and res and res.estado then
		ultimoEstado = res.estado
		dibujarEscuadron()
		refrescar()
		return true
	end
	return false
end

-- Oculto durante una partida (el servidor fija el atributo Partida del jugador).
local function visible()
	gui.Enabled = jugador:GetAttribute("Partida") == nil
end
jugador:GetAttributeChangedSignal("Partida"):Connect(function()
	visible()
	if not jugador:GetAttribute("Partida") then
		pedirEstado()
	end
end)
for _, a in { "Gemas", "Creditos", "Nucleos", "Nivel", "XP" } do
	jugador:GetAttributeChangedSignal(a):Connect(refrescar)
end
-- Al cerrar el panel de colección (escuadrón, invocaciones), refrescar las casillas.
task.spawn(function()
	local coleccionGui = jugador:WaitForChild("PlayerGui"):WaitForChild("Coleccion")
	coleccionGui:GetPropertyChangedSignal("Enabled"):Connect(function()
		abajo.Visible = not coleccionGui.Enabled -- el panel ocupa el centro: no mostrar el escuadrón detrás
		if not coleccionGui.Enabled then
			pedirEstado()
		end
	end)
end)

visible()
dibujarEscuadron()
refrescar()
gui.Parent = jugador:WaitForChild("PlayerGui")
task.spawn(function()
	-- El perfil puede tardar en cargar al entrar.
	for _ = 1, 20 do
		if pedirEstado() then
			break
		end
		task.wait(1)
	end
end)
