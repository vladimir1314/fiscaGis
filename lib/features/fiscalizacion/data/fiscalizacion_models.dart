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
