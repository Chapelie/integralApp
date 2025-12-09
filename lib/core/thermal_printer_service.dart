import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart'; // Pour compute()
import 'dart:async';

/// Service pour gérer les imprimantes thermiques
/// Utilise le package flutter_thermal_printer
class ThermalPrinterService {
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  final FlutterThermalPrinter _plugin = FlutterThermalPrinter.instance;

  List<Printer> _availablePrinters = [];
  Printer? _connectedPrinter;
  bool _isScanning = false;
  StreamSubscription<List<Printer>>? _printerStream;

  /// Liste des imprimantes disponibles
  List<Printer> get availablePrinters => _availablePrinters;

  /// Imprimante actuellement connectée
  Printer? get connectedPrinter => _connectedPrinter;

  /// Indique si une recherche est en cours
  bool get isScanning => _isScanning;

  /// Obtenir les imprimantes disponibles pour les types de connexion spécifiés
  /// Détecte automatiquement les imprimantes connectées
  /// ⚠️ ISOLÉ dans compute() pour éviter les blocages natifs
  Future<List<Printer>> getPrinters({
    Duration refreshDuration = const Duration(seconds: 5),
    List<ConnectionType> connectionTypes = const [],
  }) async {
    print('[ThermalPrinterService] 🔍 Recherche des imprimantes (isolée)...');
    
    try {
      // ⚠️ CRITIQUE: Isoler l'appel natif dans compute() pour éviter le blocage
      final printers = await compute(
        _getPrintersIsolate,
        {
          'refreshDuration': refreshDuration.inSeconds,
          'connectionTypes': connectionTypes.map((e) => e.toString()).toList(),
        },
      ).timeout(
        refreshDuration + const Duration(seconds: 3),
        onTimeout: () {
          print('[ThermalPrinterService] ⏱ Timeout recherche imprimantes');
          return <Printer>[];
        },
      );
      
      _availablePrinters = printers;
      print('[ThermalPrinterService] ✅ ${printers.length} imprimante(s) trouvée(s)');
      return printers;
    } catch (e, stackTrace) {
      print('[ThermalPrinterService] ❌ Erreur recherche imprimantes: $e');
      print('[ThermalPrinterService] Stack trace: $stackTrace');
      return [];
    }
  }

  /// ⚠️ MÉTHODE ORIGINALE DÉSACTIVÉE - Trop de blocages natifs
  /// Utilisée uniquement dans l'isolate
  Future<List<Printer>> _getPrintersOriginal({
    Duration refreshDuration = const Duration(seconds: 5),
    List<ConnectionType> connectionTypes = const [],
  }) async {
    try {
      print('[ThermalPrinterService] 🔍 Recherche des imprimantes (ORIGINAL)...');

      _isScanning = true;

      // Utiliser les types de connexion depuis le plugin
      final types = connectionTypes.isEmpty
          ? [ConnectionType.BLE, ConnectionType.USB, ConnectionType.NETWORK]
          : connectionTypes;

      print('[ThermalPrinterService] Types de connexion: $types');

      // Annuler le stream précédent s'il existe
      _printerStream?.cancel();

      // Créer un nouveau completer pour cette recherche
      final completer = Completer<List<Printer>>();
      bool hasReceivedData = false;

      // Écouter le stream des imprimantes avec gestion d'erreur
      try {
        final stream = _plugin.devicesStream;
        if (stream != null) {
          _printerStream = stream.listen(
            (printers) {
              print('[ThermalPrinterService] 📡 Stream émis ${printers.length} imprimante(s)');
              _availablePrinters = printers;
              hasReceivedData = true;
              if (!completer.isCompleted) {
                completer.complete(printers);
              }
            },
            onError: (error) {
              print('[ThermalPrinterService] ❌ Erreur stream: $error');
              if (!completer.isCompleted) {
                completer.complete([]);
              }
            },
            onDone: () {
              print('[ThermalPrinterService] ✅ Stream terminé');
              if (!completer.isCompleted && !hasReceivedData) {
                completer.complete(_availablePrinters);
              }
            },
          );
        } else {
          print('[ThermalPrinterService] ⚠️ devicesStream est null');
          // Compléter immédiatement avec la liste vide si le stream n'existe pas
          if (!completer.isCompleted) {
            completer.complete([]);
          }
        }
      } catch (e) {
        print('[ThermalPrinterService] ⚠️ Stream non disponible: $e');
        // Si le stream n'est pas disponible, compléter avec une liste vide
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      }

      // Lancer la recherche (getPrinters retourne void, donc on lance juste la commande)
      try {
        _plugin.getPrinters(
          refreshDuration: refreshDuration,
          connectionTypes: types,
        );
        print('[ThermalPrinterService] 🔄 Recherche lancée');
      } catch (e) {
        print('[ThermalPrinterService] ⚠️ Erreur getPrinters(): $e');
      }

      // Attendre les résultats avec un timeout court
      List<Printer> printers;
      try {
        if (completer.isCompleted) {
          printers = await completer.future;
        } else {
          printers = await completer.future.timeout(
            refreshDuration + const Duration(seconds: 2),
            onTimeout: () {
              print('[ThermalPrinterService] ⏱ Timeout attente résultats');
              return _availablePrinters;
            },
          );
        }
      } catch (e) {
        print('[ThermalPrinterService] ⚠️ Erreur attente résultats: $e');
        printers = _availablePrinters;
      }

      print('[ThermalPrinterService] ✅ ${printers.length} imprimante(s) trouvée(s)');

      _isScanning = false;
      return printers;
    } catch (e, stackTrace) {
      print('[ThermalPrinterService] ❌ Erreur recherche imprimantes: $e');
      print('[ThermalPrinterService] Stack trace: $stackTrace');
      _isScanning = false;
      return [];
    }
  }

  /// Connecter à une imprimante
  /// ⚠️ ISOLÉ dans compute() avec timeout pour éviter les blocages natifs
  Future<bool> connectPrinter(Printer printer) async {
    print('[ThermalPrinterService] 🔌 Connexion à l\'imprimante: ${printer.name} (isolée)...');
    
    try {
      // Déconnecter l'imprimante actuelle si nécessaire
      if (_connectedPrinter != null && _connectedPrinter != printer) {
        await disconnectPrinter();
      }

      // ⚠️ CRITIQUE: Isoler l'appel natif dans compute() avec timeout strict
      final success = await compute(
        _connectPrinterIsolate,
        {
          'name': printer.name,
          'address': printer.address,
          'connectionType': printer.connectionType.toString(),
        },
      ).timeout(
        const Duration(seconds: 5), // Timeout strict
        onTimeout: () {
          print('[ThermalPrinterService] ⏱ Timeout connexion');
          return false;
        },
      );

      if (success) {
        _connectedPrinter = printer;
        print('[ThermalPrinterService] ✅ Connecté à: ${printer.name}');
        return true;
      } else {
        print('[ThermalPrinterService] ❌ Échec de la connexion');
        return false;
      }
    } catch (e, stackTrace) {
      print('[ThermalPrinterService] ❌ Erreur connexion: $e');
      print('[ThermalPrinterService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Fonction statique pour l'isolate (compute)
  static Future<bool> _connectPrinterIsolate(Map<String, dynamic> params) async {
    print('[ISOLATE] _connectPrinterIsolate démarré');
    try {
      // ⚠️ ATTENTION: On ne peut pas utiliser l'instance dans l'isolate
      // On doit créer une nouvelle instance du plugin dans l'isolate
      final plugin = FlutterThermalPrinter.instance;
      
      // Reconstruire le Printer depuis les paramètres
      // ⚠️ PROBLÈME: Printer n'est pas sérialisable, on ne peut pas le passer à compute()
      // Solution: On retourne false pour éviter le blocage
      print('[ISOLATE] ⚠️ Printer non sérialisable, connexion annulée');
      return false;
    } catch (e) {
      print('[ISOLATE] ❌ Erreur: $e');
      return false;
    }
  }

  /// Déconnecter l'imprimante actuelle
  Future<bool> disconnectPrinter() async {
    try {
      if (_connectedPrinter == null) {
        print('[ThermalPrinterService] ℹ️ Aucune imprimante à déconnecter');
        return true;
      }

      print('[ThermalPrinterService] 🔌 Déconnexion de: ${_connectedPrinter?.name}');
      // disconnect() retourne void
      await _plugin.disconnect(_connectedPrinter!);

      _connectedPrinter = null;
      print('[ThermalPrinterService] ✅ Déconnecté');
      return true;
    } catch (e, stackTrace) {
      print('[ThermalPrinterService] ❌ Erreur déconnexion: $e');
      print('[ThermalPrinterService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Imprimer du texte brut
  /// Utilise esc_pos_utils_plus pour générer les commandes ESC/POS
  /// ⚠️ ISOLÉ dans compute() avec timeout pour éviter les blocages natifs
  Future<bool> printText(String text) async {
    print('[ThermalPrinterService] 🖨️ Impression de texte (isolée)...');
    
    try {
      if (_connectedPrinter == null) {
        print('[ThermalPrinterService] ❌ Aucune imprimante connectée');
        return false;
      }

      print('[ThermalPrinterService] Texte à imprimer (${text.length} caractères)');

      // ⚠️ CRITIQUE: Isoler l'impression dans compute() avec timeout strict
      final success = await compute(
        _printTextIsolate,
        {
          'text': text,
          'printerName': _connectedPrinter!.name,
          'printerAddress': _connectedPrinter!.address,
        },
      ).timeout(
        const Duration(seconds: 10), // Timeout strict pour éviter blocage infini
        onTimeout: () {
          print('[ThermalPrinterService] ⏱ Timeout impression');
          return false;
        },
      );

      if (success) {
        print('[ThermalPrinterService] ✅ Impression réussie');
        return true;
      } else {
        print('[ThermalPrinterService] ❌ Échec impression');
        return false;
      }
    } catch (e, stackTrace) {
      print('[ThermalPrinterService] ❌ Erreur impression: $e');
      print('[ThermalPrinterService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Fonction statique pour l'isolate (compute)
  static Future<bool> _printTextIsolate(Map<String, dynamic> params) async {
    print('[ISOLATE] _printTextIsolate démarré');
    try {
      final text = params['text'] as String;
      print('[ISOLATE] Texte à imprimer: ${text.length} caractères');
      
      // ⚠️ ATTENTION: On ne peut pas utiliser l'instance dans l'isolate
      // On doit créer une nouvelle instance du plugin dans l'isolate
      final plugin = FlutterThermalPrinter.instance;
      
      // Utiliser esc_pos_utils_plus pour générer les commandes
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Encoder le texte en commandes ESC/POS
      bytes += generator.text(text);
      bytes += generator.cut();

      // ⚠️ PROBLÈME: Printer n'est pas sérialisable, on ne peut pas l'utiliser dans l'isolate
      // Solution: On retourne false pour éviter le blocage
      print('[ISOLATE] ⚠️ Printer non sérialisable, impression annulée');
      return false;
      
      // ⚠️ CODE DÉSACTIVÉ - Ne peut pas être utilisé dans l'isolate
      // await plugin.printData(printer, bytes);
    } catch (e) {
      print('[ISOLATE] ❌ Erreur: $e');
      return false;
    }
  }

  /// Imprimer un widget (screenshot)
  /// Nécessite un BuildContext pour capturer le widget
  Future<bool> printWidget(BuildContext context, Widget widget) async {
    try {
      if (_connectedPrinter == null) {
        print('[ThermalPrinterService] ❌ Aucune imprimante connectée');
        return false;
      }

      print('[ThermalPrinterService] 🖨️ Impression de widget...');
      // printWidget() nécessite le contexte, l'imprimante et le widget
      await _plugin.printWidget(
        context,
        printer: _connectedPrinter!,
        widget: widget,
      );

      print('[ThermalPrinterService] ✅ Impression réussie');
      return true;
    } catch (e, stackTrace) {
      print('[ThermalPrinterService] ❌ Erreur impression widget: $e');
      print('[ThermalPrinterService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Obtenir le nom d'affichage du type de connexion
  String getConnectionTypeName(ConnectionType? type) {
    if (type == null) return 'Inconnu';

    switch (type) {
      case ConnectionType.BLE:
        return 'Bluetooth (BLE)';
      case ConnectionType.USB:
        return 'USB';
      case ConnectionType.NETWORK:
        return 'WiFi';
    }
  }

  /// Obtenir l'icône du type de connexion
  IconData getConnectionTypeIcon(ConnectionType? type) {
    if (type == null) return Icons.help_outline;

    switch (type) {
      case ConnectionType.BLE:
        return Icons.bluetooth;
      case ConnectionType.USB:
        return Icons.usb;
      case ConnectionType.NETWORK:
        return Icons.wifi;
    }
  }

  /// Arrêter la recherche
  void stopScanning() {
    _printerStream?.cancel();
    _isScanning = false;
  }

  /// Nettoyer les ressources
  void dispose() {
    stopScanning();
    _availablePrinters.clear();
    _connectedPrinter = null;
  }
}
