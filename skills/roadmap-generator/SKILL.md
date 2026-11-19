---
name: roadmap-generator
description: >
  Publica el plan de trabajo de un proyecto como un único issue de roadmap en GitHub, a partir de knowledge-base/: árbol de dependencias, paralelismo, camino crítico y una task list con una línea por spec futura (alcance, governance LOW/MEDIUM/HIGH/CRITICAL, dependencias y qué leer antes). Confirma el repo destino antes de publicar y no crea issues hijos.
  Trigger: When user asks to create, build, regenerate, or update the roadmap, change map, implementation plan; or says "armar roadmap", "issue de roadmap", "generar plan de implementación", "qué specs necesito", or after kb-creator.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "3.0"
---

<!-- Origen: Group-Active-IA/roadmap-generator@d603877 (Apache-2.0). Ver NOTICE.md.
     Cambios: publica un issue de roadmap en GitHub en lugar de escribir
     CHANGES.md; la lista de trabajo es una task list con IDs R-NN; governance
     LOW/MEDIUM/HIGH/CRITICAL en lugar de BAJO/MEDIO/ALTO/CRITICO; pre-check de
     9 canónicos (sin 09) y punteros a GLOSSARY.md y docs/adr/; sin orquestador
     ni archivo de estado (se borró assets/state-contract.md); sin variantes
     local-markdown/reuse ni ClickUp; sin plan de 3 agentes; confirma el repo
     destino antes de publicar; cierra indicando agent-instruction; no se copió
     tests/. -->

## When to Use

- Convertir la base de conocimiento de un proyecto nuevo en el plan de specs a escribir.
- Identificar **camino crítico**, **paralelismo** y **nivel de governance** de cada spec futura.

**Don't use when:**
- No existe `knowledge-base/` (corré `kb-creator` primero).
- El repo ya tiene un issue de roadmap abierto y el usuario quiere cambiar un ítem: editá ese issue en lugar de publicar otro.

---

## Qué produce

**Un único issue de GitHub**, con label `roadmap` y título `Roadmap: <NombreProyecto>`. Nada más:

- No escribe archivos en el repo.
- No crea issues de spec ni issues hijos. Cada ítem se vuelve spec más adelante, con `/grill-with-docs` y `/to-spec`, y recién ahí tiene su issue.

El cuerpo sigue [assets/roadmap-template.md](assets/roadmap-template.md).

---

## Pre-checks

Validá esto antes de leer la KB. Si algo falla, **no publiques nada** y devolvé el mensaje:

| Check | Si falla |
|-------|----------|
| `knowledge-base/` existe en la raíz | "Falta la KB. Corré primero `kb-creator` para generarla." |
| Están los 9 canónicos: `01_` a `08_` y `10_` (el `09` queda vacío a propósito) | "KB incompleta. Faltan: [lista]. Corré `kb-creator` para completarla." |
| `gh auth status` responde y `gh repo view --json nameWithOwner` devuelve un repo | "No hay repo de GitHub accesible con `gh`. Creá el remote o logueate y volvé a correr la skill." |
| `gh issue list --label roadmap --state open` está vacío | "Ya existe el roadmap #N. Si querés cambiarlo, decime qué ítem y lo edito." Frená ahí. |

---

## Qué leer

Leé de disco, siempre:

1. `knowledge-base/04_modelo_de_datos.md`: entidades y relaciones (orden de creación).
2. `knowledge-base/06_funcionalidades.md`: épicas e historias (la materia de cada ítem).
3. `knowledge-base/07_flujos_principales.md`: flujos E2E (qué ítems son atómicos y cuáles compuestos).
4. `knowledge-base/08_arquitectura_propuesta.md`: patrones e infraestructura previa.

Leé también, si existen:

- `knowledge-base/03_actores_y_roles.md`: ítems de auth y roles.
- `knowledge-base/05_reglas_de_negocio.md`: reglas que cruzan ítems.
- `knowledge-base/10_preguntas_abiertas.md`: ítems con dependencias inciertas.
- `GLOSSARY.md`: nombrá los ítems con los términos del dominio.
- `docs/adr/`: decisiones ya tomadas que fijan el orden o el alcance.

---

## Ítems del roadmap

Cada ítem es **una spec futura**: algo que después pasa por `/grill-with-docs` → `/to-spec` → `/to-tickets` y se implementa en varios tickets. Apuntá a ítems que un grill pueda cerrar en una sesión, no a tareas de una hora.

### IDs

- `R-01`, `R-02`, …, `R-NN`, siempre con 2 dígitos, en orden de fase.
- Las dependencias, el árbol, el paralelismo y el camino crítico se refieren a los ítems **solo por su ID**.
- El ID sobrevive a la vida del roadmap: cuando se crea la spec `#N` de un ítem, la línea pasa a `- [ ] R-NN #N` (ver "Cómo usar este roadmap" en la plantilla). Por eso nunca se renumera ni se recicla un ID.

### Línea de la task list

Una línea por ítem, sin saltos, con este orden:

```
- [ ] R-NN `nombre-kebab` — alcance · **GOVERNANCE** · deps: R-AA, R-BB · leer: ruta §sección, ruta
```

- **Nombre**: kebab-case, con términos de `GLOSSARY.md` cuando existan.
- **Alcance**: operacional y compacto, separado por `;`. Nombrá entidades, endpoints, eventos y migraciones concretas.
  - ✅ `Category, Subcategory, Product; CRUD /api/admin/*; GET /api/public/menu cacheado; migración 003`
  - ❌ `Gestión completa del catálogo`
- **Governance**: uno de `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` (tabla abajo).
- **deps**: IDs separados por coma, o `—` si no tiene.
- **leer**: 3 a 5 punteros, con sección cuando aplique. Pueden apuntar a `knowledge-base/`, a un ADR concreto de `docs/adr/` o a `GLOSSARY.md`.

### Governance

Mismos niveles que el gate final del `CLAUDE.md` global:

| Nivel | Cuándo |
|-------|--------|
| **LOW** | Scaffolding, CRUDs simples, catálogos, pantallas sin lógica crítica, utilidades read-only. |
| **MEDIUM** | Lógica de negocio, flujos con estado, máquinas de estado, adapters, eventos no críticos. |
| **HIGH** | Configuración que afecta datos del usuario, gestión de roles, notificaciones, gateway de eventos, observabilidad, backup/restore. |
| **CRITICAL** | Auth, pagos, seguridad, audit trail, datos sensibles (p. ej. alérgenos en food), modelos core que todo lo demás referencia. |

### Dependencias

Aplicá en orden:

1. **Infra primero, solo si falta**: en un repo vacío, `R-01` suele ser el scaffolding.
2. **Modelos core antes que features.**
3. **Auth antes que recursos protegidos.**
4. **Entidad referenciada antes que la que la referencia** (`categorías` antes que `productos`).
5. **Backend antes que el frontend que lo consume.**
6. **Integraciones externas, pagos y webhooks al final**: dependen del dominio.
7. **Admin y dashboards al final**: dependen de los datos que muestran.
8. **Restyle visual al final del todo.**

### Paralelismo y camino crítico

- **Gates**: cada punto del grafo donde, completado un ítem, se desbloquean varios que no dependen entre sí. Numeralos desde `GATE 0` y marcá con `← FORK` los que abren más de 2 ramas.
- **Camino crítico**: la cadena lineal más corta desde el primer ítem hasta el último indispensable para producción. Sin restyle, dashboards extra ni features opcionales. Si hay dos candidatos a último, marcá ambos con `*`.

---

## Workflow

1. Correr los pre-checks.
2. Leer la KB, `GLOSSARY.md` y `docs/adr/`.
3. Identificar los ítems y agruparlos en fases con nombre semántico.
4. Asignar IDs, dependencias y governance.
5. Calcular árbol, gates y camino crítico.
6. Escribir el cuerpo en un archivo temporal (fuera del repo) con la plantilla y pasar su checklist.
7. **Confirmar con el usuario** antes de publicar: mostrá el repo destino (`nameWithOwner`), el título, la cantidad de ítems por fase y la ruta del borrador. Esperá un sí explícito. Si el repo no es del usuario o no es el que esperaba, no publiques.
8. Publicar:

   ```bash
   gh label create roadmap --description "Plan de specs del proyecto" --color 0E8A16 --force
   gh issue create --title "Roadmap: <NombreProyecto>" --label roadmap --body-file "<borrador>"
   ```

9. Cerrar con el próximo paso.

## Próximo paso

Cerrá con este mensaje y frená; no lances `agent-instruction` vos.

```
Roadmap publicado: <url del issue> — <N> ítems en <M> fases, camino crítico de <K>, primer ítem R-01 (<nombre>).
Próximo paso: agent-instruction — genera AGENTS.md a partir de la KB y del roadmap.
```

---

## Resources

- [assets/roadmap-template.md](assets/roadmap-template.md): plantilla del cuerpo del issue, con ejemplo y checklist.
