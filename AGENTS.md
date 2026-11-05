# devjobs

Standard Flutter scaffold (SDK `^3.12.1`, Material Design). Single entrypoint at `lib/main.dart`.

## Commands

| Action | Command |
|--------|---------|
| Run (debug) | `flutter run` |
| Run (release) | `flutter run --release --no-tree-shake-icons` |
| Analyze | `flutter analyze` |
| Test | `flutter test` |
| Get deps | `flutter pub get` |
| Clean build | `flutter clean` |
| Build Android (APK) | `flutter build apk --release --no-tree-shake-icons` |
| Build Windows | `flutter build windows --release --no-tree-shake-icons` |
| Build Linux | `flutter build linux --release --no-tree-shake-icons` |
| Install Linux (local) | `./scripts/install-linux.sh` |

> **`--no-tree-shake-icons` es obligatorio en release.** El tree-shaker de íconos
> de Flutter tiene un bug que descarta glyphs usados (p.ej. `Icons.business_outlined`,
> `Icons.apartment`) y quedan **en blanco** en release. Sin el flag la fuente se
> recorta a ~6 KB; con el flag se embebe completa (~1.6 MB) y ningún ícono falla.

## Build / Deploy

- **Android APK** → `build/app/outputs/flutter-apk/app-release.apk`; instalar en dispositivo conectado con `flutter install --release`.
- **Windows** → `build/windows/x64/runner/Release/devjobs.exe`; para distribuir copiar **toda la carpeta `Release\`** (exe + DLLs + `data\`). La plataforma se habilitó con `flutter create --platforms=windows .` (carpeta `windows/` ya existe). Ventana 420×880 centrada (`windows/runner/main.cpp`); ícono generado desde `assets/icon/icon.png` vía `flutter_launcher_icons` (config `windows.generate`).
- **Instalador Windows (opcional)** → `installer/devjobs.iss` (Inno Setup 6): compilar con `ISCC.exe installer\devjobs.iss` → `installer/Output/DevJobsSetup.exe` (requiere `flutter build windows --release` previo).
- **Linux** → `build/linux/x64/release/bundle/` (binario + `data/` + `lib/`); para distribuir copiar **toda la carpeta `bundle/`**. Requiere toolchain `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`. Ventana 420×880 centrada y mínima 360×600 (`linux/runner/my_application.cc`); ícono de ventana desde `linux/devjobs.png` (256×256, copiado al bundle por `linux/CMakeLists.txt`). `APPLICATION_ID=com.example.devjobs`.
- **Instalación Linux (sin sudo)** → `scripts/install-linux.sh` copia el bundle a `~/.local/opt/devjobs`, symlink en `~/.local/bin/devjobs`, `.desktop` en `~/.local/share/applications` e ícono en `~/.local/share/icons/hicolor/256x256/apps`; `--uninstall` revierte. Plantilla del entry: `linux/devjobs.desktop`.
- Web → `build/web/`. Todos los artefactos quedan bajo `build/` (gitignored).
- El `.env` (con `API_URL`) se embebe en el bundle: debe existir antes de compilar. Ver README → Despliegue.

## Config

- `analysis_options.yaml` — default `package:flutter_lints/flutter.yaml`, no overrides.
- `opencode.json` — **local, gitignored** (no se versiona: contiene rutas absolutas por SO). Habilita el MCP server `dart-mcp-server` (análisis/LSP, hot reload, pub). En Linux/Ubuntu usa ruta absoluta al SDK (`/home/felipe/Documentos/flutter/bin/dart`) porque `dart` no está en `PATH`; en Windows basta `dart`. Plantillas listas para copiar/pegar en README → «MCP de Dart en OpenCode».
- `skills-lock.json` — **versionado**; declara las **8 skills** del proyecto (los archivos viven en `.agents/`, que está gitignoreado). Set: `find-skills`, `grill-me`, `dart-add-unit-test`, `dart-run-static-analysis`, `flutter-add-widget-test`, `flutter-use-http-package`, `flutter-fix-layout-issues`, `flutter-build-responsive-layout`. Restaurar tras clonar: `npx skills experimental_install`. Ver README → «Skills».

## Architecture

- **Data source:** Google Sheets via Apps Script Web App (REST API).
  - `apps_script_code.example.gs` — reference copy of the deployed script.
  - `.env.example` — template; copy to `.env` and set `API_URL`.
  - **Fechas:** la app envía `yyyy-MM-dd` (`formatApiDate`) y lee `d/M/yyyy`. El script convierte a `Date` real con la zona de la hoja (`getSpreadsheetTimeZone()`) y nunca escribe strings de fecha con `setValue`. `GET ?action=meta` (solo lectura) reporta zona, locale, formato de A/K, primera fila de datos y rango del filtro; si `timeZone` y `scriptTimeZone` difieren, igualar la zona del proyecto de Apps Script a la de la hoja. Tras cambiar el script, redesplegar con **Manage deployments → Edit → New version** para conservar la URL.
  - **Creación:** `createRow` rellena el hueco inmediato sobre la primera postulación si la fila está realmente vacía (sin valores, fórmulas ni notas) y devuelve `shifted: false`; si no hay hueco, inserta una fila y devuelve `shifted: true`. Las nuevas quedan encima de las anteriores.
- **State management:** `Provider` (`ChangeNotifier`). Single `AppState` in `lib/providers/app_state.dart`.
  - Cache with 3-min TTL — invalidated on refresh or status change.
  - `createApplication(JobApplication)` hace POST `create`. Con `shifted == false` (se rellenó un hueco sin mover filas) inserta en la caché local y no refresca; con `shifted == true` invalida el TTL y fuerza `fetchApplications(forceRefresh: true)` antes de volver. `updateApplication` también parchea `fechaPostulacion`/`fechaSeguimiento`.
  - Dashboard stats computed locally from cached list.
  - Dashboard cards: Total postulaciones (no click), Activas (clickable → `openApplications(filterActivas)`), Con entrevista (no click; cuenta `entrevistaRealizada`, el switch de la columna N), Finalizadas (clickable → `openApplications(filterFinalizadas)`). Clickable cards show `chevron_right` indicator.
  - "Por gestionar" (`lib/widgets/pending_applications_card.dart`) va debajo de la grilla: lista las marcadas con el switch O (`getApplications(filterPorGestionar)`), muestra hasta 3 filas compactas y "Ver todas" abre `PendingApplicationsScreen`. Si no hay pendientes **no se renderiza**. No filtra por entrevista.
  - Tasa de conversión: tres barras. "Con respuesta" = estados distintos de Enviada, Sin respuesta y Retirada (`hasResponse`, columna H); "A entrevista" = switch N (`entrevistaRealizada`); "Finalizadas" = estados terminales.
  - Actividad reciente (`lib/widgets/recent_activity_card.dart`): conteos de últimos 7/30 días por `fechaPostulacion` y hasta 3 movimientos ordenados por `fechaSeguimiento` (fallback `fechaPostulacion`); cada fila abre el detalle.
  - Pipeline (`lib/widgets/pipeline_card.dart`): barra + leyenda; cada etapa es tocable y abre `FilteredApplicationsScreen(selector: applicationsInStage)`. La lógica de etapas vive en `lib/helpers/pipeline.dart` y usa el mismo orden general (`application_sort.dart`).
  - Ritmo mensual (`lib/widgets/monthly_trend_card.dart`): últimos 6 meses por `fechaPostulacion`, con meses en cero; la lógica vive en `lib/helpers/trends.dart`.
  - Salario ofrecido (`lib/widgets/salary_insights_card.dart`): tabla por moneda (COP/USD) con promedio y rango. `parseSalary` interpreta valores únicos y rangos, detecta USD/COP y excluye "yo puse/puse/propuse/sugerí"; `formatCompactSalary` abrevia (5,9M/100K/1,3K); `salaryInsights` agrupa por moneda. Si solo hay una moneda, la tarjeta usa una fila compacta sin encabezado.
  - Distribución (dashboard): `DistributionCard` (`lib/widgets/distribution_card.dart`) con selector segmentado de ancho completo (Plataformas / Modalidades / Ciudades, por defecto Plataformas) y debajo solo el grupo activo. "Ver todas" abre `DistributionDetailScreen`; cada fila abre `FilteredApplicationsScreen`. Empresas no es un segmento: tiene su propia pestaña.
  - "Por gestionar" flag (columna O del Sheet, checkbox): marca manual de vacantes con algo pendiente (la razón vive en `comentarios`). No se auto-limpia. Se alterna desde el AppBar del detalle o tocando el `GestionTag` en la card. Las marcadas se ordenan primero en cualquier listado (`sortApplications`).
  - Postulaciones filters (pills dentro de la pestaña, con contador): `filterAll` (Todas, por defecto), `filterActivas` = estado NOT IN (Enviada, Rechazada, Retirada, Aceptada); `filterEnviadas` = estado = Enviada; `filterFinalizadas` = Rechazada + Retirada + Aceptada; `filterPorGestionar` = flag manual (lo usan la card "Por gestionar" del dashboard y `PendingApplicationsScreen`). Definición única en `_matchesFilter`, compartida por `getApplications`, `countApplications` y `dashboardStats`. Empresas = agrupación case-insensitive/trim de la columna `empresa` (`companiesStats`), ordenada por nº de postulaciones desc.
  - `diasProceso` computed getter on model: difference in days between fechaPostulacion and fechaSeguimiento (null when no seguimiento).
  - Detail screen shows "Tiempo del proceso" below "F. seguimiento" (only when available).
- **Models:** `lib/models/job_application.dart` — `JobApplication` (16 fields: rowIndex, empresa, vacante, tipoContrato, modalidad, ciudad, salarioOfrecido, estado, link, descripcion, fechaPostulacion, fechaSeguimiento, contacto, comentarios, entrevistaRealizada, porGestionar) + `DashboardStats` (total, activas, entrevistas, conRespuesta, finalizadas, porGestionar). `lib/models/application_options.dart` — opciones de los selectores (contrato, modalidad, estado) compartidas por crear/editar.
- **Service:** `lib/services/sheets_api_service.dart` — HTTP client using `package:http`.
- **Screens:** `MainScreen` with `NavigationBar` (3 tabs: Inicio/Postulaciones/Empresas). `PostulacionesScreen` = pills Todas/Activas/Enviadas/Finalizadas + `ApplicationsListScreen` (se remonta por `ValueKey(filter)` al cambiar de pill). Crear y editar comparten `ApplicationFormScreen` (`lib/screens/application_form_screen.dart`, constructores `.create()` y `.edit(app)`): secciones Vacante/Proceso/Notas, fechas con `showDatePicker` (solo calendario, locale es) y barra de guardado fija. El FAB "Nueva" aparece solo en Postulaciones (oculto offline); al crear vuelve a Todas con SnackBar. La edición se abre desde el AppBar del detalle. `EmpresasScreen` lista todas las empresas con filtro propio por nombre, contador de resultados y empty state con "Limpiar búsqueda"; `CompanyDetailScreen` (métricas en grilla adaptable + distribución + listado de vacantes). Detail via `Navigator.push`.
- **Widgets:** `lib/widgets/status_chip.dart` — colored status badge. `lib/widgets/application_card.dart` — reusable application card. `lib/widgets/company_card.dart` — card de empresa (chips condicionales de por gestionar, entrevistas, activas y respondieron; última actividad en el subtítulo). `lib/widgets/form_section.dart` — encabezado + contenido de una sección de formulario. `lib/widgets/gestion_tag.dart` — "Por gestionar" tag (color `gestionColor`, fucsia; distinto del ámbar de "estancado"). `lib/widgets/meta_chip.dart` — icon+label chip. `lib/widgets/pending_applications_card.dart` — tarjeta "Por gestionar" de Inicio; `lib/widgets/recent_activity_card.dart` — tarjeta "Actividad reciente" (conteos 7/30 + últimos movimientos); `lib/widgets/pipeline_card.dart` — pipeline con etapas tocables; `lib/widgets/monthly_trend_card.dart` — tarjeta "Ritmo mensual"; `lib/widgets/salary_insights_card.dart` — tarjeta "Salario ofrecido"; `lib/widgets/application_compact_row.dart` — fila empresa/vacante + trailing reutilizada por listas compactas.
- **Helpers:** `lib/helpers/date_formatter.dart` — fechas en español (`formatDate`, `formatDateValue`) + contrato de escritura `formatApiDate` (`yyyy-MM-dd`) + parseo D/M e ISO con validación de rangos. `lib/helpers/domain_parser.dart` — platform extraction; `lib/helpers/salary_formatter.dart` — salary extraction/formatting + `formatCompactSalary` (abreviaturas); `lib/helpers/text_shortener.dart` — truncation and contract abbreviation; `lib/helpers/network_error.dart` — network detection; `lib/helpers/company_stats.dart` — agregados por empresa (agrupación case-insensitive/trim; incluye entrevistas y porGestionar; `conNovedad` cuenta estados con respuesta); `lib/helpers/text_normalizer.dart` — minúsculas/sin acentos; `lib/helpers/status.dart` — normalización de estados, estado terminal y `hasResponse` (respondió por estado); `lib/helpers/activity.dart` — `countApplicationsSince` y `recentMovements` (últimos movimientos); `lib/helpers/application_sort.dart` — orden único (`compareApplications`/`sortApplications`); `lib/helpers/pipeline.dart` — etapas, conteos y postulaciones por etapa; `lib/helpers/trends.dart` — conteo mensual (`monthlyApplicationCounts`); `lib/helpers/salary_parser.dart` — `ParsedSalary`/`parseSalary` (moneda, rangos y exclusión de valores subjetivos); `lib/helpers/salary_insights.dart` — `SalaryGroup`/`salaryInsights` (resumen por moneda).

## Testing

- **Rule:** every new or modified reusable/utility logic (any `lib/helpers/*`, `lib/models/*` getter/parser, parser/serializer) **must** ship with unit tests in `test/` mirroring `lib/` (e.g. `lib/helpers/foo.dart` → `test/helpers/foo_test.dart`). Cover at least the happy path, one empty/null edge case, and one realistic variant (e.g. for `extractPlatform`: direct domain vs subdomain vs TLD compuesto).
- Tests use `flutter_test` only (no extra deps). Helpers/model are pure Dart; date tests must `await initializeDateFormatting('es')` in `setUpAll` because `intl` requires it for Spanish month names. See `docs/testing.md` for conventions and a minimal example.
- Before finishing any helper/model change, run `flutter test` and `flutter analyze`; both must be green before committing.
- How to run: `flutter test` (all) or `flutter test test/helpers/domain_parser_test.dart` (single file).
- Widget tests del formulario: `test/widgets/application_form_test.dart` cubre crear/editar, validación, envío de fechas ISO y modo offline. El `MaterialApp` de prueba usa `GlobalMaterialLocalizations.delegates` y `initializeDateFormatting('es')`.

## Notes

- `.agents/` and `.kiro/` are gitignored (AI tool artifacts).
- No CI, no custom build scripts, no test fixtures.
- **Íconos en release:** Flutter tree-shakea `MaterialIcons` y algunos glyphs usados se descartan por un bug del tree-shaker (p.ej. `Icons.business_outlined` queda invisible). Por eso los builds release usan `--no-tree-shake-icons` (ver tabla de comandos).
- **Fechas:** nunca enviar `DateTime.toIso8601String()` ni timestamps (pueden correr un día en GMT-5); usar `formatApiDate`. El picker debe estar en locale es (`flutter_localizations`): en inglés la entrada de texto interpreta MM/DD/YYYY y produce el clásico intercambio día/mes.
- **RowIndex:** es posicional. Insertar o borrar filas en el Sheet invalida los índices cacheados; la app refresca al crear con `shifted == true` y con el TTL, pero tras editar el Sheet conviene hacer pull-to-refresh antes de editar en la app.
- **Widgets en `Stack` con `StackFit.expand`:** un error de build (p.ej. excepción en `build`) se pinta en release como un `ErrorWidget` **gris que cubre todo el `Stack`** y bloquea el toque. En `ScrollToTopButton` esto pasaba por leer `viewportDimension`/`pixels` antes de que el `ScrollPosition` tuviera dimensiones.
