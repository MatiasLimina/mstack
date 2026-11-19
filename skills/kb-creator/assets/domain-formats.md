# Domain Formats — GLOSSARY.md y ADRs

Son los formatos de la skill `domain-modeling` de Matt Pocock (`GLOSSARY-FORMAT.md` y
`ADR-FORMAT.md`). Respetalos al pie de la letra, incluidos los encabezados en inglés
(`## Language`, `_Avoid_:`): `/grill-with-docs` y `domain-modeling` extienden estos
archivos después y esperan exactamente esta forma.

---

## GLOSSARY.md

Un solo `GLOSSARY.md` en la raíz del proyecto (repo de un solo contexto).

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request
```

Reglas:

- **Opinado.** Cuando hay varias palabras para el mismo concepto, elegí la mejor y listá las otras en `_Avoid_`. Las palabras que aparecen en las fuentes con el mismo significado son las candidatas naturales.
- **Definiciones cortas.** Una o dos oraciones: qué ES, no qué hace.
- **Solo términos de este dominio.** Conceptos generales de programación (timeouts, tipos de error, utilidades) no entran.
- **Sin detalles de implementación.** El glosario es un glosario: ni spec, ni decisiones, ni stack.
- **Subtítulos** (`### ...` dentro de `## Language`) cuando aparecen grupos naturales de términos; si son todos de un mismo área, lista plana.

---

## ADRs

Van en `docs/adr/` con numeración secuencial: `0001-slug.md`, `0002-slug.md`. Para
numerar, buscá el número más alto en `docs/adr/` y sumá uno. Creá la carpeta recién
cuando haya un primer ADR.

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

Un ADR puede ser un solo párrafo: el valor está en registrar *que* se tomó la
decisión y *por qué*. Secciones opcionales, solo cuando aportan:

- Frontmatter **Status** (`proposed | accepted | deprecated | superseded by ADR-NNNN`): cuando la decisión se revisa.
- **Considered Options**: cuando vale la pena recordar las alternativas descartadas.
- **Consequences**: cuando hay efectos no obvios que conviene marcar.

### Filtro ADR

Una decisión se vuelve ADR solo si cumple las tres:

1. **Difícil de revertir**: cambiar de idea después cuesta.
2. **Sorprendente sin contexto**: alguien que lea el código se va a preguntar "¿por qué lo hicieron así?".
3. **Resultado de un trade-off real**: había alternativas genuinas y se eligió una por razones concretas.

Lo que suele calificar: la forma de la arquitectura, los patrones de integración
entre partes, las tecnologías con lock-in (base de datos, auth, proveedor de deploy),
las decisiones de alcance y límites (los "no" valen tanto como los "sí"), los desvíos
deliberados del camino obvio, las restricciones que no se ven en el código
(compliance, contratos con terceros) y las alternativas descartadas por razones no
obvias.

Una decisión que no pasa el filtro queda como una línea en el archivo de la KB donde
se aplica. Un supuesto nunca es un ADR: va a "Supuestos a validar" en
`10_preguntas_abiertas.md`.
