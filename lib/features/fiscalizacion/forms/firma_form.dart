import 'dart:io';
import 'dart:ui' as ui;
import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart'; // For getDatabasesPath

class FirmaForm extends StatefulWidget {
  const FirmaForm({super.key});

  @override
  State<FirmaForm> createState() => _FirmaFormState();
}

class _FirmaFormState extends State<FirmaForm> {
  final _service = FiscalizacionService();
  List<List<Offset>> lines = [];
  String? _existingSignaturePath;
  Size? _canvasSize;

  @override
  void initState() {
    super.initState();
    _checkExistingSignature();
  }

  void _checkExistingSignature() {
    final path = _service.predio.cFirma;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        setState(() {
          _existingSignaturePath = path;
        });
      }
    }
  }

  Future<void> _saveSignature() async {
    if (lines.isEmpty && _existingSignaturePath == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Debe firmar antes de confirmar')),
        );
        return;
    }

    // If we have an existing signature and lines are empty, we just keep the existing one.
    // If user drew something new (lines not empty), we save the new one.
    if (lines.isNotEmpty && _canvasSize != null) {
      try {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, Rect.fromPoints(Offset.zero, Offset(_canvasSize!.width, _canvasSize!.height)));
        
        final painter = SignaturePainter(lines: lines);
        // Paint white background first
        final bgPaint = Paint()..color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(0, 0, _canvasSize!.width, _canvasSize!.height), bgPaint);
        
        painter.paint(canvas, _canvasSize!);
        
        final picture = recorder.endRecording();
        final img = await picture.toImage(_canvasSize!.width.toInt(), _canvasSize!.height.toInt());
        final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

        if (pngBytes != null) {
          final dbPath = await getDatabasesPath();
          final fileName = 'firma_${DateTime.now().millisecondsSinceEpoch}.png';
          final path = p.join(dbPath, fileName);
          final file = File(path);
          await file.writeAsBytes(pngBytes.buffer.asUint8List());
          
          _updatePredioModel(path);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando firma: $e')),
        );
        return;
      }
    } else if (_existingSignaturePath != null) {
       // Just re-confirming existing signature
       _updatePredioModel(_existingSignaturePath!);
    }
  }

  void _updatePredioModel(String path) {
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
      x: current.x,
      y: current.y,
      cFirma: path,
      createdAt: current.createdAt,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inspección Finalizada - Firma guardada')),
    );
    
    // Update local state to show the saved image instead of canvas
    setState(() {
      _existingSignaturePath = path;
      lines.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Firma del Administrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Signature Canvas
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRect(
              child: _existingSignaturePath != null
                  ? Image.file(File(_existingSignaturePath!), fit: BoxFit.contain)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Capture size once
                        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                        return GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              lines.add([details.localPosition]);
                            });
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              lines.last.add(details.localPosition);
                            });
                          },
                          child: CustomPaint(
                            painter: SignaturePainter(lines: lines),
                            size: Size.infinite,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    lines.clear();
                    _existingSignaturePath = null;
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('LIMPIAR', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Checkbox Disclaimer
          Row(
            children: [
              Checkbox(value: true, onChanged: (v) {}, activeColor: AppColors.primary),
              const Expanded(
                child: Text('Declaro que los datos proporcionados son verdaderos.'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _saveSignature();
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('CONFIRMAR INSPECCIÓN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<List<Offset>> lines;

  SignaturePainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (var line in lines) {
      for (int i = 0; i < line.length - 1; i++) {
        canvas.drawLine(line[i], line[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
