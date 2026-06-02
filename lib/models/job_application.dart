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
  });

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
    );
  }
}

class DashboardStats {
  final int total;
  final int enRevision;
  final int entrevistas;
  final int ofertas;
  final int rechazadas;

  const DashboardStats({
    required this.total,
    required this.enRevision,
    required this.entrevistas,
    required this.ofertas,
    required this.rechazadas,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      enRevision: (json['enRevision'] as num?)?.toInt() ?? 0,
      entrevistas: (json['entrevistas'] as num?)?.toInt() ?? 0,
      ofertas: (json['ofertas'] as num?)?.toInt() ?? 0,
      rechazadas: (json['rechazadas'] as num?)?.toInt() ?? 0,
    );
  }
}
