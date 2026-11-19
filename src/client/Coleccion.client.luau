-- Paneles de las estaciones del HUB: Invocaciones (elección inicial, banner, unidades, tienda y objetos),
-- Historia e Infinito.
-- Sólo muestra y envía pedidos; el servidor valida y guarda. Reglas en docs/INVOCACIONES.md.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Personajes = require(Shared.Personajes)
local Unidades = require(Shared.Unidades)
local Objetos = require(Shared.Objetos)
local heroes = Personajes.todos
local items = require(ReplicatedStorage.Shared.Data.items)
local coleccion = ReplicatedStorage:WaitForChild("Coleccion")
local abrirPanel = ReplicatedStorage:WaitForChild("AbrirPanel")

local RAREZAS = {
	{ "Common", "Común", Color3.fromRGB(170, 175, 185) },
	{ "Rare", "Raro", Color3.fromRGB(80, 160, 255) },
	{ "Epic", "Épico", Color3.fromRGB(180, 100, 255) },
	{ "Legendary", "Legendario", Color3.fromRGB(255, 190, 60) },
	{ "Mythic", "Mítico", Color3.fromRGB(255, 90, 110) },
	{ "Secret", "Secreto", Color3.fromRGB(80, 255, 220) },
}
local NOMBRE_RAREZA, COLOR_RAREZA = {}, {}
for _, r in RAREZAS do
	NOMBRE_RAREZA[r[1]], COLOR_RAREZA[r[1]] = r[2], r[3]
end

-- Misma paleta que Comic.luau (estilo limpio, 17/11/2026): vidrio oscuro, tarjetas gris azulado, acento dorado.
local Comic = require(script.Parent:WaitForChild("Comic"))
local OSCURO = Comic.FONDO
local BOTON = Comic.ROJO_OSCURO
local ACENTO = Comic.AMARILLO

--------------------------------------------------------------------------------
-- Piezas de interfaz
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Coleccion"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5 -- encima del HUD del lobby
gui.Enabled = false

local function crear(clase: string, props, padre: Instance?)
	local i = Instance.new(clase)
	for k, v in props do
		i[k] = v
	end
	if clase == "Frame" or clase == "TextButton" or clase == "ScrollingFrame" then
		Instance.new("UICorner", i).CornerRadius = UDim.new(0, 8)
	end
	i.Parent = padre
	return i
end

local function texto(props, padre)
	props.BackgroundTransparency = 1
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.Font = props.Font or Enum.Font.GothamMedium
	props.TextSize = props.TextSize or 16
	props.TextWrapped = true
	return crear("TextLabel", props, padre)
end

-- Botones del estilo común (Comic.boton): relleno con degradado y borde fino que acá se pinta por rareza.
local function boton(txt: string, props, padre, alClic)
	props.BackgroundColor3 = props.BackgroundColor3 or BOTON
	props.TextSize = (props.TextSize or 16) + 2
	return Comic.boton(txt, props, padre, alClic)
end

local ventana = crear("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(820, 580),
	BackgroundColor3 = OSCURO,
	BackgroundTransparency = Comic.TRANSPARENCIA,
}, gui)
-- Se achica o agranda con la pantalla como el resto del HUD (docs/INTERFAZ.md).
require(script.Parent:WaitForChild("Comic")).escalar(ventana)
local bordeVentana = Instance.new("UIStroke")
bordeVentana.Thickness, bordeVentana.Color, bordeVentana.Transparency = 1, Comic.BORDE, 0.3
bordeVentana.Parent = ventana
-- Línea roja bajo el título, como en todos los paneles.
local lineaTitulo = crear("Frame", { Position = UDim2.fromOffset(24, 52), Size = UDim2.fromOffset(64, 3), BackgroundColor3 = Comic.ROJO, BorderSizePixel = 0 }, ventana)
local titulo = texto({ Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -120, 0, 34), Font = Comic.TITULO, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Left }, ventana)
local saldo = texto({ Position = UDim2.new(1, -420, 0, 18), Size = UDim2.fromOffset(340, 28), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Right }, ventana)
boton("X", { Position = UDim2.new(1, -52, 0, 12), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = Comic.GRIS }, ventana, function()
	gui.Enabled = false
end)
local mensaje = texto({ Position = UDim2.new(0, 24, 1, -40), Size = UDim2.new(1, -48, 0, 28), TextColor3 = Color3.fromRGB(255, 130, 130) }, ventana)
local cuerpo = crear("Frame", { Position = UDim2.fromOffset(24, 64), Size = UDim2.new(1, -48, 1, -110), BackgroundTransparency = 1 }, ventana)
Comic.moldear(cuerpo) -- tarjetas oscuras con acento, como el resto de las ventanas
-- Títulos en mayúsculas, como las ventanas del HUD.
titulo:GetPropertyChangedSignal("Text"):Connect(function()
	local may = Comic.mayus(titulo.Text)
	if titulo.Text ~= may then
		titulo.Text = may
	end
end)

--------------------------------------------------------------------------------
-- Pantallas
--------------------------------------------------------------------------------
local estado = nil
local pestana = "banner"
local ultimas = nil -- unidades de la última invocación, para mostrarlas
local elegida = nil -- uid de la unidad seleccionada en la pestaña Unidades
local mostrar

local function pedir(nombre, arg)
	local res = coleccion:InvokeServer(nombre, arg)
	mensaje.Text = res.error or ""
	if res.estado then
		estado = res.estado
	end
	return res
end

local function tarjeta(id: string, padre, alto: number)
	local h = heroes[id]
	local f = crear("Frame", { Size = UDim2.fromOffset(220, alto), BackgroundColor3 = BOTON }, padre)
	crear("UIStroke", { Color = COLOR_RAREZA[h.rarity] or Color3.new(1, 1, 1), Thickness = 2 }, f)
	texto({ Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 26), Font = Enum.Font.GothamBold, TextSize = 20, Text = h.name }, f)
	texto({ Position = UDim2.fromOffset(10, 36), Size = UDim2.new(1, -20, 0, 20), TextSize = 14, TextColor3 = COLOR_RAREZA[h.rarity], Text = `{h.category} · {NOMBRE_RAREZA[h.rarity] or h.rarity}` }, f)
	return f
end

local function vaciar()
	for _, c in cuerpo:GetChildren() do
		c:Destroy()
	end
end

local function pantallaInicial()
	titulo.Text = "Tu primer héroe"
	texto({ Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Left, Text = "Elegí uno de los tres héroes iniciales. Empezás con 500 gemas para invocar más." }, cuerpo)
	local fila = crear("Frame", { Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1 }, cuerpo)
	crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 18), HorizontalAlignment = Enum.HorizontalAlignment.Center }, fila)
	for _, id in estado.iniciales do
		local t = tarjeta(id, fila, 300)
		texto({ Position = UDim2.fromOffset(10, 62), Size = UDim2.new(1, -20, 0, 170), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = heroes[id].abilityDesc or "" }, t)
		boton(`ELEGIR`, { Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(1, -20, 0, 40), BackgroundColor3 = Color3.fromRGB(40, 140, 70) }, t, function()
			if not pedir("elegirInicial", id).error then
				pestana = "banner"
				mostrar()
			end
		end)
	end
end

local function pestanas()
	for i, p in { { "banner", "Banner" }, { "unidades", "Unidades" }, { "tienda", "Tienda" }, { "objetos", "Objetos" } } do
		boton(p[2], { Position = UDim2.fromOffset((i - 1) * 150, 0), Size = UDim2.fromOffset(140, 36), BackgroundColor3 = if pestana == p[1] then Comic.ROJO else BOTON }, cuerpo, function()
			pestana = p[1]
			mostrar()
		end)
	end
end

local function porcentaje(p: number): string
	return string.format(if p < 1 then "%.2f%%" else "%.1f%%", p)
end

-- Cuenta regresiva del banner: se actualiza sola mientras la pestaña está abierta.
local relojBanner, finBanner = nil, 0
task.spawn(function()
	while true do
		task.wait(1)
		if relojBanner and relojBanner.Parent and gui.Enabled then
			local s = math.max(0, math.floor(finBanner - os.clock()))
			relojBanner.Text = string.format("Cambia en %d:%02d", s // 60, s % 60)
			if s <= 0 and pestana == "banner" then
				pedir("estado")
				mostrar()
			end
		end
	end
end)

local function pantallaBanner()
	local b = estado.banner
	titulo.Text = "Banner 1 · Asgard"
	finBanner = os.clock() + b.cambiaEn
	relojBanner = texto({ Position = UDim2.fromOffset(600, 4), Size = UDim2.fromOffset(130, 28), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = ACENTO, TextSize = 15, Text = string.format("Cambia en %d:%02d", b.cambiaEn // 60, b.cambiaEn % 60) }, cuerpo)
	-- Destacados: la estrella grande y los dos apoyos, con su probabilidad por tirada.
	local fila = crear("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 230), BackgroundTransparency = 1 }, cuerpo)
	crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14) }, fila)
	for i, id in { b.destacados.estrella, b.destacados.apoyos[1], b.destacados.apoyos[2] } do
		-- Altas para que entre la descripción entera de la habilidad (antes se cortaba a los 4 renglones).
		local t = tarjeta(id, fila, 150)
		t.Size = UDim2.fromOffset(if i == 1 then 250 else t.Size.X.Offset, 230)
		texto({ Position = UDim2.fromOffset(10, 62), Size = UDim2.new(1, -20, 0, 22), TextSize = 15, Font = Enum.Font.GothamBold, TextColor3 = ACENTO, Text = (if i == 1 then "★ ESTRELLA · " else "Destacado · ") .. porcentaje(b.probDestacados[id] or 0) }, t)
		texto({ Position = UDim2.fromOffset(10, 88), Size = UDim2.new(1, -20, 0, 134), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd, Text = heroes[id].abilityDesc or "" }, t)
	end
	-- Probabilidades por rareza.
	local lineas = {}
	for _, r in RAREZAS do
		local p = b.probabilidades[r[1]]
		if p then
			table.insert(lineas, `{r[2]} {porcentaje(p)}`)
		end
	end
	texto({ Position = UDim2.fromOffset(0, 286), Size = UDim2.new(1, 0, 0, 22), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = table.concat(lineas, "  ·  ") .. (if b.garantia then "  ·  Garantía: la próxima no es común" else "") }, cuerpo)
	texto({ Position = UDim2.fromOffset(0, 308), Size = UDim2.new(1, 0, 0, 20), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(180, 185, 200), Text = "Cuando sale la rareza de un destacado, hay 50% de que sea él. Los destacados cambian cada hora." }, cuerpo)
	for i, n in { 1, 10 } do
		boton(`INVOCAR x{n} · 💎 {b.costo * n}`, { Position = UDim2.new(1, -440 + (i - 1) * 230, 1, -50), Size = UDim2.fromOffset(210, 50), TextSize = 18, BackgroundColor3 = if n == 1 then Color3.fromRGB(170, 120, 30) else Color3.fromRGB(190, 80, 40) }, cuerpo, function()
			local res = pedir("invocar", n)
			if res.nuevas then
				require(script.Parent:WaitForChild("Sonido")).efecto("invocar")
				require(script.Parent:WaitForChild("Cinematica")).invocar(res.nuevas)
			end
			ultimas = res.nuevas
			mostrar()
		end)
	end
	-- Resultado de la última invocación.
	if ultimas then
		local lista = crear("Frame", { Position = UDim2.fromOffset(0, 336), Size = UDim2.new(1, -460, 1, -336), BackgroundTransparency = 1 }, cuerpo)
		crear("UIGridLayout", { CellSize = UDim2.fromOffset(150, 30), CellPadding = UDim2.fromOffset(6, 6) }, lista)
		local destacado = { [b.destacados.estrella] = true, [b.destacados.apoyos[1]] = true, [b.destacados.apoyos[2]] = true }
		for _, u in ultimas do
			local h = heroes[u.heroId]
			local f = crear("Frame", { BackgroundColor3 = BOTON }, lista)
			crear("UIStroke", { Color = COLOR_RAREZA[h.rarity], Thickness = 2 }, f)
			texto({ Size = UDim2.fromScale(1, 1), TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = COLOR_RAREZA[h.rarity], Text = (if destacado[u.heroId] then "★ " else "") .. h.name }, f)
		end
	end
end

-- Filtros del inventario (se mantienen mientras el panel está abierto).
local busqueda, filtroRareza, ordenUnidades = "", nil, "rareza"
local ORDENES = { rareza = "Rareza", nivel = "Nivel", nombre = "Nombre" }
local SIGUIENTE_ORDEN = { rareza = "nivel", nivel = "nombre", nombre = "rareza" }
local Rasgos = require(Shared.Rasgos)
local Cinematica = require(script.Parent:WaitForChild("Cinematica"))

-- Tarjeta de unidad: retrato 3D, marco del color de la rareza (brilla en Mítico y Secreto), nombre, nivel y
-- marca de escuadrón. Devuelve el botón.
local function tarjetaUnidad(u, padre, elegida: boolean, enEscuadron: boolean, alClic)
	local h = heroes[u.heroId]
	local color = COLOR_RAREZA[h.rarity] or Color3.new(1, 1, 1)
	local b = boton("", { BackgroundColor3 = if elegida then Color3.fromRGB(78, 88, 120) else BOTON }, padre, alClic)
	Comic.resaltar(b, color)
	-- Brillo que recorre el marco de los más raros.
	if u.shiny then
		Comic.marcoShiny(b)
	elseif h.rarity == "Mythic" or h.rarity == "Secret" then
		local trazo = b:FindFirstChildOfClass("UIStroke")
		local g = crear("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, color) }) }, trazo)
		task.spawn(function()
			while g.Parent and b.Parent do
				g.Rotation = (g.Rotation + 4) % 360
				task.wait(0.03)
			end
		end)
	end
	-- Degradado del color de la rareza abajo.
	local pie = crear("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0.45, 0), BackgroundColor3 = color, BackgroundTransparency = 0.55, BorderSizePixel = 0 }, b)
	crear("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.2) }, pie)
	local marco = crear("Frame", { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -38), BackgroundTransparency = 1 }, b)
	Comic.retrato(marco, u.heroId, h.name, color, Personajes.base(u.heroId))
	texto({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 6, 1, -16), Size = UDim2.new(1, -12, 0, 16), TextSize = 13, Font = Comic.TITULO, Text = h.name, TextTruncate = Enum.TextTruncate.AtEnd }, b)
	texto({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 6, 1, -2), Size = UDim2.new(1, -12, 0, 14), TextSize = 11, Font = Comic.TEXTO, TextColor3 = color, Text = `Nv {u.level}`, TextXAlignment = Enum.TextXAlignment.Left }, b)
	if enEscuadron then
		local marca = crear("Frame", { Position = UDim2.fromOffset(5, 5), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Comic.VERDE }, b)
		marca:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
		texto({ Size = UDim2.fromScale(1, 1), TextSize = 13, Font = Comic.TITULO, Text = "✓" }, marca)
	end
	return b
end

-- Fila de stat de la ficha: nombre a la izquierda, valor a la derecha.
local function stat(padre, y: number, nombre: string, valor: string, color: Color3?)
	texto({ Position = UDim2.fromOffset(12, y), Size = UDim2.new(0.5, -12, 0, 18), TextSize = 13, TextColor3 = Comic.TENUE, Text = nombre, TextXAlignment = Enum.TextXAlignment.Left }, padre)
	texto({ Position = UDim2.new(0.5, 0, 0, y), Size = UDim2.new(0.5, -12, 0, 18), TextSize = 13, Font = Comic.TITULO, TextColor3 = color or Comic.CREMA, Text = valor, TextXAlignment = Enum.TextXAlignment.Right }, padre)
end

local function pantallaUnidades()
	titulo.Text = "Unidades"
	-- Barra de filtros: buscador, rarezas y orden; a la derecha, cuántas hay.
	local caja = crear("TextBox", { Position = UDim2.fromOffset(0, 44), Size = UDim2.fromOffset(170, 32), Text = busqueda, PlaceholderText = "🔍 Buscar…", ClearTextOnFocus = false, Font = Comic.TEXTO, TextSize = 14, TextColor3 = Comic.CREMA, PlaceholderColor3 = Comic.TENUE, BackgroundColor3 = BOTON, TextXAlignment = Enum.TextXAlignment.Left }, cuerpo)
	crear("UIPadding", { PaddingLeft = UDim.new(0, 10) }, caja)
	crear("UICorner", { CornerRadius = UDim.new(0, 8) }, caja)
	caja.FocusLost:Connect(function()
		busqueda = caja.Text
		mostrar()
	end)
	local chips = crear("Frame", { Position = UDim2.fromOffset(180, 44), Size = UDim2.fromOffset(330, 32), BackgroundTransparency = 1 }, cuerpo)
	crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
	for k, r in { { nil, "Todas" }, table.unpack(RAREZAS) } do
		local id = r[1]
		local activo = filtroRareza == id
		local chip = boton(if id then string.sub(r[2], 1, 3) else r[2], { LayoutOrder = k, Size = UDim2.fromOffset(if id then 40 else 58, 32), TextSize = 11, BackgroundColor3 = if activo then (id and COLOR_RAREZA[id] or Comic.ROJO) else BOTON, TextColor3 = if activo or not id then Comic.CREMA else COLOR_RAREZA[id] }, chips, function()
			filtroRareza = id
			mostrar()
		end)
		chip.Name = id or "todas"
	end
	boton(`⇅ {ORDENES[ordenUnidades]}`, { Position = UDim2.fromOffset(518, 44), Size = UDim2.fromOffset(100, 32), TextSize = 12, BackgroundColor3 = BOTON }, cuerpo, function()
		ordenUnidades = SIGUIENTE_ORDEN[ordenUnidades]
		mostrar()
	end)
	texto({ Position = UDim2.new(1, -110, 0, 44), Size = UDim2.fromOffset(110, 32), TextXAlignment = Enum.TextXAlignment.Right, TextSize = 14, TextColor3 = Comic.TENUE, Text = `{#estado.unidades} / {Unidades.MAX_INVENTARIO}` }, cuerpo)

	-- Grilla de tarjetas (filtrada y ordenada).
	local lista = crear("ScrollingFrame", { Position = UDim2.fromOffset(0, 84), Size = UDim2.new(0.6, -10, 1, -84), BackgroundTransparency = 1, ScrollBarThickness = 5, ScrollBarImageColor3 = Comic.BORDE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, cuerpo)
	crear("UIGridLayout", { CellSize = UDim2.fromOffset(100, 132), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, lista)
	crear("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3) }, lista)
	local orden = {}
	local q = string.lower(busqueda)
	for _, u in estado.unidades do
		local h = heroes[u.heroId]
		if h and (not filtroRareza or h.rarity == filtroRareza) and (q == "" or string.find(string.lower(h.name), q, 1, true)) then
			table.insert(orden, u)
		end
	end
	local function rango(u)
		return table.find(Personajes.RAREZAS, heroes[u.heroId].rarity) or 0
	end
	table.sort(orden, function(a, b)
		-- El escuadrón siempre primero.
		local ea, eb = table.find(estado.escuadron, a.uid) ~= nil, table.find(estado.escuadron, b.uid) ~= nil
		if ea ~= eb then
			return ea
		end
		if ordenUnidades == "nombre" and heroes[a.heroId].name ~= heroes[b.heroId].name then
			return heroes[a.heroId].name < heroes[b.heroId].name
		elseif ordenUnidades == "nivel" and a.level ~= b.level then
			return a.level > b.level
		elseif rango(a) ~= rango(b) then
			return rango(a) > rango(b)
		end
		return if a.level ~= b.level then a.level > b.level else a.uid < b.uid
	end)
	for i, u in orden do
		local t = tarjetaUnidad(u, lista, elegida == u.uid, table.find(estado.escuadron, u.uid) ~= nil, function()
			elegida = if elegida == u.uid then nil else u.uid
			mostrar()
		end)
		t.LayoutOrder = i
	end
	if #orden == 0 then
		texto({ Size = UDim2.new(1, 0, 0, 40), TextSize = 14, TextColor3 = Comic.TENUE, Text = "No hay unidades con ese filtro." }, lista)
	end

	-- Ficha de la unidad elegida.
	local der = crear("Frame", { Position = UDim2.new(0.6, 0, 0, 84), Size = UDim2.new(0.4, 0, 1, -84), BackgroundColor3 = BOTON }, cuerpo)
	local u
	for _, x in estado.unidades do
		if x.uid == elegida then
			u = x
		end
	end
	if not u then
		texto({ Position = UDim2.fromOffset(16, 16), Size = UDim2.new(1, -32, 1, -32), TextSize = 14, TextColor3 = Comic.TENUE, TextYAlignment = Enum.TextYAlignment.Top, Text = `Elegí una unidad para ver su ficha, sumarla o sacarla del escuadrón (hasta {Unidades.MAX_ESCUADRON}), venderla por oro o evolucionarla con gemas.` }, der)
		return
	end
	local h = heroes[u.heroId]
	local color = COLOR_RAREZA[h.rarity]
	local enEscuadron = table.find(estado.escuadron, u.uid)
	-- Modelo grande girando, con un halo del color de la rareza detrás.
	local vista = crear("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 120), BackgroundColor3 = color, BackgroundTransparency = 0.82 }, der)
	crear("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.3, 1) }, vista)
	Cinematica.modelo3D(vista, u.heroId, true)
	texto({ Position = UDim2.fromOffset(12, 132), Size = UDim2.new(1, -24, 0, 22), TextSize = 18, Font = Comic.TITULO, Text = Comic.mayus(h.name), TextXAlignment = Enum.TextXAlignment.Left }, der)
	if u.shiny then
		Comic.marcoShiny(vista)
		texto({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 132), Size = UDim2.fromOffset(140, 22), TextSize = 12, Font = Comic.TEXTO, TextColor3 = Comic.DORADO_SHINY, Text = "+5 % de daño", TextXAlignment = Enum.TextXAlignment.Right }, der)
	end
	texto({ Position = UDim2.fromOffset(12, 154), Size = UDim2.new(1, -24, 0, 16), TextSize = 12, TextColor3 = color, Text = `{NOMBRE_RAREZA[h.rarity]} · {h.category} · Nv {u.level}`, TextXAlignment = Enum.TextXAlignment.Left }, der)
	-- Barra de XP.
	local fondoXp = crear("Frame", { Position = UDim2.fromOffset(12, 174), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = Comic.FONDO }, der)
	local llena = if u.level >= Unidades.NIVEL_MAXIMO then 1 else u.xp / Unidades.xpParaSubir(u.level)
	crear("Frame", { Size = UDim2.fromScale(math.clamp(llena, 0, 1), 1), BackgroundColor3 = Comic.AMARILLO }, fondoXp)
	local bono = 1 + (u.level - 1) / 100
	stat(der, 186, "Daño", tostring(math.floor((h.damage or 0) * bono * Unidades.bonoShiny(u) + 0.5)), Comic.AMARILLO)
	stat(der, 204, "Alcance", tostring(h.range or "?"))
	stat(der, 222, "Ataques/s", tostring(h.fireRate or "?"))
	local g = Rasgos.grados(u)
	stat(der, 240, "Rasgo", Rasgos.descripcion(u.rasgo), Color3.fromRGB(255, 143, 176))
	stat(der, 258, "Grados", `{g.dano} / {g.alcance} / {g.cadencia}`)
	texto({ Position = UDim2.fromOffset(12, 278), Size = UDim2.new(1, -24, 0, 30), TextSize = 11, TextColor3 = Comic.TENUE, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextXAlignment = Enum.TextXAlignment.Left, Text = `{h.ability or ""}` }, der)
	-- Acciones: escuadrón, vender y evolucionar.
	local acciones = crear("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -8), Size = UDim2.new(1, -20, 0, 36), BackgroundTransparency = 1 }, der)
	crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, acciones)
	boton(if enEscuadron then "SACAR" else "EQUIPAR", { Size = UDim2.new(0.34, -4, 1, 0), TextSize = 12, BackgroundColor3 = if enEscuadron then Comic.GRIS else Comic.VERDE }, acciones, function()
		local nuevo = table.clone(estado.escuadron)
		if enEscuadron then
			table.remove(nuevo, enEscuadron)
		else
			table.insert(nuevo, u.uid)
		end
		pedir("escuadron", nuevo)
		mostrar()
	end)
	boton(`VENDER 🟡{Unidades.VENTA[h.rarity]}`, { Size = UDim2.new(0.33, -4, 1, 0), TextSize = 11, BackgroundColor3 = Color3.fromRGB(120, 50, 55) }, acciones, function()
		if not pedir("vender", u.uid).error then
			elegida = nil
		end
		mostrar()
	end)
	-- Evolución: esta unidad y otras dos copias del mismo personaje.
	local destino = Personajes.evolucion(u.heroId)
	if destino then
		local copias = { u.uid }
		for _, x in estado.unidades do
			if x.heroId == u.heroId and x.uid ~= u.uid and #copias < Unidades.COPIAS_EVOLUCION then
				table.insert(copias, x.uid)
			end
		end
		local d = heroes[destino]
		local costo = Unidades.COSTO_EVOLUCION[d.rarity]
		local listo = #copias == Unidades.COPIAS_EVOLUCION and estado.gemas >= costo
		texto({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -48), Size = UDim2.new(1, -24, 0, 14), TextSize = 11, TextColor3 = Comic.TENUE, TextXAlignment = Enum.TextXAlignment.Left, Text = `Evoluciona en {d.name}: copias {#copias}/{Unidades.COPIAS_EVOLUCION} · 💎 {estado.gemas}/{costo}` }, der)
		boton("EVOLUCIONAR", { Size = UDim2.new(0.33, -4, 1, 0), TextSize = 11, BackgroundColor3 = if listo then Color3.fromRGB(150, 70, 200) else Comic.GRIS }, acciones, function()
			local res = pedir("evolucionar", copias)
			if res.nueva then
				Cinematica.evolucion(u.heroId, destino)
				elegida = res.nueva.uid
				mensaje.Text = `¡{d.name} se unió a tus unidades!`
			end
			mostrar()
		end)
	end
end

local NOMBRE_RANURA = { weapon = "Arma", armor = "Armadura", artifact = "Artefacto" }

local function pantallaTienda()
	titulo.Text = "Tienda"
	texto({ Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14, Text = "Los tres objetos más accesibles que todavía no tenés. Cada héroe usa uno." }, cuerpo)
	local fila = crear("Frame", { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 1, -80), BackgroundTransparency = 1 }, cuerpo)
	crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16), HorizontalAlignment = Enum.HorizontalAlignment.Center }, fila)
	if #estado.vitrina == 0 then
		texto({ Size = UDim2.new(1, 0, 0, 40), Text = "Ya tenés todos los objetos." }, fila)
	end
	for _, id in estado.vitrina do
		local it = items[id]
		local f = crear("Frame", { Size = UDim2.fromOffset(220, 270), BackgroundColor3 = BOTON }, fila)
		texto({ Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 40), Font = Enum.Font.GothamBold, TextSize = 17, Text = it.name }, f)
		texto({ Position = UDim2.fromOffset(10, 50), Size = UDim2.new(1, -20, 0, 18), TextSize = 13, TextColor3 = ACENTO, Text = `{NOMBRE_RANURA[it.slot] or it.slot} · nivel {it.tier}` }, f)
		texto({ Position = UDim2.fromOffset(10, 74), Size = UDim2.new(1, -20, 0, 130), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = it.desc or "" }, f)
		boton(`Comprar · 💎 {Objetos.precio(it)}`, { Position = UDim2.new(0, 10, 1, -48), Size = UDim2.new(1, -20, 0, 38), BackgroundColor3 = Color3.fromRGB(170, 120, 30) }, f, function()
			if not pedir("comprar", id).error then
				mensaje.Text = `Compraste {it.name}. Equipalo en la pestaña Objetos.`
			end
			mostrar()
		end)
	end
end

local objetoElegido = nil
local function pantallaObjetos()
	titulo.Text = "Objetos"
	-- Izquierda: tus objetos (inventario y equipados). Derecha: tus héroes; clic para equipar el elegido.
	local duenoDe = {}
	for heroeId, id in estado.equipados do
		duenoDe[id] = heroeId
	end
	local todos = table.clone(estado.inventario)
	for id in duenoDe do
		table.insert(todos, id)
	end
	local izq = crear("ScrollingFrame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(0.5, -10, 1, -46), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, cuerpo)
	crear("UIListLayout", { Padding = UDim.new(0, 6) }, izq)
	if #todos == 0 then
		texto({ Size = UDim2.new(1, 0, 0, 40), Text = "Todavía no tenés objetos: compralos en la Tienda." }, izq)
	end
	for _, id in todos do
		local it = items[id]
		local quien = duenoDe[id] and heroes[duenoDe[id]].name
		boton(`{it.name}\n{if quien then "En " .. quien else "Sin equipar"}`, { Size = UDim2.new(1, -10, 0, 50), TextSize = 14, BackgroundColor3 = if objetoElegido == id then Color3.fromRGB(60, 110, 190) else BOTON }, izq, function()
			objetoElegido = if objetoElegido == id then nil else id
			mostrar()
		end)
	end
	local der = crear("ScrollingFrame", { Position = UDim2.new(0.5, 10, 0, 46), Size = UDim2.new(0.5, -10, 1, -46), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, cuerpo)
	crear("UIListLayout", { Padding = UDim.new(0, 6) }, der)
	for _, heroeId in estado.desbloqueados do
		local actual = estado.equipados[heroeId]
		boton(`{heroes[heroeId].name}\n{if actual then items[actual].name else "—"}`, { Size = UDim2.new(1, -10, 0, 50), TextSize = 14 }, der, function()
			if objetoElegido then
				if not pedir("equipar", { heroe = heroeId, objeto = objetoElegido }).error then
					objetoElegido = nil
				end
			elseif actual then
				pedir("quitar", heroeId)
			end
			mostrar()
		end)
	end
	if not objetoElegido then
		mensaje.Text = if #todos > 0 then "Elegí un objeto y después un héroe. Clic en un héroe sin elegir objeto: lo quita." else mensaje.Text
	end
end

function mostrar()
	vaciar()
	saldo.Text = `💎 {estado.gemas}   🟡 {estado.oro}`
	if #estado.desbloqueados == 0 then
		pantallaInicial()
		return
	end
	pestanas()
	if pestana == "banner" then
		pantallaBanner()
	elseif pestana == "tienda" then
		pantallaTienda()
	elseif pestana == "objetos" then
		pantallaObjetos()
	else
		pantallaUnidades()
	end
end

-- Historia y salas (docs/PARTIDA.md): mapas a la izquierda, actos en el centro, sala a la derecha.
local salaRemota = ReplicatedStorage:WaitForChild("Sala")
local sel = { mapa = nil, acto = 1, pesadilla = false, soloAmigos = false }
local plataforma = nil -- plataforma física donde se abrió el panel (docs/LOBBY.md)
local enHistoria = false
local ultimaHistoria = nil

local pantallaHistoria
local function pedirSala(nombre: string, datos)
	local res = salaRemota:InvokeServer(nombre, datos)
	mensaje.Text = res.error or ""
	if res.historia then
		ultimaHistoria = res
	end
	return res
end

function pantallaHistoria()
	local res = ultimaHistoria
	if not res then
		return
	end
	vaciar()
	titulo.Text = "Historia"
	saldo.Text = ""
	-- Mapa elegido: el primero abierto si todavía no hay uno.
	local mapa
	for _, m in res.historia do
		if m.id == sel.mapa then
			mapa = m
		end
	end
	if not mapa then
		mapa = res.historia[1]
		sel.mapa = mapa.id
	end

	-- Izquierda: mapas.
	local izq = crear("Frame", { Size = UDim2.new(0, 170, 1, 0), BackgroundTransparency = 1 }, cuerpo)
	crear("UIListLayout", { Padding = UDim.new(0, 8) }, izq)
	for _, m in res.historia do
		local b = boton(if m.abierto then `{m.nombre}\nActos {m.ganados}/5` else `🔒 {m.nombre}`, { Size = UDim2.new(1, 0, 0, 64), TextSize = 16, BackgroundColor3 = if m.id == sel.mapa then Color3.fromRGB(60, 110, 190) else BOTON }, izq, function()
			sel.mapa, sel.acto, sel.pesadilla = m.id, 1, false
			pantallaHistoria()
		end)
		b.AutoButtonColor = m.abierto
	end

	-- Centro: actos del mapa (y su Infinito).
	local centro = crear("Frame", { Position = UDim2.fromOffset(182, 0), Size = UDim2.new(0, 300, 1, 0), BackgroundTransparency = 1 }, cuerpo)
	texto({ Size = UDim2.new(1, 0, 0, 26), Font = Comic.TITULO, TextSize = 26, TextColor3 = ACENTO, TextXAlignment = Enum.TextXAlignment.Left, Text = mapa.nombre }, centro)
	texto({ Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 18), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = `{mapa.dificultad} · 5 actos de 10 oleadas, jefe en la 10` }, centro)
	local actos = crear("Frame", { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1 }, centro)
	crear("UIListLayout", { Padding = UDim.new(0, 6) }, actos)
	local filas = table.clone(mapa.actos)
	table.insert(filas, { numero = "infinito", jefe = "Oleadas sin fin", abierto = mapa.infinito })
	for _, a in filas do
		local esInfinito = a.numero == "infinito"
		local estadoActo = if not a.abierto then "🔒" elseif a.ganado then "✔" else `+{a.premio} 💎 1.ª vez`
		local b = boton(`{if esInfinito then "INFINITO" else "Acto " .. a.numero}  ·  {a.jefe}\n{if esInfinito then (if a.abierto then "Cada 5 oleadas: +15 💎" else "🔒 Ganá el acto 5") else estadoActo}{if a.pesadilla then "  ·  Pesadilla ✔" else ""}`, {
			Size = UDim2.new(1, 0, 0, 46),
			TextSize = 15,
			BackgroundColor3 = if sel.acto == a.numero then Color3.fromRGB(60, 110, 190) elseif a.abierto then BOTON else Color3.fromRGB(60, 40, 44),
		}, actos, function()
			if a.abierto then
				sel.acto = a.numero
				sel.pesadilla = sel.pesadilla and not esInfinito and a.ganado
				pantallaHistoria()
			end
		end)
		b.AutoButtonColor = a.abierto
	end

	-- Derecha: la sala.
	local der = crear("Frame", { Position = UDim2.fromOffset(494, 0), Size = UDim2.new(1, -494, 1, 0), BackgroundColor3 = Color3.fromRGB(45, 12, 18) }, cuerpo)
	local function linea(y: number, txt: string, color: Color3?)
		texto({ Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -20, 0, 20), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color or Color3.new(1, 1, 1), Text = txt }, der)
	end
	local sala = res.sala
	if sala then
		texto({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 26), Font = Comic.TITULO, TextSize = 24, TextColor3 = ACENTO, TextXAlignment = Enum.TextXAlignment.Left, Text = `Sala · {#sala.miembros}/4` }, der)
		linea(34, `{sala.nombreMapa} · {if sala.acto == "infinito" then "Infinito" elseif sala.acto == "raid" then "Raid" else "Acto " .. sala.acto}{if sala.pesadilla then " · Pesadilla" else ""}{if sala.cuenta then ` · empieza en {sala.cuenta} s` else ""}`, ACENTO)
		for i, m in sala.miembros do
			linea(58 + (i - 1) * 22, (if m.anfitrion then "👑 " else "• ") .. m.nombre)
		end
		for i = #sala.miembros + 1, 4 do
			linea(58 + (i - 1) * 22, "+ Lugar libre", Color3.fromRGB(150, 150, 150))
		end
		if sala.anfitrion == Players.LocalPlayer.DisplayName then
			boton("¡EMPEZAR!", { Position = UDim2.new(0, 10, 1, -100), Size = UDim2.new(1, -20, 0, 42), BackgroundColor3 = Color3.fromRGB(40, 150, 60) }, der, function()
				pedirSala("iniciar")
				pantallaHistoria()
			end)
		else
			linea(160, "Esperando al anfitrión…", Color3.fromRGB(200, 200, 200))
		end
		boton("Salir de la sala", { Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(1, -20, 0, 40) }, der, function()
			pedirSala("salir")
			pantallaHistoria()
		end)
		return
	end
	texto({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 26), Font = Comic.TITULO, TextSize = 24, TextColor3 = ACENTO, TextXAlignment = Enum.TextXAlignment.Left, Text = "Sala" }, der)
	local actoElegido
	for _, a in filas do
		if a.numero == sel.acto then
			actoElegido = a
		end
	end
	local pesadillaPosible = sel.acto ~= "infinito" and actoElegido and actoElegido.ganado
	boton(`Sólo amigos: {if sel.soloAmigos then "SÍ" else "NO"}`, { Position = UDim2.fromOffset(10, 38), Size = UDim2.new(1, -20, 0, 34), TextSize = 15 }, der, function()
		sel.soloAmigos = not sel.soloAmigos
		pantallaHistoria()
	end)
	boton(if pesadillaPosible then `Pesadilla: {if sel.pesadilla then "SÍ (premios ×2)" else "NO"}` else "Pesadilla: ganá el acto", { Position = UDim2.fromOffset(10, 78), Size = UDim2.new(1, -20, 0, 34), TextSize = 15, BackgroundColor3 = if sel.pesadilla then Color3.fromRGB(120, 20, 90) else BOTON }, der, function()
		if pesadillaPosible then
			sel.pesadilla = not sel.pesadilla
			pantallaHistoria()
		end
	end)
	-- Salas abiertas de otros jugadores.
	linea(120, if #res.abiertas > 0 then "Salas abiertas:" else "No hay salas abiertas", Color3.fromRGB(200, 200, 200))
	for i, s in res.abiertas do
		if i > 2 then
			break
		end
		boton(`Unirse: {s.anfitrion} · {s.nombreMapa} {if s.acto == "infinito" then "∞" elseif s.acto == "raid" then "Raid" else "A" .. s.acto} ({#s.miembros}/4)`, { Position = UDim2.fromOffset(10, 142 + (i - 1) * 38), Size = UDim2.new(1, -20, 0, 32), TextSize = 13 }, der, function()
			pedirSala("unirse", s.id)
			pantallaHistoria()
		end)
	end
	local datos = { mapa = sel.mapa, acto = sel.acto, pesadilla = sel.pesadilla and pesadillaPosible, soloAmigos = sel.soloAmigos, plataforma = plataforma }
	boton("SOLO", { Name = "Solo", Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(0.5, -15, 0, 42), BackgroundColor3 = Color3.fromRGB(110, 60, 200) }, der, function()
		datos.solo = true
		local r = pedirSala("crear", datos)
		if r.empezo then
			gui.Enabled = false
		else
			pantallaHistoria()
		end
	end)
	boton("CREAR SALA", { Position = UDim2.new(0.5, 5, 1, -50), Size = UDim2.new(0.5, -15, 0, 42), BackgroundColor3 = Color3.fromRGB(40, 150, 60) }, der, function()
		datos.solo = false
		pedirSala("crear", datos)
		pantallaHistoria()
	end)
end

-- Mientras el panel de Historia está abierto, refrescar la sala (para ver quién entra). Sólo se redibuja si
-- cambió algo: redibujar cada 2 s destruía los botones y a veces se perdía el clic en SOLO.
local HttpService = game:GetService("HttpService")
local function firmaSala(res): string
	local ok, s = pcall(HttpService.JSONEncode, HttpService, { res.sala, res.abiertas, res.historia })
	return if ok then s else tostring(os.clock())
end
task.spawn(function()
	while true do
		task.wait(2)
		if gui.Enabled and enHistoria and not Players.LocalPlayer:GetAttribute("Partida") then
			local antes = ultimaHistoria and firmaSala(ultimaHistoria)
			local res = pedirSala("estado")
			if res.historia and firmaSala(res) ~= antes then
				pantallaHistoria()
			end
		end
	end
end)
-- Al empezar la partida (también para los invitados de una sala), cerrar el panel.
Players.LocalPlayer:GetAttributeChangedSignal("Partida"):Connect(function()
	if Players.LocalPlayer:GetAttribute("Partida") then
		gui.Enabled = false
	end
end)

abrirPanel.OnClientEvent:Connect(function(panel, datos)
	if panel == "historia" then
		enHistoria = true
		plataforma = datos and datos.plataforma
		if datos and datos.infinito then
			sel.acto = "infinito"
		end
		pedirSala("estado")
		pantallaHistoria()
		gui.Enabled = true
		return
	end
	if panel ~= "invocaciones" then
		return
	end
	enHistoria = false
	mensaje.Text = ""
	ultimas = nil
	if datos and datos.pestana then
		pestana = datos.pestana
	end
	if pedir("estado").estado then
		gui.Enabled = true
		mostrar()
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape then
		gui.Enabled = false
	end
end)

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
