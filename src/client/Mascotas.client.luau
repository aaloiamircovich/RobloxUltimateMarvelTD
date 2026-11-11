-- Mascotas que siguen a cada jugador (atributo Mascotas del jugador: "id:dorada,..."; docs/MASCOTAS.md).
-- Sólo visual: cada cliente las dibuja y las mueve; los bonos los calcula el servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local modelos = ReplicatedStorage:WaitForChild("ModelosMascotas", 30)
local carpeta = Instance.new("Folder")
carpeta.Name = "MascotasLocales"
carpeta.Parent = workspace

local DORADO = Color3.fromRGB(255, 200, 40)
-- Lugar de cada mascota detrás del jugador (izquierda, centro, derecha).
local LUGARES = { Vector3.new(-3.2, 1.2, 3.5), Vector3.new(0, 2.4, 4.5), Vector3.new(3.2, 1.2, 3.5) }

local porJugador = {} -- [Player] = { Model }

local function armar(j: Player)
	for _, m in porJugador[j] or {} do
		m:Destroy()
	end
	porJugador[j] = {}
	if not modelos then
		return
	end
	for _, txt in string.split(j:GetAttribute("Mascotas") or "", ",") do
		local partes = string.split(txt, ":")
		local plantilla = partes[1] and modelos:FindFirstChild(partes[1])
		if plantilla then
			local m = plantilla:Clone()
			if partes[2] == "1" then
				-- Dorada: contorno dorado y destellos.
				local h = Instance.new("Highlight")
				h.FillColor, h.FillTransparency, h.OutlineColor = DORADO, 0.65, DORADO
				h.Parent = m
				local base = m:FindFirstChildWhichIsA("BasePart", true)
				if base then
					local s = Instance.new("Sparkles")
					s.SparkleColor = DORADO
					s.Parent = base
				end
			end
			m.Parent = carpeta
			table.insert(porJugador[j], m)
		end
	end
end

local function seguir(j: Player)
	armar(j)
	j:GetAttributeChangedSignal("Mascotas"):Connect(function()
		armar(j)
	end)
end
Players.PlayerAdded:Connect(seguir)
for _, j in Players:GetPlayers() do
	task.spawn(seguir, j)
end
Players.PlayerRemoving:Connect(function(j)
	for _, m in porJugador[j] or {} do
		m:Destroy()
	end
	porJugador[j] = nil
end)

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for j, lista in porJugador do
		local raiz = j.Character and j.Character:FindFirstChild("HumanoidRootPart")
		for i, m in lista do
			if not raiz then
				continue
			end
			local lugar = LUGARES[i] or LUGARES[1]
			local destino = raiz.CFrame * CFrame.new(lugar + Vector3.new(0, math.sin(t * 2 + i) * 0.3, 0))
			local mira = CFrame.lookAt(destino.Position, destino.Position + raiz.CFrame.LookVector)
			local actual = m:GetPivot()
			-- Si quedó muy lejos (teletransporte), aparece directo.
			m:PivotTo(if (actual.Position - mira.Position).Magnitude > 40 then mira else actual:Lerp(mira, math.min(1, dt * 8)))
		end
	end
end)
