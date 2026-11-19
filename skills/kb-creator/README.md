# kb-creator

Skill para construir **bases de conocimiento estructuradas** (9 archivos canónicos `.md`, más el glosario y los ADRs) sobre cualquier proyecto, automáticamente o de forma iterativa.

---

## ¿Qué hace?

Genera una base de conocimiento navegable y consistente en `knowledge-base/` (raíz del proyecto) siguiendo un contrato de **9 archivos canónicos** que cubren todos los aspectos críticos de un sistema:

1. Visión y objetivos
2. Descripción general
3. Actores y roles
4. Modelo de datos
5. Reglas de negocio
6. Funcionalidades
7. Flujos principales
8. Arquitectura propuesta
10. Preguntas abiertas (incluye los supuestos a validar)

El 09 queda vacío a propósito. Además escribe, con los formatos de la skill `domain-modeling` de Matt Pocock:

- `GLOSSARY.md` en la raíz: el vocabulario del dominio, cada término definido una sola vez.
- `docs/adr/NNNN-slug.md`: las decisiones de diseño difíciles de revertir.

Si existe `discovery/discovery.md` (de `discovery-research`), lo usa como insumo.

Tiene **dos modos** que se activan automáticamente:

- **Mode A — silent**: si tu carpeta `docs/` ya tiene documentos fuente (`.txt`, `.docx`, `.pdf`, `.md`), genera la KB completa sin hacer preguntas.
- **Mode B — interactive**: si no hay documentación previa, actúa como **arquitecto senior + product manager**, haciéndote 3-5 preguntas estratégicas por ronda hasta construir la KB de forma colaborativa.

---

## Instalación

Viene en mstack: se instala con el resto de las skills (ver el `README.md` de
la raíz). Es el paso de la fundación que sigue a `discovery-research` (opcional) y
se carga cuando le pedís al agente crear, generar o armar una base de
conocimiento. Al terminar te indica el próximo paso: `roadmap-generator`.

---

## Uso

### Mode A (silent) — proyecto con documentos fuente

```
Tu repo:
proyecto/
├── docs/
│   ├── descripcion.txt
│   ├── historias_de_usuario.docx
│   └── arquitectura.pdf

Le decís al agente:
"creá la base de conocimiento del proyecto"
```

→ El agente lee los 3 documentos de `docs/` y genera `knowledge-base/` en la raíz con los 9 archivos + `README.md` índice, más `GLOSSARY.md` y `docs/adr/`.

### Mode B (interactive) — proyecto desde cero

```
Tu repo:
proyecto/
└── (sin docs/ o vacío)

Le decís al agente:
"armemos la base de conocimiento desde cero"
```

→ El agente empieza haciendo 3-5 preguntas estratégicas (visión, alcance, actores, restricciones técnicas, prioridades), iteran, y va construyendo la KB archivo por archivo con tu validación.

---

## Estructura de la KB generada

```
proyecto/
├── GLOSSARY.md                        # Vocabulario del dominio
├── docs/                              # Documentos fuente (entrada)
│   ├── descripcion.txt
│   ├── ...
│   └── adr/                           # Decisiones de diseño (salida)
│       └── 0001-xxx.md
└── knowledge-base/                    # KB generada (salida) — RAÍZ del proyecto
    ├── README.md                      # Índice + resumen ejecutivo
    ├── 01_vision_y_objetivos.md
    ├── 02_descripcion_general.md
    ├── 03_actores_y_roles.md
    ├── 04_modelo_de_datos.md
    ├── 05_reglas_de_negocio.md
    ├── 06_funcionalidades.md
    ├── 07_flujos_principales.md
    ├── 08_arquitectura_propuesta.md
    ├── 10_preguntas_abiertas.md
    └── 11_xxx.md, 12_xxx.md, ...      # Extras opcionales según dominio
```

Los 9 canónicos son **siempre obligatorios**. Si el dominio lo requiere (ej. e-commerce con pasarela de pago específica), la skill agrega archivos extra con prefijo `1X_` y nombre kebab-case.

---

## Por qué esta estructura

- **Consistencia**: cualquier proyecto documentado con esta skill comparte la misma estructura → onboarding más rápido.
- **Compatibilidad con las skills de Matt**: `grill-with-docs`, `to-spec` y `to-tickets` leen `GLOSSARY.md` y `docs/adr/`, y los extienden sin reescribirlos. La KB es además la entrada de `roadmap-generator`, el próximo paso.
- **Trazabilidad de decisiones**: cada decisión difícil de revertir queda en un ADR con su porqué → menos discusiones futuras "¿por qué hicimos esto así?".
- **Visibilidad de huecos**: el archivo 10 hace explícitas las preguntas pendientes → no quedan tapadas en commits o threads de Slack.

---

## Licencia

Apache-2.0
