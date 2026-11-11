-- Mascotas (docs/MASCOTAS.md): huevos con gemas, hasta 3 equipadas con bonos pasivos y fusión en dorada.
-- Sistema propio del port, con criaturas originales. Módulo puro: el azar entra como parámetro.
local Mascotas = {}

Mascotas.MAX_EQUIPADAS = 3
Mascotas.MAX_INVENTARIO = 50
Mascotas.COPIAS_FUSION = 3
Mascotas.FACTOR_DORADA = 2
-- Bonos en fracción: dinero (de partida), xp (de cuenta y unidades), gemas (de premios), dano (de tus unidades).
Mascotas.LISTA = {
	{ id = "dron", nombre = "Dron-robot", rareza = "Común", dinero = 0.05 },
	{ id = "gatito", nombre = "Gatito cósmico", rareza = "Común", xp = 0.08 },
	{ id = "golem", nombre = "Golem de piedra", rareza = "Raro", dano = 0.03 },
	{ id = "buho", nombre = "Búho místico", rareza = "Raro", gemas = 0.05 },
	{ id = "pulpo", nombre = "Pulpo alienígena", rareza = "Épico", dinero = 0.12 },
	{ id = "lobo", nombre = "Lobo de vibranium", rareza = "Épico", dano = 0.06 },
	{ id = "dragon", nombre = "Dragoncito de fuego", rareza = "Legendario", dano = 0.10 },
	{ id = "fenix", nombre = "Fénix", rareza = "Mítico", dano = 0.12, dinero = 0.12, gemas = 0.10 },
}
local MASCOTA = {}
for _, m in Mascotas.LISTA do
	MASCOTA[m.id] = m
end
Mascotas.RAREZAS = { "Común", "Raro", "Épico", "Legendario", "Mítico" }
-- Probabilidad (%) de cada rareza por huevo; dentro de la rareza, todas por igual.
Mascotas.HUEVOS = {
	{ id = "basico", nombre = "Huevo básico", precio = 100, prob = { ["Común"] = 60, Raro = 30, ["Épico"] = 9, Legendario = 1, ["Mítico"] = 0 } },
	{ id = "cosmico", nombre = "Huevo cósmico", precio = 300, prob = { ["Común"] = 25, Raro = 40, ["Épico"] = 25, Legendario = 8, ["Mítico"] = 2 } },
}
local HUEVO = {}
for _, h in Mascotas.HUEVOS do
	HUEVO[h.id] = h
end
Mascotas.BONOS = { "dinero", "xp", "gemas", "dano" }

function Mascotas.de(id: string?)
	return id and MASCOTA[id]
end

function Mascotas.nuevo()
	return { lista = {}, equipadas = {}, siguiente = 1 }
end

-- Frontera de confianza: lo que viene del DataStore.
function Mascotas.normalizar(crudo)
	local m = Mascotas.nuevo()
	if type(crudo) ~= "table" then
		return m
	end
	local usados = {}
	if type(crudo.lista) == "table" then
		for _, x in crudo.lista do
			local uid = type(x) == "table" and tonumber(x.uid)
			if uid and uid == math.floor(uid) and uid > 0 and not usados[uid] and MASCOTA[x.id] and #m.lista < Mascotas.MAX_INVENTARIO then
				usados[uid] = true
				table.insert(m.lista, { uid = uid, id = x.id, dorada = x.dorada == true })
				m.siguiente = math.max(m.siguiente, uid + 1)
			end
		end
	end
	if type(crudo.equipadas) == "table" then
		for _, uid in crudo.equipadas do
			if usados[uid] and not table.find(m.equipadas, uid) and #m.equipadas < Mascotas.MAX_EQUIPADAS then
				table.insert(m.equipadas, uid)
			end
		end
	end
	return m
end

local function buscar(m, uid)
	for i, x in m.lista do
		if x.uid == uid then
			return x, i
		end
	end
	return nil, nil
end

-- Abre un huevo pagando gemas. Devuelve la mascota nueva o un error.
function Mascotas.abrir(perfil, huevoId: string, azar: () -> number): (any?, string?)
	local h = HUEVO[huevoId]
	local m = perfil.mascotas
	if not h then
		return nil, "Huevo inválido"
	end
	if #m.lista >= Mascotas.MAX_INVENTARIO then
		return nil, "Inventario de mascotas lleno (fusioná o soltá alguna)"
	end
	if perfil.gems < h.precio then
		return nil, `Faltan {h.precio - perfil.gems} gemas`
	end
	perfil.gems -= h.precio
	local t, rareza = azar() * 100, Mascotas.RAREZAS[1]
	for _, r in Mascotas.RAREZAS do
		t -= h.prob[r] or 0
		if t < 0 then
			rareza = r
			break
		end
	end
	local pozo = {}
	for _, x in Mascotas.LISTA do
		if x.rareza == rareza then
			table.insert(pozo, x.id)
		end
	end
	local nueva = { uid = m.siguiente, id = pozo[math.floor(azar() * #pozo) + 1], dorada = false }
	m.siguiente += 1
	table.insert(m.lista, nueva)
	return nueva, nil
end

-- Equipa o desequipa (hasta 3).
function Mascotas.equipar(perfil, uid: number): string?
	local m = perfil.mascotas
	if not buscar(m, uid) then
		return "Mascota inválida"
	end
	local i = table.find(m.equipadas, uid)
	if i then
		table.remove(m.equipadas, i)
	elseif #m.equipadas >= Mascotas.MAX_EQUIPADAS then
		return `Podés equipar hasta {Mascotas.MAX_EQUIPADAS}`
	else
		table.insert(m.equipadas, uid)
	end
	return nil
end

-- Fusiona 3 copias normales de la mascota de `uid` en una dorada (prefiere las no equipadas).
function Mascotas.fusionar(perfil, uid: number): (any?, string?)
	local m = perfil.mascotas
	local base = buscar(m, uid)
	if not base or base.dorada then
		return nil, "Elegí una mascota normal"
	end
	local copias = {}
	for _, equipada in { false, true } do
		for _, x in m.lista do
			if #copias < Mascotas.COPIAS_FUSION and x.id == base.id and not x.dorada and (table.find(m.equipadas, x.uid) ~= nil) == equipada then
				table.insert(copias, x)
			end
		end
	end
	if #copias < Mascotas.COPIAS_FUSION then
		return nil, `Necesitás {Mascotas.COPIAS_FUSION} copias de {MASCOTA[base.id].nombre}`
	end
	local estabaEquipada = false
	for _, x in copias do
		local _, i = buscar(m, x.uid)
		table.remove(m.lista, i)
		local e = table.find(m.equipadas, x.uid)
		if e then
			table.remove(m.equipadas, e)
			estabaEquipada = true
		end
	end
	local dorada = { uid = m.siguiente, id = base.id, dorada = true }
	m.siguiente += 1
	table.insert(m.lista, dorada)
	if estabaEquipada then
		table.insert(m.equipadas, dorada.uid)
	end
	return dorada, nil
end

-- Suma de bonos de las equipadas (las doradas cuentan ×2).
function Mascotas.bonos(perfil)
	local b = { dinero = 0, xp = 0, gemas = 0, dano = 0 }
	local m = perfil.mascotas
	for _, uid in m.equipadas do
		local x = buscar(m, uid)
		local datos = x and MASCOTA[x.id]
		if datos then
			for _, k in Mascotas.BONOS do
				b[k] += (datos[k] or 0) * (if x.dorada then Mascotas.FACTOR_DORADA else 1)
			end
		end
	end
	return b
end

-- Equipadas como texto "id:dorada,..." para que los clientes dibujen las mascotas que siguen al jugador.
function Mascotas.texto(perfil): string
	local partes = {}
	for _, uid in perfil.mascotas.equipadas do
		local x = buscar(perfil.mascotas, uid)
		if x then
			table.insert(partes, `{x.id}:{if x.dorada then 1 else 0}`)
		end
	end
	return table.concat(partes, ",")
end

function Mascotas.descripcion(id: string, dorada: boolean?): string
	local d = MASCOTA[id]
	local f = if dorada then Mascotas.FACTOR_DORADA else 1
	local nombres = { dinero = "dinero", xp = "XP", gemas = "gemas", dano = "daño" }
	local partes = {}
	for _, k in Mascotas.BONOS do
		if d[k] then
			table.insert(partes, `+{math.floor(d[k] * f * 100 + 0.5)}% {nombres[k]}`)
		end
	end
	return table.concat(partes, ", ")
end

return Mascotas
