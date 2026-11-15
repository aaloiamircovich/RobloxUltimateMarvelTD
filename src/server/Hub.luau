-- HUB de islas flotantes. La isla central (aparición y Torre Vengadores) se conecta con Asgard por el
-- Bifrost, con Wakanda por un puente de selva, con Nueva York por un puente de telarañas, con la Torre
-- Baxter por una pasarela de vidrio y con el Sanctum por un portal.
-- Cada estación tiene un ProximityPrompt (tecla E) que llama a alUsar(jugador, id). Las estaciones tienen un
-- encargado del lore (héroe de Plantillas.Heroes con su reposo) y un puesto temático (Plantillas.Hub/puesto_*);
-- las invocaciones y la Historia siguen siendo portales (docs/LOBBY.md).
-- Edificios: ServerStorage.Plantillas.Hub/<hito> si existe (modelos generados); si no, un bloque provisorio.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Reposo = require(game:GetService("ReplicatedStorage").Shared.Reposo)

local Hub = {}

local ALTO = 1 -- altura del piso de las islas
-- Tamaño del lobby (decidido por el usuario el 15/11/2026): se arma como antes y al final todo se agranda ×ESCALA
-- (islas, puentes, estaciones, árboles, adornos); los edificios (HITOS) crecen además hasta ×ESCALA_EDIFICIOS.
local ESCALA, ESCALA_EDIFICIOS = 2, 3
-- Centro del agrandado: justo debajo de la isla central, para que su piso (y el pasto de terreno) quede a la
-- misma altura que antes.
local PIVOTE = Vector3.new(0, ALTO - 2, 0)

-- Texturas generadas con ForgeGUI (ids en forgegui-project.json): MaterialVariant por superficie.
local TEXTURAS = {
	pasto = { id = "117788957932584", base = Enum.Material.Grass, tile = 16 },
	marmol = { id = "134083532323760", base = Enum.Material.Marble, tile = 16 },
	selva = { id = "137987464329079", base = Enum.Material.Grass, tile = 16 },
	vereda = { id = "96049066085127", base = Enum.Material.Concrete, tile = 12 },
	metal = { id = "76077020809858", base = Enum.Material.Metal, tile = 12 },
	madera = { id = "90645111155656", base = Enum.Material.WoodPlanks, tile = 12 },
	roca = { id = "106184400863615", base = Enum.Material.Rock, tile = 12 },
	-- Mapas de batalla (Mapa.luau): techo y fachada de los edificios, piso del hangar.
	techo = { id = "96343710388043", base = Enum.Material.Metal, tile = 8 },
	fachada = { id = "99733207278881", base = Enum.Material.Concrete, tile = 10 },
	hangar = { id = "78292620747020", base = Enum.Material.Metal, tile = 16 },
	asfalto = { id = "129856472115723", base = Enum.Material.Asphalt, tile = 12 },
}
local SELLO = "132807365750031" -- imagen del sello del portal (ForgeGUI)
Hub.sellos = {}
local CIELO = { Bk = "100762723591606", Dn = "83631052228499", Ft = "97687357399973", Lf = "119663534279596", Rt = "131553877257439", Up = "102386796755504" }

local ISLAS = {
	central = { pos = Vector3.new(0, ALTO, 0), radio = 40, color = "ffffff", textura = "pasto" },
	asgard = { pos = Vector3.new(0, ALTO + 8, -125), radio = 30, color = "ffffff", textura = "marmol" },
	wakanda = { pos = Vector3.new(-125, ALTO, -15), radio = 30, color = "ffffff", textura = "selva" },
	nuevaYork = { pos = Vector3.new(125, ALTO, -15), radio = 32, color = "ffffff", textura = "vereda" },
	baxter = { pos = Vector3.new(-85, ALTO, 110), radio = 24, color = "ffffff", textura = "metal" },
	sanctum = { pos = Vector3.new(85, ALTO, 110), radio = 24, color = "ffffff", textura = "madera" },
}

-- Los MaterialVariants sólo se pueden crear en edición (los scripts del juego no tienen permiso):
-- correr una vez en Studio con `require(game.ServerScriptService.Server.Hub).crearMateriales()` y guardar el lugar.
function Hub.crearMateriales()
	local servicio = game:GetService("MaterialService")
	for nombre, t in TEXTURAS do
		local v = servicio:FindFirstChild("Hub_" .. nombre) or Instance.new("MaterialVariant")
		v.Name = "Hub_" .. nombre
		v.BaseMaterial = t.base
		v.ColorMap = "rbxassetid://" .. t.id
		v.StudsPerTile = t.tile
		v.Parent = servicio
	end
end

-- Cielo del HUB; avisa si faltan los materiales en el lugar.
local function ambientar()
	for nombre in TEXTURAS do
		if not game:GetService("MaterialService"):FindFirstChild("Hub_" .. nombre) then
			warn(`Falta el MaterialVariant Hub_{nombre}: correr Hub.crearMateriales() en Studio y guardar.`)
		end
	end
	workspace.Terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(96, 150, 62))
	local Lighting = game:GetService("Lighting")
	for _, s in Lighting:GetChildren() do
		if s:IsA("Sky") then
			s:Destroy()
		end
	end
	local cielo = Instance.new("Sky")
	cielo.Name = "CieloHub"
	-- El perfil de ForgeGUI deja Lf y Rt invertidos respecto de Roblox (comprobado en Play).
	local destino = { Lf = "Rt", Rt = "Lf" }
	for cara, id in CIELO do
		cielo["Skybox" .. (destino[cara] or cara)] = "rbxassetid://" .. id
	end
	cielo.Parent = Lighting
end

-- Aplica la textura de la tabla a una parte (material base + variante).
local function texturar(p: BasePart, nombre: string)
	p.Material = TEXTURAS[nombre].base
	p.MaterialVariant = "Hub_" .. nombre
end

-- Estaciones: isla, ángulo (grados, 0 = +X, 90 = +Z) y distancia al centro de la isla. Miran al centro de su isla.
Hub.ESTACIONES = {
	{ id = "misiones", nombre = "MISIONES", subtitulo = "Diarias y semanales", color = "64e5ff", isla = "central", angulo = 112, r = 24, personaje = "nick_fury", puesto = "puesto_misiones" },
	{ id = "bailes", nombre = "BAILES", subtitulo = "Rueda de bailes", color = "ff8fd8", isla = "central", angulo = -135, r = 27, personaje = "star_lord", puesto = "puesto_bailes" },
	{ id = "evento", nombre = "EVENTO", subtitulo = "Desafío semanal", color = "ffb347", isla = "central", angulo = -45, r = 27, personaje = "korg", puesto = "puesto_evento" },
	{ id = "ranking", nombre = "RANKING", subtitulo = "Top 10", color = "ffe066", isla = "central", angulo = 20, r = 26, personaje = "valkyrie", puesto = "puesto_ranking" },
	{ id = "monturas", nombre = "MONTURAS", subtitulo = "Moverse rápido", color = "9be37a", isla = "central", angulo = 160, r = 26, personaje = "ghost_rider", puesto = "puesto_monturas" },
	{ id = "summon", nombre = "BANNER 1", subtitulo = "Invocaciones", color = "ffcf72", isla = "asgard", angulo = 120, r = 16, personaje = "heimdall" },
	{ id = "banner_2", nombre = "BANNER 2", subtitulo = "Fichas de raid", color = "ffcf72", isla = "asgard", angulo = 90, r = 18 },
	{ id = "banner_3", nombre = "BANNER 3", subtitulo = "Próximamente", color = "ffcf72", isla = "asgard", angulo = 60, r = 16 },
	{ id = "traits", nombre = "RASGOS", subtitulo = "Fichas de rasgo", color = "7eefa9", isla = "wakanda", angulo = -40, r = 17, personaje = "shuri", puesto = "puesto_rasgos" },
	{ id = "grades", nombre = "GRADOS", subtitulo = "Cristales de grado", color = "ff8faa", isla = "wakanda", angulo = 0, r = 19, personaje = "mbaku", puesto = "puesto_grados" },
	{ id = "pets", nombre = "MASCOTAS", subtitulo = "Huevos", color = "b69aff", isla = "wakanda", angulo = 40, r = 17, personaje = "rocket_raccoon", puesto = "puesto_mascotas" },
	{ id = "raids", nombre = "RAIDS", subtitulo = "Jefe de la semana", color = "ff6b6b", isla = "nuevaYork", angulo = 220, r = 17, personaje = "capitan_america", puesto = "puesto_raids" },
	{ id = "misiones_raid", nombre = "MISIONES DE RAID", subtitulo = "Semanales", color = "ff9f6b", isla = "nuevaYork", angulo = 180, r = 20, personaje = "maria_hill", puesto = "puesto_misiones_raid" },
	{ id = "tienda", nombre = "TIENDA", subtitulo = "Objetos", color = "40c9ff", isla = "nuevaYork", angulo = 140, r = 17, personaje = "spiderman", puesto = "puesto_tienda" },
	{ id = "infinite", nombre = "INFINITO", subtitulo = "Resistí una oleada más", color = "6fb5ff", isla = "baxter_interior", angulo = 270, r = 7, personaje = "mister_fantastic", puesto = "puesto_infinito" },
	{ id = "story", nombre = "HISTORIA", subtitulo = "Modo campaña", color = "ff8f3d", isla = "sanctum_interior", angulo = 270, r = 7, personaje = "wong" },
}

-- Edificios: isla, posición relativa (x, z), alto deseado y huella de la caja provisoria.
local HITOS = {
	{ id = "torre_vengadores", isla = "central", x = 0, z = -4, alto = 34, huella = 10, color = "cfd8e3" },
	{ id = "castillo_asgard", isla = "asgard", x = 0, z = -10, alto = 30, huella = 22, color = "e0b84a" },
	-- Observatorio del Bifrost: al costado de donde llega el puente, mirando hacia él.
	{ id = "observatorio_bifrost", isla = "asgard", x = 13, z = 18, alto = 10, huella = 9, color = "e0b84a", mirar = { x = 0, z = 28 } },
	{ id = "palacio_wakanda", isla = "wakanda", x = -12, z = 0, alto = 18, huella = 16, color = "4b2d6b" },
	{ id = "empire_state", isla = "nuevaYork", x = 12, z = -10, alto = 40, huella = 9, color = "b7b2a6" },
	{ id = "daily_bugle", isla = "nuevaYork", x = 12, z = 12, alto = 22, huella = 10, color = "8a6f5a" },
	{ id = "torre_baxter", isla = "baxter", x = -5, z = 6, alto = 32, huella = 9, color = "3a6fd8" },
	{ id = "sanctum", isla = "sanctum", x = 5, z = 6, alto = 16, huella = 12, color = "7a3b2e" },
}

-- Lugares ocupados en el piso de las islas (antes de agrandar): { pos, radio } para que el decorado no tape
-- estaciones, edificios, puentes ni la aparición.
local ocupado = {}
local function ocupar(pos: Vector3, radio: number)
	table.insert(ocupado, { pos = pos, radio = radio })
end
local function libre(pos: Vector3, radio: number): boolean
	for _, o in ocupado do
		local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(o.pos.X, 0, o.pos.Z)).Magnitude
		if d < radio + o.radio then
			return false
		end
	end
	return true
end

local function parte(padre, color, cf: CFrame, tam: Vector3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Color = if typeof(color) == "string" then Color3.fromHex(color) else color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Size = tam
	p.CFrame = cf
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end

-- Disco horizontal (cilindro acostado) con la cara superior en y.
local function disco(padre, color, centro: Vector3, diametro: number, alto: number, material: Enum.Material?): Part
	local p = parte(padre, color, CFrame.new(centro - Vector3.new(0, alto / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(alto, diametro, diametro), material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function cartel(padre: BasePart, titulo: string, subtitulo: string?, color: Color3, ancho: number)
	local gui = Instance.new("BillboardGui")
	-- El BillboardGui no crece con ScaleTo: se arma ya al tamaño final.
	gui.Size = UDim2.fromScale(ancho * ESCALA, ancho * ESCALA / 4)
	gui.LightInfluence = 0
	gui.MaxDistance = 150 * ESCALA
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, if subtitulo then 0.65 else 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.4
	t.Text = titulo
	t.Parent = gui
	if subtitulo then
		local s = t:Clone()
		s.Position = UDim2.fromScale(0, 0.65)
		s.Size = UDim2.fromScale(1, 0.35)
		s.Font = Enum.Font.GothamMedium
		s.TextColor3 = Color3.new(1, 1, 1)
		s.Text = subtitulo
		s.Parent = gui
	end
	gui.Parent = padre
end

local function letrero(padre, pos: Vector3, titulo, subtitulo, color: Color3, ancho)
	local ancla = parte(padre, color, CFrame.new(pos), Vector3.new(0.1, 0.1, 0.1))
	ancla.Transparency, ancla.CanCollide, ancla.CanQuery = 1, false, false
	cartel(ancla, titulo, subtitulo, color, ancho)
end

-- Interiores (decidido por el usuario el 15/11/2026): salas cerradas lejos y arriba de las islas, a las que se
-- entra por la puerta de un edificio. Para las estaciones funcionan como una isla más (pos y radio).
-- muebles: { plantilla de Plantillas.Hub, x, z, alto, giro en grados } relativos al centro del piso.
local INTERIORES = {
	-- Sanctum: inspirado en las fotos de referencia del usuario (docs/LOBBY.md): madera oscura con molduras doradas,
	-- piso lustrado con incrustaciones de bronce, techo artesonado, ventanal redondo sobre una tarima, vitrinas
	-- con reliquias, cofre y barandas de bronce.
	sanctum_interior = {
		pos = Vector3.new(70, 170, 420), radio = 24, alto = 24, edificio = "sanctum", nombre = "Sanctum Sanctorum",
		piso = "madera", pared = "2b1d15", columna = "180f0a", material = Enum.Material.Wood,
		luz = "ffd49a", acento = "ffb46a", brillo = 0.7, estilo = "sanctum", balcon = true, circulo = true,
		puertaModelo = "int_puerta",
		personajes = { { "doctor_strange", -10, -13, 0 } },
		muebles = {
			{ "int_vitrina", -24, -14, 8, 90 }, { "int_estanteria", -24, 0, 9, 90 }, { "int_estanteria", -24, 13, 9, 90 },
			{ "int_vitrina", 24, -14, 8, -90 },
			{ "int_artefacto", -8, -22, 5, 0, 2 }, { "int_capa", 8, -22, 6, 0, 2 },
			{ "int_atril", -10, 10, 4.5, 135 }, { "int_alfombra", 0, 19, 0.4, 0 }, { "int_cofre", 10, 10, 3, -20 },
			{ "int_escritorio", -16, 21, 4, 90 }, { "int_estatua", 15, 21, 6, 200 },
		},
		-- Libros flotando (alto sobre el piso).
		flotantes = { { "int_libro", -20, -6, 8 }, { "int_libro", 20, 6, 9 }, { "int_libro", -12, -2, 9 } },
		colgantes = { { "int_candelabro", 0, 2, 5 } },
	},
	baxter_interior = {
		pos = Vector3.new(-70, 170, 420), radio = 24, alto = 24, edificio = "torre_baxter", nombre = "Laboratorio de la Torre Baxter",
		piso = "metal", pared = "dfe6ee", columna = "9fb3c8", material = Enum.Material.SmoothPlastic,
		luz = "b6dcff", acento = "4fa3ff", brillo = 1, ventanal = true, zonaNegativa = true, logo = true,
		personajes = { { "invisible_woman", -9, -15, 0 }, { "human_torch", 9, -15, 0 } },
		muebles = {
			{ "int_consola", -9, -24, 6, 0 }, { "int_consola", 9, -24, 6, 0 },
			{ "int_fantasticar", 16, 19, 3.5, 135 }, { "int_tubo", 24, -12, 6, -90 }, { "int_tubo", 24, 12, 6, -90 },
			{ "int_mesa", -10, 10, 3.5, 90 }, { "int_mesa", 10, 10, 3.5, -90 },
		},
		flotantes = { { "int_herbie", -5, -19, 6 } },
		colgantes = {},
	},
}

local function lugar(nombre: string)
	return ISLAS[nombre] or INTERIORES[nombre]
end

local function enIsla(isla, angulo: number, r: number): Vector3
	local a = math.rad(angulo)
	return isla.pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

-- Isla: tapa de terreno, borde y una raíz de roca que se afina hacia abajo. Las de pasto llevan encima
-- pasto 3D de terreno (Terrain.Decoration, activado en el lugar) y luciérnagas.
local function isla(padre, datos)
	local m = Instance.new("Model")
	local pasto = TEXTURAS[datos.textura].base == Enum.Material.Grass
	-- En las de pasto la tapa queda 2 studs abajo: la superficie es el terreno, que se ve 2 studs más arriba que su relleno.
	local tapa = disco(m, datos.color, datos.pos - Vector3.new(0, if pasto then 2 else 0, 0), datos.radio * 2, 3)
	texturar(tapa, datos.textura)
	if pasto then
		-- El pasto de terreno se llena después de agrandar el lobby (pastoDeTerreno).
		local motas = Instance.new("ParticleEmitter")
		motas.Color = ColorSequence.new(Color3.fromRGB(255, 236, 150))
		motas.LightEmission = 0.8
		motas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0) })
		motas.Lifetime = NumberRange.new(6, 10)
		motas.Rate = 4
		motas.Speed = NumberRange.new(0.3, 1)
		motas.SpreadAngle = Vector2.new(180, 180)
		motas.Parent = tapa
	end
	texturar(disco(m, "ffffff", datos.pos - Vector3.new(0, 3, 0), datos.radio * 2 - 1, 3), "roca")
	for i, f in { 0.82, 0.62, 0.42, 0.24 } do
		texturar(disco(m, if i % 2 == 0 then "d9d2c8" else "ffffff", datos.pos - Vector3.new(0, 2 + i * 5, 0), datos.radio * 2 * f, 5.5), "roca")
	end
	m.Parent = padre
end

-- Pasto 3D de terreno sobre una isla de pasto, con su posición y radio ya agrandados: el relleno termina en la
-- cara de arriba de la tapa y el pasto se ve 2 studs más arriba (que es donde camina el jugador).
local function pastoDeTerreno(datos)
	local centro = PIVOTE + (datos.pos - PIVOTE) * ESCALA
	local tope = PIVOTE.Y + (datos.pos.Y - 2 - PIVOTE.Y) * ESCALA -- cara de arriba de la tapa agrandada
	-- Franjas de 4 studs (un voxel): FillCylinder llena voxeles enteros y dejaría el pasto 3 studs más alto.
	local r = datos.radio * ESCALA - 1
	-- Franjas alineadas a la grilla del mundo: si no, los voxeles quedan a medias y el pasto se hunde.
	local cx = centro.X
	for x = math.ceil((cx - r) / 4) * 4 + 2, cx + r - 2, 4 do
		local cuerda = 2 * math.sqrt(math.max(0, r * r - (x - cx) ^ 2))
		workspace.Terrain:FillBlock(CFrame.new(x, tope - 2, centro.Z), Vector3.new(4, 4, cuerda), Enum.Material.Grass)
	end
end

-- Modelo generado de ServerStorage.Plantillas.Hub (mira a −Z, pivote en el centro de su caja), o nil.
local function plantilla(id: string): Model?
	local p = ServerStorage:FindFirstChild("Plantillas")
	local h = p and p:FindFirstChild("Hub")
	return h and h:FindFirstChild(id)
end

-- Clon de una plantilla escalado para que su eje mida `medida` (X, Y o Z del tamaño).
local function clonar(m: Model, eje: string, medida: number): Model
	local c = m:Clone()
	c:ScaleTo(c:GetScale() * medida / c:GetExtentsSize()[eje])
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return c
end

-- Puente entre dos puntos del borde de las islas, con barandas invisibles para no caerse.
-- Con plantilla "tramo_<estilo>", el piso es invisible y los tramos generados lo cubren.
local ARCOIRIS = { "ff4d4d", "ff9f40", "ffe14d", "5cff7a", "4dc3ff", "6b6bff", "c46bff" }
local function puente(padre, a: Vector3, b: Vector3, estilo: string)
	local m = Instance.new("Model")
	m.Name = "Puente_" .. estilo
	local largo = (b - a).Magnitude
	local ancho = if estilo == "bifrost" then 7 else 6
	local paso = 2
	local n = math.ceil(largo / paso)
	local tramo = plantilla("tramo_" .. estilo)
	local function curva(t: number): Vector3
		local caida = if estilo == "selva" or estilo == "telarana" then -math.sin(math.pi * t) * 2.5 else 0
		return a:Lerp(b, t) + Vector3.new(0, caida - 0.25, 0)
	end
	if tramo then
		local muestra = clonar(tramo, "X", ancho + 1)
		local largoTramo = muestra:GetExtentsSize().Z * 0.96 -- leve solape entre tramos
		local alto = muestra:GetExtentsSize().Y
		local cantidad = math.ceil(largo / largoTramo)
		for k = 0, cantidad - 1 do
			local t0, t1 = k / cantidad, (k + 1) / cantidad
			local p0, p1 = curva(t0), curva(t1)
			local c = if k == 0 then muestra else muestra:Clone()
			-- El piso del tramo queda al ras del piso invisible.
			c:PivotTo(CFrame.lookAt((p0 + p1) / 2, (p0 + p1) / 2 + (p1 - p0)) * CFrame.new(0, alto / 2 - 0.2, 0))
			for _, d in c:GetDescendants() do
				if d:IsA("BasePart") then
					d.CanCollide, d.CanQuery = false, false
				end
			end
			c.Parent = m
		end
	end
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		local p = curva(t)
		local cf = CFrame.lookAt(p, p + (b - a))
		if tramo then
			local piso = parte(m, "ffffff", cf, Vector3.new(ancho, 0.4, paso + 0.05))
			piso.Transparency = 1
		elseif estilo == "bifrost" then
			-- Losas de luz: Hub.animar corre el arcoíris a lo largo del puente.
			local tabla = parte(m, ARCOIRIS[i % #ARCOIRIS + 1], cf, Vector3.new(ancho, 0.5, paso + 0.05), Enum.Material.Neon)
			tabla.Transparency = 0.25
			tabla.Name = "Bifrost"
			tabla:SetAttribute("Indice", i)
			if i % 3 == 0 then
				local brillo = Instance.new("ParticleEmitter")
				brillo.Color = ColorSequence.new(Color3.new(1, 1, 1))
				brillo.LightEmission = 1
				brillo.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.2), NumberSequenceKeypoint.new(1, 0) })
				brillo.Transparency = NumberSequence.new(0.2)
				brillo.Lifetime = NumberRange.new(0.8, 1.6)
				brillo.Rate = 6
				brillo.Speed = NumberRange.new(1, 2.5)
				brillo.EmissionDirection = Enum.NormalId.Top
				brillo.SpreadAngle = Vector2.new(25, 25)
				brillo.Parent = tabla
			end
		elseif estilo == "selva" then
			parte(m, if i % 2 == 0 then "8a5a33" else "7a4e2b", cf, Vector3.new(ancho, 0.4, paso - 0.25), Enum.Material.WoodPlanks)
			if i % 3 == 0 then
				for _, lado in { -1, 1 } do
					parte(m, "5a3b20", cf * CFrame.new(lado * (ancho / 2 + 0.2), 1.6, 0), Vector3.new(0.5, 3.6, 0.5), Enum.Material.Wood)
					parte(m, "3f8a3c", cf * CFrame.new(lado * (ancho / 2 + 0.2), 3, 0), Vector3.new(0.6, 0.6, paso * 3), Enum.Material.Grass)
				end
			end
		elseif estilo == "telarana" then
			-- Hilos a lo largo, travesaños y, cada tanto, hilos en diagonal hacia las barandas.
			for _, x in { -2.4, -1.2, 0, 1.2, 2.4 } do
				parte(m, "f2f2f2", cf * CFrame.new(x, 0, 0), Vector3.new(0.18, 0.18, paso + 0.1))
			end
			parte(m, "e6e6e6", cf, Vector3.new(ancho, 0.15, 0.15))
			for _, lado in { -1, 1 } do
				parte(m, "f2f2f2", cf * CFrame.new(lado * ancho / 2, 2.4, 0), Vector3.new(0.15, 0.15, paso + 0.1))
				if i % 2 == 0 then
					parte(m, "e6e6e6", cf * CFrame.new(lado * ancho / 2, 1.2, 0) * CFrame.Angles(math.rad(45), 0, 0), Vector3.new(0.12, 0.12, 3.4))
				end
			end
			local piso = parte(m, "ffffff", cf, Vector3.new(ancho, 0.3, paso + 0.05))
			piso.Transparency = 1
		elseif estilo == "baxter" then
			local vidrio = parte(m, "bfe4ff", cf, Vector3.new(ancho, 0.4, paso + 0.05), Enum.Material.Glass)
			vidrio.Transparency = 0.35
			for _, lado in { -1, 1 } do
				parte(m, "3a8bff", cf * CFrame.new(lado * ancho / 2, 1.2, 0), Vector3.new(0.15, 0.15, paso + 0.05), Enum.Material.Neon)
				if i % 5 == 0 then
					local poste = parte(m, "dfe8f2", cf * CFrame.new(lado * ancho / 2, 0.6, 0), Vector3.new(0.3, 1.2, 0.3), Enum.Material.Metal)
					if i % 10 == 0 and lado == 1 then
						cartel(poste, "4", nil, Color3.fromHex("3a8bff"), 2)
					end
				end
			end
		end
		for _, lado in { -1, 1 } do
			local baranda = parte(m, "ffffff", cf * CFrame.new(lado * (ancho / 2 + 0.5), 2, 0), Vector3.new(0.4, 4, paso + 0.05))
			baranda.Transparency, baranda.CanQuery = 1, false
		end
	end
	m.Parent = padre
end

-- Punto del borde de la isla `de` en dirección a la isla `a`.
local function borde(de, a): Vector3
	local d = (a.pos - de.pos) * Vector3.new(1, 0, 1)
	return de.pos + d.Unit * (de.radio - 1.5)
end

-- Portal de pie: tocarlo lleva al jugador a `destino`.
local function portal(padre, pos: Vector3, mira: Vector3, destino: CFrame)
	ocupar(pos, 8)
	local m = Instance.new("Model")
	m.Name = "Portal"
	local radio = 4.6
	local cf = CFrame.lookAt(pos + Vector3.new(0, radio + 0.6, 0), mira + Vector3.new(0, radio + 0.6, 0))
	-- Centro: velo naranja translúcido que se atraviesa.
	local centro = parte(m, "ff7a1a", cf * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.3, radio * 2 - 0.4, radio * 2 - 0.4), Enum.Material.Neon)
	centro.Shape = Enum.PartType.Cylinder
	centro.Transparency = 0.9
	centro.CanCollide = false
	-- Sello místico girando en las dos caras (imagen generada con ForgeGUI).
	local lamina = parte(m, "ffffff", cf, Vector3.new(radio * 2.3, radio * 2.3, 0.05))
	lamina.Transparency, lamina.CanCollide, lamina.CanQuery, lamina.CanTouch = 1, false, false, false
	for _, cara in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = cara
		gui.LightInfluence = 0
		gui.Brightness = 2
		gui.PixelsPerStud = 40
		local sello = Instance.new("ImageLabel")
		sello.Name = "Sello"
		sello.BackgroundTransparency = 1
		sello.Size = UDim2.fromScale(1, 1)
		sello.Image = "rbxassetid://" .. SELLO
		sello.ImageColor3 = Color3.fromHex("ffb347")
		sello.Parent = gui
		gui.Parent = lamina
		table.insert(Hub.sellos, sello)
	end
	-- Anillo de chispas: emisores sobre la circunferencia que despiden chispas tangentes, como un portal de hechicero.
	-- El aro es invisible: sólo sostiene los emisores; el borde lo dibujan las chispas.
	local aro = parte(m, "ff6a00", cf * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.25, radio * 2 + 0.3, radio * 2 + 0.3))
	aro.Transparency, aro.CanCollide, aro.CanQuery, aro.CanTouch = 1, false, false, false
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		local punto = Instance.new("Attachment")
		punto.CFrame = CFrame.new(0, math.cos(a) * radio, math.sin(a) * radio) * CFrame.Angles(a, 0, 0)
		punto.Parent = aro
		local chispas = Instance.new("ParticleEmitter")
		chispas.Color = ColorSequence.new(Color3.fromHex("ffd27a"), Color3.fromHex("ff5a00"))
		chispas.LightEmission = 1
		chispas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		chispas.Lifetime = NumberRange.new(0.3, 0.6)
		chispas.Rate = 40
		chispas.Speed = NumberRange.new(6, 10)
		chispas.Drag = 3
		chispas.Acceleration = Vector3.new(0, -6, 0)
		chispas.EmissionDirection = Enum.NormalId.Front
		chispas.SpreadAngle = Vector2.new(12, 12)
		chispas.Parent = punto
	end
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromHex("ff8a2a")
	luz.Range = 14
	luz.Brightness = 2
	luz.Parent = centro
	local recien = {}
	centro.Touched:Connect(function(otro)
		local personaje = otro.Parent
		local jugador = Players:GetPlayerFromCharacter(personaje)
		if not jugador or (recien[jugador] and os.clock() - recien[jugador] < 2) then
			return
		end
		recien[jugador] = os.clock()
		personaje:PivotTo(destino)
	end)
	m.Parent = padre
end

-- Estación: base con luz, marco con portal y orbe que gira, cartel y ProximityPrompt.
-- Encargado de una estación: el héroe con sólo la raíz anclada (para que lo mueva la animación) y los pies en
-- `cf`, mirando a su −Z. La animación de reposo arranca cuando el lobby ya está en el workspace (Hub.construir).
local encargados = {}
local function encargado(padre, id: string, cf: CFrame)
	local p = ServerStorage:FindFirstChild("Plantillas")
	local heroes = p and p:FindFirstChild("Heroes")
	local t = heroes and heroes:FindFirstChild(id)
	if not t then
		return
	end
	local m = t:Clone()
	m.Name = "Encargado"
	local raiz = m:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = m:FindFirstChildOfClass("Humanoid")
	if not (raiz and hum) then
		m:Destroy()
		return
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = d == raiz
			d.CanCollide = d == raiz -- se choca con el cuerpo, no se lo atraviesa
		end
	end
	hum.EvaluateStateMachine = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	local caja, tam = m:GetBoundingBox()
	local desfase = (CFrame.new(caja.Position) * raiz.CFrame.Rotation):ToObjectSpace(raiz.CFrame)
	raiz.CFrame = cf * CFrame.new(0, tam.Y / 2, 0) * desfase
	m.Parent = padre
	table.insert(encargados, { modelo = m, id = id })
end

local function estacion(padre, e, alUsar)
	local datos = lugar(e.isla)
	local pos = enIsla(datos, e.angulo, e.r)
	ocupar(pos, 7)
	local cf = CFrame.lookAt(pos, Vector3.new(datos.pos.X, pos.Y, datos.pos.Z))
	local color = Color3.fromHex(e.color)
	local m = Instance.new("Model")
	m.Name = "Estacion_" .. e.id
	local base = disco(m, "152438", pos + Vector3.new(0, 0.36, 0), 3.2, 0.36)
	base.Name = "Base"
	disco(m, color, pos + Vector3.new(0, 0.39, 0), 2.9, 0.035, Enum.Material.Neon)
	-- Puesto temático detrás de la base (lejos del centro de la isla), mirando al centro; sin puesto, el portal.
	local puesto = e.puesto and plantilla(e.puesto)
	if puesto then
		local c = clonar(puesto, "Y", 4)
		c:PivotTo(cf * CFrame.new(0, c:GetExtentsSize().Y / 2, 2.4))
		c.Name = "Puesto"
		c.Parent = m
	end
	if e.personaje then
		-- Encargado al costado, mirando al centro (al lado del puesto o del portal).
		encargado(m, e.personaje, cf * CFrame.new(if puesto then 2.8 else 3.6, 0.36, if puesto then 0.9 else 0.6))
	end
	if not puesto then
		-- Portal: el marco queda detrás de la base y mira hacia el centro.
		local marco = plantilla("estacion")
		if marco then
			local c = clonar(marco, "Y", 6)
			c:PivotTo(cf * CFrame.new(0, 3, 1.4))
			c.Parent = m
		else
			parte(m, "172e48", cf * CFrame.new(0, 2.8, 1.7), Vector3.new(6, 5.6, 0.7))
			for _, lado in { -1, 1 } do
				parte(m, color, cf * CFrame.new(lado * 2.5, 2.6, 1.22), Vector3.new(0.13, 4.7, 0.12), Enum.Material.Neon)
			end
			parte(m, color, cf * CFrame.new(0, 5, 1.22), Vector3.new(5.1, 0.14, 0.12), Enum.Material.Neon)
		end
		local aro = parte(m, color, cf * CFrame.new(0, 2.7, 1.16) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.1, 3.3, 3.3), Enum.Material.Neon)
		aro.Shape = Enum.PartType.Cylinder
		local orbe = parte(m, color, cf * CFrame.new(0, 2.7, 0.9) * CFrame.Angles(math.rad(45), 0, math.rad(45)), Vector3.new(0.9, 0.9, 0.9), Enum.Material.Neon)
		orbe.Name = "Orbe"
	end
	letrero(m, (cf * CFrame.new(0, 6.3, 1)).Position, e.nombre, e.subtitulo, color, 8)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = e.nombre
	prompt.ObjectText = e.subtitulo
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 7 * ESCALA
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(jugador)
		alUsar(jugador, e.id)
	end)
	prompt.Parent = base
	m.Parent = padre
end

-- 8 plataformas de sala alrededor de la estación del modo.
local function salas(padre, islaId: string, modo: string, anguloCentro: number, alUsar)
	local datos = lugar(islaId)
	for i = 1, 8 do
		local angulo = anguloCentro + (i - 4.5) * 22
		-- En los interiores (salas chicas): dos filas de 4 contra las paredes de los costados; afuera, en arco.
		local pos = if INTERIORES[islaId]
			then datos.pos + Vector3.new(if i <= 4 then -17 else 17, 0, -12 + ((i - 1) % 4) * 8)
			else enIsla(datos, angulo, 19)
		local base = disco(padre, "1d2633", pos + Vector3.new(0, 0.3, 0), 4.4, 0.3)
		base.Name = `Sala_{modo}_{i}`
		disco(padre, if modo == "infinite" then "3a7bd5" else "c2571a", pos + Vector3.new(0, 0.33, 0), 4, 0.03)
		letrero(padre, pos + Vector3.new(0, 3, 0), `SALA {i}`, "0/4", Color3.new(1, 1, 1), 4)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Crear sala"
		prompt.ObjectText = `Sala {i}`
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 5 * ESCALA
		prompt.RequiresLineOfSight = false
		prompt.Triggered:Connect(function(jugador)
			alUsar(jugador, "sala_" .. modo)
		end)
		prompt.Parent = base
	end
end

-- Edificio: el modelo de ServerStorage.Plantillas.Hub/<id> escalado al alto pedido, o una caja provisoria.
local puerta, marcador -- de los interiores, definidas más abajo

local function hito(padre, h)
	local datos = ISLAS[h.isla]
	local base = datos.pos + Vector3.new(h.x, 0, h.z)
	-- Mira al centro de su isla, o al punto relativo `h.mirar` si lo tiene.
	local objetivo = if h.mirar then datos.pos + Vector3.new(h.mirar.x, 0, h.mirar.z) else datos.pos
	local mira = CFrame.lookAt(base, Vector3.new(objetivo.X, base.Y, objetivo.Z))
	local modelo = plantilla(h.id)
	local extra = ESCALA_EDIFICIOS / ESCALA -- con el agrandado final quedan ×ESCALA_EDIFICIOS
	if modelo then
		local m = clonar(modelo, "Y", h.alto * extra)
		-- La plantilla mira a −Z con el pivote en el centro de la caja: apoyarla en el piso.
		m:PivotTo(mira * CFrame.new(0, m:GetExtentsSize().Y / 2, 0))
		m.Name = "Hito_" .. h.id
		local tam = m:GetExtentsSize()
		ocupar(base, math.max(tam.X, tam.Z) / 2 + 2)
		for id, interior in INTERIORES do
			if interior.edificio == h.id then
				-- Puerta en la fachada (mira al centro de la isla) que lleva al interior.
				local frente = mira * CFrame.new(0, 0, -m:GetExtentsSize().Z / 2 - 0.4)
				puerta(m, frente, Color3.fromHex(interior.luz), "Entrar", interior.nombre, function()
					return Hub.llegadas[id]
				end)
				marcador(m, "Afuera_" .. id, frente * CFrame.new(0, 0, -6)) -- al salir, de espaldas al edificio
			end
		end
		m.Parent = padre
		return
	end
	local m = Instance.new("Model")
	m.Name = "Hito_" .. h.id
	parte(m, h.color, mira * CFrame.new(0, h.alto * extra / 2, 0), Vector3.new(h.huella * extra, h.alto * extra, h.huella * extra), Enum.Material.Concrete)
	letrero(m, base + Vector3.new(0, h.alto * extra + 2, 0), (h.id:upper():gsub("_", " ")), nil, Color3.fromHex(h.color), 10)
	m.Parent = padre
end

local function arbol(padre, pos: Vector3, copa: string, id: string, alto: number)
	ocupar(pos, 3)
	local modelo = plantilla(id)
	if modelo then
		local c = clonar(modelo, "Y", alto)
		-- Giro según la posición para que los árboles no se vean todos iguales.
		c:PivotTo(CFrame.new(pos + Vector3.new(0, alto / 2, 0)) * CFrame.Angles(0, (pos.X * 7 + pos.Z * 13) % 6.28, 0))
		c.Parent = padre
		return
	end
	disco(padre, "5a3b20", pos + Vector3.new(0, 2.5, 0), 0.7, 2.5, Enum.Material.Wood)
	local c = parte(padre, copa, CFrame.new(pos + Vector3.new(0, 3.6, 0)), Vector3.new(3, 3, 3), Enum.Material.Grass)
	c.Shape = Enum.PartType.Ball
end

-- Decoración común (ServerStorage.Plantillas.Deco): apoyada en `pos`, mirando a `mira` si se da.
local function adorno(padre, id: string, pos: Vector3, alto: number, mira: Vector3?): Model?
	ocupar(pos, 2)
	local p = ServerStorage:FindFirstChild("Plantillas")
	local d = p and p:FindFirstChild("Deco")
	local m = d and d:FindFirstChild(id)
	if not m then
		return nil
	end
	local c = clonar(m, "Y", alto)
	local giro = if mira then CFrame.lookAt(pos, Vector3.new(mira.X, pos.Y, mira.Z)) else CFrame.new(pos) * CFrame.Angles(0, (pos.X * 7 + pos.Z * 13) % 6.28, 0)
	c:PivotTo(giro * CFrame.new(0, c:GetExtentsSize().Y / 2, 0))
	c.Parent = padre
	return c
end

--------------------------------------------------------------------------------
-- Decorado de cada isla (decidido por el usuario el 15/11/2026: el lobby se veía vacío). Reusa los kits de los
-- mapas de partida del mismo tema y piezas propias de Plantillas.Hub: { carpeta, nombre, alto, cantidad, luz? }.
-- carpeta: "Hub" (Plantillas.Hub), "Deco" (Plantillas.Deco) o el tema de Plantillas.Mapas.
--------------------------------------------------------------------------------
local DECORADO = {
	central = {
		{ "Hub", "fuente", 7, 1 }, { "Hub", "estatua_heroe", 7, 3 }, { "Deco", "farol", 6, 4, "ffe2aa" },
		{ "Deco", "arbusto", 2.4, 8 }, { "Deco", "flores", 1, 12 },
	},
	asgard = { { "asgard", "runa", 2.5, 6 }, { "asgard", "farol", 5, 4, "8fd0ff" }, { "asgard", "arbol", 8, 3 } },
	wakanda = {
		{ "Hub", "estatua_pantera", 6, 1 }, { "wakanda", "cristal", 2.5, 7, "b070ff" }, { "wakanda", "helecho", 2.2, 9 },
		{ "wakanda", "farol", 5, 3, "ffd27a" },
	},
	nuevaYork = {
		{ "new-york", "vehiculo", 3, 2 }, { "new-york", "hidrante", 1.6, 3 }, { "new-york", "basurero", 2, 3 },
		{ "new-york", "farol", 6, 4, "ffe2aa" }, { "new-york", "arbol", 7, 2 },
	},
	baxter = { { "the-raft", "cajas", 2, 4 }, { "the-raft", "farol", 6, 3, "b6dcff" } },
	sanctum = { { "sanctum", "brasero", 2.6, 4, "ff9a40" }, { "sanctum", "arbol", 7, 3 }, { "sanctum", "farol", 5, 3, "ffb46a" } },
}

local function plantillaDe(carpeta: string, nombre: string): Model?
	local p = ServerStorage:FindFirstChild("Plantillas")
	if not p then
		return nil
	end
	local f = if carpeta == "Hub" or carpeta == "Deco" then p:FindFirstChild(carpeta) else (p:FindFirstChild("Mapas") and p.Mapas:FindFirstChild(carpeta))
	return f and f:FindFirstChild(nombre)
end

local function hash(a: number, b: number): number
	return (a * 73856093 + b * 19349663) % 1000
end

-- Reparte el decorado de una isla en lugares libres (sorteo fijo, siempre igual), entre el 30 % y el 88 % del radio.
local function decorarIsla(padre, islaId: string)
	local datos = ISLAS[islaId]
	for k, item in DECORADO[islaId] or {} do
		local modelo = plantillaDe(item[1], item[2])
		if not modelo then
			continue
		end
		local puestos, intento = 0, 0
		while puestos < item[4] and intento < 60 do
			intento += 1
			local h1, h2 = hash(k * 31 + intento, #islaId), hash(intento * 17 + k, puestos + 3)
			local angulo = h1 / 1000 * 360
			local r = datos.radio * (0.3 + 0.58 * h2 / 1000)
			local pos = enIsla(datos, angulo, r)
			local radio = math.max(1.5, item[3] * 0.45)
			if libre(pos, radio) then
				ocupar(pos, radio)
				puestos += 1
				local c = clonar(modelo, "Y", item[3])
				c:PivotTo(CFrame.new(pos + Vector3.new(0, c:GetExtentsSize().Y / 2, 0)) * CFrame.Angles(0, h2 / 1000 * math.pi * 2, 0))
				if item[5] then
					-- Faroles y cristales: luz en la parte más alta.
					local arriba
					for _, d in c:GetDescendants() do
						if d:IsA("BasePart") and (not arriba or d.Position.Y > arriba.Position.Y) then
							arriba = d
						end
					end
					if arriba then
						local luz = Instance.new("PointLight")
						luz.Color, luz.Range, luz.Brightness = Color3.fromHex(item[5]), 14, 1.3
						luz.Parent = arriba
					end
				end
				if item[2] == "fuente" then
					-- Chorro de agua de la fuente.
					local chorro = Instance.new("ParticleEmitter")
					chorro.Color = ColorSequence.new(Color3.fromRGB(170, 220, 255))
					chorro.LightEmission = 0.3
					chorro.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
					chorro.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.15) })
					chorro.Lifetime = NumberRange.new(1, 1.4)
					chorro.Rate = 60
					chorro.Speed = NumberRange.new(8, 11)
					chorro.SpreadAngle = Vector2.new(14, 14)
					chorro.Acceleration = Vector3.new(0, -18, 0)
					local boca = Instance.new("Attachment")
					boca.Position = Vector3.new(0, c:GetExtentsSize().Y * 0.4, 0)
					local raiz = c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart", true)
					boca.Parent = raiz
					chorro.Parent = boca
				end
				c.Parent = padre
			end
		end
	end
end

-- Cielo: el Helicarrier de S.H.I.E.L.D. quieto en el aire, un Quinjet que el cliente hace dar vueltas
-- (CieloHub.client.luau) e islotes de roca flotando alrededor.
local ISLOTES = {
	{ Vector3.new(-170, 22, -90), 7 }, { Vector3.new(175, 30, -100), 6 }, { Vector3.new(-40, 40, 190), 8 },
	{ Vector3.new(60, 18, -200), 5 }, { Vector3.new(200, 12, 80), 6 }, { Vector3.new(-200, 35, 60), 5 },
}
local function cielo(padre)
	local m = Instance.new("Model")
	m.Name = "Cielo"
	local heli = plantillaDe("Hub", "helicarrier")
	if heli then
		local c = clonar(heli, "X", 70)
		c:PivotTo(CFrame.new(-60, 70, -150) * CFrame.Angles(0, math.rad(30), 0))
		c.Name = "Helicarrier"
		c.Parent = m
	end
	local jet = plantillaDe("Hub", "quinjet")
	if jet then
		local c = clonar(jet, "X", 9)
		c:PivotTo(CFrame.new(0, 45, -60))
		c.Name = "Quinjet"
		c.Parent = m
	end
	for i, d in ISLOTES do
		isla(m, { pos = d[1], radio = d[2], color = "ffffff", textura = "roca" })
		local adornoIslote = if i % 2 == 0 then plantillaDe("wakanda", "cristal") else plantillaDe("asgard", "arbol")
		if adornoIslote then
			local c = clonar(adornoIslote, "Y", if i % 2 == 0 then 3 else 6)
			c:PivotTo(CFrame.new(d[1] + Vector3.new(0, c:GetExtentsSize().Y / 2, 0)))
			c.Parent = m
		end
	end
	m.Parent = padre
end

-- Lleva al jugador a una parte marcadora (su CFrame ya agrandado), pidiendo antes que cargue esa zona.
local function viajar(jugador: Player, destino: BasePart)
	local c = jugador.Character
	if not c then
		return
	end
	pcall(jugador.RequestStreamAroundAsync, jugador, destino.Position, 3)
	c:PivotTo(destino.CFrame + Vector3.new(0, 3, 0))
end

-- Puerta con «tecla E» (marco de luz y una parte invisible con el ProximityPrompt) que lleva a `destino`.
-- `modelo` (opcional, de Plantillas.Hub): una puerta de verdad en vez del marco de luz; la hoja queda invisible.
puerta = function(padre, cf: CFrame, color: Color3, accion: string, objeto: string, destino: () -> BasePart?, modelo: string?)
	local m = Instance.new("Model")
	m.Name = "Puerta"
	local pl = modelo and plantilla(modelo)
	if pl then
		local d = clonar(pl, "Y", 10)
		d:PivotTo(cf * CFrame.new(0, d:GetExtentsSize().Y / 2, 0.1))
		d.Parent = m
	else
		for _, lado in { -1, 1 } do
			parte(m, color, cf * CFrame.new(lado * 2.6, 3.6, 0), Vector3.new(0.5, 7.2, 0.5), Enum.Material.Neon)
		end
		parte(m, color, cf * CFrame.new(0, 7.2, 0), Vector3.new(5.7, 0.5, 0.5), Enum.Material.Neon)
	end
	local hoja = parte(m, color, cf * CFrame.new(0, 3.5, -0.3), Vector3.new(4.7, 7, 0.2), Enum.Material.ForceField)
	hoja.CanCollide = false
	hoja.Transparency = if pl then 1 else 0.4
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = accion
	prompt.ObjectText = objeto
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 8 * ESCALA
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(jugador)
		local d = destino()
		if d then
			viajar(jugador, d)
		end
	end)
	prompt.Parent = hoja
	m.Parent = padre
	return m
end

-- Marcador invisible: el lugar (y hacia dónde mira) en que aparece quien entra o sale.
marcador = function(padre, nombre: string, cf: CFrame): Part
	local p = parte(padre, "ffffff", cf, Vector3.new(1, 1, 1))
	p.Name = nombre
	p.Transparency, p.CanCollide, p.CanQuery, p.CanTouch = 1, false, false, false
	return p
end

local BRONCE = Color3.fromRGB(181, 140, 72)

-- Sanctum como en las fotos de referencia: molduras doradas y apliques en las paredes, techo artesonado,
-- incrustaciones de bronce en el piso lustrado y el ventanal redondo sobre una tarima con escalones y barandas.
local function extrasSanctum(m, c: Vector3, r: number, alto: number, datos)
	local madera = Color3.fromHex(datos.columna)
	-- Molduras doradas en las cuatro paredes (la del medio no cruza el ventanal del fondo).
	for _, d in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
		for _, y in if d.Z < 0 then { 3, alto - 2 } else { 3, 11, alto - 2 } do
			parte(m, BRONCE, CFrame.new(c + d * (r - 0.55) + Vector3.new(0, y, 0)), if d.X ~= 0 then Vector3.new(0.2, 0.35, r * 2) else Vector3.new(r * 2, 0.35, 0.2), Enum.Material.Metal)
		end
		-- Apliques de luz cálida en las columnas.
		local tangente = Vector3.new(math.abs(d.Z), 0, math.abs(d.X))
		for k = -r + 6, r - 6, 12 do
			if d.Z < 0 and math.abs(k) < 13 then
				continue -- delante del ventanal no hay columnas
			end
			local base = c + d * (r - 1.9) + tangente * k + Vector3.new(0, 8, 0)
			parte(m, BRONCE, CFrame.new(base), Vector3.new(0.6, 1.2, 0.6), Enum.Material.Metal)
			local foco = parte(m, "ffd49a", CFrame.new(base + Vector3.new(0, 1, 0)), Vector3.new(0.8, 0.8, 0.8), Enum.Material.Neon)
			foco.Shape = Enum.PartType.Ball
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 200, 140), 14, 0.9
			l.Parent = foco
		end
	end
	-- Techo artesonado: vigas cruzadas cada 8 studs con filete dorado.
	for k = -r + 4, r - 4, 8 do
		parte(m, madera, CFrame.new(c + Vector3.new(k, alto - 0.8, 0)), Vector3.new(1.2, 1.6, r * 2), Enum.Material.Wood)
		parte(m, madera, CFrame.new(c + Vector3.new(0, alto - 0.8, k)), Vector3.new(r * 2, 1.6, 1.2), Enum.Material.Wood)
		parte(m, BRONCE, CFrame.new(c + Vector3.new(k, alto - 1.65, 0)), Vector3.new(0.3, 0.1, r * 2), Enum.Material.Metal)
	end
	-- Incrustaciones de bronce en el piso: dos anillos alrededor del círculo mágico y ocho rayos entre ellos.
	local centro = c + Vector3.new(0, 0.03, 2)
	for _, radio in { 9.5, 13 } do
		local n = 40
		for i = 1, n do
			local a = (i - 0.5) / n * math.pi * 2
			local p = centro + Vector3.new(math.cos(a) * radio, 0, math.sin(a) * radio)
			local seg = parte(m, BRONCE, CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))), Vector3.new(0.35, 0.06, radio * 2 * math.pi / n + 0.1), Enum.Material.Metal)
			seg.CanCollide = false
		end
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local rayo = parte(m, BRONCE, CFrame.lookAt(centro + dir * 11.25, centro + dir * 20), Vector3.new(0.25, 0.06, 3.5), Enum.Material.Metal)
		rayo.CanCollide = false
	end
	-- Tarima del ventanal contra la pared del fondo (8 de fondo), con dos escalones y barandas de bronce.
	local fondo = -r + 1
	texturar(parte(m, madera, CFrame.new(c + Vector3.new(0, 1, fondo + 4)), Vector3.new(24, 2, 8)), "madera")
	for k, alturaEscalon in { 1.33, 0.66 } do
		texturar(parte(m, madera, CFrame.new(c + Vector3.new(0, alturaEscalon / 2, fondo + 8 + (k - 0.5) * 1.5)), Vector3.new(14, alturaEscalon, 1.5)), "madera")
	end
	for _, x in { -9.5, 9.5 } do
		parte(m, BRONCE, CFrame.new(c + Vector3.new(x, 4.6, fondo + 8)), Vector3.new(5, 0.3, 0.3), Enum.Material.Metal)
		for k = -2, 2, 2 do
			parte(m, BRONCE, CFrame.new(c + Vector3.new(x + k, 3.4, fondo + 8)), Vector3.new(0.22, 2.6, 0.22), Enum.Material.Metal)
		end
	end
	-- Ventanal redondo como el de la foto de referencia: vidrio claro y frío, emplomado fino (rayos desde una roseta
	-- central y anillos), marco grueso oscuro en dos escalones y las bandas curvas gruesas cruzando.
	local RV = 9 -- radio del vidrio
	local cfV = CFrame.new(c + Vector3.new(0, 2 + RV + 1.5, -r + 0.7))
	-- Neón de color medio: más claro, el resplandor tapa las bandas y el emplomado.
	local disco0 = parte(m, "8e9ab2", cfV * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.2, RV * 2, RV * 2), Enum.Material.Neon)
	disco0.Shape = Enum.PartType.Cylinder
	local entra = Instance.new("SurfaceLight")
	entra.Face = Enum.NormalId.Left -- el eje del cilindro mira al salón
	entra.Color, entra.Range, entra.Brightness, entra.Angle = Color3.fromRGB(215, 228, 255), 50, 1.8, 75
	entra.Parent = disco0
	-- Tramo recto delante del vidrio entre dos puntos (x, y) del ventanal, a `z` del vidrio.
	local function tramo(x1, y1, x2, y2, ancho: number, prof: number, z: number, color: string)
		local a = (cfV * CFrame.new(x1, y1, z)).Position
		local b = (cfV * CFrame.new(x2, y2, z)).Position
		-- Largo en Y (a lo largo del tramo), espesor en Z (hacia el salón) y ancho en X, plano contra el vidrio.
		local dir = (b - a).Unit
		local t = parte(m, color, CFrame.fromMatrix((a + b) / 2, dir:Cross(cfV.LookVector).Unit, dir), Vector3.new(ancho, (b - a).Magnitude + ancho * 0.3, prof), Enum.Material.Metal)
		t.CanCollide = false
	end
	-- Arco (centro cx, cy y radio rad) recortado dentro del radio `recorte`.
	local function arco(cx, cy, rad, ancho, prof, z, color, recorte)
		local n = math.max(24, math.floor(rad * 8))
		local px, py
		for i = 0, n do
			local a = i / n * math.pi * 2
			local x, y = cx + math.cos(a) * rad, cy + math.sin(a) * rad
			local dentro = not recorte or x * x + y * y < recorte * recorte
			if dentro and px then
				tramo(px, py, x, y, ancho, prof, z, color)
			end
			if dentro then
				px, py = x, y
			else
				px, py = nil, nil
			end
		end
	end
	local PLOMO, BANDA, MARCO = "2c3550", "121628", "0f121c"
	-- Emplomado fino: 24 rayos desde la roseta, anillos y la roseta del centro.
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		tramo(math.cos(a) * 2.2, math.sin(a) * 2.2, math.cos(a) * RV, math.sin(a) * RV, 0.08, 0.08, 0.25, PLOMO)
	end
	for _, rr in { 0.9, 1.5, 2.2, 4.6, 7 } do
		arco(0, 0, rr, 0.08, 0.08, 0.25, PLOMO)
	end
	-- Bandas gruesas: cuatro arcos de círculos corridos que se cruzan en el centro.
	for _, ang in { 40, 140, 220, 320 } do
		local a = math.rad(ang)
		arco(math.cos(a) * 10, math.sin(a) * 10, 11, 1.25, 0.6, 0.9, BANDA, RV)
	end
	-- Marco grueso y oscuro en dos escalones.
	arco(0, 0, RV + 0.6, 1.3, 0.9, 0.5, MARCO)
	arco(0, 0, RV + 1.9, 1.5, 0.5, 0.3, MARCO)
	-- Pared del frente (la de la puerta, a la espalda al entrar): friso de madera con paneles, dos ventanales altos
	-- con arco a los costados de la puerta, ventana redonda con el sello encima, apliques y cuadros.
	local zf = r - 0.6 -- cara interior de la pared del frente
	parte(m, madera, CFrame.new(c + Vector3.new(0, 1.5, zf - 0.2)), Vector3.new(r * 2, 3, 0.4), Enum.Material.Wood)
	for x = -r + 3, r - 3, 4 do
		if math.abs(x) > 4.5 then
			parte(m, "3a2619", CFrame.new(c + Vector3.new(x, 1.5, zf - 0.45)), Vector3.new(3, 2, 0.15), Enum.Material.Wood)
		end
	end
	local function ventanaArco(x: number)
		local ancho, base, alto0 = 5, 4, 10 -- rectángulo de 4 a 14 y medio círculo arriba
		local cfW = CFrame.new(c + Vector3.new(x, 0, zf - 0.05))
		local vidrio = parte(m, "9a8c70", cfW * CFrame.new(0, base + alto0 / 2, 0), Vector3.new(ancho, alto0, 0.15), Enum.Material.Neon)
		local arcoV = parte(m, "9a8c70", cfW * CFrame.new(0, base + alto0, 0) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.15, ancho, ancho), Enum.Material.Neon)
		arcoV.Shape = Enum.PartType.Cylinder
		local luzV = Instance.new("SurfaceLight")
		luzV.Face = Enum.NormalId.Front -- hacia el salón (−Z)
		luzV.Color, luzV.Range, luzV.Brightness, luzV.Angle = Color3.fromRGB(255, 225, 180), 22, 0.9, 80
		luzV.Parent = vidrio
		-- Marco de madera oscura, parante central y travesaños de bronce, alféizar.
		for _, lado in { -1, 1 } do
			parte(m, madera, cfW * CFrame.new(lado * (ancho / 2 + 0.3), base + alto0 / 2, -0.25), Vector3.new(0.6, alto0, 0.5), Enum.Material.Wood)
		end
		parte(m, BRONCE, cfW * CFrame.new(0, base + (alto0 + ancho / 2) / 2, -0.15), Vector3.new(0.18, alto0 + ancho / 2, 0.15), Enum.Material.Metal)
		for y = base + 2.5, base + alto0, 2.5 do
			parte(m, BRONCE, cfW * CFrame.new(0, y, -0.15), Vector3.new(ancho, 0.15, 0.15), Enum.Material.Metal)
		end
		parte(m, madera, cfW * CFrame.new(0, base - 0.25, -0.5), Vector3.new(ancho + 1.6, 0.5, 1.1), Enum.Material.Wood)
		-- Arco del marco: tramos sobre el medio círculo.
		for i = 0, 11 do
			local a1, a2 = i / 12 * math.pi, (i + 1) / 12 * math.pi
			local p1 = (cfW * CFrame.new(math.cos(a1) * (ancho / 2 + 0.3), base + alto0 + math.sin(a1) * (ancho / 2 + 0.3), -0.25)).Position
			local p2 = (cfW * CFrame.new(math.cos(a2) * (ancho / 2 + 0.3), base + alto0 + math.sin(a2) * (ancho / 2 + 0.3), -0.25)).Position
			parte(m, madera, CFrame.lookAt((p1 + p2) / 2, p2), Vector3.new(0.6, 0.5, (p2 - p1).Magnitude + 0.2), Enum.Material.Wood)
		end
	end
	ventanaArco(-9.5)
	ventanaArco(9.5)
	-- Ventana redonda con el sello sobre la puerta.
	local oculo = parte(m, "c8a46a", CFrame.new(c + Vector3.new(0, 15.5, zf - 0.05)) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.15, 4.4, 4.4), Enum.Material.Neon)
	oculo.Shape = Enum.PartType.Cylinder
	local selloO = Instance.new("Decal")
	selloO.Texture = "rbxassetid://" .. SELLO
	selloO.Color3 = Color3.fromRGB(90, 50, 20)
	selloO.Face = Enum.NormalId.Right
	selloO.Parent = oculo
	for i = 0, 23 do
		local a1, a2 = i / 24 * math.pi * 2, (i + 1) / 24 * math.pi * 2
		local p1 = c + Vector3.new(math.cos(a1) * 2.5, 15.5 + math.sin(a1) * 2.5, zf - 0.3)
		local p2 = c + Vector3.new(math.cos(a2) * 2.5, 15.5 + math.sin(a2) * 2.5, zf - 0.3)
		parte(m, BRONCE, CFrame.lookAt((p1 + p2) / 2, p2), Vector3.new(0.45, 0.45, (p2 - p1).Magnitude + 0.1), Enum.Material.Metal)
	end
	-- Apliques a los lados de la puerta y cuadros en las esquinas.
	for _, x in { -4.8, 4.8 } do
		local base = c + Vector3.new(x, 7.5, zf - 0.5)
		parte(m, BRONCE, CFrame.new(base), Vector3.new(0.6, 1.2, 0.6), Enum.Material.Metal)
		local foco = parte(m, "ffd49a", CFrame.new(base + Vector3.new(0, 1, 0)), Vector3.new(0.8, 0.8, 0.8), Enum.Material.Neon)
		foco.Shape = Enum.PartType.Ball
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 200, 140), 14, 1
		l.Parent = foco
	end
	local cuadro = plantilla("int_cuadro")
	if cuadro then
		for _, x in { -17.5, 17.5 } do
			local q = clonar(cuadro, "Y", 5)
			q:PivotTo(CFrame.new(c + Vector3.new(x, 9, zf - 0.3)) * CFrame.Angles(0, math.pi, 0))
			q.Parent = m
		end
	end
	local haz = parte(m, "ffffff", cfV * CFrame.new(0, -4, 9), Vector3.new(16, 14, 16))
	haz.Transparency, haz.CanCollide, haz.CanQuery, haz.CanTouch = 1, false, false, false
	local motas = Instance.new("ParticleEmitter")
	motas.Color = ColorSequence.new(Color3.fromRGB(205, 220, 255))
	motas.LightEmission = 0.8
	motas.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) })
	motas.Size = NumberSequence.new(0.15)
	motas.Lifetime = NumberRange.new(5, 8)
	motas.Rate = 45
	motas.Speed = NumberRange.new(0.2, 0.5)
	motas.SpreadAngle = Vector2.new(180, 180)
	motas.Parent = haz
end

-- Sala cerrada de un interior: piso, paredes con columnas, techo, luces, polvo flotando, muebles, personajes y la
-- puerta de salida (pared +Z); después, los extras de cada lugar (balcón, círculo, ventanal, portal, logo).
local function construirInterior(padre, id: string, datos)
	local m = Instance.new("Model")
	m.Name = "Interior_" .. id
	local c, r, alto = datos.pos, datos.radio + 2, datos.alto
	local colorPared, luz, acento = Color3.fromHex(datos.pared), Color3.fromHex(datos.luz), Color3.fromHex(datos.acento)
	local piso = parte(m, "ffffff", CFrame.new(c - Vector3.new(0, 0.5, 0)), Vector3.new(r * 2, 1, r * 2))
	texturar(piso, datos.piso)
	if datos.estilo == "sanctum" then
		piso.Reflectance = 0.18 -- piso lustrado
	end
	parte(m, colorPared, CFrame.new(c + Vector3.new(0, alto + 0.5, 0)), Vector3.new(r * 2, 1, r * 2), datos.material)
	for _, d in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
		local tam = if d.X ~= 0 then Vector3.new(1, alto, r * 2) else Vector3.new(r * 2, alto, 1)
		local pared = parte(m, colorPared, CFrame.new(c + d * r + Vector3.new(0, alto / 2, 0)), tam, datos.material)
		if datos.ventanal and d.X < 0 then
			-- Ventanal a la ciudad en la pared −X (del otro lado no hay nada: el otro interior queda hacia +X).
			pared.Material, pared.Color, pared.Transparency = Enum.Material.Glass, Color3.fromRGB(170, 210, 240), 0.55
		end
		local tangente = Vector3.new(math.abs(d.Z), 0, math.abs(d.X))
		-- Zócalo de luz al pie y columnas cada 12 studs.
		parte(m, luz, CFrame.new(c + d * (r - 0.6) + Vector3.new(0, 0.2, 0)), if d.X ~= 0 then Vector3.new(0.3, 0.3, r * 2) else Vector3.new(r * 2, 0.3, 0.3), Enum.Material.Neon)
		for k = -r + 6, r - 6, 12 do
			if datos.estilo == "sanctum" and d.Z < 0 and math.abs(k) < 13 then
				continue -- el ventanal del Sanctum ocupa el centro de la pared del fondo
			end
			parte(m, datos.columna, CFrame.new(c + d * (r - 0.9) + tangente * k + Vector3.new(0, alto / 2, 0)), Vector3.new(1.6, alto, 1.6), datos.material)
		end
	end
	-- Focos: cálidos en el centro, del color de acento en las esquinas.
	for i, esquina in { Vector3.new(0, 0, 0), Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
		local color = if i == 1 then luz else acento
		local foco = parte(m, color, CFrame.new(c + esquina * (r * 0.55) + Vector3.new(0, alto - 0.6, 0)), Vector3.new(2.4, 0.4, 2.4), Enum.Material.Neon)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = color, 36, (if i == 1 then 2 else 1.4) * datos.brillo
		l.Parent = foco
	end
	-- Polvo flotando en todo el salón.
	local aire = parte(m, "ffffff", CFrame.new(c + Vector3.new(0, alto / 2, 0)), Vector3.new(r * 1.8, alto * 0.8, r * 1.8))
	aire.Transparency, aire.CanCollide, aire.CanQuery, aire.CanTouch = 1, false, false, false
	local polvo = Instance.new("ParticleEmitter")
	polvo.Color = ColorSequence.new(luz)
	polvo.LightEmission = 0.6
	polvo.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 1) })
	polvo.Size = NumberSequence.new(0.12)
	polvo.Lifetime = NumberRange.new(6, 10)
	polvo.Rate = 25
	polvo.Speed = NumberRange.new(0.2, 0.6)
	polvo.SpreadAngle = Vector2.new(180, 180)
	polvo.Parent = aire

	local function poner(nombre: string, x: number, z: number, altoModelo: number, giro: number, y: number?): Model?
		local pl = plantilla(nombre)
		if not pl then
			return nil
		end
		local mod = clonar(pl, "Y", altoModelo)
		mod:PivotTo(CFrame.new(c + Vector3.new(x, (y or 0) + mod:GetExtentsSize().Y / 2, z)) * CFrame.Angles(0, math.rad(giro), 0))
		mod.Parent = m
		return mod
	end
	for _, mu in datos.muebles do
		-- Los que van contra una pared se apoyan en ella (x o z = ±radio).
		local x = if math.abs(mu[2]) >= datos.radio then math.sign(mu[2]) * (r - 1.6) else mu[2]
		local z = if math.abs(mu[3]) >= datos.radio then math.sign(mu[3]) * (r - 1.6) else mu[3]
		poner(mu[1], x, z, mu[4], mu[5], mu[6])
	end
	for _, f in datos.flotantes do
		local libro = poner(f[1], f[2], f[3], 1.2, (f[2] * 37) % 360, f[4])
		local raiz = libro and libro:FindFirstChildWhichIsA("BasePart", true)
		if raiz then
			local brillo = Instance.new("ParticleEmitter")
			brillo.Color = ColorSequence.new(luz)
			brillo.LightEmission = 1
			brillo.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
			brillo.Lifetime = NumberRange.new(1, 2)
			brillo.Rate = 6
			brillo.Speed = NumberRange.new(0.3, 0.8)
			brillo.Parent = raiz
		end
	end
	for _, g in datos.colgantes do
		local lampara = poner(g[1], g[2], g[3], g[4], 0, alto - g[4] - 0.5)
		local raiz = lampara and lampara:FindFirstChildWhichIsA("BasePart", true)
		if raiz then
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = luz, 40, 2.2
			l.Parent = raiz
		end
	end
	for _, p in datos.personajes do
		-- De frente a la entrada (+Z).
		encargado(m, p[1], CFrame.lookAt(c + Vector3.new(p[2], 0, p[3]), c + Vector3.new(p[2], 0, p[3] + 10)))
	end

	if datos.sello then
		-- Ventana redonda del Sanctum con el sello de Strange, en la pared del fondo, sobre el balcón.
		local ventana = parte(m, "ffd28a", CFrame.new(c + Vector3.new(0, alto * 0.7, -r + 0.6)) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.2, 12, 12), Enum.Material.Neon)
		ventana.Shape = Enum.PartType.Cylinder
		local sello = Instance.new("Decal")
		sello.Texture = "rbxassetid://" .. SELLO
		sello.Face = Enum.NormalId.Right
		sello.Parent = ventana
	end
	if datos.circulo then
		-- Círculo mágico girando en el piso (lo gira Hub.animar como el sello del portal) con chispas.
		local disco0 = parte(m, "ffffff", CFrame.new(c + Vector3.new(0, 0.06, 2)), Vector3.new(14, 0.1, 14))
		disco0.Transparency, disco0.CanCollide, disco0.CanQuery, disco0.CanTouch = 1, false, false, false
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Top
		gui.LightInfluence = 0
		gui.Brightness = 2
		gui.PixelsPerStud = 30
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = "rbxassetid://" .. SELLO
		img.ImageColor3 = Color3.fromHex("ff9a2e")
		img.Parent = gui
		gui.Parent = disco0
		table.insert(Hub.sellos, img)
		local chispas = Instance.new("ParticleEmitter")
		chispas.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60))
		chispas.LightEmission = 1
		chispas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		chispas.Lifetime = NumberRange.new(1, 2)
		chispas.Rate = 30
		chispas.Speed = NumberRange.new(1, 3)
		chispas.EmissionDirection = Enum.NormalId.Top
		chispas.SpreadAngle = Vector2.new(25, 25)
		chispas.Parent = disco0
	end
	if datos.balcon then
		-- Balcón de madera a 12 studs por las paredes −X, +X y −Z, con barandas, y escalera por la pared +X.
		local y0, ancho = 12, 6
		local madera = Color3.fromRGB(92, 58, 34)
		for _, tramo in {
			{ Vector3.new(-r + ancho / 2, 0, 0), Vector3.new(ancho, 0.8, r * 2), Vector3.new(-r + ancho, 0, 0), Vector3.new(0.4, 3, r * 2 - ancho * 2) },
			{ Vector3.new(r - ancho / 2, 0, -r / 2), Vector3.new(ancho, 0.8, r), Vector3.new(r - ancho, 0, -r / 2 - 3), Vector3.new(0.4, 3, r - ancho - 6) },
		} do
			-- (Sin balcón en la pared del fondo: ahí va el ventanal.)
			texturar(parte(m, madera, CFrame.new(c + tramo[1] + Vector3.new(0, y0, 0)), tramo[2]), "madera")
			-- Baranda de bronce: pasamanos y postes cada 3 studs.
			parte(m, BRONCE, CFrame.new(c + tramo[3] + Vector3.new(0, y0 + 3.2, 0)), Vector3.new(math.max(tramo[4].X, 0.35), 0.35, math.max(tramo[4].Z, 0.35)), Enum.Material.Metal)
			local largo = math.max(tramo[4].X, tramo[4].Z)
			local eje = if tramo[4].X > tramo[4].Z then Vector3.new(1, 0, 0) else Vector3.new(0, 0, 1)
			for k = -largo / 2, largo / 2, 3 do
				parte(m, BRONCE, CFrame.new(c + tramo[3] + eje * k + Vector3.new(0, y0 + 1.8, 0)), Vector3.new(0.25, 2.8, 0.25), Enum.Material.Metal)
			end
		end
		-- Escalera contra la pared +X: sube desde cerca de la puerta hasta el balcón (12 escalones de 1 stud).
		local paso = (r - 4) / 12
		for k = 1, 12 do
			local z = (r - 4) - (k - 0.5) * paso
			texturar(parte(m, madera, CFrame.new(c + Vector3.new(r - 3, k - 0.5, z)), Vector3.new(5, 1, paso)), "madera")
		end
	end
	if datos.ventanal then
		-- Rascacielos del otro lado del vidrio (pared −X), bajando hacia la ciudad.
		local horizonte = plantilla("int_horizonte")
		if horizonte then
			-- El modelo es largo en X: a lo largo del ventanal (eje Z) y bajado para ver los pisos altos.
			local h = clonar(horizonte, "X", r * 3)
			h:PivotTo(CFrame.new(c + Vector3.new(-r - 40, -20, 0)) * CFrame.Angles(0, math.rad(90), 0))
			h.Parent = m
		end
	end
	if datos.zonaNegativa then
		-- Portal a la Zona Negativa en la pared +X: marco generado y remolino oscuro con partículas hacia el salón.
		local marco = plantilla("int_portal")
		local cf = CFrame.new(c + Vector3.new(r - 1.6, 8, 0)) * CFrame.Angles(0, math.rad(-90), 0)
		if marco then
			local x = clonar(marco, "Y", 14)
			x:PivotTo(cf)
			x.Parent = m
		end
		local remolino = parte(m, "2a0f4a", cf * CFrame.Angles(0, math.rad(90), 0), Vector3.new(0.3, 10, 10), Enum.Material.Neon)
		remolino.Shape = Enum.PartType.Cylinder
		remolino.CanCollide = false
		local vacio = Instance.new("ParticleEmitter")
		vacio.Color = ColorSequence.new(Color3.fromRGB(150, 70, 255), Color3.fromRGB(20, 0, 40))
		vacio.LightEmission = 0.8
		vacio.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
		vacio.Lifetime = NumberRange.new(1, 2)
		vacio.Rate = 40
		vacio.Speed = NumberRange.new(2, 4)
		vacio.RotSpeed = NumberRange.new(-180, 180)
		vacio.EmissionDirection = Enum.NormalId.Left -- el eje del disco apunta a la pared; Left es hacia el salón
		vacio.Parent = remolino
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(150, 70, 255), 24, 2
		l.Parent = remolino
	end
	if datos.logo then
		-- El «4» de los Cuatro Fantásticos en el piso, en el centro del laboratorio: círculo azul con el 4 blanco.
		local placa = parte(m, "ffffff", CFrame.new(c + Vector3.new(0, 0.03, 8)) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(10, 0.05, 10)) -- derecho visto desde la entrada
		placa.Transparency, placa.CanCollide, placa.CanQuery, placa.CanTouch = 1, false, false, false
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Top
		gui.LightInfluence = 0
		-- Lienzo de ~100 px después de agrandar el lobby (ScaleTo divide PixelsPerStud): TextScaled no pasa de 100 px
		-- y el 4 tiene que llenar el círculo.
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 10
		local circulo = Instance.new("Frame")
		circulo.Size = UDim2.fromScale(1, 1)
		circulo.BackgroundColor3 = Color3.fromRGB(28, 79, 156)
		local esquina = Instance.new("UICorner")
		esquina.CornerRadius = UDim.new(0.5, 0)
		esquina.Parent = circulo
		local borde = Instance.new("UIStroke")
		borde.Color, borde.Thickness = Color3.new(1, 1, 1), 3
		borde.Parent = circulo
		circulo.Parent = gui
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(0.8, 0.8)
		t.Position = UDim2.fromScale(0.1, 0.1)
		t.Font = Enum.Font.GothamBlack
		t.TextScaled = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Text = "4"
		t.Parent = circulo
		gui.Parent = placa
		-- Pantallas gigantes en la pared del fondo.
		for _, x in { -9, 9 } do
			local pantalla = parte(m, "4fa3ff", CFrame.new(c + Vector3.new(x, 13, -r + 0.7)), Vector3.new(12, 6, 0.2), Enum.Material.Neon)
			pantalla.Transparency = 0.15
		end
	end
	if datos.estilo == "sanctum" then
		extrasSanctum(m, c, r, alto, datos)
	end
	-- Entrada: se aparece de espaldas a la puerta de salida, mirando al fondo (la estación).
	local salida = CFrame.lookAt(c + Vector3.new(0, 0, r - 0.6), c)
	marcador(m, "Llegada", CFrame.lookAt(c + Vector3.new(0, 0, r - 6), c))
	puerta(m, salida, luz, "Salir", datos.nombre, function()
		return Hub.salidas[id]
	end, datos.puertaModelo)
	m.Parent = padre
end

Hub.llegadas, Hub.salidas = {}, {} -- [interior] = marcador adentro / afuera de la puerta del edificio

function Hub.construir(alUsar: (Player, string) -> ())
	local viejo = workspace:FindFirstChild("Hub")
	if viejo then
		viejo:Destroy()
	end
	-- Las islas flotan: sin piso debajo (los mapas de batalla tienen sus propias baldosas).
	local piso = workspace:FindFirstChild("Baseplate")
	if piso then
		piso:Destroy()
	end
	local hub = Instance.new("Model")
	hub.Name = "Hub"
	Hub.sellos = {}
	ambientar()

	for _, datos in ISLAS do
		isla(hub, datos)
	end
	table.clear(ocupado)
	local c = ISLAS.central
	-- Salidas de los puentes y aparición: sin decorado encima.
	for _, otra in { ISLAS.asgard, ISLAS.wakanda, ISLAS.nuevaYork, ISLAS.baxter } do
		ocupar(borde(c, otra), 9)
		ocupar(borde(otra, c), 9)
	end
	ocupar(borde(ISLAS.sanctum, c), 9)
	ocupar(c.pos + Vector3.new(0, 0, 14), 8)
	puente(hub, borde(c, ISLAS.asgard), borde(ISLAS.asgard, c), "bifrost")
	puente(hub, borde(c, ISLAS.wakanda), borde(ISLAS.wakanda, c), "selva")
	puente(hub, borde(c, ISLAS.nuevaYork), borde(ISLAS.nuevaYork, c), "telarana")
	puente(hub, borde(c, ISLAS.baxter), borde(ISLAS.baxter, c), "baxter")

	-- Portal al Sanctum y de vuelta: cada uno deja al jugador frente al otro.
	local s = ISLAS.sanctum
	local ida = enIsla(c, 52, 33)
	local vuelta = borde(s, c)
	local function frente(p: Vector3, desde: Vector3)
		local d = ((desde - p) * Vector3.new(1, 0, 1)).Unit
		local llegada = p + d * 5 + Vector3.new(0, 3, 0)
		return CFrame.lookAt(llegada, llegada + d)
	end
	portal(hub, ida, c.pos, frente(vuelta, s.pos))
	portal(hub, vuelta, s.pos, frente(ida, c.pos))
	letrero(hub, ida + Vector3.new(0, 11.5, 0), "SANCTUM SANCTORUM", "Portal", Color3.fromHex("ff9a2e"), 12)

	for _, h in HITOS do
		hito(hub, h)
	end
	for id, datos in INTERIORES do
		construirInterior(hub, id, datos)
	end
	for _, e in Hub.ESTACIONES do
		estacion(hub, e, alUsar)
	end
	salas(hub, "baxter_interior", "infinite", 270, alUsar)
	salas(hub, "sanctum_interior", "story", 270, alUsar)

	letrero(hub, ISLAS.asgard.pos + Vector3.new(0, 34 * ESCALA_EDIFICIOS / ESCALA, -10), "ASGARD", "Invocaciones", Color3.fromHex("ffcf72"), 14)
	letrero(hub, ISLAS.wakanda.pos + Vector3.new(0, 22 * ESCALA_EDIFICIOS / ESCALA, 0), "WAKANDA", "Traits · Grades · Pets", Color3.fromHex("b865ff"), 14)
	letrero(hub, ISLAS.nuevaYork.pos + Vector3.new(0, 26 * ESCALA_EDIFICIOS / ESCALA, 0), "NUEVA YORK", "Raids · Tienda", Color3.fromHex("40c9ff"), 14)
	letrero(hub, ISLAS.baxter.pos + Vector3.new(0, 36 * ESCALA_EDIFICIOS / ESCALA, 0), "TORRE BAXTER", "Modo infinito", Color3.fromHex("6fb5ff"), 14)

	-- Árboles: jardín de la isla central y selva de Wakanda.
	for _, a in { -70, -20, 140, 200 } do
		arbol(hub, enIsla(c, a, 35), "4f9e45", "arbol_jardin", 7)
	end
	for _, a in { 100, 140, 180, 220, 260, 300 } do
		arbol(hub, enIsla(ISLAS.wakanda, a, 25), "2f7a2c", "arbol_selva", 9)
	end

	-- Faroles a cada lado de la salida de los puentes y del portal, plantas en el borde y bancos.
	for _, destino in { ISLAS.asgard, ISLAS.wakanda, ISLAS.nuevaYork, ISLAS.baxter, ida } do
		local d = if typeof(destino) == "Vector3" then destino else destino.pos
		local a = math.deg(math.atan2(d.Z - c.pos.Z, d.X - c.pos.X))
		for _, s in { -11, 11 } do
			local f = adorno(hub, "farol", enIsla(c, a + s, 34), 6, c.pos)
			local base = f and f:FindFirstChildWhichIsA("BasePart", true)
			if base then
				local luz = Instance.new("PointLight")
				luz.Color, luz.Range, luz.Brightness = Color3.fromRGB(255, 226, 170), 16, 1.4
				luz.Parent = base
			end
		end
	end
	for i, a in { -118, -62, -32, 18, 36, 78, 100, 150, 168, 215, 238 } do
		adorno(hub, if i % 3 == 0 then "flores" elseif i % 3 == 1 then "arbusto" else "roca", enIsla(c, a, 37), if i % 3 == 0 then 1.1 elseif i % 3 == 1 then 2.4 else 1.6)
		adorno(hub, "flores", enIsla(c, a + 6, 36), 1)
	end
	for _, a in { 70, 250 } do
		adorno(hub, "banco", enIsla(c, a, 17), 2.2, c.pos + (enIsla(c, a, 17) - c.pos) * 2)
	end
	for i, a in { 90, 130, 170, 210, 250, 290 } do
		adorno(hub, if i % 2 == 0 then "roca" else "arbusto", enIsla(ISLAS.wakanda, a + 20, 22), if i % 2 == 0 then 1.8 else 2.6)
	end

	for id in ISLAS do
		decorarIsla(hub, id)
	end
	cielo(hub)
	-- Chispas mágicas naranjas flotando sobre la isla del Sanctum.
	local s = ISLAS.sanctum
	local nube = parte(hub, "ffffff", CFrame.new(s.pos + Vector3.new(0, 6, 0)), Vector3.new(s.radio * 1.6, 8, s.radio * 1.6))
	nube.Transparency, nube.CanCollide, nube.CanQuery, nube.CanTouch = 1, false, false, false
	local chispas = Instance.new("ParticleEmitter")
	chispas.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 90, 20))
	chispas.LightEmission = 1
	chispas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	chispas.Lifetime = NumberRange.new(2, 4)
	chispas.Rate = 18
	chispas.Speed = NumberRange.new(0.5, 1.5)
	chispas.SpreadAngle = Vector2.new(180, 180)
	chispas.Parent = nube

	-- Aparición al pie de la torre, mirando hacia afuera: las estaciones miran al centro, o sea al jugador.
	local aparicion = Instance.new("SpawnLocation")
	aparicion.Name = "AparicionHub"
	aparicion.Anchored = true
	aparicion.Size = Vector3.new(6, 0.2, 6)
	aparicion.Transparency = 1
	aparicion.CanCollide = false
	aparicion.Neutral = true
	aparicion.Duration = 0
	aparicion.CFrame = CFrame.lookAt(c.pos + Vector3.new(0, 0.1, 10), c.pos + Vector3.new(0, 0.1, 30))
	aparicion.Parent = hub
	Hub.aparicion = aparicion

	-- Agrandar todo y rellenar el pasto de terreno a la medida nueva (borrando el de antes).
	hub.WorldPivot = CFrame.new(PIVOTE)
	hub:ScaleTo(ESCALA)
	for id in INTERIORES do
		local interior = hub:FindFirstChild("Interior_" .. id)
		Hub.llegadas[id] = interior and interior:FindFirstChild("Llegada")
		Hub.salidas[id] = hub:FindFirstChild("Afuera_" .. id, true)
	end
	for _, datos in ISLAS do
		if TEXTURAS[datos.textura].base == Enum.Material.Grass then
			-- Borrar el pasto de una construcción anterior sólo alrededor de esta isla (las arenas quedan lejos).
			local c = PIVOTE + (datos.pos - PIVOTE) * ESCALA
			local lado = datos.radio * ESCALA * 2 + 8
			workspace.Terrain:FillBlock(CFrame.new(c.X, PIVOTE.Y, c.Z), Vector3.new(lado, 40, lado), Enum.Material.Air)
			pastoDeTerreno(datos)
		end
	end

	hub.Parent = workspace
	-- Reposo de los encargados (Shared/Reposo.luau), ya en el workspace para que la animación se replique.
	for _, x in encargados do
		local hum = x.modelo:FindFirstChildOfClass("Humanoid")
		local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
		if animator then
			local anim = Instance.new("Animation")
			anim.AnimationId = Reposo.para(x.id, x.modelo:GetAttribute("Efecto"))
			local ok, pista = pcall(animator.LoadAnimation, animator, anim)
			if ok then
				pista.Looped = true
				pista:Play()
			end
		end
	end
	table.clear(encargados)
	Hub.orbes, Hub.bifrost = {}, {}
	for _, d in hub:GetDescendants() do
		if d.Name == "Orbe" then
			table.insert(Hub.orbes, d)
		elseif d.Name == "Bifrost" then
			table.insert(Hub.bifrost, d)
		end
	end
	return hub
end

-- Punto de llegada del teletransporte del HUD: borde de la isla mirando a su centro; nil si no existe.
function Hub.llegada(nombre: string): CFrame?
	local datos = ISLAS[nombre]
	if not datos then
		return nil
	end
	if nombre == "central" then
		return Hub.aparicion.CFrame + Vector3.new(0, 3, 0)
	end
	-- Posiciones de la tabla llevadas a la medida agrandada.
	local function final(v: Vector3): Vector3
		return PIVOTE + (v - PIVOTE) * ESCALA
	end
	local centro, central = final(datos.pos), final(ISLAS.central.pos)
	local haciaCentral = (central - centro) * Vector3.new(1, 0, 1)
	local p = centro + haciaCentral.Unit * (datos.radio * ESCALA - 6) + Vector3.new(0, 3, 0)
	return CFrame.lookAt(p, Vector3.new(centro.X, p.Y, centro.Z))
end

-- Gira orbes y sellos, corre el arcoíris del Bifrost y devuelve a la aparición a quien cae (llamar en Heartbeat).
local reloj, ultimoBifrost = 0, 0
function Hub.animar(_hub: Model, dt: number)
	reloj += dt
	for _, o in Hub.orbes do
		o.CFrame *= CFrame.Angles(0, dt * 1.5, 0)
	end
	for i, s in Hub.sellos do
		s.Rotation = (reloj * 25 * (if i % 2 == 0 then -1 else 1)) % 360 -- la cara de atrás gira al revés para verse igual
	end
	-- shortcut: el arcoíris se actualiza 10 veces por segundo desde el servidor; pasarlo al cliente si pesa en la red.
	if reloj - ultimoBifrost > 0.1 then
		ultimoBifrost = reloj
		for _, tabla in Hub.bifrost do
			tabla.Color = Color3.fromHSV((tabla:GetAttribute("Indice") / 24 - reloj * 0.15) % 1, 0.75, 1)
		end
	end
	for _, j in Players:GetPlayers() do
		local raiz = j.Character and j.Character:FindFirstChild("HumanoidRootPart")
		if raiz and raiz.Position.Y < -60 then
			j.Character:PivotTo(Hub.aparicion.CFrame + Vector3.new(0, 3, 0))
		end
	end
end

return Hub
