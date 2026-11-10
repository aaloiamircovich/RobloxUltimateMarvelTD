-- Compara Progresion con progresion_2d.json (scripts/referencia-progresion.mjs): costos 1→100 y stats
-- de los 105 héroes en 12 niveles.
-- Ejecutar en Studio: require(game.ServerScriptService.Server.Pruebas["Progresion.spec"])()
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Progresion = require(Shared.Progresion)
	local heroes = require(Shared.Data.heroes)
	local ref = require(script.Parent.progresion_2d)

	local fallos = {}
	for nivel, esperado in ref.costos do
		if Progresion.costo(nivel) ~= esperado then
			table.insert(fallos, `costo nivel {nivel}: {Progresion.costo(nivel)} ≠ {esperado}`)
		end
	end
	assert(Progresion.costo(100) == nil, "nivel 100 no debería tener costo")

	local campos = { "damage", "fireRate", "range", "critChance" }
	for _, fila in ref.stats do
		local s = Progresion.stats(heroes[fila[1]], fila[2])
		for k, campo in campos do
			if math.abs(s[campo] - fila[k + 2]) > 1e-3 then
				table.insert(fallos, `{fila[1]} nivel {fila[2]} {campo}: {s[campo]} ≠ {fila[k + 2]}`)
			end
		end
		if (if s.canSeeStealth then 1 else 0) ~= fila[7] then
			table.insert(fallos, `{fila[1]} nivel {fila[2]} sigilo distinto`)
		end
	end
	if #fallos > 0 then
		error(`{#fallos} diferencias con el 2D:\n` .. table.concat(fallos, "\n", 1, math.min(#fallos, 15)))
	end
	return `OK: {#ref.costos} costos y {#ref.stats} stats idénticos al 2D`
end
