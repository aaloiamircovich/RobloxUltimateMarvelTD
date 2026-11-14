# Estilo de personajes

Elegido: **variante A** (cuerpo cuadrado tipo Roblox, cara anime). Referencia en Studio: `Arquero_A_autosetup`.

## Proceso por héroe (gratis, IA de Roblox vía MCP de Studio)

1. `generate_mesh` con la plantilla de abajo, `segmentation: none`, `maxTriangles: 8000`, tamaño `{4, 5.5, 1.5}`.
2. `auto_setup_avatar` con `setup_type: Development` → R15 con 15 piezas, `AnimationConstraint` y script `Animate` incluido.
3. Armas y accesorios aparte (arco, escudo, martillo) para animarlos mejor.

No usar nombres de Marvel ni "superhero" en los prompts: `generate_avatar` los bloquea por moderación. Describir el aspecto.
Plan B si un héroe no sale: Meshy (`meshy-t2.5` + `meshy-n1`, ~15 créditos) y después el mismo `auto_setup_avatar`.

## Plantilla de prompt

```
blocky Roblox-style character with anime face: big expressive anime eyes with highlights,
thin eyebrows, small mouth, <PELO>; <TRAJE Y COLORES>, <ACCESORIOS>, standing in T-pose
```

Ejemplo (arquero): `<PELO>` = `spiky blond anime hair`; `<TRAJE>` = `black tactical suit with a purple chevron on the chest, purple forearm guards, black gloves and boots`; `<ACCESORIOS>` = `small quiver on the back`.

## Enemigos

Plantillas en `ServerStorage.Plantillas.Enemigos/<id del enemigo>` (se guardan en el lugar, no en Git). Proceso: `generate_mesh` con "blocky Roblox-style …" describiendo el aspecto sin nombres de Marvel, escalar a su altura (normales ~3.5 studs, voladores ~2, tanques ~5.5) y comprobar que el frente mire a −Z. Si una malla sale sin textura (gris), regenerarla. El juego mueve el modelo con `PivotTo`; no hace falta esqueleto.

Hechos (facción Base Avengers): `ultron_drone`, `doombot`, `aim_scientist`, `chitauri_warrior`, `skrull_infiltrator`, `sentinel`.
Manhattan, Wakanda y Sanctum: `hydra_soldier`, `chitauri_skimmer`, `chitauri_phaser`, `outrider`, `mercenary_raider`, `sakaaran_soldier`, `symbiote_spawn`, `hellfire_guard`, `dark_elf`, `hand_ninja`, `frost_giant_scout`.
Jefes de los 4 mapas: `ultron_prime`, `magneto`, `loki`, `killmonger`, `dormammu`. Plantilla de ~3,6 studs: el servidor los agranda ×1,8 en partida. La IA a veces los genera mirando a +Z; se corrige girando el `WorldPivot` 180° y se comprueba con una copia en `PivotTo(CFrame.new(...))`.
Moderación: palabras como "jaw", "teeth" o "beast" pueden bloquear la generación; describir con tono de caricatura.

## Héroes en el juego

Plantillas en `ServerStorage.Plantillas.Heroes/<id del héroe>` (en el lugar, no en Git): el R15 de `auto_setup_avatar` con atributos opcionales `AnimacionAtaque` (rbxassetid), `VelocidadAtaque` y `Efecto` (`flecha`, `rayo` o `impacto`). El servidor posiciona por la `HumanoidRootPart`, no por el pivote del modelo (están desfasados ~2 studs). Sin plantilla, el héroe aparece como bloque.

Hechos (20): los 8 Míticos (`thor`, `hulk`, `jean_grey`, `silver_surfer`, `magneto`, `adam_warlock`, `sentry`,
`profesor_x`), `scarlet_witch`, `iron_man`, `doctor_strange`, `spiderman`, `capitan_america`, `black_panther`, `wolverine`
(11/11/2026, cada uno con animación de ataque propia), `odin` y `knull` (exclusivos, docs/EXCLUSIVOS.md), `hawkeye` (arco y disparo, flecha), `black_widow` (ojos verdes, golpe cruzado con bastones, rayo), `korg` (roca con cara anime, puñetazo, impacto). Las animaciones de la IA duran ~2 s y se reproducen ×2.
Legendarios (12/11/2026, 14 más; con Iron Man y Doctor Strange están los 16): `captain_marvel`, `vision`, `storm`,
`ghost_rider`, `nova`, `namor`, `iceman`, `black_bolt`, `hela`, `emma_frost`, `invisible_woman`, `loki`,
`mister_fantastic`, `beta_ray_bill`.
Épicos (12/11/2026, 20 más; con Spider-Man, Capitán América, Black Panther y Wolverine están los 24): `daredevil`,
`shang_chi`, `moon_knight`, `cyclops`, `blade`, `domino`, `iron_fist`, `magik`, `gambit`, `human_torch`, `psylocke`,
`venom`, `angela`, `deadpool`, `nightcrawler`, `rogue`, `beast`, `cable`, `miles_morales`, `x_23`.
Raros (13/11/2026, los 26): `star_lord`, `winter_soldier`, `she_hulk`, `war_machine`, `nick_fury`, `elektra`, `cloak`,
`dagger`, `black_cat`, `elsa_bloodstone`, `the_hood`, `devil_dinosaur` (×1,25), `peni_parker`, `jeff_the_land_shark`
(×0,8), `jubilee`, `luna_snow`, `mantis`, `ms_marvel`, `nebula`, `valkyrie`, `drax`, `cosmo` (×0,8), `lady_sif`,
`heimdall`, `white_tiger`, `tigra`. Los animales se piden "standing upright on two legs" para que el armado los tome
como R15. La moderación rechazó "face mask over the mouth"/"red star" y "hood up with shadowed face".
Comunes (13/11/2026, 27 más; con Black Widow, Hawkeye y Korg están los 30): `ant_man`, `groot` (×1,15), `gamora`,
`falcon`, `luke_cage`, `wasp`, `quake`, `medusa`, `punisher`, `jessica_jones`, `shuri`, `okoye`, `crystal`, `namora`,
`triton`, `squirrel_girl`, `rocket_raccoon` (×0,8), `yelena_belova`, `mbaku`, `red_guardian`, `wong`, `yondu`,
`maria_hill`, `echo`, `mockingbird`, `kate_bishop`, `howard_the_duck` (×0,8). La palabra "duck" no pasa la moderación:
se describe como "head shaped like a white bird with an orange beak". Si un personaje no-humano sale sin cara, pedir
"anime face: large friendly anime eyes".

**Cómo escalar.** Escalar por la caja engaña cuando hay cuernos, martillos o capas: medir de los pies (`LeftFoot`) a
la cabeza (`Head`) y comparar con Hawkeye (3,97 studs). Ojo: el Humanoid recoloca las piezas uno o dos frames después de
`ScaleTo`, y una plantilla en ServerStorage nunca se recoloca. Medir siempre una **copia en el workspace tras esperar
unos `Heartbeat`**, y recién ahí aplicar `ScaleTo(escala * objetivo / medido)` a la plantilla. Medir al instante da
alturas viejas, el bucle vuelve a achicar y salen "figuras de palitos" (cabeza y piezas diminutas).
Prompts: empezar con "blocky Roblox-style character with a chunky body, thick arms and legs and a big square head";
sin accesorios flotantes (discos, cintas, alas grandes), que confunden al armado. Si el armado devuelve un esqueleto de
huesos con `AnimationController` y sin `Humanoid`, regenerar la malla. Si dice "Failed to separate the geometry",
pasar `classifications: [{path: "body", classification: "Body"}]`.

Las **evoluciones** tienen modelo propio: `Plantillas.Heroes/<id de la evolución>`; si no existe, se usa el del
personaje base (servidor y retratos). Hechas (15): `thor_evolution`, `hulk_evolution`, `scarlet_witch_evolution`,
`phoenix`, `silver_surfer_evolution`, `magneto_evolution`, `adam_warlock_evolution`, `sentry_evolution`,
`profesor_x_evolution`, `iron_man_extremis`, `iron_spider`, `capitan_america_evolution`, `black_panther_evolution`,
`doctor_strange_evolution`, `wolverine_evolution`; y las 14 de los Legendarios nuevos (12/11/2026, `<id>_evolution`:
Binary, Vision blanco, Storm diosa, Ghost Rider rey del infierno, Nova cósmico, Namor rey, Omega Iceman, Black Bolt,
Hela, Emma diamante, Invisible Woman, Loki con libro de historias, The Maker, Beta Ray Bill con armadura); y las 76
restantes de Épicos, Raros y Comunes (13/11/2026). Ya tienen modelo propio las 105 evoluciones (212 plantillas en
total con bases y exclusivos). Cada evolución toma el `Efecto` de su base. Tamaño
medido de pies a cabeza: base = Hawkeye, evolución = su base ×1,1; Hulk y Devil Dinosaur ×1,25 y la evolución de Hulk ×1,35;
Groot ×1,15; Jeff, Cosmo, Rocket y Howard ×0,8; Korg más grande a propósito. El 12/11 se volvieron a medir y corregir todas las plantillas con el método de arriba.

`auto_setup_avatar` suele devolver *timeout* aunque el armado siga en Studio: esperar ~3 min y revisar si apareció
`<nombre>_autosetup`; si no, volver a pedirlo. Con `align_front_angle: true` sale casi siempre al primer intento.
No lanzar varios a la vez. Errores pasajeros del servicio ("Failed to retrieve asset", 504, `IsPendingException`):
reintentar más tarde; precargar las mallas con `ContentProvider:PreloadAsync` ayuda con el último. El generador de
mallas admite ~12 pedidos seguidos; más allá devuelve "Rate limit exceeded".
