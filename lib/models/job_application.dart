import 'dart:math' as math;

import '../helpers/date_formatter.dart';
import '../helpers/domain_parser.dart';

/// Días sin novedad a partir de los cuales un proceso activo se marca
/// visualmente como estancado (ámbar en card y detalles).
const kUmbralDiasSinNovedad = 7;

/// Estados que cierran el proceso (no siguen en curso).
const _estadosFinales = {'aceptada', 'rechazada', 'retirada'};

class JobApplication {
  final int rowIndex;
  final String empresa;
  final String vacante;
  final String tipoContrato;
  final String modalidad;
  final String ciudad;
  final String salarioOfrecido;
  final String estado;
  final String link;
  final String descripcion;
  final String fechaPostulacion;
  final String fechaSeguimiento;
  final String contacto;
  final String comentarios;
  final bool entrevistaRealizada;

  const JobApplication({
    required this.rowIndex,
    this.empresa = '',
    this.vacante = '',
    this.tipoContrato = '',
    this.modalidad = '',
    this.ciudad = '',
    this.salarioOfrecido = '',
    this.estado = '',
    this.link = '',
    this.descripcion = '',
    this.fechaPostulacion = '',
    this.fechaSeguimiento = '',
    this.contacto = '',
    this.comentarios = '',
    this.entrevistaRealizada = false,
  });

  /// true si el proceso ya terminó (Aceptada, Rechazada o Retirada).
  bool get isFinalizado => _estadosFinales.contains(estado.trim().toLowerCase());

  /// Días del proceso según su estado:
  /// - Finalizado: duración total (postulación → última novedad).
  /// - Activo: lo que lleva hasta hoy (postulación → hoy).
  ///
  /// null si no hay fecha de postulación, o si es finalizado y no hay
  /// fecha de seguimiento (duración desconocida).
  int? get diasProceso {
    final post = parseDate(fechaPostulacion);
    if (post == null) return null;
    if (isFinalizado) {
      final seg = parseDate(fechaSeguimiento);
      if (seg == null) return null;
      return math.max(0, seg.difference(post).inDays);
    }
    return math.max(0, DateTime.now().difference(post).inDays);
  }

  /// Días transcurridos desde la última novedad (fecha de seguimiento),
  /// solo para procesos activos. Si no hay fecha de seguimiento, se usa
  /// la de postulación (sin novedad desde que se postuló).
  int? get diasSinNovedad {
    if (isFinalizado) return null;
    final ref = parseDate(fechaSeguimiento) ?? parseDate(fechaPostulacion);
    if (ref == null) return null;
    return math.max(0, DateTime.now().difference(ref).inDays);
  }

  String get plataforma => extractPlatform(link);

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      rowIndex: (json['_rowIndex'] as num?)?.toInt() ?? 0,
      empresa: json['empresa'] as String? ?? '',
      vacante: json['vacante'] as String? ?? '',
      tipoContrato: json['tipoContrato'] as String? ?? '',
      modalidad: json['modalidad'] as String? ?? '',
      ciudad: json['ciudad'] as String? ?? '',
      salarioOfrecido: json['salarioOfrecido'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      link: json['link'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      fechaPostulacion: json['fechaPostulacion'] as String? ?? '',
      fechaSeguimiento: json['fechaSeguimiento'] as String? ?? '',
      contacto: json['contacto'] as String? ?? '',
      comentarios: json['comentarios'] as String? ?? '',
      entrevistaRealizada: json['entrevistaRealizada']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_rowIndex': rowIndex,
      'empresa': empresa,
      'vacante': vacante,
      'tipoContrato': tipoContrato,
      'modalidad': modalidad,
      'ciudad': ciudad,
      'salarioOfrecido': salarioOfrecido,
      'estado': estado,
      'link': link,
      'descripcion': descripcion,
      'fechaPostulacion': fechaPostulacion,
      'fechaSeguimiento': fechaSeguimiento,
      'contacto': contacto,
      'comentarios': comentarios,
      'entrevistaRealizada': entrevistaRealizada,
    };
  }

  JobApplication copyWith({
    int? rowIndex,
    String? empresa,
    String? vacante,
    String? tipoContrato,
    String? modalidad,
    String? ciudad,
    String? salarioOfrecido,
    String? estado,
    String? link,
    String? descripcion,
    String? fechaPostulacion,
    String? fechaSeguimiento,
    String? contacto,
    String? comentarios,
    bool? entrevistaRealizada,
  }) {
    return JobApplication(
      rowIndex: rowIndex ?? this.rowIndex,
      empresa: empresa ?? this.empresa,
      vacante: vacante ?? this.vacante,
      tipoContrato: tipoContrato ?? this.tipoContrato,
      modalidad: modalidad ?? this.modalidad,
      ciudad: ciudad ?? this.ciudad,
      salarioOfrecido: salarioOfrecido ?? this.salarioOfrecido,
      estado: estado ?? this.estado,
      link: link ?? this.link,
      descripcion: descripcion ?? this.descripcion,
      fechaPostulacion: fechaPostulacion ?? this.fechaPostulacion,
      fechaSeguimiento: fechaSeguimiento ?? this.fechaSeguimiento,
      contacto: contacto ?? this.contacto,
      comentarios: comentarios ?? this.comentarios,
      entrevistaRealizada: entrevistaRealizada ?? this.entrevistaRealizada,
    );
  }
}

class DashboardStats {
  final int total;
  final int activas;
  final int entrevistas;
  final int rechazadas;

  const DashboardStats({
    required this.total,
    required this.activas,
    required this.entrevistas,
    required this.rechazadas,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      activas: (json['activas'] as num?)?.toInt() ?? 0,
      entrevistas: (json['entrevistas'] as num?)?.toInt() ?? 0,
      rechazadas: (json['rechazadas'] as num?)?.toInt() ?? 0,
    );
  }
}
