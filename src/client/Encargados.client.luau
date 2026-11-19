-- Encargados que hablan (docs/LOBBY.md, fase D): al acercarte a un encargado del lobby te saluda con la mano y un
-- globo de diálogo con un saludo de personaje y algo útil de su estación (misiones listas, destacado del banner,
-- el próximo acto de la historia…). Sólo local: cada jugador ve su globo y su saludo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Personajes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personajes"))

local jugador = Players.LocalPlayer
local SALUDO = "rbxassetid://90119581918130" -- saludo con la mano (IA de Roblox, 2 s)
local DISTANCIA = 24 -- studs (el lobby está ×2)
local DURACION = 7

local coleccion = ReplicatedStorage:WaitForChild("Coleccion")
local temporada = ReplicatedStorage:WaitForChild("Temporada")
local sala = ReplicatedStorage:WaitForChild("Sala")

local function nombreDe(id: string?): string
	local h = id and Personajes.todos[id]
	return if h then h.name else "?"
end

-- Dato útil de cada estación (puede consultar al servidor; si falla, queda sólo el saludo).
local DATOS = {
	misiones = function()
		local ok, res = pcall(temporada.InvokeServer, temporada, "estado")
		if not ok or not res or not res.diarias then
			return nil
		end
		local listas, faltan = 0, 0
		for _, lista in { res.diarias, res.semanales or {} } do
			for _, m in lista do
				if not m.reclamada and m.progreso >= m.meta then
					listas += 1
				elseif not m.reclamada then
					faltan += 1
				end
			end
		end
		if listas > 0 then
			return `Tenés {listas} {if listas == 1 then "misión lista" else "misiones listas"} para reclamar.`
		end
		return `Te quedan {faltan} misiones por cumplir.`
	end,
	summon = function()
		local ok, res = pcall(coleccion.InvokeServer, coleccion, "estado")
		local b = ok and res and res.estado and res.estado.banner
		if not b then
			return nil
		end
		return `El destacado de esta hora es {nombreDe(b.destacados.estrella)}.`
	end,
	story = function()
		local ok, res = pcall(sala.InvokeServer, sala, "estado")
		if not ok or not res or not res.historia then
			return nil
		end
		for _, mapa in res.historia do
			if mapa.abierto then
				for _, a in mapa.actos do
					if a.abierto and not a.ganado then
						return `Te falta el acto {a.numero} de {mapa.nombre}.`
					end
				end
			end
		end
		return "Ganaste todos los actos abiertos. ¡Probá la Pesadilla!"
	end,
	pets = function()
		local g = jugador:GetAttribute("Gemas")
		return if g then `Tenés {g} gemas. ¿Un huevo? Te prometo que no explota.` else nil
	end,
}

-- Saludo de cada personaje (por id de héroe).
local FRASES = {
	nick_fury = "Agente. S.H.I.E.L.D. tiene trabajo para vos.",
	star_lord = "¿Un pasito? Elegí tu baile en la rueda (tecla B).",
	korg = "¡Hola! Soy Korg. El desafío de esta semana te espera.",
	valkyrie = "Sólo los mejores llegan al Top 10. ¿Vas a intentarlo?",
	ghost_rider = "Subite a una montura y recorré el lobby más rápido (tecla G).",
	heimdall = "Lo veo todo desde acá.",
	shuri = "Traé a tus héroes y les busco un rasgo mejor.",
	mbaku = "¡La forja está caliente! Subí los grados de tus unidades.",
	rocket_raccoon = "¿Qué mirás? ¿Venís por una mascota?",
	capitan_america = "La raid de esta semana necesita un equipo. ¿Estás listo?",
	maria_hill = "Las misiones de raid dan fragmentos para los exclusivos.",
	spiderman = "¡Hola, vecino! Tengo objetos nuevos en la tienda.",
	mister_fantastic = "Las oleadas sin fin ponen a prueba cualquier estrategia. Parate en una plataforma.",
	wong = "Bienvenido al Sanctum. Parate en una plataforma para empezar.",
	doctor_strange = "Vi 14.000.605 futuros. En uno de ellos, ganás.",
	invisible_woman = "Bienvenido al laboratorio. No toques nada que brille.",
	human_torch = "¡Llamas a la orden!",
	black_widow = "El campo de pruebas está abierto: probá cualquier héroe con créditos infinitos.",
}

-- Globo de diálogo sobre la cabeza.
local function globo(m: Model, texto: string)
	local cabeza = m:FindFirstChild("Head") or m:FindFirstChild("HumanoidRootPart")
	if not cabeza then
		return
	end
	local viejo = cabeza:FindFirstChild("Dialogo")
	if viejo then
		viejo:Destroy()
	end
	local b = Instance.new("BillboardGui")
	b.Name = "Dialogo"
	b.Size = UDim2.fromOffset(280, 90)
	b.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	b.MaxDistance = 80
	b.AlwaysOnTop = true
	b.LightInfluence = 0
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 1)
	f.Position = UDim2.fromScale(0.5, 1)
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
	f.BackgroundTransparency = 0.1
	f.Parent = b
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
	local borde = Instance.new("UIStroke")
	borde.Color, borde.Transparency = Color3.fromRGB(96, 104, 128), 0.3
	borde.Parent = f
	local t = Instance.new("TextLabel")
	t.Position = UDim2.fromOffset(12, 8)
	t.Size = UDim2.new(1, -24, 1, -16)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 15
	t.TextWrapped = true
	t.TextColor3 = Color3.fromRGB(236, 240, 248)
	t.RichText = true
	t.Text = texto
	t.Parent = f
	local escala = Instance.new("UIScale")
	escala.Scale = 0.2
	escala.Parent = f
	b.Parent = cabeza
	TweenService:Create(escala, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(DURACION, function()
		if b.Parent then
			TweenService:Create(escala, TweenInfo.new(0.2), { Scale = 0 }):Play()
			task.wait(0.2)
			b:Destroy()
		end
	end)
end

local function saludar(m: Model)
	local hum = m:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator then
		local a = Instance.new("Animation")
		a.AnimationId = SALUDO
		local ok, pista = pcall(animator.LoadAnimation, animator, a)
		if ok then
			pista.Priority = Enum.AnimationPriority.Action
			pista.Looped = false
			pista:Play(0.15)
		end
	end
end

local cerca = {} -- [Model] = true mientras el jugador está cerca (saluda una vez por acercamiento)
local function hablar(m: Model)
	saludar(m)
	local id = m:GetAttribute("Heroe")
	local estacion = m.Parent and string.match(m.Parent.Name, "^Estacion_(.+)$")
	local frase = FRASES[id] or "¡Hola!"
	local nombre = nombreDe(id)
	globo(m, `<font color="#e22634">{string.upper(nombre)}</font>\n{frase}`)
	local dato = estacion and DATOS[estacion]
	if dato then
		task.spawn(function()
			local ok, extra = pcall(dato)
			if ok and extra and cerca[m] then
				globo(m, `<font color="#e22634">{string.upper(nombre)}</font>\n{frase}\n<font color="#ffc848">{extra}</font>`)
			end
		end)
	end
end

-- Lista de encargados (se arma una vez y se completa con los que llegan por streaming).
local encargados = {}
local function anotar(d: Instance)
	if d.Name == "Encargado" and d:IsA("Model") and not table.find(encargados, d) then
		table.insert(encargados, d)
	end
end
task.spawn(function()
	local hub = workspace:WaitForChild("Hub", 60)
	if not hub then
		return
	end
	for _, d in hub:GetDescendants() do
		anotar(d)
	end
	hub.DescendantAdded:Connect(anotar)
end)

local acumulado = 0
RunService.Heartbeat:Connect(function(dt)
	acumulado += dt
	if acumulado < 0.3 then
		return
	end
	acumulado = 0
	local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
	if not raiz or jugador:GetAttribute("Partida") then
		return
	end
	for _, d in encargados do
		local r = d.Parent and d:GetAttribute("Heroe") and d:FindFirstChild("HumanoidRootPart")
		local dentro = r and (r.Position - raiz.Position).Magnitude < DISTANCIA
		if dentro and not cerca[d] then
			cerca[d] = true
			hablar(d)
		elseif not dentro and cerca[d] then
			cerca[d] = nil
		end
	end
end)
