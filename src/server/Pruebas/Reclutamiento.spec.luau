-- Invocaciones, unidades y evoluciones (docs/INVOCACIONES.md): inicial, banner por hora con 50 % de
-- destacado, gemas, x1/x10, inventario de 100, venta, escuadrón, XP y crafteo de evoluciones.
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Reclutamiento = require(script.Parent.Parent.Reclutamiento)
	local Perfiles = require(script.Parent.Parent.Perfiles)
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Personajes = require(Shared.Personajes)
	local Unidades = require(Shared.Unidades)
	local Banner = require(Shared.Banner)

	-- Personajes evolucionados: una rareza más, bonos del 2D aplicados, mismo modelo base.
	local ronin = Personajes.de(Personajes.evolucion("hawkeye"))
	local hawkeye = Personajes.de("hawkeye")
	assert(ronin.name == "Ronin" and ronin.base == "hawkeye", "Hawkeye evoluciona en Ronin")
	assert(table.find(Personajes.RAREZAS, ronin.rarity) == table.find(Personajes.RAREZAS, hawkeye.rarity) + 1, "una rareza más")
	assert(math.abs(ronin.damage - hawkeye.damage * 1.26) < 1e-6, "bono de daño de la evolución")
	assert(Personajes.de(Personajes.evolucion("adam_warlock")).name == "Adam Warlock Evo", "nombre genérico")
	for _, id in Personajes.invocables().Legendary do
		assert(not Personajes.de(id).base, "las evoluciones no se invocan")
	end

	-- Inicial.
	local p = Perfiles.normalizar(nil)
	assert(p.gems == 500 and p.cores == 0 and #p.units == 0, "perfil nuevo: 500 gemas")
	assert(select(2, Banner.invocar(p, 1, 0, math.random)) == "Elegí tu héroe inicial primero.", "sin inicial no se invoca")
	assert(Reclutamiento.elegirInicial(p, "thor") == "Ese no es un héroe inicial", "sólo los tres iniciales")
	assert(Reclutamiento.elegirInicial(p, "korg") == nil and p.units[1].heroId == "korg" and p.squad[1] == p.units[1].uid, "elegir inicial")
	assert(Reclutamiento.elegirInicial(p, "hawkeye") ~= nil, "no se elige dos veces")

	-- Destacados: fijos dentro de la hora, 1 estrella Legendaria/Mítica y 2 Épicos distintos.
	local d = Banner.destacados(500000)
	local d2 = Banner.destacados(500000)
	assert(d.estrella == d2.estrella and d.apoyos[1] == d2.apoyos[1], "mismos destacados en la misma hora")
	local re = Personajes.de(d.estrella).rarity
	assert(re == "Legendary" or re == "Mythic", "estrella Legendaria o Mítica")
	assert(Personajes.de(d.apoyos[1]).rarity == "Epic" and Personajes.de(d.apoyos[2]).rarity == "Epic" and d.apoyos[1] ~= d.apoyos[2], "dos apoyos Épicos")
	local distintos = 0
	for h = 1, 24 do
		if Banner.destacados(500000 + h).estrella ~= d.estrella then
			distintos += 1
		end
	end
	assert(distintos > 0, "la estrella rota con las horas")
	assert(Banner.hora(7199) == 1 and Banner.hora(7200) == 2, "hora UTC")

	-- Tirada: rareza por probabilidad y 50 % de destacado dentro de su rareza.
	local Rng = Random.new(3)
	local function azar()
		return Rng:NextNumber()
	end
	local cuenta, destacadoEpico, epicos, N = {}, 0, 0, 20000
	for _ = 1, N do
		local id = Banner.tirar(d, false, azar)
		local r = Personajes.de(id).rarity
		cuenta[r] = (cuenta[r] or 0) + 1
		if r == "Epic" then
			epicos += 1
			if id == d.apoyos[1] or id == d.apoyos[2] then
				destacadoEpico += 1
			end
		end
	end
	assert(math.abs(cuenta.Common / N - 0.48) < 0.02 and math.abs(cuenta.Rare / N - 0.30) < 0.02, "48 % comunes y 30 % raros")
	assert(math.abs(destacadoEpico / epicos - 0.5) < 0.05, `50 % de destacado entre los épicos ({destacadoEpico}/{epicos})`)
	assert(Personajes.de(Banner.tirar(d, true, function()
		return 0
	end)).rarity ~= "Common", "garantía: no común")
	local porRareza, porDestacado = Banner.probabilidades(d, false)
	-- Los pesos del 2D suman 102: Épico = 15/102.
	local epico = 15 / 102 * 100
	assert(math.abs(porRareza.Epic - epico) < 1e-6 and math.abs(porDestacado[d.apoyos[1]] - epico / 4) < 1e-6, "probabilidades mostradas")

	-- Invocar: 50 gemas, x10 a 500, inventario de 100.
	assert(select(2, Banner.invocar(p, 5, 0, azar)) == "Cantidad inválida", "sólo x1 o x10")
	local nuevas = Banner.invocar(p, 10, 0, azar)
	assert(#nuevas == 10 and p.gems == 0 and #p.units == 11, "x10 cuesta 500 y da 10 unidades")
	assert(select(2, Banner.invocar(p, 1, 0, azar)) == "Faltan 50 gemas", "sin gemas")
	assert(#p.squad == 6, "las nuevas llenan el escuadrón hasta 6")
	p.gems = 1e6
	for _ = 1, 8 do
		Banner.invocar(p, 10, 0, azar)
	end
	assert(#p.units == 91 and select(2, Banner.invocar(p, 10, 0, azar)) ~= nil, "no pasa de 100")

	-- Venta: no las del escuadrón; devuelve gemas por rareza.
	assert(select(2, Unidades.vender(p, p.squad[1])) ~= nil, "no se vende una del escuadrón")
	local fuera
	for _, u in p.units do
		if not table.find(p.squad, u.uid) then
			fuera = u
			break
		end
	end
	local antes = p.gems
	local gemas = Unidades.vender(p, fuera.uid)
	assert(gemas == Unidades.VENTA[Personajes.de(fuera.heroId).rarity] and p.gems == antes + gemas and not Unidades.buscar(p, fuera.uid), "venta")

	-- XP: 50×N por nivel, tope 50.
	local u = { level = 1, xp = 0 }
	assert(Unidades.ganarXP(u, 49) == 0 and Unidades.ganarXP(u, 1) == 1 and u.level == 2 and u.xp == 0, "nivel 2 con 50 XP")
	assert(Unidades.ganarXP(u, 100 + 150) == 2 and u.level == 4, "varios niveles de una vez")
	Unidades.ganarXP(u, 1e9)
	assert(u.level == 50 and u.xp == 0, "tope 50")
	assert(Unidades.bonoDano(50) == 1.49, "+1 % por nivel")

	-- Evolución: 3 copias + núcleos, hereda el mayor nivel y el lugar en el escuadrón.
	local q = Perfiles.normalizar({ gems = 0, cores = 0, units = { { uid = 1, heroId = "hawkeye", level = 3 }, { uid = 2, heroId = "hawkeye", level = 9 }, { uid = 5, heroId = "hawkeye" }, { uid = 7, heroId = "korg" } }, squad = { 7, 2 } })
	local costo = Unidades.NUCLEOS[ronin.rarity]
	assert(select(2, Unidades.evolucionar(q, { 1, 2 })) ~= nil, "pide 3 copias")
	assert(select(2, Unidades.evolucionar(q, { 1, 2, 7 })) == "Las copias tienen que ser del mismo personaje", "mismo personaje")
	assert(select(2, Unidades.evolucionar(q, { 1, 2, 5 })) == `Faltan {costo} núcleos`, "pide núcleos")
	q.cores = costo + 1
	local nueva = Unidades.evolucionar(q, { 1, 2, 5 })
	assert(nueva.heroId == ronin.id and nueva.level == 9 and q.cores == 1 and #q.units == 2, "evoluciona en Ronin con nivel 9")
	assert(q.squad[1] == 7 and q.squad[2] == nueva.uid, "ocupa el lugar en el escuadrón")
	assert(table.find(q.unlockedHeroIds, ronin.id) and not table.find(q.unlockedHeroIds, "hawkeye"), "lista de personajes al día")

	-- Escuadrón.
	assert(Unidades.fijarEscuadron(q, {}) ~= nil, "vacío no")
	assert(Unidades.fijarEscuadron(q, { 99 }) ~= nil, "sólo unidades propias")
	assert(Unidades.fijarEscuadron(q, { 7, 7 }) == nil and #q.squad == 1, "sin repetir la misma unidad")
	return "OK: invocaciones y unidades"
end
