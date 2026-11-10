import 'comments.dart';
import 'date_formatter.dart';

/// Campos que se envían a la hoja al finalizar un proceso.
///
/// La nota es opcional: cuando está vacía no se incluye `comentarios` para no
/// reescribir la columna. Si hay nota, se agrega fechada con [fecha] (la fecha
/// elegida por el usuario, que puede ser anterior a hoy).
Map<String, String> finalizationUpdates({
  required String estado,
  required DateTime fecha,
  required String comentariosActuales,
  String nota = '',
}) {
  final updates = <String, String>{
    'estado': estado,
    'fechaSeguimiento': formatApiDate(fecha),
    'porGestionar': 'false',
  };

  final clean = nota.trim();
  if (clean.isNotEmpty) {
    updates['comentarios'] = appendComment(
      comentariosActuales,
      clean,
      date: fecha,
    );
  }

  return updates;
}
