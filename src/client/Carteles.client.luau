-- Placas del lobby (docs/INTERFAZ.md, 19/11/2026): aparecen y desaparecen con fundido según la distancia a la
-- cámara. VerHasta: se ve de cerca (puestos, salas, hitos). VerDesde: se ve de lejos y se apaga al llegar (islas).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local jugador = Players.LocalPlayer

local placas = {} -- [BillboardGui] = { [objeto] = { propiedad = transparencia base } }

local PROPIEDADES = {
	TextLabel = { "TextTransparency", "BackgroundTransparency" },
	Frame = { "BackgroundTransparency" },
	UIStroke = { "Transparency" },
}

local function anotar(gui: Instance)
	if not gui:IsA("BillboardGui") then
		return
	end
	local base = {}
	for _, d in gui:GetDescendants() do
		local props = PROPIEDADES[d.ClassName]
		if props then
			base[d] = {}
			for _, p in props do
				base[d][p] = d[p]
			end
		end
	end
	placas[gui] = base
end
CollectionService:GetInstanceAddedSignal("CartelLobby"):Connect(anotar)
CollectionService:GetInstanceRemovedSignal("CartelLobby"):Connect(function(gui)
	placas[gui] = nil
end)
for _, g in CollectionService:GetTagged("CartelLobby") do
	anotar(g)
end

local function suave(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local acumulado = 0
RunService.Heartbeat:Connect(function(dt)
	acumulado += dt
	if acumulado < 0.1 then
		return
	end
	acumulado = 0
	local camara = workspace.CurrentCamera.CFrame.Position
	local enPartida = jugador:GetAttribute("Partida") ~= nil -- las placas del lobby no se ven desde los mapas
	for gui, base in placas do
		if enPartida then
			gui.Enabled = false
			continue
		end
		local ancla = gui.Adornee or gui.Parent
		if not (ancla and ancla:IsA("BasePart")) then
			continue
		end
		local d = (ancla.Position - camara).Magnitude
		local visible = 1
		local hasta, desde = gui:GetAttribute("VerHasta"), gui:GetAttribute("VerDesde")
		if hasta then
			visible = suave((hasta - d) / (hasta * 0.2))
		end
		if desde then
			visible *= suave((d - desde) / (desde * 0.3))
		end
		gui.Enabled = visible > 0.01
		if gui.Enabled then
			for obj, props in base do
				for p, b in props do
					obj[p] = b + (1 - b) * (1 - visible)
				end
			end
		end
	end
end)
