-- Paneles de las estaciones del HUB: Invocaciones (elección inicial, banner, unidades, tienda y objetos),
-- Historia e Infinito.
-- Sólo muestra y envía pedidos; el servidor valida y guarda. Reglas en docs/INVOCACIONES.md.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Personajes = require(Shared.Personajes)
local Unidades = require(Shared.Unidades)
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

-- Paleta cómic (la misma que Comic.luau del HUD): fondo rojo muy oscuro, botones rojos, acento amarillo.
local OSCURO = Color3.fromRGB(28, 8, 12)
local BOTON = Color3.fromRGB(150, 25, 32)
local ACENTO = Color3.fromRGB(255, 214, 40)

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
		Instance.new("UICorner", i).CornerRadius = UDim.new(0, 6)
	end
	if clase == "TextButton" then
		local borde = Instance.new("UIStroke")
		borde.Thickness, borde.ApplyStrokeMode = 2, Enum.ApplyStrokeMode.Border
		borde.Parent = i
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

local function boton(txt: string, props, padre, alClic)
	props.Text = txt
	props.BackgroundColor3 = props.BackgroundColor3 or BOTON
	props.TextColor3 = Color3.new(1, 1, 1)
	props.Font = Enum.Font.Bangers
	props.TextSize = (props.TextSize or 16) + 4
	props.TextStrokeTransparency = 0
	props.TextWrapped = true
	local b = crear("TextButton", props, padre)
	b.Activated:Connect(alClic)
	return b
end

local ventana = crear("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(780, 500),
	BackgroundColor3 = OSCURO,
	BackgroundTransparency = 0.05,
}, gui)
local bordeVentana = Instance.new("UIStroke")
bordeVentana.Thickness = 5
bordeVentana.Parent = ventana
local titulo = texto({ Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -120, 0, 36), Font = Enum.Font.Bangers, TextSize = 34, TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ACENTO }, ventana)
local saldo = texto({ Position = UDim2.new(1, -420, 0, 18), Size = UDim2.fromOffset(340, 28), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Right }, ventana)
boton("X", { Position = UDim2.new(1, -56, 0, 12), Size = UDim2.fromOffset(40, 40) }, ventana, function()
	gui.Enabled = false
end)
local mensaje = texto({ Position = UDim2.new(0, 24, 1, -40), Size = UDim2.new(1, -48, 0, 28), TextColor3 = Color3.fromRGB(255, 130, 130) }, ventana)
local cuerpo = crear("Frame", { Position = UDim2.fromOffset(24, 64), Size = UDim2.new(1, -48, 1, -110), BackgroundTransparency = 1 }, ventana)

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
		boton(p[2], { Position = UDim2.fromOffset((i - 1) * 150, 0), Size = UDim2.fromOffset(140, 36), BackgroundColor3 = if pestana == p[1] then Color3.fromRGB(60, 110, 190) else BOTON }, cuerpo, function()
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
	local fila = crear("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 150), BackgroundTransparency = 1 }, cuerpo)
	crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14) }, fila)
	for i, id in { b.destacados.estrella, b.destacados.apoyos[1], b.destacados.apoyos[2] } do
		local t = tarjeta(id, fila, 150)
		if i == 1 then
			t.Size = UDim2.fromOffset(250, 150)
		end
		texto({ Position = UDim2.fromOffset(10, 62), Size = UDim2.new(1, -20, 0, 22), TextSize = 15, Font = Enum.Font.GothamBold, TextColor3 = ACENTO, Text = (if i == 1 then "★ ESTRELLA · " else "Destacado · ") .. porcentaje(b.probDestacados[id] or 0) }, t)
		texto({ Position = UDim2.fromOffset(10, 88), Size = UDim2.new(1, -20, 0, 54), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = heroes[id].abilityDesc or "" }, t)
	end
	-- Probabilidades por rareza.
	local lineas = {}
	for _, r in RAREZAS do
		local p = b.probabilidades[r[1]]
		if p then
			table.insert(lineas, `{r[2]} {porcentaje(p)}`)
		end
	end
	texto({ Position = UDim2.fromOffset(0, 206), Size = UDim2.new(1, 0, 0, 22), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = table.concat(lineas, "  ·  ") .. (if b.garantia then "  ·  Garantía: la próxima no es común" else "") }, cuerpo)
	texto({ Position = UDim2.fromOffset(0, 228), Size = UDim2.new(1, 0, 0, 20), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(180, 185, 200), Text = "Cuando sale la rareza de un destacado, hay 50% de que sea él. Los destacados cambian cada hora." }, cuerpo)
	for i, n in { 1, 10 } do
		boton(`INVOCAR x{n} · 💎 {b.costo * n}`, { Position = UDim2.new(1, -440 + (i - 1) * 230, 1, -50), Size = UDim2.fromOffset(210, 50), TextSize = 18, BackgroundColor3 = if n == 1 then Color3.fromRGB(170, 120, 30) else Color3.fromRGB(190, 80, 40) }, cuerpo, function()
			local res = pedir("invocar", n)
			if res.nuevas then
				require(script.Parent:WaitForChild("Sonido")).efecto("invocar")
			end
			ultimas = res.nuevas
			mostrar()
		end)
	end
	-- Resultado de la última invocación.
	if ultimas then
		local lista = crear("Frame", { Position = UDim2.fromOffset(0, 256), Size = UDim2.new(1, -460, 1, -256), BackgroundTransparency = 1 }, cuerpo)
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

local function pantallaUnidades()
	titulo.Text = "Unidades"
	texto({ Position = UDim2.fromOffset(600, 4), Size = UDim2.fromOffset(130, 28), TextXAlignment = Enum.TextXAlignment.Right, Text = `{#estado.unidades} / {Unidades.MAX_INVENTARIO}` }, cuerpo)
	local lista = crear("ScrollingFrame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(0.62, -10, 1, -46), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, cuerpo)
	crear("UIGridLayout", { CellSize = UDim2.fromOffset(140, 62), CellPadding = UDim2.fromOffset(8, 8) }, lista)
	-- Escuadrón primero, después por rareza (más alta arriba) y nivel.
	local orden = table.clone(estado.unidades)
	table.sort(orden, function(a, b)
		local ea, eb = table.find(estado.escuadron, a.uid), table.find(estado.escuadron, b.uid)
		if (ea ~= nil) ~= (eb ~= nil) then
			return ea ~= nil
		end
		local ra, rb = table.find(Personajes.RAREZAS, heroes[a.heroId].rarity), table.find(Personajes.RAREZAS, heroes[b.heroId].rarity)
		if ra ~= rb then
			return ra > rb
		end
		return if a.level ~= b.level then a.level > b.level else a.uid < b.uid
	end)
	for _, u in orden do
		local h = heroes[u.heroId]
		local enEscuadron = table.find(estado.escuadron, u.uid) ~= nil
		local b = boton("", { BackgroundColor3 = if elegida == u.uid then Color3.fromRGB(90, 140, 220) elseif enEscuadron then Color3.fromRGB(40, 80, 140) else BOTON }, lista, function()
			elegida = if elegida == u.uid then nil else u.uid
			mostrar()
		end)
		-- El botón ya trae su borde: se pinta del color de la rareza.
		b:FindFirstChildOfClass("UIStroke").Color = COLOR_RAREZA[h.rarity]
		texto({ Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 20), TextSize = 13, Font = Enum.Font.GothamBold, Text = h.name }, b)
		texto({ Position = UDim2.fromOffset(6, 24), Size = UDim2.new(1, -12, 0, 16), TextSize = 12, TextColor3 = COLOR_RAREZA[h.rarity], Text = `Nv {u.level}` .. (if enEscuadron then " · Escuadrón" else "") }, b)
		-- Barra de experiencia hacia el próximo nivel.
		local fondo = crear("Frame", { Position = UDim2.new(0, 8, 1, -14), Size = UDim2.new(1, -16, 0, 6), BackgroundColor3 = Color3.fromRGB(20, 22, 32) }, b)
		local llena = if u.level >= Unidades.NIVEL_MAXIMO then 1 else u.xp / Unidades.xpParaSubir(u.level)
		crear("Frame", { Size = UDim2.fromScale(math.clamp(llena, 0, 1), 1), BackgroundColor3 = Color3.fromRGB(90, 220, 120) }, fondo)
	end
	-- Panel de la unidad elegida: escuadrón, venta y evolución.
	local der = crear("Frame", { Position = UDim2.new(0.62, 10, 0, 46), Size = UDim2.new(0.38, -10, 1, -46), BackgroundColor3 = BOTON }, cuerpo)
	local u
	for _, x in estado.unidades do
		if x.uid == elegida then
			u = x
		end
	end
	if not u then
		texto({ Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -24), TextSize = 14, TextYAlignment = Enum.TextYAlignment.Top, Text = `Elegí una unidad para sumarla o sacarla del escuadrón (hasta {Unidades.MAX_ESCUADRON}), venderla o evolucionarla.\n\nNúcleos: {estado.nucleos}` }, der)
		return
	end
	local h = heroes[u.heroId]
	local enEscuadron = table.find(estado.escuadron, u.uid)
	texto({ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 26), TextSize = 19, Font = Enum.Font.GothamBold, Text = h.name }, der)
	local xpTexto = if u.level >= Unidades.NIVEL_MAXIMO then "nivel máximo" else `{u.xp}/{Unidades.xpParaSubir(u.level)} XP`
	texto({ Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 40), TextSize = 13, TextColor3 = COLOR_RAREZA[h.rarity], Text = `{NOMBRE_RAREZA[h.rarity]} · Nv {u.level} ({xpTexto})\n+{u.level - 1}% de daño · se coloca hasta {Unidades.LIMITE_COLOCACION[h.rarity]} veces` }, der)
	boton(if enEscuadron then "Sacar del escuadrón" else "Sumar al escuadrón", { Position = UDim2.fromOffset(12, 84), Size = UDim2.new(1, -24, 0, 38) }, der, function()
		local nuevo = table.clone(estado.escuadron)
		if enEscuadron then
			table.remove(nuevo, enEscuadron)
		else
			table.insert(nuevo, u.uid)
		end
		pedir("escuadron", nuevo)
		mostrar()
	end)
	boton(`Vender · 💎 {Unidades.VENTA[h.rarity]}`, { Position = UDim2.fromOffset(12, 130), Size = UDim2.new(1, -24, 0, 38), BackgroundColor3 = Color3.fromRGB(120, 50, 50) }, der, function()
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
		local nucleos = Unidades.NUCLEOS[d.rarity]
		texto({ Position = UDim2.fromOffset(12, 178), Size = UDim2.new(1, -24, 0, 54), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = `Evoluciona en {d.name} ({NOMBRE_RAREZA[d.rarity]}).\nCopias {#copias}/{Unidades.COPIAS_EVOLUCION} · Núcleos {estado.nucleos}/{nucleos}` }, der)
		local listo = #copias == Unidades.COPIAS_EVOLUCION and estado.nucleos >= nucleos
		boton("Evolucionar", { Position = UDim2.new(0, 12, 1, -50), Size = UDim2.new(1, -24, 0, 40), BackgroundColor3 = if listo then Color3.fromRGB(150, 70, 200) else Color3.fromRGB(60, 60, 66) }, der, function()
			local res = pedir("evolucionar", copias)
			if res.nueva then
				elegida = res.nueva.uid
				mensaje.Text = `¡{d.name} se unió a tus unidades!`
			end
			mostrar()
		end)
	else
		texto({ Position = UDim2.fromOffset(12, 178), Size = UDim2.new(1, -24, 0, 40), TextSize = 13, Text = "Este personaje no evoluciona." }, der)
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
		boton(`Comprar · 💰 {it.price}`, { Position = UDim2.new(0, 10, 1, -48), Size = UDim2.new(1, -20, 0, 38), BackgroundColor3 = Color3.fromRGB(170, 120, 30) }, f, function()
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
	saldo.Text = `💰 {estado.creditos}   💎 {estado.gemas}   🔷 {estado.nucleos}`
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
	texto({ Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.Bangers, TextSize = 26, TextColor3 = ACENTO, TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left, Text = mapa.nombre }, centro)
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
		texto({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 26), Font = Enum.Font.Bangers, TextSize = 24, TextColor3 = ACENTO, TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left, Text = `Sala · {#sala.miembros}/4` }, der)
		linea(34, `{sala.nombreMapa} · {if sala.acto == "infinito" then "Infinito" elseif sala.acto == "raid" then "Raid" else "Acto " .. sala.acto}{if sala.pesadilla then " · Pesadilla" else ""}`, ACENTO)
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
	texto({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 26), Font = Enum.Font.Bangers, TextSize = 24, TextColor3 = ACENTO, TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Left, Text = "Sala" }, der)
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
	local datos = { mapa = sel.mapa, acto = sel.acto, pesadilla = sel.pesadilla and pesadillaPosible, soloAmigos = sel.soloAmigos }
	boton("SOLO", { Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(0.5, -15, 0, 42), BackgroundColor3 = Color3.fromRGB(110, 60, 200) }, der, function()
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

-- Mientras el panel de Historia está abierto, refrescar la sala (para ver quién entra).
task.spawn(function()
	while true do
		task.wait(2)
		if gui.Enabled and enHistoria and not Players.LocalPlayer:GetAttribute("Partida") then
			pedirSala("estado")
			pantallaHistoria()
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
