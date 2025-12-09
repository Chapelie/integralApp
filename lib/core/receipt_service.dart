import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'printer_service.dart';
import 'company_warehouse_service.dart';

class ReceiptService {
  final PrinterService _printerService = PrinterService();

  /// Generate and print receipt for a sale
  Future<void> print(dynamic sale) async {
    final pdfBytes = await generateReceipt(sale);
    await _printerService.printReceipt(pdfBytes);
  }

  /// Generate and return PDF bytes for a sale
  /// Returns the PDF bytes so the caller can display them in a preview page
  Future<Uint8List> generatePdfBytes(dynamic sale) async {
    return await generateReceipt(sale);
  }

  Future<Uint8List> generateReceipt(dynamic sale) async {
    final pdf = pw.Document();
    
    // Récupérer le nom de la company
    String companyName = 'INTEGRALPOS';
    try {
      final companyWarehouseService = CompanyWarehouseService();
      final company = await companyWarehouseService.getSelectedCompany();
      if (company != null && company.name.isNotEmpty) {
        companyName = company.name.toUpperCase();
      }
    } catch (e) {
      print('[ReceiptService] Erreur récupération company: $e');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header avec nom de la company
              _buildHeader(companyName),
              pw.SizedBox(height: 10),
              
              // Sale info
              _buildSaleInfo(sale),
              pw.SizedBox(height: 10),
              
              // Items
              _buildItems(sale),
              pw.SizedBox(height: 10),
              
              // Totals
              _buildTotals(sale),
              pw.SizedBox(height: 10),
              
              // Payment info
              _buildPaymentInfo(sale),
              pw.SizedBox(height: 10),
              
              // Footer avec "Powered by IntegralPOS"
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String companyName) {
    return pw.Column(
      children: [
        // Nom de la company en haut
        pw.Text(
          companyName,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Point de Vente',
          style: pw.TextStyle(fontSize: 12),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildSaleInfo(dynamic sale) {
    final now = sale.createdAt ?? DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Vente #${sale.id}'),
        pw.Text('Date: ${formatter.format(now)}'),
        if (sale.customerId != null) pw.Text('Client ID: ${sale.customerId}'),
        pw.SizedBox(height: 4),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildItems(dynamic sale) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Article', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Prix', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Divider(),
        ...sale.items.map<pw.Widget>((item) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    item.productName,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Text(
                  '${item.quantity}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  _formatCurrency(item.lineTotal),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTotals(dynamic sale) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Sous-total:'),
            pw.Text(_formatCurrency(sale.subtotal)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TVA:'),
            pw.Text(_formatCurrency(sale.taxAmount)),
          ],
        ),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              _formatCurrency(sale.total),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaymentInfo(dynamic sale) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Paiement:'),
            pw.Text(_getPaymentMethodName(sale.paymentMethod)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Merci pour votre achat!',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.Text(
          'Powered by IntegralPOS',
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'XOF',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte';
      case 'mobile':
        return 'Mobile';
      case 'check':
        return 'Chèque';
      default:
        return method;
    }
  }
}