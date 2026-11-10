-- Ruta y terreno de los 4 mapas jugables contra getMission del 3D (scripts/referencia-mapas.mjs),
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
	return "OK: 4 mapas idénticos al 3D"
end
