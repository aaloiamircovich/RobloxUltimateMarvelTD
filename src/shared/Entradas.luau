-- Animaciones de entrada al colocar (docs/UNIDADES_VISUAL.md): los 25 Míticos, Legendarios y Secreto, más los
-- exclusivos Odin y Knull. Generadas con la IA de Roblox (2,5 s, una sola vez). Las evoluciones usan la de su base.
local Personajes = require(script.Parent.Personajes)

local Entradas = {}

Entradas.POR_PERSONAJE = {
	thor = "rbxassetid://101802744293419", -- aterriza de rodilla, golpea con el martillo y lo levanta
	hulk = "rbxassetid://77243367515929", -- cae, golpea el piso con los dos puños y ruge
	doctor_strange = "rbxassetid://75757715447799", -- dibuja un círculo en el aire y lanza un hechizo
	iron_man = "rbxassetid://139851645520131", -- aterriza agachado con el puño en el piso y apunta los repulsores
	captain_marvel = "rbxassetid://90221371391732", -- baja flotando y aprieta los puños brillantes
	scarlet_witch = "rbxassetid://123698604416343", -- teje magia entre las manos y abre los brazos
	vision = "rbxassetid://128251334416941", -- atraviesa hacia abajo, se toca la gema de la frente
	jean_grey = "rbxassetid://124311622237856", -- se levanta con los brazos abiertos como alas de fuego
	storm = "rbxassetid://115150270956422", -- baja flotando y alza los brazos llamando la tormenta
	silver_surfer = "rbxassetid://123115167926504", -- llega inclinado como sobre la tabla y alza la mano
	ghost_rider = "rbxassetid://127884955026769", -- revolea la cadena sobre la cabeza y la golpea contra el piso
	nova = "rbxassetid://113912480649469", -- cae de pie como un cohete y pose heroica
	namor = "rbxassetid://99142137173817", -- salta con el tridente y lo clava al lado
	iceman = "rbxassetid://74884569268125", -- llega patinando y congela el aire con las manos
	black_bolt = "rbxassetid://81951334818300", -- se lleva un dedo a los labios y abre los brazos
	hela = "rbxassetid://133383287931846", -- barre el brazo hacia abajo haciendo salir espadas
	emma_frost = "rbxassetid://71377635353454", -- se toca la sien y cruza los brazos
	magneto = "rbxassetid://91599081767803", -- baja con los brazos en alto y levanta algo pesado con la mente
	adam_warlock = "rbxassetid://85551102769176", -- despierta como de un capullo y se estira radiante
	invisible_woman = "rbxassetid://71439394125212", -- empuja con las palmas un campo de fuerza
	loki = "rbxassetid://123051251939486", -- reverencia teatral y pose con el cetro
	mister_fantastic = "rbxassetid://123748333222179", -- estira los brazos lejísimos y se rasca el mentón
	sentry = "rbxassetid://122351202399245", -- baja del cielo con los brazos abiertos, brillando
	beta_ray_bill = "rbxassetid://114051782938213", -- gira el martillo sobre la cabeza y lo golpea contra el piso
	profesor_x = "rbxassetid://94118643078738", -- se concentra con dos dedos en la sien
	odin = "rbxassetid://80588802485228", -- golpea el piso con la lanza y la alza al cielo
	knull = "rbxassetid://117503225213131", -- se levanta de cuclillas con las garras abiertas
}

-- Id de la animación de entrada de un personaje (o su evolución), o nil si no tiene.
function Entradas.para(heroeId: string): string?
	return Entradas.POR_PERSONAJE[heroeId] or Entradas.POR_PERSONAJE[Personajes.base(heroeId)]
end

return Entradas
