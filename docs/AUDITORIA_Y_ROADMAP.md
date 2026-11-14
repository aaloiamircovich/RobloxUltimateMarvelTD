# Auditoría y roadmap · 14/11/2026

Revisión del estado del juego (código, Studio y una mirada en Play) y lista de lo que falta para que deje de
sentirse precario. Referencias: Anime Galaxy, All Star Tower Defense y los TD de Roblox con más jugadores.

## 1. Qué hay hoy

| Área | Estado |
|---|---|
| Combate | Simulación en el servidor portada del 2D: 105 personajes con kits, mejoras, prioridades, rasgos, objetos. 19 specs pasan. |
| Modos | Historia (4 mapas × 5 actos + Pesadilla), Infinito, Desafío semanal, Raids cooperativas. |
| Meta | Invocaciones (3 banners, B3 «Próximamente»), evolución por crafteo, nivel de cuenta, misiones + pase, tienda de evento, rankings, mascotas, monturas, bailes, exclusivos (Odin, Knull). |
| Modelos | 212 plantillas de héroes con esqueleto y animación de ataque; 22 enemigos; 8 mascotas; 5 monturas; lobby (HUB) con islas. |
| Interfaz | Estilo cómic en lobby y partida, retratos 3D, números de daño, votación de fin de partida. |
| Persistencia | DataStore con reintentos, autoguardado y guardado al cerrar. |

## 2. Hallazgos (de más grave a menos)

### Bloqueantes para publicar
1. **Propiedad intelectual.** Todo el juego usa personajes, nombres y mapas de Marvel sin licencia. Con esto **no se puede
   publicar** (Roblox lo da de baja y hay riesgo legal). Hay que decidir: dejarlo privado como proyecto, o
   **rehacerlo con un universo propio** (nombres, diseños y lore originales sobre las mismas mecánicas).
2. **Sin audio.** No hay un solo `Sound` en el lugar: ni música, ni efectos de ataque, ni interfaz. Es lo que más
   hace sentir «precario» a un TD.
3. **Interfaz del lobby superpuesta en pantallas medianas/chicas.** En Play (ventana ~650 px) la barra de monedas
   tapa botones, el escuadrón queda cortado y los botones G/B tapan carteles. En celular (la mayoría del público
   de Roblox) no es usable.
4. **Todas las partidas corren en el mismo servidor** que el lobby (copias del mapa lejos del HUB). Con varios
   grupos jugando se va a trabar; los TD grandes teletransportan a un servidor reservado por partida.
5. **Guardado sin bloqueo de sesión** (`SetAsync`). Si el mismo jugador entra a dos servidores (o el teleport
   anterior no terminó de guardar) se pueden perder o duplicar gemas/unidades. Pasar a `UpdateAsync` con bloqueo
   (o ProfileStore) antes de tener teleports.

### Contenido incompleto
6. **Mapas: 4 de 11.** El 2D tiene 11 (Instituto Xavier, Knowhere, Latveria, Asgard, Dimensión Oscura, Savage Land,
   The Raft sin hacer). El juego se termina en pocas horas.
7. **Enemigos: 22 de 49 con modelo** (30 normales + 19 jefes en `enemies.json`). Los que no tienen modelo salen
   como bloque.
8. **Habilidades sin efectos visuales propios.** Hay 3 efectos genéricos (flecha, rayo, impacto) hechos con piezas.
   Las habilidades de los kits (Gungnir, Rey del Vacío, sobrecarga ARC…) no se ven distintas. En los TD de
   referencia la habilidad es el espectáculo.
9. **Modelos sin animación de reposo/colocación.** Sólo atacan; en reposo quedan en pose fija. Sin efecto de
   aparición al colocar ni de subir de mejora.
10. **Modelos verificados sólo por muestra.** De 212, se vieron pelear 9; el resto por medición y foto.
    Cyclops evolucionado, Groot y Star-Lord no encontraron casilla en la prueba (revisar reglas de terreno).
11. **Banner 3** y **`Mejoras.AJUSTES`** (precios especiales) sin definir.

### Experiencia de juego
12. **Sin tutorial ni primera sesión guiada.** El jugador nuevo cae al lobby con 10+ botones y sin saber qué hacer.
13. **Sin ajustes:** volumen, calidad gráfica, ocultar números de daño, saltar oleadas por defecto.
14. **Colocar unidades:** falta vista previa fantasma con el alcance y color válido/inválido antes de confirmar
    (se valida, pero el jugador no ve por qué no puede).
15. **Sin daily login, códigos, logros ni recompensas de grupo**: los ganchos de retorno típicos de Roblox.
16. **Sin intercambio entre jugadores** (pilar social de ASTD/Anime Defenders).
17. **Sólo en español.** El público grande de Roblox está en inglés (y portugués). Falta sistema de traducción.

### Técnico
18. **Rendimiento sin medir.** 212 modelos con malla propia y SurfaceAppearance; retratos 3D con ViewportFrame
    en el escuadrón y paneles. Hay que medir memoria y FPS en un celular de gama media.
19. **Restos en ServerStorage:** `RBX_ASSISTANT_ANIMGEN` (222 clips de animación generados, ya publicados como
    asset) y `Borradores`. Se pueden borrar para aligerar el lugar.
20. **Plantillas sólo en Studio.** Los modelos no están en Git: si el lugar se corrompe o se pisa sin guardar,
    se pierden. Exportar un respaldo `.rbxm` periódico.
21. **Bug menor:** `Partida.escuadronDe` falla si el perfil todavía no cargó (indexa `perfil.squad` con perfil nil).
22. **Sin analítica**: no sabemos dónde abandona la gente ni qué unidades se usan.

## 3. Lo que está bien
- Toda la lógica de combate y economía vive en el servidor; los remotos validan tipos, NaN e infinito.
- Módulos puros con pruebas (19 specs) y documentación por sistema en `docs/`.
- Perfil con normalización (frontera de confianza) y modo «no guardar» si el DataStore falla al cargar.
- Sistemas de meta muy completos para la etapa: ya están casi todos los que tienen los TD de referencia.

## 4. Roadmap

Cada fase deja el juego mejor jugable que la anterior. Las decisiones marcadas ❓ son del usuario.

### Fase 0 · Decisiones (antes de seguir sumando contenido)
- ❓ **Universo:** ¿privado con Marvel, o rebrand a personajes originales para poder publicar? Afecta nombres,
  modelos, mapas y textos de todo lo que viene.
- ❓ **Idiomas:** ¿español solo, o español + inglés (+ portugués)?
- ❓ **Plataforma prioritaria:** celular o PC (define tamaños de interfaz y presupuesto de rendimiento).
- ❓ **Monetización** (si se publica): pases (x2 velocidad, casillas extra, VIP) y productos (gemas). Hoy no hay nada.

### Fase 1 · Que se sienta un juego terminado (núcleo)
1. **Audio:** música de lobby, de partida y de jefe; efectos de colocar, mejorar, vender, ataque por tipo
   (flecha/rayo/impacto), golpe a enemigo, muerte, base dañada, victoria/derrota, clics de interfaz.
2. **Interfaz responsiva:** rehacer el lobby con anclajes y escala por tamaño de pantalla; probar en 375×812,
   768×1024 y 1920×1080. Botones táctiles para G/B y la rueda de bailes.
3. **Colocación con vista previa:** fantasma del modelo + anillo de alcance verde/rojo y motivo si no se puede.
4. **Tutorial de primera sesión:** invocación gratis guiada → equipar → primer acto con flechas y textos →
   reclamar premio. Desbloquear botones del lobby de a poco.
5. **Ajustes:** música, efectos, calidad baja (sin sombras/partículas), números de daño, auto-saltar.
6. **Prueba completa de los 212 modelos en partida** (script que coloque cada uno y saque foto) y corregir
   terrenos/orientación.
7. **Animaciones de reposo** (una genérica por tamaño) y efecto de aparición/mejora.
8. Arreglar el bug de `escuadronDe` y borrar restos de ServerStorage; respaldo `.rbxm` de las plantillas.

### Fase 2 · Escala y seguridad de datos
1. **Bloqueo de sesión** en perfiles (`UpdateAsync` + marca de servidor, o ProfileStore).
2. **Servidores de partida:** teleport del grupo a un servidor reservado; el lobby queda liviano.
3. **Medir rendimiento** en celular; LOD o modelos livianos para unidades lejanas; limitar ViewportFrames.
4. **Analítica** con AnalyticsService: embudo del tutorial, abandono por acto, unidades más usadas, gemas.

### Fase 3 · Contenido
1. **7 mapas restantes** (uno por semana): decorado temático, 5 actos, jefe propio.
2. **27 enemigos y jefes sin modelo**, con animación de caminar; jefes con barra y frase de entrada.
3. **VFX de habilidades** por personaje, empezando por Míticos y Legendarios (los que se invocan con banner).
4. **Banner 3** con su moneda; **`Mejoras.AJUSTES`** para los personajes más fuertes.
5. **Pasada de balance** con datos de la analítica (dificultad por acto, valor de cada rareza).

### Fase 4 · Retención y social
1. Premio de **conexión diaria** (7 días), **códigos** canjeables y premio por unirse al grupo.
2. **Logros** con premios (colección, mapas, jefes).
3. **Intercambio** de unidades entre jugadores (con confirmación doble y registro).
4. **Invitar amigos** a la sala desde el panel; servidores privados.
5. Modos rotativos extra: «Leyenda» (actos muy difíciles con premios únicos), defensa de horda temporal.

### Fase 5 · Lanzamiento (si la Fase 0 lo habilita)
1. Ícono, miniaturas, tráiler corto y descripción.
2. Prueba cerrada con jugadores reales; corregir lo que reporten.
3. Revisión anti-exploit de todos los remotos (límite de frecuencia por jugador).
4. Monetización si se decidió; publicación y anuncios.

## 5. Orden sugerido para las próximas semanas
1. Fase 0 (decidir universo e idioma).
2. Audio + interfaz responsiva + vista previa de colocación (lo que más cambia la sensación de calidad).
3. Tutorial + ajustes.
4. Bloqueo de sesión + servidores de partida.
5. Mapas y enemigos de a uno, intercalando VFX de habilidades.
