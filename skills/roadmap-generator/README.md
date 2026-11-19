# roadmap-generator

Skill que publica el **plan de specs** de un proyecto nuevo como un único issue de roadmap en GitHub, a partir de su base de conocimiento.

---

## ¿Qué hace?

Lee `knowledge-base/`, `GLOSSARY.md` y `docs/adr/` y publica un issue `Roadmap: <Proyecto>` con label `roadmap`, que contiene:

- **Árbol de dependencias** (ASCII jerárquico).
- **Paralelismo** con gates explícitos.
- **Camino crítico**: el mínimo irreducible para llegar a producción.
- **Task list**: una línea por spec futura, con ID `R-NN`, alcance, governance (LOW/MEDIUM/HIGH/CRITICAL), dependencias y qué leer antes.

No escribe archivos en el repo ni crea issues hijos. Antes de publicar te muestra el repo destino y espera tu confirmación.

---

## Dónde encaja

Es el tercer paso de la fundación:

`discovery-research` (opcional) → `kb-creator` → **`roadmap-generator`** → `agent-instruction` → `/setup-matt-pocock-skills`

Después, cada ítem del roadmap entra al workflow normal: `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/implement`. Cuando la spec de un ítem existe como `#N`, su línea pasa a `- [ ] R-NN #N`.

---

## Pre-requisitos

- `knowledge-base/` con los 9 canónicos (`01` a `08` y `10`). Si falta alguno, la skill avisa y no publica.
- `gh` logueado y un remote de GitHub.
- Ningún issue abierto con label `roadmap`. Si ya hay uno, la skill propone editarlo.

---

## Uso

```
Le decís al agente:
"armá el roadmap del proyecto"
```

Al terminar:

```
Roadmap publicado: https://github.com/<owner>/<repo>/issues/1 — 10 ítems en 4 fases, camino crítico de 7, primer ítem R-01 (foundation-setup).
Próximo paso: /agent-instruction — genera AGENTS.md a partir de la KB y del roadmap.
```

---

## Niveles de governance

| Nivel | Cuándo se usa |
|-------|---------------|
| **LOW** | Scaffolding, CRUDs simples, pantallas sin lógica crítica. |
| **MEDIUM** | Lógica de negocio, flujos con estado, adapters. |
| **HIGH** | Config que afecta datos del usuario, roles, notificaciones, observabilidad. |
| **CRITICAL** | Auth, pagos, seguridad, audit trail, modelos core. |

Son los mismos niveles que usa el gate final del `CLAUDE.md` global.

---

## Licencia

Apache-2.0. Deriva de [Group-Active-IA/roadmap-generator](https://github.com/Group-Active-IA/roadmap-generator); ver `NOTICE.md` en la raíz de mstack.
