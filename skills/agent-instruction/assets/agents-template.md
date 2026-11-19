# Plantilla del bloque de agent-instruction

Contenido que la skill escribe en `AGENTS.md`, **entre los marcadores**. Lo que queda fuera de los marcadores (por ejemplo `## Agent skills`) no es parte de la plantilla y no se toca. Adaptá nombres y contenido al proyecto, pero respetá las secciones y su orden. Borrá los comentarios `<!-- ... -->` de guía al generar; los marcadores se quedan.

---

~~~~markdown
<!-- active-stack:agent-instruction -->
# {NombreProyecto} — Instrucciones para Agentes

> Generado por `agent-instruction` a partir de `knowledge-base/` y del roadmap #{N}.
> Este bloque se regenera: editá la KB o el roadmap y volvé a correr la skill. Lo que esté fuera del bloque no se toca.

## Stack Tecnológico

<!-- Copiar la tabla de knowledge-base/02_descripcion_general.md §Stack tecnológico -->

| Capa | Tecnología | Versión |
|------|------------|---------|
| Frontend | {React + TypeScript / Vite / Tailwind} | {x.x} |
| Backend | {FastAPI / SQLModel / PostgreSQL} | {x.x} |
| Integraciones | {MercadoPago, ...} | — |

Detalle completo: [knowledge-base/02_descripcion_general.md](knowledge-base/02_descripcion_general.md)

## Base de Conocimiento

La fuente de verdad del dominio vive en `knowledge-base/`, `GLOSSARY.md` y `docs/adr/`. **Leé el archivo relevante ANTES de implementar.**

| Archivo | Cuándo leerlo |
|---------|---------------|
| [GLOSSARY.md](GLOSSARY.md) | Nombrar cosas con los términos del dominio |
| [docs/adr/](docs/adr/) | Decisiones ya tomadas; no las reabras sin un ADR nuevo |
| [01_vision_y_objetivos.md](knowledge-base/01_vision_y_objetivos.md) | Propósito y alcance |
| [03_actores_y_roles.md](knowledge-base/03_actores_y_roles.md) | Auth, roles, permisos |
| [04_modelo_de_datos.md](knowledge-base/04_modelo_de_datos.md) | Entidades, relaciones, migraciones |
| [05_reglas_de_negocio.md](knowledge-base/05_reglas_de_negocio.md) | Reglas codificadas (RN-XX) |
| [06_funcionalidades.md](knowledge-base/06_funcionalidades.md) | Historias por épica |
| [07_flujos_principales.md](knowledge-base/07_flujos_principales.md) | Flujos de punta a punta |
| [08_arquitectura_propuesta.md](knowledge-base/08_arquitectura_propuesta.md) | Patrones, estructura, env vars |
| [10_preguntas_abiertas.md](knowledge-base/10_preguntas_abiertas.md) | Inconsistencias a resolver ANTES de codear |

<!-- Incluir solo si 10_preguntas_abiertas.md tiene preguntas de prioridad Alta. -->
> ⚠️ Resolver las preguntas de prioridad **Alta** de `10_preguntas_abiertas.md` antes de arrancar R-01.

## Skills Disponibles

<!-- Solo skills encontradas en el escaneo de skills instaladas. -->

| Agente | Rol | Skills que carga |
|--------|-----|------------------|
| **Backend** | API, modelos, migraciones | `{skill}`, `{skill}` |
| **Frontend** | UI y estado | `{skill}`, `{skill}` |
| **Fundación** | Contexto e instrucciones | `kb-creator`, `roadmap-generator`, `agent-instruction` |

Cargá la skill que corresponde al contexto ANTES de escribir código.

## Roadmap

<!-- Omitir la sección entera si no hay issue de roadmap, y sacar también las menciones a "roadmap #{N}" del encabezado y del Flujo de Trabajo. Resumen, NO el detalle. -->

El plan de specs es el issue [#{N} Roadmap: {NombreProyecto}]({url}). Resumen:

- **Total**: {I} ítems en {F} fases.
- **Camino crítico**: `{R-01 → R-02 → ... → R-NN}`.
- **Primer ítem**: `R-01` ({nombre}).

Cada ítem es una spec futura. Cuando su spec exista como issue `#M`, la línea del roadmap pasa a `- [ ] R-NN #M`.

## Reglas Duras

> Las reglas globales (governance, TDD, memoria, workflow) ya están en las instrucciones globales del cliente: el proyecto las hereda. Acá viven solo las reglas **específicas de este proyecto** y las universales que el global no cubra.

<!-- Reemplazar con las reglas confirmadas en el Paso 3. Ejemplos por stack — NO copiar a ciegas:
     Go:       NUNCA mergear sin `gofmt`/`go vet` limpios → correrlos antes de cada commit.
     Python:   NUNCA schema Pydantic sin `extra='forbid'` → rechazar campos no declarados.
     React/TS: NUNCA usar `any` → tipar estricto; componentes en PascalCase. -->

- {Reglas confirmadas. Si el usuario no agregó ninguna, dejá solo la línea de referencia de arriba.}

## Flujo de Trabajo

Todo el trabajo vive en GitHub Issues:

```
1. Elegir un ítem del roadmap #{N} con sus deps cerradas  → priorizar el camino crítico
2. Leer los punteros de "leer" del ítem
3. /mattpocock-skills:grill-with-docs → /mattpocock-skills:to-spec   → issue de spec #M
4. Editar la línea del ítem en el roadmap: - [ ] R-NN #M
5. /mattpocock-skills:to-tickets                                      → issues hijos con bloqueos
6. Por cada ticket desbloqueado: su rama, /mattpocock-skills:implement #T, su PR con "Closes #T"
```

Aplicar TODAS las reglas duras en cada paso. Ante conflicto entre la KB y este archivo, las reglas duras prevalecen.
<!-- /active-stack:agent-instruction -->
~~~~

---

## Checklist antes de escribir

- [ ] El bloque arranca y termina con los marcadores, cada uno en su propia línea.
- [ ] No quedan `{placeholders}` ni comentarios de guía.
- [ ] Cada enlace local apunta a un archivo que existe; los que no existen se sacaron.
- [ ] La sección Roadmap nombra el issue por número y URL, o no está (si no hay roadmap).
- [ ] La tabla de skills solo tiene skills instaladas.
- [ ] Las reglas duras son las confirmadas por el usuario.
