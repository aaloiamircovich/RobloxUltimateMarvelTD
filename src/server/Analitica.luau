-- Analítica con AnalyticsService (docs/ANALITICA.md): los gráficos se ven en el Creator Dashboard del juego.
-- Nada de esto cambia el juego; si Roblox rechaza un evento se ignora.
local AnalyticsService = game:GetService("AnalyticsService")

local Analitica = {}

local function intentar(f, ...)
	pcall(f, AnalyticsService, ...)
end

--------------------------------------------------------------------------------
-- Embudo del tutorial (pasos de Tutorial.client.luau)
--------------------------------------------------------------------------------
local PASOS_TUTORIAL = {
	[0] = "Elegir héroe inicial",
	"Tocar ¡JUGAR!",
	"Elegir acto y SOLO",
	"Colocar una unidad",
	"Apretar ¡LISTO!",
	"Mejorar una unidad",
	"Aguantar las 10 oleadas",
	"Volver al lobby",
	"Premio e invocar",
	"Tutorial terminado",
}
function Analitica.pasoTutorial(j: Player, paso: number)
	local nombre = PASOS_TUTORIAL[paso]
	if nombre then
		-- El embudo cuenta desde 1.
		intentar(AnalyticsService.LogOnboardingFunnelStepEvent, j, paso + 1, nombre)
	end
end

--------------------------------------------------------------------------------
-- Economía: se compara el saldo con el último conocido y se registra la diferencia con su motivo.
--------------------------------------------------------------------------------
local MONEDAS = {
	{ campo = "gems", nombre = "Gemas" },
	{ campo = "cores", nombre = "Nucleos" },
	{ campo = "fichasRasgo", nombre = "FichasRasgo" },
	{ campo = "cristales", nombre = "Cristales" },
	{ campo = "fichasRaid", nombre = "FichasRaid" },
}
local ultimos = {} -- [Player] = { [campo] = saldo }

-- motivo nil = sólo tomar el saldo de referencia (al entrar).
function Analitica.saldo(j: Player, perfil, motivo: string?)
	local antes = ultimos[j]
	local ahora = {}
	for _, m in MONEDAS do
		ahora[m.campo] = perfil[m.campo] or 0
	end
	ultimos[j] = ahora
	if not antes or not motivo then
		return
	end
	for _, m in MONEDAS do
		local diferencia = ahora[m.campo] - (antes[m.campo] or 0)
		if diferencia ~= 0 then
			local flujo = if diferencia > 0 then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink
			intentar(AnalyticsService.LogEconomyEvent, j, flujo, m.nombre, math.abs(diferencia), ahora[m.campo], motivo)
		end
	end
end

function Analitica.soltar(j: Player)
	ultimos[j] = nil
end

--------------------------------------------------------------------------------
-- Partidas: progreso por mapa (camino = mapa, nivel = acto) y oleada en la que se pierde.
--------------------------------------------------------------------------------
local function camino(mapa: string, acto): (string, number, string)
	if type(acto) == "number" then
		return `Historia {mapa}`, acto, `Acto {acto}`
	end
	return `{tostring(acto)} {mapa}`, 1, tostring(acto)
end

function Analitica.partidaEmpieza(j: Player, mapa: string, acto)
	local c, n, nombre = camino(mapa, acto)
	intentar(AnalyticsService.LogProgressionStartEvent, j, c, n, nombre)
end

function Analitica.partidaTermina(j: Player, mapa: string, acto, gano: boolean, oleada: number, abandono: boolean?)
	local c, n, nombre = camino(mapa, acto)
	if gano then
		intentar(AnalyticsService.LogProgressionCompleteEvent, j, c, n, nombre)
	else
		intentar(AnalyticsService.LogProgressionFailEvent, j, c, n, nombre, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = `Oleada {oleada}`,
			[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = if abandono then "Abandono" else "Derrota",
		})
	end
end

-- Evento suelto con un dato (p. ej. «Tutorial salteado» en qué paso).
function Analitica.evento(j: Player, nombre: string, dato: string?)
	intentar(AnalyticsService.LogCustomEvent, j, nombre, 1, if dato then { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = dato } else nil)
end

--------------------------------------------------------------------------------
-- Unidades: qué se coloca y qué se mejora (para balancear).
--------------------------------------------------------------------------------
function Analitica.unidad(j: Player, accion: string, heroeId: string, rareza: string?)
	intentar(AnalyticsService.LogCustomEvent, j, `Unidad {accion}`, 1, {
		[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = heroeId,
		[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = rareza or "?",
	})
end

return Analitica
