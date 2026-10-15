# devjobs

Standard Flutter scaffold (SDK `^3.12.1`, Material Design). Single entrypoint at `lib/main.dart`.

## Commands

| Action | Command |
|--------|---------|
| Run (debug) | `flutter run` |
| Run (release) | `flutter run --release` |
| Analyze | `flutter analyze` |
| Test | `flutter test` |
| Get deps | `flutter pub get` |
| Clean build | `flutter clean` |
| Build Android (APK) | `flutter build apk --release` |
| Build Windows | `flutter build windows --release` |

## Build / Deploy

- **Android APK** → `build/app/outputs/flutter-apk/app-release.apk`; instalar en dispositivo conectado con `flutter install --release`.
- **Windows** → `build/windows/x64/runner/Release/devjobs.exe`; para distribuir copiar **toda la carpeta `Release\`** (exe + DLLs + `data\`). La plataforma se habilitó con `flutter create --platforms=windows .` (carpeta `windows/` ya existe). Ventana 420×880 centrada (`windows/runner/main.cpp`); ícono generado desde `assets/icon/icon.png` vía `flutter_launcher_icons` (config `windows.generate`).
- **Instalador Windows (opcional)** → `installer/devjobs.iss` (Inno Setup 6): compilar con `ISCC.exe installer\devjobs.iss` → `installer/Output/DevJobsSetup.exe` (requiere `flutter build windows --release` previo).
- Web → `build/web/`. Todos los artefactos quedan bajo `build/` (gitignored).
- El `.env` (con `API_URL`) se embebe en el bundle: debe existir antes de compilar. Ver README → Despliegue.

## Config

- `analysis_options.yaml` — default `package:flutter_lints/flutter.yaml`, no overrides.
- `opencode.json` — MCP server `dart-mcp-server` enabled (LSP analysis via MCP tools).
- `skills-lock.json` — 22 skills registered (all from `dart-lang/skills`, `flutter/skills`, and autoskills registries). Load with `opencode skill load <name>`.

## Architecture

- **Data source:** Google Sheets via Apps Script Web App (REST API).
  - `apps_script_code.example.gs` — reference copy of the deployed script.
  - `.env.example` — template; copy to `.env` and set `API_URL`.
- **State management:** `Provider` (`ChangeNotifier`). Single `AppState` in `lib/providers/app_state.dart`.
  - Cache with 3-min TTL — invalidated on refresh or status change.
  - Dashboard stats computed locally from cached list.
  - Dashboard cards: Total postulaciones (no click), Activas (clickable → tab 1), Por gestionar (clickable → lista filtrada `PendingApplicationsScreen`), Finalizadas (clickable → tab 3). Clickable cards show `chevron_right` indicator.
  - "Por gestionar" flag (columna O del Sheet, checkbox): marca manual de vacantes con algo pendiente (la razón vive en `comentarios`). No se auto-limpia. Se alterna desde el AppBar del detalle o tocando el `GestionTag` en la card. Las marcadas se ordenan primero en cualquier listado (`_sortByDate`).
  - Tab filters: Activas = estado NOT IN (Enviada, Rechazada, Retirada, Aceptada); Enviadas = estado = Enviada; Finalizadas = Rechazada + Retirada + Aceptada.
  - `diasProceso` computed getter on model: difference in days between fechaPostulacion and fechaSeguimiento (null when no seguimiento).
  - Detail screen shows "Tiempo del proceso" below "F. seguimiento" (only when available).
- **Models:** `lib/models/job_application.dart` — `JobApplication` (16 fields: rowIndex, empresa, vacante, tipoContrato, modalidad, ciudad, salarioOfrecido, estado, link, descripcion, fechaPostulacion, fechaSeguimiento, contacto, comentarios, entrevistaRealizada, porGestionar) + `DashboardStats` (total, activas, entrevistas, finalizadas, porGestionar).
- **Service:** `lib/services/sheets_api_service.dart` — HTTP client using `package:http`.
- **Screens:** `MainScreen` with `BottomNavigationBar` (4 tabs: Inicio/Activas/Enviadas/Finalizadas). Detail via `Navigator.push`.
- **Widgets:** `lib/widgets/status_chip.dart` — colored status badge. `lib/widgets/application_card.dart` — reusable application card. `lib/widgets/gestion_tag.dart` — "Por gestionar" tag (color `gestionColor`, fucsia; distinto del ámbar de "estancado").
- **Helpers:** `lib/helpers/date_formatter.dart` — Spanish date formatting via `package:intl`. `lib/helpers/domain_parser.dart` — platform extraction; `lib/helpers/salary_formatter.dart` — salary extraction/formatting; `lib/helpers/text_shortener.dart` — truncation and contract abbreviation; `lib/helpers/network_error.dart` — network detection.

## Testing

- **Rule:** every new or modified reusable/utility logic (any `lib/helpers/*`, `lib/models/*` getter/parser, parser/serializer) **must** ship with unit tests in `test/` mirroring `lib/` (e.g. `lib/helpers/foo.dart` → `test/helpers/foo_test.dart`). Cover at least the happy path, one empty/null edge case, and one realistic variant (e.g. for `extractPlatform`: direct domain vs subdomain vs TLD compuesto).
- Tests use `flutter_test` only (no extra deps). Helpers/model are pure Dart; date tests must `await initializeDateFormatting('es')` in `setUpAll` because `intl` requires it for Spanish month names. See `docs/testing.md` for conventions and a minimal example.
- Before finishing any helper/model change, run `flutter test` and `flutter analyze`; both must be green before committing.
- How to run: `flutter test` (all) or `flutter test test/helpers/domain_parser_test.dart` (single file).

## Notes

- `.agents/` and `.kiro/` are gitignored (AI tool artifacts).
- No CI, no custom build scripts, no test fixtures.
