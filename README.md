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

## Workflow (en construcción)

```
grill-with-docs ─┬─ (trabado / dudas de diseño) ──→ council           [divergente]
                 ▼
to-spec → implement + tdd ── (mismo error 2 veces) ──→ advisor        [causa raíz]
                 ▼
verify-<proyecto>                                                     [¿funciona de verdad?]
                 ▼
code-review (Matt) ─ ¿cumple spec y estándares?                       [convergente, 1 modelo]
                 ▼
gemini-loop ─ gate cross-provider                                     [convergente]
                 ▼
file-pr → babysit-pr        ← full-stop encadena desde verify
```

Fundación (solo proyectos grandes): `discovery-research` → `kb-creator`.

## Instalación

Clonar el repo y copiar (o enlazar) las skills a la carpeta de skills del agente:

```powershell
git clone https://github.com/MatiasLimina/mstack
Copy-Item -Recurse -Force "mstack\skills\*" "$env:USERPROFILE\.claude\skills\"
```

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
  `gemini-loop`, `file-pr` y `babysit-pr` son adaptaciones de sus skills
  (`sol-loop`, `file-pr`, `babysit-pr`), y las ideas de `full-send` /
  `full-stop` y `council` vienen de ahí.
  Ver [`NOTICE.md`](NOTICE.md).
- **Matt Pocock** — [skills](https://github.com/mattpocock/skills) (MIT).
  El flujo `grill-with-docs` → `to-spec` → `implement` + `tdd` → `code-review`
  del workflow usa sus skills tal cual; este repo no copia su código.
- **Lauren Tan** — [pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT).
  La idea de una skill de verificación por proyecto (`create-verification-skill`)
  viene de ahí; este repo no copia su código.

Si alguna skill de este repo pasa a derivar de otro trabajo, su licencia y
autoría se agregan a `NOTICE.md` y al encabezado de la skill.
