-- Ambiente de cada mapa en partida (docs/AMBIENTE.md), sólo local: luz, cielo, niebla y color «cine vibrante»,
-- clima (lluvia con relámpagos, nieve, ceniza, polvo, hojas, luciérnagas), agua con olas, fuego y humo en el
-- decorado, luces que titilan, cosas que pasan por el cielo y un paneo del recorrido al entrar.
-- Al volver al lobby se restaura todo como estaba. «Calidad baja» (Ajustes) apaga brillo, rayos y la mayor parte
-- del clima.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mapa = require(Shared:WaitForChild("Mapa"))
local niveles = require(Shared:WaitForChild("Data"):WaitForChild("levels"))
local Comic = require(script.Parent:WaitForChild("Comic"))
local Ajustes = require(script.Parent:WaitForChild("Ajustes"))

local jugador = Players.LocalPlayer
local camara = workspace.CurrentCamera
local terreno = workspace.Terrain

local function c(hex: string): Color3
	return Color3.fromHex(hex)
end

--------------------------------------------------------------------------------
-- Ambientes por mapa (decididos por el usuario el 14/11/2026: «cine vibrante»)
--------------------------------------------------------------------------------
-- hora: ClockTime · luz: Brightness · amb/ext: Ambient y OutdoorAmbient · tinte, sat, contraste: ColorCorrection
-- niebla: Atmosphere { densidad, color, decay, bruma, brillo } · cielo: "hub" (el del lobby) o "noche" (estrellas)
-- clima: lluvia | nieve | polvo | brasas | chispas | hojas | luciernagas | petalos (una lista)
-- agua: { color, olas, velocidad } · fuego/humo: nombres de piezas del kit · luces: calidas | neon | emergencia
-- cielo3d: pajaros | quinjet | nave | dragon | pterodactilo
local AMBIENTES = {
	level_1 = { -- Base de los Vengadores: día de sol
		hora = 14, luz = 3, amb = "7d8698", ext = "a8b3c8", tinte = "fff8ee", sat = 0.12, contraste = 0.08, bloom = 0.5, rayos = 0.06,
		niebla = { 0.22, "cfe0ff", "9fb6dc", 0.6, 0.1 }, cielo = "hub", luces = "neon", cielo3d = { "quinjet", "pajaros" },
	},
	level_2 = { -- Nueva York: atardecer
		hora = 17.6, luz = 2.4, amb = "8a6a62", ext = "b98a70", tinte = "ffd9b8", sat = 0.18, contraste = 0.1, bloom = 0.8, rayos = 0.12,
		niebla = { 0.32, "ffb98a", "c46a5a", 1.4, 0.4 }, cielo = "hub", luces = "neon", cielo3d = { "pajaros" },
	},
	level_3 = { -- Wakanda: tarde dorada con niebla de selva
		hora = 16.4, luz = 2.6, amb = "6e7060", ext = "a89c78", tinte = "ffeac0", sat = 0.18, contraste = 0.1, bloom = 0.7, rayos = 0.1,
		niebla = { 0.3, "f0e4c0", "a89a6a", 1, 0.3 }, cielo = "hub", clima = { "hojas", "luciernagas" },
		agua = { "2fb8a8", 0.25, 12 }, luces = "calidas", cielo3d = { "pajaros" },
	},
	level_4 = { -- Sanctum: noche de luna
		hora = 22.5, luz = 1.2, amb = "3a3f66", ext = "4a5280", tinte = "dfe4ff", sat = 0.1, contraste = 0.14, bloom = 0.9, rayos = 0,
		niebla = { 0.35, "4a4f80", "2a2f55", 1, 0 }, cielo = "noche", clima = { "chispas" }, fuego = { "brasero" }, luces = "calidas",
	},
	level_5 = { -- Instituto Xavier: mañana suave
		hora = 9.5, luz = 2.8, amb = "7a8090", ext = "b0bcd0", tinte = "fff4f0", sat = 0.1, contraste = 0.05, bloom = 0.5, rayos = 0.08,
		niebla = { 0.25, "e8eeff", "b8c4e0", 0.8, 0.2 }, cielo = "hub", clima = { "petalos" },
		agua = { "3a8fd0", 0.1, 6 }, luces = "calidas", cielo3d = { "pajaros" },
	},
	level_6 = { -- Knowhere: el espacio
		hora = 0, luz = 1.6, amb = "5a3a70", ext = "7a4a90", tinte = "ffe0f6", sat = 0.25, contraste = 0.16, bloom = 1.1, rayos = 0,
		niebla = { 0.3, "6a3a8a", "2a8fa8", 1.2, 0 }, cielo = "noche", estrellas = 5000, clima = { "polvo" },
		humo = { "estructura_2" }, luces = "neon", cielo3d = { "nave" },
	},
	level_7 = { -- Latveria: nublado y verdoso, con nieve y chimeneas
		hora = 15, luz = 1.5, amb = "5e665e", ext = "7a857a", tinte = "e6f2e0", sat = -0.08, contraste = 0.12, bloom = 0.6, rayos = 0,
		niebla = { 0.45, "a8b8a8", "5a6a5a", 2, 0 }, cielo = "nublado", clima = { "nieve" },
		agua = { "2f5a3a", 0.15, 8 }, fuego = { "farol" }, fuegoColor = "6dff6a", humo = { "estructura_1", "estructura_2", "borde_2" }, luces = "calidas",
	},
	level_8 = { -- Asgard: dorado
		hora = 17.2, luz = 2.3, amb = "7a6848", ext = "b0945c", tinte = "ffe6b8", sat = 0.18, contraste = 0.14, bloom = 0.7, rayos = 0.14,
		niebla = { 0.28, "ffd890", "c88a50", 0.7, 0.4 }, cielo = "hub", clima = { "chispas" },
		agua = { "4a5fd8", 0.2, 10 }, fuego = { "farol" }, luces = "calidas", cielo3d = { "dragon" },
	},
	level_9 = { -- Dimensión Oscura: violeta
		hora = 0, luz = 1.4, amb = "5a2a70", ext = "7a3a90", tinte = "ffd0ff", sat = 0.3, contraste = 0.2, bloom = 1.2, rayos = 0,
		niebla = { 0.42, "8a2aa8", "ff2a8a", 1.6, 0 }, cielo = "noche", estrellas = 1500, clima = { "brasas" },
		agua = { "2a0a3a", 0.3, 14 }, luces = "neon",
	},
	level_10 = { -- Savage Land: selva húmeda
		hora = 11.5, luz = 2.7, amb = "6a7258", ext = "a0a880", tinte = "fffbea", sat = 0.15, contraste = 0.1, bloom = 0.6, rayos = 0.12,
		niebla = { 0.3, "e8eed8", "8aa870", 0.9, 0.2 }, cielo = "hub", clima = { "hojas", "luciernagas" },
		agua = { "3a9a6a", 0.2, 10 }, fuego = { "farol" }, luces = "calidas", cielo3d = { "pterodactilo", "pajaros" },
	},
	level_11 = { -- The Raft: noche de tormenta
		hora = 23.5, luz = 1.5, amb = "3a4660", ext = "50607e", tinte = "d0e0ff", sat = -0.05, contraste = 0.18, bloom = 0.7, rayos = 0,
		niebla = { 0.5, "3a4a60", "1a2030", 2.2, 0 }, cielo = "nublado", clima = { "lluvia" }, tormenta = true,
		agua = { "1a3048", 0.6, 22 }, luces = "emergencia",
	},
}

--------------------------------------------------------------------------------
-- Guardar y restaurar lo del lobby
--------------------------------------------------------------------------------
local PROPS_LUZ = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale" }
local PROPS_AGUA = { "WaterColor", "WaterWaveSize", "WaterWaveSpeed", "WaterReflectance", "WaterTransparency" }
local guardado = nil -- { luz = {}, agua = {}, sacados = { [Instance] = padre } }
local propios = {} -- instancias creadas para el mapa actual
local conexiones = {}

local function crear(clase: string, props, padre: Instance?)
	local i = Instance.new(clase)
	for k, v in props do
		i[k] = v
	end
	i.Parent = padre
	table.insert(propios, i)
	return i
end

local function restaurar()
	for _, con in conexiones do
		con:Disconnect()
	end
	table.clear(conexiones)
	for _, i in propios do
		i:Destroy()
	end
	table.clear(propios)
	if not guardado then
		return
	end
	for k, v in guardado.luz do
		Lighting[k] = v
	end
	for k, v in guardado.agua do
		terreno[k] = v
	end
	for i, padre in guardado.sacados do
		i.Parent = padre
	end
	guardado = nil
end

local function guardar()
	guardado = { luz = {}, agua = {}, sacados = {} }
	for _, k in PROPS_LUZ do
		guardado.luz[k] = Lighting[k]
	end
	for _, k in PROPS_AGUA do
		guardado.agua[k] = terreno[k]
	end
end

-- Saca (sólo en este cliente) los efectos del lobby que chocan con los del mapa.
local function sacar(i: Instance)
	guardado.sacados[i] = i.Parent
	i.Parent = nil
end

--------------------------------------------------------------------------------
-- Clima: cajas que siguen a la cámara y sueltan partículas
--------------------------------------------------------------------------------
local CIRCULO = "rbxasset://textures/whiteCircle.png"
local CHISPA = "rbxasset://textures/particles/sparkles_main.dds"
local CLIMAS = {
	lluvia = { arriba = true, tex = CIRCULO, color = "c8d8f0", tam = 0.2, estirar = 6, vel = { 90, 110 }, vida = 0.9, tasa = 900, transp = 0.15, brillo = 0.2, paralelo = true },
	nieve = { arriba = true, tex = CIRCULO, color = "ffffff", tam = 0.28, vel = { 3, 6 }, vida = 12, tasa = 180, transp = 0.1, viento = Vector3.new(1.2, 0, 0.6) },
	hojas = { arriba = true, tex = CIRCULO, color = "6fa83a", color2 = "c8a83a", tam = 0.45, estirar = -0.4, vel = { 2, 4 }, vida = 14, tasa = 25, giro = 120, viento = Vector3.new(1.5, 0, 0.8) },
	petalos = { arriba = true, tex = CIRCULO, color = "ffb8d8", color2 = "ffffff", tam = 0.35, estirar = 0.8, vel = { 2, 4 }, vida = 14, tasa = 30, giro = 120, viento = Vector3.new(1.2, 0, 1) },
	polvo = { tex = CHISPA, color = "ff6bd6", color2 = "58d6ff", tam = 0.35, vel = { 0.3, 1 }, vida = 10, tasa = 60, brillo = 1 },
	brasas = { tex = CHISPA, color = "ff2a8a", color2 = "b04aff", tam = 0.3, vel = { 1, 3 }, vida = 8, tasa = 70, brillo = 1, sube = true },
	chispas = { tex = CHISPA, color = "ffb347", color2 = "ffe08a", tam = 0.3, vel = { 0.5, 2 }, vida = 6, tasa = 40, brillo = 1, sube = true },
	luciernagas = { tex = CHISPA, color = "e6ff8c", tam = 0.3, vel = { 0.2, 0.8 }, vida = 8, tasa = 30, brillo = 1 },
}

local function clima(nombres: { string })
	local baja = Ajustes.valores.calidadBaja
	local cajas = {}
	for _, n in nombres do
		local d = CLIMAS[n]
		local caja = crear("Part", {
			Name = "Clima_" .. n, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1,
			Size = if d.arriba then Vector3.new(160, 1, 160) else Vector3.new(140, 40, 140),
		}, workspace)
		local e = Instance.new("ParticleEmitter")
		e.Texture = d.tex
		e.Color = ColorSequence.new(c(d.color), c(d.color2 or d.color))
		e.LightEmission = d.brillo or 0
		e.Size = NumberSequence.new(d.tam)
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, d.transp or 0), NumberSequenceKeypoint.new(0.85, d.transp or 0), NumberSequenceKeypoint.new(1, 1) })
		if d.estirar then
			e.Squash = NumberSequence.new(d.estirar)
		end
		e.Lifetime = NumberRange.new(d.vida * 0.7, d.vida)
		e.Speed = NumberRange.new(d.vel[1], d.vel[2])
		e.Rate = if baja then math.floor(d.tasa / 5) else d.tasa
		e.EmissionDirection = if d.arriba then Enum.NormalId.Bottom elseif d.sube then Enum.NormalId.Top else Enum.NormalId.Top
		e.SpreadAngle = if d.arriba then Vector2.new(8, 8) else Vector2.new(180, 180)
		e.Acceleration = d.viento or Vector3.zero
		if d.paralelo then
			e.Orientation = Enum.ParticleOrientation.VelocityParallel
		end
		if d.giro then
			e.RotSpeed = NumberRange.new(-d.giro, d.giro)
			e.Rotation = NumberRange.new(0, 360)
		end
		e.Parent = caja
		table.insert(cajas, { caja = caja, arriba = d.arriba })
	end
	table.insert(conexiones, RunService.RenderStepped:Connect(function()
		local p = camara.CFrame.Position
		for _, x in cajas do
			x.caja.CFrame = CFrame.new(p + Vector3.new(0, if x.arriba then 40 else 0, 0))
		end
	end))
end

-- Tormenta: cada tanto un relámpago lejos, la pantalla se aclara un instante.
local function tormenta(correccion: ColorCorrectionEffect)
	local vivo = true
	table.insert(conexiones, { Disconnect = function()
		vivo = false
	end })
	task.spawn(function()
		while vivo do
			task.wait(5 + math.random() * 8)
			if not vivo then
				break
			end
			local base = correccion.Brightness
			correccion.Brightness = base + 0.45
			TweenService:Create(correccion, TweenInfo.new(0.35), { Brightness = base }):Play()
			-- El rayo: zigzag de neón a lo lejos.
			local dir = camara.CFrame.LookVector * Vector3.new(1, 0, 1)
			dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.new(0, 0, -1)
			local lejos = camara.CFrame.Position + dir * (150 + math.random() * 80) + Vector3.new(math.random(-80, 80), 0, 0)
			local anterior = lejos + Vector3.new(0, 140, 0)
			for i = 1, 8 do
				local punto = lejos + Vector3.new(math.random(-12, 12), 140 - i * 18, math.random(-12, 12))
				local l = (punto - anterior).Magnitude
				local p = crear("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.Neon, Color = c("e6f0ff"), Size = Vector3.new(1, 1, l), CFrame = CFrame.lookAt(anterior, punto) * CFrame.new(0, 0, -l / 2) }, workspace)
				TweenService:Create(p, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				task.delay(0.3, p.Destroy, p)
				anterior = punto
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Decorado vivo: fuego, humo y luces que titilan
--------------------------------------------------------------------------------
local function parteMasAlta(m: Model): BasePart?
	local alta, y = nil, -math.huge
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Position.Y + d.Size.Y / 2 > y then
			alta, y = d, d.Position.Y + d.Size.Y / 2
		end
	end
	return alta
end

local function decorar(mapa: Model, a)
	local baja = Ajustes.valores.calidadBaja
	-- El decorado llega por partes (streaming): se procesa lo que hay y lo que va llegando.
	local deco = mapa:WaitForChild("Decorado", 20)
	if not deco then
		return
	end
	local fuegos, humos = 0, 0
	local function pieza(m: Instance)
		if not m:IsA("Model") or m:GetAttribute("Ambientado") then
			return
		end
		if a.fuego and table.find(a.fuego, m.Name) and fuegos < 40 then
			local p = parteMasAlta(m)
			if p then
				fuegos += 1
				m:SetAttribute("Ambientado", true)
				local col = c(a.fuegoColor or "ff8a2a")
				crear("Fire", { Color = col, SecondaryColor = col:Lerp(Color3.new(1, 1, 0.6), 0.5), Size = 2.5, Heat = 6 }, p)
			end
		elseif a.humo and table.find(a.humo, m.Name) and humos < 14 and not baja then
			local p = parteMasAlta(m)
			if p then
				humos += 1
				m:SetAttribute("Ambientado", true)
				crear("Smoke", { Color = c("6a6a6a"), Opacity = 0.18, RiseVelocity = 5, Size = 6 }, p)
			end
		end
	end
	for _, m in deco:GetChildren() do
		pieza(m)
	end
	-- Las partes de cada pieza también llegan después que el modelo.
	table.insert(conexiones, deco.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			local m = d
			while m.Parent and m.Parent ~= deco do
				m = m.Parent
			end
			pieza(m)
		end
	end))

	-- Luces: las cálidas titilan apenas, el neón parpadea de vez en cuando y la emergencia prende y apaga.
	local luces = {}
	local function luz(l: Instance)
		if (l:IsA("PointLight") or l:IsA("SpotLight")) and #luces < 50 then
			if a.luces == "emergencia" then
				l.Color = c("ff3030")
			end
			table.insert(luces, { luz = l, base = l.Brightness, fase = math.random() * 100 })
		end
	end
	for _, l in mapa:GetDescendants() do
		luz(l)
	end
	table.insert(conexiones, mapa.DescendantAdded:Connect(luz))
	table.insert(conexiones, RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, x in luces do
			local f
			if a.luces == "emergencia" then
				f = if (t * 1.2 + x.fase) % 2 < 1 then 1.4 else 0.15
			elseif a.luces == "neon" then
				f = if math.noise(t * 3, x.fase) > 0.42 then 0.2 else 1
			else
				f = 0.85 + math.noise(t * 4, x.fase) * 0.3
			end
			x.luz.Brightness = x.base * f
		end
	end))
end

--------------------------------------------------------------------------------
-- Cielo: pájaros, Quinjet, naves, dragón y pterodáctilos
--------------------------------------------------------------------------------
local function bandada(centro: Vector3, n: number, color: Color3, radio: number, alto: number)
	local pajaros = {}
	for i = 1, n do
		local cuerpo = crear("Model", { Name = "Pajaro" }, workspace)
		local alas = {}
		for lado = -1, 1, 2 do
			local ala = Instance.new("Part")
			ala.Anchored, ala.CanCollide, ala.CanQuery, ala.CanTouch, ala.CastShadow = true, false, false, false, false
			ala.Size = Vector3.new(1.6, 0.1, 0.7)
			ala.Color = color
			ala.Parent = cuerpo
			table.insert(alas, { p = ala, lado = lado })
		end
		table.insert(pajaros, { alas = alas, desfase = Vector3.new(math.random(-6, 6), math.random(-2, 2), math.random(-6, 6)), fase = math.random() * 10 })
	end
	local giro = math.random() * math.pi * 2
	table.insert(conexiones, RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local a = giro + t / 30 * math.pi * 2
		local lider = centro + Vector3.new(math.cos(a) * radio, alto, math.sin(a) * radio)
		local adelante = Vector3.new(-math.sin(a), 0, math.cos(a))
		for _, b in pajaros do
			local pos = lider + b.desfase
			local base = CFrame.lookAt(pos, pos + adelante)
			local aleteo = math.sin(t * 9 + b.fase) * 0.6
			for _, ala in b.alas do
				ala.p.CFrame = base * CFrame.Angles(0, 0, ala.lado * aleteo) * CFrame.new(ala.lado * 0.8, 0, 0)
			end
		end
	end))
end

-- Un modelo que da vueltas alrededor del mapa (o lo cruza ida y vuelta si `cruza`).
local function volador(plantilla: Model?, centro: Vector3, radio: number, alto: number, vuelta: number, largo: number, cruza: boolean?)
	if not plantilla then
		return
	end
	local m = plantilla:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false
		end
	end
	m:ScaleTo(m:GetScale() * largo / math.max(m:GetExtentsSize().X, m:GetExtentsSize().Z))
	m.Parent = workspace
	table.insert(propios, m)
	local inicio = math.random() * vuelta
	table.insert(conexiones, RunService.RenderStepped:Connect(function()
		local t = os.clock() + inicio
		local pos, adelante
		if cruza then
			local k = (t % vuelta) / vuelta
			local x = -radio + k * radio * 2
			pos = centro + Vector3.new(x, alto + math.sin(t) * 2, -radio * 0.7) -- por el fondo, lejos de la cámara
			adelante = Vector3.new(1, 0, 0)
		else
			local a = t / vuelta * math.pi * 2
			pos = centro + Vector3.new(math.cos(a) * radio, alto + math.sin(t * 0.7) * 3, math.sin(a) * radio)
			adelante = Vector3.new(-math.sin(a), 0, math.cos(a))
		end
		m:PivotTo(CFrame.lookAt(pos, pos + adelante) * CFrame.Angles(0, 0, math.rad(-10)))
	end))
end

local function cielo3d(lista: { string }, centro: Vector3)
	local reserva = ReplicatedStorage:FindFirstChild("Cielo") -- modelos generados (se guardan en el lugar)
	local function modelo(nombre)
		return reserva and reserva:FindFirstChild(nombre)
	end
	for _, n in lista do
		if n == "pajaros" then
			bandada(centro, 6, c("2a2a2a"), 90, 45)
			bandada(centro, 4, c("3a3030"), 120, 60)
		elseif n == "quinjet" then
			volador(modelo("quinjet"), centro, 150, 70, 35, 30)
		elseif n == "nave" then
			volador(modelo("nave"), centro, 220, 95, 22, 26, true)
			volador(modelo("nave"), centro + Vector3.new(0, 25, -60), 240, 80, 30, 18, true)
		elseif n == "dragon" then
			volador(modelo("dragon"), centro, 140, 75, 28, 40)
		elseif n == "pterodactilo" then
			volador(modelo("pterodactilo"), centro, 110, 50, 20, 14)
			volador(modelo("pterodactilo"), centro + Vector3.new(20, 10, 0), 130, 55, 26, 12)
		end
	end
end

--------------------------------------------------------------------------------
-- Paneo del recorrido al entrar a una partida
--------------------------------------------------------------------------------
local pantalla = Comic.crear("ScreenGui", { Name = "Paneo", ResetOnSpawn = false, DisplayOrder = 7, IgnoreGuiInset = true, Enabled = false }, jugador:WaitForChild("PlayerGui"))
local titulo = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.1, 0), Size = UDim2.fromOffset(620, 110), BackgroundColor3 = Comic.ROJO, Rotation = -2 }, pantalla)
Comic.borde(titulo, 6)
local escalaTitulo = Comic.crear("UIScale", {}, titulo)
local nombreMapa = Comic.texto({ Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -32, 0, 66), TextColor3 = Comic.AMARILLO }, titulo)
local subMapa = Comic.texto({ Position = UDim2.fromOffset(16, 70), Size = UDim2.new(1, -32, 0, 30), Font = Comic.TEXTO, TextSize = 20 }, titulo)
Comic.texto({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 10), Size = UDim2.fromOffset(400, 28), Font = Comic.TEXTO, TextSize = 20, Text = "Clic para saltar" }, titulo)

local function paneo(estado: Instance, nivel)
	local origen = estado:GetAttribute("Origen")
	local ruta = Mapa.rutasPixeles(nivel)[1]
	if not origen or not ruta or #ruta < 2 then
		return
	end
	local puntos = {}
	for _, p in ruta do
		table.insert(puntos, Mapa.aMundo(p.x, p.y, origen))
	end
	-- Largo total para recorrerlo a velocidad pareja.
	local tramos, total = {}, 0
	for i = 1, #puntos - 1 do
		local l = (puntos[i + 1] - puntos[i]).Magnitude
		table.insert(tramos, l)
		total += l
	end
	local function puntoEn(d: number): (Vector3, Vector3)
		for i, l in tramos do
			if d <= l or i == #tramos then
				local k = math.clamp(d / l, 0, 1)
				return puntos[i]:Lerp(puntos[i + 1], k), (puntos[i + 1] - puntos[i]).Unit
			end
			d -= l
		end
		return puntos[#puntos], Vector3.new(0, 0, 1)
	end
	nombreMapa.Text = string.upper(estado:GetAttribute("NombreNivel") or "")
	local acto = estado:GetAttribute("Acto")
	subMapa.Text = if acto == "infinito" then "Modo infinito" elseif acto == "raid" then "Raid" elseif acto then `Acto {acto}` else ""
	escalaTitulo.Scale = math.clamp(camara.ViewportSize.X / 1280, 0.55, 1.2)
	pantalla.Enabled = true
	local anterior = camara.CameraType
	camara.CameraType = Enum.CameraType.Scriptable
	local DURACION = 3.6
	local inicio = os.clock()
	local suave = nil
	local terminado = false
	local con, clic
	local function terminar()
		if terminado then
			return
		end
		terminado = true
		con:Disconnect()
		clic:Disconnect()
		pantalla.Enabled = false
		camara.CameraType = anterior
	end
	clic = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			terminar()
		end
	end)
	con = RunService.RenderStepped:Connect(function(dt)
		local k = (os.clock() - inicio) / DURACION
		if k >= 1 or not jugador:GetAttribute("Partida") then
			terminar()
			return
		end
		local e = k * k * (3 - 2 * k) -- suave al empezar y al terminar
		local p, dir = puntoEn(e * total)
		local objetivo = CFrame.lookAt(p - dir * 30 + Vector3.new(0, 26, 0), p + dir * 20)
		suave = if suave then suave:Lerp(objetivo, math.min(1, dt * 4)) else objetivo
		camara.CFrame = suave
	end)
	table.insert(conexiones, { Disconnect = terminar })
end

--------------------------------------------------------------------------------
-- Entrar y salir de las partidas
--------------------------------------------------------------------------------
local function nivelDe(id: string)
	for _, n in (niveles.levels or niveles) do
		if n.id == id then
			return n
		end
	end
	return nil
end

local partidaActual = nil
local function aplicar()
	local id = jugador:GetAttribute("Partida")
	if id == partidaActual then
		return
	end
	restaurar()
	partidaActual = id
	if not id then
		return
	end
	local estado = ReplicatedStorage:WaitForChild("Partidas"):WaitForChild(id, 20)
	local carpeta = workspace:WaitForChild("Partidas"):WaitForChild("Partida_" .. id, 20)
	if not estado or not carpeta or jugador:GetAttribute("Partida") ~= id then
		return
	end
	local nivelId = estado:GetAttribute("Nivel")
	local a = AMBIENTES[nivelId]
	local nivel = nivelDe(nivelId)
	if not a or not nivel then
		return
	end
	local baja = Ajustes.valores.calidadBaja
	guardar()

	-- Luz
	Lighting.ClockTime = a.hora
	Lighting.Brightness = a.luz
	Lighting.Ambient = c(a.amb)
	Lighting.OutdoorAmbient = c(a.ext)
	Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.6, 0.6
	for _, x in Lighting:GetChildren() do
		if x:IsA("Atmosphere") or x:IsA("PostEffect") or (x:IsA("Sky") and a.cielo ~= "hub") then
			sacar(x)
		end
	end
	local n = a.niebla
	crear("Atmosphere", { Density = n[1], Color = c(n[2]), Decay = c(n[3]), Haze = n[4], Glare = n[5], Offset = 0.15 }, Lighting)
	local correccion = crear("ColorCorrectionEffect", { TintColor = c(a.tinte), Saturation = a.sat, Contrast = a.contraste, Brightness = 0.02 }, Lighting)
	if not baja then
		crear("BloomEffect", { Intensity = a.bloom, Size = 28, Threshold = 0.92 }, Lighting)
		if a.rayos > 0 then
			crear("SunRaysEffect", { Intensity = a.rayos, Spread = 0.6 }, Lighting)
		end
	end
	if a.cielo == "noche" then
		crear("Sky", { StarCount = a.estrellas or 3000, CelestialBodiesShown = true, MoonAngularSize = 14 }, Lighting)
	elseif a.cielo == "nublado" then
		crear("Sky", { StarCount = 0, CelestialBodiesShown = false }, Lighting)
	end

	-- Agua
	if a.agua then
		terreno.WaterColor = c(a.agua[1])
		terreno.WaterWaveSize = a.agua[2]
		terreno.WaterWaveSpeed = a.agua[3]
		terreno.WaterReflectance = 0.35
		terreno.WaterTransparency = 0.4
	end

	-- Clima y tormenta
	if a.clima then
		clima(a.clima)
	end
	if a.tormenta then
		tormenta(correccion)
	end

	-- Decorado vivo y cielo (cuando el mapa termine de armarse)
	local centro = Mapa.aMundo(400, 300, estado:GetAttribute("Origen"))
	task.spawn(function()
		local mapa = carpeta:WaitForChild("Mapa", 20)
		if mapa and partidaActual == id then
			decorar(mapa, a)
		end
	end)
	if a.cielo3d then
		cielo3d(a.cielo3d, centro)
	end
	if estado:GetAttribute("Oleada") == 0 or estado:GetAttribute("Oleada") == nil then
		task.defer(paneo, estado, nivel)
	end
end

jugador:GetAttributeChangedSignal("Partida"):Connect(aplicar)
task.defer(aplicar)
