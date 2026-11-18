# agent-instruction

Skill que genera el `AGENTS.md` / `CLAUDE.md` canónico de un proyecto a partir de su base de conocimiento (`knowledge-base/`) y su roadmap (`CHANGES.md`).

Consolida en un solo archivo:

- **Stack tecnológico** (desde `knowledge-base/02_descripcion_general.md`)
- **Referencia a la KB** (links a `knowledge-base/*.md`)
- **Skills disponibles por agente** (Backend Core / Aux / Frontend / Orquestación)
- **Roadmap de changes** (resumen de `CHANGES.md`: camino crítico, fases, primer change)
- **Reglas duras del proyecto** (contrato no negociable)

Las reglas se proponen según el stack detectado y se registran después de confirmarlas con el usuario. En fundación, la skill puede generar instrucciones, reutilizarlas o actualizar un bloque delimitado, según el plan aprobado.

## Instalación

```bash
npx skills add https://github.com/JuanCruzRobledo/agent-instruction
```

## Uso

Generá el `AGENTS.md` con:

```
"generar AGENTS.md" · "armar las reglas del proyecto" · "instrucciones para los agentes"
```

Pre-requisitos: `knowledge-base/` (corré `kb-creator`) y, opcionalmente, `CHANGES.md` (corré `roadmap-generator`).

## Estructura

```
agent-instruction/
├── SKILL.md                  # Skill principal
├── assets/
│   └── agents-template.md    # Plantilla completa de AGENTS.md
└── README.md
```

## Skills relacionadas

Parte de una trilogía que se encadena: `kb-creator` (documenta) → `roadmap-generator` (planifica) → `agent-instruction` (instruye).

## Licencia

Apache-2.0
