import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:flutter/material.dart';

class PredioForm extends StatefulWidget {
  const PredioForm({super.key});

  @override
  State<PredioForm> createState() => _PredioFormState();
}

class _PredioFormState extends State<PredioForm> {
  final _service = FiscalizacionService();
  
  // Controllers
  final _idPredioInfoCtrl = TextEditingController();
  final _idPropInfoCtrl = TextEditingController();
  final _nombrePropCtrl = TextEditingController(); // Antes senor
  final _direccionCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController(); // Nuevo
  final _barrioCtrl = TextEditingController();
  final _manzanaCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();

  String? _selectedCondicion;
  String? _selectedEstado;
  String? _selectedTipo;
  String? _selectedUso;
  String? _selectedClasi;

  String? _loadedId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _service.addListener(_loadData);
  }

  @override
  void dispose() {
    _service.removeListener(_loadData);
    _idPredioInfoCtrl.dispose();
    _idPropInfoCtrl.dispose();
    _nombrePropCtrl.dispose();
    _direccionCtrl.dispose();
    _numeroCtrl.dispose();
    _barrioCtrl.dispose();
    _manzanaCtrl.dispose();
    _loteCtrl.dispose();
    super.dispose();
  }

  void _loadData() {
    final predio = _service.predio;
    
    // Only reload text controllers if we are looking at a different predio
    // This prevents overwriting user input when other parts of the app (like Map) update the model
    if (_loadedId != predio.idPredio) {
      _loadedId = predio.idPredio;
      
      _idPredioInfoCtrl.text = predio.idPredio ?? '';
      _idPropInfoCtrl.text = predio.idPropietario ?? '';
      _nombrePropCtrl.text = predio.nombrePropietario ?? '';
      _direccionCtrl.text = predio.direccion ?? '';
      _numeroCtrl.text = predio.numero ?? '';
      _barrioCtrl.text = predio.barrio ?? '';
      _manzanaCtrl.text = predio.manzana ?? '';
      _loteCtrl.text = predio.lote ?? '';
      
      _selectedCondicion = predio.condicion;
      _selectedEstado = predio.estado;
      _selectedTipo = predio.tipo;
      _selectedUso = predio.uso;
      _selectedClasi = predio.clasificacion;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField('Id Predio', _idPredioInfoCtrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildReadOnlyField('Id Propietario', _idPropInfoCtrl),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildReadOnlyField('Nombre Propietario', _nombrePropCtrl),
          const SizedBox(height: 16),
          _buildReadOnlyField('Dirección', _direccionCtrl),
          const SizedBox(height: 16),
          _buildReadOnlyField('Número', _numeroCtrl), // Nuevo campo
          const SizedBox(height: 16),
          
          _buildDropdown('Condición', ['PROPIETARIO', 'ARRENDATARIO'], _selectedCondicion, (v) => _selectedCondicion = v),
          const SizedBox(height: 16),
          
          _buildTextField('Barrio', _barrioCtrl),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildTextField('Manzana', _manzanaCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Lote', _loteCtrl)),
            ],
          ),
          const SizedBox(height: 16),
           Row(
            children: [
              Expanded(child: _buildDropdown('Estado', ['BUENO', 'REGULAR', 'MALO'], _selectedEstado, (v) => _selectedEstado = v)),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown('Tipo', ['CASA', 'EDIFICIO'], _selectedTipo, (v) => _selectedTipo = v)),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdown('Uso', ['VIVIENDA', 'COMERCIO'], _selectedUso, (v) => _selectedUso = v),
          const SizedBox(height: 16),
          _buildDropdown('Clasificación', ['URBANO', 'RURAL'], _selectedClasi, (v) => _selectedClasi = v),
          const SizedBox(height: 24),
           ElevatedButton.icon(
            onPressed: () {
               _savePredio();
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Datos Guardados')));
            },
            icon: Icon(Icons.save),
            label: Text('GUARDAR CAMBIOS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 48), // Extra space for mobile scrolling
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      // readOnly: true, // User requested editable
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.primary),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.green)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
     return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey),
        border: UnderlineInputBorder(),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: UnderlineInputBorder(),
      ),
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        onChanged(v);
        _savePredio();
      },
    );
  }

  void _savePredio() {
    // Helper to safely update model
    final current = _service.predio;
    _service.updatePredio(PredioModel(
      idPredio: _idPredioInfoCtrl.text,
      idPropietario: _idPropInfoCtrl.text,
      nombrePropietario: _nombrePropCtrl.text,
      direccion: _direccionCtrl.text,
      numero: _numeroCtrl.text,
      barrio: _barrioCtrl.text,
      manzana: _manzanaCtrl.text,
      lote: _loteCtrl.text,
      condicion: _selectedCondicion ?? current.condicion,
      estado: _selectedEstado ?? current.estado,
      tipo: _selectedTipo ?? current.tipo,
      uso: _selectedUso ?? current.uso,
      clasificacion: _selectedClasi ?? current.clasificacion,
      // Preserve other fields
      x: current.x,
      y: current.y,
      cFirma: current.cFirma,
      createdAt: current.createdAt,
    ));
  }
}
