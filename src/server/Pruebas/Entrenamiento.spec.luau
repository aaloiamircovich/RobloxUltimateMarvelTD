-- Entrenamiento: mapa del campo de pruebas y validación de lo que pide el cliente (docs/ENTRENAMIENTO.md).
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Entrenamiento = require(Shared.Entrenamiento)
	local Mapa = require(Shared.Mapa)
	local enemigos = require(Shared.Data.enemies)

	-- Mapa: 25 × 19 baldosas, la ruta va por el camino y hay agua y montaña para cualquier héroe.
	local n = Entrenamiento.NIVEL
	assert(#n.rendering.terrainRows == 19, "19 filas")
	local hay = {}
	for _, fila in n.rendering.terrainRows do
		assert(#fila == 25, "25 columnas")
		for c = 1, #fila do
			hay[fila:sub(c, c)] = true
		end
	end
	assert(hay.W and hay.M and hay.G and hay.P, "pasto, camino, agua y montaña")
	local grilla, lado = Mapa.terreno(n)
	for _, pt in n.path do
		local f = grilla[math.floor(math.min(pt.y, 607) / lado) + 1]
		local codigo = f and f[math.floor(math.min(pt.x, 799) / lado) + 1]
		assert(codigo == 2, `la ruta pasa por camino en {pt.x},{pt.y}`)
	end

	-- Héroe configurado: valores fuera de rango se acotan; rasgos, grados y objetos inventados se descartan.
	local e = Entrenamiento.validarHeroe(2, { heroId = "hawkeye", nivel = 999, mejora = -3, rasgo = "vibranium", grados = { dano = "S+", alcance = "Z" }, objeto = "inventado", shiny = true })
	assert(e.uid == 2 and e.nivel == 50 and e.mejora == 0 and e.rasgo == "vibranium" and e.grados.dano == "S+" and e.grados.alcance == nil and e.objeto == nil and e.shiny, "héroe acotado")
	assert(select(2, Entrenamiento.validarHeroe(7, { heroId = "hawkeye" })) == "Datos inválidos", "casilla fuera de rango")
	assert(select(2, Entrenamiento.validarHeroe(1, { heroId = "nadie" })) == "Ese héroe no existe", "héroe inexistente")

	-- Enemigos: cantidad e intervalo acotados, velocidad 0 permitida (quietos), jefes reconocidos.
	local idNormal = next(enemigos.normal)
	local t = Entrenamiento.validarEnemigos({ id = idNormal, cantidad = 500, intervalo = 0, velocidad = 0, vida = 0 / 0 }, enemigos)
	assert(t.cantidad == Entrenamiento.MAX_ENEMIGOS and t.intervalo == 0.2 and t.velocidad == 0 and t.vida == nil and not t.jefe, "tanda acotada")
	local idJefe = next(enemigos.bosses)
	assert(Entrenamiento.validarEnemigos({ id = idJefe, vida = 5000 }, enemigos).jefe == true, "jefe")
	assert(select(2, Entrenamiento.validarEnemigos({ id = "nadie" }, enemigos)) == "Ese enemigo no existe", "enemigo inexistente")

	-- Velocidades: ciclo con cámara lenta.
	assert(Entrenamiento.siguienteVelocidad(1) == 2 and Entrenamiento.siguienteVelocidad(3) == 0.25 and Entrenamiento.siguienteVelocidad(0.5) == 1, "ciclo de velocidades")
	return "OK: entrenamiento"
end
