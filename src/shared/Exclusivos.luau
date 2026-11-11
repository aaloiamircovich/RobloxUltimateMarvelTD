-- Personajes exclusivos (docs/EXCLUSIVOS.md): no salen en los banners. Odin es el premio del nivel 50 del pase y
-- Knull se canjea por 100 fragmentos de raid. heroes.json no se edita: cada uno toma de un personaje del 2D su
-- terreno y perfil de combate, y define sus stats y su habilidad (Kits.alAtacar).
local heroes = require(script.Parent.Data.heroes)

local function crear(base: string, datos)
	local h = table.clone(heroes[base])
	h.visual, h.sprite, h.evolutionId = nil, nil, nil
	for k, v in datos do
		h[k] = v
	end
	h.exclusivo = true
	return h
end

return {
	odin = crear("thor", {
		id = "odin",
		name = "Odin",
		category = "Místico",
		rarity = "Secret",
		cost = 960,
		damage = 98,
		range = 210,
		fireRate = 0.9,
		canSeeStealth = true,
		ability = "GUNGNIR",
		abilityDesc = "Cada 3 ataques, Gungnir suelta un rayo que salta del blanco a hasta 4 enemigos a 140 px, con 70 % de poder.",
		niche = "daño en cadena",
		origen = "pase",
	}),
	knull = crear("venom", {
		id = "knull",
		name = "Knull",
		category = "Cósmico",
		rarity = "Secret",
		cost = 960,
		damage = 90,
		range = 170,
		fireRate = 1.0,
		canSeeStealth = true,
		ability = "REY DEL VACÍO",
		abilityDesc = "Cada 4 ataques, zarcillos de simbionte golpean a hasta 6 enemigos a 100 px del blanco con 60 % de poder y los ralentizan 35 % por 2 s.",
		niche = "control de área",
		origen = "raid",
	}),
}
