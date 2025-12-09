import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../widgets/pdf_preview_page.dart';
import 'package:flutter/foundation.dart'; // Pour compute()
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
// import 'package:flutter_thermal_printer/utils/printer.dart';
import '../../../core/printer_service.dart';
import '../../../core/printer_config_service.dart';
import '../../../core/company_warehouse_service.dart';
// import '../../../core/thermal_printer_service.dart';
import '../../../widgets/main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterConfigPage extends ConsumerStatefulWidget {
  const PrinterConfigPage({super.key});

  @override
  ConsumerState<PrinterConfigPage> createState() => _PrinterConfigPageState();
}

class _PrinterConfigPageState extends ConsumerState<PrinterConfigPage> {
  PrinterService? _printerService;

  bool _isTesting = false;
  bool _printerServiceEnabled = false;

  // Stockage local simplifié pour l'imprimante configurée
  String? _savedPrinterName;
  String? _savedPrinterAddress;
  String? _savedPrinterType; // 'BLE', 'USB', 'NETWORK'

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedType = 'BLE';

  @override
  void initState() {
    super.initState();
    // Charger en arrière-plan pour ne pas bloquer l'UI
    Future.microtask(() => _loadSavedPrinter());
  }

  Future<void> _loadSavedPrinter() async {
    try {
      // Timeout pour éviter les blocages
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 2), onTimeout: () {
        print('[PrinterConfigPage] ⏱ Timeout SharedPreferences');
        throw TimeoutException('Timeout chargement SharedPreferences');
      });
      
      if (!mounted) return;
      
      setState(() {
        _savedPrinterName = prefs.getString('printer_name');
        _savedPrinterAddress = prefs.getString('printer_address');
        _savedPrinterType = prefs.getString('printer_type') ?? 'BLE';
        _printerServiceEnabled = prefs.getBool('printer_service_enabled') ?? false;

        if (_savedPrinterName != null) {
          _nameController.text = _savedPrinterName!;
        }
        if (_savedPrinterAddress != null) {
          _addressController.text = _savedPrinterAddress!;
        }
        _selectedType = _savedPrinterType ?? 'BLE';
      });
    } catch (e) {
      print('[PrinterConfigPage] Erreur chargement: $e');
      // Ne pas bloquer même en cas d'erreur
    }
  }

  Future<void> _savePrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_name', _nameController.text.trim());
      await prefs.setString('printer_address', _addressController.text.trim());
      await prefs.setString('printer_type', _selectedType);

      setState(() {
        _savedPrinterName = _nameController.text.trim();
        _savedPrinterAddress = _addressController.text.trim();
        _savedPrinterType = _selectedType;
      });

      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imprimante enregistrée',
            style: theme.typography.base.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l\'enregistrement: $e',
            style: theme.typography.base.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colors.destructive,
        ),
      );
    }
  }

  Future<void> _clearPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('printer_name');
      await prefs.remove('printer_address');
      await prefs.remove('printer_type');

      setState(() {
        _savedPrinterName = null;
        _savedPrinterAddress = null;
        _savedPrinterType = 'BLE';
        _nameController.clear();
        _addressController.clear();
        _selectedType = 'BLE';
      });

      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imprimante supprimée',
            style: theme.typography.base.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: $e',
            style: theme.typography.base.copyWith(color: Colors.white),
          ),
          backgroundColor: theme.colors.destructive,
        ),
      );
    }
  }

  PrinterService? _getPrinterService() {
    // ⚠️ DÉSACTIVÉ TEMPORAIREMENT - Évite les blocages
    print('[PrinterConfigPage] ⚠️ _getPrinterService() désactivé (évite blocages)');
    return null;
    
    /* CODE DÉSACTIVÉ
    try {
      _printerService ??= PrinterService();
      return _printerService!;
    } catch (e) {
      print('[PrinterConfigPage] Erreur création PrinterService: $e');
      // Créer un nouveau service même en cas d'erreur
      _printerService = PrinterService();
      return _printerService!;
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return MainLayout(
      currentRoute: '/printer-config',
      appBar: AppBar(
        title: const Text('Configuration des Imprimantes'),
        backgroundColor: theme.colors.background,
        foregroundColor: theme.colors.foreground,
        elevation: 0,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activer/Désactiver le service d'impression
            FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          color: theme.colors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Service d\'impression',
                          style: theme.typography.lg.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Activer le service d\'impression'),
                      subtitle: const Text('Activer pour utiliser les imprimantes'),
                      value: _printerServiceEnabled,
                      onChanged: (value) {
                        // Mettre à jour l'état immédiatement (non-bloquant)
                        setState(() {
                          _printerServiceEnabled = value;
                        });
                        
                        // Sauvegarder en arrière-plan (non-bloquant)
                        Future.microtask(() async {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('printer_service_enabled', value);
                            // ⚠️ DÉSACTIVÉ - Évite les blocages
                            print('[PrinterConfigPage] ⚠️ Initialisation PrinterService désactivée');
                            /* CODE DÉSACTIVÉ
                            if (value) {
                              // Initialiser en arrière-plan aussi
                              try {
                                final service = _getPrinterService();
                                if (service != null) {
                                  service.initializeInBackground();
                                }
                              } catch (e) {
                                print('[PrinterConfigPage] Erreur init service: $e');
                              }
                            }
                            */
                          } catch (e) {
                            print('[PrinterConfigPage] Erreur sauvegarde toggle: $e');
                            // En cas d'erreur, revenir à l'état précédent
                            if (mounted) {
                              setState(() {
                                _printerServiceEnabled = !value;
                              });
                            }
                          }
                        });
                      },
                      activeThumbColor: theme.colors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Configuration manuelle de l'imprimante
            if (_printerServiceEnabled) ...[
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.print,
                            color: theme.colors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration de l\'imprimante',
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FTextField(
                        controller: _nameController,
                        hint: 'Nom de l\'imprimante',
                        label: const Text('Nom'),
                      ),
                      const SizedBox(height: 16),
                      FTextField(
                        controller: _addressController,
                        hint: 'Adresse (MAC, IP, ou chemin USB)',
                        label: const Text('Adresse'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type de connexion',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'BLE',
                            child: Row(
                              children: [
                                Icon(Icons.bluetooth, size: 20),
                                SizedBox(width: 8),
                                Text('Bluetooth (BLE)'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'USB',
                            child: Row(
                              children: [
                                Icon(Icons.usb, size: 20),
                                SizedBox(width: 8),
                                Text('USB'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'NETWORK',
                            child: Row(
                              children: [
                                Icon(Icons.wifi, size: 20),
                                SizedBox(width: 8),
                                Text('WiFi'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FButton(
                              onPress: _savePrinter,
                              child: const Text('Enregistrer'),
                            ),
                          ),
                          if (_savedPrinterName != null) ...[
                            const SizedBox(width: 8),
                            FButton(
                              onPress: _clearPrinter,
                              style: FButtonStyle.outline(),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Imprimante enregistrée
              if (_savedPrinterName != null)
                FCard.raw(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Imprimante configurée',
                              style: theme.typography.lg.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Nom', _savedPrinterName ?? 'N/A', theme),
                        _buildInfoRow(
                          'Type',
                          _savedPrinterType == 'BLE'
                              ? 'Bluetooth (BLE)'
                              : _savedPrinterType == 'USB'
                                  ? 'USB'
                                  : 'WiFi',
                          theme,
                        ),
                        if (_savedPrinterAddress != null)
                          _buildInfoRow('Adresse', _savedPrinterAddress!, theme),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Paramètres d'impression
              _buildSettings(theme),

              // Test d'impression
              const SizedBox(height: 24),
              _buildTestPrint(theme),
            ] else ...[
              FCard.raw(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colors.mutedForeground,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Activez le service d\'impression ci-dessus pour configurer une imprimante',
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, FThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.typography.base,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(FThemeData theme) {
    // Utiliser try-catch pour éviter les blocages
    // ⚠️ DÉSACTIVÉ - Évite les blocages
    Map<String, dynamic> status = {'autoPrint': false, 'printReceipt': true};
    print('[PrinterConfigPage] ⚠️ getPrinterStatus() désactivé, valeurs par défaut utilisées');
    /* CODE DÉSACTIVÉ
    try {
      final service = _getPrinterService();
      if (service != null) {
        status = service.getPrinterStatus();
      } else {
        status = {'autoPrint': false, 'printReceipt': true};
      }
    } catch (e) {
      print('[PrinterConfigPage] Erreur getPrinterStatus: $e');
      status = {'autoPrint': false, 'printReceipt': true};
    }
    */
    final autoPrint = status['autoPrint'] as bool? ?? false;
    final printReceipt = status['printReceipt'] as bool? ?? true;

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres d\'impression',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Impression automatique'),
              subtitle: const Text('Imprimer automatiquement après chaque vente'),
              value: autoPrint,
              onChanged: (value) {
                // Mettre à jour immédiatement
                setState(() {});
                // ⚠️ DÉSACTIVÉ - Évite les blocages
                print('[PrinterConfigPage] ⚠️ updateAutoPrint() désactivé');
                /* CODE DÉSACTIVÉ
                Future.microtask(() async {
                  try {
                    final service = _getPrinterService();
                    if (service != null) {
                      await service.updateAutoPrint(value);
                    }
                    if (mounted) setState(() {});
                  } catch (e) {
                    print('[PrinterConfigPage] Erreur updateAutoPrint: $e');
                  }
                });
                */
              },
              activeThumbColor: theme.colors.primary,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Imprimer les tickets'),
              subtitle: const Text('Activer l\'impression des reçus'),
              value: printReceipt,
              onChanged: (value) {
                // Mettre à jour immédiatement
                setState(() {});
                // ⚠️ DÉSACTIVÉ - Évite les blocages
                print('[PrinterConfigPage] ⚠️ updatePrintReceipt() désactivé');
                /* CODE DÉSACTIVÉ
                Future.microtask(() async {
                  try {
                    final service = _getPrinterService();
                    if (service != null) {
                      await service.updatePrintReceipt(value);
                    }
                    if (mounted) setState(() {});
                  } catch (e) {
                    print('[PrinterConfigPage] Erreur updatePrintReceipt: $e');
                  }
                });
                */
              },
              activeThumbColor: theme.colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestPrint(FThemeData theme) {
    final hasPrinter = _savedPrinterName != null && _savedPrinterName!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test d\'impression',
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FButton(
          onPress: hasPrinter && !_isTesting ? _testPrint : null,
          style: FButtonStyle.outline(),
          child: _isTesting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tester l\'impression'),
        ),
        if (!hasPrinter) ...[
          const SizedBox(height: 8),
          Text(
            'Configurez une imprimante pour tester',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _testPrint() async {
    print('[PrinterConfigPage] ==========================================');
    print('[PrinterConfigPage] 🚀 DÉBUT test impression - ${DateTime.now()}');
    print('[PrinterConfigPage] ==========================================');
    
    setState(() {
      _isTesting = true;
    });
    print('[PrinterConfigPage] ✅ État mis à jour: _isTesting = true');

    try {
      // ÉTAPE 1: Récupérer les informations de la compagnie et du warehouse
      print('[PrinterConfigPage] [ÉTAPE 1] 📋 Récupération compagnie/warehouse...');
      print('[PrinterConfigPage] [ÉTAPE 1] Création CompanyWarehouseService...');
      final companyWarehouseService = CompanyWarehouseService();
      print('[PrinterConfigPage] [ÉTAPE 1] ✅ Service créé');
      
      print('[PrinterConfigPage] [ÉTAPE 1] Appel getSelectedCompany()...');
      final company = await companyWarehouseService.getSelectedCompany();
      print('[PrinterConfigPage] [ÉTAPE 1] ✅ Company récupérée: ${company?.name ?? 'null'}');
      
      print('[PrinterConfigPage] [ÉTAPE 1] Appel getSelectedWarehouse()...');
      final warehouse = await companyWarehouseService.getSelectedWarehouse();
      print('[PrinterConfigPage] [ÉTAPE 1] ✅ Warehouse récupéré: ${warehouse?.name ?? 'null'}');
      
      final companyName = company?.name ?? 'Ma Compagnie';
      final warehouseName = warehouse?.name ?? 'Entrepôt Principal';
      print('[PrinterConfigPage] [ÉTAPE 1] ✅ Final: Compagnie=$companyName, Warehouse=$warehouseName');
      
      // ÉTAPE 2: Générer le PDF de test dans un isolate (non-bloquant)
      print('[PrinterConfigPage] [ÉTAPE 2] ⏳ Début génération PDF (isolate)...');
      print('[PrinterConfigPage] [ÉTAPE 2] Préparation des paramètres...');
      final params = {
        'company': companyName,
        'warehouse': warehouseName,
        'printerName': _savedPrinterName ?? 'Configurée',
        'printerType': _savedPrinterType,
      };
      print('[PrinterConfigPage] [ÉTAPE 2] Paramètres: $params');
      
      print('[PrinterConfigPage] [ÉTAPE 2] Appel compute()...');
      print('[PrinterConfigPage] [ÉTAPE 2] ⚠️ ATTENTION: compute() va lancer un isolate...');
      final pdfBytes = await compute(_generateTestReceiptIsolate, params);
      print('[PrinterConfigPage] [ÉTAPE 2] ✅ PDF généré dans l\'isolate (${pdfBytes.length} bytes)');
      print('[PrinterConfigPage] [ÉTAPE 2] ✅ Retour de compute() réussi');
      
      // ÉTAPE 3: Imprimer (impression manuelle, pas auto)
      print('[PrinterConfigPage] [ÉTAPE 3] 🖨️ Début envoi à l\'imprimante...');
      print('[PrinterConfigPage] [ÉTAPE 3] Création PrinterService...');
      final printerService = PrinterService();
      print('[PrinterConfigPage] [ÉTAPE 3] ✅ PrinterService créé');
      
      print('[PrinterConfigPage] [ÉTAPE 3] Préparation de l\'appel printReceipt()...');
      print('[PrinterConfigPage] [ÉTAPE 3] Paramètres: pdfBytes=${pdfBytes.length} bytes, isAutoPrint=false');
      print('[PrinterConfigPage] [ÉTAPE 3] ⚠️ ATTENTION: Appel printReceipt() dans 100ms...');
      
      // Petit délai pour s'assurer que les logs précédents sont affichés
      await Future.delayed(const Duration(milliseconds: 100));
      print('[PrinterConfigPage] [ÉTAPE 3] ✅ Délai passé, appel printReceipt() maintenant...');
      
      print('[PrinterConfigPage] [ÉTAPE 3] 📞 JUSTE AVANT L\'APPEL printReceipt()...');
      print('[PrinterConfigPage] [ÉTAPE 3] printerService: ${printerService.runtimeType}');
      print('[PrinterConfigPage] [ÉTAPE 3] pdfBytes.length: ${pdfBytes.length}');
      print('[PrinterConfigPage] [ÉTAPE 3] isAutoPrint: false');
      
      // Afficher directement la page d'aperçu PDF (non-bloquant)
      print('[PrinterConfigPage] [ÉTAPE 3] 📄 Ouverture de la page d\'aperçu PDF...');
      if (mounted) {
        print('[PrinterConfigPage] [ÉTAPE 3] Navigation vers PdfPreviewPage...');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfPreviewPage(
              pdfBytes: pdfBytes,
              title: 'Aperçu du reçu',
            ),
          ),
        );
        print('[PrinterConfigPage] [ÉTAPE 3] ✅ Page d\'aperçu ouverte');
      }
      print('[PrinterConfigPage] [ÉTAPE 3] 🏁 Aperçu PDF affiché');

      // ÉTAPE 4: Afficher le message de succès
      print('[PrinterConfigPage] [ÉTAPE 4] 📱 Affichage du message de succès...');
      if (mounted) {
        print('[PrinterConfigPage] [ÉTAPE 4] Widget monté, affichage SnackBar...');
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test d\'impression envoyé !',
              style: theme.typography.base.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: theme.colors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        print('[PrinterConfigPage] [ÉTAPE 4] ✅ SnackBar affiché');
      } else {
        print('[PrinterConfigPage] [ÉTAPE 4] ⚠️ Widget non monté, pas de SnackBar');
      }
      
      print('[PrinterConfigPage] ✅✅✅ TOUTES LES ÉTAPES TERMINÉES AVEC SUCCÈS ✅✅✅');
    } catch (e, stackTrace) {
      print('[PrinterConfigPage] ==========================================');
      print('[PrinterConfigPage] ❌❌❌ ERREUR CAPTURÉE ❌❌❌');
      print('[PrinterConfigPage] Erreur: $e');
      print('[PrinterConfigPage] Type: ${e.runtimeType}');
      print('[PrinterConfigPage] Stack trace:');
      print(stackTrace);
      print('[PrinterConfigPage] ==========================================');
      
      if (mounted) {
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: $e',
              style: theme.typography.base.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: theme.colors.destructive,
          ),
        );
      }
    } finally {
      print('[PrinterConfigPage] [FINALLY] Nettoyage...');
      if (mounted) {
        print('[PrinterConfigPage] [FINALLY] Widget monté, mise à jour de l\'état...');
        setState(() {
          _isTesting = false;
        });
        print('[PrinterConfigPage] [FINALLY] ✅ État mis à jour: _isTesting = false');
      } else {
        print('[PrinterConfigPage] [FINALLY] ⚠️ Widget non monté, pas de setState');
      }
      print('[PrinterConfigPage] ==========================================');
      print('[PrinterConfigPage] 🔚 FIN test impression - ${DateTime.now()}');
      print('[PrinterConfigPage] ==========================================');
    }
  }

  // Fonction isolée pour générer le PDF (appelée via compute())
  // Note: compute() peut passer des valeurs nullables, donc on accepte String?
  static Future<Uint8List> _generateTestReceiptIsolate(Map<String, String?> params) async {
    print('[ISOLATE] ==========================================');
    print('[ISOLATE] 🚀 DÉBUT génération PDF dans isolate');
    print('[ISOLATE] Paramètres reçus: $params');
    
    try {
      print('[ISOLATE] Préparation des valeurs...');
      final companyName = params['company'] ?? 'Ma Compagnie';
      final warehouseName = params['warehouse'] ?? 'Entrepôt Principal';
      final printerName = params['printerName'] ?? 'Configurée';
      final printerType = params['printerType'] ?? 'BLE';
      print('[ISOLATE] ✅ Valeurs préparées: company=$companyName, warehouse=$warehouseName');
      
      print('[ISOLATE] Appel _generateTestReceiptStatic()...');
      final result = await _generateTestReceiptStatic(
        companyName,
        warehouseName,
        printerName,
        printerType,
      );
      print('[ISOLATE] ✅ PDF généré: ${result.length} bytes');
      print('[ISOLATE] ==========================================');
      return result;
    } catch (e, stackTrace) {
      print('[ISOLATE] ❌ ERREUR dans l\'isolate: $e');
      print('[ISOLATE] Stack trace: $stackTrace');
      print('[ISOLATE] ==========================================');
      rethrow;
    }
  }

  // Fonction statique pour générer le PDF (doit être top-level ou static pour compute)
  static Future<Uint8List> _generateTestReceiptStatic(
    String companyName,
    String warehouseName,
    String printerName,
    String printerType,
  ) async {
    print('[PDF_GEN] Début génération PDF...');
    print('[PDF_GEN] Création Document...');
    final pdf = pw.Document();
    print('[PDF_GEN] ✅ Document créé');
    
    print('[PDF_GEN] Préparation date/time...');
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    print('[PDF_GEN] ✅ Date formatée: ${dateFormatter.format(now)}');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, 200 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo IntegralPOS (texte stylisé)
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'INTEGRAL',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      'POS',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              // Nom de la compagnie
              pw.Text(
                companyName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 5),
              
              // Warehouse
              pw.Text(
                warehouseName,
                style: pw.TextStyle(
                  fontSize: 12,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 15),
              pw.Divider(),
              pw.SizedBox(height: 15),
              
              // Message de test
              pw.Text(
                'TEST D\'IMPRESSION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 10),
              
              pw.Text(
                'Votre imprimante fonctionne',
                style: pw.TextStyle(
                  fontSize: 12,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.Text(
                'parfaitement ! 🎉',
                style: pw.TextStyle(
                  fontSize: 12,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 15),
              
              // Message clin d'œil
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      '✨ Prêt à imprimer',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'vos reçus de vente !',
                      style: pw.TextStyle(
                        fontSize: 11,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 15),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              // Informations techniques
              pw.Text(
                'Date: ${dateFormatter.format(now)}',
                style: pw.TextStyle(
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 5),
              
              pw.Text(
                'Imprimante: $printerName',
                style: pw.TextStyle(
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 5),
              
              pw.Text(
                'Type: ${printerType == 'BLE' ? 'Bluetooth' : printerType == 'USB' ? 'USB' : 'WiFi'}',
                style: pw.TextStyle(
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 15),
              
              // Footer
              pw.Text(
                'Merci d\'utiliser',
                style: pw.TextStyle(
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.Text(
                'IntegralPOS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 10),
              
              pw.Text(
                '=' * 32,
                style: pw.TextStyle(
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
      ),
    );

    print('[PDF_GEN] Appel pdf.save()...');
    print('[PDF_GEN] ⚠️ ATTENTION: pdf.save() peut être CPU-intensive...');
    final result = await pdf.save();
    print('[PDF_GEN] ✅ pdf.save() terminé: ${result.length} bytes');
    print('[PDF_GEN] ✅ Génération PDF complète');
    return result;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
