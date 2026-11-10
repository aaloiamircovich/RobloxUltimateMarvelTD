-- Dinero de partida: costo de colocar por rareza y poder, 5 mejoras con precio propio, habilidad
-- desde la mejora 2 (docs/INVOCACIONES.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Mejoras = require(Shared.Mejoras)
	local Personajes = require(Shared.Personajes)
	local Kits = require(Shared.Kits)
	local Combate = require(Shared.Combate)

	-- Colocar: base por rareza ±25 % según el costo del 2D dentro de la rareza.
	for _, r in Personajes.RAREZAS do
		local base = Mejoras.COLOCAR[r]
		for _, id in Personajes.invocables()[r] or {} do
			local c = Mejoras.costoColocar(Personajes.de(id))
			assert(c >= base * 0.75 - 5 and c <= base * 1.25 + 5 and c % 10 == 0, `{id}: {c} fuera de rango`)
		end
	end
	local promedio = {}
	for _, r in Personajes.RAREZAS do
		local suma, n = 0, 0
		for _, id in Personajes.invocables()[r] or {} do
			suma += Mejoras.costoColocar(Personajes.de(id))
			n += 1
		end
		promedio[r] = suma / n
	end
	for i = 2, #Personajes.RAREZAS do
		assert(promedio[Personajes.RAREZAS[i]] > promedio[Personajes.RAREZAS[i - 1]], "más rareza, más caro")
	end
	local ronin = Personajes.de(Personajes.evolucion("hawkeye"))
	assert(Mejoras.costoColocar(ronin) > Mejoras.COLOCAR[ronin.rarity] * 0.75 * 1.5 - 10, "el evolucionado cuesta ×1,5")

	-- Mejoras: 5, crecientes, las de habilidad con recargo.
	local hawkeye = Personajes.de("hawkeye")
	local lista = Mejoras.lista(hawkeye)
	assert(#lista == 5 and lista[2].nombre == "Carcaj táctico" and lista[4].nombre == "Carcaj táctico potenciada", "nombres")
	for i = 2, 5 do
		assert(lista[i].costo > lista[i - 1].costo, "precios crecientes")
	end
	local colocar = Mejoras.costoColocar(hawkeye)
	assert(math.abs(lista[2].costo - colocar * 0.9 * 1.3) <= 5, "recargo de habilidad")
	Mejoras.AJUSTES.hawkeye = { [5] = 3 }
	assert(math.abs(Mejoras.lista(hawkeye)[5].costo - lista[5].costo * 3) <= 15, "ajuste por personaje")
	Mejoras.AJUSTES.hawkeye = nil

	-- Efecto acumulado.
	local e0, e2, e5 = Mejoras.efecto(hawkeye, 0), Mejoras.efecto(hawkeye, 2), Mejoras.efecto(hawkeye, 5)
	assert(not e0.habilidad and e2.habilidad and e2.potencia == 1, "habilidad desde la mejora 2")
	assert(math.abs(e5.dano - 0.9) < 1e-9 and math.abs(e5.alcance - 0.2) < 1e-9 and math.abs(e5.cadencia - 0.25) < 1e-9 and e5.potencia == 1.5, "todas las mejoras")

	-- Kit bloqueado: Widow no sabotea y Hawkeye dispara simple hasta la mejora 2.
	local enemigo = Combate.nuevoEnemigo({ id = "x", hp = 100, speed = 1, reward = 1 })
	local kit = Kits.nuevo("hawkeye")
	kit.activa = false
	local g = Kits.golpe(kit, hawkeye, enemigo, 10, { damage = 10 }, nil, 50)
	assert((g.radioSplash or 0) == 0 and #g.efectos == 0, "sin habilidad, sin flecha explosiva")
	kit.activa = true
	assert(Kits.golpe(kit, hawkeye, enemigo, 10, { damage = 10 }, nil, 50).radioSplash == 68, "con habilidad, flecha explosiva")
	local widow = Kits.nuevo("black_widow")
	widow.activa = false
	for _ = 1, 4 do
		assert(#Kits.alAtacar(widow, Personajes.de("black_widow"), { damage = 10 }, 1, enemigo, { x = 0, y = 0, alcance = 999, ve = true }, { { e = enemigo, x = 0, y = 0 } }) == 0, "sin sabotaje")
	end
	return "OK: dinero de partida y mejoras"
end
