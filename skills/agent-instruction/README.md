# agent-instruction

Skill que genera las instrucciones de un proyecto en `AGENTS.md` a partir de su base de conocimiento (`knowledge-base/`, `GLOSSARY.md`, `docs/adr/`) y de su issue de roadmap en GitHub. `CLAUDE.md` queda con una sola línea, `@AGENTS.md`.

El contenido va dentro de un bloque delimitado por `<!-- active-stack:agent-instruction -->`. Al regenerar, la skill reescribe solo ese bloque y conserva textual el resto del archivo, por ejemplo la sección `## Agent skills` de `/setup-matt-pocock-skills`.

El bloque tiene:

- **Stack tecnológico** (desde `knowledge-base/02_descripcion_general.md`)
- **Base de conocimiento** (links a `knowledge-base/*.md`, `GLOSSARY.md` y `docs/adr/`)
- **Skills disponibles por agente** (de las skills instaladas)
- **Roadmap** (resumen del issue: ítems, camino crítico, primer ítem)
- **Reglas duras del proyecto**, propuestas según el stack y confirmadas con el usuario
- **Flujo de trabajo** con issues: roadmap → spec → tickets → PR

## Uso

```
"generar AGENTS.md" · "armar las reglas del proyecto" · "regenerá AGENTS.md"
```

Pre-requisitos: `knowledge-base/` (corré `kb-creator`) y, opcionalmente, el issue de roadmap (corré `roadmap-generator`).

En la cadena de fundación corre dos veces: antes y después de `/setup-matt-pocock-skills`.

## Estructura

```
agent-instruction/
├── SKILL.md                  # Skill principal
├── assets/
│   └── agents-template.md    # Plantilla del bloque de AGENTS.md
└── README.md
```

## Skills relacionadas

`kb-creator` (documenta) → `roadmap-generator` (planifica) → `agent-instruction` (instruye).

## Licencia

Apache-2.0
