import 'dart:convert';
import 'dart:io';
import 'package:fiscagis/core/services/http_provider.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/local_database.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

class FiscalizacionService extends ChangeNotifier {
  // Singleton
  static final FiscalizacionService _instance = FiscalizacionService._internal();
  factory FiscalizacionService() => _instance;
  FiscalizacionService._internal() {
    // We don't auto-load a specific ID anymore on init, or we load list
  }

  final _db = LocalDatabase.instance;
  final _httpProvider = HttpProvider();

  // Cache State (for UI binding)
  PredioModel predio = PredioModel();
  List<ConstruccionModel> construcciones = [];
  FotoModel foto = FotoModel();
  
  // List State
  List<PredioModel> allFiscalizaciones = []; // Summary list

  // --- List Management ---
  
  Future<void> loadAll() async {
    allFiscalizaciones = await _db.getAllPredios();
    notifyListeners();
  }

  Future<void> startNewInspection() async {
    // Generate new unique ID
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    
    predio = PredioModel(
      idPredio: newId,
      createdAt: DateTime.now(),
      // Defaults or Empty?
      nombrePropietario: '',
      direccion: '',
      numero: '',
    );
    construcciones = [];
    foto = FotoModel(idPredio: newId);
    
    // Save initial draft - REMOVED to prevent empty records
    // await _db.insertOrUpdatePredio(predio);
    notifyListeners();
  }

  Future<void> loadInspection(String id) async {
    final loaded = await _db.getPredio(id);
    if (loaded != null) {
      predio = loaded;
      construcciones = await _db.getConstrucciones(id);
      final loadedFoto = await _db.getFoto(id);
      foto = loadedFoto ?? FotoModel(idPredio: id);
      notifyListeners();
    }
  }

  // --- CRUD Methods ---

  Future<void> updatePredio(PredioModel newPredio) async {
    predio = newPredio;
    await _db.insertOrUpdatePredio(predio);
    notifyListeners();
  }

  Future<void> addConstruccion(ConstruccionModel construccion) async {
    // Ensure FK is set
    construccion.idPredio = predio.idPredio ?? '';

    // Ensure predio exists in DB before adding child
    await _db.insertOrUpdatePredio(predio);

    // Prevent duplicates
    if (construcciones.any((c) => c.id == construccion.id)) return;

    construcciones.add(construccion);
    await _db.insertConstruccion(construccion);
    notifyListeners();
  }

  Future<void> removeConstruccion(String id) async {
    construcciones.removeWhere((element) => element.id == id);
    await _db.deleteConstruccion(id);
    notifyListeners();
  }

  Future<void> updateFoto(FotoModel newFoto) async {
    if (newFoto.idCaptura == null) {
        newFoto.idCaptura = DateTime.now().millisecondsSinceEpoch.toString();
    }
    
    // Ensure ID consistency with parent (uses newId if synced)
    if (predio.idPredio != null) {
      newFoto.idPredio = predio.idPredio;
    }

    foto = newFoto;
    
    // Ensure predio exists in DB before adding child
    await _db.insertOrUpdatePredio(predio);
    
    await _db.insertOrUpdateFoto(foto);
    notifyListeners();
  }
  
  // --- SYNC ---
  bool isSyncing = false;
  
  Future<SyncResult> synchronize() async {
     try {
       isSyncing = true;
       notifyListeners();
       
       // 1. Fetch unsynced
       final unsyncedPredios = await _db.getUnsyncedPredios();
       final unsyncedConst = await _db.getUnsyncedConstrucciones();
       final unsyncedFotos = await _db.getUnsyncedFotos();
       
       int total = unsyncedPredios.length + unsyncedConst.length + unsyncedFotos.length;
       if (total == 0) {
         isSyncing = false;
         notifyListeners();
         return SyncResult(success: true, message: "Todo está actualizado.", count: 0);
       }
       
       // Map to track ID changes: OldID -> NewID
       Map<String, String> idMap = {};

       // 2. Real API Sending loop
       int successCount = 0;
       
       // Send Predios
       for (var item in unsyncedPredios) {
         try {
            // Convert Map<String, dynamic> to Map<String, String> for fields
           final Map<String, String> fields = {};

            item.forEach((key, value) {
              if (key == 'c_firma') return; // NO enviar como campo
              if (value != null) {
                fields[key] = value.toString();
              }
            });
            
           List<http.MultipartFile> files = [];

              final firmaPath = item['c_firma'];
              if (firmaPath != null && firmaPath.isNotEmpty) {
                final file = File(firmaPath);
                if (await file.exists()) {
                  files.add(
                    await http.MultipartFile.fromPath(
                      'firma_predio',
                      file.path,
                    ),
                  );
                }
              }


            final resp = await _httpProvider.postMultipart(
              'fiscalizacionGis/predio/registrar',
              fields: fields,
              files: files,
            );
            
            if (resp != null) {
              final oldId = item['id_predio'].toString();
              String? newId;

              // Try to parse new ID from response
              if (resp is Map) {
                if (resp.containsKey('id_predio')) newId = resp['id_predio']?.toString();
                else if (resp.containsKey('id')) newId = resp['id']?.toString();
                // Check data wrapper
                if (newId == null && resp['data'] is Map) {
                   newId = resp['data']['id_predio']?.toString() ?? resp['data']['id']?.toString();
                }
              }

              // Update local DB if ID changed
              if (newId != null && newId.isNotEmpty && newId != oldId) {
                await _db.updatePredioId(oldId, newId);
                idMap[oldId] = newId;
                
                // Update current in-memory model if it matches
                if (predio.idPredio == oldId) {
                   predio.idPredio = newId;
                   // Update children in memory to maintain consistency
                   for (var c in construcciones) {
                      if (c.idPredio == oldId) c.idPredio = newId;
                   }
                   if (foto.idPredio == oldId) {
                      foto.idPredio = newId; // Explicitly use newId for foto
                   }
                }
              }

              await _db.markSynced('predio', 'id_predio', newId ?? oldId);
              successCount++;
            }
         } catch(e) { debugPrint('Error syncing predio: $e'); }
       }
       
        // Send Construcciones
       for (var item in unsyncedConst) {
         try {
           final oldPredioId = item['id_predio'].toString();
           final targetPredioId = idMap[oldPredioId] ?? oldPredioId;

           // Format fields according to requirement
           String fecha = '';
           if (item['fecha_construccion'] != null) {
              try {
                final date = DateTime.parse(item['fecha_construccion'].toString());
                fecha = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              } catch (_) {
                fecha = item['fecha_construccion'].toString();
              }
           }

           final Map<String, String> fields = {
             "id_predio": targetPredioId,
             "piso": item['piso']?.toString() ?? '',
             "seccion": item['seccion']?.toString() ?? '',
             "fecha_construccion": fecha,
             "clasificacion": item['clasificacion']?.toString() ?? '',
             "material": item['material']?.toString() ?? '',
             "estado": item['estado']?.toString() ?? '',
             "mc": item['mc']?.toString() ?? '',
             "t": item['t']?.toString() ?? '',
             "p": item['p']?.toString() ?? '',
             "pv": item['pv']?.toString() ?? '',
             "r": item['r']?.toString() ?? '',
             "b": item['b']?.toString() ?? '',
             "ie": item['ie']?.toString() ?? '',
             "area_construccion": item['area_construccion']?.toString() ?? '',
             "area_inspeccionada": item['area_inspeccionada']?.toString() ?? '',
           };
           
           final resp = await _httpProvider.post(
             'fiscalizacionGis/construccion/registrar',
             body: fields,
           );
           
           if (resp != null) {
             await _db.markSynced('construccion', 'id', item['id']);
             successCount++;
           }
         } catch(e) { debugPrint('Error syncing construccion: $e'); }
       }
       
        // Send Fotos
       for (var item in unsyncedFotos) {
         try {
           final oldPredioId = item['id_predio'].toString();
           final targetPredioId = idMap[oldPredioId] ?? oldPredioId;

           final Map<String, String> fields = {
             'id_predio': targetPredioId,
             'descripcion': item['descripcion']?.toString() ?? '',
           };

           List<http.MultipartFile> files = [];

           // Process image if path exists
           if (item['c_ruta'] != null && item['c_ruta'].isNotEmpty) {
             final file = File(item['c_ruta']);
             if (await file.exists()) {
               files.add(await http.MultipartFile.fromPath('foto_captura', file.path));
             }
           }

           final resp = await _httpProvider.postMultipart(
             'fiscalizacionGis/captura/registrar',
             fields: fields,
             files: files,
           );

           if (resp != null) {
             await _db.markSynced('foto', 'id_captura', item['id_captura']);
             successCount++;
           }
         } catch(e) { debugPrint('Error syncing foto: $e'); }
       }
       
       // Clean up synced data
       await _db.deleteAllSynced();

       isSyncing = false;
       await loadAll(); // Refresh list to update sync icons
       notifyListeners();
       return SyncResult(
         success: successCount > 0, 
         message: "Sincronización completada.", 
         count: successCount,
         total: total
       );
       
     } catch (e) {
       isSyncing = false;
       notifyListeners();
       return SyncResult(success: false, message: "Error de conexión: $e");
     }
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int count;
  final int total;
  
  SyncResult({required this.success, required this.message, this.count = 0, this.total = 0});
}
