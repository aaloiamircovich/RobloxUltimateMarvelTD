-- Escuadrón que te sigue por el lobby (docs/LOBBY.md, fase D): las 3 primeras unidades del escuadrón de cada
-- jugador (atributo Seguidores "heroId:shiny,…", lo publica el servidor) caminan detrás de él a media escala, con
-- su animación de reposo y la de caminar. Sólo visual: cada cliente las dibuja para todos los jugadores.
-- En partida se esconden.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Reposo = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Reposo"))
local Personajes = require(ReplicatedStorage.Shared:WaitForChild("Personajes"))

local retratos = ReplicatedStorage:WaitForChild("Retratos", 30)
local carpeta = Instance.new("Folder")
carpeta.Name = "SeguidoresLocales"
carpeta.Parent = workspace

local ESCALA = 0.7 -- más chicos los tapa el pasto 3D
local CAMINAR = "rbxassetid://71471396479960" -- la caminata de los enemigos (Partida.ANIMACION_ENEMIGO)
-- A los costados y un poco atrás (justo detrás los tapa la cámara; las mascotas flotan más cerca).
local LUGARES = { Vector3.new(-6, 0, 2), Vector3.new(6, 0, 2), Vector3.new(0, 0, 6.5) }
local MAX_JUGADORES_VISIBLES = 12 -- con más jugadores cerca sólo se dibujan los más cercanos (rendimiento)

local porJugador = {} -- [Player] = { { modelo, raiz, desfase, alto, reposo, caminar } }
local filtro = RaycastParams.new()
filtro.FilterType = Enum.RaycastFilterType.Exclude

local function limpiar(j: Player)
	for _, s in porJugador[j] or {} do
		s.modelo:Destroy()
	end
	porJugador[j] = nil
end

local function armar(j: Player)
	limpiar(j)
	porJugador[j] = {}
	if not retratos then
		return
	end
	for _, txt in string.split(j:GetAttribute("Seguidores") or "", ",") do
		local id, shiny = table.unpack(string.split(txt, ":"))
		local plantilla = id and (retratos:FindFirstChild(id) or retratos:FindFirstChild(Personajes.base(id)))
		if plantilla then
			local m = plantilla:Clone()
			m:ScaleTo(m:GetScale() * ESCALA)
			local raiz = m:FindFirstChild("HumanoidRootPart")
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = d == raiz
					d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
				end
			end
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				hum.EvaluateStateMachine = false
			end
			if shiny == "1" then
				local h = Instance.new("Highlight")
				h.FillColor, h.FillTransparency = Color3.fromRGB(255, 214, 90), 0.85
				h.OutlineColor, h.OutlineTransparency = Color3.fromRGB(255, 220, 110), 0.2
				h.Parent = m
			end
			m.Parent = carpeta
			local s = { modelo = m, raiz = raiz }
			if raiz then
				-- Distancia de la raíz al piso (para apoyarlos donde camina el jugador).
				local caja, tam = m:GetBoundingBox()
				s.alto = raiz.Position.Y - (caja.Position.Y - tam.Y / 2)
			end
			local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
			if animator then
				local a1 = Instance.new("Animation")
				a1.AnimationId = Reposo.para(id, m:GetAttribute("Efecto"))
				local a2 = Instance.new("Animation")
				a2.AnimationId = CAMINAR
				local ok1, reposo = pcall(animator.LoadAnimation, animator, a1)
				local ok2, caminar = pcall(animator.LoadAnimation, animator, a2)
				if ok1 then
					reposo.Looped = true
					reposo:Play(0)
					s.reposo = reposo
				end
				if ok2 then
					caminar.Looped = true
					caminar.Priority = Enum.AnimationPriority.Movement
					s.caminar = caminar
				end
			end
			table.insert(porJugador[j], s)
		end
	end
end

local function seguir(j: Player)
	armar(j)
	j:GetAttributeChangedSignal("Seguidores"):Connect(function()
		armar(j)
	end)
end
Players.PlayerAdded:Connect(seguir)
for _, j in Players:GetPlayers() do
	task.spawn(seguir, j)
end
Players.PlayerRemoving:Connect(limpiar)

local yo = Players.LocalPlayer
RunService.RenderStepped:Connect(function(dt)
	local camara = workspace.CurrentCamera.CFrame.Position
	-- Los jugadores más cercanos a la cámara primero.
	local orden = {}
	for j in porJugador do
		local raiz = j.Character and j.Character:FindFirstChild("HumanoidRootPart")
		if raiz then
			table.insert(orden, { j = j, raiz = raiz, d = (raiz.Position - camara).Magnitude })
		end
	end
	table.sort(orden, function(a, b)
		return a.d < b.d
	end)
	local visibles = {}
	for i, x in orden do
		visibles[x.j] = if i <= MAX_JUGADORES_VISIBLES and x.d < 400 and not x.j:GetAttribute("Partida") and not yo:GetAttribute("Partida") then x.raiz else nil
	end
	for j, lista in porJugador do
		local raiz = visibles[j]
		for i, s in lista do
			if not raiz or not s.raiz then
				s.modelo.Parent = nil
				continue
			end
			if s.modelo.Parent ~= carpeta then
				s.modelo.Parent = carpeta
			end
			local plano = raiz.CFrame * CFrame.new(LUGARES[i] or LUGARES[1])
			local destino = plano.Position
			-- Apoyado en el piso debajo del lugar que le toca.
			filtro.FilterDescendantsInstances = { carpeta, j.Character }
			local golpe = workspace:Raycast(destino + Vector3.new(0, 6, 0), Vector3.new(0, -20, 0), filtro)
			local y = if golpe then golpe.Position.Y + (s.alto or 1.5) else raiz.Position.Y - 1
			destino = Vector3.new(destino.X, y, destino.Z)
			local actual = s.raiz.Position
			local lejos = (actual - destino).Magnitude
			local nueva = if lejos > 40 then destino else actual:Lerp(destino, math.min(1, dt * 6))
			local mira = Vector3.new(raiz.CFrame.LookVector.X, 0, raiz.CFrame.LookVector.Z)
			local paso = (nueva - actual) * Vector3.new(1, 0, 1)
			if paso.Magnitude > 0.02 then
				mira = paso.Unit
			end
			s.raiz.CFrame = CFrame.lookAt(nueva, nueva + mira)
			-- Camina si se está moviendo.
			local moviendo = paso.Magnitude / math.max(dt, 1e-3) > 1.5
			if s.caminar then
				if moviendo and not s.caminar.IsPlaying then
					s.caminar:Play(0.15)
				elseif not moviendo and s.caminar.IsPlaying then
					s.caminar:Stop(0.2)
				end
			end
		end
	end
end)
