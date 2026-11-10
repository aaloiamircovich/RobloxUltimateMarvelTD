-- Elección del héroe inicial (StarterSelection del 2D). Las invocaciones están en Shared.Banner y el
-- inventario en Shared.Unidades (docs/INVOCACIONES.md).
local Unidades = require(game:GetService("ReplicatedStorage").Shared.Unidades)

local Reclutamiento = {}

Reclutamiento.INICIALES = { "black_widow", "hawkeye", "korg" } -- RECOMMENDED_STARTER_IDS

function Reclutamiento.elegirInicial(perfil, id: string): string?
	if #perfil.units > 0 then
		return "Ya elegiste tu héroe inicial"
	end
	if not table.find(Reclutamiento.INICIALES, id) then
		return "Ese no es un héroe inicial"
	end
	Unidades.agregar(perfil, id)
	return nil
end

return Reclutamiento
