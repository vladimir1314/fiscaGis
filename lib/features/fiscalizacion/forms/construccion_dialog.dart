import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:flutter/material.dart';

class ConstruccionDialog extends StatefulWidget {
  const ConstruccionDialog({super.key});

  @override
  State<ConstruccionDialog> createState() => _ConstruccionDialogState();
}

class _ConstruccionDialogState extends State<ConstruccionDialog> {
  final _pisoCtrl = TextEditingController();
  final _seccionCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  
  // Categories (A-I)
  String? _mc = 'A';
  String? _t = 'A';
  String? _p = 'A';
  String? _pv = 'A';
  String? _r = 'A';
  String? _b = 'A';
  String? _ie = 'A';
  
  final List<String> _catOptions = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
  
  String _estado = 'BUENO';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Construcción'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
                Expanded(child: TextField(controller: _pisoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Piso'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _seccionCtrl, decoration: const InputDecoration(labelText: 'Sección'))),
            ]),
            TextField(controller: _materialCtrl, decoration: const InputDecoration(labelText: 'Material')),
            TextField(controller: _areaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Área (m2)')),
            DropdownButtonFormField<String>(
              value: _estado,
              items: ['BUENO', 'REGULAR', 'MALO'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _estado = v!),
              decoration: const InputDecoration(labelText: 'Estado'),
            ),
            const SizedBox(height: 16),
            const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCatDropdown('MC', _mc, (v) => _mc = v),
                _buildCatDropdown('T', _t, (v) => _t = v),
                _buildCatDropdown('P', _p, (v) => _p = v),
                _buildCatDropdown('PV', _pv, (v) => _pv = v),
                _buildCatDropdown('R', _r, (v) => _r = v),
                _buildCatDropdown('B', _b, (v) => _b = v),
                _buildCatDropdown('IE', _ie, (v) => _ie = v),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: () {
            if (_pisoCtrl.text.isEmpty) return;
            final newC = ConstruccionModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              idPredio: '11628', 
              piso: _pisoCtrl.text,
              seccion: _seccionCtrl.text,
              fechaConstruccion: DateTime.now(),
              material: _materialCtrl.text,
              estado: _estado,
              mc: _mc, t: _t, p: _p,
              pv: _pv, r: _r, b: _b, ie: _ie,
              areaConstruccion: double.tryParse(_areaCtrl.text) ?? 0.0,
              areaInspeccionada: 0,
            );
            Navigator.pop(context, newC);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('AGREGAR', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildCatDropdown(String label, String? value, Function(String?) onChange) {
    return SizedBox(
      width: 60,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: const OutlineInputBorder(),
        ),
        items: _catOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => onChange(v)),
      ),
    );
  }
}
