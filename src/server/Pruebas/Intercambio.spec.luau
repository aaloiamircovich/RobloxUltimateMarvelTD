-- Intercambio (docs/INTERCAMBIO.md). Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local RS = game:GetService("ReplicatedStorage")
	local Intercambio = require(RS.Shared.Intercambio)
	local Unidades = require(RS.Shared.Unidades)
	local Perfiles = require(script.Parent.Parent.Perfiles)

	local function perfil(nivel)
		local p = Perfiles.normalizar(nil)
		p.level = nivel
		return p
	end
	local a, b = perfil(12), perfil(15)
	local ua = Unidades.agregar(a, "hawkeye", 7)
	ua.rasgo = "veloz"
	local enEscuadron = Unidades.agregar(a, "korg", 3)
	local exclusivo = Unidades.agregar(a, "odin", 1)
	a.squad = { enEscuadron.uid }
	local ub = Unidades.agregar(b, "black_widow", 5)
	b.squad = {}
	table.insert(a.ownedItemIds, "chaleco_tactico")

	-- Validación de ofertas
	assert(select(2, Intercambio.validarOferta(a, { unidades = { enEscuadron.uid }, objetos = {} })), "no se ofrece una unidad del escuadrón")
	assert(select(2, Intercambio.validarOferta(a, { unidades = { exclusivo.uid }, objetos = {} })), "no se ofrecen exclusivos")
	assert(select(2, Intercambio.validarOferta(a, { unidades = { 999 }, objetos = {} })), "unidad inexistente")
	assert(select(2, Intercambio.validarOferta(a, { unidades = { ua.uid, ua.uid }, objetos = {} })), "unidad repetida")
	assert(select(2, Intercambio.validarOferta(a, { unidades = {}, objetos = { "baliza_fury" } })), "objeto que no tiene")
	assert(select(2, Intercambio.validarOferta(a, "hola")), "oferta con forma rota")
	assert(Intercambio.validarOferta(a, { unidades = { ua.uid }, objetos = { "chaleco_tactico" } }), "oferta válida")

	-- Nivel mínimo
	local novato = perfil(3)
	assert(Intercambio.aplicar(novato, Intercambio.ofertaVacia(), b, { unidades = { ub.uid }, objetos = {} }), "nivel mínimo 10")

	-- Intercambio completo
	local err = Intercambio.aplicar(a, { unidades = { ua.uid }, objetos = { "chaleco_tactico" } }, b, { unidades = { ub.uid }, objetos = {} })
	assert(err == nil, tostring(err))
	assert(not Unidades.buscar(a, ua.uid) or a.units[#a.units].heroId == "black_widow", "A ya no tiene a Hawkeye con ese uid")
	local recibida
	for _, u in b.units do
		if u.heroId == "hawkeye" then
			recibida = u
		end
	end
	assert(recibida and recibida.level == 7 and recibida.rasgo == "veloz", "la unidad conserva nivel y rasgo")
	assert(table.find(b.ownedItemIds, "chaleco_tactico") and not table.find(a.ownedItemIds, "chaleco_tactico"), "el objeto cambió de dueño")
	local nombres = {}
	for _, u in a.units do
		nombres[u.heroId] = true
	end
	assert(nombres.black_widow and nombres.korg and nombres.odin and not nombres.hawkeye, "A recibió a Black Widow y conserva el resto")

	-- Sin cambios si algo falla (objeto repetido en el destino)
	table.insert(a.ownedItemIds, "chaleco_tactico")
	local antesA, antesB = #a.units, #b.units
	assert(Intercambio.aplicar(a, { unidades = {}, objetos = { "chaleco_tactico" } }, b, Intercambio.ofertaVacia()), "el otro ya tiene ese objeto")
	assert(#a.units == antesA and #b.units == antesB and table.find(a.ownedItemIds, "chaleco_tactico"), "un intercambio rechazado no cambia nada")
	assert(Intercambio.aplicar(a, Intercambio.ofertaVacia(), b, Intercambio.ofertaVacia()), "ofertas vacías")
	return "ok"
end
