# Economía (19/11/2026)

Se aparta del 2D por decisión del usuario. Tres monedas con usos separados:

| Moneda | Para qué sirve | Cómo se gana |
| --- | --- | --- |
| **Gemas** 💎 | Invocar, evolucionar unidades, objetos de la tienda y huevos de mascota | Actos, raids, Infinito, misiones, pase, evento, premios y logros |
| **Oro** 🟡 | Monturas y bailes (mismos números que antes en gemas) | Al terminar cada partida y vendiendo unidades |
| **Créditos** 💰 | Colocar y mejorar unidades **dentro de la partida** (antes «dinero») | En partida, por enemigos y oleadas |

Rasgos y grados siguen con sus fichas de rasgo y cristales.

## Números
- **Evolucionar** (gemas, según la rareza de destino): Raro 50 · Épico 150 · Legendario 400 · Mítico 1000 · Secreto 2500
  (`Unidades.COSTO_EVOLUCION`).
- **Núcleos eliminados**: 1 núcleo = 50 gemas (`Unidades.GEMAS_POR_NUCLEO`). Los premios que daban núcleos dan 50 gemas
  por núcleo (actos +50 la primera vez, raid 250, Infinito +50 cada 10 oleadas, pase, diario, logros, tienda del evento).
- **Oro por partida** (`Cuenta.oroPartida`): 10 por oleada superada, ×1,5 si se gana, ×1,5 en Difícil o ×2 en
  Pesadilla. Lo cobra cada jugador de la partida (`Partida.terminar`, atributos `Oro` y `OroPartida`).
- **Vender unidad** (oro): Común 20 · Raro 50 · Épico 100 · Legendario 250 · Mítico 500 · Secreto 1000.
- **Objetos de la tienda** (gemas): precio del 2D / 40, redondeado (`Objetos.precio`).

## Migración (perfil versión 3)
Al cargar un perfil viejo, los créditos guardados pasan a oro (1 a 1) y cada núcleo a 50 gemas; los campos `credits`
y `cores` dejan de guardarse. Los perfiles nuevos empiezan con 500 gemas y 0 de oro.

## Pantalla de fin
El oro ganado aparece como premio en la pantalla de fin (`OroPartida`, 20/11/2026).
