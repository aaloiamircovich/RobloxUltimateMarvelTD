-- Conductas de enemigos del 2D con números calculados a mano.
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Combate = require(Shared.Combate)
	local Conductas = require(Shared.Conductas)
	local enemigos = require(Shared.Data.enemies)
	local function cerca(a, b)
		return math.abs(a - b) < 1e-6
	end
	local function nuevo(config)
		local e = Combate.nuevoEnemigo(table.clone(config))
		Conductas.preparar(e)
		return e
	end
	local registro = {}
	local function entorno(aliados)
		return {
			aliados = function()
				return aliados or {}
			end,
			invocar = function(id, origen, factor)
				table.insert(registro, { id = id, factor = factor })
				return true
			end,
			aviso = function(t)
				table.insert(registro, { aviso = t })
			end,
			aturdirHeroes = function(s)
				table.insert(registro, { aturdir = s })
			end,
		}
	end

	-- Apoyo: cura 6% (o healPower) a los heridos cada behaviorCooldown (4 s por defecto).
	local herido = nuevo({ id = "x", hp = 100 })
	herido.vida = 50
	local apoyo = nuevo({ id = "aim", hp = 95, archetype = "support" })
	Conductas.actualizar(apoyo, 3.9, entorno({ herido }))
	assert(herido.vida == 50, "todavía no cura")
	Conductas.actualizar(apoyo, 0.2, entorno({ herido }))
	assert(cerca(herido.vida, 56), "cura 6%")

	-- Sabotaje: bloquea la acción 2 s y deja 3 s de inmunidad.
	herido.vida = 50
	apoyo.conducta.accion = 0.1
	assert(Conductas.sabotear(apoyo, 2), "sabotea al apoyo")
	assert(not Conductas.sabotear(apoyo, 2), "inmune mientras dura el bloqueo")
	Conductas.actualizar(apoyo, 1.9, entorno({ herido }))
	assert(herido.vida == 50, "no cura saboteado")
	Conductas.actualizar(apoyo, 0.3, entorno({ herido }))
	assert(cerca(herido.vida, 56), "vuelve a curar al terminar")
	assert(not Conductas.sabotear(nuevo({ id = "s", hp = 10 }), 2), "un soldado no se sabotea")

	-- Invocador: doombot invoca su summonId al 70% de vida, hasta summonLimit.
	local doom = nuevo(enemigos.normal.doombot)
	table.clear(registro)
	for _ = 1, 40 do
		Conductas.actualizar(doom, 1, entorno())
	end
	assert(#registro == enemigos.normal.doombot.summonLimit, `invocaciones {#registro}`)
	assert(registro[1].id == enemigos.normal.doombot.summonId and registro[1].factor == 0.7, "invoca al 70%")

	-- Comandante: acelera 20% a los aliados 2.5 s.
	local aliado = nuevo({ id = "a", hp = 10 })
	local jefeTropa = nuevo({ id = "c", hp = 10, affix = "commander" })
	Conductas.actualizar(jefeTropa, 5, entorno({ aliado }))
	assert(cerca(Combate.actualizar(aliado, 0.1), 1.2), "acelerado 20%")

	-- Escudo: la barrera vuelve 5 s después del último golpe absorbido.
	local escudo = nuevo({ id = "h", hp = 100, archetype = "shield", barrierRatio = 0.26 })
	Combate.recibir(escudo, 40)
	assert(escudo.barrera == 0, "barrera rota")
	Conductas.actualizar(escudo, 4.9, entorno())
	assert(escudo.barrera == 0, "todavía no recarga")
	Conductas.actualizar(escudo, 0.2, entorno())
	assert(escudo.barrera == 26, "barrera recargada")

	-- Corredor: +45% los primeros 1.4 s de cada 5.
	local corredor = nuevo({ id = "r", hp = 10, archetype = "runner" })
	assert(cerca(Conductas.actualizar(corredor, 1, entorno()), 1.45) and Conductas.actualizar(corredor, 1, entorno()) == 1, "ráfaga de corredor")

	-- Fase: sigilo 1.4 s y +35% al activarse.
	local fase = nuevo({ id = "p", hp = 10, archetype = "phaser", behaviorCooldown = 6 })
	assert(cerca(Conductas.actualizar(fase, 6, entorno()), 1.35) and Combate.sigilo(fase), "entra en fase")
	Conductas.actualizar(fase, 1.5, entorno())
	assert(not Combate.sigilo(fase), "sale de fase")

	-- Afijos: regenerador 1.2%/s; inestable +45% bajo 35% de vida.
	local regen = nuevo({ id = "g", hp = 100, affix = "regenerator" })
	regen.vida = 50
	Conductas.actualizar(regen, 1, entorno())
	assert(cerca(regen.vida, 51.2), "regenera")
	local inestable = nuevo({ id = "u", hp = 100, affix = "unstable" })
	inestable.vida = 30
	assert(cerca(Conductas.actualizar(inestable, 0.1, entorno()), 1.45), "inestable acelera")

	-- Fases de jefe: Thanos con aviso, barrera del 12%, Guantelete que aturde 4 s y armadura.
	local thanos = nuevo(enemigos.bosses.thanos_final)
	table.clear(registro)
	thanos.vida = thanos.vidaMax * 0.7
	Conductas.actualizar(thanos, 0.1, entorno())
	assert(registro[1].aviso:find("Gema del Poder"), "anuncia la fase")
	Conductas.actualizar(thanos, 1.5, entorno())
	assert(thanos.barrera >= math.floor(thanos.vidaMax * 0.12 + 0.5), "barrera de fase")
	thanos.vida = thanos.vidaMax * 0.4
	Conductas.actualizar(thanos, 0.1, entorno())
	Conductas.actualizar(thanos, 0.8, entorno())
	local aturdio = false
	for _, r in registro do
		aturdio = aturdio or r.aturdir == 4
	end
	assert(aturdio, "el Guantelete aturde héroes 4 s")
	return "OK: conductas"
end
