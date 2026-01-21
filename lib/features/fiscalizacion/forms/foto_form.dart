import 'dart:io';
import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class FotoForm extends StatefulWidget {
  const FotoForm({super.key});

  @override
  State<FotoForm> createState() => _FotoFormState();
}

class _FotoFormState extends State<FotoForm> {
  final _service = FiscalizacionService();
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _updateFromService();
    _service.addListener(_updateFromService);
  }

  @override
  void dispose() {
    _service.removeListener(_updateFromService);
    _descController.dispose();
    super.dispose();
  }

  void _updateFromService() {
    if (!mounted) return;
    setState(() {
      // Only update text if it's different to avoid cursor jumps or overwriting user typing
      if (_service.foto.descripcion != _descController.text) {
        _descController.text = _service.foto.descripcion ?? '';
      }
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
         // Save to persistent storage
         final dbPath = await getDatabasesPath();
         final fileName = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
         final persistentPath = p.join(dbPath, fileName);
         await File(photo.path).copy(persistentPath);

         // Use current predio ID from service to ensure consistency with DB (handles synced newId)
         final currentPredioId = _service.predio.idPredio;

         _service.updateFoto(FotoModel(
            idCaptura: _service.foto.idCaptura,
            idPredio: currentPredioId,
            cRuta: persistentPath,
            descripcion: _descController.text,
          ));
          setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cámara: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _service.foto.cRuta;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey),
            ),
            child: imagePath == null
                ? const Center(child: Icon(Icons.image, size: 64, color: Colors.grey))
                : (kIsWeb 
                    ? Image.network(imagePath, fit: BoxFit.cover) 
                    : Image.file(File(imagePath), fit: BoxFit.cover)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: Icon(Icons.camera_alt),
            label: Text(imagePath == null ? 'CAPTURAR FOTO' : 'TOMAR OTRA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
             decoration: const InputDecoration(
                labelText: 'Descripción de la foto',
                border: UnderlineInputBorder(),
              ),
            onChanged: (v) {
              _service.updateFoto(FotoModel(
                idCaptura: _service.foto.idCaptura,
                idPredio: _service.foto.idPredio,
                cRuta: _service.foto.cRuta,
                descripcion: v,
              ));
            },
          ),
           const SizedBox(height: 48), // Extra padding
           ElevatedButton.icon(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto guardada en: ${_service.foto.cRuta}')));
            },
            icon: Icon(Icons.save),
            label: Text('CONFIRMAR'),
             style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
