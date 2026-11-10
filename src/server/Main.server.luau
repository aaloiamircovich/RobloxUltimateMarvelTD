-- HUB y partida de campaña en Base Avengers: mapa, oleadas del 2D y héroes que el jugador despliega.
-- Reglas del 3D: despliegue y movimiento gratis, retiro sin reembolso. Unidades, límites por rareza y
-- recompensas de gemas/núcleos/XP: docs/INVOCACIONES.md.
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
local Conductas = require(Shared.Conductas)
local Objetos = require(Shared.Objetos)
local Mapa = require(Shared.Mapa)
local Hub = require(script.Parent.Hub)
local Perfiles = require(script.Parent.Perfiles)
local Reclutamiento = require(script.Parent.Reclutamiento)
local Personajes = require(Shared.Personajes)
local Unidades = require(Shared.Unidades)
local Banner = require(Shared.Banner)

local heroes = Personajes.todos -- heroes.json más los personajes evolucionados
local enemigosDatos = require(Data.enemies)
local niveles = require(Data.levels)
local tablaTipos = require(Data.TypeChart)

local NIVEL, INDICE_NIVEL -- mapa de la misión en curso; se fija con cargarNivel()
local ESTRELLAS_POR_MAPA = 25 -- STARS_PER_LEVEL_UNLOCK del 2D
local VIDAS_INICIALES = 20 -- ResourceManager del 2D; los créditos de Historia son los del perfil
local CREDITOS_INFINITO, BONO_HITO = 750, 300 -- GameModeSystem del 2D: supervivencia
-- Escuadrón de la misión: { uid, heroId, nivel, limite } por unidad del perfil del dueño.
local ESCUADRON = {}
local GEMAS_OLEADA, GEMAS_MAPA, GEMAS_INFINITO = 10, 25, 15 -- docs/INVOCACIONES.md
local XP_OLEADA = 10

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

local rutaPx, ruta, largoTramo, largoTotal

local function cargarNivel(indice: number)
	NIVEL, INDICE_NIVEL = niveles[indice], indice - 1
	rutaPx = Mapa.rutaPixeles(NIVEL)
	ruta = Mapa.construir(NIVEL)
	largoTramo, largoTotal = {}, 0
	for i = 1, #ruta - 1 do
		largoTramo[i] = (ruta[i + 1] - ruta[i]).Magnitude
		largoTotal += largoTramo[i]
	end
	fijar("Nivel", NIVEL.id)
end
cargarNivel(1)

-- Estrellas totales (getTotalStars): una por oleada superada en cada mapa de Historia.
local function estrellas(perfil): number
	local total = 0
	for _, p in perfil.mapProgress do
		total += p.stars
	end
	return total
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

-- avanceInicial: las invocaciones aparecen donde está quien las invoca.
local function crearEnemigo(config, avanceInicial: number?)
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
	e.avance = avanceInicial or 0
	Conductas.preparar(e)
	e.altura = if config.flying then 4 else tam / 2
	e.cuerpo = cuerpo
	e.barra = cartel(cuerpo, config.name, tam / 2 + 1)
	moverEnemigo(e, CFrame.new(puntoEnRuta(e.avance) + Vector3.new(0, e.altura, 0)))
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
	local plantilla = carpeta and carpeta:FindFirstChild(Personajes.base(config.id))
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

-- Stats de combate: nivel de la partida (sin evolución, que ahora es por crafteo) y +1 % de daño por
-- nivel de la unidad.
local function statsUnidad(u)
	local s = Progresion.stats(u.config, u.nivel, u.objeto, estado:GetAttribute("Vidas"), true)
	s.damage *= Unidades.bonoDano(u.nivelUnidad)
	return s
end

local function colocadas(ranura: number): number
	local n = 0
	for _, u in unidades do
		if u.ranura == ranura then
			n += 1
		end
	end
	return n
end

-- ranura: uid de la unidad del perfil en el escuadrón. Las mejoras de la partida empiezan en nivel 1.
function ACCIONES.colocar(ranura: number, x: number, y: number)
	local e
	for _, entrada in ESCUADRON do
		if entrada.uid == ranura then
			e = entrada
		end
	end
	if not e then
		return "Esa unidad no está en tu escuadrón"
	end
	if colocadas(ranura) >= e.limite then
		return `Ya colocaste esta unidad {e.limite} {if e.limite == 1 then "vez" else "veces"} (máximo de su rareza)`
	end
	local config = heroes[e.heroId]
	local nivel = 1
	local perfil = dueno and Perfiles.de(dueno)
	local objeto = perfil and Objetos.de(perfil, e.heroId)
	local err, cx, cy = Despliegue.error(Progresion.paraDespliegue(config, nivel, objeto), x, y, NIVEL, rutaPx, listaUnidades(), nil, true)
	if err then
		return err
	end
	local base = Personajes.base(e.heroId)
	local modelo, raiz, ataque, velocidadAtaque = crearModelo(config)
	local u = { uid = siguienteUid, ranura = ranura, heroe = base, x = cx, y = cy, config = config, nivel = nivel, nivelUnidad = e.nivel, objeto = objeto, modelo = modelo, raiz = raiz, espera = 0, ataque = ataque, velocidadAtaque = velocidadAtaque, kit = Kits.nuevo(base) }
	u.stats = statsUnidad(u)
	siguienteUid += 1
	modelo:SetAttribute("Uid", u.uid)
	modelo:SetAttribute("Heroe", e.heroId)
	modelo:SetAttribute("Ranura", ranura)
	modelo:SetAttribute("Nivel", nivel)
	modelo:SetAttribute("Municion", if base == "hawkeye" then "explosive" else nil)
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
	local err, cx, cy = Despliegue.error(Progresion.paraDespliegue(u.config, u.nivel, u.objeto), x, y, NIVEL, rutaPx, listaUnidades(), uid, true)
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
	u.nivel += 1
	u.stats = statsUnidad(u)
	u.modelo:SetAttribute("Nivel", u.nivel) -- antes que los créditos: el cliente refresca al cambiar Estado
	fijar("Creditos", creditos - costo)
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
	if nombre == "colocar" and not (type(a) == "number" and type(b) == "number" and type(c) == "number") then
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

local entornoConductas -- se completa más abajo, cuando existen las unidades

local function vivo(e)
	return e.vida > 0 and e.cuerpo.Parent ~= nil
end

local function actualizarUnidad(u, dt)
	-- Aturdido (Guantelete de Thanos): como Hero.update del 2D, no actúa ni carga habilidades.
	if (u.aturdido or 0) > 0 then
		u.aturdido -= dt
		return
	end
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
		local visible = not Combate.sigilo(c.e) or u.stats.canSeeStealth
		if vivo(c.e) and visible and Despliegue.enAlcance(u.x, u.y, c.x, c.y, u.stats.range, u.config.rangePattern) and (not objetivo or c.avance > objetivo.avance) then
			objetivo = c
		end
	end
	if not objetivo then
		return
	end
	-- Recalcular por los bonus de objeto con 10 vidas o menos ("lowLife").
	u.stats = statsUnidad(u)
	u.espera = 1 / u.stats.fireRate
	local destino = objetivo.e.cuerpo.Position
	local p = u.raiz.Position
	ponerRaiz(u, CFrame.lookAt(p, Vector3.new(destino.X, p.Y, destino.Z)))
	if u.ataque then
		u.ataque:Play(0.05, 1, u.velocidadAtaque)
	end

	-- Crítico como Hero.shoot del 2D: probabilidad en %, daño ×critDamage; después el kit arma el golpe.
	local critico = math.random() * 100 < u.stats.critChance
	local distancia = math.sqrt((objetivo.x - u.x) ^ 2 + (objetivo.y - u.y) ^ 2)
	local golpe = Kits.golpe(u.kit, u.config, objetivo.e, if critico then u.stats.damage * u.stats.critDamage else u.stats.damage, u.stats, u.objeto, distancia)
	local efecto = EFECTOS[u.modelo:GetAttribute("Efecto")] or EFECTOS.flecha
	efecto(p + Vector3.new(0, 1, 0), destino, COLOR_MUNICION[u.kit.modo])

	local todos, posiciones = {}, {}
	for _, c in enPixeles do
		if vivo(c.e) then
			table.insert(todos, c.e)
			posiciones[c.e] = c
		end
	end
	local tocados, saltos = Combate.impacto(objetivo.e, golpe, tablaTipos, math.random, todos, function(e)
		return posiciones[e].x, posiciones[e].y
	end)
	for _, salto in saltos do
		EFECTOS.rayo(salto.desde.cuerpo.Position, salto.hasta.cuerpo.Position)
	end
	-- applyItemEffects del 2D: créditos por golpe principal según la recompensa del blanco.
	local pct = u.objeto and u.objeto.effects.onHitCreditPct
	if pct and (objetivo.e.config.reward or 0) > 0 then
		fijar("Creditos", estado:GetAttribute("Creditos") + math.max(1, math.ceil(objetivo.e.config.reward * pct)))
	end
	if (golpe.radioSplash or 0) > 0 then
		EFECTOS.impacto(nil, destino, COLOR_MUNICION[u.kit.modo], golpe.radioSplash * Mapa.ESCALA)
	end

	-- onAttack: sabotaje de Black Widow al cuarto ataque (blanco + hasta 3 cercanos).
	for i, g in Kits.alAtacar(u.kit, u.config, u.stats, u.nivel, objetivo.e, heroe, enPixeles) do
		Combate.danar(g.enemigo, g.golpe, 1, tablaTipos)
		if g.sabotaje and g.enemigo.vida > 0 then
			Conductas.sabotear(g.enemigo, Conductas.SABOTAJE_SEGUNDOS)
		end
		table.insert(tocados, g.enemigo)
		if i > 1 then
			EFECTOS.rayo(destino, g.enemigo.cuerpo.Position)
		end
	end
	for _, e in tocados do
		revisar(e)
	end
end

-- Lo que las conductas de enemigos pueden hacer en el mundo.
entornoConductas = {
	aliados = function(e, radio)
		local ex, ey = Mapa.aPixeles(e.cuerpo.Position)
		local r = {}
		for _, otro in enemigos do
			if otro ~= e and vivo(otro) then
				local ox, oy = Mapa.aPixeles(otro.cuerpo.Position)
				if math.sqrt((ox - ex) ^ 2 + (oy - ey) ^ 2) <= radio then
					table.insert(r, otro)
				end
			end
		end
		return r
	end,
	-- Como spawnEnemy del 2D: config de la base de datos sin escalar, sin recompensa.
	invocar = function(id, origen, factorVida)
		local base = enemigosDatos.normal[id]
		if not base then
			return false
		end
		local config = table.clone(base)
		config.hp = math.floor(base.hp * factorVida + 0.5)
		config.reward = 0
		crearEnemigo(config, origen.avance)
		return true
	end,
	aviso = function(texto)
		aviso:FireAllClients(texto)
	end,
	aturdirHeroes = function(segundos)
		for _, u in unidades do
			u.aturdido = segundos
		end
	end,
}

RunService.Heartbeat:Connect(function(dt)
	for i = #enemigos, 1, -1 do
		local e = enemigos[i]
		local velocidad, murio = Combate.actualizar(e, dt)
		if murio then
			revisar(e) -- murió por veneno
			continue
		end
		velocidad *= Conductas.actualizar(e, dt, entornoConductas)
		e.barra.Size = UDim2.fromScale(math.clamp(e.vida / e.vidaMax, 0, 1), 1) -- curas y regeneración
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
	-- updateLandmarks del 2D (Sanctum): las runas marcan a los enemigos cercanos, +12% de daño recibido.
	local mecanica = NIVEL.mission and NIVEL.mission.mechanic
	if mecanica and mecanica.type == "ward" then
		for _, zona in mecanica.landmarks or {} do
			for _, c in enPixeles do
				if vivo(c.e) and math.sqrt((c.x - zona.x) ^ 2 + (c.y - zona.y) ^ 2) <= (zona.radius or 54) then
					Combate.aplicarEstado(c.e, { type = "mark", duration = 0.4, power = 0.12 })
				end
			end
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
		local premios = {}
		if infinito then
			-- onWaveFinished del 2D: puntaje, récord y hito de +300 cada cinco oleadas.
			puntaje += math.round(100 * oleada + estado:GetAttribute("Vidas") * 12)
			if perfil then
				local r = perfil.modeRecords.survival
				r.bestWave = math.max(r.bestWave, oleada)
				r.bestScore = math.max(r.bestScore, puntaje)
				if oleada % 5 == 0 then
					perfil.gems += GEMAS_INFINITO
					table.insert(premios, `+{GEMAS_INFINITO} gemas`)
				end
				if oleada % 10 == 0 then
					perfil.cores += 1
					table.insert(premios, "+1 núcleo")
				end
			end
			if oleada % 5 == 0 then
				fijar("Creditos", estado:GetAttribute("Creditos") + BONO_HITO)
				aviso:FireAllClients(`Hito {oleada}: +{BONO_HITO} créditos`)
			end
		elseif perfil then
			-- Oleada superada: mejor oleada y estrellas del mapa, como mapProgress del 2D.
			local p = perfil.mapProgress[NIVEL.id] or { bestWave = 0, stars = 0 }
			if oleada > p.bestWave then
				perfil.gems += GEMAS_OLEADA -- sólo la primera vez que se supera esta oleada en este mapa
				table.insert(premios, `+{GEMAS_OLEADA} gemas`)
			end
			p.bestWave = math.max(p.bestWave, oleada)
			p.stars = math.max(p.stars, p.bestWave)
			perfil.mapProgress[NIVEL.id] = p
		end
		if perfil then
			-- Experiencia para cada unidad del escuadrón (×1,5 en mapas Difíciles).
			local xp = math.floor(XP_OLEADA * (if Oleadas.dificultad(NIVEL) == "hard" then 1.5 else 1))
			local subieron = 0
			for _, e in ESCUADRON do
				local u = Unidades.buscar(perfil, e.uid)
				if u and Unidades.ganarXP(u, xp) > 0 then
					subieron += 1
				end
			end
			table.insert(premios, `+{xp} XP al escuadrón` .. (if subieron > 0 then ` ({subieron} subieron de nivel)` else ""))
			Perfiles.marcar(dueno)
			aviso:FireClient(dueno, table.concat(premios, " · "))
			dueno:SetAttribute("Gemas", perfil.gems)
		end
	end
	local perfil = dueno and Perfiles.de(dueno)
	if perfil then
		perfil.gems += GEMAS_MAPA
		perfil.cores += 1
		Perfiles.marcar(dueno)
		dueno:SetAttribute("Gemas", perfil.gems)
	end
	fijar("Fase", "fin")
	fijar("Mensaje", `¡Victoria! {NIVEL.name} defendido · +{GEMAS_MAPA} gemas · +1 núcleo`)
end

-- Infinito se juega siempre en Base Avengers, como el 3D.
local function iniciarPartida(jugador: Player, modo: string, nivelId: string?): string?
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return "Tu perfil todavía no cargó"
	end
	if #perfil.squad == 0 then
		return "Elegí tu héroe inicial en Invocaciones"
	end
	local indice = 1
	if modo == "campaign" then
		indice = table.find(Mapa.JUGABLES, nivelId or "level_1")
		if not indice then
			return "Esta misión todavía no está integrada."
		end
		local requisito = (indice - 1) * ESTRELLAS_POR_MAPA
		if estrellas(perfil) < requisito then
			return `Requiere {requisito} estrellas totales. Tenés {estrellas(perfil)}.`
		end
	end
	cargarNivel(indice)
	-- Escuadrón para el cliente: "uid:personaje:nivel:límite" separados por comas.
	ESCUADRON = {}
	local texto = {}
	for _, uid in perfil.squad do
		local u = Unidades.buscar(perfil, uid)
		if u then
			local e = { uid = uid, heroId = u.heroId, nivel = u.level, limite = Unidades.LIMITE_COLOCACION[heroes[u.heroId].rarity] or 1 }
			table.insert(ESCUADRON, e)
			table.insert(texto, `{e.uid}:{e.heroId}:{e.nivel}:{e.limite}`)
		end
	end
	fijar("Escuadron", table.concat(texto, ","))
	partidaActual += 1
	limpiar()
	dueno = jugador
	modoPartida = modo
	creditosIntactos = modo == "survival"
	fijar("Vidas", VIDAS_INICIALES)
	fijar("Modo", "batalla")
	fijar("Creditos", if modo == "survival" then CREDITOS_INFINITO else perfil.credits)
	task.spawn(partida, partidaActual)
	return nil
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
		-- El cliente muestra los mapas con su requisito de estrellas y elige.
		local perfil = Perfiles.de(jugador)
		if not perfil then
			return
		end
		local mapas = {}
		for i, id in Mapa.JUGABLES do
			local n = niveles[i]
			local p = perfil.mapProgress[id] or { bestWave = 0, stars = 0 }
			table.insert(mapas, { id = id, nombre = n.name, dificultad = n.difficulty, requisito = (i - 1) * ESTRELLAS_POR_MAPA, mejor = p.bestWave })
		end
		abrirPanel:FireClient(jugador, "historia", { estrellas = estrellas(perfil), mapas = mapas })
	elseif estacion == "summon" then
		abrirPanel:FireClient(jugador, "invocaciones", { pestana = "banner" })
	elseif estacion == "tienda" then
		abrirPanel:FireClient(jugador, "invocaciones", { pestana = "tienda" })
	elseif estacion == "infinite" then
		-- Antes de entrar, el cliente explica la regla de créditos y pide confirmar.
		local perfil = Perfiles.de(jugador)
		abrirPanel:FireClient(jugador, "infinito", perfil and perfil.modeRecords.survival)
	else
		-- Traits, grades, pets, bailes, monturas, raids, banners 2 y 3, salas, etc. esperan sus reglas.
		aviso:FireClient(jugador, if estacion:sub(1, 5) == "sala_" then "Próximamente: salas con amigos" else "Próximamente")
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
	jugador:SetAttribute("Gemas", perfil.gems)
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
	local vitrina, equipados = {}, {}
	for _, it in Objetos.vitrina(perfil) do
		table.insert(vitrina, it.id)
	end
	for heroeId in perfil.equippedItems do
		equipados[heroeId] = Objetos.de(perfil, heroeId).id
	end
	local ahora = os.time()
	local destacados = Banner.destacados(Banner.hora(ahora))
	local garantia = perfil.shop.heroPity >= Banner.GARANTIA
	local porRareza, porDestacado = Banner.probabilidades(destacados, garantia)
	return {
		creditos = perfil.credits,
		gemas = perfil.gems,
		nucleos = perfil.cores,
		unidades = perfil.units,
		escuadron = perfil.squad,
		desbloqueados = perfil.unlockedHeroIds,
		iniciales = Reclutamiento.INICIALES,
		banner = {
			destacados = destacados,
			cambiaEn = 3600 - ahora % 3600, -- segundos hasta la próxima rotación
			costo = Banner.COSTO,
			probabilidades = porRareza,
			probDestacados = porDestacado,
			garantia = garantia,
		},
		vitrina = vitrina,
		inventario = perfil.ownedItemIds,
		equipados = equipados,
	}
end

local entrar = Instance.new("RemoteFunction")
entrar.Name = "Entrar"
entrar.Parent = ReplicatedStorage
entrar.OnServerInvoke = function(jugador, modo, nivelId)
	if modo ~= "survival" and modo ~= "campaign" then
		return "Modo desconocido"
	end
	if nivelId ~= nil and type(nivelId) ~= "string" then
		return "Datos inválidos"
	end
	if estado:GetAttribute("Modo") ~= "hub" then
		return `{dueno and dueno.DisplayName or "Otro jugador"} está en una misión`
	end
	return iniciarPartida(jugador, modo, nivelId)
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
	elseif nombre == "invocar" and (arg == 1 or arg == 10) then
		local nuevas, err = Banner.invocar(perfil, arg, Banner.hora(os.time()), math.random)
		res.error = err
		res.nuevas = nuevas
	elseif nombre == "escuadron" and type(arg) == "table" then
		res.error = Unidades.fijarEscuadron(perfil, arg)
	elseif nombre == "vender" and type(arg) == "number" then
		local gemas, err = Unidades.vender(perfil, arg)
		res.error = err
		res.gemas = gemas
	elseif nombre == "evolucionar" and type(arg) == "table" then
		local nueva, err = Unidades.evolucionar(perfil, arg)
		res.error = err
		res.nueva = nueva
	elseif nombre == "comprar" and type(arg) == "string" then
		res.error = Objetos.comprar(perfil, arg)
	elseif nombre == "equipar" and type(arg) == "table" and type(arg.heroe) == "string" and type(arg.objeto) == "string" then
		res.error = Objetos.equipar(perfil, arg.heroe, arg.objeto)
	elseif nombre == "quitar" and type(arg) == "string" then
		res.error = Objetos.quitar(perfil, arg)
	elseif nombre ~= "estado" then
		res.error = "Acción desconocida"
	end
	if nombre ~= "estado" and not res.error then
		Perfiles.marcar(jugador)
		jugador:SetAttribute("Creditos", perfil.credits)
		jugador:SetAttribute("Gemas", perfil.gems)
	end
	res.estado = resumen(perfil)
	return res
end
