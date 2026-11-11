-- Personajes exclusivos: Odin (pase) y Knull (raid). Datos, que no salgan en banners, habilidades y canje (docs/EXCLUSIVOS.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Personajes = require(Shared.Personajes)
	local Kits = require(Shared.Kits)
	local Mejoras = require(Shared.Mejoras)
	local Raid = require(Shared.Raid)
	local Temporada = require(Shared.Temporada)
	local Progresion = require(Shared.Progresion)
	local Perfiles = require(script.Parent.Parent.Perfiles)

	for _, id in { "odin", "knull" } do
		local h = Personajes.de(id)
		assert(h and h.rarity == "Secret" and h.exclusivo, id .. " existe y es Secreto")
		assert(Mejoras.costoColocar(h) > 0 and #Mejoras.lista(h) == Mejoras.MAXIMO, id .. " tiene costo y mejoras")
		assert(Progresion.stats(h, 1, nil, 20, true).damage > 0, id .. " tiene stats de combate")
		for _, lista in Personajes.invocables() do
			assert(not table.find(lista, id), id .. " no sale en los banners")
		end
	end
	assert(Temporada.premio(1, 50).id == "odin" and Raid.EXCLUSIVA == "knull", "premios conectados")

	-- Habilidades: Odin cada 3 ataques a blanco + 4; Knull cada 4 a blanco + 6, con ralentización.
	local function enemigo(x)
		return { e = { vida = 100, estados = {}, config = {} }, x = x, y = 0 }
	end
	local enemigos = {}
	for i = 0, 9 do
		table.insert(enemigos, enemigo(i * 20))
	end
	local heroe = { x = 0, y = 0, alcance = 500, ve = true }
	local odin = Kits.nuevo("odin")
	local stats = { damage = 100 }
	assert(#Kits.alAtacar(odin, Personajes.de("odin"), stats, 1, enemigos[1].e, heroe, enemigos) == 0, "ataque 1 sin habilidad")
	Kits.alAtacar(odin, Personajes.de("odin"), stats, 1, enemigos[1].e, heroe, enemigos)
	local g = Kits.alAtacar(odin, Personajes.de("odin"), stats, 1, enemigos[1].e, heroe, enemigos)
	assert(#g == 5 and math.abs(g[1].golpe.dano - 70) < 1e-9, "Gungnir: blanco + 4 a 70 %")
	local knull = Kits.nuevo("knull")
	for _ = 1, 3 do
		Kits.alAtacar(knull, Personajes.de("knull"), stats, 1, enemigos[1].e, heroe, enemigos)
	end
	g = Kits.alAtacar(knull, Personajes.de("knull"), stats, 1, enemigos[1].e, heroe, enemigos)
	-- A 100 px del blanco (x = 0) hay 5 enemigos (20, 40, 60, 80, 100).
	assert(#g == 6 and g[2].efecto.type == "slow", "Rey del vacío: blanco + 5 cercanos, con ralentización")

	-- Canje de Knull por 100 fragmentos.
	local p = Perfiles.normalizar({ units = { { uid = 1, heroId = "hawkeye" } } })
	local T = Temporada.INICIO + 3600
	assert(select(2, Raid.canjear(p, T)) ~= nil, "faltan fragmentos")
	Raid.actualizar(p, T)
	p.raid.fragmentos = 130
	local u = Raid.canjear(p, T)
	assert(u and u.heroId == "knull" and p.raid.fragmentos == 30, "canje: Knull y sobran 30")
	return "OK: exclusivos"
end
