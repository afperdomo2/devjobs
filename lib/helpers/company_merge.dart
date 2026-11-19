import '../models/job_application.dart';
import 'company_similarity.dart';

/// Filas que el merge debe renombrar a [finalName]: postulaciones cuyo
/// nombre de empresa pertenece a una de las [selected] pero no es
/// exactamente [finalName].
///
/// No toca las filas que ya llevan el nombre final; tampoco las de empresas
/// fuera de la selección. La comparación ignora mayúsculas, tildes y
/// puntuación, pero el renombrado sí reemplaza el texto completo por
/// [finalName] (unifica variantes como "XpertGroup" → "xpertgroup").
List<JobApplication> mergeRenameTargets(
  List<JobApplication> apps,
  Iterable<String> selected,
  String finalName,
) {
  final keys = {for (final name in selected) companyMatchKey(name)}
    ..remove('');
  if (keys.isEmpty || finalName.trim().isEmpty) return const [];

  return [
    for (final app in apps)
      if (keys.contains(companyMatchKey(app.empresa)) &&
          app.empresa != finalName)
        app,
  ];
}
