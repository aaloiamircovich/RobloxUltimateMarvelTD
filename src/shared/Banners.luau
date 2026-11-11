-- Banners 2 y 3 (docs/INVOCACIONES.md). Banner 2: limitado semanal con un Mítico destacado y garantía.
-- Banner 3: invocación normal pagada con las fichas del desafío semanal. Módulo puro: hora y azar por parámetro.
local Personajes = require(script.Parent.Personajes)
local Unidades = require(script.Parent.Unidades)
local Banner = require(script.Parent.Banner)
local Evento = require(script.Parent.Evento)

local Banners = {}

Banners.LIMITADO = {
	costo = 80, -- gemas por tirada
	prob = { Common = 20, Rare = 40, Epic = 26, Legendary = 10, Mythic = 4 },
	parteDestacado = 0.75, -- de los Míticos, el 75 % es el destacado (3 % por tirada)
	garantia = 80, -- tiradas sin el destacado: la siguiente lo da (el contador sigue entre semanas)
}
Banners.FICHAS = { costo = 30 } -- fichas del desafío por tirada; probabilidades del Banner 1, sin destacados

-- Mítico destacado de la semana (rota por la lista de Míticos invocables).
function Banners.destacado(semana: number): string
	local miticos = Personajes.invocables().Mythic
	return miticos[semana % #miticos + 1]
end

local function rareza(prob, azar: () -> number): string
	local pozo = Personajes.invocables()
	local total = 0
	for r, p in prob do
		if pozo[r] then
			total += p
		end
	end
	local t = azar() * total
	for _, r in Personajes.RAREZAS do
		if pozo[r] and prob[r] then
			t -= prob[r]
			if t < 0 then
				return r
			end
		end
	end
	return "Rare"
end

local function alAzar(lista, azar: () -> number)
	return lista[math.floor(azar() * #lista) + 1]
end

local function validar(perfil, cantidad: number): string?
	if cantidad ~= 1 and cantidad ~= 10 then
		return "Cantidad inválida"
	end
	if #perfil.units == 0 then
		return "Elegí tu héroe inicial primero."
	end
	if #perfil.units + cantidad > Unidades.MAX_INVENTARIO then
		return `Inventario lleno ({#perfil.units}/{Unidades.MAX_INVENTARIO}): vendé unidades`
	end
	return nil
end

-- Banner 2. Devuelve las unidades nuevas o (nil, motivo).
function Banners.limitado(perfil, cantidad: number, semana: number, azar: () -> number)
	local err = validar(perfil, cantidad)
	if err then
		return nil, err
	end
	local L = Banners.LIMITADO
	local costo = L.costo * cantidad
	if perfil.gems < costo then
		return nil, `Faltan {costo - perfil.gems} gemas`
	end
	perfil.gems -= costo
	local destacado = Banners.destacado(semana)
	local pozo = Personajes.invocables()
	local nuevas = {}
	for _ = 1, cantidad do
		local id
		if perfil.shop.limitadoPity + 1 >= L.garantia then
			id = destacado
		else
			local r = rareza(L.prob, azar)
			if r == "Mythic" and azar() < L.parteDestacado then
				id = destacado
			else
				local resto = {}
				for _, x in pozo[r] do
					if x ~= destacado then
						table.insert(resto, x)
					end
				end
				id = alAzar(if #resto > 0 then resto else pozo[r], azar)
			end
		end
		perfil.shop.limitadoPity = if id == destacado then 0 else perfil.shop.limitadoPity + 1
		table.insert(nuevas, Unidades.agregar(perfil, id))
	end
	return nuevas, nil
end

-- Banner 3: se paga con fichas del desafío semanal (vencen el lunes).
function Banners.fichas(perfil, cantidad: number, t: number, azar: () -> number)
	local err = validar(perfil, cantidad)
	if err then
		return nil, err
	end
	local e = Evento.actualizar(perfil, t)
	local costo = Banners.FICHAS.costo * cantidad
	if e.fichas < costo then
		return nil, `Faltan {costo - e.fichas} fichas del desafío`
	end
	e.fichas -= costo
	local pozo = Personajes.invocables()
	local nuevas = {}
	for _ = 1, cantidad do
		table.insert(nuevas, Unidades.agregar(perfil, alAzar(pozo[rareza(Banner.PROB, azar)], azar)))
	end
	return nuevas, nil
end

-- Lo que muestra el panel.
function Banners.resumen(perfil, t: number)
	local semana = Evento.semana(t)
	local e = Evento.actualizar(perfil, t)
	return {
		destacado = Banners.destacado(semana),
		costoLimitado = Banners.LIMITADO.costo,
		probLimitado = Banners.LIMITADO.prob,
		parteDestacado = Banners.LIMITADO.parteDestacado,
		garantia = Banners.LIMITADO.garantia,
		pity = perfil.shop.limitadoPity,
		costoFichas = Banners.FICHAS.costo,
		probFichas = Banner.PROB,
		fichas = e.fichas,
		gemas = perfil.gems,
		finSemana = 7 * 86400 - (t - 4 * 86400) % (7 * 86400),
	}
end

return Banners
