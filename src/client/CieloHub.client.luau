-- Cielo del lobby (docs/LOBBY.md): el Quinjet da vueltas alrededor de la isla central y el Helicarrier se mece.
-- Lo mueve cada cliente por su cuenta (el servidor los deja quietos), así no se manda nada por la red.
local RunService = game:GetService("RunService")

local cielo = workspace:WaitForChild("Hub"):WaitForChild("Cielo", 30)
if not cielo then
	return
end
local jet = cielo:FindFirstChild("Quinjet")
local heli = cielo:FindFirstChild("Helicarrier")
local baseHeli = heli and heli:GetPivot()
local alturaJet = jet and jet:GetPivot().Position.Y or 0
local RADIO_JET, VUELTA = 190, 40 -- studs y segundos por vuelta

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	if jet then
		local a = t / VUELTA * math.pi * 2
		local pos = Vector3.new(math.cos(a) * RADIO_JET, alturaJet + math.sin(t * 0.7) * 3, math.sin(a) * RADIO_JET)
		local adelante = Vector3.new(-math.sin(a), 0, math.cos(a))
		-- Inclinado hacia adentro de la curva, como un avión doblando.
		jet:PivotTo(CFrame.lookAt(pos, pos + adelante) * CFrame.Angles(0, 0, math.rad(-12)))
	end
	if heli and baseHeli then
		heli:PivotTo(baseHeli * CFrame.new(0, math.sin(t * 0.4) * 1.5, 0) * CFrame.Angles(0, math.sin(t * 0.05) * 0.05, 0))
	end
end)
