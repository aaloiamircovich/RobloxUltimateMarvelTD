-- Elige la música según dónde está el jugador y suena los efectos de la partida que se leen del estado
-- replicado (ReplicatedStorage.Partidas/<id>): oleada, golpes a la base, jefe y resultado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sonido = require(script.Parent:WaitForChild("Sonido"))

local jugador = Players.LocalPlayer
local conexiones = {}

local function limpiar()
	for _, c in conexiones do
		c:Disconnect()
	end
	table.clear(conexiones)
end

local function seguirPartida(id: string)
	local estado = ReplicatedStorage:WaitForChild("Partidas"):WaitForChild(id, 10)
	if not estado or jugador:GetAttribute("Partida") ~= id then
		return
	end
	local function musicaSegunJefe()
		local jefeRaid = (estado:GetAttribute("JefeVida") or 0) > 0
		local mensaje = estado:GetAttribute("Mensaje") or ""
		Sonido.musica(if jefeRaid or string.find(mensaje, "JEFE", 1, true) then "jefe" else "partida")
	end
	musicaSegunJefe()
	local base = estado:GetAttribute("Base")
	table.insert(conexiones, estado.AttributeChanged:Connect(function(a)
		local v = estado:GetAttribute(a)
		if a == "Oleada" and (v or 0) > 0 then
			Sonido.efecto("oleada")
		elseif a == "Mensaje" then
			if v and string.find(v, "JEFE", 1, true) then
				Sonido.efecto("jefe")
			end
			musicaSegunJefe()
		elseif a == "JefeVida" then
			musicaSegunJefe()
		elseif a == "Base" then
			if base and v and v < base then
				Sonido.efecto("base")
			end
			base = v
		elseif a == "Resultado" and v then
			Sonido.musica(nil)
			Sonido.efecto(if v == "victoria" then "victoria" else "derrota")
		end
	end))
	-- Cada baja da dinero: se usa como señal de enemigo derrotado.
	local dinero = jugador:GetAttribute("Dinero") or 0
	table.insert(conexiones, jugador:GetAttributeChangedSignal("Dinero"):Connect(function()
		local v = jugador:GetAttribute("Dinero") or 0
		if v > dinero then
			Sonido.efecto("muerte", 0.5)
		end
		dinero = v
	end))
end

local function cambio()
	limpiar()
	local id = jugador:GetAttribute("Partida")
	if id then
		task.spawn(seguirPartida, id)
	else
		Sonido.musica("lobby")
	end
end

jugador:GetAttributeChangedSignal("Partida"):Connect(cambio)
cambio()
