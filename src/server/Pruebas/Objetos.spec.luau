-- Tienda, inventario, equipo y efectos de objetos del 2D.
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Objetos = require(Shared.Objetos)
	local Progresion = require(Shared.Progresion)
	local Kits = require(Shared.Kits)
	local Combate = require(Shared.Combate)
	local items = require(Shared.Data.items)
	local heroes = require(Shared.Data.heroes)
	local tipos = require(Shared.Data.TypeChart)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local ref = require(script.Parent.objetos_2d)
	local function cerca(a, b)
		return math.abs(a - b) < 1e-6
	end

	-- La vitrina sigue el orden de sortItemsWeakestFirst del 2D: comprar siempre el primero recorre los 82.
	local p = Perfiles.normalizar({ credits = 1e9, unlockedHeroIds = { "hawkeye", "korg" } })
	for i, esperado in ref.orden do
		local v = Objetos.vitrina(p)
		assert(v[1] and v[1].id == esperado, `vitrina #{i}: {v[1] and v[1].id} ≠ {esperado}`)
		assert(#v == math.min(3, #ref.orden - i + 1), "tres a la vista")
		assert(Objetos.comprar(p, esperado) == nil, "compra " .. esperado)
	end
	assert(#Objetos.vitrina(p) == 0 and #p.ownedItemIds == 82, "se compran todos")

	local q = Perfiles.normalizar({ credits = 300, unlockedHeroIds = { "hawkeye", "korg" } })
	local primero = Objetos.vitrina(q)[1]
	assert(Objetos.comprar(q, ref.orden[10]) == "Objeto no disponible", "sólo lo que está en la vitrina")
	assert(Objetos.comprar(q, primero.id) == nil and q.credits == 300 - primero.price, "descuenta el precio")
	assert(Objetos.comprar(q, primero.id) == "Objeto no disponible", "no se compra dos veces")

	-- Equipar: desde el inventario, pasar a otro héroe, reemplazar y quitar.
	assert(Objetos.equipar(q, "thor", primero.id) == "No tenés ese héroe", "sólo héroes propios")
	assert(Objetos.equipar(q, "hawkeye", primero.id) == nil and #q.ownedItemIds == 0, "equipa desde el inventario")
	assert(Objetos.de(q, "hawkeye").id == primero.id, "equipado en Hawkeye")
	assert(Objetos.equipar(q, "korg", primero.id) == nil and Objetos.de(q, "hawkeye") == nil and Objetos.de(q, "korg").id == primero.id, "pasa de héroe")
	q.credits = 1e6
	local segundo = Objetos.vitrina(q)[1]
	Objetos.comprar(q, segundo.id)
	assert(Objetos.equipar(q, "korg", segundo.id) == nil and table.find(q.ownedItemIds, primero.id), "el anterior vuelve al inventario")
	assert(Objetos.quitar(q, "korg") == nil and #q.ownedItemIds == 2, "quitar")
	local guardado = Perfiles.normalizar({ unlockedHeroIds = { "korg" }, ownedItemIds = { primero.id, primero.id, "inventado" }, equippedItems = { korg = { weapon = primero.id }, thor = { weapon = segundo.id } } })
	assert(#guardado.ownedItemIds == 0 and Objetos.de(guardado, "korg").id == primero.id, "el perfil no duplica objetos ni acepta héroes ajenos")

	-- Estadísticas: chaleco táctico (+6% daño y cadencia), baliza Fury (detecta sigilo, +8% alcance).
	local base = Progresion.stats(heroes.korg, 1)
	local chaleco = Progresion.stats(heroes.korg, 1, items.chaleco_tactico)
	assert(cerca(chaleco.damage, base.damage * 1.06) and cerca(chaleco.fireRate, base.fireRate * 1.06), "chaleco táctico")
	local baliza = Progresion.stats(heroes.korg, 1, items.baliza_fury)
	assert(baliza.canSeeStealth and cerca(baliza.range, base.range * 1.08), "baliza Fury")
	local agua
	for id, it in items do
		if it.effects.allowWater then
			agua = it
		end
	end
	assert(table.find(Progresion.stats(heroes.korg, 1, agua).terrenos, 0), "objeto que permite agua")

	-- Golpe: penetración sumada con tope, efectos del objeto y rebotes.
	local blanco = Combate.nuevoEnemigo({ id = "d", hp = 200, armor = 0.35, category = "Tecnológico" })
	local kit = Kits.nuevo("korg")
	local g = Kits.golpe(kit, heroes.korg, blanco, 10, base, items.chaleco_tactico, 50)
	assert(cerca(g.penetracion, 0.06) and g.radioSplash == 48, "penetración del chaleco y splash propio de Korg")
	local rebote
	for _, it in items do
		if it.effects.chainCount and not rebote then
			rebote = it
		end
	end
	local gr = Kits.golpe(kit, heroes.korg, blanco, 10, base, rebote, 50)
	assert(gr.rebotes == math.floor(rebote.effects.chainCount + 0.5) and gr.factorRebote == rebote.effects.chainFactor, "rebotes del objeto")

	-- Rebote en el combate: al más cercano, factor^salto.
	local e1, e2, e3 = Combate.nuevoEnemigo({ id = "1", hp = 100 }), Combate.nuevoEnemigo({ id = "2", hp = 100 }), Combate.nuevoEnemigo({ id = "3", hp = 100 })
	local pos = { [e1] = 0, [e2] = 50, [e3] = 90 }
	local _, saltos = Combate.impacto(e1, { tipo = "x", dano = 10, rebotes = 2, rangoRebote = 60, factorRebote = 0.5 }, tipos, math.random, { e1, e2, e3 }, function(e)
		return pos[e], 0
	end)
	assert(#saltos == 2 and e2.vida == 95 and e3.vida == 97.5, `rebotes: {e2.vida}, {e3.vida}`)

	-- Estados nuevos: quemadura (DPS plano por tics de 0.5 s), maldición (% de vida) y aturdir (frena).
	local q1 = Combate.nuevoEnemigo({ id = "q", hp = 100 })
	Combate.aplicarEstado(q1, { type = "burn", duration = 4, power = 2 })
	for _ = 1, 40 do
		Combate.actualizar(q1, 0.1)
	end
	-- 7 y no 8: con pasos de 0.1 s el último tic se pierde por redondeo, igual que en el 2D (simulado en Node).
	assert(cerca(q1.vida, 93), `quemadura total {100 - q1.vida}`)
	local m = Combate.nuevoEnemigo({ id = "m", hp = 1000 })
	Combate.aplicarEstado(m, { type = "curse", duration = 1, power = 0.01 })
	Combate.actualizar(m, 0.5)
	assert(cerca(m.vida, 995), "maldición 1% de la vida máxima por segundo")
	Combate.aplicarEstado(m, { type = "stun", duration = 0.25 })
	assert(Combate.actualizar(m, 0.1) == 0, "aturdido no avanza")
	assert(Combate.cantidadEstados(m) == 2, "cuenta estados activos")
	return "OK: objetos"
end
