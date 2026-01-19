import 'dart:convert';
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
    
    // Save initial draft
    await _db.insertOrUpdatePredio(predio);
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
    foto = newFoto;
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
       
       // 2. Real API Sending loop
       final url = Uri.parse('https://jsonplaceholder.typicode.com/posts'); 
       int successCount = 0;
       
       // Send Predios
       for (var item in unsyncedPredios) {
         try {
            final resp = await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(item),
            );
            if (resp.statusCode == 200 || resp.statusCode == 201) {
              await _db.markSynced('predio', 'id_predio', item['id_predio']);
              successCount++;
            }
         } catch(e) { print(e); }
       }
       
        // Send Construcciones
       for (var item in unsyncedConst) {
         try {
           final resp = await http.post(
             url,
             headers: {"Content-Type": "application/json"},
             body: jsonEncode(item),
           );
           if (resp.statusCode == 200 || resp.statusCode == 201) {
             await _db.markSynced('construccion', 'id', item['id']);
             successCount++;
           }
         } catch(e) { print(e); }
       }
       
        // Send Fotos
       for (var item in unsyncedFotos) {
         try {
           final resp = await http.post(
             url,
             headers: {"Content-Type": "application/json"},
             body: jsonEncode(item),
           );
           if (resp.statusCode == 200 || resp.statusCode == 201) {
             await _db.markSynced('foto', 'id_captura', item['id_captura']);
             successCount++;
           }
         } catch(e) { print(e); }
       }
       
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
