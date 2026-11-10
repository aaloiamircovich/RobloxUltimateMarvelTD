-- Daño, estados y kits de los héroes iniciales, con números calculados a mano desde el 2D.
-- Ejecutar en Studio: require(game.ServerScriptService.Server.Pruebas["Kits.spec"])()
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Combate = require(Shared.Combate)
	local Kits = require(Shared.Kits)
	local heroes = require(Shared.Data.heroes)
	local tipos = require(Shared.Data.TypeChart)
	local function cerca(a, b)
		return math.abs(a - b) < 1e-6
	end

	-- Armadura, ruptura y penetración (doombot: 200 de vida, 35% de armadura).
	local doom = { id = "doombot", hp = 200, armor = 0.35, category = "Tecnológico", archetype = "summoner" }
	local e = Combate.nuevoEnemigo(doom)
	assert(cerca(Combate.recibir(e, 100), 65), "armadura 35%")
	Combate.aplicarEstado(e, { type = "armorBreak", duration = 4, power = 0.3 })
	assert(cerca(Combate.recibir(e, 10), 9.5), "ruptura de armadura 0.3")
	local p = Combate.nuevoEnemigo(doom)
	assert(cerca(Combate.recibir(p, 100, { penetracion = 0.8 }), 93), "penetración 80%")

	-- Barrera (soldado de Hydra: 115 de vida, barrera 26% = 30) y mínimo de 1.
	local hydra = { id = "hydra_soldier", hp = 115, armor = 0, barrierRatio = 0.26, statusResistances = { slow = 0.1 } }
	local h = Combate.nuevoEnemigo(hydra)
	Combate.recibir(h, 50)
	assert(h.barrera == 0 and h.vida == 95, "la barrera absorbe primero")
	assert(Combate.recibir(Combate.nuevoEnemigo(doom), 0.1) == 1, "daño mínimo 1")

	-- Ralentizar con resistencia: 2.4 s × 0.9 y velocidad × 0.52.
	Combate.aplicarEstado(h, { type = "slow", duration = 2.4, power = 0.48 })
	assert(cerca(h.estados.slow.duration, 2.16), "duración con resistencia")
	assert(cerca(Combate.actualizar(h, 0.1), 0.52), "velocidad lenta")
	Combate.actualizar(h, 3)
	assert(h.estados.slow == nil and Combate.actualizar(h, 0.1) == 1, "el ralentizar termina")

	-- Veneno de Black Widow: 0.32% de la vida máxima por segundo, 3.2 s, ignora armadura.
	local v = Combate.nuevoEnemigo(doom)
	Combate.aplicarEstado(v, { type = "poison", duration = 3.2, power = 0.0032 })
	for _ = 1, 40 do
		Combate.actualizar(v, 0.1)
	end
	assert(cerca(200 - v.vida, 200 * 0.0032 * 3.2), `veneno total {200 - v.vida}`)
	for _ = 1, 15 do
		Combate.aplicarEstado(v, { type = "poison", duration = 3.2, power = 0.0032 })
	end
	assert(#v.estados.poison == 12, "veneno hasta 12 capas")

	-- Impacto con splash: el principal recibe 100% y efectos; el resto, el factor de splash.
	local a, b = Combate.nuevoEnemigo(doom), Combate.nuevoEnemigo(doom)
	local pos = { [a] = { 0, 0 }, [b] = { 30, 0 } }
	local function posicion(x)
		return pos[x][1], pos[x][2]
	end
	Combate.impacto(a, { tipo = "Urbano", dano = 100, radioSplash = 68, factorSplash = 0.58, efectos = { { type = "slow", duration = 1, power = 0.5 } } }, tipos, function()
		return 0
	end, { a, b }, posicion)
	assert(cerca(200 - a.vida, 100 * 1.5 * 0.65) and a.estados.slow, "Urbano vs Tecnológico ×1.5 y efecto al principal")
	assert(cerca(200 - b.vida, 100 * 0.58 * 1.5 * 0.65) and not b.estados.slow, "splash sin efectos")

	-- Hawkeye: el cuarto disparo hace +35% y agranda la explosión.
	local kh = Kits.nuevo("hawkeye")
	local dist = {}
	for i = 1, 4 do
		local g = Kits.golpe(kh, heroes.hawkeye, a, 10)
		table.insert(dist, `{g.dano}/{g.radioSplash}`)
		Kits.alAtacar(kh, heroes.hawkeye, {}, 1, a, {}, {})
	end
	assert(table.concat(dist, " ") == "10/68 10/68 10/68 13.5/85", table.concat(dist, " "))
	kh.modo = "piercing"
	kh.ataques = 3
	assert(Kits.golpe(kh, heroes.hawkeye, a, 10).penetracion == 0.8, "perforante preparada")
	kh.modo = "cryo"
	kh.ataques = 0
	assert(Kits.golpe(kh, heroes.hawkeye, a, 10).efectos[1].power == 0.48, "criogénica")

	-- Black Widow: veneno de config.special; ruptura sólo contra apoyos; sabotaje al cuarto ataque.
	local kw = Kits.nuevo("black_widow")
	local gw = Kits.golpe(kw, heroes.black_widow, a, 10)
	assert(gw.efectos[1].type == "armorBreak" and gw.efectos[2].type == "poison", "ruptura (kit) y veneno (especial) contra invocador")
	local soldado = Combate.nuevoEnemigo({ id = "x", hp = 100, armor = 0 })
	assert(#Kits.golpe(kw, heroes.black_widow, soldado, 10).efectos == 1, "sin ruptura contra no-apoyos")
	local lista = { { e = soldado, x = 0, y = 0 } }
	for i = 1, 4 do
		table.insert(lista, { e = Combate.nuevoEnemigo(if i == 4 then doom else { id = "y", hp = 100 }), x = i * 10, y = 0 })
	end
	local w = { x = 0, y = 0, alcance = 130, ve = true }
	for _ = 1, 3 do
		assert(#Kits.alAtacar(kw, heroes.black_widow, { damage = 18 }, 1, soldado, w, lista) == 0, "sin sabotaje antes del cuarto")
	end
	local s = Kits.alAtacar(kw, heroes.black_widow, { damage = 18 }, 1, soldado, w, lista)
	assert(#s == 4 and s[2].enemigo == lista[5].e, "blanco + 3 cercanos, apoyos primero")
	assert(cerca(s[1].golpe.dano, 18 * 0.55), "55% del daño")

	-- Korg: enfriamiento inicial de 5 s y pisotón sólo con 3 terrestres a 65 px.
	local kk = Kits.nuevo("korg")
	local stats = { damage = 39, range = 85 }
	local cerquita = {}
	for i = 1, 3 do
		table.insert(cerquita, { e = Combate.nuevoEnemigo({ id = "z", hp = 100 }), x = i * 10, y = 0, avance = i })
	end
	assert(Kits.actualizar(kk, 1, heroes.korg, stats, { x = 0, y = 0 }, cerquita) == nil, "espera los 5 s iniciales")
	local golpes = Kits.actualizar(kk, 4, heroes.korg, stats, { x = 0, y = 0 }, cerquita)
	assert(golpes and #golpes == 3 and golpes[1].enemigo == cerquita[3].e and golpes[1].golpe.dano == 19.5, "pisotón: más avanzado primero, 50%")
	assert(Kits.actualizar(kk, 1, heroes.korg, stats, { x = 0, y = 0 }, cerquita) == nil, "vuelve a esperar 5 s")
	cerquita[3].e.config.flying = true
	kk.enfriamiento = 0
	assert(Kits.actualizar(kk, 0, heroes.korg, stats, { x = 0, y = 0 }, cerquita) == nil, "voladores no cuentan")
	assert(heroes.korg.special.projectileProfile.splashRadius == 48, "splash de Korg en los datos")
	return "OK: combate y kits"
end
