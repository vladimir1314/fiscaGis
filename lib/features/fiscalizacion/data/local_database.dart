import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fiscagis.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Table PREDIO
    await db.execute('''
      CREATE TABLE predio (
        id_predio TEXT PRIMARY KEY,
        id_propietario TEXT,
        nombre_propietario TEXT,
        direccion TEXT,
        numero TEXT,
        condicion TEXT,
        barrio TEXT,
        manzana TEXT,
        lote TEXT,
        estado TEXT,
        tipo TEXT,
        uso TEXT,
        clasificacion TEXT,
        x REAL,
        y REAL,
        c_firma TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Table CONSTRUCCION
    await db.execute('''
      CREATE TABLE construccion (
        id TEXT PRIMARY KEY,
        id_predio TEXT,
        piso TEXT,
        seccion TEXT,
        fecha_construccion TEXT,
        clasificacion TEXT,
        material TEXT,
        estado TEXT,
        area_construccion REAL,
        area_inspeccionada REAL,
        mc TEXT, t TEXT, p TEXT, pv TEXT, r TEXT, b TEXT, ie TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (id_predio) REFERENCES predio (id_predio)
      )
    ''');
    
    // Table FOTO
    await db.execute('''
      CREATE TABLE foto (
        id_captura TEXT PRIMARY KEY,
        id_predio TEXT,
        descripcion TEXT,
        c_ruta TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (id_predio) REFERENCES predio (id_predio)
      )
    ''');
    // Table OTRAS_INSTALACIONES
    await db.execute('''
      CREATE TABLE otras_instalaciones (
        id TEXT PRIMARY KEY,
        id_predio TEXT,
        tipo TEXT,
        unidad_medida TEXT,
        cantidad REAL,
        estado_conservacion TEXT,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (id_predio) REFERENCES predio (id_predio)
      )
    ''');

    // Table DECLARACIONES
    await db.execute('''
      CREATE TABLE declaraciones (
        id TEXT PRIMARY KEY,
        id_predio TEXT,
        fecha_declaracion TEXT,
        numero_declaracion TEXT,
        area_terreno_declarada REAL,
        area_construida_declarada REAL,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (id_predio) REFERENCES predio (id_predio)
      )
    ''');


    // Table DIFERENCIAS_AREAS
    await db.execute('''
      CREATE TABLE diferencias_areas (
        id TEXT PRIMARY KEY,
        id_predio TEXT,
        tipo_area TEXT,
        area_declarada REAL,
        area_verificada REAL,
        diferencia REAL,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (id_predio) REFERENCES predio (id_predio)
      )
    ''');
  }

  // --- CRUD PREDIO ---
  Future<void> insertOrUpdatePredio(PredioModel item) async {
    final db = await database;
    final data = {
      'id_predio': item.idPredio,
      'id_propietario': item.idPropietario,
      'nombre_propietario': item.nombrePropietario,
      'direccion': item.direccion,
      'numero': item.numero,
      'condicion': item.condicion,
      'barrio': item.barrio,
      'manzana': item.manzana,
      'lote': item.lote,
      'estado': item.estado,
      'tipo': item.tipo,
      'uso': item.uso,
      'clasificacion': item.clasificacion,
      'x': item.x,
      'y': item.y,
      'c_firma': item.cFirma,
      'created_at': item.createdAt?.toIso8601String(),
      'is_synced': 0, // Always mark unsynced on update
    };
    
    // Check if exists
    final exists = await db.query('predio', where: 'id_predio = ?', whereArgs: [item.idPredio]);
    if (exists.isNotEmpty) {
      await db.update('predio', data, where: 'id_predio = ?', whereArgs: [item.idPredio]);
    } else {
      await db.insert('predio', data);
    }
  }

  Future<PredioModel?> getPredio(String id) async {
    final db = await database;
    final maps = await db.query('predio', where: 'id_predio = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      final map = maps.first;
      return PredioModel(
        idPredio: map['id_predio'] as String?,
        idPropietario: map['id_propietario'] as String?,
        nombrePropietario: map['nombre_propietario'] as String?,
        direccion: map['direccion'] as String?,
        numero: map['numero'] as String?,
        condicion: map['condicion'] as String?,
        barrio: map['barrio'] as String?,
        manzana: map['manzana'] as String?,
        lote: map['lote'] as String?,
        estado: map['estado'] as String?,
        tipo: map['tipo'] as String?,
        uso: map['uso'] as String?,
        clasificacion: map['clasificacion'] as String?,
        x: map['x'] as double?,
        y: map['y'] as double?,
        cFirma: map['c_firma'] as String?,
      );
    }
    return null;
  }

  Future<List<PredioModel>> getAllPredios() async {
    final db = await database;
    final result = await db.query('predio', orderBy: 'created_at DESC');
    return result.map((map) => PredioModel(
      idPredio: map['id_predio'] as String?,
      idPropietario: map['id_propietario'] as String?,
      nombrePropietario: map['nombre_propietario'] as String?,
      direccion: map['direccion'] as String?,
      numero: map['numero'] as String?,
      condicion: map['condicion'] as String?,
      barrio: map['barrio'] as String?,
      manzana: map['manzana'] as String?,
      lote: map['lote'] as String?,
      estado: map['estado'] as String?,
      tipo: map['tipo'] as String?,
      uso: map['uso'] as String?,
      clasificacion: map['clasificacion'] as String?,
      x: map['x'] as double?,
      y: map['y'] as double?,
      cFirma: map['c_firma'] as String?,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      // createdAt is missing in DB schema but useful for sorting
    )).toList();
  }

  // --- CRUD CONSTRUCCION ---
  Future<void> insertConstruccion(ConstruccionModel item) async {
    final db = await database;
    await db.insert('construccion', {
      'id': item.id,
      'id_predio': item.idPredio,
      'piso': item.piso,
      'seccion': item.seccion,
      'fecha_construccion': item.fechaConstruccion.toIso8601String(),
      'clasificacion': item.clasificacion,
      'material': item.material,
      'estado': item.estado,
      'area_construccion': item.areaConstruccion,
      'area_inspeccionada': item.areaInspeccionada,
      'mc': item.mc, 't': item.t, 'p': item.p,
      'pv': item.pv, 'r': item.r, 'b': item.b, 'ie': item.ie,
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ConstruccionModel>> getConstrucciones(String predioId) async {
    final db = await database;
    final result = await db.query('construccion', where: 'id_predio = ?', whereArgs: [predioId]);
    
    return result.map((json) => ConstruccionModel(
      id: json['id'] as String,
      idPredio: json['id_predio'] as String,
      piso: json['piso'] as String,
      seccion: json['seccion'] as String,
      fechaConstruccion: DateTime.parse(json['fecha_construccion'] as String),
      clasificacion: json['clasificacion'] as String?,
      material: json['material'] as String,
      estado: json['estado'] as String,
      areaConstruccion: json['area_construccion'] as double,
      areaInspeccionada: json['area_inspeccionada'] as double,
      mc: json['mc'] as String?, t: json['t'] as String?, p: json['p'] as String?,
      pv: json['pv'] as String?, r: json['r'] as String?, b: json['b'] as String?, ie: json['ie'] as String?,
    )).toList();
  }

  Future<void> deleteConstruccion(String id) async {
    final db = await database;
    await db.delete('construccion', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD FOTO ---
  Future<void> insertOrUpdateFoto(FotoModel item) async {
    if (item.idCaptura == null) return;
    final db = await database;
    final data = {
      'id_captura': item.idCaptura,
      'id_predio': item.idPredio,
      'descripcion': item.descripcion,
      'c_ruta': item.cRuta,
      'is_synced': 0,
    };
     await db.insert('foto', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<FotoModel?> getFoto(String predioId) async {
    final db = await database;
    final result = await db.query('foto', where: 'id_predio = ?', whereArgs: [predioId], limit: 1);
    if (result.isNotEmpty) {
      final json = result.first;
      return FotoModel(
        idCaptura: json['id_captura'] as String?,
        idPredio: json['id_predio'] as String?,
        descripcion: json['descripcion'] as String?,
        cRuta: json['c_ruta'] as String?,
      );
    }
    return null;
  }

  // --- SYNC HELPERS ---
  Future<List<Map<String, dynamic>>> getUnsyncedPredios() async => await (await database).query('predio', where: 'is_synced = 0');
  Future<List<Map<String, dynamic>>> getUnsyncedConstrucciones() async => await (await database).query('construccion', where: 'is_synced = 0');
  Future<List<Map<String, dynamic>>> getUnsyncedFotos() async => await (await database).query('foto', where: 'is_synced = 0');
  
  Future<void> markSynced(String table, String idCol, String id) async {
    final db = await database;
    await db.update(table, {'is_synced': 1}, where: '$idCol = ?', whereArgs: [id]);
  }

  Future<void> updatePredioId(String oldId, String newId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('predio', {'id_predio': newId}, where: 'id_predio = ?', whereArgs: [oldId]);
      await txn.update('construccion', {'id_predio': newId}, where: 'id_predio = ?', whereArgs: [oldId]);
      await txn.update('foto', {'id_predio': newId}, where: 'id_predio = ?', whereArgs: [oldId]);
    });
  }

  Future<void> deleteAllSynced() async {
    final db = await database;
    // Delete synced children first
    await db.delete('construccion', where: 'is_synced = 1');
    await db.delete('foto', where: 'is_synced = 1');
    
    // Delete synced predios ONLY if they have no remaining children (orphaned or unsynced)
    // This protects predios that still have unsynced children from being deleted.
    await db.rawDelete('''
      DELETE FROM predio 
      WHERE is_synced = 1 
      AND id_predio NOT IN (SELECT id_predio FROM construccion)
      AND id_predio NOT IN (SELECT id_predio FROM foto)
    ''');
  }


  // --- CRUD OTRAS INSTALACIONES ---
  Future<void> insertOtrasInstalaciones(OtrasInstalacionesModel item) async {
    final db = await database;
    await db.insert('otras_instalaciones', {
      'id': item.id,
      'id_predio': item.idPredio,
      'tipo': item.tipo,
      'unidad_medida': item.unidadMedida,
      'cantidad': item.cantidad,
      'estado_conservacion': item.estadoConservacion,
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- CRUD DECLARACIONES ---
  Future<void> insertDeclaracion(DeclaracionModel item) async {
    final db = await database;
    await db.insert('declaraciones', {
      'id': item.id,
      'id_predio': item.idPredio,
      'fecha_declaracion': item.fechaDeclaracion.toIso8601String(),
      'numero_declaracion': item.numeroDeclaracion,
      'area_terreno_declarada': item.areaTerrenoDeclarada,
      'area_construida_declarada': item.areaConstruidaDeclarada,
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- CRUD DIFERENCIAS AREAS ---
  Future<void> insertDiferenciaArea(DiferenciaAreaModel item) async {
    final db = await database;
    await db.insert('diferencias_areas', {
      'id': item.id,
      'id_predio': item.idPredio,
      'tipo_area': item.tipoArea,
      'area_declarada': item.areaDeclarada,
      'area_verificada': item.areaVerificada,
      'diferencia': item.diferencia,
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
