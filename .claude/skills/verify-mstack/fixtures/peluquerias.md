# Fixture: Turnera, turnos para una red de peluquerías

Producto ficticio fijo para la corrida de punta a punta de la fundación. Usá
siempre este mismo producto y estas mismas respuestas: así una corrida se puede
comparar con la anterior y una diferencia en la salida viene de las skills, no
de lo que se improvisó.

Quien contesta las preguntas de la cadena (el usuario, o el agente si el
usuario se lo pide) responde con lo que dice acá. Si una skill pregunta algo
que este archivo no cubre, la respuesta es "no está definido todavía, anotalo
como pregunta abierta", y la pregunta nueva se agrega a este archivo después
de la corrida.

## Pedido inicial

Para arrancar `discovery-research`, pegá este texto tal cual:

> Quiero armar Turnera, un sistema de turnos para una red de 4 peluquerías de
> la misma dueña en Córdoba. Hoy los turnos se piden por WhatsApp y se anotan
> en una agenda de papel por local. Investiguemos el producto antes de diseñar.

A la pregunta de fuentes: "no tengo URLs de competidores; conozco de nombre
apps de turnos genéricas, pero no las usé".

## Discovery (los 11 puntos)

1. **Problema.** Los clientes piden turno por WhatsApp y esperan respuesta. Las recepcionistas pierden 2-3 horas por día contestando. Hay superposición de turnos entre agendas de papel y cerca de un 15% de ausencias sin aviso.
2. **Usuarios y roles.**
   - Cliente: reserva.
   - Peluquero: atiende y ve su agenda.
   - Recepcionista: gestiona la agenda de su local.
   - Dueña: administra locales, servicios y precios.
3. **Casos de uso.**
   - Como cliente, quiero reservar un turno eligiendo local, servicio y peluquero para no esperar respuesta por WhatsApp.
   - Como cliente, quiero cancelar o reprogramar mi turno para no tener que llamar.
   - Como recepcionista, quiero cargar un turno de alguien que llamó o vino al local, para que todo esté en la misma agenda.
   - Como peluquero, quiero ver mi agenda del día para organizarme.
   - Como dueña, quiero ver las ausencias por local y por mes para decidir si cobro seña.
4. **Competidores.** Apps de turnos genéricas, que no conozco en detalle. Lo que uso hoy es WhatsApp más agenda de papel. No hay URLs para scrapear.
5. **Funcionalidades necesarias (MVP).**
   - Reserva online por el cliente: local, servicio y peluquero o "cualquiera".
   - Agenda por peluquero y por local.
   - Carga manual de turnos por la recepcionista.
   - Cancelación y reprogramación.
   - Recordatorio 24 horas antes.
   - ABM de locales, servicios (con duración y precio) y peluqueros.
6. **Funcionalidades opcionales.**
   - Seña online con Mercado Pago.
   - Lista de espera para huecos que se liberan.
   - Historial del cliente (qué se hizo y con qué productos).
   - Reportes de facturación.
   - Programa de fidelidad.
7. **Reglas de negocio.**
   - Un turno dura lo que dura el servicio. Si son varios servicios, se suman.
   - Un peluquero no puede tener dos turnos superpuestos, y entre turnos hay 10 minutos de margen.
   - El cliente puede cancelar sin costo hasta 12 horas antes. Después cuenta como ausencia.
   - Un cliente con 3 ausencias en 90 días ya no puede reservar online; solo la recepcionista puede darle turno.
   - Cada peluquero trabaja en un solo local por día, pero puede rotar entre locales en la semana.
   - Los turnos se ofrecen en bloques de 15 minutos, dentro del horario del local.
8. **Integraciones.** Recordatorio por WhatsApp (o por email si no se puede). Mercado Pago solo si se hace la seña. Nada legacy.
9. **Restricciones.**
   - Presupuesto chico: una sola persona desarrolla y el hosting tiene que costar menos de USD 30 por mes.
   - Tiene que andar bien en el celular, porque los clientes reservan desde ahí.
   - Los datos personales se rigen por la Ley 25.326 de Argentina.
   - No hay stack obligatorio.
10. **Riesgos.**
    - Que los clientes mayores no adopten la reserva online y la recepcionista siga cargando todo.
    - El costo y la aprobación de la API de WhatsApp Business.
    - Que bloquear a quien falta 3 veces espante clientes.
11. **Preguntas abiertas.**
    - ¿Seña obligatoria para todos los servicios o solo para los largos (color, alisado)?
    - ¿El cliente elige peluquero o puede dejar "cualquiera" y el sistema asigna?
    - ¿Qué pasa con un turno si el peluquero falta ese día?
    - ¿Hace falta una app nativa o alcanza con una web móvil?

## kb-creator (preguntas estratégicas)

- **P0-sys, tipo de sistema.** Aplicación web transaccional (reservas), con un panel interno para el personal.
- **P0-scale, escala.** 4 locales, unos 20 peluqueros y entre 1.500 y 2.000 turnos por mes. Puede crecer a 10 locales en 2 años.
- **P1, problema.** El mismo del punto 1 de discovery.
- **P2, MVP.** La lista del punto 5. Sin seña ni reportes.
- **P3, actores.** Los cuatro roles del punto 2.
- **P4, restricciones.** Las del punto 9. Nada de cloud ni de stack obligatorio, más allá del costo.
- **P5, prioridad.** Primero el costo, después la velocidad de entrega. La escalabilidad no importa todavía.
- **Segunda ronda.**
  - Permisos: RBAC simple; la recepcionista solo ve su local y la dueña ve todo.
  - Auditoría: guardar quién canceló o movió cada turno.
  - Notificaciones: el recordatorio y la confirmación de reserva.
  - Borrado: un turno nunca se borra, se cancela.
  - Datos: los precios cambian y un turno conserva el precio del momento en que se reservó.

## Términos que el glosario debería tener

Sirve para leer `GLOSSARY.md` después de la corrida (ver el Gotcha de forma
contra calidad en `foundation-chain.md`). No hace falta que estén todos ni con
estas palabras exactas, pero si falta la mayoría, la KB no tomó el dominio.

Turno, Servicio, Local, Peluquero, Recepcionista, Cliente, Ausencia,
Cancelación, Reprogramación, Seña, Bloque (de 15 minutos), Agenda.
