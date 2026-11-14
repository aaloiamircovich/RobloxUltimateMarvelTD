-- Ajustes y tutorial (docs/TUTORIAL.md). Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Preferencias = require(game:GetService("ReplicatedStorage").Shared.Preferencias)

	local a = Preferencias.normalizarAjustes({ musica = 3, efectos = -1, calidadBaja = true, numerosDano = "no", autoSaltar = 1, extra = 5 })
	assert(a.musica == 1 and a.efectos == 0, "volúmenes entre 0 y 1")
	assert(a.calidadBaja == true and a.numerosDano == true and a.autoSaltar == false, "sólo booleanos; lo demás queda por defecto")
	assert(a.extra == nil, "no se guardan claves desconocidas")
	assert(Preferencias.normalizarAjustes({ musica = 0 / 0 }).musica == 0.6, "NaN vuelve al valor por defecto")

	local t = Preferencias.normalizarTutorial({ paso = 99, terminado = "sí" })
	assert(t.paso == Preferencias.PASOS and t.terminado == false and t.premiado == false, "tutorial normalizado")

	-- Premio: sólo con el Acto 1 ganado y una sola vez.
	local perfil = { gems = 100, acts = {}, tutorial = Preferencias.normalizarTutorial(nil) }
	assert(Preferencias.terminar(perfil) == 0 and perfil.gems == 100 and perfil.tutorial.terminado, "sin ganar el acto no hay premio")
	perfil.tutorial = Preferencias.normalizarTutorial(nil)
	perfil.acts[Preferencias.MAPA_TUTORIAL] = { normal = 1, pesadilla = 0 }
	assert(Preferencias.terminar(perfil) == 500 and perfil.gems == 600 and perfil.tutorial.premiado, "premio de 500 gemas")
	assert(Preferencias.terminar(perfil) == 0 and perfil.gems == 600, "el premio no se repite")

	local p = require(script.Parent.Parent.Perfiles).normalizar({ ajustes = { musica = 0.25 }, tutorial = { paso = 3 } })
	assert(p.ajustes.musica == 0.25 and p.tutorial.paso == 3, "el perfil guarda ajustes y tutorial")
	local Perfiles = require(script.Parent.Parent.Perfiles)
	assert(not Perfiles.normalizar(nil).tutorial.terminado, "cuenta nueva: hace el tutorial")
	local viejo = Perfiles.normalizar({ units = { { uid = 1, heroId = "hawkeye", level = 3 } } })
	assert(viejo.tutorial.terminado and viejo.tutorial.premiado, "cuenta vieja: sin tutorial ni premio")
	return "ok"
end
