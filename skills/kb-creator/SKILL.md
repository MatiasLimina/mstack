---
name: kb-creator
description: >
  Arma la base de conocimiento de un proyecto: 9 archivos canónicos en knowledge-base/, el vocabulario del dominio en GLOSSARY.md y las decisiones de diseño como ADRs en docs/adr/, con los formatos de domain-modeling de Matt. Dos modos: silencioso desde documentos fuente en docs/, o interactivo desde cero. Lee discovery/discovery.md si existe. Al terminar, cierra siempre con la línea `Próximo paso: /roadmap-generator`.
  Trigger: When user asks to create, build, or generate a knowledge base for a project, document a project from source documents (.txt, .docx, .pdf), or asks to "armar base de conocimiento" / "crear KB" / "documentar proyecto".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

<!-- Origen: Group-Active-IA/kb-creator@e204c47 (Apache-2.0). Ver NOTICE.md.
     assets/domain-formats.md deriva de domain-modeling (mattpocock/skills, MIT).
     Cambios: 9 canónicos (sale 09_decisiones_y_supuestos; las decisiones pasan a
     ADRs en docs/adr/ y los supuestos a 10_preguntas_abiertas); vocabulario en
     GLOSSARY.md con los formatos de domain-modeling de Matt; lee
     discovery/discovery.md de disco; sin orquestador ni archivo de estado (se
     borró assets/state-contract.md); sin mención a OpenSpec; cierra indicando
     roadmap-generator; no se copió tests/. -->

> **Cierre obligatorio.** El mensaje con el que termina esta skill lleva
> siempre, como última línea, el `Próximo paso: …` de la sección
> [Próximo paso](#próximo-paso), aunque la conversación haya sido larga o
> cierres con un resumen. Sin esa línea la cadena de fundación se corta: el
> usuario no sabe qué correr después.

## When to Use

- Generar una base de conocimiento estructurada y navegable para un proyecto.
- Convertir documentos monolíticos (`.txt`, `.docx`, `.pdf`, `.md` largos) en una KB temática.
- Documentar un sistema desde cero acompañando al usuario como socio estratégico.

**Don't use when:**
- Ya existe `knowledge-base/` con los 9 archivos canónicos completos (sugerí actualizar archivos puntuales en su lugar).
- El usuario pide UN documento específico (es una skill de KB completa, no de archivos sueltos).

---

## Qué produce

| Salida | Contenido | Formato |
|---|---|---|
| `knowledge-base/` | 9 archivos canónicos + extras opcionales + `README.md` índice | [assets/canonical-templates.md](assets/canonical-templates.md) |
| `GLOSSARY.md` (raíz) | Vocabulario del dominio | [assets/domain-formats.md](assets/domain-formats.md) |
| `docs/adr/NNNN-slug.md` | Decisiones de diseño que cumplen el filtro ADR | [assets/domain-formats.md](assets/domain-formats.md) |

`knowledge-base/` va en la **raíz del proyecto**, separada de `docs/` (que contiene los documentos fuente). La única salida dentro de `docs/` es `docs/adr/`.

### Canonical files (9 obligatorios)

| # | Archivo | Contenido |
|---------|---------|-----------|
| 01 | `01_vision_y_objetivos.md` | Propósito, objetivos por actor, alcance, fuera de alcance |
| 02 | `02_descripcion_general.md` | Stack tecnológico, arquitectura general, integraciones externas |
| 03 | `03_actores_y_roles.md` | Actores del sistema, tabla RBAC, permisos, rutas públicas |
| 04 | `04_modelo_de_datos.md` | Entidades, ERD, relaciones, seed data |
| 05 | `05_reglas_de_negocio.md` | Reglas codificadas por dominio (con códigos tipo RN-XX) |
| 06 | `06_funcionalidades.md` | Historias de usuario / features organizadas por épica |
| 07 | `07_flujos_principales.md` | Flujos extremo a extremo (auth, dominio principal, etc.) |
| 08 | `08_arquitectura_propuesta.md` | Patrones, estructura de directorios, seguridad, env vars |
| 10 | `10_preguntas_abiertas.md` | Inconsistencias, supuestos a validar y preguntas abiertas priorizadas |

El número 09 queda vacío a propósito: las referencias por número siguen apuntando al archivo correcto.

Si el dominio lo requiere, sumá extras con prefijo `1X_` o `2X_` y nombre kebab-case (ej. `11_pagos_mercadopago.md`, `12_devops_y_despliegue.md`). Los extras complementan a los 9 canónicos.

### Vocabulario y decisiones

- **Términos**: cada término del dominio se define **una sola vez**, en `GLOSSARY.md`. Los archivos de la KB lo usan en negrita con link al glosario (`[**Turno**](../GLOSSARY.md)`) y no lo redefinen. Un término de actor se define en el glosario; `03` describe sus permisos.
- **Decisiones**: una decisión de diseño va a un ADR solo si pasa el filtro ADR de [assets/domain-formats.md](assets/domain-formats.md) (difícil de revertir, sorprendente sin contexto, resultado de un trade-off real). Una decisión que no lo pasa queda como una línea en el archivo temático donde se aplica (stack en `02`, patrones en `08`). Un proyecto con stack decidido tiene al menos un ADR: las tecnologías con lock-in (base de datos, auth, deploy) pasan el filtro.
- **Supuestos**: todo supuesto inferido va a `10_preguntas_abiertas.md`, sección "Supuestos a validar".
- **Archivos existentes**: si `GLOSSARY.md` o `docs/adr/` ya existen (por ejemplo, de un `/grill-with-docs` anterior), extendelos: sumá los términos que faltan y numerá los ADRs nuevos a partir del más alto. Los términos y ADRs existentes quedan como están; si la KB los contradice, registrá la contradicción en `10_preguntas_abiertas.md`.

### Discovery previo (opcional)

Si existe `discovery/discovery.md` (lo escribe `discovery-research`), leelo en los dos modos, antes de preguntar o inferir. Cada sección alimenta la KB:

| Sección de `discovery.md` | Va a |
|---|---|
| 1. Problema que resuelve | `01` (propósito) |
| 2. Usuarios / roles | `03` y términos de actor en `GLOSSARY.md` |
| 3. Casos de uso | `06` y `07` |
| 4. Competidores / soluciones existentes | `01` (contexto); las notas de `discovery/sources/` como referencia |
| 5. Funcionalidades necesarias | `06` (alcance del MVP en `01`) |
| 6. Funcionalidades opcionales | `01` las nombra en "Fuera de alcance"; `06` las detalla en una épica posterior |
| 7. Reglas de negocio | `05` |
| 8. Integraciones | `02` |
| 9. Restricciones | `02` y `08`; una restricción que no se ve en el código es un ADR |
| 10. Riesgos | `10` (supuestos a validar) |
| 11. Preguntas abiertas | `10` |

Si no existe, la skill corre igual, con las fuentes de `docs/` o las preguntas del Mode B.

---

## Operating Modes

Si hay una KB parcial, conservá los documentos existentes: usalos como entrada, acordá con el usuario cómo completar los faltantes y escribí solo los pendientes.

### Mode A — From existing source docs (silent)

**Trigger automático**: `docs/` contiene archivos fuente (`.txt`, `.docx`, `.pdf`, o `.md` distintos a un README). `docs/adr/` y `docs/agents/` son salidas de skills, no fuentes: no cuentan para el trigger ni se leen como fuente.

1. Enumerá las fuentes de `docs/` (las de arriba) y leelas todas, junto con `discovery/discovery.md` si existe.
2. Para cada archivo canónico, extraé el contenido relevante y estructuralo siguiendo `assets/canonical-templates.md`. Si `discovery.md` y `docs/` se contradicen, registrá la discrepancia en `10_preguntas_abiertas.md` en lugar de elegir una.
3. Extraé los términos del dominio a `GLOSSARY.md` y las decisiones que pasan el filtro a `docs/adr/`.
4. Si una fuente cubre dominios extra (ej. pagos con un PSP específico), creá un archivo extra `1X_*.md`.
5. Escribí los 9 canónicos + extras + `README.md` índice + `GLOSSARY.md` + ADRs.
6. Cerrá con la tabla resumen (ver Code Examples) y el próximo paso.

**No hagas preguntas en este modo.** Si una fuente es ambigua, registrá la duda en `10_preguntas_abiertas.md` y seguí.

### Mode B — From scratch (interactive)

**Trigger automático**: `docs/` no existe o no tiene fuentes, **y** `knowledge-base/` no existe en raíz.
**Trigger explícito**: el usuario dice "armemos desde cero", "construyamos la KB", "no tengo documentación previa".

1. Analizá el contexto disponible (nombre del repo, mensaje del usuario, archivos visibles, `discovery/discovery.md` si existe).
2. Resumí en un párrafo qué entendés del proyecto.
3. Listá las **incertidumbres principales** (3-5).
4. Proponé 2-3 enfoques iniciales con pros y contras.
5. Hacé las **3-5 preguntas estratégicas** de `assets/strategic-questions.md`. Lo que ya responde `discovery.md` no se pregunta de cero: mostralo como resumen a confirmar.
6. Esperá respuesta del usuario antes de generar archivos.
7. Proponé la estructura inicial de la KB, los términos del glosario y las decisiones candidatas a ADR, y validá.
8. Iterá archivo por archivo, escribiendo + pidiendo feedback.
9. Cerrá con el próximo paso.

### Tono según modo
- **Mode A**: eficiente, factual, sin floreos.
- **Mode B**: arquitecto senior + product manager. Cuestiona decisiones débiles. Marcá supuestos con `**Suposición:**`. Proponé alternativas. Detectá riesgos.

---

## Próximo paso

Cerrá con este mensaje y frená; no lances `roadmap-generator` vos.

```
KB lista: knowledge-base/ (9 canónicos + <N> extras), GLOSSARY.md (<T> términos), docs/adr/ (<A> ADRs)
Próximo paso: /roadmap-generator — arma el plan de trabajo a partir de la KB.
```

---

## Code Examples

### Mode A: tabla resumen al cerrar

```markdown
## KB generada

| Archivo | Líneas | Temas cubiertos |
|---------|--------|-----------------|
| knowledge-base/01_vision_y_objetivos.md | 84 | Propósito, 3 actores, alcance v5.0 |
| knowledge-base/02_descripcion_general.md | 132 | FastAPI + React, REST, 14 endpoints |
| ... | | |
| GLOSSARY.md | 40 | 12 términos |
| docs/adr/0001-postgres-como-base.md | 3 | Base de datos |
```

### Mode B: pregunta estratégica modelo

```markdown
**Pregunta 2 de 4 — Alcance del MVP**

¿Cuál es el alcance MÍNIMO viable para considerar el sistema "lanzable"?

- (a) Solo flujo de compra (catálogo + carrito + checkout simulado).
- (b) Flujo completo con pago real integrado.
- (c) Pago + panel admin con métricas.

**Por qué importa**: define qué entra en la primera versión y qué se posterga. Una respuesta vaga acá te genera scope creep en sprint 2.
```

---

## Resources

- **Templates**: [assets/canonical-templates.md](assets/canonical-templates.md) — estructura interna de los 9 archivos canónicos y del índice.
- **Domain formats**: [assets/domain-formats.md](assets/domain-formats.md) — formato de `GLOSSARY.md`, de los ADRs y el filtro ADR.
- **Strategic questions**: [assets/strategic-questions.md](assets/strategic-questions.md) — banco de preguntas para Mode B.
