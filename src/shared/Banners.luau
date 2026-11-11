-- Banner 2 (docs/INVOCACIONES.md): un Mítico destacado que cambia cada 3 horas, pagado con fichas de raid,
-- con garantía. El Banner 3 está reservado para otras monedas (próximamente). Módulo puro: hora y azar por parámetro.
local Personajes = require(script.Parent.Personajes)
local Unidades = require(script.Parent.Unidades)

local Banners = {}

Banners.PERIODO = 3 * 3600 -- el destacado cambia cada 3 horas (igual en todos los servidores)
Banners.LIMITADO = {
	costo = 10, -- fichas de raid por tirada
	prob = { Common = 20, Rare = 40, Epic = 26, Legendary = 10, Mythic = 4 },
	parteDestacado = 0.75, -- de los Míticos, el 75 % es el destacado (3 % por tirada)
	garantia = 80, -- tiradas sin el destacado: la siguiente lo da (el contador se conserva al rotar)
}

function Banners.periodo(t: number): number
	return t // Banners.PERIODO
end

-- Mítico destacado del período (rota por la lista de Míticos invocables).
function Banners.destacado(periodo: number): string
	local miticos = Personajes.invocables().Mythic
	return miticos[periodo % #miticos + 1]
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

-- Tira el Banner 2. Devuelve las unidades nuevas o (nil, motivo).
function Banners.limitado(perfil, cantidad: number, t: number, azar: () -> number)
	if cantidad ~= 1 and cantidad ~= 10 then
		return nil, "Cantidad inválida"
	end
	if #perfil.units == 0 then
		return nil, "Elegí tu héroe inicial primero."
	end
	if #perfil.units + cantidad > Unidades.MAX_INVENTARIO then
		return nil, `Inventario lleno ({#perfil.units}/{Unidades.MAX_INVENTARIO}): vendé unidades`
	end
	local L = Banners.LIMITADO
	local costo = L.costo * cantidad
	if (perfil.fichasRaid or 0) < costo then
		return nil, `Faltan {costo - (perfil.fichasRaid or 0)} fichas de raid`
	end
	perfil.fichasRaid -= costo
	local destacado = Banners.destacado(Banners.periodo(t))
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
				if #resto == 0 then
					resto = pozo[r]
				end
				id = resto[math.floor(azar() * #resto) + 1]
			end
		end
		perfil.shop.limitadoPity = if id == destacado then 0 else perfil.shop.limitadoPity + 1
		table.insert(nuevas, Unidades.agregar(perfil, id))
	end
	return nuevas, nil
end

-- Lo que muestra el panel.
function Banners.resumen(perfil, t: number)
	return {
		destacado = Banners.destacado(Banners.periodo(t)),
		costo = Banners.LIMITADO.costo,
		prob = Banners.LIMITADO.prob,
		parteDestacado = Banners.LIMITADO.parteDestacado,
		garantia = Banners.LIMITADO.garantia,
		pity = perfil.shop.limitadoPity,
		fichasRaid = perfil.fichasRaid or 0,
		cambiaEn = Banners.PERIODO - t % Banners.PERIODO,
	}
end

return Banners
