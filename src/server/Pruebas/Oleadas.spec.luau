-- Compara Oleadas.preparar con oleadas_2d.json (generado por scripts/referencia-oleadas.mjs).
-- Ejecutar en Studio: require(game.ServerScriptService.Server.Pruebas["Oleadas.spec"])()
return function()
	local RS = game:GetService("ReplicatedStorage")
	local Oleadas = require(RS.Shared.Oleadas)
	local Data = RS.Shared.Data
	local enemigos, niveles, heroes = require(Data.enemies), require(Data.levels), require(Data.heroes)
	local casos = require(script.Parent.oleadas_2d)

	local fallos = {}
	for _, caso in casos do
		local equipo = {}
		for _, id in caso.equipo do
			table.insert(equipo, heroes[id])
		end
		local cola, mod = Oleadas.preparar(caso.oleada, enemigos, niveles[caso.nivel], caso.nivel - 1, equipo, caso.modo)
		local etiqueta = `mapa {caso.nivel} {caso.modo} oleada {caso.oleada} equipo [{table.concat(caso.equipo, ",")}]`
		if mod.id ~= caso.modificador then
			table.insert(fallos, `{etiqueta}: modificador {mod.id} ≠ {caso.modificador}`)
		end
		if #cola ~= #caso.cola then
			table.insert(fallos, `{etiqueta}: {#cola} enemigos ≠ {#caso.cola}`)
		else
			for i, esperado in caso.cola do
				local e, espera = cola[i].enemigo, cola[i].espera
				local obtenido = { e.id, e.hp, e.speed, e.reward, e.armor, if e.stealth then 1 else 0, espera }
				for k = 1, 7 do
					local igual = if type(esperado[k]) == "string" then obtenido[k] == esperado[k] else math.abs(obtenido[k] - esperado[k]) < 1e-3
					if not igual then
						table.insert(fallos, `{etiqueta} #{i} campo {k}: {obtenido[k]} ≠ {esperado[k]}`)
						break
					end
				end
			end
		end
	end
	if #fallos > 0 then
		error(`{#fallos} diferencias con el 2D:\n` .. table.concat(fallos, "\n", 1, math.min(#fallos, 15)))
	end
	return `OK: {#casos} oleadas idénticas al 2D`
end
