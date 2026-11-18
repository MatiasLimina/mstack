# State Contract — roadmap-generator owns `state.roadmap`

Reference: C-13a frozen contract (`.active-orchestrator-state.json` v2, §4.2 I/O matrix).

---

## 1. Schema slice

roadmap-generator is the **sole writer** of the `roadmap` object inside `.active-orchestrator-state.json`.
It NEVER touches `step`, `owner`, `kb`, `skills`, or `agents`.

```json
{
  "version": 2,
  "roadmap": {
    "created_by": "roadmap-generator",
    "source": "CHANGES.md",
    "changes_file": "CHANGES.md",
    "changes": ["C-01", "C-02", "C-03"]
  }
}
```

Fields:

| Field | Type | Description |
|---|---|---|
| `created_by` | string | Always `"roadmap-generator"` — identifies the writer (mirrors `state.kb.created_by`). |
| `source` | string | Path of the generated index — always `"CHANGES.md"` (mirrors how `state.kb.files` records produced paths). |
| `changes_file` | string | Ruta del roadmap que verifica la fundación, igual a `source`. |
| `changes` | string[] | The `C-NN` change IDs generated, in order — lets downstream phases and the orchestrator know the roadmap content without re-parsing `CHANGES.md`. |

**Thin index rationale**: per-change scope, governance, and dependencies stay ONLY in `CHANGES.md` (single source of truth). The slice is a thin index only — no duplication, no drift.

---

## 2. Conditional write algorithm

Run this hook **after** `CHANGES.md` is fully written, before returning to the user.

```
1. Check project root for `.active-orchestrator-state.json`
   ├─ ABSENT  → no-op. Do NOT create the file. Done.
   ├─ PRESENT, versión ausente, no numérica o menor que 2 → surface one-line note:
   │    "Versión de estado incompatible. Se conserva el archivo de estado."
   │    Continue. Done.
   └─ PRESENT, version >= 2 → update ONLY state.roadmap:
        • Set created_by: "roadmap-generator"
        • Set source and changes_file: "CHANGES.md"
        • Set changes: list of C-NN IDs generated (in order)
        Preserve all other fields and sections. Write the JSON back. Done.
```

**Why never create**: the orchestrator (active-orchestrator) is the sole creator of the state file (C-13a D3). roadmap-generator updating-only avoids two writers racing to create it.

**Why strictly conditional**: roadmap-generator is a public standalone skill. Forcing a state file on every direct invocation would regress standalone projects and pollute non-orchestrated repos.

**Why never touch `step`**: the orchestrator owns `step` advancement. roadmap-generator signals completion only by writing `state.roadmap`, which the orchestrator verifies before advancing the confirmed plan.

---

## 3. Orchestrated input rules

When running orchestrated (`.active-orchestrator-state.json` present and `version >= 2`):

### 3.1 Reading KB files

- **Primary**: use `state.kb.files` as the authoritative list of `knowledge-base/*.md` paths to read, instead of globbing the directory. This is robust when the KB lives at a non-default path or has extras.
- **Fallback**: if `state.kb.files` is empty or absent, fall back to globbing `knowledge-base/` on disk (the standalone read path) so the phase still produces `CHANGES.md`.

### 3.2 Using `state.kb.discovery`

- Read `state.kb.discovery` as **context** for naming/grouping changes and inferring governance:
  - `needs_infra: true` → check whether an infrastructure task is still needed before putting it in the roadmap
  - `system_type` → seed the FASE names (e.g. `web_app` → FASE 1: Infraestructura + Auth)
  - `domain` → infer domain-specific changes (e.g. ecommerce → categories/products/cart/checkout)
  - `scale` → infer whether RBAC or multi-tenancy changes are needed
- **Discovery is a hint only**: the KB files (`state.kb.files`) remain the source of truth for change scope. A wrong discovery field degrades naming quality but does NOT corrupt scope correctness.

### 3.3 Pre-checks when orchestrated

When `state.kb.files` is populated and used as the file list:
- Skip the `knowledge-base/` directory existence pre-check (files are resolved from state).
- Still verify that the listed files exist on disk before reading them.

When falling back to disk glob (no state or empty `state.kb.files`):
- Run the standard KB pre-checks (see SKILL.md §Critical Patterns).

### 3.4 Standalone invariant

With no `.active-orchestrator-state.json`:
- Generá el roadmap a partir de la KB con las mismas comprobaciones de archivos que en la ruta orquestada.
- The "Si orquestado" hook (§2) and the `state.kb` read (§3.1–3.2) never fire.
- No state file is created.
