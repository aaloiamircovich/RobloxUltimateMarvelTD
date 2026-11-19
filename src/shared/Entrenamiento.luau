-- Entrenamiento (docs/ENTRENAMIENTO.md, 20/11/2026): campo de pruebas con créditos infinitos donde se prueba
-- cualquier héroe con nivel, mejora, rasgo, grados, objeto y Shiny a elección, y se sueltan enemigos a pedido.
-- No da premios ni cuenta para misiones. Módulo puro: el mapa y la validación de lo que pide el cliente.
local Data = script.Parent.Data
local Personajes = require(script.Parent.Personajes)
local Rasgos = require(script.Parent.Rasgos)
local Unidades = require(script.Parent.Unidades)
local Mejoras = require(script.Parent.Mejoras)
local items = require(Data.items)

local Entrenamiento = {}

Entrenamiento.ACTO = "entrenamiento"
Entrenamiento.DINERO = 999999 -- se repone en cada paso: créditos infinitos
Entrenamiento.LIMITE = 10 -- unidades por casilla
Entrenamiento.CASILLAS = 6
Entrenamiento.VELOCIDADES = { 1, 2, 3, 0.25, 0.5 } -- cámara lenta incluida
Entrenamiento.MAX_ENEMIGOS = 60 -- por tanda

-- Campo de pruebas: camino en S de tres baldosas de ancho, pasto alrededor, un estanque y bloques de montaña al
-- lado del camino para probar héroes de cualquier terreno. Grilla de 25 × 19 baldosas de 32 px (800 × 608).
-- Leyenda de Mapa.luau: G pasto, P camino, W agua, M montaña.
local FILAS = {
	"GGGGGGGGGGGGGGGGGGGGGGGGG", -- 0
	"GGGGGGGGGGGGGGGGGGGGGGGGG", -- 1
	"PPPPPPPPPPPPPPPPPPPPPPGGG", -- 2  tramo 1 (fila 3 al centro)
	"PPPPPPPPPPPPPPPPPPPPPPGGG", -- 3
	"PPPPPPPPPPPPPPPPPPPPPPGGG", -- 4
	"GGGGGGWWWWWWWGMMMMMGPPPGG", -- 5  estanque y montaña entre tramos
	"GGGGGGWWWWWWWGMMMMMGPPPGG", -- 6
	"GGGGGGWWWWWWWGMMMMMGPPPGG", -- 7
	"GGGPPPPPPPPPPPPPPPPPPPPGG", -- 8  tramo 2 (fila 9)
	"GGGPPPPPPPPPPPPPPPPPPPPGG", -- 9
	"GGGPPPPPPPPPPPPPPPPPPPPGG", -- 10
	"GGGPPPGGWWWWWGGMMMMMMGGGG", -- 11
	"GGGPPPGGWWWWWGGMMMMMMGGGG", -- 12
	"GGGPPPGGWWWWWGGMMMMMMGGGG", -- 13
	"GGGPPPPPPPPPPPPPPPPPPPPPP", -- 14 tramo 3 (fila 15) hasta la base
	"GGGPPPPPPPPPPPPPPPPPPPPPP", -- 15
	"GGGPPPPPPPPPPPPPPPPPPPPPP", -- 16
	"GGGGGGGGGGGGGGGGGGGGGGGGG", -- 17
	"GGGGGGGGGGGGGGGGGGGGGGGGG", -- 18
}
Entrenamiento.NIVEL = {
	id = "entrenamiento",
	name = "Campo de pruebas",
	difficulty = "Normal",
	theme = { id = "entrenamiento" },
	-- Centros de baldosa: fila r → y = 32r + 16; columna c → x = 32c + 16.
	path = { { x = 0, y = 112 }, { x = 688, y = 112 }, { x = 688, y = 304 }, { x = 144, y = 304 }, { x = 144, y = 496 }, { x = 800, y = 496 } },
	rendering = { tileSize = 32, terrainRows = FILAS },
}

local function entero(v, minimo: number, maximo: number): number?
	local n = tonumber(v)
	if not n or n ~= n then
		return nil
	end
	return math.clamp(math.floor(n), minimo, maximo)
end

-- Frontera de confianza: héroe configurado por el cliente para una casilla.
-- cfg: { heroId, nivel, mejora, rasgo?, grados = { dano, alcance, cadencia }?, objeto?, shiny? }
-- Devuelve la entrada del escuadrón de partida o (nil, motivo).
function Entrenamiento.validarHeroe(ranura, cfg): (any?, string?)
	local casilla = entero(ranura, 1, Entrenamiento.CASILLAS)
	if casilla ~= ranura or type(cfg) ~= "table" then
		return nil, "Datos inválidos"
	end
	local h = type(cfg.heroId) == "string" and Personajes.de(cfg.heroId)
	if not h then
		return nil, "Ese héroe no existe"
	end
	local e = {
		uid = casilla,
		heroId = cfg.heroId,
		nivel = entero(cfg.nivel, 1, Unidades.NIVEL_MAXIMO) or 1,
		mejora = entero(cfg.mejora, 0, Mejoras.MAXIMO) or 0,
		limite = Entrenamiento.LIMITE,
		shiny = cfg.shiny == true,
	}
	-- Rasgo y grados con la misma validación que las unidades guardadas.
	Rasgos.normalizarUnidad({ rasgo = cfg.rasgo, grados = cfg.grados }, e)
	if type(cfg.objeto) == "string" and items[cfg.objeto] then
		e.objeto = cfg.objeto
	end
	return e, nil
end

-- Frontera de confianza: tanda de enemigos. cfg: { id, cantidad, intervalo, vida?, velocidad }
-- vida: vida fija de cada enemigo (nil = la suya); velocidad: multiplicador (0 = quietos).
-- datos: enemies.json ({ normal, bosses }).
function Entrenamiento.validarEnemigos(cfg, datos): (any?, string?)
	if type(cfg) ~= "table" or type(cfg.id) ~= "string" then
		return nil, "Datos inválidos"
	end
	local base = datos.normal[cfg.id] or datos.bosses[cfg.id]
	if not base then
		return nil, "Ese enemigo no existe"
	end
	local intervalo = tonumber(cfg.intervalo)
	local velocidad = tonumber(cfg.velocidad)
	local vida = tonumber(cfg.vida)
	return {
		id = cfg.id,
		jefe = datos.bosses[cfg.id] ~= nil,
		cantidad = entero(cfg.cantidad, 1, Entrenamiento.MAX_ENEMIGOS) or 1,
		intervalo = if intervalo and intervalo == intervalo then math.clamp(intervalo, 0.2, 10) else 1,
		velocidad = if velocidad and velocidad == velocidad then math.clamp(velocidad, 0, 3) else 1,
		vida = if vida and vida == vida and vida >= 1 then math.min(math.floor(vida), 1e9) else nil,
	}, nil
end

-- Velocidad siguiente del ciclo (×1 → ×2 → ×3 → ×0,25 → ×0,5 → ×1).
function Entrenamiento.siguienteVelocidad(actual: number): number
	local i = table.find(Entrenamiento.VELOCIDADES, actual) or 0
	return Entrenamiento.VELOCIDADES[i % #Entrenamiento.VELOCIDADES + 1]
end

-- Texto del escuadrón para el atributo Escuadron del jugador ("uid:personaje:nivel:límite:shiny").
function Entrenamiento.texto(escuadron): string
	local partes = {}
	for _, e in escuadron do
		table.insert(partes, `{e.uid}:{e.heroId}:{e.nivel}:{e.limite}:{if e.shiny then 1 else 0}`)
	end
	return table.concat(partes, ",")
end

return Entrenamiento
