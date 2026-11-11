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
local temporadaRemota = ReplicatedStorage:WaitForChild("Temporada")
local items = require(Shared.Data.items)
local jugador = Players.LocalPlayer

local COLOR_RAREZA = Comic.RAREZA

local gui = Comic.crear("ScreenGui", { Name = "Hud", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 1, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })

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

-- Misiones y pase de batalla (docs/TEMPORADA.md): el servidor devuelve el resumen tras cada pedido.
local function duracion(s: number): string
	s = math.max(0, math.floor(s))
	if s >= 86400 then
		return `{s // 86400}d {s % 86400 // 3600}h`
	end
	return `{s // 3600}h {s % 3600 // 60}m`
end

local function barra(padre, pos: UDim2, tam: UDim2, fraccion: number, color: Color3, txt: string)
	local fondo = Comic.crear("Frame", { Position = pos, Size = tam, BackgroundColor3 = Color3.fromRGB(50, 20, 24) }, padre)
	Comic.borde(fondo, 2)
	local relleno = Comic.crear("Frame", { Size = UDim2.fromScale(math.clamp(fraccion, 0, 1), 1), BackgroundColor3 = color, BorderSizePixel = 0 }, fondo)
	Comic.crear("UICorner", { CornerRadius = UDim.new(0, 6) }, relleno)
	Comic.texto({ Text = txt, Size = UDim2.fromScale(1, 1), TextSize = 16 }, fondo)
	return fondo
end

local armarMisiones, armarPase
local function pedirTemporada(nombre: string, a, b)
	local res = temporadaRemota:InvokeServer(nombre, a, b)
	armarMisiones(res)
	armarPase(res)
end

local cuerpoMisiones
do
	local p, cuerpo = Comic.panel(gui, "MISIONES", UDim2.fromOffset(780, 470))
	paneles.misiones = p
	cuerpoMisiones = cuerpo
end
function armarMisiones(res)
	cuerpoMisiones:ClearAllChildren()
	for c, col in { { "diarias", "DIARIAS", res.finDia, res.premioDiaria }, { "semanales", "SEMANALES", res.finSemana, res.premioSemanal } } do
		local x = (c - 1) * 375
		Comic.texto({ Text = `{col[2]}  ·  se renuevan en {duracion(col[3])}`, Position = UDim2.fromOffset(x, 4), Size = UDim2.fromOffset(360, 26), TextSize = 22, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, cuerpoMisiones)
		for i, m in res[col[1]] do
			local f = Comic.crear("Frame", { Position = UDim2.fromOffset(x, 38 + (i - 1) * 118), Size = UDim2.fromOffset(360, 108), BackgroundColor3 = Comic.ROJO_OSCURO }, cuerpoMisiones)
			Comic.borde(f, 3)
			Comic.texto({ Text = m.texto, Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 26), TextSize = 19, Font = Comic.TEXTO, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, f)
			barra(f, UDim2.fromOffset(10, 38), UDim2.new(1, -20, 0, 22), m.progreso / m.meta, Comic.AMARILLO, `{m.progreso} / {m.meta}`)
			Comic.texto({ Text = `💎 {col[4].gemas}   ⭐ {col[4].xp} XP`, Position = UDim2.fromOffset(10, 70), Size = UDim2.fromOffset(170, 30), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left }, f)
			local lista = col[1]
			local puede = m.progreso >= m.meta and not m.reclamada
			Comic.boton(if m.reclamada then "✔ LISTA" elseif puede then "¡RECLAMAR!" else "EN CURSO", {
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -10, 1, -8),
				Size = UDim2.fromOffset(150, 36),
				TextSize = 20,
				AutoButtonColor = puede,
				BackgroundColor3 = if puede then Comic.VERDE else Comic.GRIS,
			}, f, function()
				if puede then
					pedirTemporada("reclamar", lista, i)
				end
			end)
		end
	end
	Comic.texto({ Text = res.error or "", Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 22), TextSize = 16, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO }, cuerpoMisiones)
end

local cuerpoPase
do
	local p, cuerpo = Comic.panel(gui, "PASE DE BATALLA", UDim2.fromOffset(900, 500))
	paneles.pase = p
	cuerpoPase = cuerpo
end
local function textoPremio(pr): string
	if pr.tipo == "gemas" then
		return `💎\n{pr.cantidad}`
	elseif pr.tipo == "nucleos" then
		return `🔷\n{pr.cantidad} núcleo{if pr.cantidad > 1 then "s" else ""}`
	elseif pr.tipo == "objeto" then
		return `🎁\n{items[pr.id] and items[pr.id].name or pr.id}`
	end
	return "★ ???\nPersonaje exclusivo"
end
function armarPase(res)
	local viejo = cuerpoPase:FindFirstChild("Niveles")
	local desplazado = viejo and viejo.CanvasPosition
	cuerpoPase:ClearAllChildren()
	local pase = res.pase
	Comic.texto({ Text = `TEMPORADA {pase.numero}  ·  termina en {duracion(pase.fin)}`, Position = UDim2.fromOffset(0, 4), Size = UDim2.fromOffset(420, 28), TextSize = 24, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, cuerpoPase)
	local maximo = pase.nivel >= pase.niveles
	barra(cuerpoPase, UDim2.fromOffset(430, 6), UDim2.fromOffset(400, 26), if maximo then 1 else (pase.xp % pase.xpNivel) / pase.xpNivel, Color3.fromRGB(80, 160, 255), if maximo then `NIVEL {pase.nivel} · ¡MÁXIMO!` else `NIVEL {pase.nivel}  ·  {pase.xp % pase.xpNivel} / {pase.xpNivel} XP`)
	Comic.texto({ Text = "GRATIS", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(26, 166), Size = UDim2.fromOffset(130, 30), TextSize = 22, Rotation = -90 }, cuerpoPase)
	Comic.texto({ Text = "PREMIUM", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(26, 316), Size = UDim2.fromOffset(130, 30), TextSize = 22, Rotation = -90, TextColor3 = Comic.AMARILLO }, cuerpoPase)
	local lista = Comic.crear("ScrollingFrame", { Name = "Niveles", Position = UDim2.fromOffset(56, 44), Size = UDim2.new(1, -56, 1, -66), BackgroundTransparency = 1, ScrollBarThickness = 8, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new() }, cuerpoPase)
	Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, lista)
	for nivel = 1, pase.niveles do
		local col = Comic.crear("Frame", { Size = UDim2.fromOffset(104, 360), BackgroundTransparency = 1, LayoutOrder = nivel }, lista)
		local alcanzado = pase.nivel >= nivel
		local reclamado = table.find(pase.reclamados, nivel) ~= nil
		local pr = pase.premios[nivel]
		local insignia = Comic.texto({ Text = tostring(nivel), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(44, 44), TextSize = 24, TextColor3 = if alcanzado then Comic.ROJO_OSCURO else Comic.CREMA, TextStrokeTransparency = if alcanzado then 1 else 0 }, col)
		insignia.BackgroundTransparency = 0
		insignia.BackgroundColor3 = if alcanzado then Comic.AMARILLO else Comic.GRIS
		Comic.crear("UIStroke", { Thickness = 3 }, insignia)
		Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, insignia)
		local puede = alcanzado and not reclamado and not (pr.tipo == "unidad" and not pr.id)
		local gratis = Comic.boton(textoPremio(pr) .. (if reclamado then "\n✔" elseif puede then "\n¡TOMAR!" else ""), {
			Position = UDim2.fromOffset(0, 56),
			Size = UDim2.fromOffset(104, 140),
			TextSize = 18,
			AutoButtonColor = puede,
			BackgroundColor3 = if reclamado then Color3.fromRGB(60, 50, 55) elseif puede then Comic.VERDE elseif pr.tipo == "unidad" then Color3.fromRGB(150, 90, 20) else Comic.ROJO,
		}, col, function()
			if puede then
				pedirTemporada("reclamarPase", nivel)
			end
		end)
		if nivel % 10 == 0 then
			gratis:FindFirstChildOfClass("UIStroke").Color = Comic.AMARILLO
		end
		-- Fila premium: visible con candado hasta que se decida monetizar (CLAUDE.md).
		local premium = Comic.texto({ Text = "🔒\nPremium\npróximamente", Position = UDim2.fromOffset(0, 206), Size = UDim2.fromOffset(104, 140), TextSize = 16, Font = Comic.TEXTO, TextColor3 = Color3.fromRGB(200, 190, 170) }, col)
		premium.BackgroundTransparency = 0
		premium.BackgroundColor3 = Color3.fromRGB(40, 30, 34)
		Comic.borde(premium, 3)
	end
	lista.CanvasPosition = desplazado or Vector2.new(math.max(0, (math.min(pase.nivel, pase.niveles) - 3) * 114), 0)
	Comic.texto({ Text = res.error or "", Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 22), TextSize = 16, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO }, cuerpoPase)
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
		pedirTemporada("estado")
		abrir("misiones")
	end },
	{ "INVOCAR", "invocar", function()
		usarHud:FireServer("summon")
	end },
	{ "PASE", "pase", function()
		pedirTemporada("estado")
		abrir("pase")
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
