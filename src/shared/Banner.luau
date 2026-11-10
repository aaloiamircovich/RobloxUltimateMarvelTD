-- Banner 1: invocación con gemas y destacados que rotan cada hora (docs/INVOCACIONES.md).
-- Módulo puro: la hora y el azar entran como parámetros para poder probarlo.
local Personajes = require(script.Parent.Personajes)
local Unidades = require(script.Parent.Unidades)

local Banner = {}

Banner.COSTO = 50 -- gemas por tirada
Banner.PROB = { Common = 48, Rare = 30, Epic = 15, Legendary = 6, Mythic = 2, Secret = 1 }
Banner.PROB_DESTACADO = 0.5
Banner.GARANTIA = 4 -- tras 4 comunes seguidos, la siguiente no es común (heroPity del 2D)

-- Número de hora UTC desde la época: igual en todos los servidores.
function Banner.hora(segundos: number): number
	return math.floor(segundos / 3600)
end

-- Destacados de esa hora: 1 estrella (Legendario o Mítico) y 2 apoyos (Épicos), sin repetir.
function Banner.destacados(hora: number): { estrella: string, apoyos: { string } }
	local pozo = Personajes.invocables()
	local azar = Random.new(hora * 7919 + 17)
	local estrellas = table.clone(pozo.Legendary or {})
	for _, id in pozo.Mythic or {} do
		table.insert(estrellas, id)
	end
	local epicos = table.clone(pozo.Epic or {})
	local estrella = estrellas[azar:NextInteger(1, #estrellas)]
	local a = table.remove(epicos, azar:NextInteger(1, #epicos))
	local b = table.remove(epicos, azar:NextInteger(1, #epicos))
	return { estrella = estrella, apoyos = { a, b } }
end

-- Una tirada: rareza por probabilidad (sólo rarezas con personajes) y, si hay destacados de esa
-- rareza, 50 % de que salga uno de ellos. azar(): número en [0, 1).
function Banner.tirar(destacados, garantia: boolean, azar: () -> number): string
	local pozo = Personajes.invocables()
	local total = 0
	for r, p in Banner.PROB do
		if pozo[r] and not (garantia and r == "Common") then
			total += p
		end
	end
	local tiro = azar() * total
	local rareza = "Rare"
	for _, r in Personajes.RAREZAS do
		local p = Banner.PROB[r]
		if pozo[r] and not (garantia and r == "Common") then
			tiro -= p
			if tiro < 0 then
				rareza = r
				break
			end
		end
	end
	local suyos = {}
	for _, id in { destacados.estrella, destacados.apoyos[1], destacados.apoyos[2] } do
		if Personajes.de(id).rarity == rareza then
			table.insert(suyos, id)
		end
	end
	if #suyos > 0 and azar() < Banner.PROB_DESTACADO then
		return suyos[math.floor(azar() * #suyos) + 1]
	end
	local resto = {}
	for _, id in pozo[rareza] do
		if not table.find(suyos, id) then
			table.insert(resto, id)
		end
	end
	if #resto == 0 then
		resto = suyos
	end
	return resto[math.floor(azar() * #resto) + 1]
end

-- Invoca `cantidad` veces (1 o 10). Devuelve la lista de unidades nuevas o (nil, motivo).
function Banner.invocar(perfil, cantidad: number, hora: number, azar: () -> number)
	if cantidad ~= 1 and cantidad ~= 10 then
		return nil, "Cantidad inválida"
	end
	if #perfil.units == 0 then
		return nil, "Elegí tu héroe inicial primero."
	end
	if #perfil.units + cantidad > Unidades.MAX_INVENTARIO then
		return nil, `Inventario lleno ({#perfil.units}/{Unidades.MAX_INVENTARIO}): vendé unidades`
	end
	local costo = Banner.COSTO * cantidad
	if perfil.gems < costo then
		return nil, `Faltan {costo - perfil.gems} gemas`
	end
	perfil.gems -= costo
	local destacados = Banner.destacados(hora)
	local nuevas = {}
	for _ = 1, cantidad do
		local id = Banner.tirar(destacados, perfil.shop.heroPity >= Banner.GARANTIA, azar)
		perfil.shop.heroPity = if Personajes.de(id).rarity == "Common" then perfil.shop.heroPity + 1 else 0
		table.insert(nuevas, Unidades.agregar(perfil, id))
	end
	return nuevas, nil
end

-- Probabilidad (%) de cada rareza y de cada destacado en la próxima tirada.
function Banner.probabilidades(destacados, garantia: boolean): ({ [string]: number }, { [string]: number })
	local pozo = Personajes.invocables()
	local total = 0
	for r, p in Banner.PROB do
		if pozo[r] and not (garantia and r == "Common") then
			total += p
		end
	end
	local porRareza, porDestacado = {}, {}
	for r, p in Banner.PROB do
		if pozo[r] and not (garantia and r == "Common") then
			porRareza[r] = p / total * 100
		end
	end
	local ids = { destacados.estrella, destacados.apoyos[1], destacados.apoyos[2] }
	for _, id in ids do
		local r = Personajes.de(id).rarity
		local mismos = 0
		for _, otro in ids do
			if Personajes.de(otro).rarity == r then
				mismos += 1
			end
		end
		porDestacado[id] = (porRareza[r] or 0) * Banner.PROB_DESTACADO / mismos
	end
	return porRareza, porDestacado
end

return Banner
