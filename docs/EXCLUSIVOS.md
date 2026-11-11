# Personajes exclusivos

No salen en ningún banner. Datos en `src/shared/Exclusivos.luau` (heroes.json no se edita: cada uno toma el
terreno y el perfil de combate de un personaje del 2D y define sus stats); habilidades en `Kits.alAtacar`; pruebas en
`src/server/Pruebas/Exclusivos.spec.luau`.

| | Odin | Knull |
|---|---|---|
| Cómo se consigue | Nivel 50 del pase de batalla | Canje de 100 fragmentos de raid (pantalla de raids) |
| Rareza | Secreto (1 colocación, colocar ~6.000) | Secreto |
| Categoría | Místico (perfil de Thor) | Cósmico (perfil de Venom) |
| Daño / alcance / cadencia | 98 / 210 / 0,9 | 90 / 170 / 1,0 |
| Detecta sigilo | Sí | Sí |
| Habilidad | **GUNGNIR**: cada 3 ataques, rayo que salta del blanco a hasta 4 enemigos a 140 px con 70 % de poder | **REY DEL VACÍO**: cada 4 ataques, zarcillos a hasta 6 enemigos a 100 px del blanco con 60 % de poder y ralentización del 35 % por 2 s |

- Como el resto, la habilidad se activa con la mejora 2 y la potencia sube con las mejoras.
- Knull se puede canjear más de una vez (es una unidad más; el límite de colocación es 1).
- Modelos en `ServerStorage.Plantillas.Heroes/odin` y `/knull` (generador de Roblox + `auto_setup_avatar`), con
  animación de ataque generada (lanzar la lanza / tajo amplio) y efecto rayo / impacto.
