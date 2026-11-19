-- Animaciones de reposo por estilo (docs/ANIMACION.md). Generadas con la IA de Roblox (4 s, en bucle).
-- Cada personaje usa el estilo de su base; si no está en la lista, se elige por su efecto de ataque.
local Personajes = require(script.Parent.Personajes)

local Reposo = {}

Reposo.ESTILOS = {
	guerrero = "rbxassetid://114353481797204", -- armas cuerpo a cuerpo
	luchador = "rbxassetid://125007714848025", -- puños
	tirador = "rbxassetid://117206641918258", -- arcos, armas, proyectiles
	mistico = "rbxassetid://100111761064559", -- magia y energía
	bestia = "rbxassetid://72351296771400", -- grandes y fuertes
	pequeno = "rbxassetid://75136570730254", -- animales chicos
	armadura = "rbxassetid://136657500362740", -- trajes robóticos
	comandante = "rbxassetid://140137303306970", -- los que no atacan
	-- De pie con los brazos sueltos (el mismo reposo de los encargados del lobby, 17/11/2026): con «guerrero» la
	-- espada atravesaba la pierna o el cuerpo; uno generado «con la espada al costado» los dejaba agachados.
	espadachin = "rbxassetid://131664289365409",
}

-- Personajes base cuyo estilo no se deduce bien del efecto de ataque.
Reposo.POR_PERSONAJE = {
	-- bestia
	hulk = "bestia", she_hulk = "bestia", devil_dinosaur = "bestia", groot = "bestia", korg = "bestia", venom = "bestia",
	beast = "bestia", mbaku = "bestia", luke_cage = "bestia", drax = "bestia", knull = "bestia",
	-- pequeño
	jeff_the_land_shark = "pequeno", cosmo = "pequeno", rocket_raccoon = "pequeno", howard_the_duck = "pequeno",
	-- armadura
	iron_man = "armadura", war_machine = "armadura", vision = "armadura", nova = "armadura", ant_man = "armadura",
	-- comandante (no atacan)
	nick_fury = "comandante", maria_hill = "comandante", wasp = "comandante", wong = "comandante", profesor_x = "comandante",
	-- guerrero (armas cuerpo a cuerpo)
	thor = "guerrero", odin = "guerrero", blade = "guerrero", magik = "espadachin", angela = "guerrero", valkyrie = "espadachin",
	lady_sif = "espadachin", heimdall = "espadachin", gamora = "guerrero", namor = "guerrero", namora = "guerrero",
	okoye = "guerrero", elektra = "guerrero", psylocke = "guerrero", deadpool = "guerrero", x_23 = "guerrero",
	wolverine = "guerrero", beta_ray_bill = "guerrero", capitan_america = "guerrero", black_panther = "guerrero",
	daredevil = "guerrero", mockingbird = "guerrero", triton = "guerrero", ghost_rider = "guerrero",
}

local POR_EFECTO = { flecha = "tirador", rayo = "mistico", impacto = "luchador" }

-- Reposo propio de los únicos (Míticos, Legendarios, Secreto y exclusivos; fase E). Se completa abajo.
Reposo.PROPIOS = {
	thor = "rbxassetid://91645421383775", -- gira el martillo
	hulk = "rbxassetid://71694707741477", -- respira pesado, aprieta los puños
	doctor_strange = "rbxassetid://87813582694616", -- teje un hechizo flotando
	iron_man = "rbxassetid://112564673063748", -- flota y se mira las palmas
	captain_marvel = "rbxassetid://113690828834249", -- puños brillando
	scarlet_witch = "rbxassetid://119434112358373", -- teje magia con las manos
	vision = "rbxassetid://76329972207817", -- manos atrás, observa
	jean_grey = "rbxassetid://120042833451026", -- flota con la mano en la sien
	storm = "rbxassetid://134499470956311", -- controla el viento
	silver_surfer = "rbxassetid://100216377101166", -- se balancea como en la tabla
	ghost_rider = "rbxassetid://86266986161462", -- rueda los hombros y se truena los nudillos
	nova = "rbxassetid://111247332266427", -- flota con los puños en la cadera
	namor = "rbxassetid://117099864401592", -- tridente clavado, pecho afuera
	iceman = "rbxassetid://117371199746356", -- se sacude la escarcha de los dedos
	black_bolt = "rbxassetid://105183529905334", -- quieto y solemne
	hela = "rbxassetid://103861597425908", -- manos en la cintura, arrogante
	emma_frost = "rbxassetid://107437081054745", -- brazos cruzados
	magneto = "rbxassetid://70747610571370", -- levita con las palmas arriba
	adam_warlock = "rbxassetid://72888120034603", -- flota meditando
	invisible_woman = "rbxassetid://121545958667043", -- sostiene un campo de fuerza
	loki = "rbxassetid://128970891914473", -- apoyado en el cetro, sonríe
	mister_fantastic = "rbxassetid://127733996830269", -- piensa y estira un brazo
	sentry = "rbxassetid://140098140980654", -- flota brillando
	beta_ray_bill = "rbxassetid://110076399327845", -- martillo al hombro
	profesor_x = "rbxassetid://132942982140573", -- dedos en la sien
	odin = "rbxassetid://109698874247969", -- lanza a un costado, mira el campo
	knull = "rbxassetid://92590556324499", -- encorvado, garras
}

-- Festejo al mejorar (fase E, 18/11/2026): uno por estilo, generado con la IA de Roblox (2 s).
Reposo.FESTEJOS = {
	guerrero = "rbxassetid://136379389600498", -- alza el arma
	espadachin = "rbxassetid://136379389600498",
	luchador = "rbxassetid://70487138110685", -- puño en alto
	tirador = "rbxassetid://126977712068983", -- gira el arma y asiente
	mistico = "rbxassetid://133249363775120", -- junta energía y abre los brazos
	bestia = "rbxassetid://85784448050948", -- se golpea el pecho
	pequeno = "rbxassetid://127263117025994", -- saltitos
	armadura = "rbxassetid://106426450847675", -- mira la palma y se carga
	comandante = "rbxassetid://122316045296412", -- saludo militar
}

function Reposo.estilo(heroeId: string, efecto: string?): string
	return Reposo.POR_PERSONAJE[Personajes.base(heroeId)] or POR_EFECTO[efecto or ""] or "luchador"
end

-- Id de la animación de reposo para un personaje (o su evolución) con el efecto de ataque de su modelo.
function Reposo.para(heroeId: string, efecto: string?): string
	return Reposo.PROPIOS[Personajes.base(heroeId)] or Reposo.ESTILOS[Reposo.estilo(heroeId, efecto)]
end

function Reposo.festejo(heroeId: string, efecto: string?): string
	return Reposo.FESTEJOS[Reposo.estilo(heroeId, efecto)]
end

return Reposo
