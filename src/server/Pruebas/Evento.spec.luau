-- Desafío semanal: modificadores, puntaje, fichas con tope y tienda (docs/EVENTO.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Evento = require(Shared.Evento)
	local Temporada = require(Shared.Temporada)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local T = Temporada.INICIO + 3600

	local d = Evento.desafio(Evento.semana(T))
	assert(#d.modificadores == 2 and d.modificadores[1] ~= d.modificadores[2] and d.mapa, "mapa y 2 modificadores distintos")
	assert(Evento.desafio(Evento.semana(T)).modificadores[1] == d.modificadores[1], "iguales para todos")
	local e = Evento.efectos({ modificadores = { "rapidos", "base_fragil" } })
	assert(e.velocidad == 1.25 and e.base == 0.5 and e.vida == 1 and not e.sinVender, "efectos combinados")
	assert(Evento.puntos(12, 340) == 1540, "100 por oleada + 1 por enemigo")

	-- Fichas: 1 cada 100 puntos, tope semanal; vale el mejor puntaje.
	local p = Perfiles.normalizar(nil)
	local f, record = Evento.registrar(p, 1540, T)
	assert(f == 15 and record and p.evento.mejor == 1540, "primer intento")
	f, record = Evento.registrar(p, 900, T)
	assert(f == 9 and not record and p.evento.mejor == 1540, "peor intento suma fichas pero no récord")
	Evento.registrar(p, 1e6, T)
	assert(p.evento.ganadas == Evento.FICHAS_SEMANA and p.evento.fichas == Evento.FICHAS_SEMANA, "tope semanal")

	-- Tienda con stock semanal.
	local g = p.gems
	assert(Evento.comprar(p, "gemas", T) == nil and p.gems == g + 100 and p.evento.fichas == 260, "compra gemas")
	assert(Evento.comprar(p, "objeto", T) == nil and #p.ownedItemIds == 1, "objeto épico")
	assert(Evento.comprar(p, "objeto", T) == "Agotado esta semana", "límite semanal")
	assert(Evento.comprar(p, "xp", T) == nil and p.temporada.xp == 300, "XP de pase")
	assert(Evento.comprar(p, "trampa", T) ~= nil, "producto inválido")

	-- Semana siguiente: todo vuelve a cero.
	Evento.actualizar(p, T + Temporada.SEMANA)
	assert(p.evento.mejor == 0 and p.evento.fichas == 0 and next(p.evento.compras) == nil, "nueva semana")

	-- Guardado.
	p.evento.mejor = 777
	local copia = Perfiles.normalizar({ evento = p.evento })
	assert(copia.evento.mejor == 777, "persistencia")
	assert(Perfiles.normalizar({ evento = { fichas = "x", compras = { gemas = 99, hack = 1 } } }).evento.compras.gemas == 5, "datos rotos")
	return "OK: evento"
end
