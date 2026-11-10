/// Valores de los selectores del formulario de postulaciones.
///
/// Se mantienen en un solo lugar para que crear y editar usen exactamente las
/// mismas opciones.
library;

const List<String> applicationContractTypes = [
  'Tiempo completo',
  'Tiempo Parcial',
  'Por proyecto',
  'Temporal',
  'Freelance',
  'Otro',
];

const List<String> applicationModalities = [
  'Remoto',
  'Híbrido',
  'Presencial',
  'Otro',
];

const List<String> applicationStatuses = [
  'Enviada',
  'En revisión',
  'Entrevista agendada',
  'Entrevista realizada',
  'Prueba técnica',
  'Oferta recibida',
  'Rechazada',
  'Sin respuesta',
  'Aceptada',
  'Retirada',
];

/// Estados que cierran el proceso. Son los que ofrece el diálogo de
/// "Finalizar proceso" y los que cuentan como finalizadas en filtros y
/// métricas.
const List<String> applicationFinalStatuses = [
  'Aceptada',
  'Rechazada',
  'Retirada',
];
