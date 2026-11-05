import '../models/job_application.dart';
import '../models/job_import.dart';
import 'comments.dart';
import 'job_duplicate.dart';
import 'job_url.dart';
import 'salary_formatter.dart';
import 'salary_parser.dart';
import 'text_normalizer.dart';
import 'text_shortener.dart';

/// Salario listo para el formulario, o una nota para Comentarios.
class SalaryMapping {
  final String? value;
  final String? note;

  const SalaryMapping({this.value, this.note});
}

const _placeholderCompanies = [
  'confidencial',
  'confidential',
  'importante empresa',
  'empresa privada',
  'empresa del sector',
  'empresa anonima',
  'anonima',
];

const _platformCompanies = {
  'linkedin',
  'computrabajo',
  'getonbrd',
  'magneto',
  'elempleo',
  'indeed',
  'torre',
  'glassdoor',
  'bumeran',
  'workday',
  'greenhouse',
  'lever',
  'ashby',
  'jobgether',
};

/// Convierte los datos crudos de la página + IA en campos del formulario.
JobImportResult buildJobImportResult({
  required ParsedJobPage page,
  required AiJobData? ai,
  required String link,
  required List<JobApplication> existing,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final warnings = <String>{};
  final fields = <String, String>{};
  final imported = <String>{};

  final company =
      _cleanCompany(page.company, warnings) ??
      _cleanCompany(ai?.empresa, warnings);

  final rawTitle = page.hasJobPosting
      ? (page.title ?? ai?.vacante)
      : (ai?.vacante ?? page.title);
  final title = cleanJobTitle(rawTitle);

  final contract = mapContractType(
    page.employmentType ?? ai?.tipoContrato,
    page.text,
  );

  final employment = page.employmentType ?? '';
  final modalityRaw = employment.toUpperCase().contains('TELECOMMUTE')
      ? 'Remoto'
      : (ai?.modalidad ??
            (employment.toUpperCase().contains('REMOTE') ? 'Remoto' : null));
  final modality = mapModality(modalityRaw);

  final city = _cleanCity(page.city ?? ai?.ciudad);
  final salary = _mapSalary(page.salaryText ?? ai?.salarioTexto, warnings);
  final description = _pickDescription(page, ai, warnings);
  final contact = _cleanContact(ai?.contacto, warnings);
  final notes = _buildNotes(
    ai: ai,
    salaryNote: salary.note,
    company: company,
    title: title,
    salaryValue: salary.value,
    now: current,
  );

  void put(String key, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;
    fields[key] = text;
    imported.add(key);
  }

  put('empresa', company);
  put('vacante', title);
  put('tipoContrato', contract);
  put('modalidad', modality);
  put('ciudad', city);
  put('salarioOfrecido', salary.value);
  put('descripcion', description);
  put('contacto', contact);
  put('comentarios', notes);

  final normalizedLink = normalizeJobUrl(link);
  put('link', normalizedLink);

  if (company == null) {
    warnings.add('No se encontró la empresa; complétala.');
  }
  if (title == null) {
    warnings.add('No se encontró el cargo; complétalo.');
  }
  if (description == null) {
    warnings.add('No se encontró la descripción de la vacante.');
  }
  if (page.warning != null &&
      page.kind != JobPageKind.detail &&
      page.kind != JobPageKind.unknown) {
    warnings.add(page.warning!);
  }

  final hasCore = [
    'empresa',
    'vacante',
    'descripcion',
  ].every(imported.contains);
  final status = hasCore ? JobImportStatus.success : JobImportStatus.partial;

  final source = page.hasJobPosting
      ? (ai != null ? 'JSON-LD + IA' : 'JSON-LD')
      : (ai != null ? 'IA' : '');

  return JobImportResult(
    status: status,
    fields: fields,
    importedFields: imported,
    warnings: warnings.toList(),
    duplicate: findDuplicateByLink(existing, normalizedLink),
    source: source,
    kind: page.kind,
  );
}

String? cleanJobTitle(String? raw) {
  var text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  text = text.replaceAll(
    RegExp(
      r'\s*[|·]\s*(Empleos de\s+)?(LinkedIn|Computrabajo|GetOnBrd|Magneto|Elempleo|Indeed|Torre|Glassdoor|Bumerán|Bumeran)\s*$',
      caseSensitive: false,
    ),
    '',
  );
  text = text.replaceAll(
    RegExp(r'\s*[|·]\s*Bolsa de Empleo\s*$', caseSensitive: false),
    '',
  );
  text = text.replaceAll(
    RegExp(
      r'\s+[-–]\s+(LinkedIn|Computrabajo|GetOnBrd|Magneto|Elempleo|Indeed|Torre|Glassdoor|Bumerán|Bumeran)\s*$',
      caseSensitive: false,
    ),
    '',
  );
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.isEmpty ? null : truncate(text, 140);
}

String? mapContractType(String? raw, [String? context]) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  final normalized = normalizeText(text);
  final ctx = normalizeText(context ?? '');

  if (normalized.contains('full time') ||
      normalized.contains('full-time') ||
      normalized.contains('full_time') ||
      normalized.contains('fulltime') ||
      normalized.contains('tiempo completo') ||
      normalized.contains('jornada completa')) {
    return 'Tiempo completo';
  }
  if (normalized.contains('part time') ||
      normalized.contains('part-time') ||
      normalized.contains('part_time') ||
      normalized.contains('parttime') ||
      normalized.contains('medio tiempo') ||
      normalized.contains('tiempo parcial') ||
      normalized.contains('jornada parcial')) {
    return 'Tiempo Parcial';
  }
  if (normalized.contains('contractor') || normalized.contains('contratista')) {
    return 'Freelance';
  }
  if (normalized.contains('temporary') || normalized.contains('temporario')) {
    return 'Temporal';
  }
  if (normalized.contains('intern') ||
      normalized.contains('volunteer') ||
      normalized.contains('per_diem') ||
      normalized == 'other') {
    return 'Otro';
  }
  if (normalized.contains('por proyecto') ||
      normalized.contains('obra o labor') ||
      normalized.contains('obra labor')) {
    return 'Por proyecto';
  }
  if (normalized.contains('temporal') ||
      normalized.contains('termino fijo') ||
      normalized.contains('plazo fijo')) {
    return 'Temporal';
  }
  if (normalized.contains('freelance') ||
      normalized.contains('prestacion de servicios') ||
      normalized.contains('independiente')) {
    return 'Freelance';
  }
  if (normalized.contains('practica') ||
      normalized.contains('pasantia') ||
      normalized.contains('intern')) {
    return 'Otro';
  }
  if (normalized.contains('indefinido')) {
    return ctx.contains('tiempo completo') || ctx.contains('jornada completa')
        ? 'Tiempo completo'
        : 'Indefinido';
  }

  return text.length <= 40 ? text : 'Otro';
}

String? mapModality(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  final normalized = normalizeText(text);
  if (normalized.contains('remoto') ||
      normalized.contains('remote') ||
      normalized.contains('teletrabajo') ||
      normalized.contains('home office') ||
      normalized.contains('homeoffice') ||
      normalized.contains('telecommute')) {
    return 'Remoto';
  }
  if (normalized.contains('hibrido') || normalized.contains('hybrid')) {
    return 'Híbrido';
  }
  if (normalized.contains('presencial') ||
      normalized.contains('on-site') ||
      normalized.contains('onsite') ||
      normalized.contains('on site') ||
      normalized.contains('oficina')) {
    return 'Presencial';
  }

  return text.length <= 30 ? text : 'Otro';
}

String? _cleanCompany(String? raw, Set<String> warnings) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  final normalized = normalizeText(text);
  if (_placeholderCompanies.any(normalized.contains)) {
    warnings.add('La empresa venía como confidencial; complétala.');
    return null;
  }
  if (_platformCompanies.contains(normalized)) {
    warnings.add('La empresa detectada es el portal; verifícala.');
    return null;
  }

  return truncate(text, 120);
}

String? _cleanCity(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  final normalized = normalizeText(text);
  const notCities = {
    'remote',
    'remoto',
    'anywhere',
    'worldwide',
    'cualquier lugar',
  };
  if (notCities.contains(normalized)) return null;
  return truncate(text, 80);
}

String? _cleanContact(String? raw, Set<String> warnings) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return null;

  warnings.add('Se detectó un contacto; verifícalo.');
  return truncate(text, 100);
}

SalaryMapping _mapSalary(String? raw, Set<String> warnings) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return const SalaryMapping();

  final normalized = normalizeText(text);
  const unsupported = [
    'eur',
    'euro',
    'gbp',
    'libra',
    'mxn',
    'peso mexicano',
    'brl',
    'reais',
    'cad',
    'aud',
  ];
  if (text.contains('€') ||
      text.contains('£') ||
      unsupported.any((currency) => normalized.contains(currency))) {
    warnings.add(
      'El salario viene en una moneda distinta de COP/USD; se anotó en Comentarios.',
    );
    return SalaryMapping(note: _salaryNoteText(text));
  }

  const vague = [
    'convenir',
    'a tratar',
    'segun experiencia',
    'segun perfil',
    'no especificado',
    'salario no',
  ];
  if (vague.any((signal) => normalized.contains(signal))) {
    warnings.add(
      'El salario no es un monto concreto; se anotó en Comentarios.',
    );
    return SalaryMapping(note: _salaryNoteText(text));
  }

  final parsed = parseSalary(text);
  if (parsed == null) {
    warnings.add('No se pudo interpretar el salario; se anotó en Comentarios.');
    return SalaryMapping(note: _salaryNoteText(text));
  }

  return SalaryMapping(value: formatSalaryOffer(parsed));
}

String _salaryNoteText(String text) {
  final clean = truncate(text, 80);
  return normalizeText(clean).startsWith('salario') ? clean : 'Salario: $clean';
}

String? _pickDescription(
  ParsedJobPage page,
  AiJobData? ai,
  Set<String> warnings,
) {
  final fromAi = ai?.descripcion?.trim();
  String? candidate;

  if (page.hasJobPosting) {
    candidate = _longer(page.description?.trim(), fromAi);
  } else {
    candidate = (fromAi != null && fromAi.isNotEmpty)
        ? fromAi
        : page.description?.trim();
  }

  if (candidate == null || candidate.length < 40) return null;
  if (candidate.length > 4000) {
    warnings.add('La descripción se recortó a 4.000 caracteres.');
    return truncate(candidate, 4000);
  }
  return candidate;
}

String? _longer(String? a, String? b) {
  final first = a?.trim() ?? '';
  final second = b?.trim() ?? '';
  if (first.isEmpty) return second.isEmpty ? null : second;
  if (second.isEmpty) return first;
  return first.length >= second.length ? first : second;
}

String? _buildNotes({
  required AiJobData? ai,
  required String? salaryNote,
  required String? company,
  required String? title,
  required String? salaryValue,
  required DateTime now,
}) {
  final items = <String>[];
  final seen = <String>{};

  void add(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.length > 140) return;

    final normalized = normalizeText(text);
    if (normalized.contains('job id') ||
        normalized.contains('id:') ||
        normalized.contains('http') ||
        normalized.contains('www.')) {
      return;
    }
    if (normalized.startsWith('salario')) return;
    if (company != null && normalizeText(company) == normalized) return;
    if (title != null && normalizeText(title) == normalized) return;
    if (salaryValue != null && normalizeText(salaryValue) == normalized) {
      return;
    }
    if (!seen.add(normalized)) return;
    items.add(text);
  }

  for (final item in ai?.datosClave ?? const <String>[]) {
    add(item);
  }

  // La nota de salario se agrega aparte: el filtro de arriba descarta
  // cualquier dato que empiece por "salario" porque ya tiene su campo.
  if (salaryNote != null) {
    final text = salaryNote.trim();
    if (text.isNotEmpty && seen.add(normalizeText(text))) {
      items.add(text);
    }
  }

  if (items.isEmpty) return null;

  final joined = items.take(5).join(' · ');
  return appendComment('', 'Datos clave: $joined', date: now);
}
