-- Casos de despliegue en Base Avengers (celdas de 32 px; M = Montaña, G = Pasto, P = Camino).
-- Ejecutar en Studio: require(game.ServerScriptService.Server.Pruebas["Despliegue.spec"])()
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Despliegue = require(Shared.Despliegue)
	local Mapa = require(Shared.Mapa)
	local heroes = require(Shared.Data.heroes)
	local nivel = require(Shared.Data.levels)[1]
	local ruta = Mapa.rutaPixeles(nivel)

	local function caso(heroe, x, y, unidades, esperado, moviendo)
		local err = Despliegue.error(heroes[heroe], x, y, nivel, ruta, unidades or {}, moviendo)
		assert(err == esperado, `{heroe} en ({x}, {y}): se esperaba {esperado}, salió {err}`)
	end

	-- La ruta normalizada agrega entrada y salida a 40 px del borde, como el 2D.
	assert(ruta[1].x == -40 and ruta[1].y == 432 and ruta[#ruta].x == 840, "ruta normalizada distinta del 2D")

	caso("hawkeye", 470, 410, nil, nil) -- hangar (M) frente al último tramo, en cruz
	caso("hawkeye", 300, 280, nil, "Requiere Montaña; esta celda es Pasto")
	caso("black_widow", 80, 430, nil, "Requiere Pasto; esta celda es Camino")
	caso("black_widow", 300, 280, nil, nil)
	caso("korg", 20, 560, nil, "El camino está fuera del alcance de este héroe") -- 128 px > 85
	caso("korg", 20, 500, nil, nil) -- 64 px ≤ 85
	caso("hawkeye", -5, 400, nil, "Fuera del mapa")
	local ocupado = { { uid = 1, heroe = "black_widow", x = 304, y = 272 } }
	caso("korg", 300, 280, ocupado, "Este espacio ya está ocupado")
	caso("black_widow", 300, 340, ocupado, "Este héroe ya está desplegado")
	caso("black_widow", 300, 340, ocupado, nil, 1) -- moverse a otra celda sí

	-- Forma en cruz: fuera de los carriles no alcanza aunque esté dentro del radio.
	assert(Despliegue.enAlcance(0, 0, 30, 200, 220, "cross"), "cruz: carril vertical")
	assert(not Despliegue.enAlcance(0, 0, 100, 100, 220, "cross"), "cruz: diagonal fuera")
	assert(Despliegue.enAlcance(0, 0, 100, 100, 220, nil), "círculo: diagonal dentro")
	return "OK: reglas de despliegue"
end
