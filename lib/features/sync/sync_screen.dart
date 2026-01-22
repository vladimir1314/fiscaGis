import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:flutter/material.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _service = FiscalizacionService();
  bool _isLoading = false;
  String _statusMessage = "Presione descargar para obtener datos del servidor.";
  
  Future<void> _startDownload() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Descargando datos...";
    });
    
    final result = await _service.downloadData();
    
    setState(() {
      _isLoading = false;
      _statusMessage = result.message;
    });
    
    if (result.success) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Descarga exitosa: ${result.count} registros.')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sincronización")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cloud_download, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              "Sincronizar Datos de Campo",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              "Descargar predios, construcciones, declaraciones y diferencias de áreas asignadas.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
             const SizedBox(height: 32),
             if (_isLoading)
               const Center(child: CircularProgressIndicator())
             else
               ElevatedButton.icon(
                 onPressed: _startDownload,
                 icon: const Icon(Icons.download),
                 label: const Text("DESCARGAR DATOS"),
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                 ),
               ),
             const SizedBox(height: 24),
             Text(
               _statusMessage, 
               textAlign: TextAlign.center,
               style: TextStyle(
                 color: _statusMessage.contains("Error") ? Colors.red : Colors.green[800],
                 fontWeight: FontWeight.w500
               ),
             ),
          ],
        ),
      ),
    );
  }
}
