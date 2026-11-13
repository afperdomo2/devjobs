import 'comments.dart';
import 'date_formatter.dart';
import 'status.dart';

/// Campos que se envían a la hoja al cambiar el estado de una postulación.
///
/// El cambio de estado siempre mueve la última novedad: `fechaSeguimiento` es
/// lo que alimentan los días sin novedad, el orden por novedad y la actividad
/// reciente.
///
/// La nota es opcional: cuando está vacía no se incluye `comentarios` para no
/// reescribir la columna. Si hay nota, se agrega fechada con [fecha] (la fecha
/// elegida por el usuario, que puede ser anterior a hoy).
///
/// `porGestionar` solo se limpia cuando el nuevo estado cierra el proceso:
/// un avance intermedio no debe borrar la marca manual de "algo pendiente".
///
/// `entrevistaRealizada` (columna N) se incluye solo cuando el usuario lo
/// cambió respecto al valor actual; pasar `null` deja la columna intacta.
Map<String, String> changeStatusUpdates({
  required String estado,
  required DateTime fecha,
  required String comentariosActuales,
  String nota = '',
  bool? entrevistaRealizada,
}) {
  final updates = <String, String>{
    'estado': estado,
    'fechaSeguimiento': formatApiDate(fecha),
  };

  if (isTerminalStatus(estado)) {
    updates['porGestionar'] = 'false';
  }

  if (entrevistaRealizada != null) {
    updates['entrevistaRealizada'] = entrevistaRealizada.toString();
  }

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
