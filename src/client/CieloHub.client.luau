-- Cielo del lobby (docs/LOBBY.md): el Quinjet da vueltas alrededor de la isla central y el Helicarrier se mece.
-- Cuando toca el evento «quinjet» (AgendaLobby), el Quinjet baja, se posa en la azotea de la Torre de los
-- Vengadores y vuelve a despegar. Lo mueve cada cliente con la hora del servidor (todos lo ven igual).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AgendaLobby = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AgendaLobby"))

local hub = workspace:WaitForChild("Hub")
local cielo = hub:WaitForChild("Cielo", 30)
if not cielo then
	return
end
local jet = cielo:FindFirstChild("Quinjet")
local heli = cielo:FindFirstChild("Helicarrier")
local baseHeli = heli and heli:GetPivot()
local alturaJet = jet and jet:GetPivot().Position.Y or 0
local RADIO_JET, VUELTA = 190, 40 -- studs y segundos por vuelta

-- Azotea de la Torre de los Vengadores (llega por streaming: se busca hasta encontrarla).
local azotea = nil
local function buscarAzotea()
	local torre = hub:FindFirstChild("Hito_torre_vengadores", true)
	if torre then
		local cf, tam = torre:GetBoundingBox()
		azotea = cf.Position + Vector3.new(0, tam.Y / 2 + 3, 0)
	end
end

local function enOrbita(t: number): CFrame
	local a = t / VUELTA * math.pi * 2
	local pos = Vector3.new(math.cos(a) * RADIO_JET, alturaJet + math.sin(t * 0.7) * 3, math.sin(a) * RADIO_JET)
	local adelante = Vector3.new(-math.sin(a), 0, math.cos(a))
	-- Inclinado hacia adentro de la curva, como un avión doblando.
	return CFrame.lookAt(pos, pos + adelante) * CFrame.Angles(0, 0, math.rad(-12))
end

local function suave(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

RunService.RenderStepped:Connect(function()
	local t = workspace:GetServerTimeNow()
	if jet then
		local cf = enOrbita(t)
		local evento, p = AgendaLobby.evento(t)
		if evento == "quinjet" then
			if not azotea then
				buscarAzotea()
			end
			if azotea then
				-- 0–30 %: baja; 30–70 %: posado; 70–100 %: despega y vuelve a la órbita.
				local posado = CFrame.lookAt(azotea, azotea + Vector3.new(1, 0, 0))
				local duracion = AgendaLobby.EVENTOS[1].duracion
				local inicio = enOrbita(t - p * duracion)
				local final = enOrbita(t - p * duracion + duracion)
				if p < 0.3 then
					cf = inicio:Lerp(posado, suave(p / 0.3))
				elseif p < 0.7 then
					cf = posado * CFrame.new(0, math.sin(t * 2) * 0.15, 0)
				else
					cf = posado:Lerp(final, suave((p - 0.7) / 0.3))
				end
			end
		end
		jet:PivotTo(cf)
	end
	if heli and baseHeli then
		heli:PivotTo(baseHeli * CFrame.new(0, math.sin(t * 0.4) * 1.5, 0) * CFrame.Angles(0, math.sin(t * 0.05) * 0.05, 0))
	end
end)
