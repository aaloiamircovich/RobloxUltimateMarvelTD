-- Ruta y terreno de los mapas jugables contra getMission del 3D (los que el 3D no tenía, contra el path del 2D) (scripts/referencia-mapas.mjs),
-- más las celdas reservadas de Sanctum.
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Mapa = require(Shared.Mapa)
	local Despliegue = require(Shared.Despliegue)
	local Oleadas = require(Shared.Oleadas)
	local heroes = require(Shared.Data.heroes)
	local niveles = require(Shared.Data.levels)
	local ref = require(script.Parent.mapas_3d)

	for _, id in Mapa.JUGABLES do
		local nivel
		for _, n in niveles do
			if n.id == id then
				nivel = n
			end
		end
		local esperado = ref[id]
		local ruta = Mapa.rutaPixeles(nivel)
		if not esperado then
			-- Mapas que el 3D no tenía (Instituto Xavier en adelante): terreno propio de 20×15; se comprueba que
			-- la ruta sea la del 2D y que todas sus celdas sean camino.
			local p1, pn = nivel.path[1], nivel.path[#nivel.path]
			-- rutaPixeles alarga la ruta una celda afuera por cada punta (portón y base).
			assert(ruta[2].x == p1.x and ruta[2].y == p1.y and ruta[#ruta - 1].x == pn.x and ruta[#ruta - 1].y == pn.y, `{id}: extremos de la ruta`)
			local grilla, lado = Mapa.terreno(nivel)
			assert(#grilla == 15 and #grilla[1] == 20 and lado == 40, `{id}: tamaño de la grilla`)
			for i = 2, #ruta - 2 do
				local a, b = ruta[i], ruta[i + 1]
				for k = 0, 10 do
					local x, y = a.x + (b.x - a.x) * k / 10, a.y + (b.y - a.y) * k / 10
					local fila = grilla[math.clamp(math.floor(y / lado) + 1, 1, 15)]
					assert(fila[math.clamp(math.floor(x / lado) + 1, 1, 20)] == 2, `{id}: la ruta pasa por una celda que no es camino ({x}, {y})`)
				end
			end
			continue
		end
		assert(#ruta == #esperado.ruta, `{id}: {#ruta} puntos de ruta ≠ {#esperado.ruta}`)
		for i, p in esperado.ruta do
			assert(ruta[i].x == p.x and ruta[i].y == p.y, `{id}: punto {i} de la ruta`)
		end
		local grilla, lado = Mapa.terreno(nivel)
		assert(lado == esperado.lado, `{id}: lado {lado} ≠ {esperado.lado}`)
		assert(#grilla == #esperado.terreno, `{id}: filas`)
		for f, fila in esperado.terreno do
			for c, codigo in fila do
				assert(grilla[f][c] == codigo, `{id}: celda ({f}, {c}) = {grilla[f][c]} ≠ {codigo}`)
			end
		end
		assert(Oleadas.dificultad(nivel) == esperado.dificultad, `{id}: dificultad`)
	end

	-- Sanctum: las runas reservan su zona (radio 58 + 16 px).
	local sanctum = niveles[4]
	local ruta = Mapa.rutaPixeles(sanctum)
	assert(Despliegue.error(heroes.korg, 240, 320, sanctum, ruta, {}) == "Celda reservada para una defensa de la misión.", "runa reservada")
	assert(not Despliegue.reservada(sanctum, 100, 100), "lejos de las runas no hay reserva")

	-- Instituto Xavier: las balizas reservan su zona (radio 54 + 16 px) y hay agua y altura al alcance.
	local xavier = niveles[5]
	local rutaX = Mapa.rutaPixeles(xavier)
	assert(Despliegue.error(heroes.korg, 220, 300, xavier, rutaX, {}) == "Celda reservada para una defensa de la misión.", "baliza reservada")
	assert(Despliegue.terreno(xavier, 340, 420) == 0, "estanque de Xavier")
	assert(Despliegue.terreno(xavier, 260, 180) == 3, "ala oeste de Xavier")
	-- Knowhere: las zonas sin radio reservan 34 + 16 px; plataformas de altura junto al camino.
	local knowhere = niveles[6]
	local rutaK = Mapa.rutaPixeles(knowhere)
	assert(Despliegue.error(heroes.korg, 260, 170, knowhere, rutaK, {}) == "Celda reservada para una defensa de la misión.", "carga reservada")
	assert(Despliegue.terreno(knowhere, 280, 320) == 3 and Despliegue.terreno(knowhere, 500, 360) == 3, "plataformas de Knowhere")
	-- Latveria: torres junto al camino (altura) y foso (agua).
	local latveria = niveles[7]
	assert(Despliegue.terreno(latveria, 300, 220) == 3 and Despliegue.terreno(latveria, 60, 380) == 0, "torre y foso de Latveria")
	-- Asgard: dos rutas (Bifrost) pintadas como camino, los demás mapas con una; los portales reservan su
	-- zona; el alcance vale contra cualquiera de las dos rutas.
	local asgard = niveles[8]
	local rutasA = Mapa.rutasPixeles(asgard)
	assert(#rutasA == 2 and #Mapa.rutasPixeles(niveles[1]) == 1, "rutas del Bifrost")
	assert(Despliegue.terreno(asgard, 410, 40) == 2 and Despliegue.terreno(asgard, 20, 170) == 2, "las dos entradas son camino")
	assert(Despliegue.error(heroes.korg, 260, 140, asgard, rutasA, {}) == "Celda reservada para una defensa de la misión.", "portal reservado")
	assert(Despliegue.terreno(asgard, 340, 300) == 3 and Despliegue.terreno(asgard, 300, 540) == 0, "palacio y mar de Asgard")
	-- Dimensión Oscura: plataforma (altura) y charco (agua) al alcance; las runas reservan 72 + 16 px.
	local oscura = niveles[9]
	assert(Despliegue.terreno(oscura, 340, 200) == 3 and Despliegue.terreno(oscura, 620, 200) == 0, "plataforma y charco de la Dimensión Oscura")
	assert(Despliegue.reservada(oscura, 300, 300), "runa NEXO reservada")
	-- Savage Land: dos senderos (selva) pintados como camino; templo (altura) y río (agua) al alcance.
	local selva = niveles[10]
	assert(#Mapa.rutasPixeles(selva) == 2, "senderos de Savage Land")
	assert(Despliegue.terreno(selva, 20, 470) == 2 and Despliegue.terreno(selva, 20, 190) == 2, "las dos entradas de la selva son camino")
	assert(Despliegue.terreno(selva, 420, 260) == 3 and Despliegue.terreno(selva, 300, 540) == 0, "templo y río de Savage Land")
	return "OK: 4 mapas idénticos al 3D y los nuevos con su ruta"
end
