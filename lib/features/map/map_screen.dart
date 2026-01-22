import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fiscagis/core/utils/log_service.dart';

class LoggingTileProvider extends NetworkTileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    String url = "";
    if (options.wmsOptions != null) {
      url = options.wmsOptions!.getUrl(
        coordinates,
        (options.tileSize ?? 256).toInt(),
        false,
      );
    } else {
      url =
          options.urlTemplate
              ?.replaceAll('{x}', coordinates.x.toString())
              .replaceAll('{y}', coordinates.y.toString())
              .replaceAll('{z}', coordinates.z.toString()) ??
          "";
    }

    LogService().log('Tile URL: $url');
    return super.getImage(coordinates, options);
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  // Layer visibility state
  bool _showSector = true;
  bool _showManzana = true;
  bool _showLote = true;
  bool _showConstrucciones = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _showLayerControl() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Capas del Mapa",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text("Sectores"),
                        value: _showSector,
                        onChanged: (v) {
                          setState(() => _showSector = v);
                          setModalState(() {});
                        },
                      ),
                      SwitchListTile(
                        title: const Text("Manzanas"),
                        value: _showManzana,
                        onChanged: (v) {
                          setState(() => _showManzana = v);
                          setModalState(() {});
                        },
                      ),
                      SwitchListTile(
                        title: const Text("Lotes"),
                        value: _showLote,
                        onChanged: (v) {
                          setState(() => _showLote = v);
                          setModalState(() {});
                        },
                      ),
                      SwitchListTile(
                        title: const Text("Construcciones"),
                        value: _showConstrucciones,
                        onChanged: (v) {
                          setState(() => _showConstrucciones = v);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showLogs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const LogViewerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Collect active layers
    final activeLayers = <String>[];
    if (_showSector) activeLayers.add('bd_lamolina2026:sp_sector');
    if (_showManzana) activeLayers.add('bd_lamolina2026:sp_manzana');
    if (_showLote) activeLayers.add('bd_lamolina2026:sp_lote');
    if (_showConstrucciones)
      activeLayers.add('bd_lamolina2026:sp_construcciones');

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa General')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                -12.100,
                -76.942,
              ), // Refined for data coverage
              initialZoom: 15.0,
            ),
            children: [
              // Base Layer (OSM)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.idg.fiscagis',
              ),

              // User WMS Layer (Consolidated)
              if (activeLayers.isNotEmpty)
                TileLayer(
                  tileProvider: LoggingTileProvider(),
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl:
                        'https://geoserver140.ideasg.org/geoserver/bd_lamolina2026/wms?',
                    layers: activeLayers.map((l) => l.split(':').last).toList(),
                    version: '1.1.1',
                    transparent: true,
                    format: 'image/png',
                    otherParameters: const {
                      'STYLES': '',
                      'SRS': 'EPSG:3857',
                      'exceptions': 'application/vnd.ogc.se_inimage',
                    },
                  ),
                  additionalOptions: const {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                  },
                ),

              // Test WMS Layer (Known working) - Keep for comparison if needed
              // TileLayer(
              //   wmsOptions: WMSTileLayerOptions(
              //     baseUrl: 'https://ahocevar.com/geoserver/wms',
              //     layers: ['topp:states'],
              //     version: '1.1.1',
              //     transparent: true,
              //     format: 'image/png',
              //   ),
              // ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),

          // Controls
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Layer Control
                FloatingActionButton(
                  heroTag: 'layers',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  onPressed: _showLayerControl,
                  child: const Icon(Icons.layers),
                ),
                const SizedBox(height: 10),

                // Log Viewer
                FloatingActionButton(
                  heroTag: 'logs',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  onPressed: _showLogs,
                  child: const Icon(Icons.bug_report),
                ),
                const SizedBox(height: 10),

                // My Location (Demo)
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  onPressed: () {
                    // TODO: Implement actual geolocation
                    // For now, center on La Molina
                    _mapController.move(const LatLng(-12.089, -76.920), 16);
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),

                // Zoom Controls
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
