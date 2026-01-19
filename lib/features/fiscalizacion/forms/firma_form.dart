import 'package:fiscagis/core/theme/app_colors.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_models.dart';
import 'package:fiscagis/features/fiscalizacion/data/fiscalizacion_service.dart';
import 'package:flutter/material.dart';

class FirmaForm extends StatefulWidget {
  const FirmaForm({super.key});

  @override
  State<FirmaForm> createState() => _FirmaFormState();
}

class _FirmaFormState extends State<FirmaForm> {
  final _service = FiscalizacionService();
  List<List<Offset>> lines = [];

  void _saveSignature() {
    // In a real app, we would convert canvas to image and save file.
    // Here we simulate it for the model structure requirements.
    final mockPath = 'firma_${DateTime.now().millisecondsSinceEpoch}.png';
    
    final current = _service.predio;
    _service.updatePredio(PredioModel(
      idPredio: current.idPredio,
      idPropietario: current.idPropietario,
      nombrePropietario: current.nombrePropietario, // Updated field
      direccion: current.direccion,
      numero: current.numero, // Updated field
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
      // UPDATE SIGNATURE
      cFirma: mockPath,
      createdAt: current.createdAt,
    ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inspección Finalizada - Firma guardada en: $mockPath')),
      );
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
              child: GestureDetector(
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
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() => lines.clear());
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
              if (lines.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Debe firmar antes de confirmar')),
                  );
                  return;
              }
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
