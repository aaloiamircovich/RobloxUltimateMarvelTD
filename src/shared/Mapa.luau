-- Mapa de un nivel del 2D (grilla terrainRows + ruta en píxeles) y conversión píxeles ↔ mundo.
-- El cliente usa sólo las conversiones; construir() corre en el servidor.
local Mapa = {}

Mapa.ESCALA = 1 / 8 -- studs por píxel del 2D: una baldosa de 32 px mide 4 studs
Mapa.ORIGEN = Vector3.new(300, 0, -40) -- lejos del HUB, que está en el centro
Mapa.ANCHO, Mapa.ALTO = 800, 600 -- tamaño lógico del 2D (combat-data.js)

-- W agua, B edificio, P pavimento, G pasto, M hangar (Montaña en las reglas).
local TERRENO = {
	W = { color = Color3.fromRGB(52, 120, 190), alto = 0.6, material = Enum.Material.Glass },
	B = { color = Color3.fromRGB(150, 150, 158), alto = 2.5, material = Enum.Material.Concrete },
	P = { color = Color3.fromRGB(205, 190, 160), alto = 1, material = Enum.Material.SmoothPlastic },
	G = { color = Color3.fromRGB(96, 168, 82), alto = 1, material = Enum.Material.Grass },
	M = { color = Color3.fromRGB(72, 76, 86), alto = 1.2, material = Enum.Material.DiamondPlate },
}

function Mapa.aMundo(x: number, y: number): Vector3
	return Mapa.ORIGEN + Vector3.new(x * Mapa.ESCALA, 1, y * Mapa.ESCALA)
end

function Mapa.aPixeles(p: Vector3): (number, number)
	local d = (p - Mapa.ORIGEN) / Mapa.ESCALA
	return d.X, d.Z
end

-- normalizePath del 2D: ruta ortogonal con un punto de entrada y otro de salida fuera del mapa.
function Mapa.rutaPixeles(nivel): { { x: number, y: number } }
	local margen, ancho, alto = 40, Mapa.ANCHO, Mapa.ALTO
	local function fuera(p)
		if p.x <= 0 then
			return { x = -margen, y = p.y }
		elseif p.x >= ancho then
			return { x = ancho + margen, y = p.y }
		elseif p.y <= 0 then
			return { x = p.x, y = -margen }
		elseif p.y >= alto then
			return { x = p.x, y = alto + margen }
		end
		return { x = p.x, y = p.y }
	end
	local dentro = {}
	for _, p in nivel.path do
		table.insert(dentro, { x = math.clamp(p.x, 0, ancho), y = math.clamp(p.y, 0, alto) })
	end
	local ruta = { fuera(dentro[1]), dentro[1] }
	for i = 2, #dentro do
		local prev, sig = ruta[#ruta], dentro[i]
		if prev.x ~= sig.x and prev.y ~= sig.y then
			table.insert(ruta, { x = sig.x, y = prev.y })
		end
		table.insert(ruta, sig)
	end
	table.insert(ruta, fuera(dentro[#dentro]))
	local limpia = {}
	for _, p in ruta do
		local u = limpia[#limpia]
		if not u or u.x ~= p.x or u.y ~= p.y then
			table.insert(limpia, p)
		end
	end
	return limpia
end

-- Construye el terreno y devuelve la ruta en coordenadas del mundo.
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
	for _, punto in Mapa.rutaPixeles(nivel) do
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
