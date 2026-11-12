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
Las **evoluciones** tienen modelo propio: `Plantillas.Heroes/<id de la evolución>`; si no existe, se usa el del
personaje base (servidor y retratos). Hechas (15): `thor_evolution`, `hulk_evolution`, `scarlet_witch_evolution`,
`phoenix`, `silver_surfer_evolution`, `magneto_evolution`, `adam_warlock_evolution`, `sentry_evolution`,
`profesor_x_evolution`, `iron_man_extremis`, `iron_spider`, `capitan_america_evolution`, `black_panther_evolution`,
`doctor_strange_evolution`, `wolverine_evolution`. Tamaño: base ×1, evolución ×1,1; Hulk ×1,25 y su evolución ×1,35.

`auto_setup_avatar` suele devolver *timeout* aunque el armado siga en Studio: esperar ~3 min y revisar si apareció
`<nombre>_autosetup`; si no, volver a pedirlo. Con `align_front_angle: true` sale casi siempre al primer intento.
No lanzar varios a la vez.
