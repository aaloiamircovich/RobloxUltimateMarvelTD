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
