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
| 1 | Card “Con entrevista” en Inicio | Inicio | `[x]` |
| 2 | Barra “Con respuesta” | Inicio | `[x]` |
| 3 | “Actividad reciente” con últimos movimientos | Inicio | `[x]` |
| 4 | Etapas del proceso tocables | Inicio | `[x]` |
| 5 | “Ritmo mensual” | Inicio | `[x]` |
| 6 | “Salario ofrecido” | Inicio | `[x]` |
| 7 | Pestaña “Agenda” | Barra inferior | `[x]` |
| 8 | Nota rápida | Detalle de postulación | `[x]` |
| 9 | Ordenar empresas | Empresas | `[x]` |
| 10 | Tema claro/oscuro | Barra superior | `[x]` |
| 11 | Búsqueda mejorada | Buscador | `[x]` |
| 12 | Abrir enlace de la oferta | Detalle de postulación | `[x]` |
| 13 | Cierre y documentación | — | `[ ]` |

---

## Entregable 0 — Dejar lista la base

- [x] **Para qué sirve:** asegurar que lo que ya existe sigue funcionando antes de agregar cosas nuevas.
- **Qué se crea:** nada visible. No hay cambios en la app.
- **Cómo se ve:** la app actual sigue igual; crear y editar postulaciones funciona.
- **Listo cuando:** la app abre sin errores, se puede crear y editar una postulación, y las comprobaciones automáticas del proyecto pasan.
- **No incluye:** cambios visuales.

---

## Entregable 1 — Card “Con entrevista” en Inicio

- [x] **Para qué sirve:** ver cuántas vacantes ya tuvieron entrevista y mantener la grilla de cuatro números.
- **Qué se crea:** una card **“Con entrevista”** en la grilla de números. Reemplaza a “Por gestionar” en la grilla; esa lista vive ahora en **Agenda**.
- **Dónde se ve:** en **Inicio**.
- **Cómo se ve:**
  - La grilla queda: **Total**, **Activas**, **Con entrevista**, **Finalizadas**.
  - “Con entrevista” cuenta el switch de la columna N.
- **Listo cuando:** el número coincide con las que tienen el switch N y la grilla se ve bien en pantalla pequeña.
- **No incluye:** la tarjeta de lista “Por gestionar” en Inicio; esa se movió a Agenda.

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

- [x] **Para qué sirve:** ver los últimos movimientos, no solo cuántos hubo.
- **Qué se crea:**
  1. Se reemplaza la tarjeta actual “Postulaciones recientes” por **“Actividad reciente”**.
  2. La nueva tarjeta muestra los conteos de 7 y 30 días **y** una lista corta de movimientos.
- **Dónde se ve:** en **Inicio**.
- **Cómo se ve:**
  - Arriba, los números de “Últimos 7 días” y “Últimos 30 días”.
  - Debajo, hasta 3 filas con empresa, estado y “hace X”.
- **Cómo se usa:** tocar una fila abre esa postulación.
- **Listo cuando:**
  - Los movimientos aparecen del más reciente al más antiguo.
  - Se muestran como máximo 4.
  - Si no hay datos, la tarjeta no se rompe.
- **No incluye:** historial completo de cambios.

---

## Entregable 4 — Etapas del proceso tocables

- [x] **Para qué sirve:** pasar del resumen a ver las postulaciones de una etapa concreta.
- **Qué se crea:** no se crea una tarjeta nueva; se hace tocable la leyenda de “Pipeline de postulaciones”.
- **Dónde se ve:** en **Inicio**, dentro de la tarjeta “Pipeline de postulaciones”.
- **Cómo se ve:**
  - Cada etapa (Sin respuesta, En revisión, Entrevista, etc.) se puede tocar.
  - Un texto pequeño indica: **“Toca una etapa para ver las postulaciones”**.
- **Cómo se usa:** tocar “Entrevista” abre la lista de postulaciones de esa etapa.
- **Listo cuando:** cada etapa abre el grupo correcto, la lista respeta el orden general (Por gestionar primero) y el texto de ayuda se ve en Inicio.
- **No incluye:** cambiar los colores ni las etapas existentes.

---

## Entregable 5 — “Ritmo mensual”

- [x] **Para qué sirve:** ver cuántas postulaciones hiciste en los últimos 6 meses.
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

- [x] **Para qué sirve:** ver cuánto ofrecen, en promedio, las vacantes registradas.
- **Qué se crea:** una tarjeta nueva llamada **“Salario ofrecido”**.
- **Dónde se ve:** en **Inicio**, después de “Ritmo mensual”.
- **Cómo se ve:**
  - Tabla de **Moneda / Promedio / Rango** cuando hay COP y USD.
  - Si solo hay una moneda, una fila compacta sin encabezado.
  - Valores abreviados: `5M`, `5,9M`, `100K`, `1,3K`.
  - Sin textos de ayuda como “Basado en…” ni “Solo valores…”.
- **De dónde sale:** `parseSalary` interpreta valores únicos y rangos, detecta COP/USD y excluye “Yo puse…”, “puse…”, “propuse…” y “sugerí…”. Los rangos cuentan como una postulación; el promedio usa el punto medio.
- **Listo cuando:** COP y USD se muestran separados, los rangos se aprovechan, las abreviaturas se ven bien y la tarjeta se oculta si no hay datos.
- **No incluye:** convertir monedas ni aplicar un monto mínimo.

---

## Entregable 7 — Pestaña “Agenda”

- [x] **Para qué sirve:** tener en un solo lugar lo que necesita atención hoy.
- **Qué se crea:**
  1. Un cuarto botón en la barra inferior llamado **“Agenda”**.
  2. Una pantalla nueva con tres secciones.
  3. Un número pequeño sobre el ícono de Agenda con la cantidad de pendientes.
- **Dónde se ve:** en la barra inferior, junto a Inicio, Postulaciones y Empresas.
- **Cómo se ve:**
  - Sección **“Por gestionar”**.
  - Sección **“Entrevistas agendadas”**.
  - Sección **“Ofertas recibidas”**.
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

- [x] **Para qué sirve:** agregar una nota sin abrir el formulario completo de edición.
- **Qué se crea:**
  1. Un botón de nota en la barra superior del detalle.
  2. Una ventana pequeña para escribir la nota.
- **Dónde se ve:** en el **detalle de una postulación**.
- **Cómo se ve:** un ícono de nota; al tocarlo, una ventana con un cuadro de texto y el botón **“Guardar”**.
- **Cómo se usa:** escribir la nota, tocar “Guardar”, y la nota aparece en **Comentarios** con la fecha en formato `- d/M/yyyy: texto`.
- **Listo cuando:**
  - La nota se guarda en la hoja.
  - La nota sigue ahí al cerrar y volver a abrir la postulación.
  - Sin internet, el botón se deshabilita.
- **No incluye:** editar o borrar notas individuales.

---

## Entregable 9 — Ordenar empresas

- [x] **Para qué sirve:** ver las empresas en el orden que más te interese.
- **Qué se crea:** una fila de opciones de orden.
- **Dónde se ve:** en **Empresas**, debajo del buscador.
- **Cómo se ve:** las opciones **“Más postulaciones”**, **“Más activas”**, **“Más entrevistas”**, **“Mejor respuesta”** y **“Recientes”**.
- **Cómo se usa:** tocar una opción; la lista se reordena al instante.
- **Listo cuando:** cada opción ordena correctamente y la opción elegida se ve resaltada.
- **No incluye:** guardar el orden elegido para la próxima vez.

---

## Entregable 10 — Tema claro/oscuro

- [x] **Para qué sirve:** elegir cómo se ve la app.
- **Qué se crea:** un menú de ajustes con tres opciones.
- **Dónde se ve:** un ícono de ajustes en la barra superior.
- **Cómo se ve:** las opciones **“Sistema”**, **“Claro”** y **“Oscuro”**.
- **Cómo se usa:** elegir una opción; la app cambia al instante y recuerda la elección al cerrarla.
- **Listo cuando:** el cambio se aplica de inmediato y se mantiene después de reiniciar.
- **No incluye:** colores personalizados.

---

## Entregable 11 — Búsqueda mejorada

- [x] **Para qué sirve:** encontrar postulaciones por más datos y sin preocuparte por las tildes.
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

- [x] **Para qué sirve:** abrir la oferta original con un solo toque.
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

- La sección **“Por gestionar”** de Agenda usa el switch de la columna O.
- **“Con entrevista”** usa el switch de la columna N y cuenta todas las postulaciones.
- La sección **“Por gestionar”** no filtra ni cuenta entrevistas: son datos separados.
- “Respondió” significa que el estado ya no es Enviada, Sin respuesta o Retirada. Aplica a la barra “Con respuesta” y a la card de empresa.
- “Actividad reciente” usa la última fecha de seguimiento; si no existe, usa la fecha de postulación. Muestra hasta 3 movimientos.
- “Ritmo mensual” cuenta por fecha de postulación los últimos 6 meses, incluyendo los meses en cero.
- “Salario ofrecido” agrupa por moneda (COP/USD), interpreta rangos y excluye los valores que dicen “Yo puse…”. Las abreviaturas usan coma decimal (`5,9M`).
- Agenda usa **Por gestionar**, **Entrevistas agendadas** y **Ofertas recibidas**. Se descartó “Sin novedad +7 días” porque con volumen alto no es una agenda accionable.
- La tarjeta **“Por gestionar”** se retiró de Inicio: su única ubicación ahora es Agenda.

## Cómo marcar el avance

Cada entregable tiene un `[ ]`. Cuando esté terminado, se cambia a `[x]`.
La IA actualizará este archivo al cerrar cada entregable para que siempre sepas qué falta.
