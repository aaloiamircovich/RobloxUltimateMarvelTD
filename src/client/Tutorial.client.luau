-- Tutorial de primera sesión (docs/TUTORIAL.md): guía paso a paso con flecha, recuadro y cartel. El paso se
-- guarda en el perfil; el premio lo da y valida el servidor (Preferencias.terminar).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Comic = require(script.Parent:WaitForChild("Comic"))

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")
local remoto = ReplicatedStorage:WaitForChild("Preferencias")

local function pedir(nombre: string, a)
	local ok, res = pcall(remoto.InvokeServer, remoto, nombre, a)
	return if ok and type(res) == "table" then res else nil
end

-- Estado inicial (el perfil puede tardar en cargar).
local estado
for _ = 1, 30 do
	estado = pedir("estado")
	if estado and estado.tutorial then
		break
	end
	task.wait(1)
end
if not estado or not estado.tutorial or estado.tutorial.terminado then
	return
end

--------------------------------------------------------------------------------
-- Interfaz: cartel arriba, flecha que rebota y recuadro sobre el objetivo
--------------------------------------------------------------------------------
local gui = Comic.crear("ScreenGui", { Name = "Tutorial", ResetOnSpawn = false, DisplayOrder = 20, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
local cartel = Comic.crear("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(560, 86), BackgroundColor3 = Comic.AMARILLO, Rotation = -1 }, gui)
Comic.borde(cartel, 4)
Comic.escalar(cartel)
Comic.texto({ Text = "TUTORIAL", TextSize = 18, TextColor3 = Comic.ROJO_OSCURO, TextStrokeTransparency = 1, Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(120, 20), TextXAlignment = Enum.TextXAlignment.Left }, cartel)
local texto = Comic.texto({ Font = Comic.TEXTO, TextSize = 19, TextColor3 = Comic.FONDO, TextStrokeTransparency = 1, TextWrapped = true, Position = UDim2.fromOffset(12, 24), Size = UDim2.new(1, -130, 1, -28), TextXAlignment = Enum.TextXAlignment.Left }, cartel)
Comic.boton("SALTEAR", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(104, 40), TextSize = 18, BackgroundColor3 = Comic.GRIS }, cartel, function()
	pedir("saltar")
	gui:Destroy()
end)
local flecha = Comic.texto({ Text = "▼", TextSize = 56, TextColor3 = Comic.AMARILLO, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(60, 60), Visible = false, ZIndex = 5 }, gui)
local recuadro = Comic.crear("Frame", { BackgroundTransparency = 1, Visible = false, ZIndex = 4 }, gui)
Comic.crear("UIStroke", { Color = Comic.AMARILLO, Thickness = 4 }, recuadro)
Comic.crear("UICorner", { CornerRadius = UDim.new(0, 8) }, recuadro)
gui.Parent = playerGui

-- Busca un botón visible por nombre en cualquier ScreenGui del jugador.
local function visible(o: Instance): boolean
	while o and o ~= playerGui do
		if o:IsA("GuiObject") and not o.Visible then
			return false
		elseif o:IsA("ScreenGui") and not o.Enabled then
			return false
		end
		o = o.Parent
	end
	return true
end
local function buscar(nombre: (string | { string })?): GuiObject?
	if type(nombre) == "table" then
		-- Varios objetivos en orden de prioridad (el primero visible gana).
		for _, n in nombre do
			local o = buscar(n)
			if o then
				return o
			end
		end
		return nil
	end
	if not nombre then
		return nil
	end
	for _, sg in playerGui:GetChildren() do
		if sg ~= gui and sg:IsA("ScreenGui") and sg.Enabled then
			for _, d in sg:GetDescendants() do
				if d.Name == nombre and d:IsA("GuiButton") and visible(d) then
					return d
				end
			end
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- Pasos
--------------------------------------------------------------------------------
local function enPartida(): boolean
	return jugador:GetAttribute("Partida") ~= nil
end
local function estadoPartida(): Instance?
	local id = jugador:GetAttribute("Partida")
	local carpeta = id and ReplicatedStorage:FindFirstChild("Partidas")
	return carpeta and carpeta:FindFirstChild(id)
end
local function misUnidades()
	local l = {}
	local partidas = workspace:FindFirstChild("Partidas")
	for _, d in (partidas and partidas:GetDescendants()) or {} do
		if d:IsA("Model") and d:GetAttribute("Uid") and d:GetAttribute("Dueno") == jugador.UserId then
			table.insert(l, d)
		end
	end
	return l
end

local premio = 0
local PASOS = {
	[0] = { texto = "¡Bienvenido! Tocá UNIDADES y elegí tu héroe inicial.", objetivo = "unidades", listo = function()
		local e = pedir("estado")
		return e and e.tieneUnidades
	end },
	[1] = { texto = "Tocá ¡JUGAR! y después HISTORIA para tu primera misión.", objetivo = { "Modo_story", "jugar" }, listo = function()
		return buscar("Solo") ~= nil or enPartida()
	end },
	[2] = { texto = "Elegí Base de los Vengadores · Acto 1 y tocá SOLO.", objetivo = "Solo", listo = enPartida },
	[3] = { texto = "Tocá la tarjeta de tu héroe (o la tecla 1) y después hacé clic en el piso para colocarlo. Verde = se puede.", objetivo = "Tarjeta1", listo = function()
		return #misUnidades() > 0
	end },
	[4] = { texto = "¡Bien! Apretá ¡LISTO! para que lleguen los enemigos.", objetivo = "Listo", listo = function()
		local e = estadoPartida()
		return e ~= nil and e:GetAttribute("Fase") ~= "listo"
	end },
	[5] = { texto = "Cuando juntes 💰, tocá a tu héroe y apretá MEJORAR para hacerlo más fuerte.", objetivo = "Mejorar", listo = function()
		for _, m in misUnidades() do
			if (m:GetAttribute("Mejora") or 0) >= 1 then
				return true
			end
		end
		local e = estadoPartida()
		return e ~= nil and e:GetAttribute("Fase") == "fin"
	end },
	[6] = { texto = "¡Aguantá las 10 oleadas! Colocá más héroes si te alcanza el dinero.", listo = function()
		local e = estadoPartida()
		if e and e:GetAttribute("Fase") == "fin" then
			if e:GetAttribute("Resultado") == "victoria" then
				return true
			end
			texto.Text = "Esta vez no salió. Tocá REINTENTAR y probá de nuevo: mejorá antes a tus héroes."
		else
			texto.Text = PASOS[6].texto
		end
		return false
	end },
	[7] = { texto = "¡Ganaste tu primer acto! Volvé al lobby para tu premio.", listo = function()
		return not enPartida()
	end },
	[8] = { texto = "", objetivo = "invocar", listo = function()
		local c = playerGui:FindFirstChild("Coleccion")
		return c ~= nil and c.Enabled
	end },
}

local paso = estado.tutorial.paso
-- Al volver a entrar a mitad del tutorial fuera de una partida, se retoma desde ¡JUGAR!.
if not enPartida() and paso >= 2 and paso <= 6 then
	paso = 1
end

local function entrar(n: number)
	paso = n
	if n == 8 then
		local res = pedir("terminar")
		premio = res and res.premio or 0
		PASOS[8].texto = if premio > 0 then `¡Te regalamos {premio} 💎! Tocá INVOCAR y probá suerte con tus nuevos héroes.` else "Tocá INVOCAR para conseguir más héroes con tus gemas."
	elseif n > 8 then
		gui:Destroy()
		return
	else
		task.spawn(pedir, "paso", n)
	end
	texto.Text = PASOS[n].texto
end
entrar(paso)

-- Flecha y recuadro siguen al objetivo cada cuadro.
local inicio = os.clock()
RunService.RenderStepped:Connect(function()
	if not gui.Parent then
		return
	end
	local p = PASOS[paso]
	local o = p and buscar(p.objetivo)
	flecha.Visible = o ~= nil
	recuadro.Visible = o ~= nil
	if o then
		local pos, tam = o.AbsolutePosition, o.AbsoluteSize
		local rebote = math.abs(math.sin((os.clock() - inicio) * 4)) * 10
		flecha.Position = UDim2.fromOffset(pos.X + tam.X / 2, pos.Y - 4 - rebote)
		recuadro.Position = UDim2.fromOffset(pos.X - 6, pos.Y - 6)
		recuadro.Size = UDim2.fromOffset(tam.X + 12, tam.Y + 12)
	end
end)

-- Si volvió al lobby a mitad de la partida del tutorial: al premio si ganó el acto, si no otra vez a ¡JUGAR!.
local function volvioAlLobby(): boolean
	if enPartida() or paso < 3 or paso > 7 then
		return false
	end
	local e = pedir("estado")
	entrar(if e and e.ganoActo then 8 else 1)
	return true
end

-- Avance: se revisa la condición del paso dos veces por segundo.
while gui.Parent do
	local p = PASOS[paso]
	if volvioAlLobby() then
		continue
	elseif p and p.listo() then
		entrar(paso + 1)
	end
	task.wait(if paso == 0 then 2 else 0.5)
end
