# discovery-research

Convierte **"tengo una idea"** en **"sé qué voy a construir y por qué"**, con o
sin competidores a mano, antes de que exista una Knowledge Base.

> No completes un punto del checklist con una suposición cuando podés
> preguntarlo o investigarlo.

---

## ¿Qué hace?

Guía la etapa de Discovery que hoy falta antes de `kb-creator`, cubriendo un
checklist de 11 puntos (problema, usuarios, casos de uso, competidores,
funcionalidades necesarias y opcionales, reglas de negocio, integraciones,
restricciones, riesgos, preguntas abiertas):

1. **Fuentes** — si el usuario tiene URLs de competidores, invoca `web-scraper`
   por cada una y junta las notas.
2. **Checklist Q&A** — guía una ronda de preguntas por los 11 puntos, usando lo
   que salió del scraping para no repreguntar lo ya sabido.
3. **Gate final** — resume todo y espera confirmación explícita antes de
   escribir nada.
4. **Escribir** — genera `discovery/discovery.md`, junto a las notas de
   `discovery/sources/`. No usa ningún archivo de estado.
5. **Próximo paso** — te indica seguir con `kb-creator`, que lee
   `discovery/discovery.md` de disco.

---

## Instalación

Viene en mstack: se instala con el resto de las skills (ver el `README.md` de
la raíz). Es el primer paso, opcional, de la fundación, y se carga cuando le
decís al agente algo como "quiero investigar el mercado antes de definir qué
construir".

Para que el paso de scraping funcione, también necesitás instalada
`web-scraper`, que viene en mstack — sin ella, esta skill sigue funcionando solo
con la Q&A.

---

## Uso

Le decís al agente algo como:

```
"Hagamos discovery de este proyecto antes de armar la knowledge base"
"Todavía no sé bien qué necesito, ayudame a pensarlo"
```

El agente pregunta si tenés fuentes para investigar, corre la Q&A guiada de los
11 puntos, te muestra un resumen para confirmar, y recién ahí escribe
`discovery/discovery.md`, que es lo que va a leer `kb-creator`.

---

## Estructura

```
discovery-research/
├── SKILL.md
├── README.md
├── scripts/
│   └── collect_sources.py
├── references/
│   └── checklist.md
└── assets/
    └── example-discovery.md
```

---

## Por qué esta estructura

- **El checklist vive en `references/`, no en `SKILL.md`** — son 11 puntos con
  sub-preguntas cada uno; meterlo entero en `SKILL.md` lo haría ilegible.
- **`scripts/collect_sources.py` en vez de releer notas a mano** — cuando hay
  3+ competidores scrapeados, armar la tabla comparativa a mano es trabajo
  determinístico que se repite en cada corrida; el script lo hace una vez.
- **Sin archivo de estado** — el único contrato con `kb-creator` es
  `discovery/discovery.md`, con la estructura de `assets/example-discovery.md`.
  Cada paso de la fundación lee de disco lo que dejó el anterior.

---

## Licencia

Apache-2.0
