---
name: agent-instruction
description: >
  Genera el AGENTS.md / CLAUDE.md canónico del proyecto a partir de la KB y el roadmap:
  stack tecnológico, referencia a knowledge-base/, skills disponibles por agente,
  roadmap de changes (CHANGES.md) y las reglas duras del proyecto. Interactivo SOLO para confirmar
  las reglas duras (stack-aware, derivadas del stack real); el resto es determinístico. NO repite las
  instrucciones globales del cliente activo que el stack ya instaló — emite únicamente lo específico del proyecto.
  Trigger: cuando el usuario pide crear/generar/actualizar AGENTS.md o CLAUDE.md, "armar las reglas del proyecto",
  "instrucciones para los agentes", "generar claude.md", o tras correr kb-creator + roadmap-generator.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

<!-- Origen: JuanCruzRobledo/agent-instruction@71b9aa8 (Apache-2.0). Ver NOTICE.md.
     Cambios: ninguno en el contenido; solo se agregó este encabezado y no se
     copió tests/ (prueba el contrato de estado del orquestador). -->

## When to Use

- Generar las instrucciones de proyecto que lee el cliente activo.
- Consolidar en un solo archivo: stack, KB, skills por agente, roadmap y reglas duras.
- Refrescar las instrucciones del proyecto tras cambios en la KB o en `CHANGES.md`.

**Don't use when:**
- No existe `knowledge-base/` (corré `kb-creator` primero).
- El usuario quiere editar UNA regla puntual (sugerí editar el `AGENTS.md` existente en su lugar).
- Se busca configurar comportamiento automático del harness (eso son hooks en `settings.json`, no AGENTS.md).

## Critical Patterns

### Pre-checks (si falla, NO generes y avisá)

| Check | Si falla |
|-------|----------|
| `knowledge-base/` existe en raíz | "Falta la KB. Corré `kb-creator` primero." |
| `knowledge-base/02_descripcion_general.md` existe | "KB incompleta. Corré `kb-creator`." |
| `CHANGES.md` existe en raíz | Generá igual, pero omití la sección Roadmap y avisá: "Sin CHANGES.md — corré `roadmap-generator` para incluir el roadmap." |

### Output — ubicación

Para la fase `agents` orquestada, usá la variante y las rutas de instrucciones que llegan del plan confirmado. Esas rutas corresponden a los agentes elegidos. En uso independiente, mantené `AGENTS.md` y `CLAUDE.md` en la raíz como destinos predeterminados.

- `generate`: escribí únicamente en rutas faltantes. Si aparece un archivo mientras se ejecuta la fase, preservalo y devolvé el conflicto.
- `reuse`: leé y verificá que las instrucciones aplicables cubren el contexto y las reglas del proyecto. Validá cada enlace local con la regla de resolución de abajo. Devolvé las rutas válidas sin escribir ni proponer reglas adicionales. El orquestador registra la reutilización.
- `update`: proponé un bloque de instrucciones de proyecto y mostrá el diff para aprobación. Si hay rutas faltantes y existentes, mostrá en el mismo diff las creaciones y las actualizaciones. Usá un snapshot de cada destino existente antes de escribir. Si el snapshot falla o un destino cambió desde que se aprobó el diff, detené la actualización.

Para archivos preexistentes insertá o reemplazá únicamente un bloque delimitado por `<!-- active-stack:agent-instruction -->` y `<!-- /active-stack:agent-instruction -->` en líneas propias. Conservá el contenido alrededor y dejá intactos los bloques administrados por otros arneses. Marcadores incompletos o repetidos son un conflicto y requieren revisión. En `generate`, incluí los mismos marcadores para que actualizaciones posteriores sean idempotentes.

### Enlaces a artefactos del proyecto

Resolvé los enlaces Markdown a la KB, el roadmap y el registro desde el directorio que contiene cada archivo de instrucciones. Resolvé primero el artefacto respecto de la raíz del proyecto y después calculá la ruta relativa al destino, con separadores `/`. Renderizá cada destino por separado cuando estén en directorios distintos.

- En `AGENTS.md` de raíz, usá `knowledge-base/`, `CHANGES.md` y, si existe, `.atl/skill-registry.md` como bases de los enlaces.
- En `.claude/CLAUDE.md`, usá `../knowledge-base/`, `../CHANGES.md` y, si existe, `../.atl/skill-registry.md`.

Verificá que los enlaces locales a los artefactos de la fundación resuelven al archivo esperado. En `generate` o `update`, corregí los enlaces del bloque administrado antes de registrar finalización. En `reuse`, reportá enlaces inválidos y pedí que se confirme `update` o se elija otro destino.

Tras generar o actualizar, verificá que cada destino contiene las reglas confirmadas. Si existe un estado orquestado válido (versión >= 2), actualizá `state.agents.created_by` a `"agent-instruction"`, `state.agents.files` con las rutas verificadas relativas a la raíz y `state.agents.reglas_applied` con la lista de reglas confirmadas. Conservá el resto del JSON, incluidas las demás fases y campos de `agents`. Si la verificación falla, informá los resultados parciales sin registrar finalización. En uso independiente sin estado previo, omití el hook.

### Input — qué leer

1. `knowledge-base/02_descripcion_general.md` → stack tecnológico (copiá la tabla).
2. `knowledge-base/README.md` → nombre del proyecto + resumen ejecutivo.
3. `CHANGES.md` → camino crítico, fases y primer change (resumen, NO el detalle completo).
4. `.atl/skill-registry.md` (si existe) → **fuente de verdad de las skills disponibles** (nombres + triggers + paths). Es lo que genera `skill-registry`; leelo de ahí, no re-escanees. *Fallback* si no existe: consultá el inventario de skills del cliente activo y sus directorios resueltos si hace falta. En ambos casos, agrupá las skills por rol de agente.
5. `knowledge-base/10_preguntas_abiertas.md` → flag de inconsistencias Alta a resolver antes de codear.
6. el archivo global de instrucciones del cliente activo (si existe) → las instrucciones que el stack ya instaló (orquestador, governance, engram, TDD, reglas universales). **Leelo para NO repetirlas** — el proyecto las hereda, no las duplica.

### Reglas duras del proyecto (interactivo + stack-aware + NO repetir el global)

**Esta es la ÚNICA parte interactiva de la skill.** Las reglas duras dependen del stack REAL del
proyecto — nunca las hardcodees a un lenguaje (no asumas Python/React).

**Paso 1 — Leé el global y NO repitas lo que YA está ahí (pero NO pierdas lo que falta).**
Abrí el archivo global de instrucciones del cliente activo (si existe) y verificá qué reglas universales define realmente
(orquestador, governance, engram, TDD, y *posiblemente* no-buildear / no-commitear / conventional
commits). Para CADA regla universal:
- Si **ya está** en el global → NO la repitas; el proyecto la hereda.
- Si **NO está** en el global → **inclúila en el proyecto** (si no, queda en el limbo: ni global ni proyecto).

⚠️ **Verificá de verdad, no asumas.** Hoy el global instalado por el stack NO trae las reglas de
commit/build/co-autoría — esas van en el proyecto hasta que se agreguen al global. Solo lo que
confirmes presente arriba se referencia; el resto se escribe.

Cuando al menos una regla universal esté en el global, agregá esta línea (referencia, no duplicado):

> Reglas globales ya definidas en el archivo global de instrucciones del cliente activo (orquestador, governance, TDD, engram): el proyecto las hereda. Acá viven solo las reglas **específicas de este proyecto** + las universales que el global no cubra.

**Paso 2 — Derivá reglas candidatas del stack detectado** (de `knowledge-base/02_descripcion_general.md`).
Ejemplos según stack (NO son fijas — adaptá al stack real del proyecto):
- **Go** → `gofmt`/`go vet` obligatorios; errores envueltos con `%w`; sin `panic` en librerías.
- **Python** → `snake_case`; type hints; Pydantic `extra='forbid'` **solo si usa Pydantic**.
- **TypeScript/React** → `PascalCase` en componentes; prohibido `any`; `tsconfig` estricto.
- **Tests** → política de mocks (ej. "sin mocks de DB: base real/contenedor") si aplica al stack.

**Paso 3 — CONFIRMÁ con el usuario** (con el mecanismo de preguntas del cliente, o por chat): presentá las reglas candidatas
derivadas del stack y dejá que las edite, agregue o quite. **STOP y esperá la respuesta.** No inventes
reglas que el usuario no confirmó.

**Paso 4 — Escribí SOLO las reglas confirmadas** en la sección `## Reglas Duras (específicas del
proyecto)`, en formato `NUNCA X → hacer Y` cuando aplique. Si el usuario no agrega ninguna específica,
dejá únicamente la línea de referencia al global del Paso 1 — un archivo de proyecto sin reglas
duplicadas es válido y deseable.

### Skills por agente

Mapeá las skills detectadas a los roles de agente del proyecto. Estructura sugerida:

| Agente | Rol | Skills que carga |
|--------|-----|------------------|
| Backend Core | FastAPI/SQLModel/UoW | `fastapi-templates`, `python-testing-patterns`, `postgresql-table-design` |
| Backend Aux | Servicios/integraciones | `api-security-best-practices`, `test-driven-development` |
| Frontend | React/Zustand/TanStack | `typescript-advanced-types`, `tailwind-design-system`, `playwright-best-practices` |
| Fundación | Contexto e instrucciones | `kb-creator`, `roadmap-generator`, `agent-instruction` |

Adaptá las filas a las skills realmente presentes en el repo. No inventes skills que no existen.

**DRY — no copies los compact rules acá.** El `AGENTS.md`/`CLAUDE.md` solo mapea skill→rol (decisión de arquitectura, versionada). Los compact rules de cada skill viven SOLO en `.atl/skill-registry.md` (no versionado); el orquestador los resuelve en runtime. Si existe el registro, agregá esta referencia debajo de la tabla. Si falta el registro, omití la referencia.

> Los compact rules de cada skill los resuelve el orquestador desde `.atl/skill-registry.md` (generado por `skill-registry`; no versionado — no está en el repo).

## Code Examples

Ver la plantilla completa en [assets/agents-template.md](assets/agents-template.md). Estructura de primer nivel (no quitar secciones):

```markdown
# {Proyecto} — Instrucciones para Agentes
## Stack Tecnológico        → tabla desde KB 02
## Base de Conocimiento     → links a knowledge-base/*.md
## Skills Disponibles       → tabla skill→rol (desde el registry) + línea de referencia a `.atl/skill-registry.md` si existe
## Roadmap de Changes       → resumen de CHANGES.md + primer change
## Reglas Duras (específicas del proyecto)  → 1 línea de referencia al global + reglas del proyecto confirmadas (stack-aware)
## Flujo de Trabajo         → KB → CHANGES → alcance y criterios de aceptación → implementación y verificación
```

## Commands

```bash
# Ver el registro si existe. El fallback es el inventario del cliente activo.
test -f .atl/skill-registry.md && cat .atl/skill-registry.md

# Verificar pre-checks
ls knowledge-base/ CHANGES.md

# En uso independiente con dos archivos nuevos, validar que ambos coinciden
diff AGENTS.md CLAUDE.md && echo "OK: sincronizados"
```

## Resources

- **Templates**: ver [assets/agents-template.md](assets/agents-template.md) — plantilla completa de `AGENTS.md`: referencia al global + reglas específicas del proyecto (stack-aware) y todas las secciones de contrato.
