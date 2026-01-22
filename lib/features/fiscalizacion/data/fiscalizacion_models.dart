class PredioModel {
  String? idPredio;
  String? idPropietario;
  String? nombrePropietario;
  String? direccion;
  String? numero;
  String? condicion;
  String? barrio;
  String? manzana;
  String? lote;
  String? estado;
  String? tipo;
  String? uso;
  String? clasificacion;
  double? x;
  double? y;
  String? cFirma;
  DateTime? createdAt;
  bool isSynced; 

  PredioModel({
    this.idPredio,
    this.idPropietario,
    this.nombrePropietario,
    this.direccion,
    this.numero,
    this.condicion,
    this.barrio,
    this.manzana,
    this.lote,
    this.estado,
    this.tipo,
    this.uso,
    this.clasificacion,
    this.x,
    this.y,
    this.cFirma,
    this.createdAt,
    this.isSynced = false,
  });
}

class ConstruccionModel {
  String id;
  String idPredio; // FK
  String piso;
  String seccion;
  DateTime fechaConstruccion;
  String? clasificacion;
  String material;
  String estado;
  // Categorías
  String? mc;
  String? t;
  String? p;
  String? pv;
  String? r;
  String? b;
  String? ie;
  
  double areaConstruccion;
  double areaInspeccionada;
  DateTime? createdAt;

  ConstruccionModel({
    required this.id,
    this.idPredio = '',
    required this.piso,
    required this.seccion,
    required this.fechaConstruccion,
    this.clasificacion,
    required this.material,
    required this.estado,
    this.mc, this.t, this.p, this.pv, this.r, this.b, this.ie,
    required this.areaConstruccion,
    required this.areaInspeccionada,
    this.createdAt,
  });
}

class FotoModel {
  String? idCaptura;
  String? idPredio;
  String? descripcion;
  String? cRuta; 
  DateTime? createdAt;

  FotoModel({
    this.idCaptura,
    this.idPredio,
    this.descripcion,
    this.cRuta,
    this.createdAt,
  });
}

class OtrasInstalacionesModel {
  String id;
  String idPredio;
  String tipo; // e.g. "Piscina", "Muro"
  String unidadMedida; // "m2", "ml", "und"
  double cantidad;
  String estadoConservacion; // "Bueno", "Regular", "Malo"
  DateTime? createdAt;

  OtrasInstalacionesModel({
    required this.id,
    required this.idPredio,
    required this.tipo,
    required this.unidadMedida,
    required this.cantidad,
    required this.estadoConservacion,
    this.createdAt,
  });
}

class DeclaracionModel {
  String id;
  String idPredio;
  DateTime fechaDeclaracion;
  String numeroDeclaracion;
  double areaTerrenoDeclarada;
  double areaConstruidaDeclarada;
  DateTime? createdAt;

  DeclaracionModel({
    required this.id,
    required this.idPredio,
    required this.fechaDeclaracion,
    required this.numeroDeclaracion,
    required this.areaTerrenoDeclarada,
    required this.areaConstruidaDeclarada,
    this.createdAt,
  });
}

class DiferenciaAreaModel {
  String id;
  String idPredio;
  String tipoArea; // "Terreno", "Construcción"
  double areaDeclarada;
  double areaVerificada; // Por drone/campo
  double diferencia;
  DateTime? createdAt;

  DiferenciaAreaModel({
    required this.id,
    required this.idPredio,
    required this.tipoArea,
    required this.areaDeclarada,
    required this.areaVerificada,
    required this.diferencia,
    this.createdAt,
  });
}
