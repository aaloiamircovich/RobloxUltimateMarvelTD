-- Salón de héroes (docs/LOBBY.md, fase D): en los 5 pedestales del salón de la isla central (Hub.SALON) cada
-- jugador ve SUS 5 mejores unidades (rareza, después nivel; un Shiny gana el empate) posando con su reposo, con el
-- nombre y el nivel encima. Sólo local: los demás ven las suyas.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Personajes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personajes"))
local Reposo = require(ReplicatedStorage.Shared:WaitForChild("Reposo"))

local jugador = Players.LocalPlayer
local coleccion = ReplicatedStorage:WaitForChild("Coleccion")
local retratos = ReplicatedStorage:WaitForChild("Retratos", 30)
local ORDEN = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Secret = 6 }
local COLOR = {
	Common = Color3.fromRGB(170, 175, 185),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(180, 100, 255),
	Legendary = Color3.fromRGB(255, 190, 60),
	Mythic = Color3.fromRGB(255, 90, 110),
	Secret = Color3.fromRGB(80, 255, 220),
}
local ALTO = 6.5 -- studs de la estatua (los pedestales ya están ×2 con el lobby)

local carpeta = Instance.new("Folder")
carpeta.Name = "VitrinaLocal"
carpeta.Parent = workspace

local function mejores(unidades)
	local lista = table.clone(unidades or {})
	table.sort(lista, function(a, b)
		local ra = ORDEN[(Personajes.todos[a.heroId] or {}).rarity] or 0
		local rb = ORDEN[(Personajes.todos[b.heroId] or {}).rarity] or 0
		if ra ~= rb then
			return ra > rb
		end
		if a.level ~= b.level then
			return a.level > b.level
		end
		return (a.shiny and 1 or 0) > (b.shiny and 1 or 0)
	end)
	local r = {}
	for i = 1, math.min(5, #lista) do
		r[i] = lista[i]
	end
	return r
end

local firma = ""
local function armar()
	local salon = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("SalonHeroes")
	if not salon or not retratos then
		return
	end
	local ok, res = pcall(coleccion.InvokeServer, coleccion, "estado")
	if not ok or not res or not res.estado then
		return
	end
	local lista = mejores(res.estado.unidades)
	local nueva = ""
	for _, u in lista do
		nueva ..= `{u.heroId}:{u.level}:{u.shiny and 1 or 0},`
	end
	if nueva == firma then
		return
	end
	firma = nueva
	carpeta:ClearAllChildren()
	for i, u in lista do
		local tapa, mira = salon:FindFirstChild("Pedestal_" .. i), salon:FindFirstChild("Mira_" .. i)
		local h = Personajes.todos[u.heroId]
		local plantilla = retratos:FindFirstChild(u.heroId) or retratos:FindFirstChild(Personajes.base(u.heroId))
		if tapa and mira and h and plantilla then
			local m = plantilla:Clone()
			local _, tam = m:GetBoundingBox()
			m:ScaleTo(m:GetScale() * ALTO / tam.Y)
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
			-- Apoyada en la tapa del pedestal, mirando al centro de la isla.
			local caja, alto = m:GetBoundingBox()
			local desdePie = raiz and (raiz.Position.Y - (caja.Position.Y - alto.Y / 2)) or alto.Y / 2
			local piso = tapa.Position.Y + tapa.Size.X / 2
			local cf = CFrame.lookAt(Vector3.new(tapa.Position.X, piso + desdePie, tapa.Position.Z), Vector3.new(tapa.Position.X, piso + desdePie, tapa.Position.Z) + mira.CFrame.LookVector)
			if raiz then
				m:PivotTo(cf * raiz.CFrame:ToObjectSpace(m:GetPivot()))
			end
			if u.shiny then
				local hl = Instance.new("Highlight")
				hl.FillColor, hl.FillTransparency = Color3.fromRGB(255, 214, 90), 0.85
				hl.OutlineColor, hl.OutlineTransparency = Color3.fromRGB(255, 220, 110), 0.2
				hl.Parent = m
			end
			-- Cartel: nombre, rareza y nivel.
			local b = Instance.new("BillboardGui")
			b.Size = UDim2.fromOffset(130, 34)
			b.StudsOffsetWorldSpace = Vector3.new(0, ALTO / 2 + 1.6, 0)
			b.MaxDistance = 90
			b.LightInfluence = 0
			b.Adornee = raiz
			local n = Instance.new("TextLabel")
			n.Size = UDim2.new(1, 0, 0.58, 0)
			n.BackgroundTransparency = 1
			n.Font = Enum.Font.GothamBlack
			n.TextScaled = true
			n.TextColor3 = Color3.new(1, 1, 1)
			n.TextStrokeTransparency = 0.5
			n.Text = (if u.shiny then "★ " else "") .. h.name
			n.Parent = b
			local d = n:Clone()
			d.Position = UDim2.fromScale(0, 0.58)
			d.Size = UDim2.new(1, 0, 0.42, 0)
			d.Font = Enum.Font.GothamBold
			d.TextColor3 = COLOR[h.rarity] or Color3.new(1, 1, 1)
			d.Text = `{Personajes.NOMBRE_RAREZA[h.rarity] or ""} · Nv {u.level}`
			d.Parent = b
			b.Parent = m
			m.Parent = carpeta
			local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
			if animator then
				local a = Instance.new("Animation")
				a.AnimationId = Reposo.para(u.heroId, m:GetAttribute("Efecto"))
				local okA, pista = pcall(animator.LoadAnimation, animator, a)
				if okA then
					pista.Looped = true
					pista:Play(0)
				end
			end
			-- Luz del color de la rareza sobre el pedestal.
			local luz = Instance.new("PointLight")
			luz.Color, luz.Range, luz.Brightness = COLOR[h.rarity] or Color3.new(1, 1, 1), 10, 1.2
			luz.Parent = raiz
		end
	end
end

-- Al entrar, cuando cambia el escuadrón o las unidades (atributos que publica el servidor) y cada 30 s.
task.spawn(function()
	workspace:WaitForChild("Hub", 60)
	task.wait(3)
	armar()
	while true do
		task.wait(30)
		armar()
	end
end)
for _, a in { "Seguidores", "Gemas", "Oro" } do
	jugador:GetAttributeChangedSignal(a):Connect(function()
		task.delay(0.5, armar)
	end)
end
