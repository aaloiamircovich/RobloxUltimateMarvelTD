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
local Temporada = require(Shared.Temporada)
local Evento = require(Shared.Evento)
local Raid = require(Shared.Raid)
local Rasgos = require(Shared.Rasgos)
local Mascotas = require(Shared.Mascotas)
local Estilo = require(Shared.Estilo)
local Preferencias = require(Shared.Preferencias)
local Recompensas = require(Shared.Recompensas)
local Intercambio = require(Shared.Intercambio)
local Analitica = require(script.Parent.Analitica)
local Banners = require(Shared.Banners)
local Hub = require(script.Parent.Hub)
local Perfiles = require(script.Parent.Perfiles)
local Reclutamiento = require(script.Parent.Reclutamiento)
local Partida = require(script.Parent.Partida)
local Ranking = require(script.Parent.Ranking)

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
local temporada = remoto("RemoteFunction", "Temporada")
local eventoRemoto = remoto("RemoteFunction", "Evento")
local raidRemoto = remoto("RemoteFunction", "Raid")
local rasgosRemoto = remoto("RemoteFunction", "Rasgos")
local mascotasRemoto = remoto("RemoteFunction", "Mascotas")
local estiloRemoto = remoto("RemoteFunction", "Estilo")
local bannersRemoto = remoto("RemoteFunction", "Banners")
local preferenciasRemoto = remoto("RemoteFunction", "Preferencias")
local recompensasRemoto = remoto("RemoteFunction", "Recompensas")
local intercambioRemoto = remoto("RemoteFunction", "Intercambio")
local intercambioAviso = remoto("RemoteEvent", "IntercambioAviso") -- el servidor avisa pedidos y cambios de la sesión

--------------------------------------------------------------------------------
-- Partidas: cada una en su arena, lejos del HUB
--------------------------------------------------------------------------------
-- Copia de los modelos de héroes para los retratos 3D de la interfaz.
do
	local heroes = game:GetService("ServerStorage"):FindFirstChild("Plantillas")
	heroes = heroes and heroes:FindFirstChild("Heroes")
	if heroes then
		-- Restos de auto_setup_avatar que no usa ni la partida ni el retrato (~315 de ~490 piezas por modelo,
		-- y los 212 se copian a cada cliente): poses del armado, AnimateScript con sus 27 animaciones, etc.
		for _, d in heroes:GetDescendants() do
			if
				(d:IsA("Folder") and d.Name == "InitialPoses")
				or (d:IsA("LocalScript") and d.Name == "AnimateScript")
				or d:IsA("FaceControls")
			then
				d:Destroy()
			end
		end
		local retratos = heroes:Clone()
		-- En el retrato no hay física: las restricciones de choque entre piezas sobran.
		for _, d in retratos:GetDescendants() do
			if d:IsA("NoCollisionConstraint") then
				d:Destroy()
			end
		end
		retratos.Name = "Retratos"
		retratos.Parent = ReplicatedStorage
	end
	-- Modelos de mascotas: los clientes los clonan para dibujar las que siguen a cada jugador.
	local mascotas = game:GetService("ServerStorage"):FindFirstChild("Plantillas")
	mascotas = mascotas and mascotas:FindFirstChild("Mascotas")
	if mascotas then
		local copia = mascotas:Clone()
		copia.Name = "ModelosMascotas"
		copia.Parent = ReplicatedStorage
	end
end

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
	return i, Vector3.new(352 + (i - 1) * 352, 0, -112) -- mapas de 200×150 studs con 28 de borde; múltiplos de 4 para la grilla del terreno
end

local function indiceNivel(mapaId: string): number?
	for i, n in niveles do
		if n.id == mapaId then
			return i
		end
	end
	return nil
end

local function problemaParaEmpezar(miembros: { Player }): string?
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
	return nil
end

-- Crea la partida en este mismo servidor (en Studio, o dentro de un servidor de partida).
local function iniciarPartidaAqui(miembros: { Player }, anfitrion: Player, mapaId: string, acto, pesadilla: boolean): string?
	local problema = problemaParaEmpezar(miembros)
	if problema then
		return problema
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

--------------------------------------------------------------------------------
-- Servidores de partida (docs/SERVIDORES.md): el lobby manda al grupo a un servidor reservado de este mismo
-- lugar; ese servidor juega la partida y al volver los manda al lobby. En Studio no hay teletransporte:
-- todo se juega en un solo servidor como antes.
--------------------------------------------------------------------------------
local TeleportService = game:GetService("TeleportService")
local SERVIDOR_PARTIDA = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 -- servidor reservado
local USAR_SERVIDORES = not RunService:IsStudio()

local function enviarAPartida(miembros: { Player }, anfitrion: Player, mapaId: string, acto, pesadilla: boolean): string?
	local problema = problemaParaEmpezar(miembros)
	if problema then
		return problema
	end
	local ok, codigo = pcall(TeleportService.ReserveServer, TeleportService, game.PlaceId)
	if not ok then
		warn(`[UMTD] ReserveServer: {codigo}`)
		return "No se pudo crear el servidor de la partida. Probá de nuevo"
	end
	local ids = {}
	for _, j in miembros do
		table.insert(ids, j.UserId)
		aviso:FireClient(j, "Viajando a la partida…")
	end
	local opciones = Instance.new("TeleportOptions")
	opciones.ReservedServerAccessCode = codigo
	opciones:SetTeleportData({ tipo = "partida", mapa = mapaId, acto = acto, pesadilla = pesadilla, anfitrion = anfitrion.UserId, jugadores = ids })
	local okViaje, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, miembros, opciones)
	if not okViaje then
		warn(`[UMTD] TeleportAsync: {err}`)
		return "No se pudo viajar a la partida. Probá de nuevo"
	end
	return nil
end

-- Punto de entrada único: en el lobby publicado viaja a un servidor reservado; si no, juega aquí.
local function iniciarPartida(miembros: { Player }, anfitrion: Player, mapaId: string, acto, pesadilla: boolean): string?
	if USAR_SERVIDORES and not SERVIDOR_PARTIDA then
		return enviarAPartida(miembros, anfitrion, mapaId, acto, pesadilla)
	end
	return iniciarPartidaAqui(miembros, anfitrion, mapaId, acto, pesadilla)
end

-- Si el viaje falla después de empezar (red, servidor lleno), el jugador sigue acá: avisarle.
TeleportService.TeleportInitFailed:Connect(function(j, _resultado, mensaje)
	aviso:FireClient(j, `No se pudo viajar: {mensaje}. Probá de nuevo`)
end)

-- Vuelve al lobby público (desde un servidor de partida).
local function volverAlLobby(jugadores: { Player }, mensaje: string?)
	for _, j in jugadores do
		if mensaje then
			aviso:FireClient(j, mensaje)
		end
	end
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, jugadores)
	if not ok then
		warn(`[UMTD] Vuelta al lobby: {err}`)
		for _, j in jugadores do
			j:Kick("No se pudo volver al lobby. Volvé a entrar al juego.")
		end
	end
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

-- Ejecuta lo que votaron todos en la pantalla final (repetir, siguiente acto o siguiente mapa).
local function resolverVotos(p)
	local opcion = p.decision()
	if not opcion then
		return
	end
	local info = p.info()
	local miembros = {}
	for j in p.jugadores do
		table.insert(miembros, j)
	end
	local mapa, acto, pesadilla = info.mapa, info.acto, info.pesadilla
	if opcion == "siguiente" then
		acto += 1
	elseif opcion == "mapa" then
		mapa, acto, pesadilla = Actos.MAPAS[table.find(Actos.MAPAS, mapa) + 1], 1, false
	end
	-- Validar para todos; la Pesadilla pasa a normal si alguno no la tiene abierta.
	for _, conPesadilla in { pesadilla, false } do
		local problema
		for _, j in miembros do
			local perfil = Perfiles.de(j)
			problema = problema or (if not perfil then "Perfil no cargado" elseif acto == "evento" then nil elseif acto == "raid" then Raid.puedeEntrar(perfil, os.time()) else Actos.puedeJugar(perfil, mapa, acto, conPesadilla))
		end
		if not problema then
			if pesadilla and not conPesadilla then
				for _, j in miembros do
					aviso:FireClient(j, "Alguien no tiene abierta la Pesadilla de este acto: se juega en normal")
				end
			end
			if mapa == info.mapa then
				p.reiniciar(acto, conPesadilla)
			else
				-- Otro mapa: partida nueva en otra arena.
				for _, j in miembros do
					partidaDe[j] = nil
					p.salir(j)
				end
				p.destruir()
				partidas[p.id] = nil
				arenas[p.arena] = nil
				local anfitrion = if table.find(miembros, info.anfitrion) then info.anfitrion else miembros[1]
				local fallo = iniciarPartidaAqui(miembros, anfitrion, mapa, acto, false) -- siguiente mapa: en este mismo servidor
				if fallo then
					for _, j in miembros do
						aviso:FireClient(j, fallo)
						if j.Character then
							j.Character:PivotTo(Hub.llegada("central"))
						end
					end
				end
			end
			return
		end
		if not pesadilla then
			for _, j in miembros do
				aviso:FireClient(j, problema)
			end
			return
		end
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
		local p = partidaDe[jugador]
		salirDePartida(jugador)
		if p and partidas[p.id] then
			resolverVotos(p) -- los que quedan pueden haber quedado de acuerdo
		end
		if SERVIDOR_PARTIDA then
			task.spawn(volverAlLobby, { jugador })
		end
		return nil
	end
	if nombre == "votar" then
		local p = partidaDe[jugador]
		if not p or type(a) ~= "string" then
			return "Datos inválidos"
		end
		local problema = p.votar(jugador, a)
		if not problema then
			resolverVotos(p)
		end
		return problema
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
	return acto == "infinito" or acto == "raid" or (type(acto) == "number" and acto == math.floor(acto) and acto >= 1 and acto <= Actos.POR_MAPA)
end

salaRemota.OnServerInvoke = function(jugador, nombre, datos)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local res = {}
	if nombre == "crear" and type(datos) == "table" then
		local mapa, acto = datos.mapa, datos.acto
		if acto == "raid" then
			-- La raid se juega en el mapa del jefe de la semana y pide una llave.
			mapa = Raid.jefe(Raid.semana(os.time())).mapa
			datos.pesadilla = false
		end
		if type(mapa) ~= "string" or not validarActo(acto) then
			res.error = "Datos inválidos"
		elseif partidaDe[jugador] then
			res.error = "Ya estás en una partida"
		elseif acto == "raid" then
			res.error = Raid.puedeEntrar(perfil, os.time())
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
		local sinLlave
		for _, j in (s and s.acto == "raid" and s.miembros or {}) do
			local pj = Perfiles.de(j)
			if not pj or Raid.puedeEntrar(pj, os.time()) then
				sinLlave = j
			end
		end
		if not s or s.anfitrion ~= jugador then
			res.error = "Sólo el anfitrión inicia la partida"
		elseif sinLlave then
			res.error = `{sinLlave.DisplayName} no tiene llaves de raid hoy`
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
	elseif estacion == "banner_2" then
		abrirPanel:FireClient(jugador, "banners", {})
	elseif estacion == "monturas" or estacion == "bailes" then
		abrirPanel:FireClient(jugador, "estilo", { pestana = estacion })
	elseif estacion == "pets" then
		abrirPanel:FireClient(jugador, "mascotas", {})
	elseif estacion == "traits" or estacion == "grades" then
		abrirPanel:FireClient(jugador, "rasgos", { pestana = estacion })
	elseif estacion == "raids" or estacion == "misiones_raid" then
		abrirPanel:FireClient(jugador, "raid", { pestana = if estacion == "raids" then "raid" else "misiones" })
	elseif estacion == "evento" or estacion == "ranking" or estacion == "misiones" then
		abrirPanel:FireClient(jugador, estacion, {}) -- los abre el HUD del lobby
	else
		-- Traits, grades, pets, bailes, monturas, raids, banners 2 y 3, etc. esperan sus reglas.
		aviso:FireClient(jugador, "Próximamente")
	end
end
local hub = Hub.construir(usarEstacion)

-- Botones del HUD del lobby: abren los mismos paneles que las estaciones, sin caminar hasta ellas.
local PANELES_HUD = { story = true, infinite = true, summon = true, tienda = true, raids = true, unidades = "unidades", inventario = "objetos" }
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
-- motivo: para la analítica de economía (de dónde salió o en qué se gastó). Sin motivo = saldo de referencia.
local function publicarSaldo(jugador: Player, perfil, motivo: string?)
	jugador:SetAttribute("Nivel", perfil.level)
	jugador:SetAttribute("XP", perfil.xp)
	jugador:SetAttribute("Creditos", perfil.credits)
	jugador:SetAttribute("Gemas", perfil.gems)
	jugador:SetAttribute("Nucleos", perfil.cores)
	Analitica.saldo(jugador, perfil, motivo)
end

-- Servidor de partida: junta a los que llegan con el viaje y arranca cuando están todos (o a los 20 s).
local llegada = { config = nil, presentes = {}, empezo = false }

-- Datos del viaje (los manda nuestro lobby; igual se validan: frontera de confianza).
local function datosDeViaje(j: Player)
	local ok, datos = pcall(j.GetJoinData, j)
	local t = ok and type(datos) == "table" and datos.TeleportData
	if type(t) ~= "table" or t.tipo ~= "partida" or type(t.mapa) ~= "string" or not indiceNivel(t.mapa) then
		return nil
	end
	if not (validarActo(t.acto) or t.acto == "evento") or type(t.jugadores) ~= "table" or not table.find(t.jugadores, j.UserId) then
		return nil
	end
	return t
end

local function arrancarLlegados()
	if llegada.empezo then
		return
	end
	llegada.empezo = true
	local c = llegada.config
	local miembros = {}
	for _, j in llegada.presentes do
		if j.Parent then
			table.insert(miembros, j)
		end
	end
	if #miembros == 0 then
		return
	end
	-- Se vuelve a validar con los perfiles ya cargados en este servidor.
	for _, j in miembros do
		local perfil = Perfiles.de(j)
		local problema = if not perfil then "Tu perfil no cargó" elseif c.acto == "evento" then nil elseif c.acto == "raid" then Raid.puedeEntrar(perfil, os.time()) else Actos.puedeJugar(perfil, c.mapa, c.acto, c.pesadilla == true)
		if problema then
			volverAlLobby(miembros, problema)
			return
		end
	end
	local anfitrion = miembros[1]
	for _, j in miembros do
		if j.UserId == c.anfitrion then
			anfitrion = j
		end
	end
	local fallo = iniciarPartidaAqui(miembros, anfitrion, c.mapa, c.acto, c.pesadilla == true)
	if fallo then
		volverAlLobby(miembros, fallo)
	end
end

local function llegarAPartida(j: Player)
	local t = datosDeViaje(j)
	if llegada.empezo or not t or (llegada.config and t.mapa ~= llegada.config.mapa) then
		volverAlLobby({ j }, "Esa partida ya empezó o no existe")
		return
	end
	if not llegada.config then
		llegada.config = t
		task.delay(20, arrancarLlegados)
	end
	table.insert(llegada.presentes, j)
	aviso:FireClient(j, "Preparando la partida…")
	if #llegada.presentes >= #llegada.config.jugadores then
		arrancarLlegados()
	end
end

local function alEntrar(jugador: Player)
	local perfil, problema = Perfiles.cargar(jugador)
	publicarSaldo(jugador, perfil)
	jugador:SetAttribute("Mascotas", Mascotas.texto(perfil))
	jugador:SetAttribute("Rueda", table.concat(perfil.estilo.rueda, ","))
	jugador:SetAttribute("DiarioDisponible", not Recompensas.estadoDiario(perfil, os.time()).reclamado)
	-- Récords que ya tenía: entran al ranking aunque no juegue en esta sesión.
	if perfil.modeRecords.survival.bestWave > 0 then
		Ranking.anotar("infinito", jugador.UserId, perfil.modeRecords.survival.bestWave)
	end
	if perfil.evento.semana == Evento.semana(os.time()) and perfil.evento.mejor > 0 then
		Ranking.anotar("evento", jugador.UserId, perfil.evento.mejor)
	end
	if problema then
		aviso:FireClient(jugador, problema)
	end
	if SERVIDOR_PARTIDA and jugador.Parent then
		llegarAPartida(jugador)
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
	Analitica.soltar(jugador)
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
-- Banner 2 (destacado cada 3 horas, con fichas de raid): docs/INVOCACIONES.md. El 3 está «Próximamente».
--------------------------------------------------------------------------------
bannersRemoto.OnServerInvoke = function(jugador, nombre, cantidad)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local ahora = os.time()
	local err, nuevas
	if nombre == "limitado" then
		if partidaDe[jugador] then
			err = "Terminá o abandoná la partida primero"
		elseif type(cantidad) ~= "number" then
			err = "Cantidad inválida"
		else
			nuevas, err = Banners.limitado(perfil, cantidad, ahora, math.random)
		end
		if not err then
			Temporada.registrar(perfil, "invocar", cantidad, ahora)
			Perfiles.marcar(jugador)
			publicarSaldo(jugador, perfil, "banner2")
		end
	elseif nombre ~= "estado" then
		err = "Acción desconocida"
	end
	local res = Banners.resumen(perfil, ahora)
	res.error, res.nuevas = err, nuevas
	return res
end

--------------------------------------------------------------------------------
-- Monturas y bailes (docs/ESTILO.md). Montar: el servidor suelda el modelo bajo los pies y sube la velocidad.
-- Los bailes los reproduce el cliente sobre su personaje (Roblox replica la animación a los demás).
--------------------------------------------------------------------------------
local PLANTILLAS_MONTURA = game:GetService("ServerStorage"):FindFirstChild("Plantillas")
PLANTILLAS_MONTURA = PLANTILLAS_MONTURA and PLANTILLAS_MONTURA:FindFirstChild("Monturas")

local function bajar(jugador: Player)
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local m = personaje and personaje:FindFirstChild("Montura")
	if m then
		if humanoide then
			humanoide.HipHeight -= m:GetAttribute("Alto") or 0
			humanoide.WalkSpeed = Estilo.VELOCIDAD_BASE
		end
		m:Destroy()
	end
	jugador:SetAttribute("Montado", nil)
end

local function subir(jugador: Player, perfil)
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart") :: BasePart
	local datos = Estilo.montura(perfil.estilo.montura)
	local plantilla = PLANTILLAS_MONTURA and datos and PLANTILLAS_MONTURA:FindFirstChild(datos.id)
	if not (humanoide and raiz and plantilla) or humanoide.Health <= 0 then
		return "No se puede montar ahora"
	end
	local m = plantilla:Clone()
	m.Name = "Montura"
	local alto = m:GetAttribute("Alto") or 1
	-- Al subir la cadera `alto`, el personaje (y la montura soldada) sube: la montura va `alto` más abajo
	-- de los pies para quedar en el piso, con el jinete parado arriba.
	local pies = raiz.CFrame * CFrame.new(0, -(raiz.Size.Y / 2 + humanoide.HipHeight + alto), 0)
	m:PivotTo(pies * CFrame.Angles(0, math.rad(m:GetAttribute("Giro") or 0), 0))
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.Massless = false, false, true
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = raiz, p
			w.Parent = p
		end
	end
	m.Parent = personaje
	humanoide.HipHeight += alto
	humanoide.WalkSpeed = Estilo.VELOCIDAD_BASE * datos.velocidad
	jugador:SetAttribute("Montado", datos.id)
	return nil
end

estiloRemoto.OnServerInvoke = function(jugador, nombre, a)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local err
	if nombre == "montura" and type(a) == "string" then
		err = Estilo.elegirMontura(perfil, a)
		if not err and jugador:GetAttribute("Montado") then
			bajar(jugador)
			subir(jugador, perfil) -- cambia a la nueva sin bajarse
		end
	elseif nombre == "baile" and type(a) == "string" then
		err = Estilo.elegirBaile(perfil, a)
	elseif nombre == "montar" then
		if jugador:GetAttribute("Montado") then
			bajar(jugador)
		else
			err = subir(jugador, perfil)
		end
		return { error = err }
	elseif nombre ~= "estado" then
		err = "Acción desconocida"
	end
	if nombre ~= "estado" and not err then
		Perfiles.marcar(jugador)
		publicarSaldo(jugador, perfil, "estilo")
		jugador:SetAttribute("Rueda", table.concat(perfil.estilo.rueda, ","))
	end
	return { error = err, estilo = perfil.estilo, gemas = perfil.gems, monturas = Estilo.MONTURAS, bailes = Estilo.BAILES, rueda = Estilo.RUEDA }
end

--------------------------------------------------------------------------------
-- Premio diario, códigos y logros (docs/RECOMPENSAS.md)
--------------------------------------------------------------------------------
local ultimoCanje = {} -- [Player] = os.clock() del último intento de código (frena el probar códigos al azar)
recompensasRemoto.OnServerInvoke = function(jugador, nombre, a)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local ahora = os.time()
	local res = {}
	local premio, err
	if nombre == "diario" then
		premio, err = Recompensas.reclamarDiario(perfil, ahora)
	elseif nombre == "codigo" then
		if os.clock() - (ultimoCanje[jugador] or 0) < 2 then
			err = "Esperá un momento antes de probar otro código"
		else
			ultimoCanje[jugador] = os.clock()
			premio, err = Recompensas.canjear(perfil, a, ahora)
		end
	elseif nombre == "logro" then
		premio, err = Recompensas.reclamarLogro(perfil, a)
	elseif nombre ~= "estado" then
		err = "Acción desconocida"
	end
	if premio then
		Perfiles.marcar(jugador)
		publicarSaldo(jugador, perfil, "recompensas")
		res.premio = Recompensas.texto(premio)
	end
	res.error = err
	res.diario = Recompensas.estadoDiario(perfil, ahora)
	res.premiosDiarios = Recompensas.DIARIO
	res.logros = Recompensas.estadoLogros(perfil)
	jugador:SetAttribute("DiarioDisponible", not res.diario.reclamado)
	return res
end
Players.PlayerRemoving:Connect(function(j)
	ultimoCanje[j] = nil
end)

--------------------------------------------------------------------------------
-- Intercambio (docs/INTERCAMBIO.md): pedido → aceptar → ofertas → los dos confirman → se aplica en el servidor.
-- Cualquier cambio de oferta saca la confirmación de los dos (así nadie confirma algo que cambió a último momento).
--------------------------------------------------------------------------------
local pedidosIntercambio = {} -- [destino] = quien pide
local sesionesIntercambio = {} -- [Player] = sesión { a, b, oferta = { [Player] = oferta }, listo = { [Player] = bool } }
local itemsDatos = require(Shared.Data.items)

local function detalleOferta(perfil, oferta)
	local unidades, objetos = {}, {}
	for _, uid in oferta.unidades do
		local u = Unidades.buscar(perfil, uid)
		if u then
			table.insert(unidades, { uid = uid, heroId = u.heroId, nivel = u.level, rasgo = u.rasgo })
		end
	end
	for _, id in oferta.objetos do
		table.insert(objetos, { id = id, nombre = itemsDatos[id] and itemsDatos[id].name or id })
	end
	return { unidades = unidades, objetos = objetos }
end

local function avisarSesion(s, extra: string?)
	for _, j in { s.a, s.b } do
		local otro = if j == s.a then s.b else s.a
		local pj, po = Perfiles.de(j), Perfiles.de(otro)
		if pj and po then
			intercambioAviso:FireClient(j, "sesion", {
				conQuien = otro.DisplayName,
				mia = detalleOferta(pj, s.oferta[j]),
				suya = detalleOferta(po, s.oferta[otro]),
				listoYo = s.listo[j],
				listoOtro = s.listo[otro],
				mensaje = extra,
			})
		end
	end
end

local function cerrarIntercambio(j: Player, motivo: string?)
	pedidosIntercambio[j] = nil
	for destino, origen in pedidosIntercambio do
		if origen == j then
			pedidosIntercambio[destino] = nil
		end
	end
	local s = sesionesIntercambio[j]
	if not s then
		return
	end
	for _, x in { s.a, s.b } do
		sesionesIntercambio[x] = nil
		if x.Parent then
			intercambioAviso:FireClient(x, "fin", { mensaje = motivo })
		end
	end
end

intercambioRemoto.OnServerInvoke = function(jugador, nombre, a)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	if nombre == "estado" then
		local unidades, objetos = Intercambio.ofrecibles(perfil)
		local lista = {}
		for _, u in unidades do
			table.insert(lista, { uid = u.uid, heroId = u.heroId, nivel = u.level, rasgo = u.rasgo })
		end
		local objs = {}
		for _, id in objetos do
			table.insert(objs, { id = id, nombre = itemsDatos[id] and itemsDatos[id].name or id })
		end
		local jugadores = {}
		for _, otro in Players:GetPlayers() do
			if otro ~= jugador then
				local po = Perfiles.de(otro)
				table.insert(jugadores, { id = otro.UserId, nombre = otro.DisplayName, puede = po ~= nil and Intercambio.puede(po) == nil and not partidaDe[otro] })
			end
		end
		local pide = pedidosIntercambio[jugador]
		return {
			problema = Intercambio.puede(perfil),
			unidades = lista,
			objetos = objs,
			jugadores = jugadores,
			pedidoDe = pide and pide.Parent and pide.DisplayName or nil,
			enSesion = sesionesIntercambio[jugador] ~= nil,
			nivelMinimo = Intercambio.NIVEL_MINIMO,
		}
	end
	local problema = Intercambio.puede(perfil) or (if partidaDe[jugador] then "No podés intercambiar en una partida" else nil)
	if problema then
		return { error = problema }
	end
	if nombre == "pedir" then
		local otro = type(a) == "number" and Players:GetPlayerByUserId(a)
		local po = otro and Perfiles.de(otro)
		if not otro or otro == jugador or not po then
			return { error = "Ese jugador no está" }
		elseif Intercambio.puede(po) or partidaDe[otro] then
			return { error = `{otro.DisplayName} no puede intercambiar ahora` }
		elseif sesionesIntercambio[jugador] or sesionesIntercambio[otro] then
			return { error = "Alguno de los dos ya está intercambiando" }
		end
		pedidosIntercambio[otro] = jugador
		intercambioAviso:FireClient(otro, "pedido", { de = jugador.DisplayName })
		return { mensaje = `Pedido enviado a {otro.DisplayName}` }
	elseif nombre == "responder" then
		local origen = pedidosIntercambio[jugador]
		pedidosIntercambio[jugador] = nil
		if not origen or not origen.Parent or not Perfiles.de(origen) then
			return { error = "El pedido ya no está" }
		end
		if a ~= true then
			intercambioAviso:FireClient(origen, "fin", { mensaje = `{jugador.DisplayName} rechazó el intercambio` })
			return {}
		end
		if sesionesIntercambio[jugador] or sesionesIntercambio[origen] or partidaDe[origen] then
			return { error = "Ya no se puede empezar ese intercambio" }
		end
		local s = { a = origen, b = jugador, oferta = { [origen] = Intercambio.ofertaVacia(), [jugador] = Intercambio.ofertaVacia() }, listo = { [origen] = false, [jugador] = false } }
		sesionesIntercambio[origen], sesionesIntercambio[jugador] = s, s
		avisarSesion(s)
		return {}
	end
	local s = sesionesIntercambio[jugador]
	if not s then
		return { error = "No estás intercambiando" }
	end
	local otro = if jugador == s.a then s.b else s.a
	if nombre == "oferta" then
		local limpia, err = Intercambio.validarOferta(perfil, a)
		if not limpia then
			return { error = err }
		end
		s.oferta[jugador] = limpia
		s.listo[s.a], s.listo[s.b] = false, false
		avisarSesion(s)
		return {}
	elseif nombre == "confirmar" then
		s.listo[jugador] = true
		if not (s.listo[s.a] and s.listo[s.b]) then
			avisarSesion(s)
			return {}
		end
		local pa, pb = Perfiles.de(s.a), Perfiles.de(s.b)
		local err
		if pa and pb then
			err = Intercambio.aplicar(pa, s.oferta[s.a], pb, s.oferta[s.b])
		else
			err = "Un perfil no está cargado"
		end
		if err then
			s.listo[s.a], s.listo[s.b] = false, false
			avisarSesion(s, err)
			return { error = err }
		end
		for _, x in { s.a, s.b } do
			Perfiles.marcar(x)
			Perfiles.guardar(x)
		end
		cerrarIntercambio(jugador, "¡Intercambio hecho!")
		return {}
	elseif nombre == "cancelar" then
		cerrarIntercambio(jugador, `{jugador.DisplayName} canceló el intercambio`)
		return {}
	end
	return { error = "Acción desconocida" }
end
Players.PlayerRemoving:Connect(function(j)
	cerrarIntercambio(j, `{j.DisplayName} se fue del servidor`)
end)

--------------------------------------------------------------------------------
-- Ajustes y tutorial (docs/TUTORIAL.md)
--------------------------------------------------------------------------------
preferenciasRemoto.OnServerInvoke = function(jugador, nombre, a)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local res = {}
	-- Prueba en Studio: workspace.TutorialPrueba = true muestra el tutorial desde cero sin tocar el perfil ni dar premio.
	if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("TutorialPrueba") then
		return { ajustes = perfil.ajustes, tutorial = Preferencias.normalizarTutorial(nil), tieneUnidades = #perfil.units > 0, premio = 0, ganoActo = workspace:GetAttribute("TutorialPruebaGano") == true }
	end
	if nombre == "ajustes" and type(a) == "table" then
		perfil.ajustes = Preferencias.normalizarAjustes(a)
		Perfiles.marcar(jugador)
	elseif nombre == "paso" and type(a) == "number" and a == a then
		local t = perfil.tutorial
		if not t.terminado then
			local nuevo = math.clamp(math.floor(a), 0, Preferencias.PASOS)
			if nuevo > t.paso or (nuevo == 0 and t.paso == 0) then
				Analitica.pasoTutorial(jugador, nuevo) -- sólo cuando avanza (el embudo no cuenta repeticiones)
			end
			t.paso = nuevo
			Perfiles.marcar(jugador)
		end
	elseif nombre == "terminar" or nombre == "saltar" then
		if nombre == "saltar" then
			perfil.tutorial.terminado = true
			Analitica.evento(jugador, "Tutorial salteado", `paso {perfil.tutorial.paso}`)
		else
			res.premio = Preferencias.terminar(perfil)
			publicarSaldo(jugador, perfil, "tutorial")
			Analitica.pasoTutorial(jugador, Preferencias.PASOS)
		end
		Perfiles.marcar(jugador)
	elseif nombre ~= "estado" then
		res.error = "Acción desconocida"
	end
	res.ajustes = perfil.ajustes
	res.tutorial = perfil.tutorial
	res.tieneUnidades = #perfil.units > 0
	local prog = perfil.acts[Preferencias.MAPA_TUTORIAL]
	res.ganoActo = prog ~= nil and (prog.normal or 0) >= 1
	return res
end

-- Al reaparecer, el personaje nuevo viene sin montura.
Players.PlayerAdded:Connect(function(j)
	j.CharacterAdded:Connect(function()
		j:SetAttribute("Montado", nil)
	end)
end)
for _, j in Players:GetPlayers() do
	j.CharacterAdded:Connect(function()
		j:SetAttribute("Montado", nil)
	end)
end

--------------------------------------------------------------------------------
-- Mascotas (docs/MASCOTAS.md): huevos, equipar y fusionar sobre el propio perfil
--------------------------------------------------------------------------------
mascotasRemoto.OnServerInvoke = function(jugador, nombre, a)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local err, nueva
	if nombre ~= "estado" then
		if partidaDe[jugador] then
			err = "Terminá o abandoná la partida primero" -- los bonos se fijan al empezar
		elseif nombre == "abrir" and type(a) == "string" then
			nueva, err = Mascotas.abrir(perfil, a, math.random)
		elseif nombre == "equipar" and type(a) == "number" then
			err = Mascotas.equipar(perfil, a)
		elseif nombre == "fusionar" and type(a) == "number" then
			nueva, err = Mascotas.fusionar(perfil, a)
		else
			err = "Acción desconocida"
		end
		if not err then
			Perfiles.marcar(jugador)
			publicarSaldo(jugador, perfil, "mascotas")
			jugador:SetAttribute("Mascotas", Mascotas.texto(perfil))
		end
	end
	return { error = err, nueva = nueva, lista = perfil.mascotas.lista, equipadas = perfil.mascotas.equipadas, bonos = Mascotas.bonos(perfil), gemas = perfil.gems, huevos = Mascotas.HUEVOS }
end

--------------------------------------------------------------------------------
-- Rasgos y grados (docs/RASGOS.md): tiradas sobre las unidades del propio perfil
--------------------------------------------------------------------------------
rasgosRemoto.OnServerInvoke = function(jugador, nombre, uid, bloqueos)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local err, nuevo
	if nombre ~= "estado" then
		local u = type(uid) == "number" and Unidades.buscar(perfil, uid)
		if partidaDe[jugador] then
			err = "Terminá o abandoná la partida primero" -- el escuadrón de la partida se fijó al empezar
		elseif not u then
			err = "Unidad inválida"
		elseif nombre == "rasgo" then
			local r
			r, err = Rasgos.tirarRasgo(perfil, u, math.random)
			nuevo = r and r.id
		elseif nombre == "grados" then
			local b = {}
			for _, s in Rasgos.STATS do
				b[s] = type(bloqueos) == "table" and bloqueos[s] == true
			end
			err = Rasgos.tirarGrados(perfil, u, b, math.random)
		else
			err = "Acción desconocida"
		end
		if not err then
			Perfiles.marcar(jugador)
			Analitica.saldo(jugador, perfil, "rasgos_" .. nombre)
		end
	end
	local unidades = {}
	for _, u in perfil.units do
		table.insert(unidades, { uid = u.uid, heroId = u.heroId, nivel = u.level, rasgo = u.rasgo, grados = Rasgos.grados(u) })
	end
	return { error = err, nuevo = nuevo, unidades = unidades, fichas = perfil.fichasRasgo, cristales = perfil.cristales, pity = perfil.pityRasgo, garantia = Rasgos.GARANTIA }
end

--------------------------------------------------------------------------------
-- Raids (docs/RAIDS.md): estado y misiones de raid; las salas usan el remoto Sala con acto "raid"
--------------------------------------------------------------------------------
raidRemoto.OnServerInvoke = function(jugador, nombre, a)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local err
	if partidaDe[jugador] and nombre ~= "estado" then
		err = "Terminá o abandoná la partida primero"
	elseif nombre == "canjear" then
		local _, e = Raid.canjear(perfil, os.time())
		err = e
		if not err then
			Perfiles.marcar(jugador)
		end
	elseif nombre == "reclamar" and type(a) == "string" then
		err = Raid.reclamar(perfil, a, os.time())
		if not err then
			Perfiles.marcar(jugador)
			publicarSaldo(jugador, perfil, "raid")
		end
	elseif nombre ~= "estado" then
		err = "Acción desconocida"
	end
	local res = Raid.resumen(perfil, os.time())
	local jefe = enemigosDatos.bosses[res.jefe]
	res.nombreJefe = jefe.name
	res.vidaJefe = jefe.hp
	res.nombreMapa = niveles[indiceNivel(res.mapa)].name
	res.error = err
	return res
end

--------------------------------------------------------------------------------
-- Desafío semanal y rankings (docs/EVENTO.md)
--------------------------------------------------------------------------------
local function datosEvento(jugador: Player, perfil)
	local res = Evento.resumen(perfil, os.time())
	res.ranking = {}
	for _, tabla in Ranking.TABLAS do
		res.ranking[tabla] = Ranking.top(tabla)
	end
	res.mios = { evento = perfil.evento.mejor, infinito = perfil.modeRecords.survival.bestWave, nivel = perfil.level }
	res.nombreMapa = niveles[indiceNivel(res.mapa)].name
	return res
end

eventoRemoto.OnServerInvoke = function(jugador, nombre, a)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local err
	if nombre == "jugar" then
		if partidaDe[jugador] then
			err = "Ya estás en una partida"
		else
			salirDeSala(jugador)
			err = iniciarPartida({ jugador }, jugador, Evento.desafio(Evento.semana(os.time())).mapa, "evento", false)
		end
	elseif nombre == "comprar" and type(a) == "string" then
		err = Evento.comprar(perfil, a, os.time())
		if not err then
			Perfiles.marcar(jugador)
			publicarSaldo(jugador, perfil, "evento")
		end
	elseif nombre ~= "estado" then
		err = "Acción desconocida"
	end
	local res = datosEvento(jugador, perfil)
	res.error = err
	res.empezo = nombre == "jugar" and not err
	return res
end

-- Cartel del top 10 sobre la estación RANKING de la Torre Vengadores.
local cartelRanking
do
	local est = hub:FindFirstChild("Estacion_ranking", true)
	local base = est and est:FindFirstChild("Base")
	if base then
		local pos = base.Position
		local cartel = Instance.new("Part")
		cartel.Name = "CartelRanking"
		cartel.Anchored = true
		cartel.Size = Vector3.new(18, 11, 0.6)
		cartel.Color = Color3.fromRGB(110, 10, 18)
		cartel.Material = Enum.Material.SmoothPlastic
		cartel.CFrame = CFrame.lookAt(pos + Vector3.new(0, 14, 0), Vector3.new(0, pos.Y + 14, 0)) * CFrame.new(0, 0, 3)
		cartel.Parent = est
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 40
		sg.LightInfluence = 0
		sg.Parent = cartel
		cartelRanking = sg
	end
end

local function textoTop(tabla: string, unidad: string): string
	local lineas = {}
	for i, f in Ranking.top(tabla) do
		table.insert(lineas, `{i}. {f.nombre}  ·  {f.valor}{unidad}`)
	end
	return if #lineas > 0 then table.concat(lineas, "\n") else "Todavía nadie"
end

local function pintarCartel()
	if not cartelRanking then
		return
	end
	cartelRanking:ClearAllChildren()
	local marco = Instance.new("Frame")
	marco.Size = UDim2.fromScale(1, 1)
	marco.BackgroundTransparency = 1
	local borde = Instance.new("UIStroke")
	borde.Thickness = 14
	borde.Color = Color3.new(0, 0, 0)
	borde.Parent = marco
	marco.Parent = cartelRanking
	local d = Evento.desafio(Evento.semana(os.time()))
	local function columna(x: number, titulo: string, cuerpo: string)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.new(x, 20, 0, 70)
		t.Size = UDim2.new(0.5, -40, 0, 50)
		t.Font = Enum.Font.Bangers
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 214, 40)
		t.TextStrokeTransparency = 0
		t.Text = titulo
		t.Parent = cartelRanking
		local l = t:Clone()
		l.Position = UDim2.new(x, 20, 0, 130)
		l.Size = UDim2.new(0.5, -40, 1, -150)
		l.Font = Enum.Font.GothamBold
		l.TextScaled = false
		l.TextSize = 24
		l.TextColor3 = Color3.fromRGB(255, 244, 222)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Top
		l.Text = cuerpo
		l.Parent = cartelRanking
	end
	local titulo = Instance.new("TextLabel")
	titulo.BackgroundTransparency = 1
	titulo.Size = UDim2.new(1, 0, 0, 64)
	titulo.Font = Enum.Font.Bangers
	titulo.TextScaled = true
	titulo.TextColor3 = Color3.fromRGB(255, 244, 222)
	titulo.TextStrokeTransparency = 0
	titulo.Text = `RANKING · DESAFÍO EN {string.upper(niveles[indiceNivel(d.mapa)].name)}`
	titulo.Parent = cartelRanking
	columna(0, "DESAFÍO SEMANAL", textoTop("evento", " pts"))
	columna(0.5, "INFINITO", textoTop("infinito", " oleadas"))
end

local function anotarNivel(jugador: Player)
	local nivel = jugador:GetAttribute("Nivel")
	if nivel then
		Ranking.anotar("nivel", jugador.UserId, nivel)
	end
end
Players.PlayerAdded:Connect(function(j)
	j:GetAttributeChangedSignal("Nivel"):Connect(function()
		anotarNivel(j)
	end)
end)
for _, j in Players:GetPlayers() do
	j:GetAttributeChangedSignal("Nivel"):Connect(function()
		anotarNivel(j)
	end)
end
task.spawn(function()
	while true do
		Ranking.revisarSemana()
		Ranking.subir()
		Ranking.refrescar()
		pintarCartel()
		task.wait(60)
	end
end)

--------------------------------------------------------------------------------
-- Misiones y pase de batalla (docs/TEMPORADA.md): estado y reclamos sobre el propio perfil
--------------------------------------------------------------------------------
temporada.OnServerInvoke = function(jugador, nombre, a, b)
	local perfil = Perfiles.de(jugador)
	if not perfil then
		return { error = "Tu perfil todavía no cargó" }
	end
	local ahora = os.time()
	local err
	if nombre == "reclamar" and type(a) == "string" and type(b) == "number" then
		err = Temporada.reclamar(perfil, a, b, ahora)
	elseif nombre == "reclamarPase" and type(a) == "number" then
		err = Temporada.reclamarPase(perfil, a, ahora)
	elseif nombre ~= "estado" then
		err = "Acción desconocida"
	end
	if nombre ~= "estado" and not err then
		Perfiles.marcar(jugador)
		publicarSaldo(jugador, perfil, "pase")
	end
	local res = Temporada.resumen(perfil, ahora)
	res.error = err
	return res
end

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
		if not err then
			Temporada.registrar(perfil, "invocar", arg, os.time())
		end
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
		publicarSaldo(jugador, perfil, nombre) -- invocar, evolucionar, vender, comprar… (acción ya validada)
	end
	res.estado = resumen(perfil)
	return res
end
