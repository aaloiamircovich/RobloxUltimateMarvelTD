-- Agenda del lobby (docs/LOBBY.md, fase D): hora del día y eventos que pasan solos. Todo sale de la hora del
-- servidor (workspace:GetServerTimeNow()), así todos los clientes ven lo mismo sin mandar nada por la red.
-- Módulo puro: recibe el tiempo por parámetro.
local AgendaLobby = {}

AgendaLobby.DIA = 20 * 60 -- un día completo del lobby, en segundos
AgendaLobby.CICLO = 150 -- cada 2,5 min pasa un evento, en este orden
AgendaLobby.EVENTOS = {
	{ nombre = "quinjet", duracion = 22 }, -- el Quinjet aterriza en la isla central y vuelve a despegar
	{ nombre = "bifrost", duracion = 7 }, -- un rayo arcoíris del Bifrost cae sobre Asgard
	{ nombre = "portal", duracion = 12 }, -- se abre un portal de Strange en la isla del Sanctum
}

-- Hora del lobby (0–24). Arranca a las 8 de la mañana.
function AgendaLobby.hora(t: number): number
	return (8 + (t % AgendaLobby.DIA) / AgendaLobby.DIA * 24) % 24
end

function AgendaLobby.esDeNoche(hora: number): boolean
	return hora >= 19 or hora < 6
end

-- Evento en curso: (nombre, progreso 0–1) o nil.
function AgendaLobby.evento(t: number): (string?, number)
	local indice = math.floor(t / AgendaLobby.CICLO) % #AgendaLobby.EVENTOS + 1
	local e = AgendaLobby.EVENTOS[indice]
	local dentro = t % AgendaLobby.CICLO
	if dentro < e.duracion then
		return e.nombre, dentro / e.duracion
	end
	return nil, 0
end

return AgendaLobby
