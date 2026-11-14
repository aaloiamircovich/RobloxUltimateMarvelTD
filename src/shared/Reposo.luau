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
	thor = "guerrero", odin = "guerrero", blade = "guerrero", magik = "guerrero", angela = "guerrero", valkyrie = "guerrero",
	lady_sif = "guerrero", heimdall = "guerrero", gamora = "guerrero", namor = "guerrero", namora = "guerrero",
	okoye = "guerrero", elektra = "guerrero", psylocke = "guerrero", deadpool = "guerrero", x_23 = "guerrero",
	wolverine = "guerrero", beta_ray_bill = "guerrero", capitan_america = "guerrero", black_panther = "guerrero",
	daredevil = "guerrero", mockingbird = "guerrero", triton = "guerrero", ghost_rider = "guerrero",
}

local POR_EFECTO = { flecha = "tirador", rayo = "mistico", impacto = "luchador" }

-- Id de la animación de reposo para un personaje (o su evolución) con el efecto de ataque de su modelo.
function Reposo.para(heroeId: string, efecto: string?): string
	local estilo = Reposo.POR_PERSONAJE[Personajes.base(heroeId)] or POR_EFECTO[efecto or ""] or "luchador"
	return Reposo.ESTILOS[estilo]
end

return Reposo
