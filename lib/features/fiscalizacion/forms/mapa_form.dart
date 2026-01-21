import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Import

class MapaForm extends StatefulWidget {
  const MapaForm({super.key});

  @override
  State<MapaForm> createState() => _MapaFormState();
}

class _MapaFormState extends State<MapaForm> {
  final _service = FiscalizacionService();
  final MapController _mapController = MapController();
  
  // Default: Lima
  LatLng _currentCenter = const LatLng(-12.046374, -77.042793);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load existing coordinates if they exist
    if (_service.predio.y != null && _service.predio.x != null) {
      _currentCenter = LatLng(_service.predio.y!, _service.predio.x!);
    }
    // Auto-geolocalize on start if no data
    else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Servicios de ubicación desactivados.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permisos de ubicación denegados.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permisos de ubicación denegados permanentemente.';
      }

      // Try to get last known position first for speed
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          setState(() {
            _currentCenter = LatLng(lastKnown.latitude, lastKnown.longitude);
            _mapController.move(_currentCenter, 16.0);
          });
        }
      } catch (_) {}

      // Get precise position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentCenter, 18.0);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación actualizada')));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
        _currentCenter = camera.center;
        if (mounted) setState(() {});
    }
  }
  
  void _saveLocation() {
    final current = _service.predio;
    _service.updatePredio(PredioModel(
      idPredio: current.idPredio,
      idPropietario: current.idPropietario,
      nombrePropietario: current.nombrePropietario,
      direccion: current.direccion,
      numero: current.numero,
      condicion: current.condicion,
      barrio: current.barrio,
      manzana: current.manzana,
      lote: current.lote,
      estado: current.estado,
      tipo: current.tipo,
      uso: current.uso,
      clasificacion: current.clasificacion,
      // UPDATE COORDINATES
      x: _currentCenter.longitude,
      y: _currentCenter.latitude,
      cFirma: current.cFirma,
      createdAt: current.createdAt,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ubicación (X, Y) Guardada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: 15.0,
            onPositionChanged: _onPositionChanged,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.fiscagis',
            ),
             // Fixed marker
             const Center(
               child: Icon(Icons.location_on, color: Colors.red, size: 40),
             ),
          ],
        ),
        // GEOLOCATION BUTTON
        Positioned(
          top: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'gps_btn',
            onPressed: _isLoading ? null : _getCurrentLocation,
            backgroundColor: Colors.white,
            child: _isLoading 
              ? const CircularProgressIndicator() 
              : const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.primary),
                    title: const Text('Coordenadas (X, Y)'),
                    subtitle: Text(
                      'Y (Lat): ${_currentCenter.latitude.toStringAsFixed(6)}\n'
                      'X (Lng): ${_currentCenter.longitude.toStringAsFixed(6)}',
                    ),
                  ),
                  const Divider(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveLocation,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('GUARDAR GEOLOCALIZACIÓN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
