# mstack

Mi stack personal de skills para agentes (Claude Code y T3 Code), armado
tomando lo que más me sirve de otros stacks y adaptándolo a mi forma de
trabajar.

## Skills

| Skill | Decí | Qué hace | Origen |
|---|---|---|---|
| `gemini-loop` | "gemini loop" | Revisa un cambio con un revisor Gemini en loop hasta que los dos agentes estén de acuerdo. | Adaptada de `sol-loop` ([tstack](https://github.com/t3dotgg/tstack)) |
| `file-pr` | "abrí el PR" | Abre un PR con título y descripción concisos, sin secretos. | Adaptada de `file-pr` ([tstack](https://github.com/t3dotgg/tstack)) |
| `babysit-pr` | "vigilá el PR" | Vigila CI y reviews del PR hasta que esté listo para mergear. Incluye `pr-wait`. | Adaptada de `babysit-pr` ([tstack](https://github.com/t3dotgg/tstack)) |
| `council` | "council" | Convoca a Opus, Gemini Neon y un tercer modelo a elección para revisar o dar feedback. | Adaptada de `council` ([tstack](https://github.com/t3dotgg/tstack)) |
| `design-studio` | `/design-studio` | Explora un diseño (web, móvil, escritorio o imagen): Gemini Neon lidera, tres diseñadores proponen en paralelo y elegís entre capturas. La ganadora queda en `docs/design/`. Solo la invocás vos. | Propia |
| `full-send` | "full send" | Lleva el cambio solo hasta un PR mergeado: prueba, code-review, gemini-loop, PR y vigilancia. | Adaptada de `full-send` ([tstack](https://github.com/t3dotgg/tstack)) |
| `full-stop` | "full stop" | Igual que `full-send`, pero deja el PR listo sin mergear. | Adaptada de `full-stop` ([tstack](https://github.com/t3dotgg/tstack)) |
| `opsx-orchestrator` | "opsx" | Modo orquestador OpenSpec (propose/apply/archive), opt-in para proyectos que usan `openspec/`. | Propia (antes vivía en el `CLAUDE.md` global) |
| `leaving-pr-comments` | (automática) | Formatea los comentarios que un agente deja en GitHub en tu nombre. La usan `file-pr` y `babysit-pr`. | Adaptada de `leaving-pr-comments` ([tstack](https://github.com/t3dotgg/tstack)) |
| `unslop` | `/unslop` | Saca de un texto las marcas típicas de la escritura de IA. Solo la invocás vos. | Copia de `unslop` ([pstack](https://github.com/cursor/plugins/tree/main/pstack)) |
| `discovery-research` | "investiguemos el producto" | Fundación, paso opcional: investiga competidores (con `web-scraper`) y guía una Q&A sobre el producto antes de la KB. Deja el resultado en `discovery/`. | Adaptada de [Group-Active-IA/discovery-research](https://github.com/Group-Active-IA/discovery-research) |
| `web-scraper` | "investigá este competidor: `<URL>`" | Saca de la URL de un competidor una nota con esquema fijo. La usa `discovery-research`. | Copia de [Group-Active-IA/web-scraper](https://github.com/Group-Active-IA/web-scraper) |
| `kb-creator` | "armá la KB" | Fundación: arma la base de conocimiento del proyecto en `knowledge-base/`, el vocabulario en `GLOSSARY.md` y las decisiones como ADRs en `docs/adr/`. | Adaptada de [Group-Active-IA/kb-creator](https://github.com/Group-Active-IA/kb-creator) |
| `roadmap-generator` | "armá el roadmap" | Fundación: publica el plan de trabajo como un issue de roadmap en GitHub, con una línea de task list por spec futura. | Adaptada de [Group-Active-IA/roadmap-generator](https://github.com/Group-Active-IA/roadmap-generator) |
| `agent-instruction` | "generá el AGENTS.md" | Fundación: escribe las instrucciones del proyecto en `AGENTS.md` (y un `CLAUDE.md` que lo importa) a partir de la KB y el roadmap, sin pisar las secciones ajenas como `## Agent skills`. | Adaptada de [JuanCruzRobledo/agent-instruction](https://github.com/JuanCruzRobledo/agent-instruction) |

## Workflow

El modo de trabajo de Matt Pocock con agregados. Los pasos con `/` los
escribís vos (esas skills no las puede invocar un agente); el resto lo encadena
el agente. Tracker en GitHub Issues: un PR por ticket.

```
/mattpocock-skills:grill-with-docs ─┬─ (trabado / dudas de diseño) ──→ council          [divergente]
                                    └─ (cómo se ve algo) ──→ /design-studio → docs/design/
                  ▼
/mattpocock-skills:to-spec        → issue de spec
                  ▼
/mattpocock-skills:to-tickets     → issues hijos con bloqueos
                  ▼
por ticket desbloqueado (rama <tipo>/<N>-<slug>):
  /mattpocock-skills:implement #N  (tdd + code-review) ── (mismo error 2 veces) ──→ advisor  [causa raíz]
                  ▼
  verify-<proyecto>                                                  [¿funciona de verdad?]
                  ▼
  gate final según governance                                        [convergente]
                  ▼
  file-pr (Closes #N) → babysit-pr   ← full-stop / full-send encadenan desde verify
```

Cada proyecto necesita antes `/mattpocock-skills:setup-matt-pocock-skills` con
GitHub como tracker.

Gate final según el nivel de governance del cambio (detalle en `config/CLAUDE.md`):

| Nivel | Revisión |
|---|---|
| LOW | Tests en verde |
| MEDIUM | `code-review` (Matt) |
| HIGH | `code-review` + `gemini-loop` |
| CRITICAL | `code-review` + `gemini-loop` + `council` |

### Fundación

Solo para proyectos grandes y vacíos; el resto arranca directo con
`/mattpocock-skills:grill-with-docs`. Es una cadena sin orquestador ni archivo
de estado: cada skill lee de disco o de GitHub lo que dejó la anterior y termina diciéndote
el próximo comando.

```
discovery-research (opcional, con web-scraper)   → discovery/
          ▼
kb-creator                                       → knowledge-base/, GLOSSARY.md, docs/adr/
          ▼
roadmap-generator                                → issue de roadmap en GitHub (task list)
          ▼
agent-instruction                                → AGENTS.md + CLAUDE.md (@AGENTS.md)
          ▼
/mattpocock-skills:setup-matt-pocock-skills      → agrega ## Agent skills a AGENTS.md
          ▼
agent-instruction (otra vez)                     → suma las skills de Matt, conserva ## Agent skills
```

Lo que produce cae en los formatos que ya leen las skills de Matt. Después,
cada ítem del issue de roadmap entra al workflow normal con
`/mattpocock-skills:grill-with-docs`; cuando `to-spec` crea la spec, el agente
deja la línea del ítem como `- [ ] R-NN #N` (conserva el ID y reemplaza el
resto) y GitHub la tilda sola al cerrarse la spec.

## Instalación

Clonar el repo y copiar (o enlazar) las skills a la carpeta de skills del agente:

```powershell
git clone https://github.com/MatiasLimina/mstack
Copy-Item -Recurse -Force "mstack\skills\*" "$env:USERPROFILE\.claude\skills\"
Copy-Item -Force "$env:USERPROFILE\.claude\CLAUDE.md" "$env:USERPROFILE\.claude\CLAUDE.md.bak"  # backup del global actual
Copy-Item -Force "mstack\config\CLAUDE.md" "$env:USERPROFILE\.claude\CLAUDE.md"
```

### Dependencias

El workflow usa skills de terceros que este repo no copia:

```powershell
# Matt Pocock (grill-with-docs, to-spec, implement, tdd, code-review): plugin, se actualiza solo
claude plugin marketplace add mattpocock/skills
claude plugin install mattpocock-skills@mattpocock --scope user

# pstack (Lauren Tan): solo las dos skills de verificación; el plugin entero suma ~40 skills que el workflow no usa
git clone https://github.com/cursor/plugins cursor-plugins
Copy-Item -Recurse -Force "cursor-plugins\pstack\skills\create-verification-skill" "$env:USERPROFILE\.claude\skills\"
Copy-Item -Recurse -Force "cursor-plugins\pstack\skills\maintain-verification-skill" "$env:USERPROFILE\.claude\skills\"
```

No mezcles el plugin de Matt con copias sueltas de sus skills en
`~/.claude/skills`: quedarían duplicadas.

Las skills de fundación vienen en este repo; no hace falta active-stack para
correrlas. Los agentes `advisor` y `scout` vienen de **active-stack**. Instalalo
antes, pero ojo: su install/update reescribe el `CLAUDE.md` global con bloques
`active-stack:sdd-*`; después de correrlo, volvé a copiar `config/CLAUDE.md`.

`config/CLAUDE.md` es el `CLAUDE.md` global: shell, workflow, governance,
gate final y preferencias. Reemplaza al tuyo (el bloque de instalación hace
backup en `CLAUDE.md.bak`).

### AGENTS.md en otros agentes

La fundación deja las instrucciones de cada proyecto en `AGENTS.md`, y el
`CLAUDE.md` del proyecto solo lo importa (`@AGENTS.md`).

- **Gemini CLI** lee `GEMINI.md` por defecto. Para que lea `AGENTS.md` en
  todos los proyectos, agregalo una vez a sus archivos de contexto en
  `$env:USERPROFILE\.gemini\settings.json` (si el archivo ya existe, sumá la
  clave sin pisar el resto):

  ```json
  {
    "context": {
      "fileName": ["AGENTS.md", "GEMINI.md"]
    }
  }
  ```

- **OpenCode** lee `AGENTS.md` sin configurar nada.

## Preferencias personales

Los modelos y presupuestos que pueden cambiar con el tiempo van en el
`CLAUDE.md` / `AGENTS.md`, no dentro de las skills, para poder actualizar las
skills sin perder la configuración. Cada skill documenta sus defaults.

## Licencia

[MIT](LICENSE). Las partes derivadas de terceros conservan su aviso en
[`NOTICE.md`](NOTICE.md).

## Créditos

Este stack se apoya en el trabajo de otros. Gracias a:

- **Theo Browne** — [tstack](https://github.com/t3dotgg/tstack) (MIT).
  `gemini-loop`, `file-pr`, `babysit-pr`, `council`, `full-send`,
  `full-stop` y `leaving-pr-comments` son adaptaciones de sus skills
  (`sol-loop` y las homónimas).
  Ver [`NOTICE.md`](NOTICE.md).
- **Matt Pocock** — [skills](https://github.com/mattpocock/skills) (MIT).
  El flujo `grill-with-docs` → `to-spec` → `implement` + `tdd` → `code-review`
  del workflow usa sus skills tal cual; este repo no copia su código.
- **Group-Active-IA** — [discovery-research](https://github.com/Group-Active-IA/discovery-research),
  [kb-creator](https://github.com/Group-Active-IA/kb-creator),
  [roadmap-generator](https://github.com/Group-Active-IA/roadmap-generator) y
  [web-scraper](https://github.com/Group-Active-IA/web-scraper) (Apache-2.0).
  Las skills de fundación homónimas se adaptaron de esos repos para el
  workflow con GitHub Issues (`web-scraper` es copia sin cambios).
  Ver [`NOTICE.md`](NOTICE.md).
- **Juan Cruz Robledo** — [agent-instruction](https://github.com/JuanCruzRobledo/agent-instruction) (Apache-2.0).
  `agent-instruction` es una adaptación de su skill.
  Ver [`NOTICE.md`](NOTICE.md).
- **Lauren Tan** — [pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT).
  La idea de una skill de verificación por proyecto (`create-verification-skill`)
  viene de ahí. `unslop` es una copia de su skill homónima.
  Ver [`NOTICE.md`](NOTICE.md).

Si alguna skill de este repo pasa a derivar de otro trabajo, su licencia y
autoría se agregan a `NOTICE.md` y al encabezado de la skill.
