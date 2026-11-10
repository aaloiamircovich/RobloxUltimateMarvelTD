-- Servidor: HUB, salas y partidas (una por sala, ver Partida.luau), perfiles y colección.
-- Diseño en docs/PARTIDA.md (actos, salas, oleadas) y docs/INVOCACIONES.md (unidades, banner, gemas).
-- shortcut: las salas juegan en arenas del mismo servidor; a futuro, servidores reservados por partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Data = Shared.Data
local Objetos = require(Shared.Objetos)
local Oleadas = require(Shared.Oleadas)
local Unidades = require(Shared.Unidades)
local Banner = require(Shared.Banner)
local Cuenta = require(Shared.Cuenta)
local Actos = require(Shared.Actos)
local Hub = require(script.Parent.Hub)
local Perfiles = require(script.Parent.Perfiles)
local Reclutamiento = require(script.Parent.Reclutamiento)
local Partida = require(script.Parent.Partida)

local niveles = require(Data.levels)
local enemigosDatos = require(Data.enemies)

local function remoto(clase: string, nombre: string)
	local r = Instance.new(clase)
	r.Name = nombre
	r.Parent = ReplicatedStorage
	return r
end
local accion = remoto("RemoteFunction", "Accion")
local aviso = remoto("RemoteEvent", "Aviso")
local abrirPanel = remoto("RemoteEvent", "AbrirPanel")
local usarHud = remoto("RemoteEvent", "UsarHud")
local teletransportar = remoto("RemoteEvent", "Teletransportar")
local salaRemota = remoto("RemoteFunction", "Sala")
local coleccion = remoto("RemoteFunction", "Coleccion")

--------------------------------------------------------------------------------
-- Partidas: cada una en su arena, lejos del HUB
--------------------------------------------------------------------------------
local partidas = {} -- [id] = partida
local partidaDe = {} -- [Player] = partida
local arenas = {} -- [índice] = id de la partida que la ocupa
local siguientePartida = 0

local function origenLibre(): (number, Vector3)
	local i = 1
	while arenas[i] do
		i += 1
	end
	-- Arenas en fila al este del HUB, separadas para que no se vean entre sí.
	return i, Vector3.new(450 + (i - 1) * 450, 0, -110) -- mapas de 300×225 studs con 40 de borde
end

local function indiceNivel(mapaId: string): number?
	for i, n in niveles do
		if n.id == mapaId then
			return i
		end
	end
	return nil
end

local function iniciarPartida(miembros: { Player }, anfitrion: Player, mapaId: string, acto, pesadilla: boolean): string?
	for _, j in miembros do
		local perfil = Perfiles.de(j)
		if not perfil then
			return `El perfil de {j.DisplayName} todavía no cargó`
		end
		if #perfil.squad == 0 then
			return `{j.DisplayName} tiene que elegir su héroe inicial`
		end
		if partidaDe[j] then
			return `{j.DisplayName} ya está en una partida`
		end
	end
	siguientePartida += 1
	local id = "P" .. siguientePartida
	local arena, origen = origenLibre()
	arenas[arena] = id
	local p = Partida.nueva({
		id = id,
		indice = indiceNivel(mapaId),
		acto = acto,
		pesadilla = pesadilla,
		jugadores = miembros,
		anfitrion = anfitrion,
		origen = origen,
		aviso = aviso,
	})
	p.arena = arena
	partidas[id] = p
	for _, j in miembros do
		partidaDe[j] = p
	end
	return nil
end

-- Saca al jugador de su partida y lo devuelve al HUB; la partida vacía se destruye.
local function salirDePartida(j: Player)
	local p = partidaDe[j]
	if not p then
		return
	end
	partidaDe[j] = nil
	if p.salir(j) then
		p.destruir()
		partidas[p.id] = nil
		arenas[p.arena] = nil
	end
	if j.Character and j.Parent then
		j.Character:PivotTo(Hub.llegada("central"))
	end
end

-- Frontera de confianza: tipos de cada acción antes de pasarla a la partida.
local FIRMAS = {
	colocar = { "number", "number", "number" },
	mover = { "number", "number", "number" },
	vender = { "number" },
	mejorar = { "number" },
	municion = { "number" },
	prioridad = { "number" },
	listo = {},
	saltar = {},
	auto = {},
	velocidad = {},
}
accion.OnServerInvoke = function(jugador, nombre, a, b, c)
	if nombre == "volver" then
		salirDePartida(jugador)
		return nil
	end
	local firma = type(nombre) == "string" and FIRMAS[nombre]
	if not firma then
		return "Acción desconocida"
	end
	local p = partidaDe[jugador]
	if not p then
		return "No estás en una partida"
	end
	local args = { a, b, c }
	for i, tipo in firma do
		local v = args[i]
		if type(v) ~= tipo or (tipo == "number" and (v ~= v or math.abs(v) == math.huge)) then
			return "Datos inválidos"
		end
	end
	return p.accion(jugador, nombre, a, b, c)
end

--------------------------------------------------------------------------------
-- Salas: se arman en el panel de Historia (hasta 4, «Sólo amigos», «Pesadilla»)
--------------------------------------------------------------------------------
local salas = {} -- [id] = { id, anfitrion, miembros, mapa, acto, pesadilla, soloAmigos }
local salaDe = {} -- [Player] = sala
local siguienteSala = 0

local function infoSala(s)
	if not s then
		return nil
	end
	local miembros = {}
	for _, j in s.miembros do
		table.insert(miembros, { nombre = j.DisplayName, anfitrion = j == s.anfitrion })
	end
	local n = niveles[indiceNivel(s.mapa)]
	return {
		id = s.id,
		anfitrion = s.anfitrion.DisplayName,
		miembros = miembros,
		mapa = s.mapa,
		nombreMapa = n and n.name,
		acto = s.acto,
		pesadilla = s.pesadilla,
		soloAmigos = s.soloAmigos,
	}
end

local function salirDeSala(j: Player)
	local s = salaDe[j]
	if not s then
		return
	end
	salaDe[j] = nil
	if s.anfitrion == j then
		-- Si se va el anfitrión, la sala se disuelve.
		for _, otro in s.miembros do
			salaDe[otro] = nil
			if otro ~= j then
				aviso:FireClient(otro, "El anfitrión cerró la sala")
			end
		end
		salas[s.id] = nil
	else
		table.remove(s.miembros, table.find(s.miembros, j))
	end
end

-- Datos del panel de Historia: mapas, actos con su jefe y premio, y el progreso del jugador.
local function datosHistoria(perfil)
	local mapas = {}
	for _, id in Actos.MAPAS do
		local n = niveles[indiceNivel(id)]
		local prog = Actos.progreso(perfil, id)
		local actos = {}
		for a = 1, Actos.POR_MAPA do
			local jefe = enemigosDatos.bosses[Oleadas.jefeDeActo(n, a)]
			table.insert(actos, {
				numero = a,
				jefe = jefe and jefe.name or "?",
				premio = Actos.GEMAS_PRIMERA * a,
				abierto = Actos.puedeJugar(perfil, id, a) == nil,
				ganado = prog.normal >= a,
				pesadilla = prog.pesadilla >= a,
			})
		end
		table.insert(mapas, {
			id = id,
			nombre = n.name,
			dificultad = n.difficulty,
			descripcion = n.description or "",
			abierto = Actos.mapaAbierto(perfil, id),
			ganados = prog.normal,
			actos = actos,
			infinito = prog.normal >= Actos.POR_MAPA,
		})
	end
	return mapas
end

local function validarActo(acto)
	return acto == "infinito" or (type(acto) == "number" and acto == math.floor(acto) and acto >= 1 and acto <= Actos.POR_MAPA)
end

salaRemota.OnServerInvoke = function(jugador, nombre, datos)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local res = {}
	if nombre == "crear" and type(datos) == "table" then
		local mapa, acto = datos.mapa, datos.acto
		if type(mapa) ~= "string" or not validarActo(acto) then
			res.error = "Datos inválidos"
		elseif partidaDe[jugador] then
			res.error = "Ya estás en una partida"
		else
			res.error = Actos.puedeJugar(perfil, mapa, acto, datos.pesadilla == true)
		end
		if not res.error then
			salirDeSala(jugador)
			if datos.solo == true then
				res.error = iniciarPartida({ jugador }, jugador, mapa, acto, datos.pesadilla == true)
				res.empezo = res.error == nil
			else
				siguienteSala += 1
				local s = { id = "S" .. siguienteSala, anfitrion = jugador, miembros = { jugador }, mapa = mapa, acto = acto, pesadilla = datos.pesadilla == true, soloAmigos = datos.soloAmigos == true }
				salas[s.id] = s
				salaDe[jugador] = s
			end
		end
	elseif nombre == "unirse" and type(datos) == "string" then
		local s = salas[datos]
		if not s then
			res.error = "Esa sala ya no existe"
		elseif #s.miembros >= Partida.MAX_JUGADORES then
			res.error = "La sala está llena"
		elseif s.soloAmigos and not (function()
			local ok, amigo = pcall(s.anfitrion.IsFriendsWith, s.anfitrion, jugador.UserId)
			return ok and amigo
		end)() then
			res.error = "Sala sólo para amigos del anfitrión"
		else
			salirDeSala(jugador)
			table.insert(s.miembros, jugador)
			salaDe[jugador] = s
		end
	elseif nombre == "salir" then
		salirDeSala(jugador)
	elseif nombre == "iniciar" then
		local s = salaDe[jugador]
		if not s or s.anfitrion ~= jugador then
			res.error = "Sólo el anfitrión inicia la partida"
		else
			res.error = iniciarPartida(table.clone(s.miembros), jugador, s.mapa, s.acto, s.pesadilla)
			if not res.error then
				for _, j in s.miembros do
					salaDe[j] = nil
				end
				salas[s.id] = nil
				res.empezo = true
			end
		end
	elseif nombre ~= "estado" then
		res.error = "Acción desconocida"
	end
	local abiertas = {}
	for _, s in salas do
		if s ~= salaDe[jugador] and #s.miembros < Partida.MAX_JUGADORES then
			table.insert(abiertas, infoSala(s))
		end
	end
	res.historia = datosHistoria(perfil)
	res.sala = infoSala(salaDe[jugador])
	res.abiertas = abiertas
	return res
end

--------------------------------------------------------------------------------
-- HUB
--------------------------------------------------------------------------------
local function usarEstacion(jugador: Player, estacion: string)
	if partidaDe[jugador] then
		return
	end
	if estacion == "story" or estacion == "sala_story" then
		abrirPanel:FireClient(jugador, "historia", { infinito = false })
	elseif estacion == "infinite" or estacion == "sala_infinite" then
		abrirPanel:FireClient(jugador, "historia", { infinito = true })
	elseif estacion == "summon" then
		abrirPanel:FireClient(jugador, "invocaciones", { pestana = "banner" })
	elseif estacion == "tienda" then
		abrirPanel:FireClient(jugador, "invocaciones", { pestana = "tienda" })
	else
		-- Traits, grades, pets, bailes, monturas, raids, banners 2 y 3, etc. esperan sus reglas.
		aviso:FireClient(jugador, "Próximamente")
	end
end
local hub = Hub.construir(usarEstacion)

-- Botones del HUD del lobby: abren los mismos paneles que las estaciones, sin caminar hasta ellas.
local PANELES_HUD = { story = true, infinite = true, summon = true, tienda = true, unidades = "unidades", inventario = "objetos" }
usarHud.OnServerEvent:Connect(function(jugador, nombre)
	local destino = type(nombre) == "string" and PANELES_HUD[nombre]
	if not destino or partidaDe[jugador] then
		return
	end
	if type(destino) == "string" then
		abrirPanel:FireClient(jugador, "invocaciones", { pestana = destino })
	else
		usarEstacion(jugador, nombre)
	end
end)

teletransportar.OnServerEvent:Connect(function(jugador, isla)
	local destino = type(isla) == "string" and not partidaDe[jugador] and Hub.llegada(isla)
	if destino and jugador.Character then
		jugador.Character:PivotTo(destino)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	Hub.animar(hub, dt)
	for _, p in partidas do
		p.paso(dt)
	end
end)

--------------------------------------------------------------------------------
-- Perfiles: carga al entrar, guardado al salir, al cerrar y cada minuto
--------------------------------------------------------------------------------
local function publicarSaldo(jugador: Player, perfil)
	jugador:SetAttribute("Nivel", perfil.level)
	jugador:SetAttribute("XP", perfil.xp)
	jugador:SetAttribute("Creditos", perfil.credits)
	jugador:SetAttribute("Gemas", perfil.gems)
	jugador:SetAttribute("Nucleos", perfil.cores)
end

local function alEntrar(jugador: Player)
	local perfil, problema = Perfiles.cargar(jugador)
	publicarSaldo(jugador, perfil)
	if problema then
		aviso:FireClient(jugador, problema)
	end
end
Players.PlayerAdded:Connect(alEntrar)
for _, j in Players:GetPlayers() do
	task.spawn(alEntrar, j)
end
Players.PlayerRemoving:Connect(function(jugador)
	salirDeSala(jugador)
	salirDePartida(jugador)
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
		nivel = perfil.level,
		xp = perfil.xp,
		casillas = Cuenta.casillas(perfil.level),
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

coleccion.OnServerInvoke = function(jugador, nombre, arg)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	-- El escuadrón de una partida en curso se fijó al empezar: no tocar el perfil a la vez.
	if nombre ~= "estado" and partidaDe[jugador] then
		return { error = "Terminá o abandoná la partida primero" }
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
		publicarSaldo(jugador, perfil)
	end
	res.estado = resumen(perfil)
	return res
end
