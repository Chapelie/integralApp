// lib/core/reports_service.dart
/// Reports service for generating and printing reports
///
/// Handles report generation, printing, and sales accounting
/// for the IntegralPOS system.
library;

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/sale.dart';
import '../models/cash_movement.dart';
import 'storage_service.dart';
import 'printer_service.dart';

class ReportsService {
  static final ReportsService _instance = ReportsService._internal();
  factory ReportsService() => _instance;
  ReportsService._internal();

  final StorageService _storageService = StorageService();
  final PrinterService _printerService = PrinterService();

  /// Générer un rapport de ventes pour une période
  String generateSalesReport(DateTime startDate, DateTime endDate) {
    final sales = _storageService.getSalesByDateRange(startDate, endDate);
    final cashMovements = _storageService.getCashMovements();
    
    // Filtrer les mouvements de caisse pour la période
    final periodMovements = cashMovements.where((movement) {
      return movement.createdAt.isAfter(startDate) && 
             movement.createdAt.isBefore(endDate);
    }).toList();

    final salesMovements = periodMovements.where((m) => m.type == 'sale').toList();
    final manualMovements = periodMovements.where((m) => m.type == 'manual_in' || m.type == 'manual_out').toList();

    final totalSales = sales.fold(0.0, (sum, sale) => sum + sale.total);
    final salesCount = sales.length;
    final averageSale = salesCount > 0 ? totalSales / salesCount : 0.0;

    // Compter les méthodes de paiement
    final paymentMethods = <String, int>{};
    for (final sale in sales) {
      paymentMethods[sale.paymentMethod] = (paymentMethods[sale.paymentMethod] ?? 0) + 1;
    }

    // Générer le contenu du rapport
    final buffer = StringBuffer();
    
    // En-tête
    buffer.writeln('=' * 32);
    buffer.writeln('    RAPPORT DE VENTES');
    buffer.writeln('=' * 32);
    buffer.writeln();
    
    // Période
    buffer.writeln('Période:');
    buffer.writeln('Du: ${_formatDate(startDate)}');
    buffer.writeln('Au: ${_formatDate(endDate)}');
    buffer.writeln();
    
    // Statistiques générales
    buffer.writeln('RÉSUMÉ:');
    buffer.writeln('-' * 20);
    buffer.writeln('Total des ventes: ${_formatCurrency(totalSales)}');
    buffer.writeln('Nombre de ventes: $salesCount');
    buffer.writeln('Vente moyenne: ${_formatCurrency(averageSale)}');
    buffer.writeln();
    
    // Méthodes de paiement
    buffer.writeln('MÉTHODES DE PAIEMENT:');
    buffer.writeln('-' * 20);
    paymentMethods.forEach((method, count) {
      buffer.writeln('${method.toUpperCase()}: $count ventes');
    });
    buffer.writeln();
    
    // Mouvements de caisse
    if (salesMovements.isNotEmpty) {
      buffer.writeln('MOUVEMENTS DE CAISSE:');
      buffer.writeln('-' * 20);
      buffer.writeln('Ventes: ${_formatCurrency(salesMovements.fold(0.0, (sum, m) => sum + m.amount))}');
    }
    
    if (manualMovements.isNotEmpty) {
      final manualIn = manualMovements.where((m) => m.type == 'manual_in').fold(0.0, (sum, m) => sum + m.amount);
      final manualOut = manualMovements.where((m) => m.type == 'manual_out').fold(0.0, (sum, m) => sum + m.amount);
      buffer.writeln('Entrées manuelles: ${_formatCurrency(manualIn)}');
      buffer.writeln('Sorties manuelles: ${_formatCurrency(manualOut)}');
    }
    buffer.writeln();
    
    // Détail des ventes
    if (sales.isNotEmpty) {
      buffer.writeln('DÉTAIL DES VENTES:');
      buffer.writeln('-' * 20);
      for (final sale in sales) {
        buffer.writeln('${_formatDateTime(sale.createdAt)} - ${_formatCurrency(sale.total)} (${sale.paymentMethod.toUpperCase()})');
        if (sale.customerId != null) {
          buffer.writeln('  Client: ${sale.customerId}');
        }
        buffer.writeln();
      }
    }
    
    buffer.writeln('=' * 32);
    buffer.writeln('Fin du rapport');
    buffer.writeln('=' * 32);
    
    return buffer.toString();
  }

  /// Générer un PDF de rapport de ventes
  Future<Uint8List> generateSalesReportPdf(DateTime startDate, DateTime endDate) async {
    try {
      final reportContent = generateSalesReport(startDate, endDate);
      // Convertir le texte en PDF
      return await _generatePdfFromText(reportContent, 'Rapport de ventes');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Imprimer un rapport de ventes (déprécié - utilisez generateSalesReportPdf)
  @Deprecated('Use generateSalesReportPdf() and navigate to PdfPreviewPage instead')
  Future<void> printSalesReport(DateTime startDate, DateTime endDate) async {
    try {
      final reportContent = generateSalesReport(startDate, endDate);
      await _printerService.print(reportContent);
    } catch (e) {
      throw Exception('Erreur lors de l\'impression du rapport: $e');
    }
  }

  /// Générer un rapport de caisse (Z-report)
  String generateCashRegisterReport(String cashRegisterId) {
    final sales = _storageService.getSales();
    final cashMovements = _storageService.getCashMovementsByRegister(cashRegisterId);
    
    // Filtrer les ventes de cette caisse
    final registerSales = sales.where((sale) => sale.cashRegisterId == cashRegisterId).toList();
    
    final totalSales = registerSales.fold(0.0, (sum, sale) => sum + sale.total);
    final salesCount = registerSales.length;
    
    // Calculer les totaux par méthode de paiement
    final paymentTotals = <String, double>{};
    for (final sale in registerSales) {
      paymentTotals[sale.paymentMethod] = (paymentTotals[sale.paymentMethod] ?? 0.0) + sale.total;
    }
    
    // Calculer les mouvements de caisse
    final salesMovements = cashMovements.where((m) => m.type == 'sale').fold(0.0, (sum, m) => sum + m.amount);
    final manualIn = cashMovements.where((m) => m.type == 'manual_in').fold(0.0, (sum, m) => sum + m.amount);
    final manualOut = cashMovements.where((m) => m.type == 'manual_out').fold(0.0, (sum, m) => sum + m.amount);
    
    final buffer = StringBuffer();
    
    // En-tête Z-Report
    buffer.writeln('=' * 32);
    buffer.writeln('        Z-REPORT');
    buffer.writeln('=' * 32);
    buffer.writeln();
    buffer.writeln('Caisse: $cashRegisterId');
    buffer.writeln('Date: ${_formatDateTime(DateTime.now())}');
    buffer.writeln();
    
    // Résumé des ventes
    buffer.writeln('RÉSUMÉ DES VENTES:');
    buffer.writeln('-' * 20);
    buffer.writeln('Total des ventes: ${_formatCurrency(totalSales)}');
    buffer.writeln('Nombre de ventes: $salesCount');
    buffer.writeln();
    
    // Détail par méthode de paiement
    buffer.writeln('PAR MÉTHODE DE PAIEMENT:');
    buffer.writeln('-' * 20);
    paymentTotals.forEach((method, total) {
      buffer.writeln('${method.toUpperCase()}: ${_formatCurrency(total)}');
    });
    buffer.writeln();
    
    // Mouvements de caisse
    buffer.writeln('MOUVEMENTS DE CAISSE:');
    buffer.writeln('-' * 20);
    buffer.writeln('Ventes: ${_formatCurrency(salesMovements)}');
    buffer.writeln('Entrées manuelles: ${_formatCurrency(manualIn)}');
    buffer.writeln('Sorties manuelles: ${_formatCurrency(manualOut)}');
    buffer.writeln();
    
    // Solde théorique
    final theoreticalBalance = salesMovements + manualIn - manualOut;
    buffer.writeln('SOLDE THÉORIQUE:');
    buffer.writeln('-' * 20);
    buffer.writeln('${_formatCurrency(theoreticalBalance)}');
    buffer.writeln();
    
    buffer.writeln('=' * 32);
    buffer.writeln('Fin du Z-Report');
    buffer.writeln('=' * 32);
    
    return buffer.toString();
  }

  /// Générer un PDF de Z-Report
  Future<Uint8List> generateCashRegisterReportPdf(String cashRegisterId) async {
    try {
      final reportContent = generateCashRegisterReport(cashRegisterId);
      // Convertir le texte en PDF
      return await _generatePdfFromText(reportContent, 'Z-Report');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Imprimer un Z-Report (déprécié - utilisez generateCashRegisterReportPdf)
  @Deprecated('Use generateCashRegisterReportPdf() and navigate to PdfPreviewPage instead')
  Future<void> printCashRegisterReport(String cashRegisterId) async {
    try {
      final reportContent = generateCashRegisterReport(cashRegisterId);
      await _printerService.print(reportContent);
    } catch (e) {
      throw Exception('Erreur lors de l\'impression du Z-Report: $e');
    }
  }

  /// Générer un PDF à partir d'un texte
  Future<Uint8List> _generatePdfFromText(String text, String title) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Titre
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              // Contenu (formaté en texte simple, préserver le formatage avec des espaces)
              pw.Text(
                text,
                style: const pw.TextStyle(
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Exporter les ventes pour comptabilisation (CSV)
  String exportSalesForAccounting(DateTime startDate, DateTime endDate) {
    final sales = _storageService.getSalesByDateRange(startDate, endDate);
    
    final buffer = StringBuffer();
    
    // En-tête CSV
    buffer.writeln('Date,Heure,ID_Vente,Client,Méthode_Paiement,Total,TVA,Articles');
    
    // Données des ventes
    for (final sale in sales) {
      final date = _formatDate(sale.createdAt);
      final time = _formatTime(sale.createdAt);
      final customer = sale.customerId ?? '';
      final items = sale.items.map((item) => '${item.productName}x${item.quantity}').join(';');
      
      buffer.writeln('$date,$time,${sale.id},$customer,${sale.paymentMethod},${sale.total},${sale.taxAmount},$items');
    }
    
    return buffer.toString();
  }

  /// Exporter les mouvements de caisse pour comptabilisation
  String exportCashMovementsForAccounting(DateTime startDate, DateTime endDate) {
    final movements = _storageService.getCashMovements();
    
    // Filtrer pour la période
    final periodMovements = movements.where((movement) {
      return movement.createdAt.isAfter(startDate) && 
             movement.createdAt.isBefore(endDate);
    }).toList();
    
    final buffer = StringBuffer();
    
    // En-tête CSV
    buffer.writeln('Date,Heure,Type,Montant,Description,Caisse_ID,Vente_ID');
    
    // Données des mouvements
    for (final movement in periodMovements) {
      final date = _formatDate(movement.createdAt);
      final time = _formatTime(movement.createdAt);
      final description = movement.description ?? '';
      final saleId = movement.saleId ?? '';
      
      buffer.writeln('$date,$time,${movement.type},${movement.amount},$description,${movement.cashRegisterId},$saleId');
    }
    
    return buffer.toString();
  }

  /// Obtenir les statistiques de comptabilisation
  Map<String, dynamic> getAccountingStats(DateTime startDate, DateTime endDate) {
    final sales = _storageService.getSalesByDateRange(startDate, endDate);
    final movements = _storageService.getCashMovements();
    
    // Filtrer les mouvements pour la période
    final periodMovements = movements.where((movement) {
      return movement.createdAt.isAfter(startDate) && 
             movement.createdAt.isBefore(endDate);
    }).toList();
    
    final totalSales = sales.fold(0.0, (sum, sale) => sum + sale.total);
    final totalTax = sales.fold(0.0, (sum, sale) => sum + sale.taxAmount);
    final totalCashIn = periodMovements
        .where((m) => m.type == 'sale' || m.type == 'manual_in')
        .fold(0.0, (sum, m) => sum + m.amount);
    final totalCashOut = periodMovements
        .where((m) => m.type == 'manual_out')
        .fold(0.0, (sum, m) => sum + m.amount);
    
    return {
      'period': {
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
      },
      'sales': {
        'count': sales.length,
        'total': totalSales,
        'tax': totalTax,
        'net': totalSales - totalTax,
      },
      'cash_flow': {
        'in': totalCashIn,
        'out': totalCashOut,
        'net': totalCashIn - totalCashOut,
      },
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  // Méthodes utilitaires
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm:ss').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }
}

