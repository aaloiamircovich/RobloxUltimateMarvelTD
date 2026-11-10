-- Partida de campaña en Base Avengers: mapa, oleadas del 2D y un Hawkeye fijo que dispara.
-- shortcut: torre fija y equipo de un solo héroe; falta colocar/mejorar héroes desde el cliente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Data = Shared.Data
local Oleadas = require(Shared.Oleadas)
local Arco = require(Shared.Modelos.Arco)
local Mapa = require(script.Parent.Mapa)

local heroes = require(Data.heroes)
local enemigosDatos = require(Data.enemies)
local niveles = require(Data.levels)
local tablaTipos = require(Data.TypeChart)

local NIVEL, INDICE_NIVEL = niveles[1], 0
local VIDAS_INICIALES, CREDITOS_INICIALES = 20, 650 -- ResourceManager del 2D

-- Estado visible para los clientes.
local estado = Instance.new("Folder")
estado.Name = "Estado"
estado.Parent = ReplicatedStorage
local function fijar(nombre, valor)
	estado:SetAttribute(nombre, valor)
end
fijar("Vidas", VIDAS_INICIALES)
fijar("Creditos", CREDITOS_INICIALES)
fijar("Oleada", 0)
fijar("Mensaje", "Preparando la Base Avengers…")

local ruta = Mapa.construir(NIVEL)
local largoTramo, largoTotal = {}, 0
for i = 1, #ruta - 1 do
	largoTramo[i] = (ruta[i + 1] - ruta[i]).Magnitude
	largoTotal += largoTramo[i]
end

local function puntoEnRuta(distancia: number): Vector3
	for i, largo in largoTramo do
		if distancia <= largo then
			return ruta[i]:Lerp(ruta[i + 1], distancia / largo)
		end
		distancia -= largo
	end
	return ruta[#ruta]
end

--------------------------------------------------------------------------------
-- Enemigos
--------------------------------------------------------------------------------
local COLORES = {
	["Tecnológico"] = Color3.fromRGB(120, 140, 170),
	["Místico"] = Color3.fromRGB(170, 90, 200),
	["Mutante"] = Color3.fromRGB(220, 170, 50),
	["Cósmico"] = Color3.fromRGB(70, 60, 160),
	["Urbano"] = Color3.fromRGB(170, 60, 60),
}

local enemigos = {}
local carpetaEnemigos = Instance.new("Folder")
carpetaEnemigos.Name = "Enemigos"
carpetaEnemigos.Parent = workspace

local function crearEnemigo(config)
	local tam = if config.isBoss then 4 elseif config.isElite then 2.6 else 2
	local cuerpo = Instance.new("Part")
	cuerpo.Name = config.id
	cuerpo.Anchored, cuerpo.CanCollide = true, false
	cuerpo.Size = Vector3.new(tam, tam, tam)
	cuerpo.Color = COLORES[config.category] or Color3.new(0.5, 0.5, 0.5)
	cuerpo.Material = if config.stealth then Enum.Material.ForceField else Enum.Material.SmoothPlastic

	local cartel = Instance.new("BillboardGui")
	cartel.Size = UDim2.fromOffset(70, 22)
	cartel.StudsOffset = Vector3.new(0, tam / 2 + 1, 0)
	cartel.AlwaysOnTop = true
	local nombre = Instance.new("TextLabel")
	nombre.Size = UDim2.new(1, 0, 0, 12)
	nombre.BackgroundTransparency = 1
	nombre.TextScaled = true
	nombre.TextColor3 = Color3.new(1, 1, 1)
	nombre.TextStrokeTransparency = 0.3
	nombre.Text = config.name
	nombre.Parent = cartel
	local fondo = Instance.new("Frame")
	fondo.Position = UDim2.fromOffset(0, 14)
	fondo.Size = UDim2.new(1, 0, 0, 6)
	fondo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	fondo.Parent = cartel
	local barra = Instance.new("Frame")
	barra.Size = UDim2.fromScale(1, 1)
	barra.BackgroundColor3 = Color3.fromRGB(80, 220, 90)
	barra.BorderSizePixel = 0
	barra.Parent = fondo
	cartel.Parent = cuerpo

	local e = {
		config = config,
		vida = config.hp,
		barrera = math.floor(config.hp * (config.barrierRatio or 0) + 0.5),
		avance = 0,
		altura = if config.flying then 4 else tam / 2,
		cuerpo = cuerpo,
		barra = barra,
	}
	cuerpo.Position = puntoEnRuta(0) + Vector3.new(0, e.altura, 0)
	cuerpo.Parent = carpetaEnemigos
	table.insert(enemigos, e)
	return e
end

local function quitarEnemigo(e)
	local i = table.find(enemigos, e)
	if i then
		table.remove(enemigos, i)
	end
	e.cuerpo:Destroy()
end

-- Daño como Enemy.takeDamage del 2D: armadura (tope 0.85) y después barrera.
-- shortcut: sin resistencias de estado, penetración ni recarga de barrera de escudos.
local function danar(e, cantidad: number, tipoAtacante: string)
	local mult = (tablaTipos[tipoAtacante] or {})[e.config.category] or 1
	local armadura = math.clamp(e.config.armor or 0, 0, 0.85)
	local dano = math.max(1, cantidad * mult * (1 - armadura))
	local absorbido = math.min(e.barrera, dano)
	e.barrera -= absorbido
	e.vida -= dano - absorbido
	e.barra.Size = UDim2.fromScale(math.max(0, e.vida / e.config.hp), 1)
	if e.vida <= 0 then
		fijar("Creditos", estado:GetAttribute("Creditos") + (e.config.reward or 0))
		quitarEnemigo(e)
	end
end

--------------------------------------------------------------------------------
-- Torre: Hawkeye
--------------------------------------------------------------------------------
local torres = {}

local function crearTorre(heroeId: string, xPx: number, yPx: number)
	local config = heroes[heroeId]
	local plantillas = ServerStorage:FindFirstChild("Plantillas")
	local plantilla = plantillas and plantillas:FindFirstChild("Arquero")
	if not plantilla then
		warn("[UMTD] Falta ServerStorage.Plantillas.Arquero; no se coloca la torre")
		return
	end
	local modelo = plantilla:Clone()
	modelo.Name = config.name
	if not modelo:FindFirstChild("Arco") then
		Arco.equipar(modelo)
	end
	local raiz = modelo:FindFirstChild("HumanoidRootPart") :: BasePart
	raiz.Anchored = true
	local pos = Mapa.aMundo(xPx, yPx)
	modelo:PivotTo(CFrame.new(pos + Vector3.new(0, modelo.Humanoid.HipHeight + raiz.Size.Y / 2, 0)))
	modelo.Parent = workspace

	local animator = modelo.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", modelo.Humanoid)
	local anim = Instance.new("Animation")
	anim.AnimationId = Arco.ANIMACION_DISPARO
	table.insert(torres, {
		config = config,
		modelo = modelo,
		raiz = raiz,
		alcance = config.range * Mapa.ESCALA,
		espera = 0,
		disparo = animator:LoadAnimation(anim),
	})
end

local function flecha(desde: Vector3, hasta: Vector3)
	local f = Instance.new("Part")
	f.Anchored, f.CanCollide, f.CanQuery = true, false, false
	f.Size = Vector3.new(0.15, 0.15, 1.6)
	f.Color = Color3.fromRGB(150, 80, 230)
	f.Material = Enum.Material.Neon
	f.CFrame = CFrame.lookAt(desde, hasta)
	f.Parent = workspace
	local t = TweenService:Create(f, TweenInfo.new(0.12, Enum.EasingStyle.Linear), { CFrame = CFrame.lookAt(hasta, hasta + (hasta - desde)) })
	t.Completed:Once(function()
		f:Destroy()
	end)
	t:Play()
end

local function actualizarTorre(t, dt)
	t.espera -= dt
	if t.espera > 0 then
		return
	end
	-- Prioridad "Primero": el enemigo más avanzado dentro del alcance (en el plano del suelo).
	local objetivo
	for _, e in enemigos do
		local d = (e.cuerpo.Position - t.raiz.Position) * Vector3.new(1, 0, 1)
		local visible = not e.config.stealth or t.config.canSeeStealth
		if visible and d.Magnitude <= t.alcance and (not objetivo or e.avance > objetivo.avance) then
			objetivo = e
		end
	end
	if not objetivo then
		return
	end
	t.espera = 1 / t.config.fireRate
	local destino = objetivo.cuerpo.Position
	t.modelo:PivotTo(CFrame.lookAt(t.raiz.Position, Vector3.new(destino.X, t.raiz.Position.Y, destino.Z)))
	t.disparo:Play(0.05, 1, 2)
	flecha(t.raiz.Position + Vector3.new(0, 1, 0), destino)
	danar(objetivo, t.config.damage, t.config.category)
end

--------------------------------------------------------------------------------
-- Bucle
--------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	for i = #enemigos, 1, -1 do
		local e = enemigos[i]
		e.avance += e.config.speed * Mapa.ESCALA * dt
		if e.avance >= largoTotal then
			-- Como el 2D: un jefe que llega al final se lleva todas las vidas.
			local perdida = if e.config.isBoss then estado:GetAttribute("Vidas") else 1
			fijar("Vidas", math.max(0, estado:GetAttribute("Vidas") - perdida))
			quitarEnemigo(e)
		else
			e.cuerpo.Position = puntoEnRuta(e.avance) + Vector3.new(0, e.altura, 0)
		end
	end
	for _, t in torres do
		actualizarTorre(t, dt)
	end
end)

crearTorre("hawkeye", 304, 272)
local equipo = {}
for _, t in torres do
	table.insert(equipo, t.config)
end

for oleada = 1, Oleadas.MAX_OLEADAS do
	local cola, mod = Oleadas.preparar(oleada, enemigosDatos, NIVEL, INDICE_NIVEL, equipo)
	fijar("Oleada", oleada)
	for s = 5, 1, -1 do
		fijar("Mensaje", `Oleada {oleada}: {mod.nombre} — empieza en {s}`)
		task.wait(1)
	end
	fijar("Mensaje", `Oleada {oleada}: {mod.nombre}`)
	for _, entrada in cola do
		task.wait(entrada.espera)
		if estado:GetAttribute("Vidas") <= 0 then
			break
		end
		crearEnemigo(entrada.enemigo)
	end
	while #enemigos > 0 and estado:GetAttribute("Vidas") > 0 do
		task.wait(0.2)
	end
	if estado:GetAttribute("Vidas") <= 0 then
		fijar("Mensaje", `Derrota en la oleada {oleada}`)
		return
	end
end
fijar("Mensaje", "¡Victoria! Base Avengers defendida")
