---
name: leaving-pr-comments
description: Formatea los comentarios que un agente deja en GitHub en nombre del usuario. Usala siempre que vayas a comentar en GitHub.
---

<!-- Origen: tstack/skills/leaving-pr-comments (MIT, Theo Browne). Ver NOTICE.md.
     Cambios: traducida. -->

# leaving-pr-comments

Arrancá todo comentario que un agente deje en nombre del usuario con este
callout de nota de GitHub:

```md
> [!NOTE]
> 🤖 **<modelo> respondiendo en nombre de <usuario>**

Acá empieza el comentario.
```

Usá el nombre público verificado del modelo que escribió el comentario, y el
nombre o el login de GitHub del usuario.

Si el harness no informa el nombre del modelo, usá el nombre del harness. No
adivines.

Antes de postear, revisá el comentario entero, incluidas citas y adjuntos, en
busca de secretos y datos privados.

La atribución va dentro de la nota y la respuesta va afuera. La línea de
contexto tiene que empezar con el emoji del robot. No agregues una línea
horizontal, subrayado Setext, encabezado, firma al pie ni una segunda
atribución.

Aplicá este formato a comentarios de primer nivel en el PR, comentarios
inline de review, respuestas a bots o revisores, y explicaciones escritas antes
de resolver o descartar feedback. No lo agregues a descripciones de PR,
mensajes de commit ni a texto que el usuario pidió postear tal cual sin
atribución.

Escribí el comentario en estilo directo:

- Arrancá por la conclusión.
- Citá el código, comportamiento, check o reproducción que corresponda.
- Sé conciso: sin relleno, agradecimientos de manual ni narración de estado.
- Distinguí los hechos verificados del criterio propio.

Previsualizá el Markdown final antes de postear, así las citas y las líneas en
blanco se ven como esperás. Después de postear, verificá que GitHub devolvió la
URL del comentario o de la review. Resolvé un hilo de review solo después de
que tu respuesta se posteó bien.
