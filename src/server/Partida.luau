-- Una partida (docs/PARTIDA.md): su copia del mapa, enemigos, unidades de cada jugador, base con vida,
-- oleadas con «Listo», temporizador, saltar y velocidad. Se crea una por sala; Main las avanza en Heartbeat
-- y les pasa las acciones de sus jugadores. Las reglas de combate son las del 2D (Combate, Kits, Conductas).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
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
local Personajes = require(Shared.Personajes)
local Unidades = require(Shared.Unidades)
local Mejoras = require(Shared.Mejoras)
local Cuenta = require(Shared.Cuenta)
local Actos = require(Shared.Actos)
local Temporada = require(Shared.Temporada)
local Evento = require(Shared.Evento)
local Raid = require(Shared.Raid)
local Rasgos = require(Shared.Rasgos)
local Mascotas = require(Shared.Mascotas)
local Perfiles = require(script.Parent.Perfiles)
local Ranking = require(script.Parent.Ranking)

local heroes = Personajes.todos
local enemigosDatos = require(Data.enemies)
local niveles = require(Data.levels)
local tablaTipos = require(Data.TypeChart)
local items = require(Data.items)

local Partida = {}

Partida.BASE = 500
Partida.ESPERA = 60 -- segundos para «Listo» y entre oleadas
Partida.MAX_JUGADORES = 4
Partida.BONO_SALTAR = 0.10
Partida.REEMBOLSO = 0.5
local XP_OLEADA = 10 -- XP de unidad por oleada superada
local GEMAS_INFINITO, NUCLEO_INFINITO = 15, 10 -- cada 5 oleadas / cada 10 oleadas
Partida.PRIORIDADES = { "primero", "ultimo", "fuerte", "debil" }

local carpetaEstados = ReplicatedStorage:FindFirstChild("Partidas") or Instance.new("Folder")
carpetaEstados.Name = "Partidas"
carpetaEstados.Parent = ReplicatedStorage
local carpetaMundo = workspace:FindFirstChild("Partidas") or Instance.new("Folder")
carpetaMundo.Name = "Partidas"
carpetaMundo.Parent = workspace

local COLORES = {
	["Tecnológico"] = Color3.fromRGB(120, 140, 170),
	["Místico"] = Color3.fromRGB(170, 90, 200),
	["Mutante"] = Color3.fromRGB(220, 170, 50),
	["Cósmico"] = Color3.fromRGB(70, 60, 160),
	["Urbano"] = Color3.fromRGB(170, 60, 60),
}
local COLOR_MUNICION = {
	explosive = Color3.fromHex("ff9d3d"),
	cryo = Color3.fromHex("7ce7ff"),
	piercing = Color3.fromHex("d8f0ff"),
}

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

local function modeloProvisional(config): Model
	local m = Instance.new("Model")
	local cuerpo = Instance.new("Part")
	cuerpo.Name = "HumanoidRootPart"
	cuerpo.Size = Vector3.new(2, 4, 2)
	cuerpo.Color = COLORES[config.category] or Color3.fromRGB(110, 110, 120)
	cuerpo.Parent = m
	m.PrimaryPart = cuerpo
	local barra = cartel(cuerpo, config.name, 3)
	barra.Parent.Visible = false
	return m
end

-- Plantilla de ServerStorage.Plantillas.Heroes/<id base>: R15 con atributos AnimacionAtaque y VelocidadAtaque.
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

local function ponerRaiz(u, cf: CFrame)
	u.modelo:PivotTo(cf * u.raiz.CFrame:ToObjectSpace(u.modelo:GetPivot()))
end

local function pieza(padre: Instance, tam: Vector3, color: Color3, cf: CFrame): Part
	local f = Instance.new("Part")
	f.Anchored, f.CanCollide, f.CanQuery = true, false, false
	f.Size = tam
	f.Color = color
	f.Material = Enum.Material.Neon
	f.CFrame = cf
	f.Parent = padre
	return f
end

local function animarYBorrar(f: Part, segundos: number, meta)
	local t = TweenService:Create(f, TweenInfo.new(segundos, Enum.EasingStyle.Quad), meta)
	t.Completed:Once(function()
		f:Destroy()
	end)
	t:Play()
end

-- Escuadrón de un jugador para la partida: { uid, heroId, nivel, limite }.
local function escuadronDe(perfil)
	local r, texto = {}, {}
	for _, uid in perfil.squad do
		local u = Unidades.buscar(perfil, uid)
		if u then
			local e = { uid = uid, heroId = u.heroId, nivel = u.level, limite = Unidades.LIMITE_COLOCACION[heroes[u.heroId].rarity] or 1, rasgo = u.rasgo, grados = u.grados }
			table.insert(r, e)
			table.insert(texto, `{e.uid}:{e.heroId}:{e.nivel}:{e.limite}`)
		end
	end
	return r, table.concat(texto, ",")
end

-- op: { id, indice (mapa en levels.json), acto (1–5, "infinito", "evento" o "raid"), pesadilla, jugadores, anfitrion, origen, aviso, alSalir }
function Partida.nueva(op)
	local p = {}
	local NIVEL, INDICE_NIVEL = niveles[op.indice], op.indice - 1
	local infinito = op.acto == "infinito"
	-- Desafío semanal (docs/EVENTO.md): oleadas sin fin hasta Evento.OLEADAS con los modificadores de la semana.
	local esEvento = op.acto == "evento"
	local sinFin = infinito or esEvento
	local efectos = if esEvento then Evento.efectos(Evento.desafio(Evento.semana(os.time()))) else Evento.efectos({ modificadores = {} })
	local BASE = math.floor(Partida.BASE * efectos.base)
	local modo = if sinFin then "survival" else "campaign"
	local pesadilla = op.pesadilla and not sinFin
	local superadas, derrotados = 0, 0 -- para el puntaje del evento
	-- Raid (docs/RAIDS.md): 5 oleadas de esbirros y el jefe de la semana con fases.
	local esRaid = op.acto == "raid"
	local jefeRaid = Raid.jefe(Raid.semana(os.time()))
	local jefeVivo = nil -- el enemigo jefe mientras está en el mapa
	local danoJefe = {} -- [Player] = daño hecho al jefe
	local function nombreActo(): string
		return if infinito then "Infinito" elseif esEvento then "Evento" elseif esRaid then "Raid" else tostring(op.acto)
	end
	local origen: Vector3 = op.origen
	local terminada = false

	local mundo = Instance.new("Model")
	mundo.Name = "Partida_" .. op.id
	mundo.Parent = carpetaMundo
	local carpetaEnemigos = Instance.new("Folder")
	carpetaEnemigos.Name = "Enemigos"
	carpetaEnemigos.Parent = mundo
	local carpetaUnidades = Instance.new("Folder")
	carpetaUnidades.Name = "Unidades"
	carpetaUnidades.Parent = mundo
	local rutaPx = Mapa.rutaPixeles(NIVEL)
	local ruta = Mapa.construir(NIVEL, origen, mundo)
	local largoTramo, largoTotal = {}, 0
	for i = 1, #ruta - 1 do
		largoTramo[i] = (ruta[i + 1] - ruta[i]).Magnitude
		largoTotal += largoTramo[i]
	end

	-- Estado visible para los clientes de esta partida.
	local estado = Instance.new("Folder")
	estado.Name = op.id
	local function fijar(nombre, valor)
		estado:SetAttribute(nombre, valor)
	end
	fijar("Nivel", NIVEL.id)
	fijar("NombreNivel", if esEvento then "Desafío · " .. NIVEL.name else NIVEL.name)
	fijar("Acto", nombreActo())
	fijar("Pesadilla", pesadilla)
	fijar("Origen", origen)
	fijar("Base", BASE)
	fijar("BaseMax", BASE)
	fijar("Oleada", 0)
	fijar("OleadasTotal", if infinito then 0 elseif esEvento then Evento.OLEADAS elseif esRaid then Raid.OLEADAS_ESBIRROS + 1 else Actos.OLEADAS)
	fijar("Fase", "listo")
	fijar("Mensaje", "")
	fijar("Velocidad", 1)
	fijar("FinTemporizador", 0)
	fijar("Anfitrion", op.anfitrion.UserId)
	estado.Parent = carpetaEstados
	p.estado = estado
	p.id = op.id

	local function aviso(texto: string, jugador: Player?)
		if jugador then
			op.aviso:FireClient(jugador, texto)
		else
			for j in p.jugadores do
				op.aviso:FireClient(j, texto)
			end
		end
	end

	-- Jugadores: dinero propio, escuadrón y votos.
	p.jugadores = {}
	local function agregar(j: Player)
		local perfil = Perfiles.de(j)
		local esc, texto = escuadronDe(perfil)
		-- Bonos de las mascotas equipadas, fijos durante la partida (docs/MASCOTAS.md).
		p.jugadores[j] = { escuadron = esc, listo = false, saltar = false, auto = false, bonos = if perfil then Mascotas.bonos(perfil) else Mascotas.bonos({ mascotas = Mascotas.nuevo() }) }
		j:SetAttribute("Partida", op.id)
		j:SetAttribute("Dinero", if esRaid then Raid.DINERO else math.floor(Mejoras.DINERO_INICIAL * efectos.dinero))
		j:SetAttribute("Escuadron", texto)
		j:SetAttribute("Listo", false)
		j:SetAttribute("Auto", false)
		-- Aparece en el borde del mapa, junto a la base, mirando hacia el campo.
		if j.Character then
			local base = ruta[#ruta]
			local llegada = base + (ruta[#ruta - 1] - base).Unit * 6 + Vector3.new(0, 8, 0)
			j.Character:PivotTo(CFrame.lookAt(llegada, ruta[#ruta - 1] + Vector3.new(0, 8, 0)))
		end
	end
	for _, j in op.jugadores do
		agregar(j)
	end
	-- Avance de misiones y XP de pase (docs/TEMPORADA.md).
	local function evento(j: Player?, nombre: string, n: number, xpPase: number?)
		local perfil = j and Perfiles.de(j)
		if perfil then
			Temporada.registrar(perfil, nombre, n, os.time())
			if xpPase then
				Temporada.ganarXP(perfil, xpPase, os.time())
			end
			Perfiles.marcar(j)
		end
	end

	local function dar(j: Player?, n: number)
		if j and p.jugadores[j] then
			n = math.floor(n * (1 + p.jugadores[j].bonos.dinero) + 0.5)
			j:SetAttribute("Dinero", (j:GetAttribute("Dinero") or 0) + n)
		end
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

	------------------------------------------------------------------------------
	-- Enemigos
	------------------------------------------------------------------------------
	local enemigos = {}
	local function moverEnemigo(e, cf: CFrame)
		e.cuerpo.CFrame = cf
		if e.modelo then
			e.modelo:PivotTo(cf)
		end
	end

	local function crearEnemigo(config, avanceInicial: number?)
		if pesadilla then
			config = table.clone(config)
			config.hp = math.floor(config.hp * Actos.PESADILLA.vida + 0.5)
			config.speed = config.speed * Actos.PESADILLA.velocidad
		end
		if esEvento then
			config = table.clone(config)
			config.hp = math.floor(config.hp * efectos.vida + 0.5)
			config.speed = config.speed * efectos.velocidad
		end
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
		cuerpo:SetAttribute("Vida", math.ceil(e.vida)) -- el cliente dibuja los números de daño
		moverEnemigo(e, CFrame.new(puntoEnRuta(e.avance) + Vector3.new(0, e.altura, 0)))
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

	-- Refleja la vida; si murió, paga la recompensa a quien le dio el último golpe y lo saca.
	local function revisar(e)
		if not table.find(enemigos, e) then
			return
		end
		e.barra.Size = UDim2.fromScale(math.max(0, e.vida / e.vidaMax), 1)
		e.cuerpo:SetAttribute("Vida", math.max(0, math.ceil(e.vida)))
		if e == jefeVivo then
			-- Daño por jugador (misiones de raid) y fases: refuerzos y furia al 66 % y 33 %.
			local antes = e.vidaVista or e.vidaMax
			local ahora = math.max(0, e.vida)
			if e.ultimoAtacante then
				danoJefe[e.ultimoAtacante] = (danoJefe[e.ultimoAtacante] or 0) + (antes - ahora)
			end
			e.vidaVista = ahora
			fijar("JefeVida", math.ceil(ahora))
			for _ = 1, Raid.fasesCruzadas(antes / e.vidaMax, ahora / e.vidaMax) do
				e.config.speed *= Raid.FURIA
				aviso(`¡{string.upper(e.config.name)} SE ENFURECE! Llegan refuerzos`)
				local ids = {}
				for id in enemigosDatos.normal do
					table.insert(ids, id)
				end
				table.sort(ids)
				for i = 1, Raid.REFUERZOS do
					local config = table.clone(enemigosDatos.normal[ids[math.random(#ids)]])
					config.reward = 0
					task.delay(i * 0.4, crearEnemigo, config, math.max(0, e.avance - 2))
				end
			end
		end
		if e.vida <= 0 then
			-- Rasgo Mercenario: más dinero si el último golpe fue de esa unidad.
			local extra = if e.ultimaUnidad then Rasgos.dinero(e.ultimaUnidad) else 0
			dar(e.ultimoAtacante, math.floor((e.config.reward or 0) * (1 + extra) + 0.5))
			evento(e.ultimoAtacante, "derrota", 1)
			derrotados += 1
			quitarEnemigo(e)
		end
	end

	local enPixeles = {}
	local function actualizarPixeles()
		table.clear(enPixeles)
		for _, e in enemigos do
			local x, y = Mapa.aPixeles(e.cuerpo.Position, origen)
			table.insert(enPixeles, { e = e, x = x, y = y, avance = e.avance })
		end
	end

	local function vivo(e)
		return e.vida > 0 and e.cuerpo.Parent ~= nil
	end

	------------------------------------------------------------------------------
	-- Unidades
	------------------------------------------------------------------------------
	local unidades = {}
	local siguienteUid = 1

	local function vidasEquivalentes(): number
		-- Los bonus "lowLife" del 2D valen con 10 vidas de 20: aquí, con la base al 50 % o menos.
		return math.ceil(estado:GetAttribute("Base") / BASE * 20)
	end

	local function statsUnidad(u)
		local s = Progresion.stats(u.config, 1, u.objeto, vidasEquivalentes(), true)
		local m = Mejoras.efecto(u.config, u.mejora)
		s.damage *= (1 + m.dano) * Unidades.bonoDano(u.nivelUnidad)
		s.range *= 1 + m.alcance
		s.fireRate *= 1 + m.cadencia
		Rasgos.aplicar(s, u) -- rasgo y grados (docs/RASGOS.md)
		local d = p.jugadores[u.dueno]
		s.damage *= 1 + (if d then d.bonos.dano else 0) -- mascotas
		u.kit.activa = m.habilidad
		u.kit.potencia = m.potencia
		-- Lo que muestra el panel de la unidad (alcance en studs).
		u.modelo:SetAttribute("Dano", math.floor(s.damage + 0.5))
		u.modelo:SetAttribute("Alcance", math.floor(s.range * Mapa.ESCALA + 0.5))
		u.modelo:SetAttribute("Cadencia", math.floor(s.fireRate * 100 + 0.5) / 100)
		return s
	end

	local function ubicar(u)
		local alto = if u.modelo:FindFirstChildOfClass("Humanoid") then u.modelo.Humanoid.HipHeight + u.raiz.Size.Y / 2 else u.raiz.Size.Y / 2
		-- Apoyada sobre la superficie real (techos y plataformas de montaña son más altos).
		local suelo = origen + Vector3.new(u.x * Mapa.ESCALA, Mapa.alturaSuelo(NIVEL, u.x, u.y), u.y * Mapa.ESCALA)
		ponerRaiz(u, CFrame.new(suelo + Vector3.new(0, alto + 0.1, 0)))
	end

	local function listaUnidades()
		local l = {}
		for _, u in unidades do
			table.insert(l, { uid = u.uid, heroe = u.heroe, x = u.x, y = u.y })
		end
		return l
	end

	-- Unidad colocada por `jugador` (sólo el dueño la puede tocar).
	local function suya(jugador, uid)
		for i, u in unidades do
			if u.uid == uid and u.dueno == jugador then
				return u, i
			end
		end
		return nil
	end

	local ACCIONES = {}

	function ACCIONES.colocar(j: Player, ranura: number, x: number, y: number)
		local e
		for _, entrada in p.jugadores[j].escuadron do
			if entrada.uid == ranura then
				e = entrada
			end
		end
		if not e then
			return "Esa unidad no está en tu escuadrón"
		end
		local puestas = 0
		for _, u in unidades do
			if u.dueno == j and u.ranura == ranura then
				puestas += 1
			end
		end
		if puestas >= e.limite then
			return `Ya colocaste esta unidad {e.limite} {if e.limite == 1 then "vez" else "veces"} (máximo de su rareza)`
		end
		local config = heroes[e.heroId]
		local costo = Mejoras.costoColocar(config)
		local dinero = j:GetAttribute("Dinero")
		if dinero < costo then
			return `Faltan {costo - dinero} 💰 para colocar {config.name}`
		end
		local perfil = Perfiles.de(j)
		local objeto = perfil and Objetos.de(perfil, e.heroId)
		local err, cx, cy = Despliegue.error(Progresion.paraDespliegue(config, 1, objeto), x, y, NIVEL, rutaPx, listaUnidades(), nil, true, true)
		if err then
			return err
		end
		j:SetAttribute("Dinero", dinero - costo)
		local base = Personajes.base(e.heroId)
		local modelo, raiz, ataque, velocidadAtaque = crearModelo(config)
		local u = {
			uid = siguienteUid,
			dueno = j,
			ranura = ranura,
			heroe = base,
			x = cx,
			y = cy,
			config = config,
			nivel = 1,
			mejora = 0,
			invertido = costo,
			prioridad = "primero",
			nivelUnidad = e.nivel,
			rasgo = e.rasgo,
			grados = e.grados,
			objeto = objeto,
			modelo = modelo,
			raiz = raiz,
			espera = 0,
			ataque = ataque,
			velocidadAtaque = velocidadAtaque,
			kit = Kits.nuevo(base),
		}
		u.stats = statsUnidad(u)
		siguienteUid += 1
		modelo:SetAttribute("Uid", u.uid)
		modelo:SetAttribute("Dueno", j.UserId)
		modelo:SetAttribute("Heroe", e.heroId)
		modelo:SetAttribute("Ranura", ranura)
		modelo:SetAttribute("NivelUnidad", e.nivel)
		modelo:SetAttribute("Rasgo", e.rasgo)
		local g = Rasgos.grados(e)
		modelo:SetAttribute("Grados", `{g.dano}/{g.alcance}/{g.cadencia}`)
		modelo:SetAttribute("Mejora", 0)
		modelo:SetAttribute("Invertido", costo)
		modelo:SetAttribute("Prioridad", "primero")
		modelo:SetAttribute("Municion", if base == "hawkeye" then "explosive" else nil)
		ubicar(u)
		modelo.Parent = carpetaUnidades
		table.insert(unidades, u)
		evento(j, "colocar", 1)
		return nil
	end

	function ACCIONES.mover(j: Player, uid: number, x: number, y: number)
		local u = suya(j, uid)
		if not u then
			return "Héroe no disponible"
		end
		local err, cx, cy = Despliegue.error(Progresion.paraDespliegue(u.config, 1, u.objeto), x, y, NIVEL, rutaPx, listaUnidades(), uid, true, true)
		if err then
			return err
		end
		u.x, u.y = cx, cy
		ubicar(u)
		return nil
	end

	-- Vender devuelve el 50 % de lo invertido (colocar + mejoras).
	function ACCIONES.vender(j: Player, uid: number)
		if efectos.sinVender then
			return "En este desafío no se puede vender"
		end
		local u, i = suya(j, uid)
		if not u then
			return "Héroe no disponible"
		end
		table.remove(unidades, i)
		u.modelo:Destroy()
		dar(j, math.floor(u.invertido * Partida.REEMBOLSO))
		return nil
	end

	function ACCIONES.mejorar(j: Player, uid: number)
		local u = suya(j, uid)
		if not u then
			return "Héroe no disponible"
		end
		local siguiente = Mejoras.lista(u.config)[u.mejora + 1]
		if not siguiente then
			return "Ya tiene todas las mejoras"
		end
		local dinero = j:GetAttribute("Dinero")
		if dinero < siguiente.costo then
			return `Faltan {siguiente.costo - dinero} 💰`
		end
		u.mejora += 1
		u.invertido += siguiente.costo
		u.stats = statsUnidad(u)
		u.modelo:SetAttribute("Mejora", u.mejora)
		u.modelo:SetAttribute("Invertido", u.invertido)
		j:SetAttribute("Dinero", dinero - siguiente.costo)
		evento(j, "mejorar", 1)
		return nil
	end

	function ACCIONES.prioridad(j: Player, uid: number)
		local u = suya(j, uid)
		if not u then
			return "Héroe no disponible"
		end
		local i = table.find(Partida.PRIORIDADES, u.prioridad) or 1
		u.prioridad = Partida.PRIORIDADES[i % #Partida.PRIORIDADES + 1]
		u.modelo:SetAttribute("Prioridad", u.prioridad)
		return nil
	end

	-- Carcaj de Hawkeye: cambia de munición; conserva la carga, como setMode del 2D.
	function ACCIONES.municion(j: Player, uid: number)
		local u = suya(j, uid)
		if not u or not u.kit.modo then
			return "Ese héroe no cambia de munición"
		end
		local i = table.find(Kits.MODOS_HAWKEYE, u.kit.modo)
		u.kit.modo = Kits.MODOS_HAWKEYE[i % #Kits.MODOS_HAWKEYE + 1]
		u.modelo:SetAttribute("Municion", u.kit.modo)
		return nil
	end

	function ACCIONES.listo(j: Player)
		p.jugadores[j].listo = true
		j:SetAttribute("Listo", true)
		return nil
	end

	function ACCIONES.saltar(j: Player)
		p.jugadores[j].saltar = true
		return nil
	end

	function ACCIONES.auto(j: Player)
		local d = p.jugadores[j]
		d.auto = not d.auto
		j:SetAttribute("Auto", d.auto)
		return nil
	end

	function ACCIONES.velocidad(j: Player)
		if j ~= op.anfitrion then
			return "Sólo el anfitrión cambia la velocidad"
		end
		fijar("Velocidad", if estado:GetAttribute("Velocidad") == 1 then 2 else 1)
		return nil
	end

	-- Frontera de confianza: tipos validados en Main; aquí, que la partida siga en juego.
	function p.accion(j: Player, nombre: string, a, b, c)
		local f = ACCIONES[nombre]
		if not f or not p.jugadores[j] then
			return "Acción desconocida"
		end
		if terminada then
			return "La partida ya terminó"
		end
		return f(j, a, b, c)
	end

	------------------------------------------------------------------------------
	-- Ataque de las unidades
	------------------------------------------------------------------------------
	local EFECTOS = {
		flecha = function(desde: Vector3, hasta: Vector3, color: Color3?)
			local f = pieza(mundo, Vector3.new(0.15, 0.15, 1.6), color or Color3.fromRGB(150, 80, 230), CFrame.lookAt(desde, hasta))
			animarYBorrar(f, 0.12, { CFrame = CFrame.lookAt(hasta, hasta + (hasta - desde)) })
		end,
		rayo = function(desde: Vector3, hasta: Vector3)
			local largo = (hasta - desde).Magnitude
			local f = pieza(mundo, Vector3.new(0.2, 0.2, largo), Color3.fromRGB(90, 190, 255), CFrame.lookAt(desde, hasta) * CFrame.new(0, 0, -largo / 2))
			animarYBorrar(f, 0.15, { Transparency = 1, Size = Vector3.new(0.05, 0.05, largo) })
		end,
		impacto = function(_desde: Vector3, hasta: Vector3, color: Color3?, radio: number?)
			local d = (radio or 2) * 2
			local f = pieza(mundo, Vector3.new(1, 1, 1), color or Color3.fromRGB(190, 130, 80), CFrame.new(hasta))
			f.Shape = Enum.PartType.Ball
			f.Material = Enum.Material.Slate
			f.Transparency = 0.3
			animarYBorrar(f, 0.25, { Transparency = 1, Size = Vector3.new(d, d, d) })
		end,
	}

	-- Elige el blanco según la prioridad de la unidad.
	local function mejorBlanco(u, a, b): boolean
		if u.prioridad == "ultimo" then
			return a.avance < b.avance
		elseif u.prioridad == "fuerte" then
			return a.e.vida > b.e.vida
		elseif u.prioridad == "debil" then
			return a.e.vida < b.e.vida
		end
		return a.avance > b.avance
	end

	local function actualizarUnidad(u, dt)
		if (u.aturdido or 0) > 0 then
			u.aturdido -= dt
			return
		end
		local heroe = { x = u.x, y = u.y, alcance = u.stats.range, ve = u.stats.canSeeStealth }
		local pisoton = Kits.actualizar(u.kit, dt, u.config, u.stats, heroe, enPixeles)
		if pisoton then
			for _, g in pisoton do
				Combate.danar(g.enemigo, g.golpe, 1, tablaTipos)
				g.enemigo.ultimoAtacante = u.dueno
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
		local objetivo
		for _, c in enPixeles do
			local visible = not Combate.sigilo(c.e) or u.stats.canSeeStealth
			if vivo(c.e) and visible and Despliegue.enAlcance(u.x, u.y, c.x, c.y, u.stats.range, u.config.rangePattern) and (not objetivo or mejorBlanco(u, c, objetivo)) then
				objetivo = c
			end
		end
		if not objetivo then
			return
		end
		u.stats = statsUnidad(u)
		u.espera = 1 / u.stats.fireRate
		local destino = objetivo.e.cuerpo.Position
		local pos = u.raiz.Position
		ponerRaiz(u, CFrame.lookAt(pos, Vector3.new(destino.X, pos.Y, destino.Z)))
		if u.ataque then
			u.ataque:Play(0.05, 1, u.velocidadAtaque)
		end
		local critico = math.random() * 100 < u.stats.critChance
		local distancia = math.sqrt((objetivo.x - u.x) ^ 2 + (objetivo.y - u.y) ^ 2)
		local golpe = Kits.golpe(u.kit, u.config, objetivo.e, if critico then u.stats.damage * u.stats.critDamage else u.stats.damage, u.stats, u.objeto, distancia)
		local efecto = EFECTOS[u.modelo:GetAttribute("Efecto")] or EFECTOS.flecha
		efecto(pos + Vector3.new(0, 1, 0), destino, COLOR_MUNICION[u.kit.modo])

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
		local pct = u.objeto and u.objeto.effects.onHitCreditPct
		if pct and (objetivo.e.config.reward or 0) > 0 then
			dar(u.dueno, math.max(1, math.ceil(objetivo.e.config.reward * pct)))
		end
		if (golpe.radioSplash or 0) > 0 then
			EFECTOS.impacto(nil, destino, COLOR_MUNICION[u.kit.modo], golpe.radioSplash * Mapa.ESCALA)
		end
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
			e.ultimoAtacante = u.dueno
			e.ultimaUnidad = u
			revisar(e)
		end
	end

	local entornoConductas = {
		aliados = function(e, radio)
			local ex, ey = Mapa.aPixeles(e.cuerpo.Position, origen)
			local r = {}
			for _, otro in enemigos do
				if otro ~= e and vivo(otro) then
					local ox, oy = Mapa.aPixeles(otro.cuerpo.Position, origen)
					if math.sqrt((ox - ex) ^ 2 + (oy - ey) ^ 2) <= radio then
						table.insert(r, otro)
					end
				end
			end
			return r
		end,
		invocar = function(id, origenEnemigo, factorVida)
			local base = enemigosDatos.normal[id]
			if not base then
				return false
			end
			local config = table.clone(base)
			config.hp = math.floor(base.hp * factorVida + 0.5)
			config.reward = 0
			crearEnemigo(config, origenEnemigo.avance)
			return true
		end,
		aviso = function(texto)
			aviso(texto)
		end,
		aturdirHeroes = function(segundos)
			for _, u in unidades do
				u.aturdido = segundos
			end
		end,
	}

	-- Un paso de simulación (Main lo llama en Heartbeat).
	function p.paso(dt: number)
		if terminada then
			return
		end
		dt *= estado:GetAttribute("Velocidad")
		for i = #enemigos, 1, -1 do
			local e = enemigos[i]
			local velocidad, murio = Combate.actualizar(e, dt)
			if murio then
				revisar(e)
				continue
			end
			velocidad *= Conductas.actualizar(e, dt, entornoConductas)
			e.barra.Size = UDim2.fromScale(math.clamp(e.vida / e.vidaMax, 0, 1), 1)
			e.avance += e.config.speed * velocidad * Mapa.ESCALA * dt
			if e.avance >= largoTotal then
				-- La base pierde la vida restante del enemigo ÷ 10 (mínimo 5); un jefe la destruye.
				local base = estado:GetAttribute("Base")
				local perdida = if e.config.isBoss then base else math.max(5, math.ceil(e.vida / 10))
				fijar("Base", math.max(0, base - perdida))
				quitarEnemigo(e)
			else
				local aqui = puntoEnRuta(e.avance)
				local adelante = puntoEnRuta(e.avance + 0.5)
				local alto = Vector3.new(0, e.altura, 0)
				moverEnemigo(e, if (adelante - aqui).Magnitude > 1e-3 then CFrame.lookAt(aqui + alto, adelante + alto) else CFrame.new(aqui + alto))
			end
		end
		actualizarPixeles()
		-- Runas del Sanctum: marcan a los enemigos cercanos (+12 % de daño recibido).
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
	end

	------------------------------------------------------------------------------
	-- Oleadas
	------------------------------------------------------------------------------
	local function ahora()
		return workspace:GetServerTimeNow()
	end

	-- Espera `segundos` de partida (respeta la velocidad x2); false si la partida terminó.
	local function esperar(segundos: number): boolean
		local fin = ahora() + segundos / estado:GetAttribute("Velocidad")
		while ahora() < fin do
			if terminada then
				return false
			end
			task.wait(0.05)
		end
		return not terminada
	end

	local function todos(campo: string): boolean
		for _, d in p.jugadores do
			if not (d[campo] or (campo == "saltar" and d.auto)) then
				return false
			end
		end
		return next(p.jugadores) ~= nil
	end

	local function derrota(): boolean
		return estado:GetAttribute("Base") <= 0
	end

	local function terminar(mensaje: string)
		terminada = true
		local gano = string.sub(mensaje, 1, 7) ~= "Derrota"
		fijar("Resultado", if gano then "victoria" else "derrota")
		if esRaid then
			for j in p.jugadores do
				local perfil = Perfiles.de(j)
				if perfil then
					local premio = Raid.terminar(perfil, gano, danoJefe[j] or 0, os.time(), math.random)
					local extra = math.floor(premio.gemas * p.jugadores[j].bonos.gemas + 0.5) -- mascotas
					perfil.gems += extra
					premio.gemas += extra
					Perfiles.marcar(j)
					j:SetAttribute("Gemas", perfil.gems)
					j:SetAttribute("Nucleos", perfil.cores)
					local partes = { `Daño al jefe: {math.floor(danoJefe[j] or 0)}` }
					if premio.gemas > 0 then
						table.insert(partes, `+{premio.gemas} gemas · +{premio.nucleos} núcleos`)
					end
					table.insert(partes, `+{premio.fragmentos} fragmentos · +{premio.fichasRaid} fichas de raid`)
					if premio.objeto then
						table.insert(partes, `¡{items[premio.objeto].name}!`)
					end
					j:SetAttribute("PremioActo", table.concat(partes, " · "))
				end
			end
		end
		if esEvento then
			-- Puntaje del intento: fichas, mejor puntaje y ranking de la semana.
			local puntos = Evento.puntos(superadas, derrotados)
			for j in p.jugadores do
				local perfil = Perfiles.de(j)
				if perfil then
					local fichas, record = Evento.registrar(perfil, puntos, os.time())
					Ranking.anotar("evento", j.UserId, perfil.evento.mejor)
					Perfiles.marcar(j)
					j:SetAttribute("PremioActo", `{puntos} puntos · +{fichas} fichas` .. (if record then " · ¡RÉCORD!" else ""))
				end
			end
		end
		-- Qué se puede votar en la pantalla final.
		local opciones = {}
		if gano and not sinFin and op.acto < Actos.POR_MAPA then
			table.insert(opciones, "siguiente")
		elseif gano and not sinFin and Actos.MAPAS[(table.find(Actos.MAPAS, NIVEL.id) or 0) + 1] then
			table.insert(opciones, "mapa")
		end
		table.insert(opciones, "repetir")
		fijar("Opciones", table.concat(opciones, ","))
		fijar("Fase", "fin")
		fijar("Mensaje", mensaje)
		for j in p.jugadores do
			task.spawn(Perfiles.guardar, j)
		end
	end

	-- Premios de cada oleada superada: XP de unidades y de cuenta; en Infinito, gemas y núcleos.
	local function premiarOleada(n: number)
		superadas = n
		for j, d in p.jugadores do
			evento(j, "oleada", 1, Temporada.XP_OLEADA)
			if infinito then
				evento(j, "infinito", n)
			end
			local perfil = Perfiles.de(j)
			if perfil then
				local premios = {}
				local xp = math.floor(XP_OLEADA * (if Oleadas.dificultad(NIVEL) == "hard" then 1.5 else 1) * (1 + d.bonos.xp))
				for _, e in d.escuadron do
					local u = Unidades.buscar(perfil, e.uid)
					if u then
						Unidades.ganarXP(u, xp)
					end
				end
				if Cuenta.ganarXP(perfil, math.floor((if infinito then Cuenta.XP_OLEADA_INFINITO else Cuenta.XP_OLEADA) * (1 + d.bonos.xp))) > 0 then
					table.insert(premios, `¡Nivel de cuenta {perfil.level}!`)
				end
				if infinito then
					local r = perfil.modeRecords.survival
					r.bestWave = math.max(r.bestWave, n)
					Ranking.anotar("infinito", j.UserId, r.bestWave)
					if n % 5 == 0 then
						local gemas = math.floor(GEMAS_INFINITO * (1 + d.bonos.gemas) + 0.5)
						perfil.gems += gemas
						table.insert(premios, `+{gemas} gemas`)
					end
					if n % NUCLEO_INFINITO == 0 then
						perfil.cores += 1
						table.insert(premios, "+1 núcleo")
					end
				end
				Perfiles.marcar(j)
				j:SetAttribute("Nivel", perfil.level)
				j:SetAttribute("XP", perfil.xp)
				j:SetAttribute("Gemas", perfil.gems)
				j:SetAttribute("Nucleos", perfil.cores)
				if #premios > 0 then
					aviso(table.concat(premios, " · "), j)
				end
			end
		end
	end

	local function bucle()
		-- Primera oleada: cuando todos aprietan «Listo» o a los 60 s.
		fijar("Fase", "listo")
		fijar("FinTemporizador", ahora() + Partida.ESPERA)
		fijar("Mensaje", "¿Listos? Colocá tus unidades y apretá «Listo»")
		while not terminada and not todos("listo") and ahora() < estado:GetAttribute("FinTemporizador") do
			task.wait(0.1)
		end
		local total = if infinito then math.huge elseif esEvento then Evento.OLEADAS elseif esRaid then Raid.OLEADAS_ESBIRROS + 1 else Actos.OLEADAS
		local n = 0
		local generando = 0 -- oleadas que todavía están sacando enemigos
		while not terminada and n < total do
			n += 1
			fijar("Oleada", n)
			fijar("Fase", "combate")
			for j, d in p.jugadores do
				d.saltar = false
			end
			local equipo = {}
			for _, u in unidades do
				table.insert(equipo, u.config)
			end
			local oleada2D = if sinFin then n elseif esRaid then n * 2 else Actos.oleada2D(op.acto, n)
			local jefe = if sinFin then nil elseif esRaid or n ~= Actos.OLEADAS then false else op.acto
			local cola, mod = Oleadas.preparar(oleada2D, enemigosDatos, NIVEL, INDICE_NIVEL, equipo, modo, jefe)
			fijar("Mensaje", `Oleada {n}: {mod.nombre}` .. (if n == Actos.OLEADAS and not sinFin and not esRaid then " · ¡JEFE!" else ""))
			if esRaid and n > Raid.OLEADAS_ESBIRROS then
				-- Oleada final: sólo el jefe de raid, con vida según los jugadores, lento y con fases.
				local base = enemigosDatos.bosses[jefeRaid.id]
				local config = table.clone(base)
				local cuantos = 0
				for _ in p.jugadores do
					cuantos += 1
				end
				config.hp = Raid.vidaJefe(base.armor, cuantos)
				config.speed = base.speed * Raid.VELOCIDAD_JEFE
				config.reward = 0
				config.isBoss = true
				cola = { { espera = 1, enemigo = config, jefeRaid = true } }
				fijar("Mensaje", `¡JEFE DE RAID: {string.upper(base.name)}!`)
			end
			generando += 1
			local completa = false -- ya salieron todos los enemigos de esta oleada
			task.spawn(function()
				for _, entrada in cola do
					if not esperar(entrada.espera) or derrota() then
						break
					end
					local e = crearEnemigo(entrada.enemigo)
					if entrada.jefeRaid then
						jefeVivo = e
						fijar("NombreJefe", e.config.name)
						fijar("JefeVidaMax", e.vidaMax)
						fijar("JefeVida", e.vidaMax)
					end
				end
				generando -= 1
				completa = true
			end)
			-- Siguiente oleada: al limpiar, al vencer el temporizador o si todos saltan (la última hay que limpiarla).
			fijar("FinTemporizador", ahora() + Partida.ESPERA)
			local salto = false
			while not terminada and not derrota() do
				local limpia = generando == 0 and #enemigos == 0
				if limpia then
					break
				end
				if n < total and ahora() >= estado:GetAttribute("FinTemporizador") then
					break
				end
				-- Saltar sólo cuando la oleada terminó de salir: si no, se encadenan bonos sin pelear.
				if n < total and completa and todos("saltar") then
					salto = true
					break
				end
				task.wait(0.1)
			end
			if terminada then
				return
			end
			if derrota() then
				terminar(`Derrota en la oleada {n}` .. (if sinFin or esRaid then "" else ` del acto {op.acto}`))
				return
			end
			local bono = Mejoras.BONO_OLEADA + math.floor(estado:GetAttribute("Base") * Mejoras.BONO_VIDA / 25)
			if salto then
				bono = math.floor(bono * (1 + Partida.BONO_SALTAR))
			end
			for j in p.jugadores do
				dar(j, bono)
			end
			premiarOleada(n)
		end
		-- Victoria del acto: quedan por limpiar las oleadas salteadas.
		while not terminada and not derrota() and (generando > 0 or #enemigos > 0) do
			task.wait(0.1)
		end
		if terminada then
			return
		end
		if derrota() then
			terminar(`Derrota en el acto {op.acto}`)
			return
		end
		if esEvento then
			terminar(`¡Desafío superado! {Evento.OLEADAS} oleadas`)
			return
		end
		if esRaid then
			terminar(`¡Raid superada! {enemigosDatos.bosses[jefeRaid.id].name} derrotado`)
			return
		end
		for j in p.jugadores do
			local perfil = Perfiles.de(j)
			if perfil then
				local premio = Actos.ganar(perfil, NIVEL.id, op.acto, pesadilla)
				local extra = math.floor(premio.gemas * p.jugadores[j].bonos.gemas + 0.5) -- mascotas
				perfil.gems += extra
				premio.gemas += extra
				evento(j, "acto", 1, Temporada.XP_ACTO)
				Cuenta.ganarXP(perfil, Cuenta.XP_MAPA)
				Perfiles.marcar(j)
				j:SetAttribute("Gemas", perfil.gems)
				j:SetAttribute("Nucleos", perfil.cores)
				j:SetAttribute("Nivel", perfil.level)
				j:SetAttribute("XP", perfil.xp)
				j:SetAttribute("PremioActo", `+{premio.gemas} gemas` .. (if premio.nucleos > 0 then ` · +{premio.nucleos} núcleo` else "") .. (if premio.primera then " (primera vez)" else "") .. ` · +{Cuenta.XP_MAPA} XP`)
			end
		end
		terminar(`¡Victoria! {NIVEL.name} · Acto {op.acto}` .. (if pesadilla then " · Pesadilla" else ""))
	end
	task.spawn(bucle)

	------------------------------------------------------------------------------
	-- Pantalla final: votos para repetir, siguiente acto o siguiente mapa (Main decide y ejecuta)
	------------------------------------------------------------------------------
	local OPCIONES = { "siguiente", "mapa", "repetir" }

	function p.info()
		return { mapa = NIVEL.id, acto = op.acto, pesadilla = pesadilla, anfitrion = op.anfitrion }
	end

	function p.votar(j: Player, opcion: string): string?
		if not terminada then
			return "La partida sigue en juego"
		end
		if not table.find(string.split(estado:GetAttribute("Opciones") or "", ","), opcion) then
			return "Opción no disponible"
		end
		p.jugadores[j].voto = opcion
		j:SetAttribute("Voto", opcion)
		return nil
	end

	-- Publica el conteo; devuelve la opción si todos los que quedan votaron lo mismo.
	function p.decision(): string?
		if not terminada then
			return nil
		end
		local conteo, total = {}, 0
		for _, d in p.jugadores do
			total += 1
			if d.voto then
				conteo[d.voto] = (conteo[d.voto] or 0) + 1
			end
		end
		fijar("VotosTotal", total)
		for _, o in OPCIONES do
			fijar("Votos_" .. o, conteo[o])
			if total > 0 and conteo[o] == total then
				return o
			end
		end
		return nil
	end

	-- Reinicio rápido en el mismo mapa (repetir o siguiente acto): nadie sale de la arena.
	function p.reiniciar(acto, conPesadilla: boolean)
		for _, u in unidades do
			u.modelo:Destroy()
		end
		table.clear(unidades)
		for i = #enemigos, 1, -1 do
			quitarEnemigo(enemigos[i])
		end
		op.acto, pesadilla = acto, conPesadilla and not sinFin
		superadas, derrotados = 0, 0
		jefeVivo, danoJefe = nil, {}
		for _, a in { "JefeVida", "JefeVidaMax", "NombreJefe" } do
			fijar(a, nil)
		end
		fijar("Acto", nombreActo())
		fijar("Pesadilla", pesadilla)
		fijar("Base", BASE)
		fijar("Oleada", 0)
		for _, a in { "Resultado", "Opciones", "VotosTotal", "Votos_siguiente", "Votos_mapa", "Votos_repetir" } do
			fijar(a, nil)
		end
		for j in p.jugadores do
			j:SetAttribute("PremioActo", nil)
			j:SetAttribute("Voto", nil)
			agregar(j)
		end
		terminada = false
		task.spawn(bucle)
	end

	------------------------------------------------------------------------------
	-- Salida
	------------------------------------------------------------------------------
	-- Saca al jugador (y sus unidades); devuelve true si la partida quedó vacía.
	function p.salir(j: Player): boolean
		if not p.jugadores[j] then
			return next(p.jugadores) == nil
		end
		for i = #unidades, 1, -1 do
			if unidades[i].dueno == j then
				unidades[i].modelo:Destroy()
				table.remove(unidades, i)
			end
		end
		p.jugadores[j] = nil
		for _, a in { "Partida", "Dinero", "Escuadron", "Listo", "Auto", "PremioActo", "Voto" } do
			j:SetAttribute(a, nil)
		end
		task.spawn(Perfiles.guardar, j)
		return next(p.jugadores) == nil
	end

	function p.destruir()
		terminada = true
		Mapa.limpiar(NIVEL, origen)
		mundo:Destroy()
		estado:Destroy()
	end

	return p
end

return Partida
