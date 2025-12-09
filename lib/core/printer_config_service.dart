import 'dart:convert';

enum PrinterInterface {
  system, // Impression système (choix de l'imprimante par l'utilisateur)
  usb,
  bluetooth,
  network,
}

class PrinterConfig {
  final PrinterInterface interface;
  final String? printerName;
  final String? printerAddress;
  final bool autoPrint;
  final bool printReceipt;

  PrinterConfig({
    required this.interface,
    this.printerName,
    this.printerAddress,
    this.autoPrint = false,
    this.printReceipt = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'interface': interface.name,
      'printerName': printerName,
      'printerAddress': printerAddress,
      'autoPrint': autoPrint,
      'printReceipt': printReceipt,
    };
  }

  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      interface: PrinterInterface.values.firstWhere(
        (e) => e.name == json['interface'],
        orElse: () => PrinterInterface.system,
      ),
      printerName: json['printerName'],
      printerAddress: json['printerAddress'],
      autoPrint: json['autoPrint'] ?? false,
      printReceipt: json['printReceipt'] ?? true,
    );
  }

  PrinterConfig copyWith({
    PrinterInterface? interface,
    String? printerName,
    String? printerAddress,
    bool? autoPrint,
    bool? printReceipt,
  }) {
    return PrinterConfig(
      interface: interface ?? this.interface,
      printerName: printerName ?? this.printerName,
      printerAddress: printerAddress ?? this.printerAddress,
      autoPrint: autoPrint ?? this.autoPrint,
      printReceipt: printReceipt ?? this.printReceipt,
    );
  }
}

class PrinterConfigService {
  static final PrinterConfigService _instance = PrinterConfigService._internal();
  factory PrinterConfigService() => _instance;
  PrinterConfigService._internal();

  static const String _key = 'printer_config';

  PrinterConfig _config = PrinterConfig(
    interface: PrinterInterface.system,
    autoPrint: false,
    printReceipt: true,
  );

  PrinterConfig get config => _config;

  // NE PLUS UTILISER SharedPreferences - Juste la config en mémoire
  Future<void> load() async {
    print('[PrinterConfigService] ℹ️ Utilisation config par défaut (pas de SharedPreferences)');
    // Config par défaut déjà initialisée, rien à charger
  }

  // Sauvegarder uniquement en mémoire, pas sur disque
  Future<void> save(PrinterConfig config) async {
    _config = config;
    print('[PrinterConfigService] Configuration en mémoire: ${config.toJson()}');
  }

  Future<void> updateAutoPrint(bool autoPrint) async {
    await save(_config.copyWith(autoPrint: autoPrint));
  }

  Future<void> updatePrintReceipt(bool printReceipt) async {
    await save(_config.copyWith(printReceipt: printReceipt));
  }

  Future<void> updateInterface(PrinterInterface interface) async {
    await save(_config.copyWith(interface: interface));
  }

  Future<void> updatePrinter(String? printerName, String? printerAddress) async {
    await save(_config.copyWith(
      printerName: printerName,
      printerAddress: printerAddress,
    ));
  }
}


