import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:fiscagis/features/fiscalizacion/forms/construccion_dialog.dart';
import 'package:flutter/material.dart';

class ConstruccionForm extends StatefulWidget {
  const ConstruccionForm({super.key});

  @override
  State<ConstruccionForm> createState() => _ConstruccionFormState();
}

class _ConstruccionFormState extends State<ConstruccionForm> {
  final _service = FiscalizacionService();
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_update);
  }

  @override
  void dispose() {
    _service.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  Future<void> _addConstruccion() async {
    if (_isOpening) return;
    _isOpening = true;

    try {
      final result = await showDialog<ConstruccionModel>(
        context: context,
        builder: (context) => ConstruccionDialog(
          idPredio: _service.predio.idPredio ?? '',
        ),
      );

      if (result != null) {
        _service.addConstruccion(result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir formulario: $e')),
      );
    } finally {
      _isOpening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final constructions = _service.construcciones;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addConstruccion,
        child: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
      body: constructions.isEmpty
          ? const Center(
              child: Text(
                'No hay construcciones registradas.\nPulse + para agregar una.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: constructions.length,
              itemBuilder: (context, index) {
                final item = constructions[index];
                return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🛠 ID: ${item.id}', style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _service.removeConstruccion(item.id),
                      )
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                       Expanded(child: Text('🏢 PISO: ${item.piso}')),
                       Expanded(child: Text('➕ SECCIÓN: ${item.seccion}')),
                    ],
                  ),
                   const SizedBox(height: 8),
                  Text('📅 FECHA DE CONSTRUCCIÓN: ${item.fechaConstruccion?.toIso8601String().split('T')[0]}'),
                  const SizedBox(height: 8),
                  Text('🔧 MATERIAL: ${item.material}'),
                  Text('🛡 ESTADO: ${item.estado}'),
                  const SizedBox(height: 8),
                  // Matriz Mock
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _MatrixCell('MC', _hasVal(item.mc), value: item.mc),
                        _MatrixCell('T', _hasVal(item.t), value: item.t),
                        _MatrixCell('P', _hasVal(item.p), value: item.p),
                         _MatrixCell('PV', _hasVal(item.pv), value: item.pv),
                          _MatrixCell('R', _hasVal(item.r), value: item.r),
                           _MatrixCell('B', _hasVal(item.b), value: item.b),
                           _MatrixCell('IE', _hasVal(item.ie), value: item.ie),
                      ],
                    ),
                  ),
                   const SizedBox(height: 8),
                   Text('📐 AREA CONSTRUCCIÓN: ${item.areaConstruccion}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hasVal(String? v) => v != null && v.isNotEmpty && v != 'null';
}

class _MatrixCell extends StatelessWidget {
  final String label;
  final String? value;
  final bool active;
  
  const _MatrixCell(this.label, this.active, {this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: active ? AppColors.primary : Colors.grey),
      ),
      child: Column(
        children: [
           Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.black54)),
           if (active && value != null)
             Text(value!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
