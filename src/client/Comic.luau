-- Estilo de interfaz tipo cómic Marvel: rojo intenso, amarillo/dorado de acento, borde negro grueso,
-- paneles levemente inclinados y letras Bangers. Lo usan el HUD del lobby y los paneles.
local Comic = {}

Comic.ROJO = Color3.fromRGB(200, 24, 32)
Comic.ROJO_OSCURO = Color3.fromRGB(110, 10, 18)
Comic.FONDO = Color3.fromRGB(28, 8, 12)
Comic.AMARILLO = Color3.fromRGB(255, 214, 40)
Comic.CREMA = Color3.fromRGB(255, 244, 222)
Comic.NEGRO = Color3.new(0, 0, 0)
Comic.VERDE = Color3.fromRGB(40, 150, 60)
Comic.GRIS = Color3.fromRGB(70, 70, 80)
Comic.RAREZA = {
	Common = Color3.fromRGB(170, 175, 185),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(180, 100, 255),
	Legendary = Color3.fromRGB(255, 190, 60),
	Mythic = Color3.fromRGB(255, 90, 110),
	Secret = Color3.fromRGB(80, 255, 220),
}
Comic.TITULO = Enum.Font.Bangers
Comic.TEXTO = Enum.Font.GothamBold

function Comic.crear(clase: string, props, padre: Instance?)
	local i = Instance.new(clase)
	for k, v in props do
		i[k] = v
	end
	i.Parent = padre
	return i
end

-- Borde negro grueso y esquinas apenas redondeadas, como un recuadro de viñeta.
function Comic.borde(objeto: GuiObject, grosor: number?)
	Comic.crear("UIStroke", { Color = Comic.NEGRO, Thickness = grosor or 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, objeto)
	Comic.crear("UICorner", { CornerRadius = UDim.new(0, 6) }, objeto)
end

-- Texto con contorno negro (letras de cómic).
function Comic.texto(props, padre)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Comic.TITULO
	props.TextColor3 = props.TextColor3 or Comic.CREMA
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0
	props.TextStrokeColor3 = Comic.NEGRO
	props.TextScaled = if props.TextSize then false else true
	-- Retrato 3D del personaje (modelo de ReplicatedStorage.Retratos) o, si no tiene modelo, sus iniciales.
function Comic.retrato(padre: GuiObject, base: string, nombre: string, color: Color3)
	local plantilla = game:GetService("ReplicatedStorage"):FindFirstChild("Retratos")
	plantilla = plantilla and plantilla:FindFirstChild(base)
	if not plantilla then
		local iniciales = string.upper(string.gsub(nombre, "(%w)%w*%s*", "%1"))
		return Comic.texto({ Text = string.sub(iniciales, 1, 3), TextColor3 = color, Size = UDim2.fromScale(1, 1) }, padre)
	end
	local vista = Comic.crear("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 200), LightDirection = Vector3.new(-1, -1, -1) }, padre)
	local m = plantilla:Clone()
	m.Parent = vista
	local cf, tam = m:GetBoundingBox()
	-- Plano medio: cabeza y torso, de frente (los modelos miran hacia su LookVector).
	local foco = cf.Position + Vector3.new(0, tam.Y * 0.22, 0)
	local camara = Comic.crear("Camera", { FieldOfView = 30 }, vista)
	camara.CFrame = CFrame.lookAt(foco + m:GetPivot().LookVector * tam.Y * 1.5, foco)
	vista.CurrentCamera = camara
	return vista
end

return Comic.crear("TextLabel", props, padre)
end

-- Botón con ícono grande y rótulo abajo (como los botones del lobby de los TD de Roblox).
function Comic.botonIcono(nombre: string, icono: string, props, padre, alClic)
	props.BackgroundColor3 = props.BackgroundColor3 or Comic.ROJO
	props.AutoButtonColor = true
	props.Text = ""
	local b = Comic.crear("TextButton", props, padre)
	Comic.borde(b, 3)
	Comic.crear("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)) }, b)
	Comic.crear("ImageLabel", {
		BackgroundTransparency = 1,
		Image = icono,
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.new(1, -8, 0.72, 0),
	}, b)
	Comic.texto({ Text = nombre, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, -6, 0.26, 0) }, b)
	b.Activated:Connect(alClic)
	-- Pequeño rebote al apretar.
	local escala = Comic.crear("UIScale", {}, b)
	b.MouseButton1Down:Connect(function()
		escala.Scale = 0.92
	end)
	b.MouseButton1Up:Connect(function()
		escala.Scale = 1
	end)
	b.MouseLeave:Connect(function()
		escala.Scale = 1
	end)
	return b
end

-- Botón de texto (acciones dentro de los paneles).
function Comic.boton(txt: string, props, padre, alClic)
	props.Text = txt
	props.BackgroundColor3 = props.BackgroundColor3 or Comic.ROJO
	props.TextColor3 = props.TextColor3 or Comic.CREMA
	props.Font = props.Font or Comic.TITULO
	props.TextSize = props.TextSize or 22
	props.TextStrokeTransparency = 0
	props.TextWrapped = true
	local b = Comic.crear("TextButton", props, padre)
	Comic.borde(b, 3)
	b.Activated:Connect(alClic)
	return b
end

-- Panel centrado con franja de título amarilla inclinada y botón de cierre. Devuelve (panel, cuerpo).
function Comic.panel(gui: Instance, titulo: string, tamano: UDim2)
	-- ZIndex alto: el panel se dibuja encima de los botones, monedas y escuadrón del HUD.
	local p = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = tamano, BackgroundColor3 = Comic.FONDO, Visible = false, ZIndex = 10 }, gui)
	Comic.borde(p, 5)
	local franja = Comic.crear("Frame", { Position = UDim2.fromOffset(-10, -22), Size = UDim2.new(0, 320, 0, 52), BackgroundColor3 = Comic.AMARILLO, Rotation = -2 }, p)
	Comic.borde(franja, 4)
	Comic.texto({ Text = titulo, TextColor3 = Comic.ROJO_OSCURO, TextStrokeTransparency = 1, Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -28, 1, -8), TextXAlignment = Enum.TextXAlignment.Left }, franja)
	Comic.boton("X", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 14, 0, -18), Size = UDim2.fromOffset(46, 46), TextSize = 28 }, p, function()
		p.Visible = false
	end)
	-- Se achica para entrar en pantallas chicas (celulares).
	local escala = Comic.crear("UIScale", {}, p)
	local camara = workspace.CurrentCamera
	local function ajustar()
		local v = camara.ViewportSize
		escala.Scale = math.min(1, (v.X - 40) / tamano.X.Offset, (v.Y - 80) / (tamano.Y.Offset + 30))
	end
	camara:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	ajustar()
	local cuerpo = Comic.crear("Frame", { Position = UDim2.fromOffset(20, 46), Size = UDim2.new(1, -40, 1, -64), BackgroundTransparency = 1 }, p)
	return p, cuerpo
end

-- Retrato 3D del personaje (modelo de ReplicatedStorage.Retratos) o, si no tiene modelo, sus iniciales.
function Comic.retrato(padre: GuiObject, base: string, nombre: string, color: Color3)
	local plantilla = game:GetService("ReplicatedStorage"):FindFirstChild("Retratos")
	plantilla = plantilla and plantilla:FindFirstChild(base)
	if not plantilla then
		local iniciales = string.upper(string.gsub(nombre, "(%w)%w*%s*", "%1"))
		return Comic.texto({ Text = string.sub(iniciales, 1, 3), TextColor3 = color, Size = UDim2.fromScale(1, 1) }, padre)
	end
	local vista = Comic.crear("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(200, 200, 200), LightDirection = Vector3.new(-1, -1, -1) }, padre)
	local m = plantilla:Clone()
	m.Parent = vista
	local cf, tam = m:GetBoundingBox()
	-- Plano medio: cabeza y torso, de frente (los modelos miran hacia su LookVector).
	local foco = cf.Position + Vector3.new(0, tam.Y * 0.22, 0)
	local camara = Comic.crear("Camera", { FieldOfView = 30 }, vista)
	camara.CFrame = CFrame.lookAt(foco + m:GetPivot().LookVector * tam.Y * 1.5, foco)
	vista.CurrentCamera = camara
	return vista
end

return Comic
