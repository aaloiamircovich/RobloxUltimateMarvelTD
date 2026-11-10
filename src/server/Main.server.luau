-- HUB y partida de campaña en Base Avengers: mapa, oleadas del 2D y héroes que el jugador despliega.
-- Reglas del 3D: despliegue y movimiento gratis, una unidad por héroe, retiro sin reembolso.
-- shortcut: un escuadrón compartido por todos los jugadores; con multijugador, una partida por jugador.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Data = Shared.Data
local Oleadas = require(Shared.Oleadas)
local Despliegue = require(Shared.Despliegue)
local Progresion = require(Shared.Progresion)
local Mapa = require(Shared.Mapa)
local Hub = require(script.Parent.Hub)

local heroes = require(Data.heroes)
local enemigosDatos = require(Data.enemies)
local niveles = require(Data.levels)
local tablaTipos = require(Data.TypeChart)

local NIVEL, INDICE_NIVEL = niveles[1], 0
local VIDAS_INICIALES, CREDITOS_INICIALES = 20, 650 -- ResourceManager del 2D
local ESCUADRON = { "black_widow", "hawkeye", "korg" } -- héroes iniciales del 3D

-- Estado visible para los clientes.
local estado = Instance.new("Folder")
estado.Name = "Estado"
estado:SetAttribute("Escuadron", table.concat(ESCUADRON, ","))
estado.Parent = ReplicatedStorage
local function fijar(nombre, valor)
	estado:SetAttribute(nombre, valor)
end
fijar("Vidas", VIDAS_INICIALES)
fijar("Creditos", CREDITOS_INICIALES)
fijar("Oleada", 0)
fijar("Modo", "hub")
fijar("Fase", "hub")
fijar("Mensaje", "")

local accion = Instance.new("RemoteFunction")
accion.Name = "Accion"
accion.Parent = ReplicatedStorage

local rutaPx = Mapa.rutaPixeles(NIVEL)
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

local function cartel(padre: BasePart, texto: string, alto: number): Frame
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(80, 22)
	gui.StudsOffset = Vector3.new(0, alto, 0)
	gui.AlwaysOnTop = true
	local nombre = Instance.new("TextLabel")
	nombre.Size = UDim2.new(1, 0, 0, 12)
	nombre.BackgroundTransparency = 1
	nombre.TextScaled = true
	nombre.TextColor3 = Color3.new(1, 1, 1)
	nombre.TextStrokeTransparency = 0.3
	nombre.Text = texto
	nombre.Parent = gui
	local fondo = Instance.new("Frame")
	fondo.Position = UDim2.fromOffset(0, 14)
	fondo.Size = UDim2.new(1, 0, 0, 6)
	fondo.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	fondo.Parent = gui
	local barra = Instance.new("Frame")
	barra.Size = UDim2.fromScale(1, 1)
	barra.BackgroundColor3 = Color3.fromRGB(80, 220, 90)
	barra.BorderSizePixel = 0
	barra.Parent = fondo
	gui.Parent = padre
	return barra
end

-- Modelo de ServerStorage.Plantillas.Enemigos/<id> que acompaña al bloque raíz invisible.
-- Sin plantilla, el bloque de color queda visible.
local function vestir(cuerpo: Part, config): (number, Model?)
	local plantillas = ServerStorage:FindFirstChild("Plantillas")
	local carpeta = plantillas and plantillas:FindFirstChild("Enemigos")
	local plantilla = carpeta and carpeta:FindFirstChild((config.id:gsub("_elite$", "")))
	if not plantilla then
		return cuerpo.Size.Y, nil
	end
	local m = plantilla:Clone()
	m:ScaleTo(m:GetScale() * (if config.isBoss then 1.8 elseif config.isElite then 1.3 else 1))
	local tam = m:GetExtentsSize()
	cuerpo.Size = tam
	cuerpo.Transparency = 1
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery = true, false, false
			if config.stealth then
				p.Transparency = math.max(p.Transparency, 0.6)
			end
		end
	end
	m.Parent = cuerpo
	return tam.Y, m
end

-- Mueve la raíz y su modelo (las soldaduras no arrastraban un modelo anclado).
local function moverEnemigo(e, cf: CFrame)
	e.cuerpo.CFrame = cf
	if e.modelo then
		e.modelo:PivotTo(cf)
	end
end

local function crearEnemigo(config)
	local tam = if config.isBoss then 4 elseif config.isElite then 2.6 else 2
	local cuerpo = Instance.new("Part")
	cuerpo.Name = config.id
	cuerpo.Anchored, cuerpo.CanCollide, cuerpo.CanQuery = true, false, false
	cuerpo.Size = Vector3.new(tam, tam, tam)
	cuerpo.Color = COLORES[config.category] or Color3.new(0.5, 0.5, 0.5)
	cuerpo.Material = if config.stealth then Enum.Material.ForceField else Enum.Material.SmoothPlastic
	local modelo
	tam, modelo = vestir(cuerpo, config)
	local e = {
		modelo = modelo,
		config = config,
		vida = config.hp,
		barrera = math.floor(config.hp * (config.barrierRatio or 0) + 0.5),
		avance = 0,
		altura = if config.flying then 4 else tam / 2,
		cuerpo = cuerpo,
		barra = cartel(cuerpo, config.name, tam / 2 + 1),
	}
	moverEnemigo(e, CFrame.new(puntoEnRuta(0) + Vector3.new(0, e.altura, 0)))
	cuerpo.Parent = carpetaEnemigos
	table.insert(enemigos, e)
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
-- Unidades (héroes desplegados)
--------------------------------------------------------------------------------
local unidades = {} -- { uid, heroe, x, y, config, nivel, stats, modelo, raiz, espera, ataque, velocidadAtaque }
local siguienteUid = 1
local carpetaUnidades = Instance.new("Folder")
carpetaUnidades.Name = "Unidades"
carpetaUnidades.Parent = workspace

-- Modelo provisional para héroes que todavía no tienen personaje: un bloque con su nombre.
local function modeloProvisional(config): Model
	local m = Instance.new("Model")
	local cuerpo = Instance.new("Part")
	cuerpo.Name = "HumanoidRootPart"
	cuerpo.Size = Vector3.new(2, 4, 2)
	cuerpo.Color = COLORES[config.category] or Color3.fromRGB(110, 110, 120)
	cuerpo.Parent = m
	m.PrimaryPart = cuerpo
	local barra = cartel(cuerpo, config.name, 3)
	barra.Parent.Visible = false -- las unidades no tienen barra de vida
	return m
end

-- Plantilla de ServerStorage.Plantillas.Heroes/<id>: un R15 con atributos opcionales
-- AnimacionAtaque (rbxassetid) y VelocidadAtaque (número). Sin plantilla, bloque provisional.
local function crearModelo(config): (Model, BasePart, AnimationTrack?, number)
	local plantillas = ServerStorage:FindFirstChild("Plantillas")
	local carpeta = plantillas and plantillas:FindFirstChild("Heroes")
	local plantilla = carpeta and carpeta:FindFirstChild(config.id)
	local modelo = if plantilla then plantilla:Clone() else modeloProvisional(config)
	local raiz = modelo:FindFirstChild("HumanoidRootPart") :: BasePart
	raiz.Anchored = true
	local ataque
	local humanoide = modelo:FindFirstChildOfClass("Humanoid")
	local animacion = modelo:GetAttribute("AnimacionAtaque")
	if humanoide and animacion then
		local animator = humanoide:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoide)
		local anim = Instance.new("Animation")
		anim.AnimationId = animacion
		ataque = animator:LoadAnimation(anim)
	end
	modelo.Name = config.name
	return modelo, raiz, ataque, modelo:GetAttribute("VelocidadAtaque") or 1
end

-- Mueve el modelo para que su raíz quede en `cf`; el pivote de los modelos R15 no coincide con la raíz.
local function ponerRaiz(u, cf: CFrame)
	u.modelo:PivotTo(cf * u.raiz.CFrame:ToObjectSpace(u.modelo:GetPivot()))
end

local function ubicar(u)
	local alto = if u.modelo:FindFirstChildOfClass("Humanoid") then u.modelo.Humanoid.HipHeight + u.raiz.Size.Y / 2 else u.raiz.Size.Y / 2
	-- La celda es pavimento/pasto (1 stud) o hangar (1.2): apoyar sobre la baldosa más alta.
	ponerRaiz(u, CFrame.new(Mapa.aMundo(u.x, u.y) + Vector3.new(0, alto + 0.2, 0)))
end

local function listaUnidades()
	local l = {}
	for _, u in unidades do
		table.insert(l, { uid = u.uid, heroe = u.heroe, x = u.x, y = u.y })
	end
	return l
end

local function buscarUnidad(uid)
	for i, u in unidades do
		if u.uid == uid then
			return u, i
		end
	end
	return nil
end

local ACCIONES = {}

function ACCIONES.colocar(heroeId: string, x: number, y: number)
	if not table.find(ESCUADRON, heroeId) then
		return "Ese héroe no está en tu escuadrón"
	end
	local config = heroes[heroeId]
	local err, cx, cy = Despliegue.error(Progresion.paraDespliegue(config, 1), x, y, NIVEL, rutaPx, listaUnidades())
	if err then
		return err
	end
	local modelo, raiz, ataque, velocidadAtaque = crearModelo(config)
	-- shortcut: el nivel vale sólo para esta partida; en el 3D se guarda en el perfil (falta DataStore).
	local u = { uid = siguienteUid, heroe = heroeId, x = cx, y = cy, config = config, nivel = 1, stats = Progresion.stats(config, 1), modelo = modelo, raiz = raiz, espera = 0, ataque = ataque, velocidadAtaque = velocidadAtaque }
	siguienteUid += 1
	modelo:SetAttribute("Uid", u.uid)
	modelo:SetAttribute("Heroe", heroeId)
	modelo:SetAttribute("Nivel", 1)
	ubicar(u)
	modelo.Parent = carpetaUnidades
	table.insert(unidades, u)
	return nil
end

function ACCIONES.mover(uid: number, x: number, y: number)
	local u = buscarUnidad(uid)
	if not u then
		return "Héroe no disponible"
	end
	local err, cx, cy = Despliegue.error(Progresion.paraDespliegue(u.config, u.nivel), x, y, NIVEL, rutaPx, listaUnidades(), uid)
	if err then
		return err
	end
	u.x, u.y = cx, cy
	ubicar(u)
	return nil
end

function ACCIONES.retirar(uid: number)
	local u, i = buscarUnidad(uid)
	if not u then
		return "Héroe no disponible"
	end
	table.remove(unidades, i)
	u.modelo:Destroy()
	return nil
end

function ACCIONES.mejorar(uid: number)
	local u = buscarUnidad(uid)
	if not u then
		return "Héroe no disponible"
	end
	local costo = Progresion.costo(u.nivel)
	if not costo then
		return "Nivel máximo"
	end
	local creditos = estado:GetAttribute("Creditos")
	if creditos < costo then
		return `Faltan {costo - creditos} créditos`
	end
	local evolucionaba = Progresion.evolucion(u.heroe, u.nivel)
	u.nivel += 1
	u.stats = Progresion.stats(u.config, u.nivel)
	u.modelo:SetAttribute("Nivel", u.nivel) -- antes que los créditos: el cliente refresca al cambiar Estado
	fijar("Creditos", creditos - costo)
	local evo = Progresion.evolucion(u.heroe, u.nivel)
	if evo and not evolucionaba then
		fijar("Mensaje", `¡{u.config.name} evolucionó: {evo.name}!`)
	end
	return nil
end

local iniciarPedido = false
function ACCIONES.iniciar()
	if estado:GetAttribute("Fase") ~= "preparacion" then
		return "La oleada ya está en curso"
	end
	if #unidades == 0 then
		return "Desplegá al menos un héroe"
	end
	iniciarPedido = true
	return nil
end

-- Frontera de confianza: validar tipos antes de tocar el estado.
accion.OnServerInvoke = function(_jugador, nombre, a, b, c)
	local f = ACCIONES[nombre]
	if type(nombre) ~= "string" or not f then
		return "Acción desconocida"
	end
	if nombre ~= "volver" and estado:GetAttribute("Modo") ~= "batalla" then
		return "No hay una misión en curso"
	end
	if nombre ~= "volver" and estado:GetAttribute("Fase") == "fin" then
		return "La misión ya terminó"
	end
	if nombre == "colocar" and not (type(a) == "string" and type(b) == "number" and type(c) == "number") then
		return "Datos inválidos"
	end
	if nombre == "mover" and not (type(a) == "number" and type(b) == "number" and type(c) == "number") then
		return "Datos inválidos"
	end
	if (nombre == "retirar" or nombre == "mejorar") and type(a) ~= "number" then
		return "Datos inválidos"
	end
	for _, v in { a, b, c } do
		if type(v) == "number" and (v ~= v or math.abs(v) == math.huge) then
			return "Datos inválidos"
		end
	end
	return f(a, b, c)
end

--------------------------------------------------------------------------------
-- Ataque de las unidades
--------------------------------------------------------------------------------
local function pieza(tam: Vector3, color: Color3, cf: CFrame): Part
	local f = Instance.new("Part")
	f.Anchored, f.CanCollide, f.CanQuery = true, false, false
	f.Size = tam
	f.Color = color
	f.Material = Enum.Material.Neon
	f.CFrame = cf
	f.Parent = workspace
	return f
end

local function animarYBorrar(f: Part, segundos: number, meta)
	local t = TweenService:Create(f, TweenInfo.new(segundos, Enum.EasingStyle.Quad), meta)
	t.Completed:Once(function()
		f:Destroy()
	end)
	t:Play()
end

-- Efecto visual del ataque según el atributo Efecto de la plantilla del héroe.
local EFECTOS = {
	flecha = function(desde: Vector3, hasta: Vector3)
		local f = pieza(Vector3.new(0.15, 0.15, 1.6), Color3.fromRGB(150, 80, 230), CFrame.lookAt(desde, hasta))
		animarYBorrar(f, 0.12, { CFrame = CFrame.lookAt(hasta, hasta + (hasta - desde)) })
	end,
	rayo = function(desde: Vector3, hasta: Vector3)
		local largo = (hasta - desde).Magnitude
		local f = pieza(Vector3.new(0.2, 0.2, largo), Color3.fromRGB(90, 190, 255), CFrame.lookAt(desde, hasta) * CFrame.new(0, 0, -largo / 2))
		animarYBorrar(f, 0.15, { Transparency = 1, Size = Vector3.new(0.05, 0.05, largo) })
	end,
	impacto = function(_desde: Vector3, hasta: Vector3)
		local f = pieza(Vector3.new(1, 1, 1), Color3.fromRGB(190, 130, 80), CFrame.new(hasta))
		f.Shape = Enum.PartType.Ball
		f.Material = Enum.Material.Slate
		animarYBorrar(f, 0.25, { Transparency = 1, Size = Vector3.new(4, 4, 4) })
	end,
}

local function actualizarUnidad(u, dt)
	u.espera -= dt
	if u.espera > 0 then
		return
	end
	-- Prioridad "Primero": el enemigo más avanzado dentro de la forma de alcance.
	local objetivo
	for _, e in enemigos do
		local ex, ey = Mapa.aPixeles(e.cuerpo.Position)
		local visible = not e.config.stealth or u.stats.canSeeStealth
		if visible and Despliegue.enAlcance(u.x, u.y, ex, ey, u.stats.range, u.config.rangePattern) and (not objetivo or e.avance > objetivo.avance) then
			objetivo = e
		end
	end
	if not objetivo then
		return
	end
	u.espera = 1 / u.stats.fireRate
	local destino = objetivo.cuerpo.Position
	local p = u.raiz.Position
	ponerRaiz(u, CFrame.lookAt(p, Vector3.new(destino.X, p.Y, destino.Z)))
	if u.ataque then
		u.ataque:Play(0.05, 1, u.velocidadAtaque)
	end
	local efecto = EFECTOS[u.modelo:GetAttribute("Efecto")] or EFECTOS.flecha
	efecto(p + Vector3.new(0, 1, 0), destino)
	-- Crítico como Hero.attack del 2D: probabilidad en %, daño ×critDamage.
	local critico = math.random() * 100 < u.stats.critChance
	danar(objetivo, if critico then u.stats.damage * u.stats.critDamage else u.stats.damage, u.config.category)
end

RunService.Heartbeat:Connect(function(dt)
	for i = #enemigos, 1, -1 do
		local e = enemigos[i]
		e.avance += e.config.speed * Mapa.ESCALA * dt
		if e.avance >= largoTotal then
			-- Como el 3D: un jefe que llega al final se lleva todas las vidas.
			local perdida = if e.config.isBoss then estado:GetAttribute("Vidas") else 1
			fijar("Vidas", math.max(0, estado:GetAttribute("Vidas") - perdida))
			quitarEnemigo(e)
		else
			-- Mirar hacia donde avanza (el -Z de la raíz es el frente).
			local aqui = puntoEnRuta(e.avance)
			local adelante = puntoEnRuta(e.avance + 0.5)
			local alto = Vector3.new(0, e.altura, 0)
			moverEnemigo(e, if (adelante - aqui).Magnitude > 1e-3 then CFrame.lookAt(aqui + alto, adelante + alto) else CFrame.new(aqui + alto))
		end
	end
	for _, u in unidades do
		actualizarUnidad(u, dt)
	end
end)

--------------------------------------------------------------------------------
-- Oleadas
--------------------------------------------------------------------------------
-- Cada partida tiene un número; volver al HUB lo cambia y corta el bucle de la anterior.
local partidaActual = 0

local function limpiar()
	for i = #enemigos, 1, -1 do
		quitarEnemigo(enemigos[i])
	end
	for _, u in unidades do
		u.modelo:Destroy()
	end
	table.clear(unidades)
end

local function partida(id: number)
	local function sigue()
		return id == partidaActual
	end
	for oleada = 1, Oleadas.MAX_OLEADAS do
		fijar("Oleada", oleada)
		fijar("Fase", "preparacion")
		fijar("Mensaje", `Oleada {oleada}: desplegá héroes y apretá «Iniciar oleada»`)
		iniciarPedido = false
		repeat
			task.wait(0.1)
		until iniciarPedido or not sigue()
		if not sigue() then
			return
		end

		local equipo = {}
		for _, u in unidades do
			table.insert(equipo, u.config)
		end
		local cola, mod = Oleadas.preparar(oleada, enemigosDatos, NIVEL, INDICE_NIVEL, equipo)
		fijar("Fase", "combate")
		fijar("Mensaje", `Oleada {oleada}: {mod.nombre}`)
		for _, entrada in cola do
			task.wait(entrada.espera)
			if not sigue() or estado:GetAttribute("Vidas") <= 0 then
				break
			end
			crearEnemigo(entrada.enemigo)
		end
		while sigue() and #enemigos > 0 and estado:GetAttribute("Vidas") > 0 do
			task.wait(0.2)
		end
		if not sigue() then
			return
		end
		if estado:GetAttribute("Vidas") <= 0 then
			fijar("Fase", "fin")
			fijar("Mensaje", `Derrota en la oleada {oleada}`)
			return
		end
	end
	fijar("Fase", "fin")
	fijar("Mensaje", "¡Victoria! Base Avengers defendida")
end

local function iniciarPartida()
	partidaActual += 1
	limpiar()
	fijar("Vidas", VIDAS_INICIALES)
	fijar("Creditos", CREDITOS_INICIALES)
	fijar("Modo", "batalla")
	task.spawn(partida, partidaActual)
end

function ACCIONES.volver()
	partidaActual += 1
	limpiar()
	fijar("Modo", "hub")
	fijar("Fase", "hub")
	return nil
end

--------------------------------------------------------------------------------
-- HUB
--------------------------------------------------------------------------------
local aviso = Instance.new("RemoteEvent")
aviso.Name = "Aviso"
aviso.Parent = ReplicatedStorage

local hub = Hub.construir(function(jugador, estacion)
	if estacion == "story" then
		if estado:GetAttribute("Modo") == "hub" then
			iniciarPartida()
		end
	else
		-- Infinito y reclutamiento esperan su port; traits y grades, las reglas del usuario.
		aviso:FireClient(jugador, "Próximamente")
	end
end)
RunService.Heartbeat:Connect(function(dt)
	Hub.animar(hub, dt)
end)
