# TODO DevJobs — versión fácil de leer

Este archivo explica **qué vamos a construir, en qué orden y cómo saber si ya está listo**.
No entra en detalles técnicos: la IA decide cómo hacerlo.

**Cómo leerlo:**

- `[ ]` = pendiente
- `[x]` = terminado
- Cada entregable tiene: para qué sirve, qué se crea, dónde se ve y cuándo está listo.

---

## Estado rápido

| # | Entregable | Dónde se ve | Estado |
|---|---|---|---|
| 0 | Dejar lista la base | — | `[x]` |
| 1 | Tarjeta “Por gestionar” + card “Con entrevista” | Inicio | `[x]` |
| 2 | Barra “Con respuesta” | Inicio | `[x]` |
| 3 | “Actividad reciente” con últimos movimientos | Inicio | `[ ]` |
| 4 | Etapas del proceso tocables | Inicio | `[ ]` |
| 5 | “Ritmo mensual” | Inicio | `[ ]` |
| 6 | “Salario ofrecido” | Inicio | `[ ]` |
| 7 | Pestaña “Agenda” | Barra inferior | `[ ]` |
| 8 | Nota rápida | Detalle de postulación | `[ ]` |
| 9 | Ordenar empresas | Empresas | `[ ]` |
| 10 | Tema claro/oscuro | Barra superior | `[ ]` |
| 11 | Búsqueda mejorada | Buscador | `[ ]` |
| 12 | Abrir enlace de la oferta | Detalle de postulación | `[ ]` |
| 13 | Cierre y documentación | — | `[ ]` |

---

## Entregable 0 — Dejar lista la base

- [x] **Para qué sirve:** asegurar que lo que ya existe sigue funcionando antes de agregar cosas nuevas.
- **Qué se crea:** nada visible. No hay cambios en la app.
- **Cómo se ve:** la app actual sigue igual; crear y editar postulaciones funciona.
- **Listo cuando:** la app abre sin errores, se puede crear y editar una postulación, y las comprobaciones automáticas del proyecto pasan.
- **No incluye:** cambios visuales.

---

## Entregable 1 — Tarjeta “Por gestionar” y card “Con entrevista” en Inicio

- [x] **Para qué sirve:** ver lo que marcaste para gestionar y, aparte, cuántas vacantes ya tuvieron entrevista.
- **Qué se crea:**
  1. Una tarjeta **“Por gestionar”** debajo de los números.
  2. Una card **“Con entrevista”** en la grilla de números (reemplaza a “Por gestionar”).
- **Dónde se ve:** en **Inicio**.
- **Cómo se ve:**
  - La grilla queda: **Total**, **Activas**, **Con entrevista**, **Finalizadas**.
  - “Con entrevista” cuenta el switch de la columna N.
  - La tarjeta “Por gestionar” muestra el total, hasta 3 filas con empresa, cargo y “hace X días”, y **“Ver todas (N)”** si hay más de 3.
  - Si no hay pendientes, la tarjeta **no se muestra**.
- **Cómo se usa:** tocar una fila abre esa postulación; tocar “Ver todas” abre el listado de “Por gestionar”.
- **Listo cuando:**
  - El número coincide con las marcadas con el switch O.
  - Se muestran 3 filas y el total real.
  - La tarjeta se oculta si no hay pendientes.
  - “Con entrevista” cuenta todas las que tienen el switch N.
  - La tarjeta “Por gestionar” **no** filtra por entrevista.
- **No incluye:** motivos de comentarios dentro de la tarjeta ni notificaciones automáticas.

---

## Entregable 2 — Barra “Con respuesta”

- [x] **Para qué sirve:** ver qué porcentaje de postulaciones ya tuvo alguna respuesta de la empresa.
- **Qué se crea:** una barra nueva llamada **“Con respuesta”** dentro de “Tasa de conversión”, antes de “A entrevista” y “Finalizadas”.
- **Dónde se ve:** en **Inicio**, dentro de la tarjeta de conversión.
- **Cómo se ve:** una barra con su porcentaje, igual que las otras dos.
- **De dónde sale:** del estado (columna H). Cuenta como respuesta cualquier estado distinto de **Enviada**, **Sin respuesta** o **Retirada**. No usa la fecha de seguimiento.
- **Listo cuando:** el porcentaje coincide con los datos, la card de empresa usa la misma regla para “respondieron” y se ve bien en pantalla pequeña.
- **No incluye:** tarjetas nuevas ni columnas nuevas en la Sheet.

---

## Entregable 3 — “Actividad reciente” con últimos movimientos

- [ ] **Para qué sirve:** ver los últimos movimientos, no solo cuántos hubo.
- **Qué se crea:**
  1. Se reemplaza la tarjeta actual “Postulaciones recientes” por **“Actividad reciente”**.
  2. La nueva tarjeta muestra los conteos de 7 y 30 días **y** una lista corta de movimientos.
- **Dónde se ve:** en **Inicio**.
- **Cómo se ve:**
  - Arriba, los números de “Últimos 7 días” y “Últimos 30 días”.
  - Debajo, hasta 4 filas con empresa, estado y “hace X”.
- **Cómo se usa:** tocar una fila abre esa postulación.
- **Listo cuando:**
  - Los movimientos aparecen del más reciente al más antiguo.
  - Se muestran como máximo 4.
  - Si no hay datos, la tarjeta no se rompe.
- **No incluye:** historial completo de cambios.

---

## Entregable 4 — Etapas del proceso tocables

- [ ] **Para qué sirve:** pasar del resumen a ver las postulaciones de una etapa concreta.
- **Qué se crea:** no se crea una tarjeta nueva; se hace tocable la leyenda de “Pipeline de postulaciones”.
- **Dónde se ve:** en **Inicio**, dentro de la tarjeta “Pipeline de postulaciones”.
- **Cómo se ve:**
  - Cada etapa (Sin respuesta, En revisión, Entrevista, etc.) se puede tocar.
  - Un texto pequeño indica: **“Toca una etapa para ver las postulaciones”**.
- **Cómo se usa:** tocar “Entrevista” abre la lista de postulaciones de esa etapa.
- **Listo cuando:** cada etapa abre el grupo correcto.
- **No incluye:** cambiar los colores ni las etapas existentes.

---

## Entregable 5 — “Ritmo mensual”

- [ ] **Para qué sirve:** ver cuántas postulaciones hiciste en los últimos 6 meses.
- **Qué se crea:** una tarjeta nueva llamada **“Ritmo mensual”**.
- **Dónde se ve:** en **Inicio**, después de “Actividad reciente”.
- **Cómo se ve:**
  - 6 barras, una por mes.
  - Debajo de cada barra, el nombre corto del mes.
  - La barra más alta representa el mes con más postulaciones.
- **Listo cuando:**
  - Se ven los últimos 6 meses.
  - Los meses sin postulaciones aparecen en cero.
  - El cambio de diciembre a enero se muestra bien.
- **No incluye:** comparación con años anteriores.

---

## Entregable 6 — “Salario ofrecido”

- [ ] **Para qué sirve:** ver cuánto ofrecen, en promedio, las vacantes registradas.
- **Qué se crea:** una tarjeta nueva llamada **“Salario ofrecido”**.
- **Dónde se ve:** en **Inicio**, después de “Ritmo mensual”.
- **Cómo se ve:**
  - Tres números: **promedio**, **mínimo** y **máximo**.
  - Una nota: “Basado en N postulaciones”.
  - Solo aparece si hay al menos **3 salarios** registrados.
- **Listo cuando:** los cálculos coinciden y la tarjeta se oculta cuando hay pocos datos.
- **No incluye:** convertir monedas ni comparar salarios por país.

---

## Entregable 7 — Pestaña “Agenda”

- [ ] **Para qué sirve:** tener en un solo lugar lo que necesita atención hoy.
- **Qué se crea:**
  1. Un cuarto botón en la barra inferior llamado **“Agenda”**.
  2. Una pantalla nueva con tres secciones.
  3. Un número pequeño sobre el ícono de Agenda con la cantidad de pendientes.
- **Dónde se ve:** en la barra inferior, junto a Inicio, Postulaciones y Empresas.
- **Cómo se ve:**
  - Sección **“Por gestionar”**.
  - Sección **“Entrevistas agendadas”**.
  - Sección **“Sin novedad +7 días”**.
  - Cada sección muestra hasta 5 filas y un enlace “Ver todas”.
  - Si no hay nada pendiente: **“Todo al día”**.
- **Cómo se usa:** tocar una fila abre la postulación; “Ver todas” abre la lista completa de esa sección.
- **Listo cuando:**
  - Una postulación no aparece en dos secciones a la vez.
  - El número del ícono coincide con la cantidad de pendientes.
  - La barra inferior cabe en una pantalla pequeña.
- **No incluye:** notificaciones del teléfono.

---

## Entregable 8 — Nota rápida

- [ ] **Para qué sirve:** agregar una nota sin abrir el formulario completo de edición.
- **Qué se crea:**
  1. Un botón de nota en la barra superior del detalle.
  2. Una ventana pequeña para escribir la nota.
- **Dónde se ve:** en el **detalle de una postulación**.
- **Cómo se ve:** un ícono de nota; al tocarlo, una ventana con un cuadro de texto y el botón **“Guardar”**.
- **Cómo se usa:** escribir la nota, tocar “Guardar”, y la nota aparece en **Comentarios** con la fecha.
- **Listo cuando:**
  - La nota se guarda en la hoja.
  - La nota sigue ahí al cerrar y volver a abrir la postulación.
  - Sin internet, el botón se deshabilita.
- **No incluye:** editar o borrar notas individuales.

---

## Entregable 9 — Ordenar empresas

- [ ] **Para qué sirve:** ver las empresas en el orden que más te interese.
- **Qué se crea:** una fila de opciones de orden.
- **Dónde se ve:** en **Empresas**, debajo del buscador.
- **Cómo se ve:** las opciones **“Más postulaciones”**, **“Más activas”**, **“Más entrevistas”**, **“Mejor respuesta”** y **“Recientes”**.
- **Cómo se usa:** tocar una opción; la lista se reordena al instante.
- **Listo cuando:** cada opción ordena correctamente y la opción elegida se ve resaltada.
- **No incluye:** guardar el orden elegido para la próxima vez.

---

## Entregable 10 — Tema claro/oscuro

- [ ] **Para qué sirve:** elegir cómo se ve la app.
- **Qué se crea:** un menú de ajustes con tres opciones.
- **Dónde se ve:** un ícono de ajustes en la barra superior.
- **Cómo se ve:** las opciones **“Sistema”**, **“Claro”** y **“Oscuro”**.
- **Cómo se usa:** elegir una opción; la app cambia al instante y recuerda la elección al cerrarla.
- **Listo cuando:** el cambio se aplica de inmediato y se mantiene después de reiniciar.
- **No incluye:** colores personalizados.

---

## Entregable 11 — Búsqueda mejorada

- [ ] **Para qué sirve:** encontrar postulaciones por más datos y sin preocuparte por las tildes.
- **Qué se crea:** una mejora del buscador actual.
- **Dónde se ve:** en el ícono de lupa de la barra superior.
- **Cómo se ve:**
  - Un contador: **“N resultados”**.
  - Encuentra también por estado, comentarios, enlace y plataforma.
  - “Bogota” encuentra “Bogotá”.
  - Se pueden escribir varias palabras, por ejemplo “acme remoto”.
- **Listo cuando:** todos esos casos funcionan y el contador coincide.
- **No incluye:** búsqueda por fechas ni filtros avanzados.

---

## Entregable 12 — Abrir enlace de la oferta

- [ ] **Para qué sirve:** abrir la oferta original con un solo toque.
- **Qué se crea:**
  1. Un botón **“Abrir”** junto al enlace.
  2. Se mantiene el botón para copiar el enlace.
- **Dónde se ve:** en el **detalle de la postulación**, sección “Enlace externo”.
- **Cómo se ve:** el enlace, un botón “Abrir” y un botón “Copiar”.
- **Cómo se usa:** tocar “Abrir”; se abre el navegador.
- **Listo cuando:**
  - Abre el enlace en Android, Linux y Windows.
  - Si el enlace no es válido, muestra un aviso claro.
- **No incluye:** abrir enlaces dentro de la app.

---

## Entregable 13 — Cierre y documentación

- [ ] **Para qué sirve:** dejar el proyecto documentado y verificado.
- **Qué se crea:** actualización de la documentación del proyecto.
- **Listo cuando:**
  - La app compila.
  - Las comprobaciones automáticas pasan.
  - Se probó en pantalla pequeña y en tema claro/oscuro.
  - El README explica las funciones nuevas.

---

## Notas

- La tarjeta **“Por gestionar”** usa el switch de la columna O y se oculta si no hay pendientes.
- **“Con entrevista”** usa el switch de la columna N y cuenta todas las postulaciones.
- La tarjeta **“Por gestionar”** no filtra ni cuenta entrevistas: son datos separados.
- “Respondió” significa que el estado ya no es Enviada, Sin respuesta o Retirada. Aplica a la barra “Con respuesta” y a la card de empresa.

## Cómo marcar el avance

Cada entregable tiene un `[ ]`. Cuando esté terminado, se cambia a `[x]`.
La IA actualizará este archivo al cerrar cada entregable para que siempre sepas qué falta.
