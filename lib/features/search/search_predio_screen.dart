import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:fiscagis/features/fiscalizacion/fiscalizacion_screen.dart';
import 'package:flutter/material.dart';

class SearchPredioScreen extends StatefulWidget {
  const SearchPredioScreen({super.key});

  @override
  State<SearchPredioScreen> createState() => _SearchPredioScreenState();
}

class _SearchPredioScreenState extends State<SearchPredioScreen> {
  final _service = FiscalizacionService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _manzanaCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();
  
  bool _isLoading = false;
  List<PredioModel> _results = [];
  bool _hasSearched = false;

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _results = [];
    });
    
    final filters = {
      if (_codigoCtrl.text.isNotEmpty) 'codigo': _codigoCtrl.text,
      if (_nombreCtrl.text.isNotEmpty) 'nombre': _nombreCtrl.text,
      if (_sectorCtrl.text.isNotEmpty) 'sector': _sectorCtrl.text,
      if (_manzanaCtrl.text.isNotEmpty) 'manzana': _manzanaCtrl.text,
      if (_loteCtrl.text.isNotEmpty) 'lote': _loteCtrl.text,
    };
    
    final list = await _service.searchPredio(filters);
    
    setState(() {
      _isLoading = false;
      _results = list;
    });
  }

  void _selectPredio(PredioModel predio) {
    // Load it into service context and go to form
    // Note: In a real app we might want to check if it already exists locally
    _service.loadInspection(predio.idPredio ?? '').then((_) {
        // If not found locally, we might need to save it first or pass it temporarily
        // For now, let's assume Search returns full data or we fetch it. 
        // We might need to 'import' this search result into local DB to start working.
        _importAndNavigate(predio);
    });
  }
  
  Future<void> _importAndNavigate(PredioModel item) async {
      await _service.updatePredio(item); // Save locally as drafted/imported
      if (!mounted) return;
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => const FiscalizacionScreen())
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar Predio")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _codigoCtrl,
                        decoration: const InputDecoration(labelText: 'Código Predial'),
                      ),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre Propietario'),
                      ),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _sectorCtrl, decoration: const InputDecoration(labelText: 'Sector'))),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(controller: _manzanaCtrl, decoration: const InputDecoration(labelText: 'Manzana'))),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(controller: _loteCtrl, decoration: const InputDecoration(labelText: 'Lote'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _search,
                          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.search),
                          label: _isLoading ? const CircularProgressIndicator() : const Text("BUSCAR"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _results.isEmpty 
              ? Center(child: Text(_hasSearched ? "No se encontraron resultados" : "Ingrese criterios de búsqueda"))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (ctx, i) {
                    final item = _results[i];
                    return ListTile(
                      leading: const Icon(Icons.home, color: AppColors.primary),
                      title: Text(item.direccion ?? 'Sin Dirección'),
                      subtitle: Text("${item.nombrePropietario}\nMz: ${item.manzana} Lt: ${item.lote}"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _selectPredio(item),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}
