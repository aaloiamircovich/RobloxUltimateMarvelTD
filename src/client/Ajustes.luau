-- Ajustes del jugador en el cliente (docs/TUTORIAL.md): se cargan del perfil, se aplican al momento y se guardan
-- en el servidor (que los vuelve a validar).
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Preferencias = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Preferencias"))
local Sonido = require(script.Parent:WaitForChild("Sonido"))

local Ajustes = {}
Ajustes.valores = Preferencias.ajustesPorDefecto()
local cambio = Instance.new("BindableEvent")
Ajustes.cambio = cambio.Event

-- Calidad baja: sin sombras, sin efectos de post-proceso ni partículas. Se guarda el estado original para volver.
local originales = {}
local conexionNuevos
local function apagar(d: Instance)
	if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("PostEffect") then
		if originales[d] == nil then
			originales[d] = d.Enabled
		end
		d.Enabled = false
	end
end
local function aplicarCalidad(baja: boolean)
	if baja then
		if originales[Lighting] == nil then
			originales[Lighting] = Lighting.GlobalShadows
		end
		Lighting.GlobalShadows = false
		for _, d in Lighting:GetDescendants() do
			apagar(d)
		end
		for _, d in workspace:GetDescendants() do
			apagar(d)
		end
		conexionNuevos = conexionNuevos or workspace.DescendantAdded:Connect(apagar)
	else
		if conexionNuevos then
			conexionNuevos:Disconnect()
			conexionNuevos = nil
		end
		for d, v in originales do
			if d == Lighting then
				Lighting.GlobalShadows = v
			elseif d.Parent then
				d.Enabled = v
			end
		end
		table.clear(originales)
	end
end

local function aplicar()
	local v = Ajustes.valores
	Sonido.fijarVolumenes(v.musica, v.efectos)
	aplicarCalidad(v.calidadBaja)
	cambio:Fire(v)
end

local remoto = ReplicatedStorage:WaitForChild("Preferencias")
local pendiente = false
function Ajustes.fijar(clave: string, valor)
	local nuevos = table.clone(Ajustes.valores)
	nuevos[clave] = valor
	Ajustes.valores = Preferencias.normalizarAjustes(nuevos)
	aplicar()
	-- Un solo guardado aunque se toquen varios botones seguidos.
	if not pendiente then
		pendiente = true
		task.delay(1, function()
			pendiente = false
			pcall(remoto.InvokeServer, remoto, "ajustes", Ajustes.valores)
		end)
	end
end

-- Carga inicial (el perfil puede tardar en estar listo).
task.spawn(function()
	for _ = 1, 20 do
		local ok, res = pcall(remoto.InvokeServer, remoto, "estado")
		if ok and res and res.ajustes then
			Ajustes.valores = Preferencias.normalizarAjustes(res.ajustes)
			aplicar()
			return
		end
		task.wait(1)
	end
end)

return Ajustes
