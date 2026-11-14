-- Música y efectos del cliente (docs/INTERFAZ.md). Los IDs se completan cuando haya audio publicado; con el ID
-- vacío no suena nada y no da error.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sonido = {}

Sonido.MUSICA = {
	lobby = "", -- heroica tranquila
	partida = "", -- acción orquestal
	jefe = "", -- intensa con coro
}
Sonido.EFECTOS = {
	clic = "",
	premio = "",
	invocar = "",
	colocar = "",
	mejorar = "",
	vender = "",
	muerte = "",
	base = "",
	oleada = "",
	jefe = "",
	victoria = "",
	derrota = "",
}
Sonido.VOLUMEN_MUSICA = 0.35
Sonido.VOLUMEN_EFECTOS = 0.6
-- Multiplicadores de los Ajustes del jugador (0 a 1).
Sonido.ajusteMusica = 1
Sonido.ajusteEfectos = 1

local function id(v: string): string?
	if v == "" then
		return nil
	end
	return if string.find(v, "rbxassetid://", 1, true) then v else "rbxassetid://" .. v
end

local carpeta = Instance.new("Folder")
carpeta.Name = "SonidosUMTD"
carpeta.Parent = SoundService

-- Efectos: un Sound por nombre, se reproduce clonado para que se puedan superponer.
local ultimo = {}
function Sonido.efecto(nombre: string, volumen: number?)
	local a = id(Sonido.EFECTOS[nombre] or "")
	if not a then
		return
	end
	-- Evita amontonar el mismo efecto (p. ej. muchas bajas en el mismo frame).
	local ahora = os.clock()
	if ultimo[nombre] and ahora - ultimo[nombre] < 0.06 then
		return
	end
	ultimo[nombre] = ahora
	local s = Instance.new("Sound")
	s.SoundId = a
	s.Volume = (volumen or 1) * Sonido.VOLUMEN_EFECTOS * Sonido.ajusteEfectos
	s.Parent = carpeta
	s.Ended:Once(function()
		s:Destroy()
	end)
	s:Play()
	task.delay(10, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

-- Música: una pista a la vez, con fundido al cambiar.
local pista: Sound? = nil
local actual: string? = nil
function Sonido.musica(nombre: string?)
	if nombre == actual then
		return
	end
	actual = nombre
	local vieja = pista
	pista = nil
	if vieja then
		TweenService:Create(vieja, TweenInfo.new(1), { Volume = 0 }):Play()
		task.delay(1.1, function()
			vieja:Destroy()
		end)
	end
	local a = nombre and id(Sonido.MUSICA[nombre] or "")
	if not a then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = a
	s.Looped = true
	s.Volume = 0
	s.Parent = carpeta
	s:Play()
	TweenService:Create(s, TweenInfo.new(1), { Volume = Sonido.VOLUMEN_MUSICA * Sonido.ajusteMusica }):Play()
	pista = s
end

function Sonido.fijarVolumenes(musica: number, efectos: number)
	Sonido.ajusteMusica, Sonido.ajusteEfectos = musica, efectos
	if pista then
		pista.Volume = Sonido.VOLUMEN_MUSICA * musica
	end
end

return Sonido
