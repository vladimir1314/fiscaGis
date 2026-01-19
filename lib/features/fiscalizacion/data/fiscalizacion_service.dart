import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/local_database.dart';
import 'package:flutter/foundation.dart';

class FiscalizacionService extends ChangeNotifier {
  // Singleton
  static final FiscalizacionService _instance = FiscalizacionService._internal();
  factory FiscalizacionService() => _instance;
  FiscalizacionService._internal() {
    _initRepository();
  }

  final _db = LocalDatabase.instance;

  // Cache State (for UI binding)
  PredioModel predio = PredioModel();
  List<ConstruccionModel> construcciones = [];
  FotoModel foto = FotoModel();

  Future<void> _initRepository() async {
    // Attempt to load existing data
    // For demo, we assume we are working with specific ID '11628'
    const targetId = '11628';
    
    // 1. Get Predio
    final loadedPredio = await _db.getPredio(targetId);
    if (loadedPredio != null) {
      predio = loadedPredio;
    } else {
      // Initialize with default if not found (First Run)
      predio = PredioModel(
        idPredio: targetId,
        idPropietario: '9923',
        nombrePropietario: 'HINOSTROZA GUTIERREZ FORTUNATO',
        direccion: 'CALLE SIN NOMBRE',
        numero: '167 N',
        createdAt: DateTime.now(),
      );
      await _db.insertOrUpdatePredio(predio);
    }

    // 2. Get Construcciones
    construcciones = await _db.getConstrucciones(targetId);
    if (construcciones.isEmpty) {
       // Optional: Add mock if empty
       // ...
    }

    // 3. Get Foto
    final loadedFoto = await _db.getFoto(targetId);
    if (loadedFoto != null) {
      foto = loadedFoto;
    } else {
       foto = FotoModel(idPredio: targetId);
    }

    notifyListeners();
  }

  // --- Methods ---

  Future<void> updatePredio(PredioModel newPredio) async {
    predio = newPredio;
    await _db.insertOrUpdatePredio(predio);
    notifyListeners();
  }

  Future<void> addConstruccion(ConstruccionModel construccion) async {
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
    // Generate UUID if needed
    if (newFoto.idCaptura == null) {
        newFoto.idCaptura = DateTime.now().millisecondsSinceEpoch.toString();
    }
    foto = newFoto;
    await _db.insertOrUpdateFoto(foto);
    notifyListeners();
  }
  
  // --- SYNC ---
  bool isSyncing = false;
  
  Future<String> synchronize() async {
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
         return "Nada pendiente de sincronizar.";
       }
       
       // 2. Mock API Sending loop
       await Future.delayed(const Duration(seconds: 2)); // Simulate network
       
       // 3. Mark as synced
       for (var r in unsyncedPredios) await _db.markSynced('predio', 'id_predio', r['id_predio']);
       for (var r in unsyncedConst) await _db.markSynced('construccion', 'id', r['id']);
       for (var r in unsyncedFotos) await _db.markSynced('foto', 'id_captura', r['id_captura']);
       
       isSyncing = false;
       notifyListeners();
       return "Sincronización Exitosa: $total registros enviados.";
       
     } catch (e) {
       isSyncing = false;
       notifyListeners();
       return "Error al sincronizar: $e";
     }
  }
}
