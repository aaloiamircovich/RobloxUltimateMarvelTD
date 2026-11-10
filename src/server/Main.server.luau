-- HUB y partida de campaña en Base Avengers: mapa, oleadas del 2D y héroes que el jugador despliega.
-- Reglas del 3D: despliegue y movimiento gratis, una unidad por héroe, retiro sin reembolso.
-- shortcut: un escuadrón compartido por todos los jugadores; con multijugador, una partida por jugador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Data = Shared.Data
local Oleadas = require(Shared.Oleadas)
local Despliegue = require(Shared.Despliegue)
local Progresion = require(Shared.Progresion)
local Combate = require(Shared.Combate)
local Kits = require(Shared.Kits)
local Mapa = require(Shared.Mapa)
local Hub = require(script.Parent.Hub)
local Perfiles = require(script.Parent.Perfiles)
local Reclutamiento = require(script.Parent.Reclutamiento)

local heroes = require(Data.heroes)
local enemigosDatos = require(Data.enemies)
local niveles = require(Data.levels)
local tablaTipos = require(Data.TypeChart)

local NIVEL, INDICE_NIVEL = niveles[1], 0
local VIDAS_INICIALES = 20 -- ResourceManager del 2D; los créditos de Historia son los del perfil
local CREDITOS_INFINITO, BONO_HITO = 750, 300 -- GameModeSystem del 2D: supervivencia
local ESCUADRON = {} -- el escuadrón del perfil del dueño, fijado al iniciar la misión

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
fijar("Modo", "hub")
fijar("Fase", "hub")
fijar("Mensaje", "")

-- Jugador que inició la partida: juega con su perfil y es el único que puede actuar en ella.
local dueno: Player? = nil

-- "campaign" (Historia) o "survival" (Infinito).
local modoPartida = "campaign"
-- Infinito: hasta el primer movimiento de créditos, el saldo del perfil no se toca (regla del 3D).
local creditosIntactos = false

-- Los créditos de la partida son el saldo del perfil del dueño (como Historia en el 3D).
-- En Infinito, ganar o gastar reemplaza el saldo del perfil por el de la partida.
estado:GetAttributeChangedSignal("Creditos"):Connect(function()
	local perfil = dueno and Perfiles.de(dueno)
	if creditosIntactos then
		if estado:GetAttribute("Creditos") == CREDITOS_INFINITO then
			return
		end
		creditosIntactos = false
	end
	if perfil and estado:GetAttribute("Modo") == "batalla" then
		perfil.credits = estado:GetAttribute("Creditos")
		Perfiles.marcar(dueno)
		dueno:SetAttribute("Creditos", perfil.credits)
	end
end)

local accion = Instance.new("RemoteFunction")
accion.Name = "Accion"
accion.Parent = ReplicatedStorage
local aviso = Instance.new("RemoteEvent")
aviso.Name = "Aviso"
aviso.Parent = ReplicatedStorage
local abrirPanel = Instance.new("RemoteEvent")
abrirPanel.Name = "AbrirPanel"
abrirPanel.Parent = ReplicatedStorage

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
	local e = Combate.nuevoEnemigo(config)
	e.modelo = modelo
	e.avance = 0
	e.altura = if config.flying then 4 else tam / 2
	e.cuerpo = cuerpo
	e.barra = cartel(cuerpo, config.name, tam / 2 + 1)
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

-- Refleja la vida en la barra; si murió, paga la recompensa y lo saca (una sola vez).
-- shortcut: sin recarga de barrera de escudos ni conductas de enemigos (curas, invocaciones).
local function revisar(e)
	if not table.find(enemigos, e) then
		return
	end
	e.barra.Size = UDim2.fromScale(math.max(0, e.vida / e.vidaMax), 1)
	if e.vida <= 0 then
		fijar("Creditos", estado:GetAttribute("Creditos") + (e.config.reward or 0))
		quitarEnemigo(e)
	end
end

-- Enemigos con su posición en píxeles del 2D, para kits y splash (se arma una vez por cuadro).
local enPixeles = {}
local function actualizarPixeles()
	table.clear(enPixeles)
	for _, e in enemigos do
		local x, y = Mapa.aPixeles(e.cuerpo.Position)
		table.insert(enPixeles, { e = e, x = x, y = y, avance = e.avance })
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

-- Nivel del héroe guardado en el perfil del dueño (heroUpgrades del 2D).
local function nivelGuardado(heroeId: string): number
	local perfil = dueno and Perfiles.de(dueno)
	local g = perfil and perfil.heroUpgrades[heroeId]
	return g and g.level or 1
end

function ACCIONES.colocar(heroeId: string, x: number, y: number)
	if not table.find(ESCUADRON, heroeId) then
		return "Ese héroe no está en tu escuadrón"
	end
	local config = heroes[heroeId]
	local nivel = nivelGuardado(heroeId)
	local err, cx, cy = Despliegue.error(Progresion.paraDespliegue(config, nivel), x, y, NIVEL, rutaPx, listaUnidades())
	if err then
		return err
	end
	local modelo, raiz, ataque, velocidadAtaque = crearModelo(config)
	local u = { uid = siguienteUid, heroe = heroeId, x = cx, y = cy, config = config, nivel = nivel, stats = Progresion.stats(config, nivel), modelo = modelo, raiz = raiz, espera = 0, ataque = ataque, velocidadAtaque = velocidadAtaque, kit = Kits.nuevo(heroeId) }
	siguienteUid += 1
	modelo:SetAttribute("Uid", u.uid)
	modelo:SetAttribute("Heroe", heroeId)
	modelo:SetAttribute("Nivel", nivel)
	modelo:SetAttribute("Municion", if heroeId == "hawkeye" then "explosive" else nil)
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
	local perfil = dueno and Perfiles.de(dueno)
	if perfil then
		perfil.heroUpgrades[u.heroe] = { level = u.nivel }
	end
	fijar("Creditos", creditos - costo)
	local evo = Progresion.evolucion(u.heroe, u.nivel)
	if evo and not evolucionaba then
		fijar("Mensaje", `¡{u.config.name} evolucionó: {evo.name}!`)
	end
	return nil
end

-- Carcaj de Hawkeye: cambia de munición; conserva la carga, como setMode del 2D.
function ACCIONES.municion(uid: number)
	local u = buscarUnidad(uid)
	if not u or not u.kit.modo then
		return "Ese héroe no cambia de munición"
	end
	local i = table.find(Kits.MODOS_HAWKEYE, u.kit.modo)
	u.kit.modo = Kits.MODOS_HAWKEYE[i % #Kits.MODOS_HAWKEYE + 1]
	u.modelo:SetAttribute("Municion", u.kit.modo)
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
accion.OnServerInvoke = function(jugador, nombre, a, b, c)
	local f = ACCIONES[nombre]
	if type(nombre) ~= "string" or not f then
		return "Acción desconocida"
	end
	if dueno and jugador ~= dueno then
		return `La misión es de {dueno.DisplayName}`
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
	if (nombre == "retirar" or nombre == "mejorar" or nombre == "municion") and type(a) ~= "number" then
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
	flecha = function(desde: Vector3, hasta: Vector3, color: Color3?)
		local f = pieza(Vector3.new(0.15, 0.15, 1.6), color or Color3.fromRGB(150, 80, 230), CFrame.lookAt(desde, hasta))
		animarYBorrar(f, 0.12, { CFrame = CFrame.lookAt(hasta, hasta + (hasta - desde)) })
	end,
	rayo = function(desde: Vector3, hasta: Vector3)
		local largo = (hasta - desde).Magnitude
		local f = pieza(Vector3.new(0.2, 0.2, largo), Color3.fromRGB(90, 190, 255), CFrame.lookAt(desde, hasta) * CFrame.new(0, 0, -largo / 2))
		animarYBorrar(f, 0.15, { Transparency = 1, Size = Vector3.new(0.05, 0.05, largo) })
	end,
	impacto = function(_desde: Vector3, hasta: Vector3, color: Color3?, radio: number?)
		local d = (radio or 2) * 2
		local f = pieza(Vector3.new(1, 1, 1), color or Color3.fromRGB(190, 130, 80), CFrame.new(hasta))
		f.Shape = Enum.PartType.Ball
		f.Material = Enum.Material.Slate
		f.Transparency = 0.3
		animarYBorrar(f, 0.25, { Transparency = 1, Size = Vector3.new(d, d, d) })
	end,
}

-- Colores del 2D (getProjectileColor) para la munición de Hawkeye.
local COLOR_MUNICION = {
	explosive = Color3.fromHex("ff9d3d"),
	cryo = Color3.fromHex("7ce7ff"),
	piercing = Color3.fromHex("d8f0ff"),
}

local function vivo(e)
	return e.vida > 0 and e.cuerpo.Parent ~= nil
end

local function actualizarUnidad(u, dt)
	local heroe = { x = u.x, y = u.y, alcance = u.stats.range, ve = u.stats.canSeeStealth }

	-- Habilidades por tiempo: pisotón de Korg.
	local pisoton = Kits.actualizar(u.kit, dt, u.config, u.stats, heroe, enPixeles)
	if pisoton then
		for _, g in pisoton do
			Combate.danar(g.enemigo, g.golpe, 1, tablaTipos)
			if g.enemigo.vida > 0 then
				Combate.aplicarEstado(g.enemigo, g.efecto)
			end
			revisar(g.enemigo)
		end
		EFECTOS.impacto(nil, u.raiz.Position - Vector3.new(0, 2, 0), Color3.fromHex("a3a3a3"), 65 * Mapa.ESCALA)
	end

	u.espera -= dt
	if u.espera > 0 then
		return
	end
	-- Prioridad "Primero": el enemigo más avanzado dentro de la forma de alcance.
	local objetivo
	for _, c in enPixeles do
		local visible = not c.e.config.stealth or u.stats.canSeeStealth
		if vivo(c.e) and visible and Despliegue.enAlcance(u.x, u.y, c.x, c.y, u.stats.range, u.config.rangePattern) and (not objetivo or c.avance > objetivo.avance) then
			objetivo = c
		end
	end
	if not objetivo then
		return
	end
	u.espera = 1 / u.stats.fireRate
	local destino = objetivo.e.cuerpo.Position
	local p = u.raiz.Position
	ponerRaiz(u, CFrame.lookAt(p, Vector3.new(destino.X, p.Y, destino.Z)))
	if u.ataque then
		u.ataque:Play(0.05, 1, u.velocidadAtaque)
	end

	-- Crítico como Hero.shoot del 2D: probabilidad en %, daño ×critDamage; después el kit arma el golpe.
	local critico = math.random() * 100 < u.stats.critChance
	local golpe = Kits.golpe(u.kit, u.config, objetivo.e, if critico then u.stats.damage * u.stats.critDamage else u.stats.damage)
	local efecto = EFECTOS[u.modelo:GetAttribute("Efecto")] or EFECTOS.flecha
	efecto(p + Vector3.new(0, 1, 0), destino, COLOR_MUNICION[u.kit.modo])

	local tocados = { objetivo.e }
	Combate.impacto(objetivo.e, golpe, tablaTipos, math.random, function(radio)
		local r = {}
		for _, c in enPixeles do
			if vivo(c.e) and math.sqrt((c.x - objetivo.x) ^ 2 + (c.y - objetivo.y) ^ 2) <= radio then
				table.insert(r, c.e)
				table.insert(tocados, c.e)
			end
		end
		return r
	end)
	if (golpe.radioSplash or 0) > 0 then
		EFECTOS.impacto(nil, destino, COLOR_MUNICION[u.kit.modo], golpe.radioSplash * Mapa.ESCALA)
	end

	-- onAttack: sabotaje de Black Widow al cuarto ataque (blanco + hasta 3 cercanos).
	for i, g in Kits.alAtacar(u.kit, u.config, u.stats, u.nivel, objetivo.e, heroe, enPixeles) do
		Combate.danar(g.enemigo, g.golpe, 1, tablaTipos)
		table.insert(tocados, g.enemigo)
		if i > 1 then
			EFECTOS.rayo(destino, g.enemigo.cuerpo.Position)
		end
	end
	for _, e in tocados do
		revisar(e)
	end
end

RunService.Heartbeat:Connect(function(dt)
	for i = #enemigos, 1, -1 do
		local e = enemigos[i]
		local velocidad, murio = Combate.actualizar(e, dt)
		if murio then
			revisar(e) -- murió por veneno
			continue
		end
		e.avance += e.config.speed * velocidad * Mapa.ESCALA * dt
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
	actualizarPixeles()
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
	local infinito = modoPartida == "survival"
	local prefijo = if infinito then "Infinito · " else ""
	local puntaje = 0
	local oleada = 0
	while infinito or oleada < Oleadas.MAX_OLEADAS do
		oleada += 1
		fijar("Oleada", oleada)
		fijar("Fase", "preparacion")
		fijar("Mensaje", `{prefijo}Oleada {oleada}: desplegá héroes y apretá «Iniciar oleada»`)
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
		local cola, mod = Oleadas.preparar(oleada, enemigosDatos, NIVEL, INDICE_NIVEL, equipo, modoPartida)
		fijar("Fase", "combate")
		fijar("Mensaje", `{prefijo}Oleada {oleada}: {mod.nombre}`)
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
			fijar("Mensaje", `{prefijo}Derrota en la oleada {oleada}` .. (if infinito then ` · {puntaje} puntos` else ""))
			return
		end
		local perfil = dueno and Perfiles.de(dueno)
		if infinito then
			-- onWaveFinished del 2D: puntaje, récord y hito de +300 cada cinco oleadas.
			puntaje += math.round(100 * oleada + estado:GetAttribute("Vidas") * 12)
			if perfil then
				local r = perfil.modeRecords.survival
				r.bestWave = math.max(r.bestWave, oleada)
				r.bestScore = math.max(r.bestScore, puntaje)
				Perfiles.marcar(dueno)
			end
			if oleada % 5 == 0 then
				fijar("Creditos", estado:GetAttribute("Creditos") + BONO_HITO)
				aviso:FireAllClients(`Hito {oleada}: +{BONO_HITO} créditos`)
			end
		elseif perfil then
			-- Oleada superada: mejor oleada y estrellas del mapa, como mapProgress del 2D.
			local p = perfil.mapProgress[NIVEL.id] or { bestWave = 0, stars = 0 }
			p.bestWave = math.max(p.bestWave, oleada)
			p.stars = math.max(p.stars, p.bestWave)
			perfil.mapProgress[NIVEL.id] = p
			Perfiles.marcar(dueno)
		end
	end
	fijar("Fase", "fin")
	fijar("Mensaje", "¡Victoria! Base Avengers defendida")
end

local function iniciarPartida(jugador: Player, modo: string)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return
	end
	if #perfil.activeTeamIds == 0 then
		aviso:FireClient(jugador, "Elegí tu héroe inicial en Invocaciones")
		return
	end
	ESCUADRON = table.clone(perfil.activeTeamIds)
	fijar("Escuadron", table.concat(ESCUADRON, ","))
	partidaActual += 1
	limpiar()
	dueno = jugador
	modoPartida = modo
	creditosIntactos = modo == "survival"
	fijar("Vidas", VIDAS_INICIALES)
	fijar("Modo", "batalla")
	fijar("Creditos", if modo == "survival" then CREDITOS_INFINITO else perfil.credits)
	task.spawn(partida, partidaActual)
end

function ACCIONES.volver()
	partidaActual += 1
	limpiar()
	fijar("Modo", "hub")
	fijar("Fase", "hub")
	if dueno then
		task.spawn(Perfiles.guardar, dueno)
	end
	dueno = nil
	return nil
end

--------------------------------------------------------------------------------
-- HUB
--------------------------------------------------------------------------------
local hub = Hub.construir(function(jugador, estacion)
	if estacion == "story" then
		if estado:GetAttribute("Modo") == "hub" then
			iniciarPartida(jugador, "campaign")
		elseif dueno ~= jugador then
			aviso:FireClient(jugador, `{dueno and dueno.DisplayName or "Otro jugador"} está en una misión`)
		end
	elseif estacion == "summon" then
		abrirPanel:FireClient(jugador, "invocaciones")
	elseif estacion == "infinite" then
		-- Antes de entrar, el cliente explica la regla de créditos y pide confirmar.
		local perfil = Perfiles.de(jugador)
		abrirPanel:FireClient(jugador, "infinito", perfil and perfil.modeRecords.survival)
	else
		-- Traits y grades esperan las reglas del usuario.
		aviso:FireClient(jugador, "Próximamente")
	end
end)
RunService.Heartbeat:Connect(function(dt)
	Hub.animar(hub, dt)
end)

--------------------------------------------------------------------------------
-- Perfiles: carga al entrar, guardado al salir, al cerrar y cada minuto
--------------------------------------------------------------------------------
local function alEntrar(jugador: Player)
	local perfil, problema = Perfiles.cargar(jugador)
	jugador:SetAttribute("Creditos", perfil.credits)
	if problema then
		aviso:FireClient(jugador, problema)
	end
end
Players.PlayerAdded:Connect(alEntrar)
for _, j in Players:GetPlayers() do
	task.spawn(alEntrar, j)
end
Players.PlayerRemoving:Connect(function(jugador)
	if jugador == dueno then
		ACCIONES.volver()
	end
	Perfiles.soltar(jugador)
end)
game:BindToClose(function()
	Perfiles.guardarTodos()
	task.wait(3)
end)
task.spawn(function()
	while true do
		task.wait(60)
		Perfiles.guardarTodos()
	end
end)

--------------------------------------------------------------------------------
-- Colección (estación Invocaciones): acciones por jugador sobre su propio perfil
--------------------------------------------------------------------------------
local function resumen(perfil)
	return {
		creditos = perfil.credits,
		desbloqueados = perfil.unlockedHeroIds,
		equipo = perfil.activeTeamIds,
		costo = Reclutamiento.costo(perfil),
		probabilidades = Reclutamiento.probabilidades(perfil, heroes),
		iniciales = Reclutamiento.INICIALES,
		garantia = perfil.shop.heroPity >= 4,
	}
end

local entrar = Instance.new("RemoteFunction")
entrar.Name = "Entrar"
entrar.Parent = ReplicatedStorage
entrar.OnServerInvoke = function(jugador, modo)
	if modo ~= "survival" then
		return "Modo desconocido"
	end
	if estado:GetAttribute("Modo") ~= "hub" then
		return `{dueno and dueno.DisplayName or "Otro jugador"} está en una misión`
	end
	iniciarPartida(jugador, modo)
	return nil
end

local coleccion = Instance.new("RemoteFunction")
coleccion.Name = "Coleccion"
coleccion.Parent = ReplicatedStorage
coleccion.OnServerInvoke = function(jugador, nombre, arg)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	-- Los créditos de una misión en curso son los del perfil: no tocarlos desde otro lado a la vez.
	if nombre ~= "estado" and jugador == dueno then
		return { error = "Terminá o abandoná la misión primero" }
	end
	local res = {}
	if nombre == "elegirInicial" and type(arg) == "string" then
		res.error = Reclutamiento.elegirInicial(perfil, arg)
	elseif nombre == "reclutar" then
		local heroe, extra = Reclutamiento.reclutar(perfil, heroes, math.random)
		if heroe then
			res.heroe = { id = heroe.id, nombre = heroe.name, rareza = heroe.rarity, categoria = heroe.category, garantizado = extra }
		else
			res.error = extra
		end
	elseif nombre == "equipo" and type(arg) == "table" then
		res.error = Reclutamiento.fijarEquipo(perfil, arg)
	elseif nombre ~= "estado" then
		res.error = "Acción desconocida"
	end
	if nombre ~= "estado" and not res.error then
		Perfiles.marcar(jugador)
		jugador:SetAttribute("Creditos", perfil.credits)
	end
	res.estado = resumen(perfil)
	return res
end
