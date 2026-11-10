-- Arco de bloques estilo Roblox, armado con piezas (la IA de mallas lo generaba doble y torcido).
-- Espacio local: Y arriba, el arco se curva hacia -Z (frente del personaje), la cuerda queda en Z = 0.
local Arco = {}

local NEGRO = Color3.fromRGB(30, 30, 36)
local VIOLETA = Color3.fromRGB(130, 60, 220)

local function bloque(nombre, tamano, cframe, color, padre)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.Massless = true
	p.Parent = padre
	return p
end

-- Devuelve un Model cuyo PrimaryPart "Empunadura" está en el origen; el resto va soldado a ella.
function Arco.crear(altura: number?, profundidad: number?): Model
	local h = (altura or 3) / 2
	local d = profundidad or 0.8
	local modelo = Instance.new("Model")
	modelo.Name = "Arco"
	local empunadura = bloque("Empunadura", Vector3.new(0.24, 0.5, 0.24), CFrame.new(0, 0, -d), VIOLETA, modelo)
	modelo.PrimaryPart = empunadura

	local pasos = 7
	for i = -pasos, pasos do
		if i ~= 0 then
			local y = i / pasos * h
			local z = -d * (1 - (y / h) ^ 2)
			local punta = math.abs(i) == pasos
			local b = bloque("Pala", Vector3.new(0.18, h / pasos + 0.04, 0.18), CFrame.new(0, y, z), punta and VIOLETA or NEGRO, modelo)
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1, w.Parent = empunadura, b, b
		end
	end

	local cuerda = bloque("Cuerda", Vector3.new(0.04, 2 * h, 0.04), CFrame.new(0, 0, 0), Color3.new(1, 1, 1), modelo)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1, w.Parent = empunadura, cuerda, cuerda

	-- Mover el pivote a la empuñadura para posicionar con PivotTo.
	modelo.WorldPivot = empunadura.CFrame
	return modelo
end

return Arco
