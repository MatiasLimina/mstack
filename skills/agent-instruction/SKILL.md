---
name: agent-instruction
description: >
  Genera las instrucciones del proyecto en AGENTS.md (y un CLAUDE.md que solo contiene @AGENTS.md) a partir
  de knowledge-base/, GLOSSARY.md, docs/adr/ y el issue de roadmap: stack, punteros a la KB, skills por agente,
  resumen del roadmap, workflow con issues y las reglas duras del proyecto. Escribe solo dentro de su bloque
  delimitado y conserva textual el resto del archivo (en particular `## Agent skills`). Interactivo SOLO para
  confirmar las reglas duras. NO repite las instrucciones globales que el stack ya instaló.
  Trigger: cuando el usuario pide crear/generar/actualizar AGENTS.md o CLAUDE.md, "armar las reglas del proyecto",
  "instrucciones para los agentes", "regenerá AGENTS.md", o después de roadmap-generator.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

<!-- Origen: JuanCruzRobledo/agent-instruction@71b9aa8 (Apache-2.0). Ver NOTICE.md.
     Cambios: AGENTS.md es la fuente y CLAUDE.md solo contiene @AGENTS.md (antes,
     dos copias); lee el issue de roadmap en lugar de CHANGES.md y describe el
     workflow con issues, sin /opsx; deja de leer .atl/skill-registry.md (queda
     el escaneo de skills instaladas); sin variantes generate/reuse/update ni
     hook de estado del orquestador (state.agents, "plan confirmado"); conserva
     el bloque delimitado active-stack:agent-instruction de upstream y todo lo de
     alrededor; cierra indicando /mattpocock-skills:setup-matt-pocock-skills; no se copió tests/. -->

## When to Use

- Generar las instrucciones del proyecto después de `kb-creator` y `roadmap-generator`.
- Regenerarlas cuando cambió la KB, el roadmap o las skills instaladas, sin perder lo que agregaron otras herramientas.

**Don't use when:**
- No existe `knowledge-base/` (corré `kb-creator` primero).
- El usuario quiere editar UNA regla puntual: editá el `AGENTS.md` existente en su lugar.
- Se busca configurar comportamiento automático del harness (eso son hooks en `settings.json`, no AGENTS.md).

La skill corre sola: no recibe plan ni estado de otra skill. Todas sus entradas están en disco o en GitHub.

---

## Qué produce

Dos archivos en la raíz del proyecto:

| Archivo | Contenido |
|---------|-----------|
| `AGENTS.md` | Las instrucciones, dentro del bloque administrado (abajo). Lo que esté fuera del bloque es ajeno y no se toca. |
| `CLAUDE.md` | Exactamente una línea: `@AGENTS.md`. Claude Code lo resuelve como import; no hay segunda copia que sincronizar. |

### Bloque administrado

La skill escribe **solo** entre estos dos marcadores, cada uno en su propia línea:

```markdown
<!-- active-stack:agent-instruction -->
...secciones de agent-instruction...
<!-- /active-stack:agent-instruction -->
```

Todo lo que está fuera del bloque es de otras herramientas o del dev y se conserva **textual**, en particular la sección `## Agent skills` que agrega `/mattpocock-skills:setup-matt-pocock-skills`. Nunca muevas, reformatees ni reordenes contenido ajeno.

| Estado de `AGENTS.md` | Qué hacer |
|-----------------------|-----------|
| No existe | Crealo con el bloque como único contenido. |
| Existe con un par de marcadores bien formado | Reemplazá solo lo que hay entre los marcadores. Si entre ellos hay una sección `## ` que no es de la plantilla (por ejemplo `## Agent skills`), no la borres: movela textual después del marcador de cierre y mostralo en el diff. |
| Existe sin marcadores | Insertá el bloque al principio del archivo, seguido de una línea en blanco y del contenido existente tal cual. |
| Marcadores incompletos, repetidos o en orden invertido | Conflicto: no escribas nada. Mostrale al usuario las líneas de los marcadores y pedile que lo resuelva. |

| Estado de `CLAUDE.md` | Qué hacer |
|-----------------------|-----------|
| No existe | Crealo con `@AGENTS.md`. |
| Su único contenido (ignorando líneas en blanco) es `@AGENTS.md` | Dejalo como está. |
| Tiene otro contenido | Ver "CLAUDE.md con contenido propio" abajo. |

### CLAUDE.md con contenido propio

Si `CLAUDE.md` tiene contenido que no es solo `@AGENTS.md`, migralo para que quede una sola fuente:

1. Sacá de ese contenido las líneas `@AGENTS.md` que ya tenga.
2. Agregá el resto a `AGENTS.md`, **fuera del bloque**, después del marcador de cierre, tal cual (sin reformatear ni deduplicar). Desde ahí es contenido ajeno: las corridas siguientes no lo tocan.
3. Dejá `CLAUDE.md` en `@AGENTS.md`.

Esto entra en el diff de "Confirmación antes de escribir": el usuario ve qué se mueve de `CLAUDE.md` a `AGENTS.md` antes de aprobar. Si no aprueba, no escribas ninguno de los dos archivos. Si el contenido migrado repite secciones del bloque (por ejemplo, otro "Stack"), avisalo en el cierre para que el usuario lo limpie; no lo borres vos.

### Confirmación antes de escribir

Si `AGENTS.md` o `CLAUDE.md` ya existían, mostrale al usuario el diff de lo que vas a cambiar (solo el bloque y, si aplica, `CLAUDE.md`) y esperá un sí explícito. Si el archivo cambió entre que mostraste el diff y que vas a escribir, frená y volvé a mostrarlo.

---

## Pre-checks

| Check | Si falla |
|-------|----------|
| `knowledge-base/` existe en la raíz | "Falta la KB. Corré `kb-creator` primero." No generes nada. |
| `knowledge-base/02_descripcion_general.md` existe | "KB incompleta. Corré `kb-creator`." No generes nada. |
| `gh issue list --label roadmap --state open --json number,title,url` devuelve un issue | Generá igual, sin la sección Roadmap, y avisá: "No encontré el issue de roadmap — corré `roadmap-generator` para incluirlo." Si devuelve más de uno, preguntá cuál usar. En una regeneración, si el bloque anterior tenía sección Roadmap y ahora no la vas a escribir, decilo en el diff. |

---

## Qué leer

1. `knowledge-base/02_descripcion_general.md` → stack tecnológico (copiá la tabla).
2. `knowledge-base/README.md` → nombre del proyecto y resumen.
3. `GLOSSARY.md` y `docs/adr/` (si existen) → solo para enlazarlos; no copies términos ni decisiones.
4. El issue de roadmap (`gh issue view <N> --json number,title,url,body`) → cantidad de ítems y fases, camino crítico y primer ítem (`R-01`). Resumen, NO el detalle.
5. `knowledge-base/10_preguntas_abiertas.md` → si hay preguntas de prioridad Alta, avisá en el bloque que se resuelven antes de codear.
6. Skills instaladas → escaneá los `SKILL.md` de `.claude/skills/` del proyecto, de `~/.claude/skills/` y de los plugins habilitados (o el inventario de skills del cliente activo). Tomá `name` y `description` de cada una.
7. El archivo global de instrucciones del cliente activo (si existe) → para NO repetir lo que ya define.
8. `AGENTS.md` y `CLAUDE.md` existentes → para ubicar el bloque y detectar `## Agent skills`.

### Enlaces

Todos los enlaces del bloque son relativos a la raíz (donde vive `AGENTS.md`): `knowledge-base/<archivo>.md`, `GLOSSARY.md`, `docs/adr/`. El roadmap se enlaza por su URL de GitHub y se nombra como `#N`. Enlazá solo archivos que existan.

---

## Reglas duras del proyecto (interactivo + stack-aware + NO repetir el global)

**Esta es la ÚNICA parte interactiva de la skill** (además de confirmar el diff sobre archivos existentes). Las reglas duras dependen del stack REAL del proyecto — nunca las hardcodees a un lenguaje.

**Paso 1 — Leé el global y NO repitas lo que YA está ahí (pero NO pierdas lo que falta).**
Para cada regla universal (governance, TDD, memoria, commits, builds), verificá si el global la define:
- Si **ya está** → NO la repitas; el proyecto la hereda.
- Si **NO está** → incluila en el proyecto, para que no quede en el limbo.

Verificá de verdad, no asumas. Cuando al menos una regla universal esté en el global, dejá en `## Reglas Duras` la línea de referencia de la plantilla.

**Paso 2 — Derivá reglas candidatas del stack detectado** (de `knowledge-base/02_descripcion_general.md`). Ejemplos, NO fijos:
- **Go** → `gofmt`/`go vet` obligatorios; errores envueltos con `%w`; sin `panic` en librerías.
- **Python** → `snake_case`; type hints; Pydantic `extra='forbid'` **solo si usa Pydantic**.
- **TypeScript/React** → `PascalCase` en componentes; prohibido `any`; `tsconfig` estricto.
- **Tests** → política de mocks (ej. "sin mocks de DB: base real/contenedor") si aplica.

**Paso 3 — CONFIRMÁ con el usuario**: presentá las candidatas y dejá que las edite, agregue o quite. **STOP y esperá la respuesta.** No inventes reglas que el usuario no confirmó. En una regeneración, partí de las reglas que ya están en el bloque y preguntá solo por los cambios.

**Paso 4 — Escribí SOLO las reglas confirmadas** en `## Reglas Duras`, en formato `NUNCA X → hacer Y` cuando aplique. Si el usuario no agrega ninguna, dejá solo la línea de referencia al global.

---

## Skills por agente

Mapeá las skills instaladas a los roles del proyecto:

| Agente | Rol | Skills que carga |
|--------|-----|------------------|
| Backend | API, modelos, migraciones | `fastapi-python`, `python-testing-patterns` |
| Frontend | UI y estado | `typescript-advanced-types`, `tailwind-design-system` |
| Fundación | Contexto e instrucciones | `kb-creator`, `roadmap-generator`, `agent-instruction` |

Usá solo skills que encontraste en el escaneo. No inventes skills. No copies sus reglas: la tabla solo mapea skill→rol.

---

## Workflow

1. Pre-checks.
2. Leer las entradas (arriba).
3. Proponer las reglas duras y esperar la confirmación.
4. Armar el bloque con [assets/agents-template.md](assets/agents-template.md).
5. Calcular los cambios según las tablas de "Qué produce"; si hay archivos existentes, mostrar el diff y esperar el sí.
6. Escribir.
7. Verificar (abajo).
8. Cerrar con el próximo paso.

### Verificación

Después de escribir, comprobá en disco:

- `AGENTS.md` tiene exactamente un marcador de apertura y uno de cierre, en ese orden.
- Todo lo que está fuera del bloque es idéntico a lo que había antes (compará contra la copia que leíste en el paso 2).
- `CLAUDE.md` es `@AGENTS.md`, y si hubo migración, su contenido anterior está textual en `AGENTS.md` después del bloque.
- Cada enlace local del bloque apunta a un archivo que existe.
- El bloque contiene las reglas confirmadas.

Si algo falla, reportá qué y no declares terminado.

```bash
tr -d '\r' < AGENTS.md | grep -c '^<!-- active-stack:agent-instruction -->$'    # 1
tr -d '\r' < AGENTS.md | grep -c '^<!-- /active-stack:agent-instruction -->$'   # 1
tr -d '\r' < CLAUDE.md | sed '/^[[:space:]]*$/d'                  # @AGENTS.md
```

---

## Próximo paso

Cerrá con uno de estos mensajes y frená; no corras la skill siguiente vos.

Si `AGENTS.md` todavía no tiene `## Agent skills`:

```
Instrucciones listas: AGENTS.md (bloque de agent-instruction) y CLAUDE.md → @AGENTS.md.
Próximo paso: /mattpocock-skills:setup-matt-pocock-skills con GitHub como tracker. Después volvé a correr agent-instruction para que las instrucciones incluyan las skills de Matt.
```

Si ya tiene `## Agent skills`:

```
Instrucciones actualizadas: solo cambió el bloque de agent-instruction; `## Agent skills` quedó intacta.
Próximo paso: /mattpocock-skills:grill-with-docs sobre R-01 del roadmap #<N>.
```

---

## Resources

- [assets/agents-template.md](assets/agents-template.md): plantilla del bloque administrado, con todas las secciones.
