-- Agenda del lobby (docs/LOBBY.md): hora del día y eventos. Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local AgendaLobby = require(game:GetService("ReplicatedStorage").Shared.AgendaLobby)
	assert(AgendaLobby.hora(0) == 8, "arranca a las 8")
	assert(math.abs(AgendaLobby.hora(AgendaLobby.DIA / 2) - 20) < 1e-6, "a la mitad del día son las 20")
	assert(AgendaLobby.hora(AgendaLobby.DIA) == 8, "el día da la vuelta")
	assert(AgendaLobby.esDeNoche(22) and AgendaLobby.esDeNoche(3) and not AgendaLobby.esDeNoche(12), "noche de 19 a 6")
	local vistos = {}
	for k = 0, #AgendaLobby.EVENTOS - 1 do
		local nombre, p = AgendaLobby.evento(k * AgendaLobby.CICLO + 1)
		assert(nombre and p > 0 and p < 1, "hay un evento al principio de cada ciclo")
		vistos[nombre] = true
	end
	assert(vistos.quinjet and vistos.bifrost and vistos.portal, "los tres eventos se turnan")
	assert(AgendaLobby.evento(AgendaLobby.CICLO - 1) == nil, "al final del ciclo no hay evento")
	return "OK: agenda del lobby"
end
