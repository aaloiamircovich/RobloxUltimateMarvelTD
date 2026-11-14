-- Ajustes del jugador y estado del tutorial de primera sesión (docs/TUTORIAL.md). Se guardan en el perfil.
local Preferencias = {}

Preferencias.PREMIO_TUTORIAL = 500 -- gemas al terminar el tutorial (10 invocaciones)
Preferencias.MAPA_TUTORIAL = "level_1"
Preferencias.PASOS = 9 -- último paso del tutorial (Tutorial.client.luau)

function Preferencias.ajustesPorDefecto()
	return { musica = 0.6, efectos = 0.8, calidadBaja = false, numerosDano = true, autoSaltar = false }
end

local function volumen(v, defecto: number): number
	v = tonumber(v)
	if not v or v ~= v then
		return defecto
	end
	return math.clamp(math.floor(v * 100 + 0.5) / 100, 0, 1)
end

-- Frontera de confianza: viene del DataStore o del cliente.
function Preferencias.normalizarAjustes(crudo)
	local d = Preferencias.ajustesPorDefecto()
	if type(crudo) ~= "table" then
		return d
	end
	d.musica = volumen(crudo.musica, d.musica)
	d.efectos = volumen(crudo.efectos, d.efectos)
	for _, k in { "calidadBaja", "numerosDano", "autoSaltar" } do
		if type(crudo[k]) == "boolean" then
			d[k] = crudo[k]
		end
	end
	return d
end

function Preferencias.normalizarTutorial(crudo)
	local t = { paso = 0, terminado = false, premiado = false }
	if type(crudo) ~= "table" then
		return t
	end
	t.paso = math.clamp(math.floor(tonumber(crudo.paso) or 0), 0, Preferencias.PASOS)
	t.terminado = crudo.terminado == true
	t.premiado = crudo.premiado == true
	return t
end

-- El premio se da una sola vez y sólo si ganó el Acto 1 del primer mapa (no alcanza con decir «terminé»).
function Preferencias.puedePremiar(perfil): (boolean, string?)
	local t = perfil.tutorial
	if t.premiado then
		return false, "Ya recibiste el premio del tutorial"
	end
	local prog = perfil.acts and perfil.acts[Preferencias.MAPA_TUTORIAL]
	if not prog or (prog.normal or 0) < 1 then
		return false, "Primero ganá el Acto 1 de la Base de los Vengadores"
	end
	return true, nil
end

-- Marca el tutorial como terminado y da el premio si corresponde. Devuelve las gemas dadas.
function Preferencias.terminar(perfil): number
	local t = perfil.tutorial
	t.terminado = true
	t.paso = Preferencias.PASOS
	if Preferencias.puedePremiar(perfil) then
		t.premiado = true
		perfil.gems += Preferencias.PREMIO_TUTORIAL
		return Preferencias.PREMIO_TUTORIAL
	end
	return 0
end

return Preferencias
