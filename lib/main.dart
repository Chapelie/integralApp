// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage_service.dart';
import 'core/device_service.dart';
import 'core/device_registration_service.dart';
import 'core/image_service.dart';
import 'core/auth_service.dart';
import 'core/pin_service.dart';
import 'core/business_config.dart';
import 'core/business_config.dart' as core;
import 'core/warehouse_type_service.dart';
import 'models/warehouse_type.dart';
import 'core/theme.dart';
import 'core/initial_sync_service.dart';
import 'core/api_service.dart';
import 'widgets/inactivity_wrapper.dart';
import 'core/api_service.dart' show ErrorInterceptor;
import 'features/auth/login_page.dart';
import 'features/cash_register/open_register_page.dart';
import 'features/cash_register/close_register_page.dart';
import 'features/settings/device_registration_debug_page.dart';
import 'features/settings/printer_config_page.dart';
import 'features/auth/company_warehouse_config_page.dart';
import 'features/pos/payment_page.dart';
import 'features/pos/pos_page.dart';
import 'features/products/products_page.dart';
import 'features/customers/customer_list_page.dart';
import 'features/inventory/inventory_page.dart';
import 'features/employees/employees_page.dart';
import 'features/cash_register/cash_register_page.dart';
import 'features/reports/reports_page.dart';
import 'features/accounting/accounting_page.dart';
import 'features/settings/settings_page.dart';
import 'features/restaurant/tables_page.dart';
import 'features/restaurant/waiters_page.dart';
import 'features/restaurant/kitchen_page.dart';
import 'features/pos/tab_list_page.dart';
import 'features/pos/credit_note_list_page.dart';
import 'features/sales/receipts_page.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  print('[Main] 🚀 DÉBUT main()');
  WidgetsFlutterBinding.ensureInitialized();
  print('[Main] ✅ WidgetsFlutterBinding initialisé');

  // Initialize core services
  print('[Main] 🔧 Initialisation de StorageService...');
  await StorageService().init();
  print('[Main] ✅ StorageService initialisé');
  
  print('[Main] 🔧 Initialisation de DeviceService...');
  await DeviceService().init();
  print('[Main] ✅ DeviceService initialisé');
  
  print('[Main] 🔧 Initialisation de ImageService...');
  await ImageService().init(); // Initialize image service
  print('[Main] ✅ ImageService initialisé');
  
  print('[Main] 🔧 Initialisation de AuthService...');
  await AuthService().init();
  print('[Main] ✅ AuthService initialisé');
  
  print('[Main] 🔧 Initialisation de PinService...');
  await PinService().init();
  print('[Main] ✅ PinService initialisé');
  
  // Skip PrinterService initialization at startup to avoid blocking
  // It will be initialized on-demand when needed
  print('[Main] ⏭️ PrinterService initialisation reportée (lazy loading)');
  
  // Initialize BusinessConfig to load saved business type
  print('[Main] 🔧 Initialisation de BusinessConfig...');
  await BusinessConfig().init();
  print('[Main] ✅ BusinessConfig initialisé');
  
  // Try to load warehouse type and sync with BusinessConfig
  print('[Main] 🔧 Tentative de chargement du warehouse type...');
  try {
    final warehouseTypeService = WarehouseTypeService();
    print('[Main] 🔍 Appel de getStoredWarehouseType...');
    final storedWarehouseType = await warehouseTypeService.getStoredWarehouseType();
    print('[Main] 🔍 getStoredWarehouseType terminé');
    
    if (storedWarehouseType != null) {
      print('[Main] ✅ Warehouse type found: ${storedWarehouseType.displayName}');
      // Synchroniser avec BusinessConfig
      print('[Main] 🔧 Création de BusinessConfig...');
      final businessConfig = BusinessConfig();
      print('[Main] ✅ BusinessConfig créé');
      
      BusinessType businessType;
      
      print('[Main] 🔄 Mapping warehouse type vers business type...');
      switch (storedWarehouseType) {
        case WarehouseType.restaurant:
          businessType = core.BusinessType.restaurant;
          break;
        case WarehouseType.supermarket:
        case WarehouseType.pharmacie:
        case WarehouseType.electronique:
          businessType = core.BusinessType.retail;
          break;
        default:
          businessType = core.BusinessType.retail;
      }
      
      print('[Main] 📊 Updating BusinessConfig with type: ${businessType.label}');
      await businessConfig.init(businessType);
      print('[Main] ✅ BusinessConfig mis à jour');
    } else {
      print('[Main] ⚠️ Aucun warehouse type trouvé');
    }
  } catch (e, stackTrace) {
    print('[Main] ❌ Error loading warehouse type: $e');
    print('[Main] Stack trace: $stackTrace');
  }
  
  print('[Main] ✅ Fin du chargement du warehouse type');
  
  // SyncService is initialized automatically when needed
  print('[Main] ℹ️ SyncService initialisé automatiquement');
  
  // Configure API service logout callback
  print('[Main] 🔧 Configuration du callback ErrorInterceptor...');
  ErrorInterceptor.setOnUnauthorizedCallback(() {
    // This will be called when a 401 error occurs
    // The actual logout will be handled by the UI layer
    print('[Main] 🚫 401 Unauthorized detected - UI should handle logout');
  });
  print('[Main] ✅ ErrorInterceptor configuré');

  // Try to register device with backend
  print('[Main] 🚀 Début _registerDeviceIfNeeded...');
  await _registerDeviceIfNeeded();
  print('[Main] ✅ _registerDeviceIfNeeded terminé');

  // Perform initial sync with backend if needed
  print('[Main] 🚀 Début _performInitialSyncIfNeeded...');
  await _performInitialSyncIfNeeded();
  print('[Main] ✅ _performInitialSyncIfNeeded terminé');

  print('[Main] 🚀 Lancement de runApp...');
  runApp(const ProviderScope(child: IntegralPOSApp()));
  print('[Main] ✅ runApp lancé');
}

/// Try to register device with backend
/// Only attempts registration if user is authenticated
Future<void> _registerDeviceIfNeeded() async {
  print('[Main] 📍 _registerDeviceIfNeeded: début');
  
  try {
    // Vérifier si l'utilisateur est connecté
    print('[Main] 🔐 Vérification de l\'authentification...');
    final isAuth = AuthService().isAuthenticated;
    print('[Main] 🔐 isAuthenticated: $isAuth');
    
    if (!isAuth) {
      print('[Main] ❌ User not authenticated - skipping device registration');
      return;
    }

    print('[Main] ✅ User authenticated - starting device registration monitoring');
    final deviceRegistrationService = DeviceRegistrationService();
    print('[Main] 📋 Appel de startRegistrationMonitoring...');
    
    // Démarrer le monitoring automatique (retry continu)
    await deviceRegistrationService.startRegistrationMonitoring();
    print('[Main] ✅ startRegistrationMonitoring terminé');
  } catch (e, stackTrace) {
    print('[Main] ❌ Error starting device registration monitoring: $e');
    print('[Main] Stack trace: $stackTrace');
    // Ne pas faire échouer l'application si l'enregistrement échoue
  }
  
  print('[Main] 🔚 _registerDeviceIfNeeded: fin');
}

/// Checks if products exist, if not, performs initial sync with backend
Future<void> _performInitialSyncIfNeeded() async {
  print('[Main] 📍 _performInitialSyncIfNeeded: début');
  
  try {
    print('[Main] 🔧 Création de InitialSyncService...');
    final initialSyncService = InitialSyncService();
    print('[Main] ✅ InitialSyncService créé');
    
    print('[Main] 🔍 Vérification de needsInitialSync...');
    final needsSync = await initialSyncService.needsInitialSync();
    print('[Main] 🔍 needsSync: $needsSync');

    if (needsSync) {
      print('[Main] ❌ No products found. Performing initial sync with backend...');
      final result = await initialSyncService.performInitialSync();
      
      if (result['success']) {
        print('[Main] ✅ Initial sync completed successfully:');
        result['synced'].forEach((key, value) {
          print('[Main]   - $key: $value items');
        });
      } else {
        print('[Main] ❌ Initial sync failed with errors:');
        result['errors'].forEach((error) {
          print('[Main]   - $error');
        });
        // No fallback data - products will be loaded from API
        print('[Main] ⚠️ No products available - will load from API when needed');
      }
    } else {
      print('[Main] ✅ Products already exist. Skipping initial sync.');
    }
  } catch (e, stackTrace) {
    print('[Main] ❌ Error during initial sync: $e');
    print('[Main] Stack trace: $stackTrace');
    // No fallback data - products will be loaded from API
    print('[Main] ⚠️ No products available - will load from API when needed');
  }
  
  print('[Main] 🔚 _performInitialSyncIfNeeded: fin');
}


class IntegralPOSApp extends ConsumerStatefulWidget {
  const IntegralPOSApp({super.key});

  @override
  ConsumerState<IntegralPOSApp> createState() => _IntegralPOSAppState();
}

class _IntegralPOSAppState extends ConsumerState<IntegralPOSApp> {
  @override
  void initState() {
    super.initState();
    // Settings are loaded automatically in the provider
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return AppTheme.wrapApp(
      MaterialApp(
        title: 'IntegralPOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(themeType: settingsState.themeType).toApproximateMaterialTheme(),
        darkTheme: AppTheme.darkTheme(themeType: settingsState.themeType).toApproximateMaterialTheme(),
        themeMode: settingsState.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: InactivityWrapper(
          child: const SplashOrLogin(),
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/company-warehouse-config': (context) => const CompanyWarehouseConfigPage(),
          '/pos': (context) => PosPage(),
          '/products': (context) => ProductsPage(),
          '/customers': (context) => CustomerListPage(),
          '/inventory': (context) => InventoryPage(),
          '/employees': (context) => EmployeesPage(),
          '/cash-register': (context) => CashRegisterPage(),
          '/open-register': (context) => const OpenRegisterPage(),
          '/close-register': (context) => const CloseRegisterPage(),
          '/reports': (context) => ReportsPage(),
          '/accounting': (context) => AccountingPage(),
          '/settings': (context) => SettingsPage(),
          '/printer-config': (context) => const PrinterConfigPage(),
          '/device-debug': (context) => const DeviceRegistrationDebugPage(),
          // Restaurant routes
          '/tables': (context) => TablesPage(),
          '/waiters': (context) => WaitersPage(),
          '/kitchen': (context) => KitchenPage(),
          // Credit notes and tabs
          '/tabs': (context) => const TabListPage(),
          '/credit-notes': (context) => const CreditNoteListPage(),
          // Receipts page
          '/receipts': (context) => const ReceiptsPage(),
          // Payment page
          '/payment': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            final totalToPay = args is double ? args : null;
            return PaymentPage(totalToPay: totalToPay);
          },
        },
      ),
      darkMode: settingsState.darkMode,
      themeType: settingsState.themeType,
    );
  }
}

class SplashOrLogin extends ConsumerStatefulWidget {
  const SplashOrLogin({super.key});

  @override
  ConsumerState<SplashOrLogin> createState() => _SplashOrLoginState();
}

class _SplashOrLoginState extends ConsumerState<SplashOrLogin> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    print('[SplashOrLogin] 🚀 DÉBUT _checkAuth');
    
    // Show splash for a brief moment
    await Future.delayed(const Duration(milliseconds: 500));
    print('[SplashOrLogin] ⏱️ Splash delay terminé');

    if (mounted) {
      print('[SplashOrLogin] 🔐 Vérification de l\'authentification...');
      await ref.read(authProvider.notifier).checkAuth();
      print('[SplashOrLogin] ✅ Vérification terminée');

      setState(() {
        _isChecking = false;
      });
      print('[SplashOrLogin] 🔄 État mis à jour');

      final authState = ref.read(authProvider);
      print('[SplashOrLogin] 👤 AuthState: authenticated=${authState.isAuthenticated}');

      if (authState.isAuthenticated && mounted) {
        print('[SplashOrLogin] 📍 Redirection vers /pos...');
        Navigator.of(context).pushReplacementNamed('/pos');
      } else {
        print('[SplashOrLogin] 📍 Affichage de LoginPage');
      }
    } else {
      print('[SplashOrLogin] ⚠️ Widget non monté');
    }
    
    print('[SplashOrLogin] 🔚 FIN _checkAuth');
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'IntegralPOS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point de vente moderne',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // Always return a valid widget
    return const LoginPage();
  }
}

