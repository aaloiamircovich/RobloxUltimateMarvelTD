-- Estilo de interfaz (docs/INTERFAZ.md, decidido el 17/11/2026): limpio, como Anime Vanguards. Paneles de vidrio
-- oscuro con esquinas redondeadas y borde fino, títulos en Gotham Black, botones rellenos con degradado que se
-- agrandan al pasar el mouse; rojo Marvel para lo principal y dorado para premios. El módulo conserva el nombre y
-- las funciones de cuando era cómic para que todo el juego cambie de aspecto desde acá.
local TweenService = game:GetService("TweenService")
local Comic = {}
local Sonido = require(script.Parent:WaitForChild("Sonido"))

Comic.ROJO = Color3.fromRGB(226, 38, 52) -- botón principal
Comic.ROJO_OSCURO = Color3.fromRGB(34, 38, 52) -- fondo secundario (tarjetas, filas)
Comic.FONDO = Color3.fromRGB(16, 18, 26) -- panel
Comic.AMARILLO = Color3.fromRGB(255, 200, 72) -- dorado: premios y valores destacados
Comic.CREMA = Color3.fromRGB(236, 240, 248) -- texto
Comic.TENUE = Color3.fromRGB(150, 158, 178) -- texto secundario
Comic.BORDE = Color3.fromRGB(96, 104, 128)
Comic.NEGRO = Color3.new(0, 0, 0)
Comic.VERDE = Color3.fromRGB(46, 170, 90)
Comic.GRIS = Color3.fromRGB(58, 63, 80)
Comic.RAREZA = {
	Common = Color3.fromRGB(170, 175, 185),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(180, 100, 255),
	Legendary = Color3.fromRGB(255, 190, 60),
	Mythic = Color3.fromRGB(255, 90, 110),
	Secret = Color3.fromRGB(80, 255, 220),
}
Comic.TITULO = Enum.Font.GothamBlack
Comic.TEXTO = Enum.Font.GothamBold
Comic.TRANSPARENCIA = 0.1 -- de los paneles (vidrio)

local function tween(obj: Instance, t: number, meta)
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), meta):Play()
end

-- Mayúsculas con acentos y eñe (string.upper deja «í» o «ñ» en minúscula).
local ACENTOS = { ["á"] = "Á", ["é"] = "É", ["í"] = "Í", ["ó"] = "Ó", ["ú"] = "Ú", ["ñ"] = "Ñ", ["ü"] = "Ü" }
function Comic.mayus(texto: string): string
	local r = string.upper(texto)
	for min, may in ACENTOS do
		r = string.gsub(r, min, may)
	end
	return r
end

function Comic.crear(clase: string, props, padre: Instance?)
	local i = Instance.new(clase)
	for k, v in props do
		i[k] = v
	end
	i.Parent = padre
	return i
end

-- Borde fino y esquinas redondeadas. `grosor` se respeta sólo como énfasis (2 como máximo).
function Comic.borde(objeto: GuiObject, grosor: number?)
	Comic.crear("UIStroke", {
		Color = Comic.BORDE,
		Thickness = if grosor and grosor >= 4 then 2 else 1,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, objeto)
	Comic.crear("UICorner", { CornerRadius = UDim.new(0, 10) }, objeto)
end

-- Pinta el borde de un elemento con un color fuerte (rareza, seleccionado, premio listo).
function Comic.resaltar(objeto: GuiObject, color: Color3)
	local trazo = objeto:FindFirstChildOfClass("UIStroke") or Comic.crear("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, objeto)
	trazo.Color, trazo.Transparency, trazo.Thickness = color, 0, 2
end

-- Corte en diagonal (identidad Marvel, docs/INTERFAZ.md): la esquina pedida se recorta en diagonal y el borde
-- toma el color de acento justo en el corte. Se hace con degradados (fondo y borde), sin imágenes.
-- `esquina`: "arriba" (arriba a la derecha) o "abajo" (abajo a la izquierda). `corte`: fracción de la diagonal.
local ROTACION_CORTE = { arriba = -45, abajo = 135 }
function Comic.diagonal(objeto: GuiObject, acento: Color3?, esquina: string?, corte: number?)
	-- Los degradados girados de Roblox no respetan la proporción: en piezas anchas el corte se come un tercio.
	-- shortcut: sólo piezas casi cuadradas; para anchas haría falta una imagen 9-slice (ForgeGUI, diciembre).
	local w, h = objeto.Size.X.Offset, objeto.Size.Y.Offset
	if w <= 0 or h <= 0 or math.max(w / h, h / w) > 1.7 then
		return nil
	end
	local fin = 1 - (corte or 0.12)
	local recorte = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(fin, 0),
		NumberSequenceKeypoint.new(math.min(fin + 0.005, 0.999), 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	local rot = ROTACION_CORTE[esquina or "arriba"]
	-- El objeto puede traer su propio degradado (botón principal): se le suma el recorte.
	local g = objeto:FindFirstChildOfClass("UIGradient") or Comic.crear("UIGradient", {}, objeto)
	g.Rotation, g.Transparency = rot, recorte
	local trazo = objeto:FindFirstChildOfClass("UIStroke")
	if trazo then
		trazo.Color = Color3.new(1, 1, 1)
		trazo.Transparency = math.min(trazo.Transparency, 0.2)
		local gt = trazo:FindFirstChildOfClass("UIGradient") or Comic.crear("UIGradient", {}, trazo)
		gt.Rotation, gt.Transparency = rot, recorte
		Comic.acentoDiagonal(objeto, acento or Comic.ROJO, false)
	end
	return g
end
-- Color del borde con corte: tenue con la esquina del acento, o todo del acento (al pasar el mouse).
function Comic.acentoDiagonal(objeto: GuiObject, acento: Color3, lleno: boolean)
	local trazo = objeto:FindFirstChildOfClass("UIStroke")
	local gt = trazo and trazo:FindFirstChildOfClass("UIGradient")
	if not gt then
		return
	end
	local base = if lleno then acento else Comic.BORDE
	gt.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, base),
		ColorSequenceKeypoint.new(0.62, base),
		ColorSequenceKeypoint.new(0.8, acento),
		ColorSequenceKeypoint.new(1, acento),
	})
end

-- Brillo que cruza el objeto cada tanto (botón principal).
function Comic.brillo(objeto: GuiObject, cada: number?)
	local capa = Comic.crear("Frame", { Name = "Brillo", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = (objeto.ZIndex or 1) + 1 }, objeto)
	Comic.crear("UICorner", { CornerRadius = UDim.new(0, 10) }, capa)
	local g = Comic.crear("UIGradient", {
		Rotation = 20,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Offset = Vector2.new(-1, 0),
	}, capa)
	task.spawn(function()
		while capa.Parent do
			g.Offset = Vector2.new(-1, 0)
			TweenService:Create(g, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Offset = Vector2.new(1, 0) }):Play()
			task.wait(cada or 3.5)
		end
	end)
	return capa
end

-- Número que sube (o baja) contando hasta el valor nuevo en `t` segundos. `formato` arma el texto.
local contando = setmetatable({}, { __mode = "k" })
function Comic.contar(etiqueta: TextLabel, hasta: number, formato: (number) -> string, t: number?)
	local desde = contando[etiqueta] or hasta
	contando[etiqueta] = hasta
	if desde == hasta then
		etiqueta.Text = formato(hasta)
		return
	end
	local valor = Instance.new("NumberValue")
	valor.Value = desde
	valor.Changed:Connect(function(v)
		etiqueta.Text = formato(math.floor(v + 0.5))
	end)
	local tw = TweenService:Create(valor, TweenInfo.new(t or 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = hasta })
	tw.Completed:Once(function()
		etiqueta.Text = formato(hasta)
		valor:Destroy()
	end)
	tw:Play()
end

-- Marca Shiny (docs/SHINY.md) en una tarjeta: borde dorado con un brillo que lo recorre y la etiqueta «★ SHINY».
Comic.DORADO_SHINY = Color3.fromRGB(255, 214, 90)
function Comic.marcoShiny(objeto: GuiObject)
	Comic.resaltar(objeto, Comic.DORADO_SHINY)
	local trazo = objeto:FindFirstChildOfClass("UIStroke")
	trazo.Thickness = 3
	local g = Comic.crear("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Comic.DORADO_SHINY), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Comic.DORADO_SHINY) }) }, trazo)
	task.spawn(function()
		while g.Parent and objeto.Parent do
			g.Rotation = (g.Rotation + 5) % 360
			task.wait(0.03)
		end
	end)
	local etiqueta = Comic.crear("TextLabel", { Text = "★ SHINY", Font = Comic.TITULO, TextSize = 10, TextColor3 = Color3.fromRGB(40, 28, 0), BackgroundColor3 = Comic.DORADO_SHINY, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(52, 15), ZIndex = (objeto.ZIndex or 1) + 3 }, objeto)
	Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, etiqueta)
	return etiqueta
end

-- Texto limpio, sin contorno grueso (una sombra muy suave para leerse sobre el 3D).
function Comic.texto(props, padre)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Comic.TITULO
	props.TextColor3 = props.TextColor3 or Comic.CREMA
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0.8
	props.TextStrokeColor3 = Comic.NEGRO
	props.TextScaled = if props.TextSize then false else true
	return Comic.crear("TextLabel", props, padre)
end

-- Agranda un poco al pasar el mouse y hunde al apretar.
local function animarBoton(b: GuiButton, alPasar: (boolean) -> ()?)
	local escala = Comic.crear("UIScale", {}, b)
	b.MouseEnter:Connect(function()
		tween(escala, 0.12, { Scale = 1.07 })
		if alPasar then
			alPasar(true)
		end
	end)
	b.MouseLeave:Connect(function()
		tween(escala, 0.12, { Scale = 1 })
		if alPasar then
			alPasar(false)
		end
	end)
	b.MouseButton1Down:Connect(function()
		tween(escala, 0.06, { Scale = 0.95 })
	end)
	b.MouseButton1Up:Connect(function()
		tween(escala, 0.1, { Scale = 1.07 })
	end)
end

-- Botón con ícono grande y rótulo abajo (columnas del lobby): baldosa de vidrio oscuro con una franja del color
-- de la sección abajo; al pasar el mouse el borde toma ese color.
function Comic.botonIcono(nombre: string, icono: string, props, padre, alClic)
	local acento = props.BackgroundColor3 or Comic.ROJO
	props.BackgroundColor3 = Comic.FONDO
	props.BackgroundTransparency = Comic.TRANSPARENCIA
	props.AutoButtonColor = false
	props.Text = ""
	local b = Comic.crear("TextButton", props, padre)
	Comic.borde(b)
	local trazo = b:FindFirstChildOfClass("UIStroke")
	local franja = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(1, -16, 0, 3), BackgroundColor3 = acento, BorderSizePixel = 0 }, b)
	Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, franja)
	local imagen = Comic.crear("ImageLabel", {
		Name = "Icono",
		BackgroundTransparency = 1,
		Image = icono,
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 4),
		Size = UDim2.new(1, -16, 0.64, 0),
	}, b)
	Comic.diagonal(b, acento)
	Comic.texto({ Text = Comic.mayus(nombre), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -8, 0.2, 0) }, b)
	b.Activated:Connect(function()
		Sonido.efecto("clic")
		alClic()
	end)
	animarBoton(b, function(encima)
		-- Borde del acento y el ícono sube un poco (también el retrato que lo reemplace).
		Comic.acentoDiagonal(b, acento, encima)
		tween(trazo, 0.12, { Transparency = if encima then 0 else 0.2 })
		local y = UDim2.new(0.5, 0, 0, if encima then 0 else 4)
		tween(imagen, 0.15, { Position = y, Rotation = if encima then -4 else 0 })
		local retrato = b:FindFirstChild("Retrato")
		if retrato then
			tween(retrato, 0.15, { Position = y })
		end
	end)
	return b
end

-- Botón de texto: relleno del color pedido con un degradado suave hacia abajo.
function Comic.boton(txt: string, props, padre, alClic)
	props.Text = txt
	props.BackgroundColor3 = props.BackgroundColor3 or Comic.ROJO
	props.TextColor3 = props.TextColor3 or Comic.CREMA
	props.Font = props.Font or Comic.TITULO
	props.TextSize = props.TextSize or 20
	props.TextStrokeTransparency = 1
	props.TextWrapped = true
	props.AutoButtonColor = false
	local b = Comic.crear("TextButton", props, padre)
	Comic.crear("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	Comic.crear("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.82, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	local degradado = Comic.crear("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 200)) }, b)
	b.Activated:Connect(function()
		Sonido.efecto("clic")
		alClic()
	end)
	animarBoton(b, function(encima)
		degradado.Color = if encima
			then ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(225, 225, 232))
			else ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 200))
	end)
	return b
end

-- Fondo de las ventanas (docs/INTERFAZ.md, 19/11/2026): con cualquier ventana abierta el mundo se desenfoca y se
-- oscurece, y el HUD de los costados se esconde (lo hace cada script escuchando Comic.ventanas).
local abiertas = {}
local eventoVentanas = Instance.new("BindableEvent")
Comic.ventanas = eventoVentanas.Event -- (hay: boolean)
local blur, velo
function Comic.hayVentana(): boolean
	return next(abiertas) ~= nil
end
function Comic.registrarVentana(clave: Instance, abierta: boolean)
	local antes = Comic.hayVentana()
	abiertas[clave] = if abierta then true else nil
	local ahora = Comic.hayVentana()
	if antes == ahora then
		return
	end
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "BlurVentanas"
		blur.Size = 0
		blur.Parent = game:GetService("Lighting")
		local jugador = game:GetService("Players").LocalPlayer
		velo = Comic.crear("ScreenGui", { Name = "VeloVentanas", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 0 }, jugador:WaitForChild("PlayerGui"))
		velo = Comic.crear("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 8, 14), BackgroundTransparency = 1, BorderSizePixel = 0 }, velo)
	end
	tween(blur, 0.2, { Size = if ahora then 16 else 0 })
	tween(velo, 0.2, { BackgroundTransparency = if ahora then 0.45 else 1 })
	eventoVentanas:Fire(ahora)
end

-- Molde de tarjetas (docs/INTERFAZ.md, 19/11/2026): dentro de una ventana, todo bloque de color fuerte que sea
-- una tarjeta (tiene contenido y mide al menos 60×60) pasa a vidrio oscuro con el color en el borde y en una
-- franja abajo. Los botones de acción chicos, las barras y sus rellenos quedan como están. Se aplica también a lo
-- que las ventanas arman después (al cambiar de pestaña, reclamar, etc.).
-- shortcut: decide por color y tamaño; si una tarjeta queda mal, marcala con el atributo SinMolde = true.
local MIN_TARJETA = 60
local function fuerte(c: Color3): boolean
	local _, sat, val = c:ToHSV()
	return sat > 0.35 and val > 0.3
end
local function esTarjeta(o: Instance): boolean
	if not (o:IsA("Frame") or o:IsA("TextButton") or o:IsA("TextLabel")) or o:GetAttribute("SinMolde") then
		return false
	end
	if o.BackgroundTransparency > 0.6 or not fuerte(o.BackgroundColor3) then
		return false
	end
	local tam = o.AbsoluteSize
	local w, h = if tam.X > 0 then tam.X else o.Size.X.Offset, if tam.Y > 0 then tam.Y else o.Size.Y.Offset
	if w < MIN_TARJETA or h < MIN_TARJETA then
		return false
	end
	-- Con contenido: hijos visibles o texto propio (los rellenos de barras no tienen ninguno).
	if (o:IsA("TextButton") or o:IsA("TextLabel")) and o.Text ~= "" then
		return true
	end
	for _, h2 in o:GetChildren() do
		if h2:IsA("GuiObject") then
			return true
		end
	end
	return false
end
local function textoClaro(t: Instance, acento: Color3)
	if (t:IsA("TextLabel") or t:IsA("TextButton")) then
		local _, _, v = t.TextColor3:ToHSV()
		if v < 0.4 then
			t.TextColor3 = acento:Lerp(Color3.new(1, 1, 1), 0.35)
		end
	end
end
local function moldearUno(o: Instance)
	if o:GetAttribute("Moldeado") or not esTarjeta(o) then
		return
	end
	local acento = o.BackgroundColor3
	o:SetAttribute("Moldeado", true)
	o.BackgroundColor3, o.BackgroundTransparency = Comic.ROJO_OSCURO, 0
	local g = o:FindFirstChildOfClass("UIGradient")
	if g then
		g:Destroy()
	end
	local trazo = o:FindFirstChildOfClass("UIStroke") or Comic.crear("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	trazo.Color, trazo.Transparency, trazo.Thickness = acento, 0.15, 1.5
	if not o:FindFirstChildOfClass("UICorner") then
		Comic.crear("UICorner", { CornerRadius = UDim.new(0, 10) }, o)
	end
	local franja = Comic.crear("Frame", { Name = "FranjaMolde", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(1, -16, 0, 3), BackgroundColor3 = acento, BorderSizePixel = 0 }, o)
	Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, franja)
	textoClaro(o, acento)
	for _, d in o:GetDescendants() do
		textoClaro(d, acento)
	end
end
function Comic.moldear(raiz: Instance)
	local function revisar(d: Instance)
		if d:IsA("GuiObject") then
			task.defer(function()
				if d.Parent then
					moldearUno(d)
					-- Texto oscuro agregado dentro de una tarjeta ya moldeada.
					local madre = d:FindFirstAncestorWhichIsA("GuiObject")
					while madre and not madre:GetAttribute("Moldeado") do
						madre = madre.Parent and madre.Parent:IsA("GuiObject") and madre.Parent or nil
					end
					if madre and madre ~= d then
						local trazo = madre:FindFirstChildOfClass("UIStroke")
						textoClaro(d, if trazo then trazo.Color else Comic.CREMA)
					end
				end
			end)
		end
	end
	raiz.DescendantAdded:Connect(revisar)
	for _, d in raiz:GetDescendants() do
		revisar(d)
	end
end
-- Repaso al abrir la ventana: lo creado antes de que la interfaz estuviera en pantalla a veces no se moldea.
function Comic.repasarMolde(raiz: Instance)
	for _, d in raiz:GetDescendants() do
		moldearUno(d)
	end
end

-- Panel centrado de vidrio oscuro: título arriba a la izquierda con una línea roja debajo y botón de cierre.
-- Devuelve (panel, cuerpo). Aparece con un pequeño crecimiento.
function Comic.panel(gui: Instance, titulo: string, tamano: UDim2)
	-- ZIndex alto: el panel se dibuja encima de los botones, monedas y escuadrón del HUD.
	local p = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = tamano, BackgroundColor3 = Comic.FONDO, BackgroundTransparency = Comic.TRANSPARENCIA, Visible = false, ZIndex = 10 }, gui)
	Comic.crear("UICorner", { CornerRadius = UDim.new(0, 12) }, p)
	Comic.crear("UIStroke", { Color = Comic.BORDE, Thickness = 1, Transparency = 0.3 }, p)
	Comic.texto({ Text = Comic.mayus(titulo), Position = UDim2.fromOffset(22, 12), Size = UDim2.new(1, -90, 0, 30), TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left }, p)
	local linea = Comic.crear("Frame", { Position = UDim2.fromOffset(22, 46), Size = UDim2.fromOffset(64, 3), BackgroundColor3 = Comic.ROJO, BorderSizePixel = 0 }, p)
	Comic.crear("UICorner", { CornerRadius = UDim.new(1, 0) }, linea)
	Comic.boton("X", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(36, 36), TextSize = 18, BackgroundColor3 = Comic.GRIS }, p, function()
		p.Visible = false
	end)
	-- Se achica para entrar en ventanas chicas.
	local escala = Comic.crear("UIScale", {}, p)
	local camara = workspace.CurrentCamera
	local base = 1
	local function ajustar()
		local v = camara.ViewportSize
		base = math.min(1, (v.X - 40) / tamano.X.Offset, (v.Y - 80) / (tamano.Y.Offset + 30))
		escala.Scale = base
	end
	camara:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	ajustar()
	p:GetPropertyChangedSignal("Visible"):Connect(function()
		Comic.registrarVentana(p, p.Visible)
		if p.Visible then
			Comic.repasarMolde(p)
			-- Entra subiendo desde un poco más abajo, con un leve rebote.
			escala.Scale = base * 0.94
			p.Position = UDim2.new(0.5, 0, 0.5, 28)
			TweenService:Create(escala, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = base }):Play()
			TweenService:Create(p, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
		end
	end)
	local cuerpo = Comic.crear("Frame", { Position = UDim2.fromOffset(20, 60), Size = UDim2.new(1, -40, 1, -76), BackgroundTransparency = 1 }, p)
	Comic.moldear(cuerpo)
	return p, cuerpo
end

-- Escala un bloque del HUD según la pantalla (diseño base 1280×720, PC primero; docs/INTERFAZ.md).
Comic.BASE_ANCHO, Comic.BASE_ALTO = 1280, 720
function Comic.escala(): number
	local v = workspace.CurrentCamera.ViewportSize
	return math.clamp(math.min(v.X / Comic.BASE_ANCHO, v.Y / Comic.BASE_ALTO), 0.55, 1.35)
end
function Comic.escalar(bloque: GuiObject, alCambiar: ((number) -> ())?)
	local escala = Comic.crear("UIScale", {}, bloque)
	local camara = workspace.CurrentCamera
	local function ajustar()
		escala.Scale = Comic.escala()
		if alCambiar then
			alCambiar(escala.Scale)
		end
	end
	camara:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	ajustar()
end

-- Retrato 3D del personaje (modelo de ReplicatedStorage.Retratos) o, si no tiene modelo, sus iniciales.
function Comic.retrato(padre: GuiObject, id: string, nombre: string, color: Color3, respaldo: string?)
	local retratos = game:GetService("ReplicatedStorage"):FindFirstChild("Retratos")
	-- Modelo propio (las evoluciones tienen el suyo) o el del personaje base.
	local plantilla = retratos and (retratos:FindFirstChild(id) or (respaldo and retratos:FindFirstChild(respaldo)))
	if not plantilla then
		local iniciales = Comic.mayus(string.gsub(nombre, "(%w)%w*%s*", "%1"))
		return Comic.texto({ Text = string.sub(iniciales, 1, 3), TextColor3 = color, Size = UDim2.fromScale(1, 1) }, padre)
	end
	local vista = Comic.crear("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 200), LightDirection = Vector3.new(-1, -1, -1) }, padre)
	-- WorldModel: deja animar el modelo dentro del ViewportFrame (reposo en bucle, docs/ANIMACION.md).
	local mundo = Comic.crear("WorldModel", {}, vista)
	local m = plantilla:Clone()
	m.Parent = mundo
	local humanoide = m:FindFirstChildOfClass("Humanoid")
	-- Algunos retratos llegan sin Animator (Nightcrawler quedaba en pose T): se crea si falta.
	local animator = humanoide and (humanoide:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoide))
	if animator then
		local Reposo = require(game:GetService("ReplicatedStorage").Shared.Reposo)
		local anim = Instance.new("Animation")
		anim.AnimationId = Reposo.para(id, m:GetAttribute("Efecto"))
		local ok, pista = pcall(animator.LoadAnimation, animator, anim)
		if ok then
			pista.Looped = true
			pista:Play(0)
		end
	end
	local cf, tam = m:GetBoundingBox()
	-- Plano medio: cabeza y torso, de frente (los modelos miran hacia su LookVector).
	local foco = cf.Position + Vector3.new(0, tam.Y * 0.22, 0)
	local camara = Comic.crear("Camera", { FieldOfView = 30 }, vista)
	camara.CFrame = CFrame.lookAt(foco + m:GetPivot().LookVector * tam.Y * 1.5, foco)
	vista.CurrentCamera = camara
	return vista
end

return Comic
