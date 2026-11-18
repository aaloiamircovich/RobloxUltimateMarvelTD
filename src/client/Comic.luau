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
		tween(escala, 0.12, { Scale = 1.04 })
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
		tween(escala, 0.1, { Scale = 1.04 })
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
	Comic.crear("ImageLabel", {
		BackgroundTransparency = 1,
		Image = icono,
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 4),
		Size = UDim2.new(1, -16, 0.64, 0),
	}, b)
	Comic.texto({ Text = Comic.mayus(nombre), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -8, 0.2, 0) }, b)
	b.Activated:Connect(function()
		Sonido.efecto("clic")
		alClic()
	end)
	animarBoton(b, function(encima)
		tween(trazo, 0.12, { Color = if encima then acento else Comic.BORDE, Transparency = if encima then 0 else 0.35 })
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
		if p.Visible then
			escala.Scale = base * 0.94
			tween(escala, 0.14, { Scale = base })
		end
	end)
	local cuerpo = Comic.crear("Frame", { Position = UDim2.fromOffset(20, 60), Size = UDim2.new(1, -40, 1, -76), BackgroundTransparency = 1 }, p)
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
