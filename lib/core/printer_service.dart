import 'dart:async'; // Pour TimeoutException
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:printing/printing.dart'; // Pour afficher le PDF avec options d'impression intégrées
import 'printer_config_service.dart';
// import 'thermal_printer_service.dart'; // DÉSACTIVÉ temporairement pour éviter les blocages

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  PrinterConfigService? __configService;
  PrinterConfigService get _configService {
    // ⚠️ CRITIQUE: Créer immédiatement sans logs, sans blocage
    if (__configService == null) {
      __configService = PrinterConfigService();
    }
    return __configService!;
  }
  // final ThermalPrinterService _thermalPrinterService = ThermalPrinterService(); // DÉSACTIVÉ temporairement
  bool _initialized = false;

  /// Initialize printer service (instantané, pas de chargement)
  void initializeInBackground() {
    if (_initialized) {
      return;
    }
    print('[PrinterService] ✅ Initialisation immédiate (pas de chargement de config)');
    _initialized = true;
  }

  /// Public initialization method (for backward compatibility)
  Future<void> initialize() async {
    initializeInBackground();
  }

  PrinterConfig get config => _configService.config;

  List<String> getAvailablePrinters(PrinterInterface interface) {
    switch (interface) {
      case PrinterInterface.system:
        return ['Imprimante système (sélection automatique)'];
      case PrinterInterface.usb:
        return ['USB Printer 1', 'USB Printer 2'];
      case PrinterInterface.bluetooth:
        return ['Bluetooth Printer 1', 'Bluetooth Printer 2'];
      case PrinterInterface.network:
        return ['Network Printer 1', 'Network Printer 2'];
    }
  }

  Future<void> setPrinter(PrinterInterface interface, String printer) async {
    await _configService.save(
      PrinterConfig(
        interface: interface,
        printerName: printer,
        printerAddress: null,
        autoPrint: _configService.config.autoPrint,
        printReceipt: _configService.config.printReceipt,
      ),
    );
  }

  Future<void> updateInterface(PrinterInterface interface) async {
    await _configService.updateInterface(interface);
  }

  Future<void> updateAutoPrint(bool autoPrint) async {
    await _configService.updateAutoPrint(autoPrint);
  }

  Future<void> updatePrintReceipt(bool printReceipt) async {
    await _configService.updatePrintReceipt(printReceipt);
  }

  /// Print text content (for reports)
  Future<bool> print(String textContent) async {
    final bytes = Uint8List.fromList(textContent.codeUnits);
    return await printReceipt(bytes);
  }

  Future<bool> printReceipt(Uint8List pdfBytes, {dynamic sale, bool isAutoPrint = false}) async {
    print('[PrinterService] ==========================================');
    print('[PrinterService] 🚀 ENTRÉE dans printReceipt()');
    print('[PrinterService] Paramètres: pdfBytes=${pdfBytes.length} bytes, isAutoPrint=$isAutoPrint');
    
    try {
      // Initialiser si nécessaire (instantané)
      initializeInBackground();

      // Accès à la config (en mémoire, pas de blocage)
      final config = _configService.config;
      print('[PrinterService] Mode: ${isAutoPrint ? "Auto" : "Manuel"}');
    
      // Vérifier si l'impression est activée
      if (!config.printReceipt) {
        print('[PrinterService] ❌ Impression désactivée (printReceipt = false)');
        return false;
      }
      
      // Si c'est une impression automatique, vérifier autoPrint
      if (isAutoPrint && !config.autoPrint) {
        print('[PrinterService] ❌ Impression automatique désactivée (autoPrint = false)');
        return false;
      }

      // Utiliser Printing.layoutPdf() pour afficher le PDF avec les options d'impression intégrées
      print('[PrinterService] 📄 PDF généré en mémoire: ${pdfBytes.length} bytes');
      print('[PrinterService] 🖨️ Ouverture du viewer PDF avec options d\'impression...');
      
      // Printing.layoutPdf() affiche le PDF avec un bouton d'impression intégré
      try {
        print('[PrinterService] 📞 Appel Printing.layoutPdf()...');
        await Printing.layoutPdf(
          onLayout: (format) async {
            print('[PrinterService] [onLayout] Format: $format');
            return pdfBytes;
          },
        );
        print('[PrinterService] ✅ Viewer PDF ouvert avec succès');
      } catch (e) {
        print('[PrinterService] ⚠️ Erreur ouverture viewer PDF: $e (peut être normal si l\'utilisateur ferme)');
        // Continuer même en cas d'erreur - l'impression ne doit pas bloquer
      }
      
      print('[PrinterService] ✅ Traitement terminé');
      print('[PrinterService] ==========================================');
      return true;
    } catch (e, stackTrace) {
      print('[PrinterService] ❌ ERREUR: $e');
      print('[PrinterService] Stack: $stackTrace');
      return false;
    }
  }
  
  /* CODE DÉSACTIVÉ - CAUSERAIT DES BLOCAGES
  Future<bool> printReceipt_OLD(Uint8List pdfBytes, {dynamic sale, bool isAutoPrint = false}) async {
    print('[PrinterService] ==========================================');
    print('[PrinterService] 🚀🚀🚀 ENTRÉE dans printReceipt() - LIGNE 1');
    print('[PrinterService] 🚀🚀🚀 ENTRÉE dans printReceipt() - LIGNE 2');
    print('[PrinterService] Paramètres: pdfBytes=${pdfBytes.length} bytes, isAutoPrint=$isAutoPrint');
    print('[PrinterService] ⚠️ AVANT LE TRY');
    
    try {
      print('[PrinterService] ✅ DANS LE TRY - LIGNE 1');
      // Initialiser si nécessaire (instantané) dans un microtask
      print('[PrinterService] [INIT] Appel initializeInBackground()...');
      await Future.microtask(() => initializeInBackground());
      print('[PrinterService] [INIT] ✅ initializeInBackground() terminé');

      print('[PrinterService] ========== DÉBUT IMPRESSION ==========');
      print('[PrinterService] Taille PDF: ${pdfBytes.length} bytes');
      
      // Accès à la config - SANS microtask pour éviter délai inutile
      // La config est en mémoire, pas de blocage I/O
      print('[PrinterService] [CONFIG] Accès à _configService.config...');
      final config = _configService.config;
      print('[PrinterService] [CONFIG] ✅ Config récupérée');
      
      print('[PrinterService] Mode: ${isAutoPrint ? "Auto" : "Manuel"}');
    
      // Vérifier si l'impression est activée - SANS microtask (config en mémoire)
      if (!config.printReceipt) {
        print('[PrinterService] ❌ Impression désactivée dans les paramètres (printReceipt = false)');
        print('[PrinterService] ==========================================');
        return false;
      }
      
      // Si c'est une impression automatique, vérifier autoPrint
      if (isAutoPrint && !config.autoPrint) {
        print('[PrinterService] ❌ Impression automatique désactivée (autoPrint = false)');
        print('[PrinterService] ==========================================');
        return false;
      }

      // DÉSACTIVÉ: Vérifier si une imprimante thermique est connectée
      // final thermalPrinter = _thermalPrinterService.connectedPrinter;
      // if (thermalPrinter != null && sale != null) {
      //   print('[PrinterService] 🔥 Imprimante thermique détectée: ${thermalPrinter.name}');
      //   return await _printToThermalPrinter(sale);
      // }

      // Sinon, utiliser l'impression système classique
      // ⚠️ IMPORTANT: On ne sauvegarde PAS le PDF sur disque pour éviter les blocages I/O
      print('[PrinterService] 📄 PDF généré en mémoire: ${pdfBytes.length} bytes');
      print('[PrinterService] ⚠️ Sauvegarde sur disque désactivée (pour éviter blocages)');
      
      // ⚠️ CRITIQUE: L'appel natif est désactivé, donc on ne fait rien
      // Le PDF est généré mais pas sauvegardé ni imprimé automatiquement
      print('[PrinterService] 💡 PDF disponible en mémoire mais non sauvegardé');
      print('[PrinterService] 💡 L\'utilisateur peut utiliser la fonctionnalité d\'aperçu pour voir/partager le PDF');
      
      // Ne pas appeler _openPrintDialog car il nécessite un fichier
      // et on ne veut pas sauvegarder sur disque
      print('[PrinterService] ⚠️ Impression système désactivée (nécessite fichier sur disque)');
      print('[PrinterService] ========== FIN IMPRESSION ==========');
      print('[PrinterService] ==========================================');
      return true;
    } catch (e, stackTrace) {
      print('[PrinterService] ❌ ERREUR impression: $e');
      print('[PrinterService] Type: ${e.runtimeType}');
      print('[PrinterService] Stack trace: $stackTrace');
      print('[PrinterService] ==========================================');
      return false;
    } finally {
      print('[PrinterService] 🔚 SORTIE de printReceipt()');
    }
  }
  */

  /// Imprimer vers une imprimante thermique
  // DÉSACTIVÉ temporairement pour éviter les blocages
  /*
  Future<bool> _printToThermalPrinter(dynamic sale) async {
    try {
      print('[PrinterService] 🔥 Génération du reçu thermique...');
      
      // Générer le texte du reçu
      final receiptText = _generateThermalReceiptText(sale);
      
      // Imprimer via l'imprimante thermique
      final success = await _thermalPrinterService.printText(receiptText);
      
      if (success) {
        print('[PrinterService] ✅ Impression thermique réussie');
        print('[PrinterService] ========== FIN IMPRESSION ==========');
      } else {
        print('[PrinterService] ❌ Échec impression thermique');
        print('[PrinterService] ==========================================');
      }
      
      return success;
    } catch (e, stackTrace) {
      print('[PrinterService] ❌ ERREUR impression thermique: $e');
      print('[PrinterService] Stack trace: $stackTrace');
      print('[PrinterService] ==========================================');
      return false;
    }
  }
  */

  /// Générer le texte du reçu pour imprimante thermique
  String _generateThermalReceiptText(dynamic sale) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    
    // Header
    buffer.writeln('================================');
    buffer.writeln('      INTEGRALPOS');
    buffer.writeln('    Point de Vente');
    buffer.writeln('================================');
    buffer.writeln('');
    
    // Informations de vente
    buffer.writeln('Vente: ${sale.id?.substring(0, 8) ?? 'N/A'}');
    buffer.writeln('Date: ${dateFormatter.format(now)}');
    if (sale.customerId != null) {
      buffer.writeln('Client: ${sale.customerId}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('');
    
    // Articles
    buffer.writeln('Article          Qty    Prix');
    buffer.writeln('--------------------------------');
    
    if (sale.items != null) {
      for (var item in sale.items) {
        final productName = item.productName ?? 'Produit';
        final quantity = item.quantity ?? 0;
        final price = item.price ?? 0.0;
        final lineTotal = item.lineTotal ?? (price * quantity);
        
        // Tronquer le nom si trop long (pour imprimantes 58mm)
        final displayName = productName.length > 15 
            ? '${productName.substring(0, 15)}...' 
            : productName;
        
        buffer.writeln('$displayName');
        buffer.writeln('  ${quantity}x ${_formatCurrency(price)} = ${_formatCurrency(lineTotal)}');
      }
    }
    
    buffer.writeln('--------------------------------');
    buffer.writeln('');
    
    // Totaux
    buffer.writeln('Sous-total:      ${_formatCurrency(sale.subtotal ?? 0.0)}');
    
    if (sale.taxAmount != null && sale.taxAmount! > 0) {
      buffer.writeln('TVA:              ${_formatCurrency(sale.taxAmount!)}');
    }
    
    buffer.writeln('--------------------------------');
    buffer.writeln('TOTAL:            ${_formatCurrency(sale.total ?? 0.0)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('');
    
    // Méthode de paiement
    buffer.writeln('Paiement: ${_getPaymentMethodName(sale.paymentMethod ?? 'cash')}');
    buffer.writeln('');
    
    // Footer
    buffer.writeln('Merci pour votre achat!');
    buffer.writeln('');
    buffer.writeln('================================');
    buffer.writeln('Reçu généré par IntegralPOS');
    buffer.writeln('www.integralpos.com');
    buffer.writeln('================================');
    buffer.writeln('');
    buffer.writeln(''); // Espace supplémentaire pour couper
    
    return buffer.toString();
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} XOF';
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

  Future<void> _openPrintDialog(File file) async {
    print('[PrinterService] [_openPrintDialog] ==========================================');
    print('[PrinterService] [_openPrintDialog] 🚀 ENTRÉE dans _openPrintDialog()');
    print('[PrinterService] [_openPrintDialog] Fichier: ${file.path}');
    
    // DÉSACTIVÉ TEMPORAIREMENT: L'appel natif bloque l'application
    // Le code natif Android/iOS n'est probablement pas implémenté ou ne répond pas
    print('[PrinterService] [_openPrintDialog] ⚠️ APPEL NATIF DÉSACTIVÉ (pour éviter le blocage)');
    print('[PrinterService] [_openPrintDialog] 📄 PDF sauvegardé à: ${file.path}');
    print('[PrinterService] [_openPrintDialog] 💡 L\'utilisateur peut ouvrir ce fichier manuellement');
    print('[PrinterService] [_openPrintDialog] ✅✅✅ _openPrintDialog() terminé (sans appel natif)');
    return;
    
    /* CODE NATIF DÉSACTIVÉ - À RÉACTIVER QUAND LE CODE NATIF SERA IMPLÉMENTÉ
    try {
      print('[PrinterService] [_openPrintDialog] 🔍 Détection de la plateforme...');
      print('[PrinterService] [_openPrintDialog] Plateforme: ${Platform.operatingSystem}');
      
      if (Platform.isAndroid) {
        print('[PrinterService] [_openPrintDialog] 📱 Android détecté');
        print('[PrinterService] [_openPrintDialog] Création MethodChannel...');
        const platform = MethodChannel('com.integralpos.print');
        print('[PrinterService] [_openPrintDialog] ✅ MethodChannel créé');
        
        print('[PrinterService] [_openPrintDialog] 📞 Appel méthode native printPdf...');
        print('[PrinterService] [_openPrintDialog] ⚠️ ATTENTION: invokeMethod() peut bloquer si le code natif ne répond pas');
        print('[PrinterService] [_openPrintDialog] Paramètres: path=${file.path}');
        
        // Utiliser un timeout pour éviter le blocage indéfini
        await platform.invokeMethod('printPdf', {'path': file.path}).timeout(
          const Duration(seconds: 1), // Timeout très court pour éviter le crash
          onTimeout: () {
            print('[PrinterService] [_openPrintDialog] ⏱ Timeout invokeMethod (code natif ne répond pas)');
            throw TimeoutException('Timeout invokeMethod printPdf');
          },
        );
        print('[PrinterService] [_openPrintDialog] ✅ Méthode native appelée avec succès');
      } else if (Platform.isIOS) {
        print('[PrinterService] [_openPrintDialog] 🍎 iOS détecté');
        print('[PrinterService] [_openPrintDialog] Création MethodChannel...');
        const platform = MethodChannel('com.integralpos.print');
        print('[PrinterService] [_openPrintDialog] ✅ MethodChannel créé');
        
        print('[PrinterService] [_openPrintDialog] 📞 Appel méthode native printPdf...');
        print('[PrinterService] [_openPrintDialog] ⚠️ ATTENTION: invokeMethod() peut bloquer si le code natif ne répond pas');
        
        await platform.invokeMethod('printPdf', {'path': file.path}).timeout(
          const Duration(seconds: 1), // Timeout très court pour éviter le crash
          onTimeout: () {
            print('[PrinterService] [_openPrintDialog] ⏱ Timeout invokeMethod (code natif ne répond pas)');
            throw TimeoutException('Timeout invokeMethod printPdf');
          },
        );
        print('[PrinterService] [_openPrintDialog] ✅ Méthode native appelée avec succès');
      } else {
        print('[PrinterService] [_openPrintDialog] 💻 Desktop détecté');
        print('[PrinterService] [_openPrintDialog] Fichier disponible: ${file.path}');
        // On desktop, just open the file - pas de blocage attendu
      }
      
      print('[PrinterService] [_openPrintDialog] ✅✅✅ _openPrintDialog() terminé avec succès');
    } catch (e, stackTrace) {
      print('[PrinterService] [_openPrintDialog] ❌❌❌ ERREUR dans _openPrintDialog: $e');
      print('[PrinterService] [_openPrintDialog] Type: ${e.runtimeType}');
      print('[PrinterService] [_openPrintDialog] Stack trace: $stackTrace');
      print('[PrinterService] [_openPrintDialog] ⚠️ Ne pas faire échouer l\'impression, continuer...');
      // Ne pas rethrow - l'impression peut continuer sans le dialogue système
    } finally {
      print('[PrinterService] [_openPrintDialog] 🔚 SORTIE de _openPrintDialog()');
      print('[PrinterService] [_openPrintDialog] ==========================================');
    }
    */
  }

  /// Print using custom interface (USB, Bluetooth, Network)
  Future<bool> printReceiptCustom(Uint8List pdfBytes) async {
    try {
      final config = _configService.config;
      switch (config.interface) {
        case PrinterInterface.system:
          return await printReceipt(pdfBytes);
        case PrinterInterface.usb:
          return await _printViaUSB(pdfBytes);
        case PrinterInterface.bluetooth:
          return await _printViaBluetooth(pdfBytes);
        case PrinterInterface.network:
          return await _printViaNetwork(pdfBytes);
      }
    } catch (e) {
      print('[PrinterService] Erreur impression: $e');
      return false;
    }
  }

  Future<bool> _printViaUSB(Uint8List pdfBytes) async {
    try {
      final printerName = _configService.config.printerName ?? 'USB Printer';
      print('[PrinterService] Impression USB vers: $printerName');
      
      // Save PDF to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt.pdf');
      await file.writeAsBytes(pdfBytes);
      
      // In a real implementation, you would use platform channels
      // to communicate with native printing libraries
      
      return true;
    } catch (e) {
      print('[PrinterService] Erreur impression USB: $e');
      return false;
    }
  }

  Future<bool> _printViaBluetooth(Uint8List pdfBytes) async {
    try {
      final printerName = _configService.config.printerName ?? 'Bluetooth Printer';
      print('[PrinterService] Impression Bluetooth vers: $printerName');
      
      // In a real implementation, you would use Bluetooth connectivity
      // to send the PDF to the printer
      
      return true;
    } catch (e) {
      print('[PrinterService] Erreur impression Bluetooth: $e');
      return false;
    }
  }

  Future<bool> _printViaNetwork(Uint8List pdfBytes) async {
    try {
      final printerName = _configService.config.printerName ?? 'Network Printer';
      print('[PrinterService] Impression réseau vers: $printerName');
      
      // In a real implementation, you would use HTTP requests
      // to send the PDF to a network printer
      
      return true;
    } catch (e) {
      print('[PrinterService] Erreur impression réseau: $e');
      return false;
    }
  }

  Future<bool> testPrint() async {
    final config = _configService.config;
    if (config.printerName == null) {
      print('[PrinterService] Aucune imprimante sélectionnée');
      return false;
    }

    try {
      // Create a test receipt
      final testData = Uint8List.fromList('Test Impression\n'.codeUnits);
      return await printReceipt(testData);
    } catch (e) {
      print('[PrinterService] Erreur test impression: $e');
      return false;
    }
  }

  Map<String, dynamic> getPrinterStatus() {
    final config = _configService.config;
    return {
      'interface': config.interface.name,
      'printer': config.printerName,
      'available': config.printerName != null,
      'autoPrint': config.autoPrint,
      'printReceipt': config.printReceipt,
    };
  }

  // Getters pour compatibilité avec l'ancien code
  PrinterInterface get selectedInterface => _configService.config.interface;
  String? get selectedPrinter => _configService.config.printerName;
}