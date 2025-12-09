import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../core/printer_service.dart';

/// Page d'aperçu PDF avec options d'impression intégrées
/// Utilise PrinterService pour l'impression (même système que le test d'imprimante)
class PdfPreviewPage extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;

  const PdfPreviewPage({
    Key? key,
    required this.pdfBytes,
    this.title = 'Aperçu PDF',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Bouton d'impression dans la barre d'outils
          // Utilise PrinterService (même système que le test d'imprimante)
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              try {
                print('[PdfPreviewPage] 🖨️ Impression via PrinterService...');
                final printerService = PrinterService();
                final success = await printerService.printReceipt(
                  pdfBytes,
                  isAutoPrint: false,
                );
                
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Impression lancée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('L\'impression est désactivée dans les paramètres'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('[PdfPreviewPage] ❌ Erreur impression: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur impression: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Imprimer',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        allowPrinting: true, // Permet aussi l'impression via le widget PdfPreview
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
