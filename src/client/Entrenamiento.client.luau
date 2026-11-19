-- Panel del entrenamiento (docs/ENTRENAMIENTO.md): sólo en el campo de pruebas (Acto «Entrenamiento»).
-- Pestañas: HÉROES (cualquier héroe con nivel, mejora, rasgo, grados, objeto y Shiny en una de las 6 casillas),
-- ENEMIGOS (tandas a pedido, limpiar, base inmortal) y DATOS (daño, DPS, golpes, críticos, estados y desglose de
-- cada unidad; detalle del enemigo que tocás). Arriba: velocidad con cámara lenta, cámara sobre una unidad,
-- ocultar la interfaz (tecla H) y salir. Sólo pide; el servidor valida (Partida.luau).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Comic = require(script.Parent:WaitForChild("Comic"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Personajes = require(Shared.Personajes)
local Rasgos = require(Shared.Rasgos)
local Mejoras = require(Shared.Mejoras)
local Unidades = require(Shared.Unidades)
local Entrenamiento = require(Shared.Entrenamiento)
local items = require(Shared.Data.items)
local enemigosDatos = require(Shared.Data.enemies)
local accion = ReplicatedStorage:WaitForChild("Accion")

local jugador = Players.LocalPlayer
local crear, texto = Comic.crear, Comic.texto
local camara = workspace.CurrentCamera

local gui = crear("ScreenGui", { Name = "Entrenamiento", ResetOnSpawn = false, DisplayOrder = 4, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, jugador:WaitForChild("PlayerGui"))
local estado, carpeta = nil, nil

--------------------------------------------------------------------------------
-- Ventana
--------------------------------------------------------------------------------
local ANCHO, ALTO = 400, 612
local ventana = crear("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 96), Size = UDim2.fromOffset(ANCHO, ALTO), BackgroundColor3 = Comic.FONDO, BackgroundTransparency = Comic.TRANSPARENCIA }, gui)
Comic.borde(ventana)
Comic.escalar(ventana)
texto({ Text = "ENTRENAMIENTO", Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 24), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left }, ventana)
local linea = crear("Frame", { Position = UDim2.fromOffset(16, 37), Size = UDim2.fromOffset(48, 3), BackgroundColor3 = Comic.ROJO, BorderSizePixel = 0 }, ventana)
crear("UICorner", { CornerRadius = UDim.new(1, 0) }, linea)
local mensaje = texto({ Text = "", Position = UDim2.new(0, 16, 1, -26), Size = UDim2.new(1, -32, 0, 18), TextSize = 13, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, ventana)

local function pedir(nombre: string, a, b)
	local ok, err = pcall(accion.InvokeServer, accion, nombre, a, b)
	mensaje.Text = if not ok then "Sin conexión" elseif err then tostring(err) else ""
	return ok and not err
end

local siguienteCamara, alternarInterfaz -- se definen abajo (cámara y ocultar)

-- Fila de herramientas: velocidad, cámara, ocultar y salir.
local herramientas = crear("Frame", { Position = UDim2.fromOffset(16, 48), Size = UDim2.new(1, -32, 0, 32), BackgroundTransparency = 1 }, ventana)
crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, herramientas)
local function chico(txt: string, color: Color3, orden: number, ancho: number, alClic): TextButton
	return Comic.boton(txt, { Size = UDim2.fromOffset(ancho, 32), TextSize = 12, BackgroundColor3 = color, LayoutOrder = orden }, herramientas, alClic)
end
local botonVelocidad = chico("×1", Color3.fromRGB(60, 120, 200), 1, 70, function()
	pedir("velocidad")
end)
local botonCamara = chico("CÁMARA", Comic.GRIS, 2, 110, function()
	siguienteCamara()
end)
local botonOcultar = chico("OCULTAR (H)", Comic.GRIS, 3, 102, function()
	alternarInterfaz()
end)
chico("SALIR", Comic.ROJO_OSCURO, 4, 70, function()
	accion:InvokeServer("volver")
end)

-- Pestañas.
local pestanas = crear("Frame", { Position = UDim2.fromOffset(16, 90), Size = UDim2.new(1, -32, 0, 32), BackgroundTransparency = 1 }, ventana)
crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, pestanas)
local cuerpo = crear("Frame", { Position = UDim2.fromOffset(16, 132), Size = UDim2.new(1, -32, 1, -164), BackgroundTransparency = 1 }, ventana)
local paginas, botonesPestana = {}, {}
local function pestana(nombre: string, orden: number): Frame
	local pagina = crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = orden == 1 }, cuerpo)
	paginas[nombre] = pagina
	botonesPestana[nombre] = Comic.boton(nombre, { Size = UDim2.fromOffset(116, 32), TextSize = 14, BackgroundColor3 = if orden == 1 then Comic.ROJO else Comic.GRIS, LayoutOrder = orden }, pestanas, function()
		for n, p in paginas do
			p.Visible = n == nombre
			botonesPestana[n].BackgroundColor3 = if n == nombre then Comic.ROJO else Comic.GRIS
		end
	end)
	return pagina
end

-- Fila «rótulo · − valor +» o «rótulo · ◀ valor ▶»; alCambiar(delta) devuelve el texto nuevo.
local function fila(padre: Instance, y: number, rotulo: string, alCambiar: (number) -> string, izq: string?, der: string?): TextLabel
	texto({ Text = rotulo, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(110, 28), TextSize = 13, Font = Comic.TEXTO, TextColor3 = Comic.TENUE, TextXAlignment = Enum.TextXAlignment.Left }, padre)
	local valor = texto({ Text = alCambiar(0), Position = UDim2.fromOffset(150, y), Size = UDim2.new(1, -190, 0, 28), TextSize = 14 }, padre)
	Comic.boton(izq or "−", { Position = UDim2.fromOffset(112, y), Size = UDim2.fromOffset(34, 28), TextSize = 14, BackgroundColor3 = Comic.GRIS }, padre, function()
		valor.Text = alCambiar(-1)
	end)
	Comic.boton(der or "+", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y), Size = UDim2.fromOffset(34, 28), TextSize = 14, BackgroundColor3 = Comic.GRIS }, padre, function()
		valor.Text = alCambiar(1)
	end)
	return valor
end

-- Lista con buscador: elementos { id, texto, color }; alElegir(id).
local function lista(padre: Instance, y: number, alto: number, elementos, alElegir): (TextBox, () -> ())
	local buscar = crear("TextBox", { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 28), PlaceholderText = "Buscar…", Text = "", ClearTextOnFocus = false, Font = Comic.TEXTO, TextSize = 14, TextColor3 = Comic.CREMA, PlaceholderColor3 = Comic.TENUE, BackgroundColor3 = Comic.ROJO_OSCURO, TextXAlignment = Enum.TextXAlignment.Left }, padre)
	crear("UICorner", { CornerRadius = UDim.new(0, 8) }, buscar)
	crear("UIPadding", { PaddingLeft = UDim.new(0, 10) }, buscar)
	local caja = crear("ScrollingFrame", { Position = UDim2.fromOffset(0, y + 34), Size = UDim2.new(1, 0, 0, alto), BackgroundColor3 = Comic.ROJO_OSCURO, BackgroundTransparency = 0.3, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), BorderSizePixel = 0 }, padre)
	crear("UICorner", { CornerRadius = UDim.new(0, 8) }, caja)
	crear("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, caja)
	local filas = {}
	local elegido = nil
	for i, el in elementos do
		local b = crear("TextButton", { Text = "  " .. el.texto, Size = UDim2.new(1, -8, 0, 24), LayoutOrder = i, BackgroundColor3 = Comic.FONDO, BackgroundTransparency = 1, AutoButtonColor = false, Font = Comic.TEXTO, TextSize = 13, TextColor3 = el.color or Comic.CREMA, TextXAlignment = Enum.TextXAlignment.Left }, caja)
		b:SetAttribute("Busca", string.lower(el.texto))
		b.Activated:Connect(function()
			if elegido then
				elegido.BackgroundTransparency = 1
			end
			elegido = b
			b.BackgroundTransparency = 0
			alElegir(el.id)
		end)
		filas[el.id] = b
	end
	buscar:GetPropertyChangedSignal("Text"):Connect(function()
		local q = string.lower(buscar.Text)
		for _, b in filas do
			b.Visible = q == "" or string.find(b:GetAttribute("Busca"), q, 1, true) ~= nil
		end
	end)
	return buscar, function()
		if elegido then
			elegido.BackgroundTransparency = 1
			elegido = nil
		end
	end
end

--------------------------------------------------------------------------------
-- HÉROES
--------------------------------------------------------------------------------
local paginaHeroes = pestana("HÉROES", 1)
local ORDEN_RAREZA = {}
for i, r in Personajes.RAREZAS do
	ORDEN_RAREZA[r] = i
end
local heroes = {}
for id, h in Personajes.todos do
	table.insert(heroes, { id = id, texto = `{h.name} · {Personajes.NOMBRE_RAREZA[h.rarity] or h.rarity}`, color = Comic.RAREZA[h.rarity], orden = ORDEN_RAREZA[h.rarity] or 0, nombre = h.name })
end
table.sort(heroes, function(a, b)
	if a.orden ~= b.orden then
		return a.orden > b.orden
	end
	return a.nombre < b.nombre
end)
local RASGOS = { "" }
for _, r in Rasgos.LISTA do
	table.insert(RASGOS, r.id)
end
local GRADOS = {}
for _, g in Rasgos.GRADOS do
	table.insert(GRADOS, g.id)
end
local OBJETOS = { "" }
for id in items do
	table.insert(OBJETOS, id)
end
table.sort(OBJETOS, function(a, b)
	return (items[a] and items[a].price or 0) < (items[b] and items[b].price or 0)
end)

-- Configuración de cada casilla (lo último que se aplicó o se está armando).
local casilla = 1
local configs = {}
local function cfg()
	configs[casilla] = configs[casilla] or { heroId = nil, nivel = 1, mejora = 0, rasgo = "", grados = { dano = "B", alcance = "B", cadencia = "B" }, objeto = "", shiny = false }
	return configs[casilla]
end

local filaCasillas = crear("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, paginaHeroes)
crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, filaCasillas)
local botonesCasilla = {}
local refrescarFormulario -- más abajo
for i = 1, Entrenamiento.CASILLAS do
	botonesCasilla[i] = Comic.boton(tostring(i), { Size = UDim2.fromOffset(56, 30), TextSize = 12, BackgroundColor3 = if i == 1 then Comic.ROJO else Comic.GRIS }, filaCasillas, function()
		casilla = i
		for k, b in botonesCasilla do
			b.BackgroundColor3 = if k == i then Comic.ROJO else Comic.GRIS
		end
		refrescarFormulario()
	end)
end
-- Las casillas muestran el héroe que tienen (atributo Escuadron del jugador).
local function nombresCasillas()
	local ocupadas = {}
	for _, parte in string.split(jugador:GetAttribute("Escuadron") or "", ",") do
		local p = string.split(parte, ":")
		local n, id = tonumber(p[1]), p[2]
		if n and id and Personajes.todos[id] then
			ocupadas[n] = Personajes.todos[id].name
			-- Sin configuración propia, o si la casilla cambió de héroe: arranca con lo que trae el escuadrón.
			if not configs[n] or configs[n].heroId ~= id then
				configs[n] = { heroId = id, nivel = tonumber(p[3]) or 1, mejora = 0, rasgo = "", grados = { dano = "B", alcance = "B", cadencia = "B" }, objeto = "", shiny = p[5] == "1" }
			end
		end
	end
	for i, b in botonesCasilla do
		b.Text = if ocupadas[i] then `{i}·{string.sub(ocupadas[i], 1, 5)}` else `{i}·+`
	end
end
jugador:GetAttributeChangedSignal("Escuadron"):Connect(function()
	nombresCasillas()
	if refrescarFormulario then
		refrescarFormulario()
	end
end)

local elegidoTxt = texto({ Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 20), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, paginaHeroes)
local _, soltarHeroe = lista(paginaHeroes, 58, 96, heroes, function(id)
	cfg().heroId = id
	refrescarFormulario()
end)

local Y = 196
local valores = {}
local NIVELES = { 1 }
for n = 5, Unidades.NIVEL_MAXIMO, 5 do
	table.insert(NIVELES, n)
end
valores.nivel = fila(paginaHeroes, Y, "Nivel", function(d)
	local c = cfg()
	-- De a 5 (1, 5, 10… 50); un nivel intermedio salta al paso más cercano.
	local i = 1
	for k, n in NIVELES do
		if n <= c.nivel then
			i = k
		end
	end
	c.nivel = NIVELES[math.clamp(i + d, 1, #NIVELES)]
	return tostring(c.nivel)
end)
valores.mejora = fila(paginaHeroes, Y + 30, "Mejora", function(d)
	local c = cfg()
	c.mejora = math.clamp(c.mejora + d, 0, Mejoras.MAXIMO)
	return `{c.mejora} / {Mejoras.MAXIMO}`
end)
local function ciclo(listaValores, actual, d)
	local i = table.find(listaValores, actual) or 1
	return listaValores[(i - 1 + d) % #listaValores + 1]
end
valores.rasgo = fila(paginaHeroes, Y + 60, "Rasgo", function(d)
	local c = cfg()
	c.rasgo = ciclo(RASGOS, c.rasgo, d)
	local r = Rasgos.de(c.rasgo)
	return if r then r.nombre else "Ninguno"
end, "◀", "▶")
for k, stat in Rasgos.STATS do
	local nombre = ({ dano = "Grado daño", alcance = "Grado alcance", cadencia = "Grado cadencia" })[stat]
	valores[stat] = fila(paginaHeroes, Y + 60 + k * 30, nombre, function(d)
		local c = cfg()
		c.grados[stat] = ciclo(GRADOS, c.grados[stat], d)
		return c.grados[stat]
	end, "◀", "▶")
end
valores.objeto = fila(paginaHeroes, Y + 180, "Objeto", function(d)
	local c = cfg()
	c.objeto = ciclo(OBJETOS, c.objeto, d)
	return if items[c.objeto] then Comic.mayus(string.lower(items[c.objeto].name)) else "Ninguno"
end, "◀", "▶")
valores.objeto.TextSize = 11
valores.objeto.TextWrapped = true
local botonShiny = Comic.boton("SHINY: NO", { Position = UDim2.fromOffset(0, Y + 214), Size = UDim2.new(0.5, -4, 0, 34), TextSize = 14, BackgroundColor3 = Comic.GRIS }, paginaHeroes, function()
	cfg().shiny = not cfg().shiny
	refrescarFormulario()
end)
Comic.boton("APLICAR", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, Y + 214), Size = UDim2.new(0.5, -4, 0, 34), TextSize = 15, BackgroundColor3 = Comic.VERDE }, paginaHeroes, function()
	local c = cfg()
	if not c.heroId then
		mensaje.Text = "Elegí un héroe de la lista"
		return
	end
	local datos = { heroId = c.heroId, nivel = c.nivel, mejora = c.mejora, rasgo = if c.rasgo ~= "" then c.rasgo else nil, grados = c.grados, objeto = if c.objeto ~= "" then c.objeto else nil, shiny = c.shiny }
	if pedir("configurar", casilla, datos) then
		mensaje.Text = `Casilla {casilla}: {Personajes.todos[c.heroId].name}. Colocalo desde la barra de abajo.`
	end
end)

function refrescarFormulario()
	local c = cfg()
	local h = c.heroId and Personajes.todos[c.heroId]
	elegidoTxt.Text = if h then `Casilla {casilla}: {h.name}` else `Casilla {casilla}: elegí un héroe`
	elegidoTxt.TextColor3 = if h then (Comic.RAREZA[h.rarity] or Comic.CREMA) else Comic.TENUE
	soltarHeroe()
	valores.nivel.Text = tostring(c.nivel)
	valores.mejora.Text = `{c.mejora} / {Mejoras.MAXIMO}`
	local r = Rasgos.de(c.rasgo)
	valores.rasgo.Text = if r then r.nombre else "Ninguno"
	for _, stat in Rasgos.STATS do
		valores[stat].Text = c.grados[stat]
	end
	valores.objeto.Text = if items[c.objeto] then Comic.mayus(string.lower(items[c.objeto].name)) else "Ninguno"
	botonShiny.Text = if c.shiny then "SHINY: SÍ" else "SHINY: NO"
	botonShiny.BackgroundColor3 = if c.shiny then Comic.DORADO_SHINY else Comic.GRIS
end

--------------------------------------------------------------------------------
-- ENEMIGOS
--------------------------------------------------------------------------------
local paginaEnemigos = pestana("ENEMIGOS", 2)
local listaEnemigos = {}
for id, e in enemigosDatos.normal do
	table.insert(listaEnemigos, { id = id, texto = `{e.name} · {e.hp} de vida`, nombre = e.name, jefe = false })
end
for id, e in enemigosDatos.bosses do
	table.insert(listaEnemigos, { id = id, texto = `★ {e.name} (jefe) · {e.hp}`, nombre = e.name, jefe = true, color = Comic.AMARILLO })
end
table.sort(listaEnemigos, function(a, b)
	if a.jefe ~= b.jefe then
		return not a.jefe
	end
	return a.nombre < b.nombre
end)
local tanda = { id = nil, cantidad = 5, intervalo = 1, vida = 0, velocidad = 1 }
local elegidoEnemigo = texto({ Text = "Elegí un enemigo", Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 20), TextSize = 14, TextColor3 = Comic.TENUE, TextXAlignment = Enum.TextXAlignment.Left }, paginaEnemigos)
lista(paginaEnemigos, 24, 150, listaEnemigos, function(id)
	tanda.id = id
	local e = enemigosDatos.normal[id] or enemigosDatos.bosses[id]
	elegidoEnemigo.Text = e.name
	elegidoEnemigo.TextColor3 = Comic.CREMA
end)
local VIDAS = { 0, 100, 500, 1000, 5000, 10000, 50000, 100000, 1000000 } -- 0: la suya
local VELOCIDADES = { 0, 0.25, 0.5, 1, 1.5, 2, 3 }
local YE = 218
fila(paginaEnemigos, YE, "Cantidad", function(d)
	tanda.cantidad = math.clamp(tanda.cantidad + d * (if tanda.cantidad >= 10 then 5 else 1), 1, Entrenamiento.MAX_ENEMIGOS)
	return tostring(tanda.cantidad)
end)
fila(paginaEnemigos, YE + 32, "Cada (s)", function(d)
	tanda.intervalo = math.clamp(math.floor((tanda.intervalo + d * 0.2) * 10 + 0.5) / 10, 0.2, 10)
	return string.gsub(string.format("%.1f s", tanda.intervalo), "%.", ",")
end)
fila(paginaEnemigos, YE + 64, "Vida", function(d)
	tanda.vida = ciclo(VIDAS, tanda.vida, d)
	return if tanda.vida == 0 then "La suya" else tostring(tanda.vida)
end, "◀", "▶")
fila(paginaEnemigos, YE + 96, "Velocidad", function(d)
	tanda.velocidad = ciclo(VELOCIDADES, tanda.velocidad, d)
	return if tanda.velocidad == 0 then "Quietos" else `×{tanda.velocidad}`
end, "◀", "▶")
Comic.boton("SOLTAR", { Position = UDim2.fromOffset(0, YE + 136), Size = UDim2.new(0.5, -4, 0, 38), TextSize = 16, BackgroundColor3 = Comic.ROJO }, paginaEnemigos, function()
	if not tanda.id then
		mensaje.Text = "Elegí un enemigo de la lista"
		return
	end
	pedir("enemigos", { id = tanda.id, cantidad = tanda.cantidad, intervalo = tanda.intervalo, vida = if tanda.vida > 0 then tanda.vida else nil, velocidad = tanda.velocidad })
end)
Comic.boton("LIMPIAR", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, YE + 136), Size = UDim2.new(0.5, -4, 0, 38), TextSize = 16, BackgroundColor3 = Comic.GRIS }, paginaEnemigos, function()
	pedir("limpiar")
end)
local botonInmortal = Comic.boton("BASE INMORTAL: SÍ", { Position = UDim2.fromOffset(0, YE + 180), Size = UDim2.new(1, 0, 0, 34), TextSize = 14, BackgroundColor3 = Comic.VERDE }, paginaEnemigos, function()
	pedir("inmortal")
end)

--------------------------------------------------------------------------------
-- DATOS
--------------------------------------------------------------------------------
local paginaDatos = pestana("DATOS", 3)
local tiempoTxt = texto({ Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -110, 0, 26), TextSize = 13, Font = Comic.TEXTO, TextColor3 = Comic.TENUE, TextXAlignment = Enum.TextXAlignment.Left }, paginaDatos)
Comic.boton("REINICIAR", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(104, 26), TextSize = 12, BackgroundColor3 = Comic.GRIS }, paginaDatos, function()
	pedir("reiniciarStats")
end)
local tabla = crear("ScrollingFrame", { Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 236), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), BorderSizePixel = 0 }, paginaDatos)
crear("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabla)
-- Enemigo tocado: detalle del golpe.
local detalle = crear("Frame", { Position = UDim2.fromOffset(0, 276), Size = UDim2.new(1, 0, 1, -276), BackgroundColor3 = Comic.ROJO_OSCURO }, paginaDatos)
crear("UICorner", { CornerRadius = UDim.new(0, 8) }, detalle)
local detalleTxt = texto({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 1, -12), TextSize = 12, Font = Comic.TEXTO, TextWrapped = true, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "Tocá un enemigo para ver su vida, armadura, resistencias y el último golpe." }, detalle)
local enemigoVisto: BasePart? = nil

local filasDatos = {}
local function miles(n: number): string
	local s = tostring(math.floor(n))
	local r = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (r:gsub("^%.", ""))
end
local function refrescarDatos()
	local segundos = math.max(estado:GetAttribute("EstSegundos") or 0, 0.1)
	tiempoTxt.Text = `Midiendo hace {math.floor(segundos)} s de juego`
	local vistos = {}
	for _, m in carpeta.Unidades:GetChildren() do
		if m:GetAttribute("Dueno") ~= jugador.UserId or m:GetAttribute("Vendida") then
			continue
		end
		local uid = m:GetAttribute("Uid")
		vistos[uid] = true
		local f = filasDatos[uid]
		if not f then
			f = crear("Frame", { Size = UDim2.new(1, -8, 0, 104), BackgroundColor3 = Comic.ROJO_OSCURO, LayoutOrder = uid }, tabla)
			crear("UICorner", { CornerRadius = UDim.new(0, 8) }, f)
			texto({ Name = "Titulo", Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 18), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, f)
			texto({ Name = "Cifras", Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -20, 0, 16), TextSize = 12, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, f)
			texto({ Name = "Desglose", Position = UDim2.fromOffset(10, 40), Size = UDim2.new(1, -20, 0, 60), TextSize = 10, Font = Comic.TEXTO, TextColor3 = Comic.TENUE, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, f)
			filasDatos[uid] = f
		end
		local h = Personajes.todos[m:GetAttribute("Heroe")]
		local dano, golpes, criticos = m:GetAttribute("EstDano") or 0, m:GetAttribute("EstGolpes") or 0, m:GetAttribute("EstCriticos") or 0
		f.Titulo.Text = `{h and h.name or "?"} · Nv {m:GetAttribute("NivelUnidad") or 1} · Mejora {m:GetAttribute("Mejora") or 0}`
		f.Titulo.TextColor3 = h and Comic.RAREZA[h.rarity] or Comic.CREMA
		local estados = m:GetAttribute("EstEstados") or ""
		f.Cifras.Text = `Daño {miles(dano)} · DPS {miles(dano / segundos)} · {golpes} golpes · {if golpes > 0 then math.floor(criticos / golpes * 100 + 0.5) else 0}% crít.` .. (if estados ~= "" then ` · {estados}` else "")
		f.Desglose.Text = m:GetAttribute("Desglose") or ""
	end
	for uid, f in filasDatos do
		if not vistos[uid] then
			f:Destroy()
			filasDatos[uid] = nil
		end
	end
	if enemigoVisto then
		local e = enemigoVisto
		if not e.Parent or e:GetAttribute("Muerto") then
			detalleTxt.Text = "El enemigo elegido ya no está. Tocá otro."
			enemigoVisto = nil
		else
			detalleTxt.Text = table.concat({
				`<b>{e:GetAttribute("Nombre") or e.Name}</b> · {e:GetAttribute("Categoria") or ""}`,
				`Vida {miles(e:GetAttribute("Vida") or 0)} / {miles(e:GetAttribute("VidaMax") or 0)} · Armadura {e:GetAttribute("Armadura") or 0}%`,
				`Resistencias: {if (e:GetAttribute("Resistencias") or "") ~= "" then e:GetAttribute("Resistencias") else "ninguna"}`,
				`Estados: {e:GetAttribute("Estados") or "ninguno"}`,
				`Último golpe: {e:GetAttribute("UltimoGolpe") or "—"}`,
			}, "\n")
		end
	end
end

-- Tocar un enemigo en el mapa lo elige para el detalle.
UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado or not gui.Enabled or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	-- Los enemigos no reciben rayos (CanQuery apagado): se elige el más cercano al puntero en pantalla.
	local inset = game:GetService("GuiService"):GetGuiInset()
	local raton = Vector2.new(input.Position.X, input.Position.Y + inset.Y)
	local cuerpo, mejor = nil, 50 -- píxeles
	for _, e in carpeta.Enemigos:GetChildren() do
		if e:IsA("BasePart") and not e:GetAttribute("Muerto") then
			local p, enPantalla = camara:WorldToViewportPoint(e.Position)
			local d = (Vector2.new(p.X, p.Y) - raton).Magnitude
			if enPantalla and d < mejor then
				cuerpo, mejor = e, d
			end
		end
	end
	if cuerpo then
		enemigoVisto = cuerpo
		for n, p in paginas do
			p.Visible = n == "DATOS"
			botonesPestana[n].BackgroundColor3 = if n == "DATOS" then Comic.ROJO else Comic.GRIS
		end
		refrescarDatos()
	end
end)

--------------------------------------------------------------------------------
-- Cámara sobre una unidad y ocultar la interfaz
--------------------------------------------------------------------------------
local orbitando: Model? = nil
local angulo = 0
function siguienteCamara()
	local propias = {}
	for _, m in carpeta.Unidades:GetChildren() do
		if m:GetAttribute("Dueno") == jugador.UserId and not m:GetAttribute("Vendida") then
			table.insert(propias, m)
		end
	end
	table.sort(propias, function(a, b)
		return (a:GetAttribute("Uid") or 0) < (b:GetAttribute("Uid") or 0)
	end)
	local i = orbitando and table.find(propias, orbitando)
	orbitando = propias[(i or 0) + 1]
	if orbitando then
		camara.CameraType = Enum.CameraType.Scriptable
		local h = Personajes.todos[orbitando:GetAttribute("Heroe")]
		botonCamara.Text = `CÁM: {string.sub(h and h.name or "?", 1, 8)}`
	else
		camara.CameraType = Enum.CameraType.Custom
		botonCamara.Text = "CÁMARA"
	end
end
RunService.RenderStepped:Connect(function(dt)
	if not orbitando then
		return
	end
	if not orbitando.Parent then
		orbitando = nil
		camara.CameraType = Enum.CameraType.Custom
		botonCamara.Text = "CÁMARA"
		return
	end
	angulo += dt * 0.35
	local cf, tam = orbitando:GetBoundingBox()
	local foco = cf.Position + Vector3.new(0, tam.Y * 0.1, 0)
	local d = math.max(tam.Y, 3) * 2.2
	camara.CFrame = CFrame.lookAt(foco + Vector3.new(math.cos(angulo) * d, tam.Y * 0.45, math.sin(angulo) * d), foco)
end)

local ocultos = nil -- ScreenGuis que estaban visibles antes de ocultar
function alternarInterfaz()
	local pg = jugador.PlayerGui
	if ocultos then
		for _, g in ocultos do
			g.Enabled = true
		end
		ocultos = nil
		return
	end
	ocultos = {}
	for _, g in pg:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then
			table.insert(ocultos, g)
			g.Enabled = false
		end
	end
end
UserInputService.InputBegan:Connect(function(input, procesado)
	if not procesado and input.KeyCode == Enum.KeyCode.H and (gui.Enabled or ocultos) then
		alternarInterfaz()
	end
end)

--------------------------------------------------------------------------------
-- Entrar y salir del entrenamiento
--------------------------------------------------------------------------------
local conexion = nil
local function cambiar()
	if conexion then
		conexion:Disconnect()
		conexion = nil
	end
	if ocultos then
		alternarInterfaz()
	end
	orbitando = nil
	if camara.CameraType == Enum.CameraType.Scriptable and botonCamara.Text ~= "CÁMARA" then
		camara.CameraType = Enum.CameraType.Custom
	end
	botonCamara.Text = "CÁMARA"
	local id = jugador:GetAttribute("Partida")
	estado = id and ReplicatedStorage:WaitForChild("Partidas"):WaitForChild(id, 20)
	carpeta = id and workspace:WaitForChild("Partidas"):WaitForChild("Partida_" .. id, 20)
	local activo = estado ~= nil and carpeta ~= nil and estado:GetAttribute("Acto") == "Entrenamiento"
	gui.Enabled = activo
	if not activo then
		return
	end
	table.clear(configs)
	nombresCasillas()
	refrescarFormulario()
	local acumulado = 0
	conexion = RunService.Heartbeat:Connect(function(dt)
		acumulado += dt
		if acumulado < 0.5 then
			return
		end
		acumulado = 0
		botonVelocidad.Text = `×{string.gsub(tostring(estado:GetAttribute("Velocidad") or 1), "%.", ",")}`
		local inmortal = estado:GetAttribute("BaseInmortal")
		botonInmortal.Text = if inmortal then "BASE INMORTAL: SÍ" else "BASE INMORTAL: NO"
		botonInmortal.BackgroundColor3 = if inmortal then Comic.VERDE else Comic.GRIS
		if paginas.DATOS.Visible then
			refrescarDatos()
		end
	end)
end
jugador:GetAttributeChangedSignal("Partida"):Connect(cambiar)
cambiar()
