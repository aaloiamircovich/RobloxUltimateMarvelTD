-- Monturas y bailes (docs/ESTILO.md): cosméticos que se compran con gemas. Las monturas aumentan la velocidad
-- al caminar (lobby y mapas), los bailes se equipan en una rueda de 4. Sistema propio del port; módulo puro.
local Estilo = {}

Estilo.VELOCIDAD_BASE = 16
Estilo.MONTURAS = {
	{ id = "patineta", nombre = "Patineta flotante", precio = 0, velocidad = 1.5 },
	{ id = "moto", nombre = "Moto a reacción", precio = 300, velocidad = 1.7 },
	{ id = "disco", nombre = "Disco cósmico", precio = 600, velocidad = 1.9 },
	{ id = "pantera", nombre = "Pantera de vibranium", precio = 1000, velocidad = 2.0 },
	{ id = "dragon", nombre = "Dragón de fuego", precio = 1500, velocidad = 2.2 },
}
-- animacion: id del asset (los 2 gratis son emotes públicos de Roblox; los otros, generados).
Estilo.BAILES = {
	{ id = "saludo", nombre = "Saludo", precio = 0, animacion = "rbxassetid://507770239" },
	{ id = "clasico", nombre = "Paso clásico", precio = 0, animacion = "rbxassetid://507771019" },
	{ id = "robot", nombre = "Robot", precio = 100, animacion = "rbxassetid://104185003547683" },
	{ id = "victoria", nombre = "¡Victoria!", precio = 200, animacion = "rbxassetid://118656636666654" },
	{ id = "poder", nombre = "Pose de poder", precio = 300, animacion = "rbxassetid://139760743413828" },
	{ id = "giro", nombre = "Giro cósmico", precio = 400, animacion = "rbxassetid://73201221556654" },
}
Estilo.RUEDA = 4
local MONTURA, BAILE = {}, {}
for _, m in Estilo.MONTURAS do
	MONTURA[m.id] = m
end
for _, b in Estilo.BAILES do
	BAILE[b.id] = b
end

function Estilo.montura(id: string?)
	return id and MONTURA[id]
end
function Estilo.baile(id: string?)
	return id and BAILE[id]
end

-- Lo gratis viene incluido: patineta equipada y los 2 bailes gratis en la rueda.
function Estilo.nuevo()
	local e = { monturas = {}, montura = "patineta", bailes = {}, rueda = {} }
	for _, m in Estilo.MONTURAS do
		if m.precio == 0 then
			table.insert(e.monturas, m.id)
		end
	end
	for _, b in Estilo.BAILES do
		if b.precio == 0 then
			table.insert(e.bailes, b.id)
			table.insert(e.rueda, b.id)
		end
	end
	return e
end

-- Frontera de confianza: lo que viene del DataStore.
function Estilo.normalizar(crudo)
	local e = Estilo.nuevo()
	if type(crudo) ~= "table" then
		return e
	end
	for _, campo in { { "monturas", MONTURA }, { "bailes", BAILE } } do
		if type(crudo[campo[1]]) == "table" then
			for _, id in crudo[campo[1]] do
				if campo[2][id] and not table.find(e[campo[1]], id) then
					table.insert(e[campo[1]], id)
				end
			end
		end
	end
	if table.find(e.monturas, crudo.montura) then
		e.montura = crudo.montura
	end
	if type(crudo.rueda) == "table" then
		e.rueda = {}
		for _, id in crudo.rueda do
			if table.find(e.bailes, id) and not table.find(e.rueda, id) and #e.rueda < Estilo.RUEDA then
				table.insert(e.rueda, id)
			end
		end
	end
	return e
end

-- Compra (si no la tiene) o equipa la montura.
function Estilo.elegirMontura(perfil, id: string): string?
	local m = MONTURA[id]
	local e = perfil.estilo
	if not m then
		return "Montura inválida"
	end
	if not table.find(e.monturas, id) then
		if perfil.gems < m.precio then
			return `Faltan {m.precio - perfil.gems} gemas`
		end
		perfil.gems -= m.precio
		table.insert(e.monturas, id)
	end
	e.montura = id
	return nil
end

-- Compra el baile (si no lo tiene) o lo pone/saca de la rueda.
function Estilo.elegirBaile(perfil, id: string): string?
	local b = BAILE[id]
	local e = perfil.estilo
	if not b then
		return "Baile inválido"
	end
	if not table.find(e.bailes, id) then
		if perfil.gems < b.precio then
			return `Faltan {b.precio - perfil.gems} gemas`
		end
		perfil.gems -= b.precio
		table.insert(e.bailes, id)
		if #e.rueda < Estilo.RUEDA then
			table.insert(e.rueda, id)
		end
		return nil
	end
	local i = table.find(e.rueda, id)
	if i then
		table.remove(e.rueda, i)
	elseif #e.rueda >= Estilo.RUEDA then
		return `La rueda tiene lugar para {Estilo.RUEDA}: sacá uno primero`
	else
		table.insert(e.rueda, id)
	end
	return nil
end

return Estilo
