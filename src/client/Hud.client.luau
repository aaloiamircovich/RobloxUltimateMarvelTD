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
local Recompensas = require(Shared.Recompensas)
local coleccion = ReplicatedStorage:WaitForChild("Coleccion")
local usarHud = ReplicatedStorage:WaitForChild("UsarHud")
local teletransportar = ReplicatedStorage:WaitForChild("Teletransportar")
local temporadaRemota = ReplicatedStorage:WaitForChild("Temporada")
local eventoRemoto = ReplicatedStorage:WaitForChild("Evento")
local raidRemoto = ReplicatedStorage:WaitForChild("Raid")
local salaRemota = ReplicatedStorage:WaitForChild("Sala")
local rasgosRemoto = ReplicatedStorage:WaitForChild("Rasgos")
local mascotasRemoto = ReplicatedStorage:WaitForChild("Mascotas")
local estiloRemoto = ReplicatedStorage:WaitForChild("Estilo")
local bannersRemoto = ReplicatedStorage:WaitForChild("Banners")
local Mascotas = require(Shared.Mascotas)
local Rasgos = require(Shared.Rasgos)
local abrirPanelRemoto = ReplicatedStorage:WaitForChild("AbrirPanel")
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
	for _, m in { { "HISTORIA", "story", Comic.ROJO }, { "INFINITO", "infinite", Color3.fromRGB(90, 60, 190) }, { "RAIDS", "raids", Color3.fromRGB(150, 30, 90) } } do
		local b = Comic.boton(m[1], { Name = "Modo_" .. m[2], Size = UDim2.fromOffset(150, 170), BackgroundColor3 = m[3], TextSize = 34 }, cuerpo, function()
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
	elseif pr.tipo == "fichas" then
		return `🎫\n{pr.cantidad} ficha{if pr.cantidad > 1 then "s" else ""} de rasgo`
	elseif pr.tipo == "cristales" then
		return `💠\n{pr.cantidad} cristales`
	end
	return if pr.id and Personajes.todos[pr.id] then `★ {Personajes.todos[pr.id].name}\nExclusivo` else "★ ???\nPersonaje exclusivo"
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

-- Raids (docs/RAIDS.md): jefe de la semana, llaves, fragmentos, sala cooperativa y misiones de raid.
local cuerpoRaid
local pestanaRaid = "raid"
local armarRaid
do
	local p, cuerpo = Comic.panel(gui, "RAIDS", UDim2.fromOffset(820, 480))
	paneles.raid = p
	cuerpoRaid = cuerpo
end
local function pedirRaid(remoto: RemoteFunction, nombre: string, a)
	local res = remoto:InvokeServer(nombre, a)
	if res.empezo then
		paneles.raid.Visible = false
		return
	end
	local estado = raidRemoto:InvokeServer("estado")
	local sala = if remoto == salaRemota then res else salaRemota:InvokeServer("estado")
	estado.error = res.error
	armarRaid(estado, sala)
end

function armarRaid(res, sala)
	cuerpoRaid:ClearAllChildren()
	for i, t in { { "raid", "RAID" }, { "misiones", "MISIONES DE RAID" } } do
		Comic.boton(t[2], { Position = UDim2.fromOffset((i - 1) * 150, 0), Size = UDim2.fromOffset(if i == 1 then 140 else 220, 40), TextSize = 22, BackgroundColor3 = if pestanaRaid == t[1] then Comic.AMARILLO else Comic.ROJO_OSCURO, TextColor3 = if pestanaRaid == t[1] then Comic.ROJO_OSCURO else Comic.CREMA }, cuerpoRaid, function()
			pestanaRaid = t[1]
			armarRaid(res, sala)
		end)
	end
	Comic.texto({ Text = `🔸 {res.fichasRaid}   🔑 {res.llaves}/{res.llavesDia} llaves  ·  se renuevan en {duracion(res.finDia)}`, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 6), Size = UDim2.fromOffset(380, 30), TextSize = 22, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Right }, cuerpoRaid)
	local area = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 1, -80), BackgroundTransparency = 1 }, cuerpoRaid)
	Comic.texto({ Text = res.error or "", Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 22), TextSize = 16, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO }, cuerpoRaid)

	-- Fragmentos para el personaje exclusivo de raid (todavía no existe).
	local function fragmentos(y: number)
		local nombre = if res.exclusiva then Personajes.todos[res.exclusiva].name else "próximamente"
		barra(area, UDim2.fromOffset(0, y), UDim2.new(1, -170, 0, 28), math.min(1, res.fragmentos / res.fragmentosUnidad), Color3.fromRGB(255, 120, 40), `FRAGMENTOS {res.fragmentos} / {res.fragmentosUnidad}  ·  personaje de raid: {nombre}`)
		local puede = res.exclusiva and res.fragmentos >= res.fragmentosUnidad
		Comic.boton(`CANJEAR {string.upper(nombre)}`, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y - 6), Size = UDim2.fromOffset(160, 40), TextSize = 18, BackgroundColor3 = if puede then Comic.VERDE else Comic.GRIS }, area, function()
			if puede then
				pedirRaid(raidRemoto, "canjear")
			end
		end)
	end

	if pestanaRaid == "raid" then
		-- Izquierda: jefe y premios.
		local jefe = Comic.crear("Frame", { Size = UDim2.fromOffset(380, 250), BackgroundColor3 = Comic.ROJO, Rotation = -1.5 }, area)
		Comic.borde(jefe, 5)
		Comic.texto({ Text = "JEFE DE LA SEMANA", Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 26), TextSize = 22, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, jefe)
		Comic.texto({ Text = string.upper(res.nombreJefe), Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 60), TextSize = 50, TextXAlignment = Enum.TextXAlignment.Left }, jefe)
		Comic.texto({
			Text = `En {res.nombreMapa}. 5 oleadas de esbirros y después el jefe, que al 66 % y al 33 % de vida llama refuerzos y se enfurece.\nVictoria: 💎 {res.premio.gemas} · 🔷 {res.premio.nucleos} · 🔸 {res.premio.fichasRaid} fichas de raid · {res.premio.fragmentos} fragmentos y chance de objeto Legendario o Mítico.`,
			Position = UDim2.fromOffset(12, 100),
			Size = UDim2.new(1, -24, 0, 140),
			TextSize = 17,
			Font = Comic.TEXTO,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, jefe)
		fragmentos(276)
		-- Derecha: sala (hasta 4) o salas abiertas para unirse.
		local der = Comic.crear("Frame", { Position = UDim2.fromOffset(404, 0), Size = UDim2.fromOffset(376, 260), BackgroundColor3 = Comic.ROJO_OSCURO }, area)
		Comic.borde(der, 4)
		local miSala = sala.sala
		if miSala and miSala.acto == "raid" then
			Comic.texto({ Text = `SALA DE {string.upper(miSala.anfitrion)}  ({#miSala.miembros}/4)`, Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 28), TextSize = 24, TextColor3 = Comic.AMARILLO }, der)
			local nombres = {}
			for _, m in miSala.miembros do
				table.insert(nombres, (if m.anfitrion then "★ " else "• ") .. m.nombre)
			end
			Comic.texto({ Text = table.concat(nombres, "\n"), Position = UDim2.fromOffset(16, 44), Size = UDim2.new(1, -32, 0, 120), TextSize = 20, Font = Comic.TEXTO, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, der)
			if miSala.anfitrion == jugador.DisplayName then
				Comic.boton("¡INICIAR RAID!", { Position = UDim2.new(0, 10, 1, -62), Size = UDim2.new(0.6, -15, 0, 52), TextSize = 26, BackgroundColor3 = Comic.VERDE }, der, function()
					pedirRaid(salaRemota, "iniciar")
				end)
			else
				Comic.texto({ Text = "Esperando al anfitrión…", Position = UDim2.new(0, 10, 1, -62), Size = UDim2.new(0.6, -15, 0, 52), TextSize = 18, Font = Comic.TEXTO }, der)
			end
			Comic.boton("SALIR", { Position = UDim2.new(0.6, 5, 1, -62), Size = UDim2.new(0.4, -15, 0, 52), TextSize = 24, BackgroundColor3 = Comic.GRIS }, der, function()
				pedirRaid(salaRemota, "salir")
			end)
		else
			Comic.boton("CREAR SALA", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(0.5, -15, 0, 52), TextSize = 24, BackgroundColor3 = Comic.VERDE }, der, function()
				pedirRaid(salaRemota, "crear", { acto = "raid", mapa = res.mapa })
			end)
			Comic.boton("JUGAR SOLO", { Position = UDim2.new(0.5, 5, 0, 10), Size = UDim2.new(0.5, -15, 0, 52), TextSize = 24, BackgroundColor3 = Color3.fromRGB(200, 130, 20) }, der, function()
				pedirRaid(salaRemota, "crear", { acto = "raid", mapa = res.mapa, solo = true })
			end)
			Comic.texto({ Text = "SALAS ABIERTAS", Position = UDim2.fromOffset(10, 72), Size = UDim2.new(1, -20, 0, 24), TextSize = 20, TextColor3 = Comic.AMARILLO }, der)
			local n = 0
			for _, s in sala.abiertas or {} do
				if s.acto == "raid" and n < 3 then
					n += 1
					Comic.boton(`UNIRSE: {s.anfitrion} ({#s.miembros}/4)`, { Position = UDim2.fromOffset(10, 100 + (n - 1) * 50), Size = UDim2.new(1, -20, 0, 42), TextSize = 20 }, der, function()
						pedirRaid(salaRemota, "unirse", s.id)
					end)
				end
			end
			if n == 0 then
				Comic.texto({ Text = "No hay salas de raid abiertas", Position = UDim2.fromOffset(10, 110), Size = UDim2.new(1, -20, 0, 24), TextSize = 16, Font = Comic.TEXTO }, der)
			end
		end
	else
		Comic.texto({ Text = `MISIONES SEMANALES  ·  se renuevan en {duracion(res.finSemana)}`, Size = UDim2.new(1, 0, 0, 30), TextSize = 26, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, area)
		for i, m in res.misiones do
			local f = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 40 + (i - 1) * 72), Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = Comic.ROJO_OSCURO }, area)
			Comic.borde(f, 3)
			Comic.texto({ Text = m.texto, Position = UDim2.fromOffset(10, 4), Size = UDim2.fromOffset(330, 26), TextSize = 19, Font = Comic.TEXTO, TextXAlignment = Enum.TextXAlignment.Left }, f)
			barra(f, UDim2.fromOffset(10, 34), UDim2.fromOffset(330, 22), m.progreso / m.meta, Comic.AMARILLO, `{m.progreso} / {m.meta}`)
			Comic.texto({ Text = `💎 {res.premioMision.gemas} · 🔸 {res.premioMision.fichasRaid} · {res.premioMision.fragmentos} frag.`, Position = UDim2.fromOffset(356, 18), Size = UDim2.fromOffset(220, 30), TextSize = 20 }, f)
			local puede = m.progreso >= m.meta and not m.reclamada
			Comic.boton(if m.reclamada then "✔ LISTA" elseif puede then "¡RECLAMAR!" else "EN CURSO", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(150, 42), TextSize = 20, AutoButtonColor = puede, BackgroundColor3 = if puede then Comic.VERDE else Comic.GRIS }, f, function()
				if puede then
					pedirRaid(raidRemoto, "reclamar", m.id)
				end
			end)
		end
		fragmentos(270)
	end
end

local function abrirRaid(pestana: string)
	pestanaRaid = pestana
	pedirRaid(raidRemoto, "estado")
	if not paneles.raid.Visible then
		abrir("raid")
	end
end
-- Mientras el panel está abierto, refresca la sala (alguien se une o se va).
task.spawn(function()
	while true do
		task.wait(2)
		if paneles.raid.Visible and pestanaRaid == "raid" then
			pedirRaid(raidRemoto, "estado")
		end
	end
end)

-- Rasgos y grados (docs/RASGOS.md): elegir una unidad, tirar su rasgo con fichas y sus grados con cristales.
local COLOR_RASGO = { ["Común"] = Color3.fromRGB(190, 190, 200), Raro = Color3.fromRGB(80, 160, 255), ["Épico"] = Color3.fromRGB(180, 100, 255), ["Mítico"] = Color3.fromRGB(255, 90, 110) }
local COLOR_GRADO = { C = Color3.fromRGB(150, 150, 150), B = Color3.fromRGB(230, 230, 230), A = Color3.fromRGB(80, 200, 255), S = Color3.fromRGB(255, 200, 40), ["S+"] = Color3.fromRGB(255, 90, 110) }
local NOMBRE_STAT = { dano = "DAÑO", alcance = "ALCANCE", cadencia = "CADENCIA" }
local cuerpoRasgos
local elegidaRasgo -- uid
local bloqueos = {}
local armarRasgos
do
	local p, cuerpo = Comic.panel(gui, "RASGOS Y GRADOS", UDim2.fromOffset(860, 500))
	paneles.rasgos = p
	cuerpoRasgos = cuerpo
end
local function pedirRasgos(nombre: string, uid: number?)
	armarRasgos(rasgosRemoto:InvokeServer(nombre, uid, bloqueos))
end

function armarRasgos(res)
	cuerpoRasgos:ClearAllChildren()
	if res.error and not res.unidades then
		Comic.texto({ Text = res.error, Size = UDim2.fromScale(1, 1), TextSize = 22, Font = Comic.TEXTO }, cuerpoRasgos)
		return
	end
	Comic.texto({ Text = `🎫 {res.fichas} fichas de rasgo   💠 {res.cristales} cristales   ·   mítico garantizado en {res.garantia - res.pity} tiradas`, Size = UDim2.new(1, 0, 0, 28), TextSize = 22, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, cuerpoRasgos)
	Comic.texto({ Text = res.error or "", Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 22), TextSize = 16, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO }, cuerpoRasgos)

	-- Izquierda: unidades.
	local lista = Comic.crear("ScrollingFrame", { Position = UDim2.fromOffset(0, 36), Size = UDim2.fromOffset(300, 380), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, cuerpoRasgos)
	Comic.crear("UIListLayout", { Padding = UDim.new(0, 6) }, lista)
	local sel
	for _, u in res.unidades do
		if u.uid == elegidaRasgo then
			sel = u
		end
	end
	sel = sel or res.unidades[1]
	elegidaRasgo = sel and sel.uid
	for _, u in res.unidades do
		local h = Personajes.todos[u.heroId]
		local r = Rasgos.de(u.rasgo)
		local b = Comic.boton(`{h.name} · Nv {u.nivel}\n{if r then r.nombre else "Sin rasgo"} · {u.grados.dano}/{u.grados.alcance}/{u.grados.cadencia}`, { Size = UDim2.new(1, -10, 0, 54), TextSize = 17, BackgroundColor3 = if u == sel then Comic.AMARILLO else Comic.ROJO_OSCURO, TextColor3 = if u == sel then Comic.ROJO_OSCURO else Comic.CREMA }, lista, function()
			elegidaRasgo = u.uid
			bloqueos = {}
			armarRasgos(res)
		end)
		b:FindFirstChildOfClass("UIStroke").Color = COLOR_RAREZA[h.rarity] or Comic.NEGRO
	end
	if not sel then
		return
	end

	-- Derecha: rasgo y grados de la unidad elegida.
	local der = Comic.crear("Frame", { Position = UDim2.fromOffset(316, 36), Size = UDim2.fromOffset(504, 380), BackgroundTransparency = 1 }, cuerpoRasgos)
	local r = Rasgos.de(sel.rasgo)
	local caja = Comic.crear("Frame", { Size = UDim2.fromOffset(504, 150), BackgroundColor3 = Comic.ROJO, Rotation = -1 }, der)
	Comic.borde(caja, 4)
	Comic.texto({ Text = "RASGO", Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(200, 24), TextSize = 22, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, caja)
	Comic.texto({ Text = if r then `{string.upper(r.nombre)} · {r.rareza}` else "SIN RASGO", Position = UDim2.fromOffset(12, 32), Size = UDim2.fromOffset(300, 40), TextSize = 36, TextColor3 = if r then COLOR_RASGO[r.rareza] else Comic.CREMA, TextXAlignment = Enum.TextXAlignment.Left }, caja)
	Comic.texto({ Text = Rasgos.descripcion(sel.rasgo), Position = UDim2.fromOffset(12, 78), Size = UDim2.fromOffset(300, 60), TextSize = 17, Font = Comic.TEXTO, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, caja)
	Comic.boton("TIRAR RASGO\n🎫 1", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(170, 84), TextSize = 24, BackgroundColor3 = if res.fichas > 0 then Comic.VERDE else Comic.GRIS }, caja, function()
		if Rasgos.rango(sel.rasgo) >= 3 then
			-- Confirmar antes de perder un rasgo Épico o Mítico.
			local aviso = Comic.crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Comic.NEGRO, BackgroundTransparency = 0.3, ZIndex = 5 }, cuerpoRasgos)
			Comic.texto({ Text = `¿Seguro? Vas a perder {r.nombre} ({r.rareza}).`, Position = UDim2.fromScale(0, 0.3), Size = UDim2.new(1, 0, 0, 40), TextSize = 30, ZIndex = 6 }, aviso)
			Comic.boton("SÍ, TIRAR", { Position = UDim2.new(0.5, -210, 0.5, 0), Size = UDim2.fromOffset(200, 56), TextSize = 26, BackgroundColor3 = Comic.VERDE, ZIndex = 6 }, aviso, function()
				pedirRasgos("rasgo", sel.uid)
			end)
			Comic.boton("NO", { Position = UDim2.new(0.5, 10, 0.5, 0), Size = UDim2.fromOffset(200, 56), TextSize = 26, BackgroundColor3 = Comic.GRIS, ZIndex = 6 }, aviso, function()
				aviso:Destroy()
			end)
		else
			pedirRasgos("rasgo", sel.uid)
		end
	end)

	Comic.texto({ Text = "GRADOS  ·  bloqueá hasta 2 (cada bloqueo duplica el costo)", Position = UDim2.fromOffset(0, 166), Size = UDim2.fromOffset(504, 24), TextSize = 20, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, der)
	local n = 0
	for i, s in Rasgos.STATS do
		if bloqueos[s] then
			n += 1
		end
		local f = Comic.crear("Frame", { Position = UDim2.fromOffset((i - 1) * 170, 196), Size = UDim2.fromOffset(160, 110), BackgroundColor3 = Comic.ROJO_OSCURO }, der)
		Comic.borde(f, 3)
		Comic.texto({ Text = NOMBRE_STAT[s], Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 22), TextSize = 20 }, f)
		Comic.texto({ Text = sel.grados[s], Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 44), TextSize = 44, TextColor3 = COLOR_GRADO[sel.grados[s]] }, f)
		Comic.boton(if bloqueos[s] then "🔒 BLOQUEADO" else "🔓 bloquear", { Position = UDim2.new(0, 8, 1, -34), Size = UDim2.new(1, -16, 0, 28), TextSize = 15, BackgroundColor3 = if bloqueos[s] then Color3.fromRGB(200, 130, 20) else Comic.GRIS }, f, function()
			bloqueos[s] = not bloqueos[s] or nil
			armarRasgos(res)
		end)
	end
	local costo = Rasgos.costoGrados(n)
	Comic.boton(if n > 2 then "MÁXIMO 2 BLOQUEOS" else `TIRAR GRADOS  💠 {costo}`, { Position = UDim2.fromOffset(0, 318), Size = UDim2.fromOffset(500, 56), TextSize = 28, BackgroundColor3 = if n <= 2 and res.cristales >= costo then Comic.VERDE else Comic.GRIS }, der, function()
		if n <= 2 then
			pedirRasgos("grados", sel.uid)
		end
	end)
end

local function abrirRasgos()
	pedirRasgos("estado")
	if not paneles.rasgos.Visible then
		abrir("rasgos")
	end
end

-- Mascotas (docs/MASCOTAS.md): abrir huevos, equipar hasta 3 y fusionar 3 copias en una dorada.
local COLOR_MASCOTA = { ["Común"] = Color3.fromRGB(190, 190, 200), Raro = Color3.fromRGB(80, 160, 255), ["Épico"] = Color3.fromRGB(180, 100, 255), Legendario = Color3.fromRGB(255, 190, 60), ["Mítico"] = Color3.fromRGB(255, 90, 110) }
local cuerpoMascotas
local elegidaMascota
local armarMascotas
do
	local p, cuerpo = Comic.panel(gui, "MASCOTAS", UDim2.fromOffset(880, 500))
	paneles.mascotas = p
	cuerpoMascotas = cuerpo
end
local function pedirMascotas(nombre: string, a)
	armarMascotas(mascotasRemoto:InvokeServer(nombre, a))
end

function armarMascotas(res)
	cuerpoMascotas:ClearAllChildren()
	if not res.lista then
		Comic.texto({ Text = res.error or "", Size = UDim2.fromScale(1, 1), TextSize = 22, Font = Comic.TEXTO }, cuerpoMascotas)
		return
	end
	local b = res.bonos
	Comic.texto({ Text = `💎 {res.gemas}   ·   bonos equipados: +{math.floor(b.dinero * 100 + 0.5)}% dinero · +{math.floor(b.xp * 100 + 0.5)}% XP · +{math.floor(b.gemas * 100 + 0.5)}% gemas · +{math.floor(b.dano * 100 + 0.5)}% daño`, Size = UDim2.new(1, 0, 0, 26), TextSize = 20, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, cuerpoMascotas)
	local nuevaTxt = ""
	if res.nueva then
		local d = Mascotas.de(res.nueva.id)
		nuevaTxt = `¡{if res.nueva.dorada then "Dorada: " else ""}{d.nombre} ({d.rareza})!`
	end
	Comic.texto({ Text = res.error or nuevaTxt, Position = UDim2.new(0, 0, 1, -26), Size = UDim2.new(1, 0, 0, 24), TextSize = if res.error then 16 else 24, Font = if res.error then Comic.TEXTO else Comic.TITULO, TextColor3 = Comic.AMARILLO }, cuerpoMascotas)

	-- Izquierda: huevos.
	for i, h in res.huevos do
		local f = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 36 + (i - 1) * 196), Size = UDim2.fromOffset(220, 184), BackgroundColor3 = if h.id == "cosmico" then Color3.fromRGB(70, 30, 120) else Comic.ROJO, Rotation = if i == 1 then -1.5 else 1.5 }, cuerpoMascotas)
		Comic.borde(f, 4)
		Comic.texto({ Text = `🥚 {string.upper(h.nombre)}`, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 32), TextSize = 26, TextColor3 = Comic.AMARILLO }, f)
		local probs = {}
		for _, r in Mascotas.RAREZAS do
			if (h.prob[r] or 0) > 0 then
				table.insert(probs, `{r} {h.prob[r]}%`)
			end
		end
		Comic.texto({ Text = table.concat(probs, " · "), Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 0, 70), TextSize = 15, Font = Comic.TEXTO, TextWrapped = true }, f)
		Comic.boton(`ABRIR  💎 {h.precio}`, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, -20, 0, 50), TextSize = 26, BackgroundColor3 = if res.gemas >= h.precio then Comic.VERDE else Comic.GRIS }, f, function()
			pedirMascotas("abrir", h.id)
		end)
	end

	-- Derecha: inventario y acciones.
	local der = Comic.crear("Frame", { Position = UDim2.fromOffset(240, 36), Size = UDim2.fromOffset(600, 400), BackgroundTransparency = 1 }, cuerpoMascotas)
	local grilla = Comic.crear("ScrollingFrame", { Size = UDim2.fromOffset(600, 300), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, der)
	Comic.crear("UIGridLayout", { CellSize = UDim2.fromOffset(110, 92), CellPadding = UDim2.fromOffset(8, 8) }, grilla)
	local sel
	for _, x in res.lista do
		if x.uid == elegidaMascota then
			sel = x
		end
	end
	sel = sel or res.lista[1]
	elegidaMascota = sel and sel.uid
	for _, x in res.lista do
		local d = Mascotas.de(x.id)
		local equipada = table.find(res.equipadas, x.uid) ~= nil
		local boton = Comic.boton(`{if x.dorada then "★ " else ""}{d.nombre}{if equipada then "\n[EQUIPADA]" else ""}`, { TextSize = 15, BackgroundColor3 = if x == sel then Comic.AMARILLO elseif equipada then Color3.fromRGB(40, 110, 50) else Comic.ROJO_OSCURO, TextColor3 = if x == sel then Comic.ROJO_OSCURO else Comic.CREMA }, grilla, function()
			elegidaMascota = x.uid
			armarMascotas(res)
		end)
		local borde = boton:FindFirstChildOfClass("UIStroke")
		borde.Color = if x.dorada then Color3.fromRGB(255, 200, 40) else COLOR_MASCOTA[d.rareza]
		borde.Thickness = if x.dorada then 5 else 3
	end
	if #res.lista == 0 then
		Comic.texto({ Text = "Todavía no tenés mascotas: abrí un huevo", Size = UDim2.fromOffset(600, 40), TextSize = 20, Font = Comic.TEXTO }, der)
	end
	if not sel then
		return
	end
	local d = Mascotas.de(sel.id)
	local equipada = table.find(res.equipadas, sel.uid) ~= nil
	local copias = 0
	for _, x in res.lista do
		if x.id == sel.id and not x.dorada then
			copias += 1
		end
	end
	Comic.texto({ Text = `{if sel.dorada then "★ DORADA · " else ""}{string.upper(d.nombre)} · {d.rareza}\n{Mascotas.descripcion(sel.id, sel.dorada)}`, Position = UDim2.fromOffset(0, 306), Size = UDim2.fromOffset(300, 56), TextSize = 20, TextColor3 = COLOR_MASCOTA[d.rareza], TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, der)
	Comic.boton(if equipada then "DESEQUIPAR" else `EQUIPAR ({#res.equipadas}/{Mascotas.MAX_EQUIPADAS})`, { Position = UDim2.fromOffset(310, 308), Size = UDim2.fromOffset(140, 50), TextSize = 20, BackgroundColor3 = if equipada then Comic.GRIS else Comic.VERDE }, der, function()
		pedirMascotas("equipar", sel.uid)
	end)
	local puedeFusionar = not sel.dorada and copias >= Mascotas.COPIAS_FUSION
	Comic.boton(if sel.dorada then "YA ES DORADA" else `FUSIONAR ({copias}/{Mascotas.COPIAS_FUSION})`, { Position = UDim2.fromOffset(460, 308), Size = UDim2.fromOffset(140, 50), TextSize = 20, BackgroundColor3 = if puedeFusionar then Color3.fromRGB(200, 150, 20) else Comic.GRIS }, der, function()
		if puedeFusionar then
			pedirMascotas("fusionar", sel.uid)
		end
	end)
end

local function abrirMascotas()
	pedirMascotas("estado")
	if not paneles.mascotas.Visible then
		abrir("mascotas")
	end
end

-- Monturas y bailes (docs/ESTILO.md): comprar con gemas, equipar montura y armar la rueda de bailes.
local cuerpoEstilo
local pestanaEstilo = "monturas"
local armarEstilo
do
	local p, cuerpo = Comic.panel(gui, "MONTURAS Y BAILES", UDim2.fromOffset(860, 460))
	paneles.estilo = p
	cuerpoEstilo = cuerpo
end
local function pedirEstilo(nombre: string, a)
	armarEstilo(estiloRemoto:InvokeServer(nombre, a))
end

function armarEstilo(res)
	cuerpoEstilo:ClearAllChildren()
	if not res.estilo then
		Comic.texto({ Text = res.error or "", Size = UDim2.fromScale(1, 1), TextSize = 22, Font = Comic.TEXTO }, cuerpoEstilo)
		return
	end
	for i, t in { { "monturas", "MONTURAS" }, { "bailes", "BAILES" } } do
		Comic.boton(t[2], { Position = UDim2.fromOffset((i - 1) * 150, 0), Size = UDim2.fromOffset(140, 40), TextSize = 22, BackgroundColor3 = if pestanaEstilo == t[1] then Comic.AMARILLO else Comic.ROJO_OSCURO, TextColor3 = if pestanaEstilo == t[1] then Comic.ROJO_OSCURO else Comic.CREMA }, cuerpoEstilo, function()
			pestanaEstilo = t[1]
			armarEstilo(res)
		end)
	end
	Comic.texto({ Text = `💎 {res.gemas}   ·   G: montar   ·   B: rueda de bailes`, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 6), Size = UDim2.fromOffset(460, 30), TextSize = 22, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Right }, cuerpoEstilo)
	Comic.texto({ Text = res.error or "", Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 22), TextSize = 16, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO }, cuerpoEstilo)
	local area = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 1, -84), BackgroundTransparency = 1 }, cuerpoEstilo)
	Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center }, area)
	local e = res.estilo
	local lista = if pestanaEstilo == "monturas" then res.monturas else res.bailes
	local ancho = if pestanaEstilo == "monturas" then 150 else 124
	for _, x in lista do
		local tiene = table.find(if pestanaEstilo == "monturas" then e.monturas else e.bailes, x.id) ~= nil
		local activo = if pestanaEstilo == "monturas" then e.montura == x.id else table.find(e.rueda, x.id) ~= nil
		local f = Comic.crear("Frame", { Size = UDim2.fromOffset(ancho, 300), BackgroundColor3 = if activo then Color3.fromRGB(40, 110, 50) else Comic.ROJO_OSCURO }, area)
		Comic.borde(f, 4)
		Comic.texto({ Text = string.upper(x.nombre), Position = UDim2.fromOffset(6, 12), Size = UDim2.new(1, -12, 0, 70), TextSize = 24, TextWrapped = true, TextColor3 = Comic.AMARILLO }, f)
		Comic.texto({ Text = if x.velocidad then `Velocidad ×{x.velocidad}` else (if activo then "En la rueda" else ""), Position = UDim2.fromOffset(6, 100), Size = UDim2.new(1, -12, 0, 40), TextSize = 18, Font = Comic.TEXTO, TextWrapped = true }, f)
		local txt, color
		if not tiene then
			txt, color = if x.precio == 0 then "GRATIS" else `💎 {x.precio}`, if res.gemas >= x.precio then Comic.VERDE else Comic.GRIS
		elseif pestanaEstilo == "monturas" then
			txt, color = if activo then "EQUIPADA" else "EQUIPAR", if activo then Comic.GRIS else Comic.VERDE
		else
			txt, color = if activo then "SACAR" else "A LA RUEDA", if activo then Comic.GRIS else Comic.VERDE
		end
		Comic.boton(txt, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -16, 0, 50), TextSize = 22, BackgroundColor3 = color }, f, function()
			if pestanaEstilo == "monturas" then
				if not activo then
					pedirEstilo("montura", x.id)
				end
			else
				pedirEstilo("baile", x.id)
			end
		end)
	end
end

local function abrirEstilo(pestana: string?)
	pestanaEstilo = if pestana == "bailes" then "bailes" else "monturas"
	pedirEstilo("estado")
	if not paneles.estilo.Visible then
		abrir("estilo")
	end
end

-- Banner 2 (docs/INVOCACIONES.md): Mítico destacado que cambia cada 3 horas, con fichas de raid y garantía.
local NOMBRE_RAREZA_B = { Common = "Común", Rare = "Raro", Epic = "Épico", Legendary = "Legendario", Mythic = "Mítico", Secret = "Secreto" }
local cuerpoBanners
local armarBanners
do
	local p, cuerpo = Comic.panel(gui, "BANNER 2", UDim2.fromOffset(840, 460))
	paneles.banners = p
	cuerpoBanners = cuerpo
end
local function pedirBanner(nombre: string, cantidad: number?)
	armarBanners(bannersRemoto:InvokeServer(nombre, cantidad))
end

function armarBanners(res)
	cuerpoBanners:ClearAllChildren()
	if not res.destacado then
		Comic.texto({ Text = res.error or "", Size = UDim2.fromScale(1, 1), TextSize = 22, Font = Comic.TEXTO }, cuerpoBanners)
		return
	end
	Comic.texto({ Text = `🔸 {res.fichasRaid} fichas de raid (se ganan en las raids)`, Size = UDim2.new(1, 0, 0, 30), TextSize = 24, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, cuerpoBanners)
	Comic.texto({ Text = res.error or "", Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 22), TextSize = 16, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO }, cuerpoBanners)

	local caja = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 40), Size = UDim2.fromOffset(420, 330), BackgroundColor3 = Color3.fromRGB(110, 20, 60), Rotation = -1 }, cuerpoBanners)
	Comic.borde(caja, 5)
	local lineas = {}
	for _, r in { "Common", "Rare", "Epic", "Legendary", "Mythic" } do
		if res.prob[r] and res.prob[r] > 0 then
			table.insert(lineas, `{NOMBRE_RAREZA_B[r]} {res.prob[r]}%`)
		end
	end
	local h = Personajes.todos[res.destacado]
	Comic.texto({ Text = "MÍTICO DESTACADO", Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 26), TextSize = 22, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, caja)
	Comic.texto({ Text = string.upper(h.name), Position = UDim2.fromOffset(14, 38), Size = UDim2.new(1, -28, 0, 56), TextSize = 50, TextColor3 = COLOR_RAREZA.Mythic, TextXAlignment = Enum.TextXAlignment.Left }, caja)
	Comic.texto({
		Text = `Cambia en {duracion(res.cambiaEn)} (cada 3 horas).\n{table.concat(lineas, " · ")}\n{h.name}: {math.floor(res.prob.Mythic * res.parteDestacado * 10 + 0.5) / 10}% por tirada.`,
		Position = UDim2.fromOffset(14, 100),
		Size = UDim2.new(1, -28, 0, 100),
		TextSize = 17,
		Font = Comic.TEXTO,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, caja)
	barra(caja, UDim2.fromOffset(14, 210), UDim2.new(1, -28, 0, 30), res.pity / res.garantia, COLOR_RAREZA.Mythic, `GARANTÍA  {res.pity} / {res.garantia}`)
	for i, n in { 1, 10 } do
		Comic.boton(`x{n}  🔸 {res.costo * n}`, { Position = UDim2.new(0, 14 + (i - 1) * 200, 1, -66), Size = UDim2.fromOffset(186, 54), TextSize = 26, BackgroundColor3 = if res.fichasRaid >= res.costo * n then Comic.VERDE else Comic.GRIS }, caja, function()
			pedirBanner("limitado", n)
		end)
	end

	-- Derecha: lo que salió en la última tirada.
	local der = Comic.crear("Frame", { Position = UDim2.fromOffset(440, 40), Size = UDim2.fromOffset(360, 330), BackgroundColor3 = Comic.ROJO_OSCURO }, cuerpoBanners)
	Comic.borde(der, 4)
	Comic.texto({ Text = "ÚLTIMA TIRADA", Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 28), TextSize = 24, TextColor3 = Comic.AMARILLO }, der)
	local lista = Comic.crear("Frame", { Position = UDim2.fromOffset(10, 44), Size = UDim2.new(1, -20, 1, -54), BackgroundTransparency = 1 }, der)
	Comic.crear("UIGridLayout", { CellSize = UDim2.fromOffset(165, 50), CellPadding = UDim2.fromOffset(10, 6) }, lista)
	for _, u in res.nuevas or {} do
		local hu = Personajes.todos[u.heroId]
		local t = Comic.texto({ Text = `{hu.name}\n{NOMBRE_RAREZA_B[hu.rarity] or hu.rarity}`, TextSize = 16, Font = Comic.TEXTO, TextColor3 = COLOR_RAREZA[hu.rarity] or Comic.CREMA }, lista)
		t.BackgroundTransparency = 0
		t.BackgroundColor3 = Comic.FONDO
		Comic.borde(t, 2)
	end
	if not res.nuevas then
		Comic.texto({ Text = "Tirá para ver qué sale", Position = UDim2.fromOffset(10, 140), Size = UDim2.new(1, -20, 0, 30), TextSize = 18, Font = Comic.TEXTO }, der)
	end
end

local function abrirBanners()
	pedirBanner("estado")
	if not paneles.banners.Visible then
		abrir("banners")
	end
end

-- Desafío semanal, tienda de fichas y rankings (docs/EVENTO.md).
local cuerpoEvento
local pestanaEvento = "desafio"
local armarEvento
do
	local p, cuerpo = Comic.panel(gui, "EVENTO", UDim2.fromOffset(820, 480))
	paneles.evento = p
	cuerpoEvento = cuerpo
end
local function pedirEvento(nombre: string, a)
	local res = eventoRemoto:InvokeServer(nombre, a)
	if res.empezo then
		paneles.evento.Visible = false
		return
	end
	armarEvento(res)
end

function armarEvento(res)
	cuerpoEvento:ClearAllChildren()
	-- Pestañas.
	for i, t in { { "desafio", "DESAFÍO" }, { "tienda", "TIENDA" }, { "ranking", "RANKING" } } do
		Comic.boton(t[2], { Position = UDim2.fromOffset((i - 1) * 150, 0), Size = UDim2.fromOffset(140, 40), TextSize = 22, BackgroundColor3 = if pestanaEvento == t[1] then Comic.AMARILLO else Comic.ROJO_OSCURO, TextColor3 = if pestanaEvento == t[1] then Comic.ROJO_OSCURO else Comic.CREMA }, cuerpoEvento, function()
			pestanaEvento = t[1]
			armarEvento(res)
		end)
	end
	Comic.texto({ Text = `🎟 {res.fichas} fichas  ·  termina en {duracion(res.fin)}`, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 6), Size = UDim2.fromOffset(300, 30), TextSize = 22, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Right }, cuerpoEvento)
	local area = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 1, -80), BackgroundTransparency = 1 }, cuerpoEvento)
	Comic.texto({ Text = res.error or "", Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 22), TextSize = 16, Font = Comic.TEXTO, TextColor3 = Comic.AMARILLO }, cuerpoEvento)

	if pestanaEvento == "desafio" then
		Comic.texto({ Text = `DESAFÍO SEMANAL · {string.upper(res.nombreMapa)}`, Size = UDim2.new(1, 0, 0, 40), TextSize = 34, TextXAlignment = Enum.TextXAlignment.Left }, area)
		for i, m in res.modificadores do
			local f = Comic.crear("Frame", { Position = UDim2.fromOffset((i - 1) * 390, 52), Size = UDim2.fromOffset(370, 96), BackgroundColor3 = Comic.ROJO, Rotation = if i == 1 then -1.5 else 1.5 }, area)
			Comic.borde(f, 4)
			Comic.texto({ Text = string.upper(m.nombre), Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 36), TextSize = 30, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, f)
			Comic.texto({ Text = m.texto, Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 40), TextSize = 18, Font = Comic.TEXTO, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }, f)
		end
		Comic.texto({
			Text = `Sobreviví hasta {res.oleadas} oleadas. 100 puntos por oleada + 1 por enemigo; vale tu mejor intento.\n1 ficha cada 100 puntos (hasta {res.topeFichas} por semana: llevás {res.ganadas}).`,
			Position = UDim2.fromOffset(0, 162),
			Size = UDim2.new(1, 0, 0, 60),
			TextSize = 18,
			Font = Comic.TEXTO,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, area)
		Comic.texto({ Text = `TU MEJOR PUNTAJE: {res.mejor}`, Position = UDim2.fromOffset(0, 236), Size = UDim2.fromOffset(420, 44), TextSize = 34, TextColor3 = Comic.AMARILLO, TextXAlignment = Enum.TextXAlignment.Left }, area)
		Comic.boton("¡JUGAR DESAFÍO!", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 230), Size = UDim2.fromOffset(300, 70), TextSize = 34, BackgroundColor3 = Comic.VERDE }, area, function()
			pedirEvento("jugar")
		end)
	elseif pestanaEvento == "tienda" then
		Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center }, area)
		for _, prod in res.tienda do
			local f = Comic.crear("Frame", { Size = UDim2.fromOffset(118, 290), BackgroundColor3 = Comic.ROJO_OSCURO }, area)
			Comic.borde(f, 4)
			Comic.texto({ Text = prod.nombre, Position = UDim2.fromOffset(6, 14), Size = UDim2.new(1, -12, 0, 90), TextSize = 22, TextWrapped = true, TextColor3 = Comic.AMARILLO }, f)
			Comic.texto({ Text = `Quedan {prod.quedan} esta semana`, Position = UDim2.fromOffset(8, 120), Size = UDim2.new(1, -16, 0, 40), TextSize = 16, Font = Comic.TEXTO, TextWrapped = true }, f)
			local puede = prod.quedan > 0 and res.fichas >= prod.precio
			Comic.boton(if prod.quedan > 0 then `🎟 {prod.precio}` else "AGOTADO", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -16, 0, 50), TextSize = 22, AutoButtonColor = puede, BackgroundColor3 = if puede then Comic.VERDE else Comic.GRIS }, f, function()
				if puede then
					pedirEvento("comprar", prod.id)
				end
			end)
		end
	else
		for i, t in { { "evento", "DESAFÍO SEMANAL", " pts" }, { "infinito", "INFINITO", " oleadas" }, { "nivel", "NIVEL DE CUENTA", "" } } do
			local f = Comic.crear("Frame", { Position = UDim2.fromOffset((i - 1) * 262, 0), Size = UDim2.fromOffset(248, 360), BackgroundColor3 = Comic.ROJO_OSCURO }, area)
			Comic.borde(f, 4)
			Comic.texto({ Text = t[2], Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 34), TextSize = 26, TextColor3 = Comic.AMARILLO }, f)
			local lineas = {}
			for n, fila in res.ranking[t[1]] do
				table.insert(lineas, `{n}. {fila.nombre} · {fila.valor}{t[3]}`)
			end
			Comic.texto({ Text = if #lineas > 0 then table.concat(lineas, "\n") else "Todavía nadie", Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 1, -100), TextSize = 17, Font = Comic.TEXTO, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true }, f)
			Comic.texto({ Text = `VOS: {res.mios[t[1]]}{t[3]}`, Position = UDim2.new(0, 8, 1, -44), Size = UDim2.new(1, -16, 0, 36), TextSize = 24 }, f)
		end
	end
end

local function abrirEvento(pestana: string)
	pestanaEvento = pestana
	pedirEvento("estado")
	abrir("evento")
end
abrirPanelRemoto.OnClientEvent:Connect(function(nombre, datos)
	if nombre == "evento" or nombre == "ranking" then
		abrirEvento(if nombre == "ranking" then "ranking" else "desafio")
	elseif nombre == "banners" then
		abrirBanners()
	elseif nombre == "estilo" then
		abrirEstilo(datos and datos.pestana)
	elseif nombre == "mascotas" then
		abrirMascotas()
	elseif nombre == "rasgos" then
		abrirRasgos()
	elseif nombre == "raid" then
		abrirRaid(if datos and datos.pestana == "misiones" then "misiones" else "raid")
	elseif nombre == "misiones" then
		pedirTemporada("estado")
		abrir("misiones")
	end
end)

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
-- Disposición «barras compactas» (docs/INTERFAZ.md): columnas de íconos a los costados, monedas y nivel arriba,
-- escuadrón abajo y ¡JUGAR! abajo a la derecha. Diseñado para 1280×720; cada bloque se escala con la pantalla.
--------------------------------------------------------------------------------
local LADO = 84
local escalar = Comic.escalar

local grilla = Comic.crear("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(LADO, 6 * LADO + 5 * 8), BackgroundTransparency = 1 }, gui)
Comic.crear("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grilla)
escalar(grilla)
local BOTONES_IZQ = {
	{ "TIENDA", "tienda", function()
		abrir("tienda")
	end },
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
}
for i, b in BOTONES_IZQ do
	local boton = Comic.botonIcono(b[1], Iconos[b[2]], { LayoutOrder = i, Size = UDim2.fromOffset(LADO, LADO), BackgroundColor3 = if b[2] == "tienda" then Comic.VERDE else Comic.ROJO }, grilla, b[3])
	boton.Name = b[2]
end

-- ¡JUGAR!: el botón principal, grande y abajo a la derecha.
local jugar = Comic.botonIcono("¡JUGAR!", Iconos.jugar, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(190, 120), BackgroundColor3 = Color3.fromRGB(230, 150, 20) }, gui, function()
	abrir("jugar")
end)
jugar.Name = "jugar"
-- En ventanas angostas el escuadrón llega a la esquina: ahí ¡JUGAR! sube por encima de él.
escalar(jugar, function(s)
	local v = workspace.CurrentCamera.ViewportSize
	local anchoEscuadron = (6 * 92 + 5 * 8) * s
	local choca = v.X / 2 + anchoEscuadron / 2 > v.X - 16 - 190 * s
	jugar.Position = UDim2.new(1, -16, 1, if choca then -(16 + (92 + 12) * s) else -16)
end)

local derecha = Comic.crear("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, -40), Size = UDim2.fromOffset(LADO, 6 * LADO + 5 * 8), BackgroundTransparency = 1 }, gui)
Comic.crear("UIListLayout", { Padding = UDim.new(0, 8) }, derecha)
escalar(derecha)
for _, b in {
	{ "VIAJAR", "teleport", function()
		abrir("teleport")
	end },
	{ "PERFIL", "perfil", function()
		abrir("perfil")
	end },
	{ "EVENTO", "evento", function()
		abrirEvento("desafio")
	end },
	{ "NOVEDADES", "log", function()
		abrir("log")
	end },
} do
	Comic.botonIcono(b[1], Iconos[b[2]], { Size = UDim2.fromOffset(LADO, LADO) }, derecha, b[3])
end

--------------------------------------------------------------------------------
-- Ajustes (docs/TUTORIAL.md): volumen, calidad baja, números de daño y auto-saltar; se guardan en el perfil.
--------------------------------------------------------------------------------
do
	local Ajustes = require(script.Parent:WaitForChild("Ajustes"))
	local p, cuerpo = Comic.panel(gui, "AJUSTES", UDim2.fromOffset(460, 330))
	paneles.ajustes = p
	Comic.crear("UIListLayout", { Padding = UDim.new(0, 10) }, cuerpo)
	local filas = {}
	local function fila(titulo: string)
		local f = Comic.crear("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Comic.ROJO_OSCURO }, cuerpo)
		Comic.borde(f, 2)
		Comic.texto({ Text = titulo, Font = Comic.TEXTO, TextSize = 18, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.55, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left }, f)
		return f
	end
	local function volumen(clave: string, titulo: string)
		local f = fila(titulo)
		local valor = Comic.texto({ TextSize = 22, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0.5, 0), Size = UDim2.fromOffset(70, 30) }, f)
		Comic.boton("−", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -132, 0.5, 0), Size = UDim2.fromOffset(38, 34), TextSize = 26 }, f, function()
			Ajustes.fijar(clave, Ajustes.valores[clave] - 0.1)
		end)
		Comic.boton("+", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(38, 34), TextSize = 26 }, f, function()
			Ajustes.fijar(clave, Ajustes.valores[clave] + 0.1)
		end)
		table.insert(filas, function(v)
			valor.Text = `{math.floor(v[clave] * 100 + 0.5)}%`
		end)
	end
	local function interruptor(clave: string, titulo: string)
		local f = fila(titulo)
		local b = Comic.boton("", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 34), TextSize = 20 }, f, function()
			Ajustes.fijar(clave, not Ajustes.valores[clave])
		end)
		table.insert(filas, function(v)
			b.Text = if v[clave] then "SÍ" else "NO"
			b.BackgroundColor3 = if v[clave] then Comic.VERDE else Comic.GRIS
		end)
	end
	volumen("musica", "🎵 Volumen de la música")
	volumen("efectos", "🔊 Volumen de los efectos")
	interruptor("calidadBaja", "🖥 Calidad baja (más FPS)")
	interruptor("numerosDano", "💥 Números de daño")
	interruptor("autoSaltar", "⏩ Juego automático al empezar")
	local function pintar(v)
		for _, f in filas do
			f(v)
		end
	end
	Ajustes.cambio:Connect(pintar)
	pintar(Ajustes.valores)
end
--------------------------------------------------------------------------------
-- Premios (docs/RECOMPENSAS.md): racha diaria, logros y códigos.
--------------------------------------------------------------------------------
local abrirPremios
do
	local recompensasRemoto = ReplicatedStorage:WaitForChild("Recompensas")
	local p, cuerpo = Comic.panel(gui, "PREMIOS", UDim2.fromOffset(820, 470))
	paneles.premios = p
	local pestana = "diario"
	local ultimo
	local mensaje = Comic.texto({ Font = Comic.TEXTO, TextSize = 18, TextColor3 = Comic.AMARILLO, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 24) }, cuerpo)
	local area = Comic.crear("Frame", { Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 1, -82), BackgroundTransparency = 1 }, cuerpo)
	local armar
	local function pedir(nombre: string, a)
		local res = recompensasRemoto:InvokeServer(nombre, a)
		ultimo = res
		mensaje.Text = res.error or (if res.premio then `¡Recibiste {res.premio}!` else "")
		armar()
	end
	local botonesPestana = {}
	for i, t in { { "diario", "DIARIO" }, { "logros", "LOGROS" }, { "codigos", "CÓDIGOS" } } do
		botonesPestana[t[1]] = Comic.boton(t[2], { Position = UDim2.fromOffset((i - 1) * 170, 0), Size = UDim2.fromOffset(160, 40), TextSize = 22 }, cuerpo, function()
			pestana = t[1]
			mensaje.Text = ""
			armar()
		end)
	end
	local cajaCodigo
	function armar()
		for k, b in botonesPestana do
			b.BackgroundColor3 = if k == pestana then Comic.AMARILLO else Comic.ROJO_OSCURO
			b.TextColor3 = if k == pestana then Comic.ROJO_OSCURO else Comic.CREMA
		end
		area:ClearAllChildren()
		local res = ultimo
		if not res or not res.diario then
			return
		end
		if pestana == "diario" then
			local d = res.diario
			Comic.texto({ Text = if d.reclamado then `Volvé mañana · próximo premio en {duracion(d.finDia - os.time())}` else `¡Tu premio del día {d.dia} está listo!`, TextSize = 24, TextColor3 = Comic.AMARILLO, Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left }, area)
			for i, premio in res.premiosDiarios do
				local hoy = i == d.dia
				local hecho = i < d.dia or (hoy and d.reclamado)
				local f = Comic.crear("Frame", { Position = UDim2.fromOffset((i - 1) * 112, 44), Size = UDim2.fromOffset(104, 170), BackgroundColor3 = if hoy then Comic.ROJO elseif hecho then Comic.GRIS else Comic.ROJO_OSCURO, Rotation = if hoy then -2 else 0 }, area)
				Comic.borde(f, if hoy then 4 else 2)
				Comic.texto({ Text = `DÍA {i}`, TextSize = 22, TextColor3 = Comic.AMARILLO, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 26) }, f)
				Comic.texto({ Text = string.gsub(Recompensas.texto(premio), " %+ ", "\n"), Font = Comic.TEXTO, TextSize = 17, TextWrapped = true, Position = UDim2.fromOffset(4, 40), Size = UDim2.new(1, -8, 0, 90) }, f)
				if hecho then
					Comic.texto({ Text = "✔", TextSize = 30, TextColor3 = Comic.VERDE, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.fromOffset(40, 34) }, f)
				end
			end
			if not d.reclamado then
				Comic.boton("¡RECLAMAR!", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 232), Size = UDim2.fromOffset(260, 56), TextSize = 30, BackgroundColor3 = Comic.VERDE }, area, function()
					pedir("diario")
				end)
			end
			Comic.texto({ Text = "Si faltás un día, la racha vuelve al día 1. Se renueva a las 00:00 UTC.", Font = Comic.TEXTO, TextSize = 15, Position = UDim2.fromOffset(0, 300), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left }, area)
		elseif pestana == "logros" then
			local lista = Comic.crear("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, area)
			Comic.crear("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, lista)
			for i, l in res.logros do
				local listo = l.progreso >= l.meta
				local f = Comic.crear("Frame", { LayoutOrder = (if l.reclamado then 1000 elseif listo then 0 else 500) + i, Size = UDim2.new(1, -14, 0, 56), BackgroundColor3 = if l.reclamado then Comic.GRIS else Comic.ROJO_OSCURO }, lista)
				Comic.borde(f, 2)
				Comic.texto({ Text = `{l.categoria} · {l.nombre}`, Font = Comic.TEXTO, TextSize = 18, Position = UDim2.fromOffset(10, 4), Size = UDim2.new(0.55, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Left }, f)
				Comic.texto({ Text = Recompensas.texto(l.premio), Font = Comic.TEXTO, TextSize = 15, TextColor3 = Comic.AMARILLO, Position = UDim2.fromOffset(10, 30), Size = UDim2.new(0.55, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left }, f)
				local fondo = Comic.crear("Frame", { Position = UDim2.new(0.57, 0, 0.5, -10), Size = UDim2.new(0.22, 0, 0, 20), BackgroundColor3 = Comic.FONDO }, f)
				Comic.crear("Frame", { Size = UDim2.fromScale(l.progreso / l.meta, 1), BackgroundColor3 = Comic.VERDE, BorderSizePixel = 0 }, fondo)
				Comic.texto({ Text = `{l.progreso}/{l.meta}`, TextSize = 14, Size = UDim2.fromScale(1, 1) }, fondo)
				Comic.boton(if l.reclamado then "✔" elseif listo then "RECLAMAR" else "EN CURSO", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(130, 40), TextSize = 18, AutoButtonColor = listo and not l.reclamado, BackgroundColor3 = if listo and not l.reclamado then Comic.VERDE else Comic.GRIS }, f, function()
					if listo and not l.reclamado then
						pedir("logro", l.id)
					end
				end)
			end
		else
			Comic.texto({ Text = "Escribí un código para canjear premios", TextSize = 24, TextColor3 = Comic.AMARILLO, Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left }, area)
			cajaCodigo = Comic.crear("TextBox", { Text = "", PlaceholderText = "CÓDIGO", ClearTextOnFocus = false, Font = Comic.TITULO, TextSize = 30, TextColor3 = Comic.FONDO, BackgroundColor3 = Comic.CREMA, Position = UDim2.fromOffset(0, 50), Size = UDim2.fromOffset(420, 56) }, area)
			Comic.borde(cajaCodigo, 3)
			Comic.boton("CANJEAR", { Position = UDim2.fromOffset(436, 50), Size = UDim2.fromOffset(180, 56), TextSize = 28, BackgroundColor3 = Comic.VERDE }, area, function()
				pedir("codigo", cajaCodigo.Text)
			end)
			Comic.texto({ Text = "Los códigos se anuncian en el grupo y en Novedades. Cada código se canjea una vez por cuenta.", Font = Comic.TEXTO, TextSize = 15, TextWrapped = true, Position = UDim2.fromOffset(0, 120), Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Left }, area)
		end
	end
	function abrirPremios()
		if not p.Visible then
			abrir("premios")
		end
		pedir("estado")
	end
end
local botonPremios = Comic.botonIcono("PREMIOS", "", { Size = UDim2.fromOffset(LADO, LADO), BackgroundColor3 = Color3.fromRGB(200, 130, 20) }, derecha, function()
	abrirPremios()
end)
Comic.texto({ Text = "🎁", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.new(1, -8, 0.68, 0) }, botonPremios)
-- Globo «!» cuando el premio diario está listo.
local globoPremios = Comic.crear("Frame", { BackgroundColor3 = Comic.ROJO, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(30, 30), ZIndex = 3 }, botonPremios)
Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, globoPremios)
Comic.crear("UIStroke", { Color = Comic.NEGRO, Thickness = 2 }, globoPremios)
Comic.texto({ Text = "!", TextSize = 24, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, globoPremios)
local function globo()
	globoPremios.Visible = jugador:GetAttribute("DiarioDisponible") == true
end
jugador:GetAttributeChangedSignal("DiarioDisponible"):Connect(globo)
globo()

local botonAjustes = Comic.botonIcono("AJUSTES", "", { Size = UDim2.fromOffset(LADO, LADO), BackgroundColor3 = Comic.GRIS }, derecha, function()
	abrir("ajustes")
end)
Comic.texto({ Text = "⚙", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.new(1, -8, 0.68, 0), TextColor3 = Comic.CREMA }, botonAjustes)

--------------------------------------------------------------------------------
-- Arriba: monedas y nivel de cuenta
--------------------------------------------------------------------------------
local arriba = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(540, 76), BackgroundTransparency = 1 }, gui)
escalar(arriba)
local monedas = Comic.crear("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 }, arriba)
Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center }, monedas)
local etiquetas = {}
for _, m in { { "Gemas", "💎", Color3.fromRGB(120, 60, 200) }, { "Creditos", "💰", Color3.fromRGB(190, 130, 20) }, { "Nucleos", "🔷", Color3.fromRGB(30, 110, 200) } } do
	local f = Comic.crear("Frame", { Size = UDim2.fromOffset(160, 38), BackgroundColor3 = m[3], Rotation = -2 }, monedas)
	Comic.borde(f, 3)
	etiquetas[m[1]] = Comic.texto({ Text = m[2] .. " …", Size = UDim2.new(1, -16, 1, -6), Position = UDim2.fromOffset(8, 3) }, f)
	etiquetas[m[1]]:SetAttribute("Simbolo", m[2])
end

--------------------------------------------------------------------------------
-- Abajo: escuadrón
--------------------------------------------------------------------------------
local CASILLA = 92
local abajo = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(6 * CASILLA + 5 * 8, CASILLA), BackgroundTransparency = 1 }, gui)
escalar(abajo)
local casillas = Comic.crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, abajo)
Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }, casillas)

local barraNivel = Comic.crear("Frame", { Position = UDim2.fromOffset(70, 50), Size = UDim2.new(1, -140, 0, 24), BackgroundColor3 = Comic.FONDO }, arriba)
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
		local c = Comic.crear("TextButton", { Text = "", Size = UDim2.fromOffset(CASILLA, CASILLA), BackgroundColor3 = if h then Comic.ROJO_OSCURO elseif cerrada then Color3.fromRGB(45, 45, 52) else Color3.fromRGB(70, 22, 28) }, casillas)
		Comic.borde(c, 3)
		if h then
			c:FindFirstChildOfClass("UIStroke").Color = COLOR_RAREZA[h.rarity] or Comic.NEGRO
			Comic.texto({ Text = h.name, Position = UDim2.fromOffset(5, 6), Size = UDim2.new(1, -10, 0, 32), TextWrapped = true }, c)
			Comic.texto({ Text = `Nv {u.level}`, TextColor3 = Comic.AMARILLO, Position = UDim2.fromOffset(5, 40), Size = UDim2.new(1, -10, 0, 20) }, c)
			Comic.texto({ Text = `💰 {Mejoras.costoColocar(h)}`, Font = Comic.TEXTO, TextSize = 13, Position = UDim2.fromOffset(5, 66), Size = UDim2.new(1, -10, 0, 18) }, c)
		elseif cerrada then
			Comic.texto({ Text = `🔒 Nv {Cuenta.nivelCasilla(i) or "?"}`, Size = UDim2.new(1, -10, 0, 32), Position = UDim2.new(0, 5, 0.5, -16) }, c)
		else
			Comic.texto({ Text = "+ Vacía", Size = UDim2.new(1, -10, 0, 32), Position = UDim2.new(0, 5, 0.5, -16) }, c)
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
		jugar.Visible = abajo.Visible
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
