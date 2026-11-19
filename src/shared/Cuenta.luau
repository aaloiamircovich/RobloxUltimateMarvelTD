-- Nivel de cuenta del jugador: XP por jugar y casillas del escuadrón que desbloquea
-- (docs/INVOCACIONES.md). Módulo puro sobre el perfil.
local Cuenta = {}

Cuenta.XP_OLEADA = 5 -- oleada de Historia superada
Cuenta.XP_MAPA = 50 -- mapa ganado
Cuenta.XP_OLEADA_INFINITO = 2
Cuenta.CASILLAS = { { nivel = 1, casillas = 3 }, { nivel = 10, casillas = 4 }, { nivel = 25, casillas = 5 }, { nivel = 40, casillas = 6 } }

-- XP para pasar del nivel n al n+1.
function Cuenta.xpParaSubir(n: number): number
	return 100 * n
end

-- Casillas de escuadrón abiertas con ese nivel.
function Cuenta.casillas(nivel: number): number
	local c = 3
	for _, p in Cuenta.CASILLAS do
		if nivel >= p.nivel then
			c = p.casillas
		end
	end
	return c
end

-- Nivel que abre la casilla número `i` (nil si ya está abierta desde el inicio).
function Cuenta.nivelCasilla(i: number): number?
	for _, p in Cuenta.CASILLAS do
		if p.casillas == i and p.nivel > 1 then
			return p.nivel
		end
	end
	return nil
end

-- Suma XP de cuenta; devuelve cuántos niveles subió.
function Cuenta.ganarXP(perfil, xp: number): number
	local subidos = 0
	perfil.xp += xp
	while perfil.xp >= Cuenta.xpParaSubir(perfil.level) do
		perfil.xp -= Cuenta.xpParaSubir(perfil.level)
		perfil.level += 1
		subidos += 1
	end
	return subidos
end

-- Oro al terminar una partida (19/11/2026): 10 por oleada superada, ×1,5 si se gana, ×1,5 en Difícil y ×2 en
-- Pesadilla (no se suman: vale el mayor).
Cuenta.ORO_OLEADA = 10
function Cuenta.oroPartida(superadas: number, gano: boolean, dificil: boolean, pesadilla: boolean): number
	local mult = (if gano then 1.5 else 1) * (if pesadilla then 2 elseif dificil then 1.5 else 1)
	return math.floor(math.max(0, superadas) * Cuenta.ORO_OLEADA * mult + 0.5)
end

return Cuenta
