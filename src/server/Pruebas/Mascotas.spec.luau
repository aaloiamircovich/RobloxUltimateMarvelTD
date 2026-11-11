-- Mascotas: huevos, equipar hasta 3, fusión en dorada, bonos y guardado (docs/MASCOTAS.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Mascotas = require(Shared.Mascotas)
	local Perfiles = require(script.Parent.Parent.Perfiles)

	for _, h in Mascotas.HUEVOS do
		local total = 0
		for _, r in Mascotas.RAREZAS do
			total += h.prob[r] or 0
		end
		assert(total == 100, "probabilidades del " .. h.nombre)
	end

	local p = Perfiles.normalizar(nil)
	p.gems = 1000
	local comun = function()
		return 0
	end
	local a = Mascotas.abrir(p, "basico", comun)
	assert(a and a.id == "dron" and p.gems == 900, "huevo básico: común")
	local mitica = Mascotas.abrir(p, "cosmico", function()
		return 0.999
	end)
	assert(mitica.id == "fenix" and p.gems == 600, "huevo cósmico: mítica")
	assert(select(2, Mascotas.abrir(p, "trampa", comun)) ~= nil, "huevo inválido")
	p.gems = 50
	assert(select(2, Mascotas.abrir(p, "basico", comun)) ~= nil, "sin gemas")

	-- Equipar hasta 3 y bonos sumados.
	p.gems = 1000
	local b = Mascotas.abrir(p, "basico", comun)
	local c = Mascotas.abrir(p, "basico", comun)
	local d = Mascotas.abrir(p, "basico", comun)
	for _, x in { a, mitica, b } do
		assert(Mascotas.equipar(p, x.uid) == nil, "equipar")
	end
	assert(Mascotas.equipar(p, c.uid) ~= nil, "máximo 3")
	local bonos = Mascotas.bonos(p)
	assert(math.abs(bonos.dinero - (0.05 * 2 + 0.12)) < 1e-9 and math.abs(bonos.dano - 0.12) < 1e-9, "bonos sumados")

	-- Fusión: 4 drones (2 equipados); usa primero los no equipados y la dorada queda equipada si usó uno equipado.
	local dorada = Mascotas.fusionar(p, a.uid)
	assert(dorada and dorada.dorada and dorada.id == "dron", "fusión en dorada")
	local drones = 0
	for _, x in p.mascotas.lista do
		if x.id == "dron" and not x.dorada then
			drones += 1
		end
	end
	assert(drones == 1, "quedó 1 dron normal")
	assert(table.find(p.mascotas.equipadas, dorada.uid), "la dorada reemplaza al equipado")
	-- Equipadas: fénix (0,12) + dron (0,05) + dron dorado (0,10).
	assert(math.abs(Mascotas.bonos(p).dinero - 0.27) < 1e-9, "dorada ×2")
	assert(select(2, Mascotas.fusionar(p, dorada.uid)) ~= nil, "una dorada no se vuelve a fusionar")
	assert(Mascotas.texto(p):find("dron:1"), "texto para dibujar")

	-- Guardado.
	local copia = Perfiles.normalizar({ mascotas = p.mascotas })
	assert(#copia.mascotas.lista == #p.mascotas.lista and #copia.mascotas.equipadas == #p.mascotas.equipadas, "persistencia")
	local rota = Perfiles.normalizar({ mascotas = { lista = { { uid = 1, id = "hack" }, { uid = 2, id = "dron" } }, equipadas = { 1, 2, 2 } } })
	assert(#rota.mascotas.lista == 1 and #rota.mascotas.equipadas == 1 and rota.mascotas.siguiente == 3, "datos rotos")
	return "OK: mascotas"
end
