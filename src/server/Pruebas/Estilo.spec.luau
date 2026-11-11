-- Monturas y bailes: lo gratis incluido, compras con gemas, rueda de 4 y guardado (docs/ESTILO.md).
-- Ejecutar en Studio: scripts/correr-pruebas.luau
return function()
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Estilo = require(Shared.Estilo)
	local Perfiles = require(script.Parent.Parent.Perfiles)

	local p = Perfiles.normalizar(nil)
	local e = p.estilo
	assert(e.montura == "patineta" and table.find(e.monturas, "patineta"), "patineta gratis equipada")
	assert(#e.rueda == 2 and table.find(e.bailes, "saludo") and table.find(e.bailes, "clasico"), "2 bailes gratis en la rueda")
	for _, b in Estilo.BAILES do
		assert(b.animacion:match("^rbxassetid://%d+$"), "animación de " .. b.id)
	end

	-- Monturas: comprar con gemas y equipar.
	p.gems = 500
	assert(Estilo.elegirMontura(p, "dragon") ~= nil and p.gems == 500, "dragón muy caro")
	assert(Estilo.elegirMontura(p, "moto") == nil and p.gems == 200 and e.montura == "moto", "compra y equipa la moto")
	assert(Estilo.elegirMontura(p, "patineta") == nil and p.gems == 200 and e.montura == "patineta", "volver a una que ya tiene no cobra")

	-- Bailes: comprar entra en la rueda; la rueda tiene 4 lugares.
	p.gems = 1000
	assert(Estilo.elegirBaile(p, "robot") == nil and p.gems == 900 and #e.rueda == 3, "robot comprado y en la rueda")
	assert(Estilo.elegirBaile(p, "victoria") == nil and #e.rueda == 4, "rueda llena")
	assert(Estilo.elegirBaile(p, "poder") == nil and p.gems == 400 and #e.rueda == 4 and not table.find(e.rueda, "poder"), "comprado pero sin lugar")
	assert(Estilo.elegirBaile(p, "poder") ~= nil, "sacá uno primero")
	assert(Estilo.elegirBaile(p, "saludo") == nil and #e.rueda == 3, "sacar de la rueda")
	assert(Estilo.elegirBaile(p, "poder") == nil and table.find(e.rueda, "poder"), "poner en la rueda")
	assert(Estilo.elegirBaile(p, "trampa") ~= nil, "baile inválido")

	-- Guardado: no se puede equipar algo no comprado.
	local copia = Perfiles.normalizar({ estilo = e })
	assert(copia.estilo.montura == "patineta" and #copia.estilo.rueda == 4, "persistencia")
	local rota = Perfiles.normalizar({ estilo = { montura = "dragon", rueda = { "giro", "saludo" }, bailes = { "hack" } } })
	assert(rota.estilo.montura == "patineta" and #rota.estilo.rueda == 1 and rota.estilo.rueda[1] == "saludo", "datos rotos")
	return "OK: monturas y bailes"
end
