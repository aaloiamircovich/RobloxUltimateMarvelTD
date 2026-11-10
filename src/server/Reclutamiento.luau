-- Colección de héroes: elección inicial, reclutamiento y escuadrón.
-- Portado de ShopSystem.recruitHero, ProgressionManager (startProfile, unlockHero, setActiveTeam)
-- y StarterSelection del 2D, y de progression.js del 3D (recruitmentOdds). Módulo puro sobre el perfil.
local Reclutamiento = {}

Reclutamiento.INICIALES = { "black_widow", "hawkeye", "korg" } -- RECOMMENDED_STARTER_IDS
Reclutamiento.PESOS = { Common = 48, Rare = 30, Epic = 15, Legendary = 6, Mythic = 2, Secret = 1 }
Reclutamiento.MAX_EQUIPO = 6
local COSTO_BASE, CRECIMIENTO = 500, 1.12

function Reclutamiento.costo(perfil): number
	return math.max(COSTO_BASE, math.ceil(tonumber(perfil.shop.heroBoxCost) or COSTO_BASE))
end

local function tiene(perfil, id)
	return table.find(perfil.unlockedHeroIds, id) ~= nil
end

-- Héroes que todavía pueden salir, ordenados por id para que el sorteo sea reproducible con la misma semilla.
local function pozo(perfil, heroes)
	local p = {}
	for id, h in heroes do
		if not tiene(perfil, id) then
			table.insert(p, h)
		end
	end
	table.sort(p, function(a, b)
		return a.id < b.id
	end)
	local garantizado = {}
	for _, h in p do
		if h.rarity ~= "Common" then
			table.insert(garantizado, h)
		end
	end
	local usaGarantia = perfil.shop.heroPity >= 4 and #garantizado > 0
	return if usaGarantia then garantizado else p, usaGarantia
end

function Reclutamiento.elegirInicial(perfil, id: string): string?
	if #perfil.unlockedHeroIds > 0 then
		return "Ya elegiste tu héroe inicial"
	end
	if not table.find(Reclutamiento.INICIALES, id) then
		return "Ese no es un héroe inicial"
	end
	perfil.unlockedHeroIds = { id }
	perfil.activeTeamIds = { id }
	return nil
end

-- azar(): número en [0, 1). Devuelve (héroe, garantizado) o (nil, motivo).
function Reclutamiento.reclutar(perfil, heroes, azar: () -> number)
	if #perfil.unlockedHeroIds == 0 then
		return nil, "Elegí tu héroe inicial primero."
	end
	local candidatos, garantizado = pozo(perfil, heroes)
	if #candidatos == 0 then
		return nil, "Ya tenés todos los héroes"
	end
	local costo = Reclutamiento.costo(perfil)
	if perfil.credits < costo then
		return nil, "Créditos insuficientes"
	end
	-- Sorteo ponderado por rareza, equivalente a repetir cada héroe según su peso.
	local total = 0
	for _, h in candidatos do
		total += Reclutamiento.PESOS[h.rarity] or Reclutamiento.PESOS.Rare
	end
	local tiro = azar() * total
	local elegido = candidatos[#candidatos]
	for _, h in candidatos do
		tiro -= Reclutamiento.PESOS[h.rarity] or Reclutamiento.PESOS.Rare
		if tiro < 0 then
			elegido = h
			break
		end
	end
	perfil.credits -= costo
	table.insert(perfil.unlockedHeroIds, elegido.id)
	if #perfil.activeTeamIds < Reclutamiento.MAX_EQUIPO then
		table.insert(perfil.activeTeamIds, elegido.id)
	end
	perfil.shop.heroPity = if elegido.rarity == "Common" then perfil.shop.heroPity + 1 else 0
	perfil.shop.heroBoxCost = math.ceil(costo * CRECIMIENTO)
	return elegido, garantizado
end

-- Probabilidad (%) por rareza del próximo reclutamiento.
function Reclutamiento.probabilidades(perfil, heroes): { [string]: number }
	local candidatos = pozo(perfil, heroes)
	local pesos, total = {}, 0
	for _, h in candidatos do
		local w = Reclutamiento.PESOS[h.rarity] or Reclutamiento.PESOS.Rare
		pesos[h.rarity] = (pesos[h.rarity] or 0) + w
		total += w
	end
	for r, w in pesos do
		pesos[r] = w / total * 100
	end
	return pesos
end

-- setActiveTeam: sin repetidos, sólo desbloqueados, de 1 a 6.
function Reclutamiento.fijarEquipo(perfil, ids): string?
	local equipo = {}
	for _, id in ids do
		if type(id) == "string" and tiene(perfil, id) and not table.find(equipo, id) then
			table.insert(equipo, id)
		end
	end
	if #equipo == 0 then
		return "El escuadrón necesita al menos un héroe"
	end
	if #equipo > Reclutamiento.MAX_EQUIPO then
		return `El escuadrón admite hasta {Reclutamiento.MAX_EQUIPO} héroes`
	end
	perfil.activeTeamIds = equipo
	return nil
end

return Reclutamiento
