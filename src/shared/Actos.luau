-- Historia por actos (docs/PARTIDA.md): 5 actos de 10 oleadas por mapa, jefe en la 10, desbloqueos,
-- Pesadilla y premios. Módulo puro sobre el perfil (perfil.acts).
local Actos = {}

Actos.POR_MAPA = 5
Actos.OLEADAS = 10
Actos.MAPAS = { "level_1", "level_2", "level_3", "level_4" } -- orden de desbloqueo (Mapa.JUGABLES)
Actos.GEMAS_PRIMERA = 50 -- × número de acto
Actos.GEMAS_REPETIR = 10
Actos.NUCLEOS_PRIMERA = 1
Actos.PESADILLA = { vida = 1.5, velocidad = 1.1, premios = 2 }

-- Progreso de un mapa: { normal = último acto ganado (0–5), pesadilla = último acto ganado en Pesadilla }.
function Actos.progreso(perfil, mapaId: string)
	return perfil.acts[mapaId] or { normal = 0, pesadilla = 0 }
end

function Actos.mapaAbierto(perfil, mapaId: string): boolean
	local i = table.find(Actos.MAPAS, mapaId)
	if not i then
		return false
	end
	return i == 1 or Actos.progreso(perfil, Actos.MAPAS[i - 1]).normal >= Actos.POR_MAPA
end

-- acto: 1–5 o "infinito". Devuelve nil si se puede jugar, o el motivo.
function Actos.puedeJugar(perfil, mapaId: string, acto, pesadilla: boolean?): string?
	if not Actos.mapaAbierto(perfil, mapaId) then
		return "Ganá el acto 5 del mapa anterior para abrir este mapa"
	end
	local p = Actos.progreso(perfil, mapaId)
	if acto == "infinito" then
		return if p.normal >= Actos.POR_MAPA then nil else "Ganá el acto 5 para abrir el Infinito de este mapa"
	end
	if type(acto) ~= "number" or acto ~= math.floor(acto) or acto < 1 or acto > Actos.POR_MAPA then
		return "Acto inválido"
	end
	if acto > p.normal + 1 then
		return `Ganá el acto {acto - 1} primero`
	end
	if pesadilla and acto > p.normal then
		return "La Pesadilla se abre al ganar el acto en normal"
	end
	return nil
end

-- Oleada del 2D que corresponde a la oleada `n` (1–10) del acto: el acto 2 juega la 11–20, etc.
function Actos.oleada2D(acto: number, n: number): number
	return (acto - 1) * Actos.OLEADAS + n
end

-- Premios de ganar el acto (sin aplicarlos): { gemas, nucleos, primera }.
function Actos.premios(perfil, mapaId: string, acto: number, pesadilla: boolean?)
	local p = Actos.progreso(perfil, mapaId)
	local primera = acto > (if pesadilla then p.pesadilla else p.normal)
	local mult = if pesadilla then Actos.PESADILLA.premios else 1
	if primera then
		return { gemas = Actos.GEMAS_PRIMERA * acto * mult, nucleos = Actos.NUCLEOS_PRIMERA * mult, primera = true }
	end
	return { gemas = Actos.GEMAS_REPETIR * mult, nucleos = 0, primera = false }
end

-- Aplica la victoria: premios al perfil y progreso. Devuelve los premios dados.
function Actos.ganar(perfil, mapaId: string, acto: number, pesadilla: boolean?)
	local premio = Actos.premios(perfil, mapaId, acto, pesadilla)
	local p = table.clone(Actos.progreso(perfil, mapaId))
	if pesadilla then
		p.pesadilla = math.max(p.pesadilla, acto)
	else
		p.normal = math.max(p.normal, acto)
	end
	perfil.acts[mapaId] = p
	perfil.gems += premio.gemas
	perfil.cores += premio.nucleos
	return premio
end

return Actos
