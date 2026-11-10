-- Construye un mapa del 2D (grilla terrainRows + ruta en píxeles) con bloques.
local Mapa = {}

Mapa.ESCALA = 1 / 8 -- studs por píxel del 2D: una baldosa de 32 px mide 4 studs
Mapa.ORIGEN = Vector3.new(20, 0, -40)

-- W agua, B edificio, P pavimento, G pasto, M hangar metálico.
local TERRENO = {
	W = { color = Color3.fromRGB(52, 120, 190), alto = 0.6, material = Enum.Material.Glass },
	B = { color = Color3.fromRGB(150, 150, 158), alto = 2.5, material = Enum.Material.Concrete },
	P = { color = Color3.fromRGB(205, 190, 160), alto = 1, material = Enum.Material.SmoothPlastic },
	G = { color = Color3.fromRGB(96, 168, 82), alto = 1, material = Enum.Material.Grass },
	M = { color = Color3.fromRGB(72, 76, 86), alto = 1.2, material = Enum.Material.DiamondPlate },
}

-- Píxeles del 2D (x, y) → posición en el mundo sobre el suelo.
function Mapa.aMundo(x: number, y: number): Vector3
	return Mapa.ORIGEN + Vector3.new(x * Mapa.ESCALA, 1, y * Mapa.ESCALA)
end

-- Devuelve la ruta en coordenadas del mundo.
function Mapa.construir(nivel): { Vector3 }
	local viejo = workspace:FindFirstChild("Mapa")
	if viejo then
		viejo:Destroy()
	end
	local carpeta = Instance.new("Model")
	carpeta.Name = "Mapa"

	local r = nivel.rendering
	local lado = r.tileSize * Mapa.ESCALA
	for fila, texto in r.terrainRows do
		for col = 1, #texto do
			local t = TERRENO[texto:sub(col, col)] or TERRENO.G
			local p = Instance.new("Part")
			p.Anchored = true
			p.Size = Vector3.new(lado, t.alto, lado)
			p.Position = Mapa.ORIGEN + Vector3.new((col - 0.5) * lado, t.alto / 2, (fila - 0.5) * lado)
			p.Color = t.color
			p.Material = t.material
			p.TopSurface = Enum.SurfaceType.Smooth
			p.Parent = carpeta
		end
	end

	local ruta = {}
	for _, punto in nivel.path do
		table.insert(ruta, Mapa.aMundo(punto.x, punto.y))
	end

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.Size = Vector3.new(4, 6, 4)
	base.Position = ruta[#ruta] + Vector3.new(-2, 3, 0)
	base.Color = Color3.fromRGB(240, 170, 40)
	base.Material = Enum.Material.Neon
	base.Parent = carpeta

	carpeta.Parent = workspace
	return ruta
end

return Mapa
