-- Paneles de las estaciones del HUB: Invocaciones (elección inicial, reclutamiento y escuadrón)
-- e Infinito (explica la regla de créditos antes de entrar, como el 3D).
-- Sólo muestra y envía pedidos; el servidor valida y guarda.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local heroes = require(ReplicatedStorage:WaitForChild("Shared").Data.heroes)
local coleccion = ReplicatedStorage:WaitForChild("Coleccion")
local abrirPanel = ReplicatedStorage:WaitForChild("AbrirPanel")
local entrar = ReplicatedStorage:WaitForChild("Entrar")

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

local OSCURO = Color3.fromRGB(20, 22, 32)
local BOTON = Color3.fromRGB(44, 48, 66)
local ACENTO = Color3.fromRGB(255, 200, 90)

--------------------------------------------------------------------------------
-- Piezas de interfaz
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Coleccion"
gui.ResetOnSpawn = false
gui.Enabled = false

local function crear(clase: string, props, padre: Instance?)
	local i = Instance.new(clase)
	for k, v in props do
		i[k] = v
	end
	if clase == "Frame" or clase == "TextButton" or clase == "ScrollingFrame" then
		Instance.new("UICorner", i).CornerRadius = UDim.new(0, 10)
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
	props.Font = Enum.Font.GothamBold
	props.TextSize = props.TextSize or 16
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
local titulo = texto({ Position = UDim2.fromOffset(24, 14), Size = UDim2.new(1, -120, 0, 36), Font = Enum.Font.GothamBlack, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ACENTO }, ventana)
local saldo = texto({ Position = UDim2.new(1, -250, 0, 18), Size = UDim2.fromOffset(170, 28), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Right }, ventana)
boton("X", { Position = UDim2.new(1, -56, 0, 12), Size = UDim2.fromOffset(40, 40) }, ventana, function()
	gui.Enabled = false
end)
local mensaje = texto({ Position = UDim2.new(0, 24, 1, -40), Size = UDim2.new(1, -48, 0, 28), TextColor3 = Color3.fromRGB(255, 130, 130) }, ventana)
local cuerpo = crear("Frame", { Position = UDim2.fromOffset(24, 64), Size = UDim2.new(1, -48, 1, -110), BackgroundTransparency = 1 }, ventana)

--------------------------------------------------------------------------------
-- Pantallas
--------------------------------------------------------------------------------
local estado = nil
local pestana = "reclutar"
local seleccion = {}
local ultimo = nil -- último héroe reclutado, para mostrarlo
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
	texto({ Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Left, Text = "Elegí uno de los tres héroes iniciales. Empezás con 1.200 créditos para reclutar o mejorar en combate." }, cuerpo)
	local fila = crear("Frame", { Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1 }, cuerpo)
	crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 18), HorizontalAlignment = Enum.HorizontalAlignment.Center }, fila)
	for _, id in estado.iniciales do
		local t = tarjeta(id, fila, 300)
		texto({ Position = UDim2.fromOffset(10, 62), Size = UDim2.new(1, -20, 0, 170), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = heroes[id].abilityDesc or "" }, t)
		boton(`ELEGIR`, { Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(1, -20, 0, 40), BackgroundColor3 = Color3.fromRGB(40, 140, 70) }, t, function()
			if not pedir("elegirInicial", id).error then
				pestana = "escuadron"
				mostrar()
			end
		end)
	end
end

local function pestanas()
	for i, p in { { "reclutar", "Reclutamiento" }, { "escuadron", "Escuadrón" } } do
		boton(p[2], { Position = UDim2.fromOffset((i - 1) * 190, 0), Size = UDim2.fromOffset(180, 36), BackgroundColor3 = if pestana == p[1] then Color3.fromRGB(60, 110, 190) else BOTON }, cuerpo, function()
			pestana = p[1]
			mostrar()
		end)
	end
end

local function pantallaReclutar()
	titulo.Text = "Centro de reclutamiento"
	local izq = crear("Frame", { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(0.5, -10, 1, -50), BackgroundTransparency = 1 }, cuerpo)
	local lineas = { "Sin repetidos. El costo sube 12% por compra.", "Probabilidades del próximo reclutamiento:" }
	for _, r in RAREZAS do
		local pct = estado.probabilidades[r[1]]
		if pct then
			table.insert(lineas, `   {r[2]}: {string.format(if pct < 1 then "%.2f" else "%.1f", pct)}%`)
		end
	end
	if estado.garantia then
		table.insert(lineas, "Tras cuatro comunes seguidos, el próximo es de rareza superior.")
	end
	texto({ Size = UDim2.new(1, 0, 1, -60), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = table.concat(lineas, "\n") }, izq)
	boton(`RECLUTAR · 💰 {estado.costo}`, { Position = UDim2.new(0, 0, 1, -50), Size = UDim2.new(1, 0, 0, 50), TextSize = 20, BackgroundColor3 = Color3.fromRGB(170, 120, 30) }, izq, function()
		local res = pedir("reclutar")
		ultimo = res.heroe
		mostrar()
	end)
	local der = crear("Frame", { Position = UDim2.new(0.5, 10, 0, 50), Size = UDim2.new(0.5, -10, 1, -50), BackgroundTransparency = 1 }, cuerpo)
	if ultimo then
		texto({ Size = UDim2.new(1, 0, 0, 28), TextSize = 18, Text = if ultimo.garantizado then "¡Garantizado!" else "¡Nuevo héroe!" }, der)
		local t = tarjeta(ultimo.id, der, 120)
		t.Position = UDim2.new(0.5, -110, 0, 40)
		texto({ Position = UDim2.fromOffset(10, 64), Size = UDim2.new(1, -20, 0, 40), TextSize = 13, Text = "Se sumó a tu escuadrón si había lugar." }, t)
	end
end

local function pantallaEscuadron()
	titulo.Text = "Tu escuadrón"
	local cuenta = texto({ Position = UDim2.fromOffset(400, 4), Size = UDim2.fromOffset(160, 28), TextXAlignment = Enum.TextXAlignment.Right }, cuerpo)
	local function contar()
		cuenta.Text = `{#seleccion} / 6 · {#estado.desbloqueados} héroes`
	end
	local lista = crear("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -110),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, cuerpo)
	crear("UIGridLayout", { CellSize = UDim2.fromOffset(170, 56), CellPadding = UDim2.fromOffset(10, 10) }, lista)
	for _, id in estado.desbloqueados do
		local h = heroes[id]
		local b
		b = boton(`{h.name}\n{NOMBRE_RAREZA[h.rarity] or h.rarity}`, { TextSize = 14 }, lista, function()
			local i = table.find(seleccion, id)
			if i then
				table.remove(seleccion, i)
			elseif #seleccion < 6 then
				table.insert(seleccion, id)
			end
			b.BackgroundColor3 = if table.find(seleccion, id) then Color3.fromRGB(60, 110, 190) else BOTON
			contar()
		end)
		b.BackgroundColor3 = if table.find(seleccion, id) then Color3.fromRGB(60, 110, 190) else BOTON
		crear("UIStroke", { Color = COLOR_RAREZA[h.rarity] or Color3.new(1, 1, 1), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	end
	contar()
	boton("Guardar escuadrón", { Position = UDim2.new(1, -220, 1, -50), Size = UDim2.fromOffset(220, 46), BackgroundColor3 = Color3.fromRGB(40, 140, 70) }, cuerpo, function()
		if not pedir("equipo", seleccion).error then
			mensaje.Text = "Escuadrón guardado"
		end
	end)
end

function mostrar()
	vaciar()
	saldo.Text = `💰 {estado.creditos}`
	if #estado.desbloqueados == 0 then
		pantallaInicial()
		return
	end
	if pestana == "escuadron" then
		seleccion = table.clone(estado.equipo)
	end
	pestanas()
	if pestana == "reclutar" then
		pantallaReclutar()
	else
		pantallaEscuadron()
	end
end

local function pantallaInfinito(record)
	vaciar()
	titulo.Text = "Infinito"
	saldo.Text = ""
	mensaje.Text = ""
	local r = record or { bestWave = 0, bestScore = 0 }
	texto({
		Size = UDim2.new(1, 0, 1, -70),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 18,
		Text = table.concat({
			"Oleadas sin límite en la Base Avengers con tu escuadrón.",
			"Empezás con 750 créditos y 20 vidas; cada cinco oleadas ganás +300.",
			"",
			"Regla de créditos: si ganás o gastás créditos en Infinito, tu saldo pasa a ser el de esta partida.",
			"Si salís antes de cualquier movimiento, conservás tu saldo actual.",
			"",
			`Tu récord: oleada {r.bestWave} · {r.bestScore} puntos`,
		}, "\n"),
	}, cuerpo)
	boton("ENTRAR", { Position = UDim2.new(1, -220, 1, -50), Size = UDim2.fromOffset(220, 50), TextSize = 20, BackgroundColor3 = Color3.fromRGB(120, 80, 210) }, cuerpo, function()
		local err = entrar:InvokeServer("survival")
		mensaje.Text = err or ""
		if not err then
			gui.Enabled = false
		end
	end)
end

abrirPanel.OnClientEvent:Connect(function(panel, datos)
	if panel == "infinito" then
		pantallaInfinito(datos)
		gui.Enabled = true
		return
	end
	if panel ~= "invocaciones" then
		return
	end
	mensaje.Text = ""
	ultimo = nil
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
