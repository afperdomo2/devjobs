// Genera las capturas de la app para el README.
//
// Normalmente se usa el script (que además convierte los PNG a WebP):
//
//   ./scripts/capture-screenshots.sh
//
// La app se ejecuta en una ventana real de escritorio, se navega con toques
// y los PNG se toman del árbol de render en tamaño de teléfono
// (420×880 lógicos @2x) y tema claro, sin importar la ventana ni el tema
// del sistema.
//
// A diferencia de un test de integración normal, aquí NO se habla con la
// Google Sheet real: los datos se siembran con un [_FakeApi] determinista para
// que las capturas sean reproducibles y no dependan del contenido del Sheet.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:devjobs/main.dart';
import 'package:devjobs/models/ai_config.dart';
import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/application_detail_screen.dart';
import 'package:devjobs/screens/company_detail_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/widgets/application_card.dart';
import 'package:devjobs/widgets/company_card.dart';
import 'package:devjobs/widgets/company_insight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

/// Dónde guardar los PNG (lo define scripts/capture-screenshots.sh).
const _outDir = String.fromEnvironment(
  'SCREENSHOT_DIR',
  defaultValue: 'screenshots',
);

/// Resolución de exportación: el doble del tamaño lógico.
const _pixelRatio = 2.0;

/// Tamaño lógico de la ventana de la app (mobile-first). Por debajo de 600 de
/// ancho se muestra la barra de navegación inferior.
const _phoneSize = Size(420, 880);

final _captureKey = GlobalKey();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capturas para el README', (tester) async {
    // Tamaño de teléfono; el tema se fuerza claro vía ThemeMode (no system).
    tester.view.physicalSize = _phoneSize * _pixelRatio;
    tester.view.devicePixelRatio = _pixelRatio;
    addTearDown(tester.view.reset);

    await dotenv.load(fileName: '.env');
    await initializeDateFormatting('es', null);
    Directory(_outDir).createSync(recursive: true);

    final state = AppState(
      apiService: _FakeApi(_fixtureApplications(), _fixtureInsights()),
      initialThemeMode: ThemeMode.light,
    );
    // Precarga para que las pantallas muestren datos desde el primer frame y
    // habilite la tarjeta de Análisis IA en el detalle de empresa.
    await state.fetchApplications(forceRefresh: true);
    await state.loadCompanyInsights();
    await state.updateAiConfig(_demoAiConfig);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: RepaintBoundary(key: _captureKey, child: const DevJobsApp()),
      ),
    );
    await _waitFor(tester, find.text('Total postulaciones'));

    // 1) Inicio: dashboard (métricas, conversión, actividad, pipeline…).
    await _capture(tester, 'home');

    // 2) Plataformas: desde el botón de Inicio.
    await tester.tap(find.text('Revisar plataformas').hitTestable());
    await _waitFor(tester, find.text('Plataformas'));
    await _capture(tester, 'plataformas');
    await _back(tester);

    // 3) Postulaciones: lista con pills de filtro.
    await _tapTab(tester, 'Postulaciones');
    await _waitFor(tester, find.byType(ApplicationCard).hitTestable());
    await _capture(tester, 'postulaciones');

    // 4) Detalle de una postulación (la de referencia: Flutter Senior).
    await tester.tap(
      find.widgetWithText(ApplicationCard, 'Flutter Senior').hitTestable(),
    );
    await _waitFor(tester, find.byType(ApplicationDetailScreen));
    await _capture(tester, 'detalle');
    await _back(tester);

    // 5) Empresas: listado con análisis IA por empresa.
    await _tapTab(tester, 'Empresas');
    await _waitFor(tester, find.byType(CompanyCard).hitTestable());
    await _capture(tester, 'empresas');

    // 6) Detalle de empresa (con la tarjeta Análisis IA a la vista).
    await tester.tap(
      find.widgetWithText(CompanyCard, 'Acme Tech').hitTestable(),
    );
    await _waitFor(tester, find.byType(CompanyDetailScreen));
    // La lista es perezosa: hay que hacer scroll hasta la tarjeta de análisis.
    await tester.scrollUntilVisible(
      find.byType(CompanyInsightCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _capture(tester, 'empresa-detalle');
    await _back(tester);

    // 7) Agenda: secciones por gestionar / entrevistas / ofertas.
    await _tapTab(tester, 'Agenda');
    await _waitFor(tester, find.text('Por gestionar'));
    await _capture(tester, 'agenda');
  });
}

/// Cambia a la pestaña [label] tocando su destino de la `NavigationBar`.
///
/// Se busca el texto dentro de los `NavigationDestination` para que no choque
/// con el título del AppBar (que puede llamarse igual, p. ej. "Postulaciones").
Future<void> _tapTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(NavigationDestination),
    matching: find.text(label),
  );
  await tester.tap(tab.hitTestable());
  await tester.pumpAndSettle();
}

/// Vuelve atrás tocando el botón de retroceso del AppBar.
Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).hitTestable().first);
  await tester.pumpAndSettle();
}

/// Espera (en tiempo real) a que [finder] encuentre algo en pantalla.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final limit = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(limit)) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 200));
  }
  fail('No apareció $finder después de $timeout');
}

/// Captura el árbol de render en `$_outDir/<nombre>.png`.
Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();

  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
  final ui.Image image = await boundary.toImage(pixelRatio: _pixelRatio);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final file = File('$_outDir/$name.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('Captura guardada: ${file.path} (${image.width}×${image.height})');
  image.dispose();
}

/// Servicio falso: evita la red y devuelve datos de ejemplo fijos.
class _FakeApi extends SheetsApiService {
  final List<JobApplication> apps;
  final List<CompanyInsight> insights;

  _FakeApi(this.apps, this.insights) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => apps;

  @override
  Future<List<CompanyInsight>> fetchCompanyInsights() async => insights;
}

/// Configuración de IA "habilitada" para que se muestre la tarjeta de análisis.
final _demoAiConfig = AiConfig(
  baseUrl: 'https://api.example.com/v1',
  apiKey: 'demo-key',
  models: const ['demo-model'],
);

/// Fecha `d/M/yyyy` de hace [days] días (formato que lee la app).
String _daysAgo(int days) {
  final date = DateTime.now().subtract(Duration(days: days));
  return '${date.day}/${date.month}/${date.year}';
}

/// Postulaciones de ejemplo: cubren los estados, plataformas, modalidades,
/// ciudades y salarios que deben verse en las capturas.
List<JobApplication> _fixtureApplications() {
  return [
    // — Acme Tech (la empresa de referencia; 4 postulaciones) —
    JobApplication(
      rowIndex: 1,
      empresa: 'Acme Tech',
      vacante: 'Flutter Senior',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Remoto',
      ciudad: 'Bogotá',
      salarioOfrecido: '6.000.000 - 8.500.000 COP',
      estado: 'Entrevista realizada',
      link: 'https://www.linkedin.com/jobs/view/1000001',
      descripcion:
          'Desarrollo de apps móviles multiplataforma con Flutter para el '
          'sector fintech.\n\n'
          'Trabajarás en un equipo pequeño con autonomía sobre la arquitectura '
          'y las decisiones técnicas.',
      fechaPostulacion: _daysAgo(12),
      fechaSeguimiento: _daysAgo(1),
      contacto: 'Laura Gómez — reclutadora, responde por email',
      comentarios:
          '- ${_daysAgo(10)}: La reclutadora contactó por LinkedIn.\n'
          '- ${_daysAgo(4)}: Entrevista técnica superada, pasan a la final con '
          'el cliente.',
      entrevistaRealizada: true,
      porGestionar: true,
    ),
    JobApplication(
      rowIndex: 2,
      empresa: 'Acme Tech',
      vacante: 'Desarrollador Backend',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Híbrido',
      ciudad: 'Bogotá',
      salarioOfrecido: '5.000.000 - 7.000.000',
      estado: 'En revisión',
      link: 'https://www.linkedin.com/jobs/view/1000002',
      fechaPostulacion: _daysAgo(20),
      fechaSeguimiento: _daysAgo(6),
    ),
    JobApplication(
      rowIndex: 3,
      empresa: 'Acme Tech',
      vacante: 'QA Automation',
      tipoContrato: 'Por proyecto',
      modalidad: 'Remoto',
      ciudad: 'Medellín',
      salarioOfrecido: '4.000.000 - 5.200.000',
      estado: 'Prueba técnica',
      link: 'https://www.linkedin.com/jobs/view/1000003',
      fechaPostulacion: _daysAgo(30),
      fechaSeguimiento: _daysAgo(9),
      entrevistaRealizada: true,
    ),
    JobApplication(
      rowIndex: 4,
      empresa: 'Acme Tech',
      vacante: 'DevOps Engineer',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Remoto',
      ciudad: 'Bogotá',
      salarioOfrecido: '7.000.000 - 9.000.000',
      estado: 'Rechazada',
      link: 'https://www.linkedin.com/jobs/view/1000004',
      fechaPostulacion: _daysAgo(60),
      fechaSeguimiento: _daysAgo(40),
    ),

    // — Globant —
    JobApplication(
      rowIndex: 5,
      empresa: 'Globant',
      vacante: 'React Native Developer',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Remoto',
      ciudad: 'Cali',
      salarioOfrecido: '5.500.000 - 7.500.000',
      estado: 'Entrevista agendada',
      link: 'https://getonbrd.com/jobs/2000001',
      fechaPostulacion: _daysAgo(8),
      fechaSeguimiento: _daysAgo(3),
    ),
    JobApplication(
      rowIndex: 6,
      empresa: 'Globant',
      vacante: 'Java Developer',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Híbrido',
      ciudad: 'Bogotá',
      salarioOfrecido: 'USD 3200',
      estado: 'Oferta recibida',
      link: 'https://getonbrd.com/jobs/2000002',
      fechaPostulacion: _daysAgo(25),
      fechaSeguimiento: _daysAgo(4),
    ),
    JobApplication(
      rowIndex: 7,
      empresa: 'Globant',
      vacante: 'Data Engineer',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Remoto',
      ciudad: 'Medellín',
      salarioOfrecido: '6.800.000 - 8.200.000',
      estado: 'Aceptada',
      link: 'https://getonbrd.com/jobs/2000003',
      fechaPostulacion: _daysAgo(90),
      fechaSeguimiento: _daysAgo(70),
    ),

    // — Mercado Libre —
    JobApplication(
      rowIndex: 8,
      empresa: 'Mercado Libre',
      vacante: 'Frontend Angular',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Presencial',
      ciudad: 'Bogotá',
      salarioOfrecido: '5.200.000 - 6.500.000',
      estado: 'Enviada',
      link: 'https://www.elempleo.com/ofertas/3000001',
      fechaPostulacion: _daysAgo(5),
    ),
    JobApplication(
      rowIndex: 9,
      empresa: 'Mercado Libre',
      vacante: 'SRE',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Remoto',
      ciudad: 'Bogotá',
      salarioOfrecido: '8.000.000 - 10.000.000',
      estado: 'Sin respuesta',
      link: 'https://www.elempleo.com/ofertas/3000002',
      fechaPostulacion: _daysAgo(45),
    ),

    // — Rappi —
    JobApplication(
      rowIndex: 10,
      empresa: 'Rappi',
      vacante: 'Mobile iOS',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Híbrido',
      ciudad: 'Medellín',
      salarioOfrecido: '6.200.000 - 7.800.000',
      estado: 'Entrevista agendada',
      link: 'https://www.computrabajo.com.co/ofertas/4000001',
      fechaPostulacion: _daysAgo(15),
      fechaSeguimiento: _daysAgo(2),
      entrevistaRealizada: true,
      porGestionar: true,
    ),
    JobApplication(
      rowIndex: 11,
      empresa: 'Rappi',
      vacante: 'Product Designer',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Remoto',
      ciudad: 'Cali',
      salarioOfrecido: '4.800.000 - 6.000.000',
      estado: 'En revisión',
      link: 'https://www.computrabajo.com.co/ofertas/4000002',
      fechaPostulacion: _daysAgo(18),
      fechaSeguimiento: _daysAgo(7),
      porGestionar: true,
    ),

    // — Bancolombia —
    JobApplication(
      rowIndex: 12,
      empresa: 'Bancolombia',
      vacante: 'Analista de Datos',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Presencial',
      ciudad: 'Bogotá',
      salarioOfrecido: '4.200.000 - 5.500.000',
      estado: 'Entrevista realizada',
      link: 'https://co.indeed.com/viewjob/5000001',
      fechaPostulacion: _daysAgo(35),
      fechaSeguimiento: _daysAgo(11),
      entrevistaRealizada: true,
    ),
    JobApplication(
      rowIndex: 13,
      empresa: 'Bancolombia',
      vacante: 'Arquitecto Cloud',
      tipoContrato: 'Término fijo',
      modalidad: 'Híbrido',
      ciudad: 'Bogotá',
      salarioOfrecido: '9.000.000 - 11.000.000',
      estado: 'Retirada',
      link: 'https://co.indeed.com/viewjob/5000002',
      fechaPostulacion: _daysAgo(110),
      fechaSeguimiento: _daysAgo(80),
    ),

    // — Empresa confidencial —
    JobApplication(
      rowIndex: 14,
      empresa: 'Empresa confidencial',
      vacante: 'Full Stack',
      tipoContrato: 'Tiempo completo',
      modalidad: 'Remoto',
      ciudad: '',
      salarioOfrecido: '5.000.000 - 6.500.000',
      estado: 'Enviada',
      link: '',
      fechaPostulacion: _daysAgo(3),
    ),
    JobApplication(
      rowIndex: 15,
      empresa: 'Empresa confidencial',
      vacante: 'SysAdmin',
      tipoContrato: 'Prestación servicios',
      modalidad: 'Presencial',
      ciudad: 'Cali',
      salarioOfrecido: '3.800.000 - 4.600.000',
      estado: 'En revisión',
      link: 'https://www.linkedin.com/jobs/view/1000005',
      fechaPostulacion: _daysAgo(55),
      fechaSeguimiento: _daysAgo(20),
    ),
  ];
}

/// Análisis IA de ejemplo para la empresa de referencia (Acme Tech).
///
/// `totalPostulaciones` y `datosAl` se dejan consistentes con las
/// postulaciones de Acme para que la tarjeta no muestre "datos desactualizados".
List<CompanyInsight> _fixtureInsights() {
  return [
    CompanyInsight(
      empresa: 'Acme Tech',
      fechaAnalisis: DateTime.now(),
      datosAl: DateTime.now(),
      totalPostulaciones: 4,
      etiquetas: const ['respuesta-rapida', 'con-feedback', 'proceso-agil'],
      recomendacion: CompanyRecommendation.priorizar,
      resumen:
          'Empresa fintech con procesos de selección ágiles y transparentes. '
          'Reclutan de forma seria, comunican cada etapa y responden rápido.',
      fortalezas: const [
        'Siempre dan feedback después de cada etapa',
        'De postulación a oferta en menos de 3 semanas',
        'Salarios claros desde la primera conversación',
      ],
      riesgos: const ['Piden una prueba técnica larga (4–6 horas)'],
      perfilVacantes:
          'Roles de mobile y backend, contrato a término completo, modalidad '
          'remota o híbrida, salarios entre 5 y 8,5 M COP.',
      procesoSeleccion:
          'Postulación → filtro con recruiter → prueba técnica → entrevista '
          'técnica → oferta. Suele durar 2–3 semanas.',
      contactos: const ['Laura Gómez — reclutadora, responde por email'],
    ),
  ];
}
