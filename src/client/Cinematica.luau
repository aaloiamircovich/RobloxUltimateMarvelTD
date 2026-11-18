-- Cinemáticas de pantalla completa (docs/PANTALLAS.md): invocación con portal y cartas, el momento del Mítico,
-- la evolución y las tarjetas de «subió de nivel». Sólo visual; los resultados ya los decidió el servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Comic = require(script.Parent:WaitForChild("Comic"))
local Personajes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personajes"))

local Cinematica = {}
local jugador = Players.LocalPlayer
local camara = workspace.CurrentCamera

local ORDEN = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Secret = 6 }
local NOMBRE = Personajes.NOMBRE_RAREZA
local function colorDe(rareza: string): Color3
	return Comic.RAREZA[rareza] or Comic.CREMA
end

local pantalla = Comic.crear("ScreenGui", { Name = "Cinematica", ResetOnSpawn = false, DisplayOrder = 20, IgnoreGuiInset = true, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, jugador:WaitForChild("PlayerGui"))

local function tween(obj: Instance, t: number, meta, estilo: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(obj, TweenInfo.new(t, estilo or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), meta)
	tw:Play()
	return tw
end

-- Espera un clic/toque o que pasen `segundos` (lo que llegue primero). Devuelve true si fue clic.
local function esperarClic(segundos: number): boolean
	local clic = false
	local con = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.Space then
			clic = true
		end
	end)
	local fin = os.clock() + segundos
	while not clic and os.clock() < fin do
		task.wait()
	end
	con:Disconnect()
	return clic
end

-- Personaje de cuerpo entero en un ViewportFrame, con su reposo. `giro` hace orbitar la cámara.
local function modelo3D(padre: GuiObject, id: string, giro: boolean?)
	local retratos = ReplicatedStorage:FindFirstChild("Retratos")
	local plantilla = retratos and (retratos:FindFirstChild(id) or retratos:FindFirstChild(Personajes.base(id)))
	if not plantilla then
		local h = Personajes.todos[id]
		return Comic.texto({ Text = h and h.name or id, Size = UDim2.fromScale(1, 1) }, padre), nil
	end
	local vista = Comic.crear("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(210, 210, 210), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -1, -1) }, padre)
	local mundo = Comic.crear("WorldModel", {}, vista)
	local m = plantilla:Clone()
	m.Parent = mundo
	local humanoide = m:FindFirstChildOfClass("Humanoid")
	-- Algunos retratos llegan sin Animator (Nightcrawler quedaba en pose T): se crea si falta.
	local animator = humanoide and (humanoide:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoide))
	if animator then
		local Reposo = require(ReplicatedStorage.Shared.Reposo)
		local anim = Instance.new("Animation")
		anim.AnimationId = Reposo.para(id, m:GetAttribute("Efecto"))
		local ok, pista = pcall(animator.LoadAnimation, animator, anim)
		if ok then
			pista.Looped = true
			pista:Play(0)
		end
	end
	local cf, tam = m:GetBoundingBox()
	local foco = cf.Position
	local frente = m:GetPivot().LookVector
	local cam = Comic.crear("Camera", { FieldOfView = 30 }, vista)
	local distancia = tam.Y * 2.2
	cam.CFrame = CFrame.lookAt(foco + frente * distancia, foco)
	vista.CurrentCamera = cam
	if giro then
		local inicio = os.clock()
		local con
		con = RunService.RenderStepped:Connect(function()
			if not vista.Parent then
				con:Disconnect()
				return
			end
			local a = (os.clock() - inicio) * 0.9
			local dir = (CFrame.Angles(0, a, 0) * CFrame.new(frente)).Position
			cam.CFrame = CFrame.lookAt(foco + dir.Unit * distancia + Vector3.new(0, tam.Y * 0.1, 0), foco)
		end)
	end
	return vista, m
end

-- Halo de luz detrás del personaje (estilo limpio, en vez de los rayos de cómic): círculos concéntricos del color
-- dado, cada vez más tenues, que laten despacio. `cantidad` decide cuántos aros.
local function rayos(padre: GuiObject, color: Color3, cantidad: number)
	local centro = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1 }, padre)
	local aros = math.clamp(cantidad, 4, 8)
	for i = 1, aros do
		local lado = 160 + i * 90
		local aro = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(lado, lado), BackgroundColor3 = color, BackgroundTransparency = 0.78 + i * 0.025, BorderSizePixel = 0 }, centro)
		Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, aro)
	end
	local escalaHalo = Comic.crear("UIScale", {}, centro)
	local con
	con = RunService.RenderStepped:Connect(function()
		if not centro.Parent then
			con:Disconnect()
			return
		end
		local base = math.clamp(math.min(camara.ViewportSize.X / 1280, camara.ViewportSize.Y / 720), 0.5, 1.3)
		escalaHalo.Scale = base * (1 + math.sin(os.clock() * 2) * 0.04)
	end)
	return centro
end

-- Fondo de pantalla completa (se borra al terminar).
local function fondo(color: Color3, transparencia: number): Frame
	pantalla.Enabled = true
	local f = Comic.crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BackgroundTransparency = 1, BorderSizePixel = 0 }, pantalla)
	tween(f, 0.25, { BackgroundTransparency = transparencia })
	return f
end

local function destello(padre: GuiObject, color: Color3?)
	local f = Comic.crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color or Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 50 }, padre)
	tween(f, 0.5, { BackgroundTransparency = 1 })
	task.delay(0.5, f.Destroy, f)
end

local function escala(): number
	return math.clamp(math.min(camara.ViewportSize.X / 1280, camara.ViewportSize.Y / 720), 0.5, 1.3)
end

--------------------------------------------------------------------------------
-- Revelación grande de un personaje
--------------------------------------------------------------------------------
local function revelar(id: string, saltar: { valor: boolean }, shiny: boolean?)
	local h = Personajes.todos[id]
	if not h then
		return
	end
	local color = colorDe(h.rarity)
	local mitico = ORDEN[h.rarity] >= ORDEN.Mythic
	local f = fondo(Color3.new(0, 0, 0), 0.15)
	f.ZIndex = 30
	local capa = Comic.crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 30 }, f)
	Comic.crear("UIScale", { Scale = 1 }, capa)

	if mitico then
		-- Falso aviso de rareza baja (portal azul) que se rompe: pantalla dorada, temblor y rayos.
		local portal = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(260 * escala(), 260 * escala()), BackgroundColor3 = Comic.RAREZA.Rare, ZIndex = 31 }, capa)
		Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, portal)
		Comic.crear("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.2 }, portal)
		tween(portal, 0.8, { Size = UDim2.fromOffset(320 * escala(), 320 * escala()) }, Enum.EasingStyle.Sine)
		task.wait(0.9)
		for i = 1, 8 do
			portal.Position = UDim2.new(0.5, math.random(-14, 14), 0.5, math.random(-14, 14))
			portal.BackgroundColor3 = if i % 2 == 0 then color else Comic.RAREZA.Rare
			task.wait(0.06)
		end
		portal:Destroy()
		destello(capa, Color3.fromRGB(255, 240, 180))
		f.BackgroundColor3 = Color3.fromRGB(70, 45, 0)
		rayos(capa, Comic.AMARILLO, 10)
		task.wait(0.2)
	else
		rayos(capa, color, 6)
		destello(capa, color)
	end

	local marco = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(420, 520), BackgroundTransparency = 1, ZIndex = 32 }, capa)
	local esc = Comic.crear("UIScale", { Scale = 0.2 }, marco)
	modelo3D(marco, id, mitico)
	tween(esc, 0.45, { Scale = escala() }, Enum.EasingStyle.Back)
	-- Estilo limpio: nombre grande sin caja, una línea del color de la rareza y «RAREZA · habilidad».
	local cartel = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromOffset(640, 120), BackgroundTransparency = 1, ZIndex = 33 }, capa)
	Comic.crear("UIScale", { Scale = escala() }, cartel)
	Comic.texto({ Text = Comic.mayus(h.name), Size = UDim2.new(1, 0, 0, 58), TextStrokeTransparency = 0.4, ZIndex = 34 }, cartel)
	if shiny then
		-- Shiny (docs/SHINY.md): halo dorado extra, destello y la etiqueta arriba del nombre.
		rayos(capa, Comic.DORADO_SHINY, 6)
		destello(capa, Comic.DORADO_SHINY)
		local marca = Comic.texto({ Text = "★ SHINY ★", TextSize = 22, TextColor3 = Comic.DORADO_SHINY, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -6), Size = UDim2.fromOffset(300, 26), ZIndex = 35 }, cartel)
		task.spawn(function()
			while marca.Parent do
				marca.TextTransparency = 0.15 + math.sin(os.clock() * 5) * 0.15
				task.wait()
			end
		end)
	end
	Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 64), Size = UDim2.fromOffset(110, 3), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 34 }, cartel)
	Comic.texto({ Text = `{Comic.mayus(NOMBRE[h.rarity] or h.rarity)}  ·  {h.ability or ""}`, Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 0, 26), TextSize = 20, TextColor3 = color, ZIndex = 34 }, cartel)
	if mitico then
		-- Su habilidad como grito, grande y cruzada.
		local grito = Comic.texto({ Text = `«{h.ability or ""}»`, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromOffset(900, 80), TextColor3 = Comic.AMARILLO, ZIndex = 35 }, capa)
		Comic.crear("UIScale", { Scale = 0.1 }, grito)
		tween(grito:FindFirstChildOfClass("UIScale"), 0.4, { Scale = escala() }, Enum.EasingStyle.Back)
	end
	local aviso = Comic.texto({ Text = "Tocá para seguir", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(300, 26), Font = Comic.TEXTO, TextSize = 18, ZIndex = 34 }, capa)
	aviso.TextTransparency = 1
	task.delay(0.8, function()
		if aviso.Parent then
			tween(aviso, 0.3, { TextTransparency = 0 })
		end
	end)
	task.wait(0.5)
	if not saltar.valor then
		esperarClic(if mitico then 7 else 4)
	end
	tween(f, 0.2, { BackgroundTransparency = 1 })
	tween(esc, 0.2, { Scale = 0 })
	task.wait(0.2)
	f:Destroy()
end

--------------------------------------------------------------------------------
-- Invocación: x1 con portal; x10 con cartas que se dan vuelta
--------------------------------------------------------------------------------
local ocupado = false
-- Corre una cinemática; si algo falla, limpia la pantalla igual para no dejar el juego tapado ni trabado.
local function correr(cuerpo: () -> ())
	ocupado = true
	task.spawn(function()
		local ok, err = pcall(cuerpo)
		if not ok then
			warn("[Cinematica] " .. tostring(err))
			for _, x in pantalla:GetChildren() do
				x:Destroy()
			end
		end
		pantalla.Enabled = #pantalla:GetChildren() > 0
		ocupado = false
	end)
end

function Cinematica.invocar(nuevas)
	if ocupado or not nuevas or #nuevas == 0 then
		return
	end
	correr(function()
		local saltar = { valor = false }
		local mejor = "Common"
		for _, u in nuevas do
			local r = Personajes.todos[u.heroId] and Personajes.todos[u.heroId].rarity or "Common"
			if ORDEN[r] > ORDEN[mejor] then
				mejor = r
			end
		end
		local f = fondo(Color3.fromRGB(12, 4, 8), 0.1)
		f.ZIndex = 20
		-- Portal: el color insinúa la mejor rareza (los Míticos se disfrazan de azul hasta la revelación).
		local pista = if ORDEN[mejor] >= ORDEN.Mythic then Comic.RAREZA.Rare else colorDe(mejor)
		local portal = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = pista, ZIndex = 21 }, f)
		Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, portal)
		Comic.crear("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.2 }, portal)
		local grad = Comic.crear("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), pista), Rotation = 0 }, portal)
		local girar = RunService.RenderStepped:Connect(function(dt)
			grad.Rotation += dt * 240
		end)
		local lado = 300 * escala()
		tween(portal, 0.7, { Size = UDim2.fromOffset(lado, lado) }, Enum.EasingStyle.Back)
		local botonSaltar = Comic.boton("SALTAR ⏩", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 20), Size = UDim2.fromOffset(150, 46), TextSize = 22, ZIndex = 40 }, f, function()
			saltar.valor = true
		end)
		task.wait(1.1)
		girar:Disconnect()
		destello(f, pista)
		portal:Destroy()

		if #nuevas == 1 then
			revelar(nuevas[1].heroId, saltar, nuevas[1].shiny)
		else
			-- Cartas boca abajo que se dan vuelta de a una; Épico o más se muestra en grande.
			local mesa = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(5 * 170, 2 * 230), BackgroundTransparency = 1, ZIndex = 22 }, f)
			Comic.crear("UIScale", { Scale = escala() }, mesa)
			Comic.crear("UIGridLayout", { CellSize = UDim2.fromOffset(156, 216), CellPadding = UDim2.fromOffset(14, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, mesa)
			local cartas = {}
			for i, u in nuevas do
				-- Dorso: vidrio oscuro con un rombo rojo al centro.
				local carta = Comic.crear("Frame", { BackgroundColor3 = Comic.ROJO_OSCURO, LayoutOrder = i, ZIndex = 23 }, mesa)
				Comic.borde(carta)
				local giro = Comic.crear("UIScale", { Scale = 1 }, carta)
				local dorso = Comic.texto({ Text = "◆", TextSize = 48, TextColor3 = Comic.ROJO, Size = UDim2.fromScale(1, 1), ZIndex = 24 }, carta)
				table.insert(cartas, { carta = carta, giro = giro, dorso = dorso, id = u.heroId, shiny = u.shiny })
			end
			local function darVuelta(c, rapido: boolean)
				local h = Personajes.todos[c.id]
				local color = colorDe(h and h.rarity or "Common")
				local t = if rapido then 0.05 else 0.12
				c.dorso.TextTransparency = 1
				c.carta.BackgroundColor3 = Comic.FONDO
				Comic.resaltar(c.carta, color)
				local caja = Comic.crear("Frame", { Size = UDim2.new(1, 0, 1, -50), BackgroundTransparency = 1, ZIndex = 24 }, c.carta)
				Comic.retrato(caja, c.id, h and h.name or c.id, color, Personajes.base(c.id))
				Comic.texto({ Text = h and h.name or c.id, Position = UDim2.new(0, 6, 1, -50), Size = UDim2.new(1, -12, 0, 28), TextColor3 = color, ZIndex = 25 }, c.carta)
				Comic.texto({ Text = NOMBRE[h and h.rarity or ""] or "", Position = UDim2.new(0, 6, 1, -24), Size = UDim2.new(1, -12, 0, 20), Font = Comic.TEXTO, TextSize = 14, ZIndex = 25 }, c.carta)
				if c.shiny then
					Comic.marcoShiny(c.carta).ZIndex = 26
				end
				c.giro.Scale = 1.25
				tween(c.giro, t * 2, { Scale = 1 }, Enum.EasingStyle.Back)
			end
			for _, c in cartas do
				local h = Personajes.todos[c.id]
				if saltar.valor then
					darVuelta(c, true)
				else
					tween(c.giro, 0.12, { Scale = 0.05 }).Completed:Wait()
					darVuelta(c, false)
					task.wait(0.22)
					if h and (ORDEN[h.rarity] >= ORDEN.Epic or c.shiny) and not saltar.valor then
						revelar(c.id, saltar, c.shiny)
					end
				end
			end
		end

		-- Al final: cerrar.
		botonSaltar:Destroy()
		if #nuevas > 1 then
			local listo = false
			Comic.boton("LISTO", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(200, 56), TextSize = 28, BackgroundColor3 = Comic.VERDE, ZIndex = 40 }, f, function()
				listo = true
			end)
			while not listo and f.Parent do
				task.wait()
			end
		end
		tween(f, 0.25, { BackgroundTransparency = 1 })
		task.wait(0.25)
		f:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Evolución: el modelo viejo se llena de luz y aparece el nuevo
--------------------------------------------------------------------------------
function Cinematica.evolucion(desde: string, hacia: string)
	if ocupado then
		return
	end
	correr(function()
		local h = Personajes.todos[hacia]
		local color = colorDe(h and h.rarity or "Legendary")
		local f = fondo(Color3.fromRGB(10, 4, 20), 0.1)
		local marco = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(420, 520), BackgroundTransparency = 1 }, f)
		Comic.crear("UIScale", { Scale = escala() }, marco)
		local vista = modelo3D(marco, desde, false)
		-- Brillo que crece sobre el modelo viejo.
		local luz = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.2, ZIndex = 5 }, marco)
		Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, luz)
		if vista:IsA("ViewportFrame") then
			tween(vista, 1.4, { ImageColor3 = color, Ambient = Color3.new(1, 1, 1) })
		end
		tween(luz, 1.4, { Size = UDim2.fromOffset(700, 700), BackgroundTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(1.5)
		vista:Destroy()
		modelo3D(marco, hacia, true)
		rayos(f, color, 8)
		tween(luz, 0.5, { BackgroundTransparency = 1 })
		destello(f, Color3.new(1, 1, 1))
		local cartel = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromOffset(640, 110), BackgroundTransparency = 1, ZIndex = 10 }, f)
		Comic.crear("UIScale", { Scale = escala() }, cartel)
		Comic.texto({ Text = "EVOLUCIONÓ", TextSize = 20, TextColor3 = color, Size = UDim2.new(1, 0, 0, 24), ZIndex = 11 }, cartel)
		Comic.texto({ Text = Comic.mayus(h and h.name or hacia), Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 56), TextStrokeTransparency = 0.4, ZIndex = 11 }, cartel)
		Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 90), Size = UDim2.fromOffset(110, 3), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 11 }, cartel)
		task.wait(0.6)
		esperarClic(5)
		tween(f, 0.25, { BackgroundTransparency = 1 })
		task.wait(0.25)
		f:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Subidas de nivel (pantalla final): tarjetitas que saltan con «Nv 7 → 8»
--------------------------------------------------------------------------------
-- texto: "heroId:desde:hasta,..." (atributo Subidas del jugador). Devuelve el marco creado (o nil).
function Cinematica.subidas(padre: GuiObject, texto: string?)
	if not texto or texto == "" then
		return nil
	end
	local fila = Comic.crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, padre)
	Comic.crear("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }, fila)
	for i, parte in string.split(texto, ",") do
		local id, desde, hasta = string.match(parte, "^([%w_]+):(%d+):(%d+)$")
		local h = id and Personajes.todos[id]
		if h then
			local t = Comic.crear("Frame", { Size = UDim2.fromOffset(150, 40), BackgroundColor3 = Comic.FONDO, ZIndex = 22 }, fila)
			Comic.borde(t, 3)
			Comic.resaltar(t, colorDe(h.rarity))
			Comic.texto({ Text = `{h.name}\nNv {desde} → {hasta}`, Size = UDim2.fromScale(1, 1), Font = Comic.TEXTO, TextSize = 15, TextColor3 = Comic.AMARILLO, ZIndex = 23 }, t)
			local esc = Comic.crear("UIScale", { Scale = 0 }, t)
			task.delay(0.6 + i * 0.2, function()
				tween(esc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
			end)
		end
	end
	return fila
end

-- Modelo 3D de cuerpo entero (lo usa la pantalla final para el escuadrón).
Cinematica.modelo3D = modelo3D

return Cinematica
