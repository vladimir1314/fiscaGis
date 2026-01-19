import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:fiscagis/features/fiscalizacion/fiscalizacion_screen.dart';
import 'package:flutter/material.dart';

class FiscalizacionesListScreen extends StatefulWidget {
  const FiscalizacionesListScreen({super.key});

  @override
  State<FiscalizacionesListScreen> createState() => _FiscalizacionesListScreenState();
}

class _FiscalizacionesListScreenState extends State<FiscalizacionesListScreen> {
  final _service = FiscalizacionService();

  @override
  void initState() {
    super.initState();
    _refresh();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
   if (mounted) setState(() {});
  }
  
  void _refresh() {
    _service.loadAll();
  }

  void _goToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FiscalizacionScreen()),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final list = _service.allFiscalizaciones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Fiscalizaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _service.isSyncing 
              ? null 
              : () async {
                  // Show loading snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sincronizando... por favor espere')),
                  );
                  
                  final result = await _service.synchronize();
                  
                  if (mounted) {
                     showDialog(
                       context: context,
                       builder: (_) => AlertDialog(
                         title: Text(result.success ? "Sincronización Exitosa" : "Atención"),
                         content: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(
                               result.success ? Icons.check_circle : Icons.warning,
                               color: result.success ? Colors.green : Colors.orange,
                               size: 48,
                             ),
                             const SizedBox(height: 16),
                             Text(result.message),
                             if (result.total > 0)
                               Text("Registros guardados: ${result.count} / ${result.total}", style: const TextStyle(fontWeight: FontWeight.bold)),
                           ],
                         ),
                         actions: [
                           TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
                         ],
                       ),
                     );
                  }
                },
            icon: _service.isSyncing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Icon(Icons.cloud_upload), // Changed icon
            tooltip: 'Sincronizar Datos',
          )
        ],
      ),
      body: list.isEmpty
          ? const Center(child: Text('No hay inspecciones registradas.\nUsa el botón + para crear una.'))
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final PredioModel item = list[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange, // item.isSynced ? Colors.green : Colors.orange,
                      child: Icon(Icons.access_time, color: Colors.white), // item.isSynced ? Colors.check : Colors.access_time
                    ),
                    title: Text(item.idPredio ?? 'Sin ID', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prop: ${item.nombrePropietario ?? '---'}'),
                        Text('Dir: ${item.direccion ?? '---'}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await _service.loadInspection(item.idPredio!);
                      if (mounted) _goToDetail(context);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _service.startNewInspection();
          if (mounted) _goToDetail(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
