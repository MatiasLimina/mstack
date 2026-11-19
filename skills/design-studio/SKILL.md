---
name: design-studio
description: Explora un diseño (web, app móvil, app de escritorio o imagen) con tres diseñadores en paralelo, Gemini Neon como líder, y te trae opciones para elegir.
disable-model-invocation: true
---

# design-studio

Un estudio de diseño de tres miembros que produce **prototipos descartables**
para que el usuario elija. Nunca toca el código de la app: la opción ganadora
se guarda como documentación y se implementa después por el flujo normal
(spec → tickets → implement).

## Miembros

| Rol | Proveedor / modelo | Razonamiento |
|---|---|---|
| Líder y diseñador | `antigravity` / `gemini-4-neon` | `thought_level: high` |
| Diseñador | `claudeAgent` / `claude-opus-5-5` | effort `high` |
| Diseñador | `antigravity` / `gemini-4-argon` | `thought_level: high` |

- Si el `CLAUDE.md` global tiene una línea `design-studio: ...` en
  "Overrides de skills", esos miembros reemplazan a los de la tabla.
- Gemini va siempre por `antigravity`, nunca por `opencode`.
- **Neon lidera con lo que escribe**: el brief y la crítica. La orquestación
  (lanzar delegados, renderizar, mostrar) la hace esta sesión, porque un
  delegado no puede lanzar otros delegados.

## Disponibilidad

Llamá a `orchestrator_capabilities` y resolvé cada miembro antes de hacer
cualquier otra cosa.

- Sin `orchestrator_capabilities` (fuera de T3 Code) o sin Neon: no arranques.
  Reportá el motivo.
- Si falta Opus o Argon: decile al usuario quién falta y preguntale si sigue
  con menos opciones.
- Cada miembro que falta se reporta; el reemplazo lo elige el usuario,
  nunca vos.

## 1. Detectar el medio

Leé el pedido y el repo para decidir el **medio**:

| Medio | Señales |
|---|---|
| web | Next, Vite, Astro, Remix, SvelteKit, HTML suelto; pedido de landing, sitio o dashboard |
| móvil | Expo, React Native, Flutter, proyectos iOS/Android |
| escritorio | Electron, Tauri, WPF, SwiftUI para macOS |
| imagen | pedido de logo, ícono, ilustración o banner |

Si las señales se contradicen o no hay ninguna, preguntale al usuario el medio.

Buscá también el **design system** del proyecto (tokens, config de Tailwind,
variables CSS, librería de componentes, tema). Lo que encuentres es una
restricción del brief. Juntá además las referencias y las direcciones que el
usuario haya dado al invocar la skill.

## 2. Brief (Neon)

Lanzá a Neon con `delegate_task` (rol `design`, repo de solo lectura) para que
escriba el **brief**. Pasale el pedido, el medio, el design system (rutas, no
archivos pegados), las referencias y las direcciones del usuario. El brief
cubre:

- Público, objetivo y tono.
- Restricciones: design system, marca, accesibilidad, idioma del contenido.
- Pantallas: las que nombra el pedido, máximo 3. Si el pedido es amplio
  ("diseñame la app"), Neon elige las 2 o 3 más representativas y lo dice.
- Una **dirección** por diseñador (Opus, Argon, Neon), distinta entre sí: una
  frase de estilo más 2-3 decisiones concretas (paleta, tipografía, densidad,
  layout). Las direcciones que dio el usuario se respetan tal cual; Neon
  completa solo las libres.

## 3. Parada del brief

Mostrale al usuario un resumen del brief: medio detectado, restricciones,
pantallas y la dirección de cada diseñador. Esperá su OK. Si cambia o
reemplaza una dirección, actualizá el brief y seguí sin volver a parar. Esta
es la única parada antes de diseñar.

## 4. Diseño en paralelo

Creá una **carpeta de corrida** fuera del repo (el scratchpad de la sesión si
existe; si no, el directorio temporal del sistema) con una subcarpeta por
diseñador: `opus/`, `argon/`, `neon/`.

Lanzá los tres con `delegate_task` en paralelo, cada uno con el brief completo,
su dirección, la ruta absoluta de su subcarpeta y estas reglas:

- El repo es de solo lectura. Escribe únicamente en su subcarpeta.
- Entrega según el medio:
  - **web**: `opcion.html` autocontenido (CSS y JS inline, sin dependencias
    remotas salvo fuentes), con layout responsive.
  - **móvil**: `opcion.html` con las pantallas lado a lado, cada una dentro de
    un marco de teléfono de 390 px de ancho.
  - **escritorio**: `opcion.html` con las pantallas dentro de un marco de
    ventana (barra de título y controles del sistema operativo del proyecto).
  - **imagen**: ver [Imágenes](#imágenes).
- Una nota `decisiones.md` de 5-10 líneas: paleta, tipografía, layout y cómo
  interpretó su dirección.

No esperes sin hacer nada: renderizá cada opción a medida que llega.

## 5. Captura y crítica

Capturá cada opción con `html_preview`:

| Medio | Capturas |
|---|---|
| web | ancho 1280 y ancho 390 |
| móvil | ancho que entre el marco completo (hasta 1600) |
| escritorio | ancho 1280 |
| imagen | el SVG embebido en un HTML mínimo, ancho 728 |

Revisá la salida de consola de `html_preview`. Si una opción no renderiza,
devolvésela a su autor con el error y esperá la corrección.

Con las tres opciones listas, lanzá a Neon para la **crítica**: pasale el brief
y las rutas de las tres carpetas. Por cada opción: fortalezas, debilidades, si
cumple el brief (y si no, por qué) y cuál es su favorita.

## 6. Presentación

Mostrá cada opción con `html_render`, en orden A (Opus), B (Argon), C (Neon),
cada una con su párrafo de crítica. Las que Neon marcó como "no cumple" se
muestran igual, con la marca y el motivo. Cerrá con la favorita de Neon y
preguntale al usuario cuál elige.

## 7. Retoques

El usuario elige una opción y pide cambios ("la B con la paleta de la A").
Cada retoque:

1. Lo hace el autor de la opción elegida, en su subcarpeta, con el pedido del
   usuario y, si cita otra opción, la ruta de esa opción.
2. Neon revisa el resultado contra el brief y el pedido.
3. Mostrás la nueva captura con el comentario de Neon.

Repetí hasta que el usuario diga "listo". No hay límite de rondas.

## 8. Cierre

Con el "listo", guardá la ganadora en el repo, en `docs/design/<slug>/`
(`<slug>`: el pedido en kebab-case corto):

- `opcion.html` (o el SVG).
- Capturas en PNG: abrí el HTML con `preview_open`, `preview_resize` a cada
  ancho de la tabla del paso 5 y `preview_snapshot` con `save: true`. Copiá
  cada PNG con un nombre que diga el ancho (`captura-1280.png`). Cerrá la
  pestaña al terminar.
- `README.md` con las decisiones: medio, paleta, tipografía, layout, el brief
  resumido y por qué ganó (en palabras del usuario si las dio).

Las opciones descartadas quedan solo en la carpeta de corrida. Terminá con el
próximo comando, tal cual:

```
/mattpocock-skills:to-spec
```

## Imágenes

Antes de diseñar una imagen, fijate si hay un **generador de imágenes**
configurado: una línea `design-studio — imágenes: <skill o herramienta>` en
"Overrides de skills" del `CLAUDE.md` global.

- Con generador: cada diseñador escribe un prompt con su dirección; el
  generador produce la imagen y la entrega queda en su subcarpeta.
- Sin generador: cada diseñador entrega `opcion.svg` (logo, ícono o
  ilustración simple, con `viewBox` y sin imágenes raster embebidas).
  Si el pedido necesita una foto o una ilustración compleja, avisale al
  usuario que el resultado en SVG va a ser una aproximación.
