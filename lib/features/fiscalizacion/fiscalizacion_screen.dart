import 'package:fiscagis/features/fiscalizacion/forms/construccion_form.dart';
import 'package:fiscagis/features/fiscalizacion/forms/firma_form.dart';
import 'package:fiscagis/features/fiscalizacion/forms/foto_form.dart';
import 'package:fiscagis/features/fiscalizacion/forms/mapa_form.dart';
import 'package:fiscagis/features/fiscalizacion/forms/predio_form.dart';
import 'package:flutter/material.dart';

class FiscalizacionScreen extends StatefulWidget {
  final int initialIndex;

  const FiscalizacionScreen({super.key, this.initialIndex = 0});

  @override
  State<FiscalizacionScreen> createState() => _FiscalizacionScreenState();
}

class _FiscalizacionScreenState extends State<FiscalizacionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fisca GIS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          isScrollable: true, // Allow scrolling for 5 tabs
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Predio'),
            Tab(icon: Icon(Icons.construction), text: 'Construcción'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Capturar'),
            Tab(icon: Icon(Icons.map), text: 'Mapa'),
            Tab(icon: Icon(Icons.edit_document), text: 'Firma'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Prevent accidental swipes if signature interferes
        children: const [
          PredioForm(),
          ConstruccionForm(),
          FotoForm(),
          MapaForm(),
          FirmaForm(),
        ],
      ),
    );
  }
}
