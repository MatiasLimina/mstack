# Plantilla del issue de roadmap

Cuerpo del issue `Roadmap: <NombreProyecto>`. Adaptá nombres y contenido al dominio, pero respetá las secciones, su orden y el formato de cada línea de la task list.

---

~~~~markdown
> Plan de specs de **{NombreProyecto}**, generado desde `knowledge-base/`.
> Cada ítem es una spec futura: todavía no tiene issue propio.

## Cómo usar este roadmap

1. Elegí un ítem cuyas dependencias (`deps`) ya estén cerradas. El camino crítico marca cuáles conviene priorizar.
2. Leé los punteros de `leer` del ítem.
3. Corré `/grill-with-docs` sobre el ítem y después `/to-spec`.
4. Cuando la spec exista como issue `#N`, editá este roadmap y dejá la línea del ítem como `- [ ] R-NN #N`: se conserva el ID y se reemplaza el resto. GitHub muestra el título y el estado de la spec en esa línea.
5. Los IDs `R-NN` no se renumeran ni se reciclan. Las dependencias, el árbol y el camino crítico los usan.

## Árbol de dependencias

```
R-01 foundation-setup
  └── R-02 core-models
        └── R-03 auth                          ← desbloquea TODO lo demás
              │
              ├── R-04 menu-catalog
              │     ├── R-05 allergens
              │     └── R-06 sectors-tables
              │
              ├── R-07 ingredients             ← paralelo con R-04
              │
              └── R-08 dashboard-shell         ← solo necesita R-03
                    └── R-09 dashboard-pages   ← + R-04 + R-05
```

### Paralelismo

Cada gate es un punto de sincronización: los ítems de un mismo gate se pueden trabajar en paralelo.

```
GATE 0: ninguno
  → R-01

GATE 1: R-01 ✓
  → R-02

GATE 2: R-02 ✓
  → R-03

GATE 3: R-03 ✓                     ← FORK (3 paralelos)
  → R-04 menu-catalog
  → R-07 ingredients
  → R-08 dashboard-shell

GATE 4: R-04 ✓
  → R-05 allergens
  → R-06 sectors-tables

GATE 5: R-08 + R-04 + R-05 ✓
  → R-09 dashboard-pages
```

### Camino crítico (5 ítems)

```
R-01 → R-02 → R-03 → R-04 → R-09
```

## Fase 0 — Cimientos

- [ ] R-01 `foundation-setup` — monorepo backend/ + frontend/; FastAPI con /api/health y Alembic; Vite + React + TS; .env.example por subproyecto; CI con jobs paralelos · **LOW** · deps: — · leer: knowledge-base/01_vision_y_objetivos.md, knowledge-base/02_descripcion_general.md §Stack, knowledge-base/08_arquitectura_propuesta.md §Estructura de directorios, docs/adr/0001-stack.md
- [ ] R-02 `core-models` — Tenant, User, Role, UserRole; AuditMixin con soft delete; BaseRepository y UnitOfWork; migración 001; seed de 1 tenant y 1 admin · **CRITICAL** · deps: R-01 · leer: knowledge-base/04_modelo_de_datos.md §Entidades core, knowledge-base/08_arquitectura_propuesta.md §Patrones, GLOSSARY.md, docs/adr/0002-multi-tenant.md

## Fase 1 — Autenticación

- [ ] R-03 `auth` — POST /api/auth/login con JWT access + refresh y rate limit 5/60s; refresh con rotación y blacklist; logout; GET /api/auth/me; require_role(); refresh en cookie HttpOnly; migración 002 · **CRITICAL** · deps: R-02 · leer: knowledge-base/03_actores_y_roles.md, knowledge-base/05_reglas_de_negocio.md §Autenticación, knowledge-base/07_flujos_principales.md §Auth

## Fase 2 — Dominio principal

- [ ] R-04 `menu-catalog` — Category, Subcategory, Product; CRUD /api/admin/*; GET /api/public/menu cacheado 5 min; precios en centavos; migración 003 · **LOW** · deps: R-03 · leer: knowledge-base/04_modelo_de_datos.md §Catálogo, knowledge-base/05_reglas_de_negocio.md §Catálogo, knowledge-base/07_flujos_principales.md §Catálogo público
- [ ] R-05 `allergens` — Allergen, ProductAllergen, reacciones cruzadas; filtro por alérgeno en el menú público; migración 004 · **CRITICAL** · deps: R-04 · leer: knowledge-base/05_reglas_de_negocio.md §Alérgenos, knowledge-base/04_modelo_de_datos.md §Alérgenos, GLOSSARY.md

(seguí el patrón hasta cubrir todos los ítems)
~~~~

---

## Checklist antes de publicar

- [ ] No hay título `#` en el cuerpo: el título va en `--title`.
- [ ] "Cómo usar este roadmap" tiene los 5 pasos, incluido el paso de `R-NN #N`.
- [ ] El árbol usa `└──` y `│`, y nombra los ítems como `R-NN nombre`.
- [ ] Hay un gate por cada punto donde se abren ramas paralelas.
- [ ] El camino crítico es una sola flecha lineal.
- [ ] Cada ítem es **una** línea `- [ ] R-NN ...` con nombre, alcance, governance, deps y leer.
- [ ] Cada governance es `LOW`, `MEDIUM`, `HIGH` o `CRITICAL`.
- [ ] Cada `deps` lista IDs que existen en el roadmap, o `—`.
- [ ] Cada `leer` tiene 3 a 5 punteros a archivos que existen (`knowledge-base/`, `docs/adr/`, `GLOSSARY.md`).
- [ ] Las fases tienen nombre semántico, no solo "Fase 1, 2, 3".
