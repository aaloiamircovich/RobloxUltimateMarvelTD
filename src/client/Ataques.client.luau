-- Efectos de combate en partida (docs/COMBATE_VISUAL.md), sólo visuales y locales:
--  · Ataques: el servidor avisa por «Ataques» quién atacó, desde dónde y a dónde. Los 25 Míticos/Legendarios/Secreto
--    (más Odin y Knull) tienen efecto propio; el resto usa una familia según su poder (fuego, hielo, cortes…).
--  · Muertes: el enemigo se disuelve en partículas del color de su categoría (los jefes, con onda y temblor).
--  · Entrada de jefe: franjas de cine, viñeta con nombre y frase, la cámara lo muestra 2 s y la pantalla tiembla.
-- «Calidad baja» (Ajustes) deja sólo lo básico; «Sacudida de cámara» se puede apagar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Comic = require(script.Parent:WaitForChild("Comic"))
local Ajustes = require(script.Parent:WaitForChild("Ajustes"))
local Personajes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personajes"))

local jugador = Players.LocalPlayer
local camara = workspace.CurrentCamera
local carpeta = Instance.new("Folder")
carpeta.Name = "EfectosLocales"
carpeta.Parent = workspace

local TEX = {
	chispa = "rbxasset://textures/particles/sparkles_main.dds",
	fuego = "rbxasset://textures/particles/fire_main.dds",
	humo = "rbxasset://textures/particles/smoke_main.dds",
}
local MAX_PIEZAS = 220 -- con más piezas vivas se dibuja sólo lo básico
local TAMANO = 1.5 -- escala de todos los ataques (los mapas están ×3 y el pasto tapa lo que es muy chico)

local function c(hex: string): Color3
	return Color3.fromHex(hex)
end
local BLANCO = Color3.new(1, 1, 1)

--------------------------------------------------------------------------------
-- Piezas básicas
--------------------------------------------------------------------------------
local function baja(): boolean
	return Ajustes.valores.calidadBaja or #carpeta:GetChildren() > MAX_PIEZAS
end

local function tween(obj: Instance, t: number, meta, estilo: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(obj, TweenInfo.new(t, estilo or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), meta)
	tw:Play()
	return tw
end

local function pieza(tam: Vector3, cf: CFrame, color: Color3, forma: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.Shape = forma or Enum.PartType.Block
	p.Size, p.CFrame, p.Color = tam, cf, color
	p.Parent = carpeta
	return p
end

local function borrar(obj: Instance, t: number)
	task.delay(t, obj.Destroy, obj)
end

local function luz(p: BasePart, color: Color3, rango: number, brillo: number?, t: number)
	if baja() then
		return
	end
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = color, rango, brillo or 3, false
	l.Parent = p
	tween(l, t, { Brightness = 0 })
end

-- Bola que crece y se apaga, con luz.
local function destello(pos: Vector3, color: Color3, tam: number, t: number?)
	t = t or 0.25
	local p = pieza(Vector3.one * tam * 0.4, CFrame.new(pos), color, Enum.PartType.Ball)
	p.Transparency = 0.1
	luz(p, color, tam * 4, 4, t)
	tween(p, t, { Size = Vector3.one * tam, Transparency = 1 })
	borrar(p, t)
end

-- Partículas que salen de una vez desde un punto.
local function particulas(pos: Vector3, color: Color3, cantidad: number, o)
	o = o or {}
	if baja() then
		cantidad = math.floor(cantidad / 4)
		if cantidad < 1 then
			return
		end
	end
	local p = pieza(Vector3.one, CFrame.new(pos), color)
	p.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX[o.textura or "chispa"]
	e.Color = ColorSequence.new(color, o.color2 or color)
	e.LightEmission = o.brillo or 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, o.tam or 0.8), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	local vida = o.vida or 0.6
	e.Lifetime = NumberRange.new(vida * 0.6, vida)
	e.Speed = NumberRange.new((o.velocidad or 12) * 0.5, o.velocidad or 12)
	e.SpreadAngle = o.abanico or Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, o.gravedad or 0, 0)
	e.Drag = o.freno or 2
	e.RotSpeed = NumberRange.new(-180, 180)
	e.Rate = 0
	e.Enabled = false
	e.Parent = p
	e:Emit(cantidad)
	borrar(p, vida + 0.1)
end

-- Disco plano que se expande desde el piso.
local function onda(pos: Vector3, color: Color3, radio: number, t: number?)
	t = t or 0.35
	local cf = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	local p = pieza(Vector3.new(0.15, radio * 0.3, radio * 0.3), cf, color, Enum.PartType.Cylinder)
	p.Transparency = 0.2
	tween(p, t, { Size = Vector3.new(0.15, radio * 2, radio * 2), Transparency = 1 })
	borrar(p, t)
end

-- Anillo vertical (de frente) que avanza en la dirección del ataque: ondas sónicas y psíquicas.
local function anillo(pos: Vector3, mira: Vector3, color: Color3, radio: number, t: number)
	local cf = CFrame.lookAt(pos, pos + mira) * CFrame.Angles(0, math.rad(90), 0)
	local p = pieza(Vector3.new(0.1, radio * 0.5, radio * 0.5), cf, color, Enum.PartType.Cylinder)
	p.Transparency = 0.3
	tween(p, t, { Size = Vector3.new(0.1, radio * 2, radio * 2), Transparency = 1, CFrame = cf + mira.Unit * radio })
	borrar(p, t)
end

-- Proyectil que viaja y al llegar llama a alLlegar(destino).
local function proyectil(desde: Vector3, hasta: Vector3, color: Color3, o)
	o = o or {}
	local t = o.tiempo or 0.14
	local tam = o.tam or 0.6
	local forma = o.forma or "bola"
	local cf = CFrame.lookAt(desde, hasta)
	local p
	if forma == "aguja" then
		p = pieza(Vector3.new(tam * 0.25, tam * 0.25, tam * 2.6), cf, color)
	elseif forma == "disco" then
		p = pieza(Vector3.new(0.25, tam * 1.6, tam * 1.6), cf * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
	elseif forma == "diamante" then
		p = pieza(Vector3.one * tam, cf * CFrame.Angles(math.rad(45), math.rad(45), 0), color)
	else
		p = pieza(Vector3.one * tam, cf, color, Enum.PartType.Ball)
	end
	if o.material then
		p.Material = o.material
	end
	luz(p, color, tam * 6, 2, t)
	if not baja() then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0, tam * 0.35, 0), Vector3.new(0, -tam * 0.35, 0)
		a0.Parent, a1.Parent = p, p
		local estela = Instance.new("Trail")
		estela.Attachment0, estela.Attachment1 = a0, a1
		estela.Color = ColorSequence.new(o.estela or color)
		estela.LightEmission = 1
		estela.Lifetime = o.largoEstela or 0.15
		estela.Transparency = NumberSequence.new(0.2, 1)
		estela.FaceCamera = true
		estela.WidthScale = NumberSequence.new(1, 0)
		estela.Parent = p
		if o.fuego then
			local f = Instance.new("Fire")
			f.Color, f.SecondaryColor, f.Size, f.Heat = color, o.fuego, tam * 3, 6
			f.Parent = p
		end
	end
	local destino = CFrame.lookAt(hasta, hasta + (hasta - desde))
	if forma == "disco" then
		destino *= CFrame.Angles(0, 0, math.rad(90))
	elseif forma == "diamante" then
		destino *= CFrame.Angles(math.rad(45), math.rad(45), 0)
	end
	tween(p, t, { CFrame = destino }, Enum.EasingStyle.Linear).Completed:Once(function()
		p:Destroy()
		if o.alLlegar then
			o.alLlegar(hasta)
		end
	end)
end

-- Haz recto que se afina y desaparece.
local function haz(desde: Vector3, hasta: Vector3, color: Color3, ancho: number, t: number?, nucleo: Color3?)
	t = t or 0.2
	local largo = (hasta - desde).Magnitude
	local cf = CFrame.lookAt(desde, hasta) * CFrame.new(0, 0, -largo / 2)
	local p = pieza(Vector3.new(ancho, ancho, largo), cf, color)
	p.Transparency = 0.15
	tween(p, t, { Size = Vector3.new(0.05, 0.05, largo), Transparency = 1 })
	borrar(p, t)
	local n = pieza(Vector3.new(ancho * 0.4, ancho * 0.4, largo), cf, nucleo or BLANCO)
	tween(n, t * 0.8, { Size = Vector3.new(0.02, 0.02, largo), Transparency = 1 })
	borrar(n, t)
	luz(n, color, ancho * 8, 3, t)
end

-- Rayo en zigzag (se redibuja dos veces para que parpadee).
local function relampago(desde: Vector3, hasta: Vector3, color: Color3, ancho: number, t: number?, saltos: number?)
	t = t or 0.18
	saltos = saltos or 6
	local function dibujar()
		local largo = (hasta - desde).Magnitude
		local desvio = math.min(2.5, largo * 0.12)
		local anterior = desde
		for i = 1, saltos do
			local punto = if i == saltos
				then hasta
				else desde:Lerp(hasta, i / saltos) + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * desvio * 2
			local l = (punto - anterior).Magnitude
			local p = pieza(Vector3.new(ancho, ancho, l), CFrame.lookAt(anterior, punto) * CFrame.new(0, 0, -l / 2), color)
			tween(p, t, { Transparency = 1, Size = Vector3.new(ancho * 0.3, ancho * 0.3, l) })
			borrar(p, t)
			anterior = punto
		end
	end
	dibujar()
	if not baja() then
		task.delay(t * 0.4, dibujar)
	end
end

-- Rayo que baja del cielo sobre un punto.
local function rayoCielo(pos: Vector3, color: Color3, ancho: number)
	relampago(pos + Vector3.new(math.random(-4, 4), 45, math.random(-4, 4)), pos, color, ancho, 0.25, 9)
	destello(pos, BLANCO, ancho * 6, 0.3)
	onda(pos - Vector3.new(0, 1, 0), color, ancho * 7)
end

-- Columna de luz que sube.
local function columna(pos: Vector3, color: Color3, radio: number, alto: number, t: number?)
	t = t or 0.5
	local base = pos - Vector3.new(0, 1, 0)
	local p = pieza(Vector3.new(alto * 0.1, radio * 2, radio * 2), CFrame.new(base + Vector3.new(0, alto * 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
	p.Transparency = 0.25
	luz(p, color, radio * 6, 4, t)
	tween(p, t, { Size = Vector3.new(alto, radio * 0.4, radio * 0.4), CFrame = CFrame.new(base + Vector3.new(0, alto / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 1 })
	borrar(p, t)
end

-- Púas que salen del piso alrededor de un punto y se hunden.
local function espinas(pos: Vector3, color: Color3, n: number, radio: number, material: Enum.Material?)
	local piso = pos - Vector3.new(0, 1.5, 0)
	for i = 1, (if baja() then math.ceil(n / 2) else n) do
		local a = (i / n) * math.pi * 2 + math.random()
		local d = math.random() * radio
		local alto = 1.5 + math.random() * 2.5
		local donde = piso + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local inclinado = CFrame.new(donde) * CFrame.Angles(math.rad(math.random(-20, 20)), a, math.rad(math.random(-20, 20)))
		local p = pieza(Vector3.new(0.5, alto, 0.5), inclinado * CFrame.new(0, -alto, 0), color)
		p.Material = material or Enum.Material.Neon
		tween(p, 0.12, { CFrame = inclinado * CFrame.new(0, alto / 2, 0) }, Enum.EasingStyle.Back)
		task.delay(0.45, function()
			tween(p, 0.25, { CFrame = inclinado * CFrame.new(0, -alto, 0), Transparency = 1 })
		end)
		borrar(p, 0.75)
	end
end

-- Círculo mágico en el piso: polígono de 16 lados y dos cuadrados cruzados que giran.
local function circulo(pos: Vector3, color: Color3, radio: number, t: number?)
	t = t or 0.6
	local centro = pos - Vector3.new(0, 1.4, 0)
	local piezas = {}
	local lados = if baja() then 8 else 16
	local lado = 2 * radio * math.sin(math.pi / lados)
	for i = 1, lados do
		local a = (i / lados) * math.pi * 2
		table.insert(piezas, { p = pieza(Vector3.new(lado, 0.08, 0.15), CFrame.new(), color), a = a, r = radio })
	end
	if not baja() then
		for k = 0, 7 do
			local a = k * math.pi / 4
			table.insert(piezas, { p = pieza(Vector3.new(radio * 1.15, 0.08, 0.12), CFrame.new(), color), a = a, r = radio * 0.55, cuadrado = true })
		end
	end
	local inicio = os.clock()
	local con
	con = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - inicio) / t
		if k >= 1 then
			con:Disconnect()
			for _, x in piezas do
				x.p:Destroy()
			end
			return
		end
		local giro = k * math.pi
		local escala = math.min(1, k * 4)
		for _, x in piezas do
			local a = x.a + (if x.cuadrado then -giro else giro)
			local r = x.r * escala
			x.p.CFrame = CFrame.new(centro + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0)
			x.p.Transparency = k ^ 2
		end
	end)
end

-- Tajo en arco frente al blanco.
local function corte(desde: Vector3, hasta: Vector3, color: Color3, radio: number, t: number?)
	t = t or 0.2
	local mira = (hasta - desde) * Vector3.new(1, 0, 1)
	if mira.Magnitude < 0.01 then
		mira = Vector3.new(0, 0, -1)
	end
	local base = CFrame.lookAt(hasta, hasta + mira.Unit) * CFrame.Angles(0, 0, math.rad(math.random(-35, 35)))
	local n = if baja() then 5 else 9
	for i = 1, n do
		local a = math.rad(-70 + 140 * (i - 1) / (n - 1))
		local grosor = 0.35 * math.sin(math.pi * (i - 0.5) / n) + 0.08
		local cf = base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, radio)
		local p = pieza(Vector3.new(radio * 0.32, grosor, grosor), cf, color)
		p.Transparency = 1
		task.delay((i - 1) * t * 0.04, function()
			p.Transparency = 0.05
			tween(p, t, { Transparency = 1, Size = Vector3.new(radio * 0.4, 0.03, 0.03) })
		end)
		borrar(p, t * 1.5)
	end
	destello(hasta, color, radio * 0.6, 0.15)
end

-- Bala trazadora con fogonazo.
local function bala(desde: Vector3, hasta: Vector3, color: Color3)
	destello(desde, c("fff1a6"), 0.9, 0.08)
	local largo = (hasta - desde).Magnitude
	local p = pieza(Vector3.new(0.18, 0.18, math.min(5, largo)), CFrame.lookAt(desde, hasta), color)
	tween(p, 0.08, { CFrame = CFrame.lookAt(hasta, hasta + (hasta - desde)) }, Enum.EasingStyle.Linear)
	borrar(p, 0.09)
	task.delay(0.08, particulas, hasta, color, 6, { velocidad = 10, tam = 0.3, vida = 0.25 })
end

-- Telaraña: hilo que queda un momento y una red en el blanco.
local function telarana(desde: Vector3, hasta: Vector3, color: Color3)
	local largo = (hasta - desde).Magnitude
	local hilo = pieza(Vector3.new(0.08, 0.08, largo), CFrame.lookAt(desde, hasta) * CFrame.new(0, 0, -largo / 2), color)
	hilo.Material = Enum.Material.SmoothPlastic
	tween(hilo, 0.4, { Transparency = 1 })
	borrar(hilo, 0.4)
	for k = 0, 2 do
		local p = pieza(Vector3.new(2.4, 0.07, 0.07), CFrame.lookAt(hasta, desde) * CFrame.Angles(0, 0, k * math.pi / 3), color)
		p.Material = Enum.Material.SmoothPlastic
		tween(p, 0.6, { Transparency = 1 })
		borrar(p, 0.6)
	end
end

-- Cristales de hielo que aparecen y se rompen.
local function escarcha(pos: Vector3, radio: number)
	for i = 1, (if baja() then 3 else 7) do
		local a = math.random() * math.pi * 2
		local d = math.random() * radio
		local cf = CFrame.new(pos + Vector3.new(math.cos(a) * d, -1, math.sin(a) * d)) * CFrame.Angles(math.random() * 0.8, a, math.random() * 0.8)
		local p = pieza(Vector3.new(0.6, 1.4 + math.random() * 1.6, 0.6), cf, c("bfefff"))
		p.Material = Enum.Material.Glass
		p.Transparency = 0.2
		tween(p, 0.5, { Transparency = 1, Size = p.Size * 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		borrar(p, 0.5)
	end
	particulas(pos, c("e6fbff"), 14, { velocidad = 8, tam = 0.4, vida = 0.5, gravedad = -10 })
end

--------------------------------------------------------------------------------
-- Sacudida de cámara
--------------------------------------------------------------------------------
local temblor = 0
local function sacudir(fuerza: number, donde: Vector3?)
	if not Ajustes.valores.sacudida then
		return
	end
	if donde and (camara.CFrame.Position - donde).Magnitude > 150 then
		return
	end
	temblor = math.max(temblor, fuerza)
end
RunService:BindToRenderStep("SacudidaCamara", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if temblor <= 0.01 then
		temblor = 0
		return
	end
	local t = os.clock() * 40
	camara.CFrame *= CFrame.Angles(math.noise(t, 0) * temblor * 0.03, math.noise(0, t) * temblor * 0.03, math.noise(t, t) * temblor * 0.015)
	temblor = math.max(0, temblor - dt * 3.5)
end)

--------------------------------------------------------------------------------
-- Familias (los 80 personajes sin efecto propio) y efectos únicos
--------------------------------------------------------------------------------
-- ctx: { critico, extra, escala }. Los golpes críticos se dibujan un 50 % más grandes.
local FAMILIAS = {}

-- Remate común en el blanco: lo que le da peso a los ataques de familia (revisión de ataques, fase E).
local function remate(p: Vector3, col: Color3, ctx, fuerza: number?)
	local f = (fuerza or 1) * ctx.escala
	destello(p, col, 2.8 * f, 0.22)
	onda(p - Vector3.new(0, 1.1, 0), col, 2.6 * f, 0.3)
	particulas(p, col, 10, { color2 = BLANCO, velocidad = 14, tam = 0.45, vida = 0.35 })
end

function FAMILIAS.balas(d, h, col, ctx)
	-- Ráfaga de tres (cuatro con crítico) con fogonazo; el último disparo remata.
	local n = if ctx.critico then 4 else 3
	for i = 0, n - 1 do
		local desvio = Vector3.new(math.random(-3, 3), math.random(-2, 2), math.random(-3, 3)) * 0.1
		task.delay(i * 0.05, bala, d, h + desvio, col)
	end
	task.delay(0.05 * n + 0.04, function()
		destello(h, c("fff1a6"), 1.8 * ctx.escala, 0.15)
		particulas(h, c("ffcf6b"), 8, { velocidad = 16, tam = 0.35, vida = 0.25, gravedad = -30 })
	end)
end

local MODO_HAWKEYE = { explosive = c("ff9d3d"), cryo = c("7ce7ff"), piercing = c("d8f0ff") }
function FAMILIAS.flecha(d, h, col, ctx)
	local modo = ctx.extra
	col = MODO_HAWKEYE[modo] or col
	proyectil(d, h, col, { forma = "aguja", tam = 0.9 * ctx.escala, tiempo = 0.12, largoEstela = 0.22, alLlegar = function(p)
		if modo == "explosive" then
			destello(p, c("ffb347"), 3.4 * ctx.escala, 0.3)
			onda(p - Vector3.new(0, 1.1, 0), c("ff7a1f"), 3 * ctx.escala, 0.3)
			particulas(p, c("ff7a1f"), 18, { textura = "fuego", velocidad = 14, tam = 1.3 })
		elseif modo == "cryo" then
			escarcha(p, 1.8)
		else
			destello(p, col, 1.8 * ctx.escala, 0.15)
			particulas(p, col, 8, { velocidad = 10, tam = 0.35, vida = 0.3 })
		end
	end })
end

function FAMILIAS.energia(d, h, col, ctx)
	proyectil(d, h, col, { tam = 1 * ctx.escala, largoEstela = 0.22, alLlegar = function(p)
		remate(p, col, ctx)
	end })
end

function FAMILIAS.haz(d, h, col, ctx)
	haz(d, h, col, 0.7 * ctx.escala, 0.22, BLANCO)
	remate(h, col, ctx)
end

function FAMILIAS.electrico(d, h, col, ctx)
	relampago(d, h, col, 0.25 * ctx.escala)
	destello(h, col, 2 * ctx.escala, 0.15)
	particulas(h, col, 12, { velocidad = 16, tam = 0.35, vida = 0.3 })
end

function FAMILIAS.fuego(d, h, col, ctx)
	proyectil(d, h, col, { tam = 1.1 * ctx.escala, fuego = c("ffd23d"), tiempo = 0.18, alLlegar = function(p)
		destello(p, c("ff9a2e"), 3.2 * ctx.escala)
		onda(p - Vector3.new(0, 1.1, 0), c("ff7a1f"), 3 * ctx.escala, 0.35)
		particulas(p, c("ff7a1f"), 16, { textura = "fuego", color2 = c("ffd23d"), velocidad = 9, tam = 1.6, gravedad = 6 })
	end })
end

function FAMILIAS.hielo(d, h, col, ctx)
	haz(d, h, col, 0.5 * ctx.escala, 0.25, c("ffffff"))
	escarcha(h, 1.9 * ctx.escala)
end

function FAMILIAS.magia(d, h, col, ctx)
	proyectil(d, h, col, { tam = 0.9 * ctx.escala, tiempo = 0.16, largoEstela = 0.25, alLlegar = function(p)
		circulo(p, col, 3 * ctx.escala, 0.5)
		destello(p, col, 2.4 * ctx.escala, 0.25)
		particulas(p, col, 14, { velocidad = 7, tam = 0.55, vida = 0.6, gravedad = 6 })
	end })
end

function FAMILIAS.psiquico(d, h, col, ctx)
	local mira = h - d
	for i = 0, 2 do
		task.delay(i * 0.05, anillo, d:Lerp(h, 0.2 + i * 0.25), mira, col, 1.7 * ctx.escala, 0.2)
	end
	task.delay(0.12, remate, h, col, ctx, 0.9)
end

function FAMILIAS.golpe(d, h, col, ctx)
	local mira = (h - d).Unit
	local p = pieza(Vector3.new(0.9, 0.9, 3), CFrame.lookAt(h - mira * 3.5, h), col)
	tween(p, 0.08, { CFrame = CFrame.lookAt(h - mira * 0.5, h), Transparency = 0.5 })
	borrar(p, 0.09)
	task.delay(0.07, function()
		destello(h, BLANCO, 2.6 * ctx.escala, 0.15)
		onda(h - Vector3.new(0, 1.2, 0), col, 3.4 * ctx.escala, 0.32)
		anillo(h - mira * 0.5, mira, col, 1.4 * ctx.escala, 0.18)
		particulas(h - Vector3.new(0, 1, 0), c("cbb89a"), 10, { textura = "humo", brillo = 0, velocidad = 7, tam = 1.8, vida = 0.6 })
		if ctx.critico then
			sacudir(0.15, h)
		end
	end)
end

function FAMILIAS.corte(d, h, col, ctx)
	-- Tajo en cruz: el segundo cruza al primero y deja chispas.
	corte(d, h, col, 2.8 * ctx.escala)
	task.delay(0.07, function()
		corte(d, h, if ctx.critico then BLANCO else col, 2.8 * ctx.escala)
		particulas(h, BLANCO, 8, { velocidad = 14, tam = 0.3, vida = 0.25 })
	end)
end

function FAMILIAS.telarana(d, h, col, ctx)
	telarana(d, h, col)
	particulas(h, col, 5, { velocidad = 6, tam = 0.3, vida = 0.3 })
end

function FAMILIAS.simbionte(d, h, col, ctx)
	relampago(d, h, col, 0.45 * ctx.escala, 0.3, 4)
	particulas(h, c("1a1a1a"), 10, { brillo = 0, velocidad = 8, tam = 0.9, vida = 0.5 })
end

function FAMILIAS.escudo(d, h, col, ctx)
	-- El escudo va al blanco y vuelve.
	proyectil(d, h, c("2f5fd0"), { forma = "disco", tam = 1.3, tiempo = 0.14, material = Enum.Material.Metal, estela = c("cfe0ff"), alLlegar = function(p)
		remate(p, c("8fb4ff"), ctx, 0.9)
		proyectil(p, d, c("2f5fd0"), { forma = "disco", tam = 1.3, tiempo = 0.14, material = Enum.Material.Metal, estela = c("cfe0ff") })
	end })
end

-- Personaje → { familia, color }. Los que no están usan el efecto de su modelo (flecha, rayo, impacto).
local PERSONAJES = {
	-- balas
	punisher = { "balas", "fff1a6" }, winter_soldier = { "balas", "fff1a6" }, nick_fury = { "balas", "fff1a6" },
	maria_hill = { "balas", "fff1a6" }, red_guardian = { "balas", "ff5a4f" }, domino = { "balas", "f2f2f2" },
	yelena_belova = { "balas", "fff1a6" }, cable = { "balas", "8fd0ff" }, war_machine = { "balas", "ffcf6b" },
	howard_the_duck = { "balas", "fff1a6" }, elsa_bloodstone = { "balas", "ff8a3d" }, falcon = { "balas", "ff6a5a" },
	-- flechas y dagas
	hawkeye = { "flecha", "b36bff" }, kate_bishop = { "flecha", "b36bff" }, yondu = { "flecha", "ff3b3b" },
	moon_knight = { "flecha", "f4f4ff" }, dagger = { "flecha", "fffbe0" },
	-- energía
	star_lord = { "energia", "ff4a3a" }, rocket_raccoon = { "energia", "ff9d3d" }, nebula = { "energia", "4fa3ff" },
	shuri = { "energia", "a46bff" }, crystal = { "energia", "7fe6ff" }, jubilee = { "energia", "ffd23d" },
	gambit = { "energia", "ff4fc3" }, peni_parker = { "energia", "ff4a6a" },
	cyclops = { "haz", "ff2a2a" },
	-- eléctricos
	black_widow = { "electrico", "7fc8ff" }, miles_morales = { "electrico", "ffe14a" }, wasp = { "electrico", "ffe14a" },
	-- fuego e hielo
	human_torch = { "fuego", "ff7a1f" }, luna_snow = { "hielo", "9fe7ff" },
	-- magia
	wong = { "magia", "ffa23a" }, the_hood = { "magia", "c2293b" }, cloak = { "magia", "6b4fd6" },
	-- psíquicos
	mantis = { "psiquico", "8fff8f" }, cosmo = { "psiquico", "ffd23d" },
	-- golpes
	she_hulk = { "golpe", "5fe36a" }, luke_cage = { "golpe", "ffd23d" }, jessica_jones = { "golpe", "d9d9e6" },
	iron_fist = { "golpe", "6dff8a" }, shang_chi = { "golpe", "ff8a3d" }, daredevil = { "golpe", "ff3b3b" },
	tigra = { "golpe", "ffa23a" }, squirrel_girl = { "golpe", "c98a4b" }, drax = { "golpe", "ff5a4f" },
	mbaku = { "golpe", "d9c7a6" }, korg = { "golpe", "b0a49a" }, groot = { "golpe", "6fbf4f" },
	devil_dinosaur = { "golpe", "ff3b3b" }, beast = { "golpe", "5f8bff" }, rogue = { "golpe", "6dff8a" },
	ms_marvel = { "golpe", "ff6a8a" }, jeff_the_land_shark = { "golpe", "5fc8ff" }, echo = { "golpe", "f2f2f2" },
	white_tiger = { "golpe", "f2f2f2" }, black_cat = { "golpe", "d9d9e6" }, ant_man = { "golpe", "ff4a3a" },
	medusa = { "golpe", "ff4a3a" }, triton = { "golpe", "5fc8ff" }, namora = { "golpe", "5fc8ff" },
	mockingbird = { "golpe", "6fa8ff" }, quake = { "golpe", "e8d9b0" }, nightcrawler = { "golpe", "7a5fff" },
	-- cortes
	wolverine = { "corte", "e6eef7" }, x_23 = { "corte", "e6eef7" }, blade = { "corte", "f2f2f2" },
	elektra = { "corte", "ff3b3b" }, gamora = { "corte", "6dff8a" }, okoye = { "corte", "ffd23d" },
	black_panther = { "corte", "b36bff" }, lady_sif = { "corte", "e6eef7" }, valkyrie = { "corte", "e6eef7" },
	angela = { "corte", "ffd23d" }, magik = { "corte", "c08bff" }, psylocke = { "corte", "ff5fd0" },
	deadpool = { "corte", "ff3b3b" }, heimdall = { "corte", "ffd23d" },
	-- otros
	spiderman = { "telarana", "f2f2f2" }, iron_spider = { "telarana", "ffd23d" }, venom = { "simbionte", "202028" },
	capitan_america = { "escudo", "2f5fd0" },
}

local UNICOS = {}
UNICOS.thor = function(d, h, ctx)
	relampago(d, h, c("9fdcff"), 0.35 * ctx.escala, 0.22, 7)
	rayoCielo(h, c("bfe9ff"), 0.4 * ctx.escala)
	if ctx.critico then
		sacudir(0.6, h)
	end
end
UNICOS.odin = function(d, h, ctx)
	rayoCielo(h, c("ffe08a"), 0.55 * ctx.escala)
	columna(h, c("ffd23d"), 1.8, 22)
	onda(h - Vector3.new(0, 1, 0), c("ffd23d"), 6 * ctx.escala, 0.5)
	if ctx.critico then
		sacudir(0.8, h)
	end
end
UNICOS.iron_man = function(d, h, ctx)
	if ctx.critico then
		haz(d, h, c("7fe6ff"), 1.3, 0.35) -- unirrayo
		sacudir(0.4, h)
	else
		haz(d + Vector3.new(0.6, 0, 0), h, c("9fefff"), 0.45, 0.16)
		task.delay(0.08, haz, d - Vector3.new(0.6, 0, 0), h, c("9fefff"), 0.45, 0.16)
	end
	destello(h, c("bff6ff"), 2.4 * ctx.escala)
end
UNICOS.hulk = function(d, h, ctx)
	FAMILIAS.golpe(d, h, c("5fe36a"), ctx)
	onda(h - Vector3.new(0, 1.2, 0), c("8fff6a"), 6 * ctx.escala, 0.45)
	espinas(h, c("8a7f72"), 7, 3 * ctx.escala, Enum.Material.Slate)
	particulas(h, c("a89a85"), 18, { textura = "humo", brillo = 0, velocidad = 10, tam = 2, vida = 0.8 })
	sacudir(if ctx.critico then 0.9 else 0.35, h)
end
UNICOS.doctor_strange = function(d, h, ctx)
	circulo(d - Vector3.new(0, -2.5, 0), c("ffa23a"), 1.4, 0.35)
	proyectil(d, h, c("ffb347"), { tam = 0.6, tiempo = 0.16, alLlegar = function(p)
		circulo(p, c("ffa23a"), 3 * ctx.escala, 0.6)
		particulas(p, c("ffc46b"), 16, { velocidad = 9, tam = 0.5, vida = 0.6, gravedad = 4 })
	end })
end
UNICOS.captain_marvel = function(d, h, ctx)
	haz(d, h, c("ffcf4a"), 0.8 * ctx.escala, 0.25, c("fff6d0"))
	destello(h, c("ffd23d"), 3.5 * ctx.escala, 0.3)
	particulas(h, c("ff8a3d"), 16, { color2 = c("ffd23d"), velocidad = 14, tam = 0.6 })
	if ctx.critico then
		sacudir(0.5, h)
	end
end
UNICOS.scarlet_witch = function(d, h, ctx)
	relampago(d, h, c("ff2a5f"), 0.25, 0.3, 10)
	relampago(d, h, c("ff7aa0"), 0.12, 0.3, 10)
	circulo(h, c("ff2a5f"), 2.6 * ctx.escala, 0.5)
	particulas(h, c("ff2a5f"), 14, { velocidad = 6, tam = 0.6, vida = 0.7, gravedad = 5 })
end
UNICOS.vision = function(d, h, ctx)
	haz(d + Vector3.new(0, 1.2, 0), h, c("ffd23d"), 0.4 * ctx.escala, 0.22, c("7fff8a"))
	destello(h, c("ffe14a"), 2.6 * ctx.escala)
end
UNICOS.jean_grey = function(d, h, ctx)
	proyectil(d, h, c("ff6a1f"), { tam = 1.1 * ctx.escala, fuego = c("ffd23d"), tiempo = 0.2, largoEstela = 0.3, alLlegar = function(p)
		destello(p, c("ffb347"), 4 * ctx.escala, 0.35)
		onda(p - Vector3.new(0, 1, 0), c("ff7a1f"), 4.5 * ctx.escala)
		particulas(p, c("ff7a1f"), 20, { textura = "fuego", color2 = c("ffd23d"), velocidad = 10, tam = 1.6, gravedad = 8 })
		if ctx.critico then
			columna(p, c("ff8a2a"), 1.6, 18)
			sacudir(0.5, p)
		end
	end })
end
UNICOS.storm = function(d, h, ctx)
	rayoCielo(h, c("e6f4ff"), 0.4 * ctx.escala)
	particulas(h, c("e6eef7"), 14, { textura = "humo", brillo = 0.2, velocidad = 14, tam = 2, vida = 0.6, abanico = Vector2.new(30, 180) })
end
UNICOS.silver_surfer = function(d, h, ctx)
	haz(d, h, c("dfe9ff"), 0.6 * ctx.escala, 0.25, c("ffffff"))
	destello(h, c("bcd2ff"), 3 * ctx.escala)
	particulas(h, c("cfe0ff"), 18, { color2 = c("8fa8ff"), velocidad = 12, tam = 0.5, vida = 0.6 })
end
UNICOS.ghost_rider = function(d, h, ctx)
	relampago(d, h, c("ff7a1f"), 0.3, 0.25, 8) -- cadena en llamas
	particulas(h, c("ff7a1f"), 16, { textura = "fuego", color2 = c("ffd23d"), velocidad = 7, tam = 1.4, gravedad = 8 })
	destello(h, c("ff9a2e"), 2.4 * ctx.escala)
end
UNICOS.nova = function(d, h, ctx)
	proyectil(d, h, c("ffd23d"), { tam = 1 * ctx.escala, tiempo = 0.15, alLlegar = function(p)
		destello(p, c("fff1a6"), 3.6 * ctx.escala, 0.3)
		onda(p - Vector3.new(0, 1, 0), c("ffd23d"), 4 * ctx.escala)
	end })
end
UNICOS.namor = function(d, h, ctx)
	proyectil(d, h, c("ffd23d"), { forma = "aguja", tam = 1.1, tiempo = 0.13, alLlegar = function(p)
		particulas(p, c("5fc8ff"), 18, { color2 = c("e6fbff"), velocidad = 12, tam = 0.6, gravedad = -20, abanico = Vector2.new(40, 40) })
		onda(p - Vector3.new(0, 1, 0), c("5fc8ff"), 3 * ctx.escala)
	end })
end
UNICOS.iceman = function(d, h, ctx)
	haz(d, h, c("9fe7ff"), 0.6 * ctx.escala, 0.3, c("ffffff"))
	escarcha(h, 2.6 * ctx.escala)
	onda(h - Vector3.new(0, 1.2, 0), c("cff4ff"), 3.5 * ctx.escala, 0.5)
end
UNICOS.black_bolt = function(d, h, ctx)
	local mira = h - d
	for i = 0, 3 do
		task.delay(i * 0.04, anillo, d:Lerp(h, 0.1 + i * 0.25), mira, c("cfe0ff"), 1.6 * ctx.escala, 0.22)
	end
	task.delay(0.15, function()
		destello(h, BLANCO, 3.5 * ctx.escala, 0.3)
		onda(h - Vector3.new(0, 1, 0), c("9fbfff"), 5 * ctx.escala)
		sacudir(if ctx.critico then 0.7 else 0.25, h)
	end)
end
UNICOS.hela = function(d, h, ctx)
	espinas(h, c("1f6b3a"), 8, 2.5 * ctx.escala)
	particulas(h, c("2fbf6a"), 14, { velocidad = 6, tam = 0.6, vida = 0.7, gravedad = 4 })
	destello(h, c("2fbf6a"), 2 * ctx.escala)
end
UNICOS.emma_frost = function(d, h, ctx)
	proyectil(d, h, c("f4fbff"), { forma = "diamante", tam = 0.8, tiempo = 0.15, alLlegar = function(p)
		destello(p, c("ffffff"), 2.4 * ctx.escala)
		for i = 0, 2 do
			task.delay(i * 0.07, onda, p - Vector3.new(0, 1, 0), c("ff8fe0"), (2 + i) * ctx.escala, 0.3)
		end
	end })
end
UNICOS.magneto = function(d, h, ctx)
	proyectil(d, h, c("8a8f99"), { forma = "disco", tam = 0.9, tiempo = 0.16, material = Enum.Material.Metal, estela = c("c23bff"), alLlegar = function(p)
		destello(p, c("c23bff"), 2.6 * ctx.escala)
		onda(p - Vector3.new(0, 1, 0), c("ff3b5f"), 3.5 * ctx.escala)
		particulas(p, c("c9ccd6"), 10, { brillo = 0.2, velocidad = 12, tam = 0.4, vida = 0.4, gravedad = -30 })
	end })
end
UNICOS.adam_warlock = function(d, h, ctx)
	haz(d, h, c("ffcf4a"), 0.5 * ctx.escala, 0.25)
	circulo(h, c("ffd23d"), 2.6 * ctx.escala, 0.5)
	destello(h, c("fff1a6"), 2.4 * ctx.escala)
end
UNICOS.invisible_woman = function(d, h, ctx)
	local p = pieza(Vector3.one * 1, CFrame.new(h), c("8fd0ff"), Enum.PartType.Ball)
	p.Material = Enum.Material.ForceField
	tween(p, 0.4, { Size = Vector3.one * 5 * ctx.escala, Transparency = 1 })
	borrar(p, 0.4)
	anillo(d, h - d, c("8fd0ff"), 1.2, 0.2)
	destello(h, c("cfeaff"), 2 * ctx.escala)
end
UNICOS.loki = function(d, h, ctx)
	proyectil(d, h, c("4fe36a"), { tam = 0.7, tiempo = 0.15, alLlegar = function(p)
		destello(p, c("6dff8a"), 2.6 * ctx.escala)
		particulas(p, c("4fe36a"), 16, { color2 = c("ffd23d"), velocidad = 7, tam = 0.6, vida = 0.7 })
	end })
	-- Una copia ilusoria que se desvanece al lado.
	proyectil(d + Vector3.new(0, 1.5, 0), h + Vector3.new(1.5, 0.5, 0), c("2a8f45"), { tam = 0.5, tiempo = 0.15 })
end
UNICOS.mister_fantastic = function(d, h, ctx)
	-- Brazo que se estira hasta el blanco y vuelve.
	local largo = (h - d).Magnitude
	local p = pieza(Vector3.new(0.6, 0.6, 0.1), CFrame.lookAt(d, h), c("2f6bff"))
	p.Material = Enum.Material.SmoothPlastic
	tween(p, 0.1, { Size = Vector3.new(0.6, 0.6, largo), CFrame = CFrame.lookAt(d, h) * CFrame.new(0, 0, -largo / 2) })
	task.delay(0.12, function()
		destello(h, BLANCO, 2 * ctx.escala, 0.15)
		onda(h - Vector3.new(0, 1.2, 0), c("5f8bff"), 3 * ctx.escala)
		tween(p, 0.12, { Size = Vector3.new(0.6, 0.6, 0.1), CFrame = CFrame.lookAt(d, h) })
	end)
	borrar(p, 0.26)
end
UNICOS.sentry = function(d, h, ctx)
	haz(d, h, c("fff1a6"), 1 * ctx.escala, 0.3, c("ffffff"))
	columna(h, c("ffe08a"), 2, 26)
	destello(h, c("fffbe0"), 4.5 * ctx.escala, 0.35)
	sacudir(if ctx.critico then 0.8 else 0.3, h)
end
UNICOS.beta_ray_bill = function(d, h, ctx)
	relampago(d, h, c("ffb347"), 0.35 * ctx.escala, 0.22, 7)
	rayoCielo(h, c("ffcf6b"), 0.45 * ctx.escala)
	if ctx.critico then
		sacudir(0.6, h)
	end
end
UNICOS.profesor_x = function(d, h, ctx)
	for i = 0, 3 do
		task.delay(i * 0.08, onda, h - Vector3.new(0, 1, 0), c("b36bff"), (2 + i * 1.3) * ctx.escala, 0.35)
	end
	FAMILIAS.psiquico(d + Vector3.new(0, 1.5, 0), h, c("d39bff"), ctx)
end
UNICOS.knull = function(d, h, ctx)
	FAMILIAS.simbionte(d, h, c("15151c"), ctx)
	espinas(h, c("0d0d12"), 9, 2.8 * ctx.escala, Enum.Material.Slate)
	destello(h, c("7f8fff"), 2 * ctx.escala)
end

-- Efectos que no son de un personaje: saltos en cadena, salpicaduras y el pisotón de Korg.
local GENERALES = {
	cadena = function(d, h)
		relampago(d, h, c("8fd0ff"), 0.15, 0.15, 4)
	end,
	area = function(_d, h, ctx)
		onda(h - Vector3.new(0, 1, 0), c("ffb347"), math.max(2, ctx.extra or 2), 0.35)
		particulas(h, c("ff9a3d"), 10, { textura = "fuego", velocidad = 10, tam = 1 })
	end,
	pisoton = function(_d, h, ctx)
		onda(h, c("cbb89a"), ctx.extra or 10, 0.5)
		particulas(h, c("a89a85"), 20, { textura = "humo", brillo = 0, velocidad = 14, tam = 2.5, vida = 0.8 })
		sacudir(0.5, h)
	end,
}
local POR_EFECTO = { flecha = "flecha", rayo = "energia", impacto = "golpe" }

local remoto = ReplicatedStorage:WaitForChild("Ataques") :: UnreliableRemoteEvent
remoto.OnClientEvent:Connect(function(estilo: string, desde: Vector3, hasta: Vector3, critico: boolean, extra)
	if typeof(desde) ~= "Vector3" or typeof(hasta) ~= "Vector3" or (camara.CFrame.Position - hasta).Magnitude > 260 then
		return
	end
	local ctx = { critico = critico, extra = extra, escala = TAMANO * (if critico then 1.5 else 1) }
	if GENERALES[estilo] then
		GENERALES[estilo](desde, hasta, ctx)
	elseif UNICOS[estilo] then
		UNICOS[estilo](desde, hasta, ctx)
	else
		local datos = PERSONAJES[estilo]
		local familia = if datos then datos[1] else POR_EFECTO[extra] or "energia"
		FAMILIAS[familia](desde, hasta, if datos then c(datos[2]) else Comic.AMARILLO, ctx)
	end
	if critico then
		destello(hasta, BLANCO, 1.6, 0.12)
	end
end)

--------------------------------------------------------------------------------
-- Muertes: el enemigo se vuelve luz del color de su categoría y se deshace en partículas
--------------------------------------------------------------------------------
local disolviendo = 0
local function disolver(cuerpo: BasePart)
	local pos = cuerpo.Position
	local color = cuerpo.Color
	local jefe = cuerpo:GetAttribute("Jefe") ~= nil
	local tam = math.max(cuerpo.Size.Y, 2)
	local modelo = cuerpo:FindFirstChildWhichIsA("Model")
	if modelo and not baja() and disolviendo < 12 then
		local ok, copia = pcall(modelo.Clone, modelo)
		if ok and copia then
			disolviendo += 1
			for _, d in copia:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
					if d.Transparency < 1 then
						d.Material = Enum.Material.Neon
						d.Color = BLANCO
						if d:IsA("MeshPart") then
							d.TextureID = ""
						end
						tween(d, 0.5, { Color = color, Transparency = 1, Size = d.Size * 0.85 })
					end
				elseif d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture") or d:IsA("BillboardGui") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ParticleEmitter") then
					d:Destroy()
				end
			end
			for _, d in modelo:GetDescendants() do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = 1
				end
			end
			copia.Parent = carpeta
			task.delay(0.55, function()
				copia:Destroy()
				disolviendo -= 1
			end)
		end
	end
	particulas(pos, color, if jefe then 60 else 18, { color2 = BLANCO, velocidad = if jefe then 18 else 8, tam = if jefe then 1.2 else 0.6, vida = 0.9, gravedad = 8 })
	destello(pos, color, tam * (if jefe then 2.5 else 1.2), 0.3)
	if jefe then
		onda(pos - Vector3.new(0, tam / 2, 0), color, 14, 0.7)
		columna(pos, color, 2.5, 30, 0.8)
		sacudir(1, pos)
	end
end

--------------------------------------------------------------------------------
-- Entrada de jefe
--------------------------------------------------------------------------------
local FRASES = {
	loki = "Nada de lo que ven es real… salvo su derrota.",
	doctor_doom = "Latveria no negocia. Latveria conquista.",
	magneto = "Su metal me obedece. Ustedes también lo harán.",
	green_goblin = "¡Hora de jugar, héroes!",
	red_skull = "Hydra nunca muere: sólo espera.",
	ultron_prime = "Ya calculé su final. No hay margen de error.",
	kingpin = "Esta ciudad tiene dueño.",
	kang = "Ya gané esta batalla en mil líneas de tiempo.",
	apocalypse = "Sólo los fuertes sobreviven. Demuéstrenlo.",
	carnage = "¡Qué lindo caos vamos a armar!",
	hela = "Asgard ya es mío. Ustedes siguen.",
	killmonger = "Vine a quedarme con el trono.",
	dormammu = "Esta dimensión ya me pertenece.",
	galactus = "Este mundo será mi alimento.",
	thanos_final = "Con un gesto, todo termina.",
	malekith = "La oscuridad vuelve a reinar.",
	baron_mordo = "La magia tiene un precio. Hoy lo pagan ustedes.",
	sauron = "¡Sus mentes ya son mías!",
	abomination = "¡Más fuerte que cualquier héroe!",
}
local ultimaEntrada = 0
local pantalla = Comic.crear("ScreenGui", { Name = "EntradaJefe", ResetOnSpawn = false, DisplayOrder = 8, IgnoreGuiInset = true, Enabled = false }, jugador:WaitForChild("PlayerGui"))
local franjaArriba = Comic.crear("Frame", { BackgroundColor3 = Comic.NEGRO, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.fromScale(0, -0.12) }, pantalla)
local franjaAbajo = Comic.crear("Frame", { BackgroundColor3 = Comic.NEGRO, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.fromScale(0, 1) }, pantalla)
-- Panel de vidrio con una franja roja a la izquierda: «JEFE», el nombre grande y su frase.
local vineta = Comic.crear("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(560, 150), Position = UDim2.new(1, 40, 0.68, 0), BackgroundColor3 = Comic.FONDO, BackgroundTransparency = Comic.TRANSPARENCIA }, pantalla)
Comic.borde(vineta)
Comic.crear("Frame", { Position = UDim2.fromOffset(0, 14), Size = UDim2.new(0, 5, 1, -28), BackgroundColor3 = Comic.ROJO, BorderSizePixel = 0 }, vineta)
local escalaVineta = Comic.crear("UIScale", {}, vineta)
Comic.texto({ Text = "JEFE", TextSize = 14, TextColor3 = Comic.ROJO, Position = UDim2.fromOffset(24, 14), Size = UDim2.fromOffset(100, 16), TextXAlignment = Enum.TextXAlignment.Left }, vineta)
local nombreJefe = Comic.texto({ Position = UDim2.fromOffset(24, 32), Size = UDim2.new(1, -44, 0, 56), TextXAlignment = Enum.TextXAlignment.Left }, vineta)
local fraseJefe = Comic.texto({ Position = UDim2.fromOffset(24, 94), Size = UDim2.new(1, -44, 0, 44), Font = Comic.TEXTO, TextSize = 18, TextColor3 = Comic.TENUE, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }, vineta)

local function entradaJefe(cuerpo: BasePart)
	if os.clock() - ultimaEntrada < 20 or (camara.CFrame.Position - cuerpo.Position).Magnitude > 400 then
		return
	end
	ultimaEntrada = os.clock()
	nombreJefe.Text = Comic.mayus(cuerpo:GetAttribute("Jefe") or "JEFE")
	fraseJefe.Text = `«{FRASES[cuerpo.Name] or "Prepárense para caer."}»`
	escalaVineta.Scale = math.clamp(camara.ViewportSize.X / 1280, 0.6, 1.2)
	pantalla.Enabled = true
	tween(franjaArriba, 0.3, { Position = UDim2.fromScale(0, 0) })
	tween(franjaAbajo, 0.3, { Position = UDim2.fromScale(0, 0.88) })
	tween(vineta, 0.35, { Position = UDim2.new(1, -600 * escalaVineta.Scale, 0.68, 0) }, Enum.EasingStyle.Back)

	-- La cámara lo muestra 2 s desde adelante y arriba, siguiéndolo; después vuelve a la normal.
	local anterior = camara.CameraType
	local inicio = os.clock()
	local desde = camara.CFrame
	camara.CameraType = Enum.CameraType.Scriptable
	local pasos = 0
	local con
	con = RunService.RenderStepped:Connect(function()
		local k = os.clock() - inicio
		if k > 2.2 or not cuerpo.Parent then
			con:Disconnect()
			camara.CameraType = anterior
			tween(franjaArriba, 0.3, { Position = UDim2.fromScale(0, -0.12) })
			tween(franjaAbajo, 0.3, { Position = UDim2.fromScale(0, 1) })
			tween(vineta, 0.25, { Position = UDim2.new(1, 40, 0.68, 0) }).Completed:Once(function()
				if os.clock() - ultimaEntrada > 2 then
					pantalla.Enabled = false
				end
			end)
			return
		end
		local modelo = cuerpo:FindFirstChildWhichIsA("Model")
		local objetivo, alto = cuerpo.Position, math.max(cuerpo.Size.Y, 4)
		if modelo then
			local caja, tam = modelo:GetBoundingBox()
			objetivo, alto = caja.Position, math.max(tam.Y, 4)
		end
		local lado = (desde.Position - objetivo) * Vector3.new(1, 0, 1)
		lado = if lado.Magnitude > 0.1 then lado.Unit else Vector3.new(0, 0, 1)
		local cerca = CFrame.lookAt(objetivo + lado * alto * 4 + Vector3.new(0, alto * 1.2, 0), objetivo + Vector3.new(0, alto * 0.3, 0))
		camara.CFrame = desde:Lerp(cerca, math.min(1, k / 0.5))
		-- Cada paso pesado hace temblar la pantalla.
		if k > 0.4 + pasos * 0.55 then
			pasos += 1
			sacudir(0.7)
		end
	end)
end

--------------------------------------------------------------------------------
-- Enemigos de las partidas: muertes y jefes
--------------------------------------------------------------------------------
local function seguir(cuerpo: Instance)
	if not cuerpo:IsA("BasePart") or not cuerpo.Parent or cuerpo.Parent.Name ~= "Enemigos" then
		return
	end
	if cuerpo:GetAttribute("Jefe") then
		task.defer(entradaJefe, cuerpo)
	end
	local con
	con = cuerpo:GetAttributeChangedSignal("Muerto"):Connect(function()
		con:Disconnect()
		disolver(cuerpo)
	end)
end
--------------------------------------------------------------------------------
-- Entrada de los únicos al colocarlos: su ataque cae del cielo sobre ellos (docs/UNIDADES_VISUAL.md)
--------------------------------------------------------------------------------
local function entrada(modelo: Instance)
	if not modelo:IsA("Model") or modelo:GetAttribute("Uid") == nil or not modelo:GetAttribute("Entrada") then
		return
	end
	local id = Personajes.base(modelo:GetAttribute("Heroe") or "")
	local efecto = UNICOS[id]
	if not efecto then
		return
	end
	task.delay(0.35, function()
		if not modelo.Parent then
			return
		end
		local cf, tam = modelo:GetBoundingBox()
		local pie = cf.Position - Vector3.new(0, tam.Y / 2 - 0.5, 0)
		efecto(pie + Vector3.new(0, 30, 0), pie, { critico = true, escala = TAMANO * 1.5 })
		onda(pie, BLANCO, 8, 0.5)
		sacudir(0.35, pie)
	end)
end

local partidas = workspace:WaitForChild("Partidas")
partidas.DescendantAdded:Connect(seguir)
partidas.DescendantAdded:Connect(entrada)
for _, d in partidas:GetDescendants() do
	seguir(d)
end
