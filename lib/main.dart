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
import 'core/api_service.dart' show ErrorInterceptor;
import 'features/auth/login_page.dart';
import 'features/cash_register/open_register_page.dart';
import 'features/cash_register/close_register_page.dart';
import 'features/settings/device_registration_debug_page.dart';
import 'features/settings/printer_config_page.dart';
import 'features/auth/company_warehouse_config_page.dart';
import 'features/pos/payment_page.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/app_shell.dart';
import 'providers/navigation_provider.dart';

// Helper function pour créer une route AppShell avec initialisation du provider
Widget _createAppShellRoute(AppRoute route) {
  return Builder(
    builder: (context) {
      // Initialiser la route dans le provider
      final container = ProviderScope.containerOf(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.read(navigationProvider.notifier).navigateTo(route);
      });
      return const AppShell();
    },
  );
}

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
        home: const SplashOrLogin(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/company-warehouse-config': (context) => const CompanyWarehouseConfigPage(),
          // Routes principales gérées par AppShell avec IndexedStack
          '/pos': (context) => _createAppShellRoute(AppRoute.pos),
          '/products': (context) => _createAppShellRoute(AppRoute.products),
          '/customers': (context) => _createAppShellRoute(AppRoute.customers),
          '/inventory': (context) => _createAppShellRoute(AppRoute.inventory),
          '/employees': (context) => _createAppShellRoute(AppRoute.employees),
          '/cash-register': (context) => _createAppShellRoute(AppRoute.cashRegister),
          '/reports': (context) => _createAppShellRoute(AppRoute.reports),
          '/receipts': (context) => _createAppShellRoute(AppRoute.receipts),
          '/accounting': (context) => _createAppShellRoute(AppRoute.accounting),
          '/settings': (context) => _createAppShellRoute(AppRoute.settings),
          '/tables': (context) => _createAppShellRoute(AppRoute.tables),
          '/waiters': (context) => _createAppShellRoute(AppRoute.waiters),
          '/kitchen': (context) => _createAppShellRoute(AppRoute.kitchen),
          // Routes modales (gardent la navigation normale)
          '/open-register': (context) => const OpenRegisterPage(),
          '/close-register': (context) => const CloseRegisterPage(),
          '/printer-config': (context) => const PrinterConfigPage(),
          '/device-debug': (context) => const DeviceRegistrationDebugPage(),
          '/payment': (context) {
            // Récupérer le total depuis les arguments
            final args = ModalRoute.of(context)?.settings.arguments;
            final total = args is double ? args : 0.0;
            return PaymentPage(total: total);
          },
        },
        onGenerateRoute: (settings) {
          // Les routes principales sont déjà définies dans 'routes' et pointent vers AppShell
          // onGenerateRoute est appelé seulement si la route n'est pas trouvée dans 'routes'
          // Donc on retourne null pour laisser Flutter gérer les routes non définies
          return null;
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
        // Initialiser la route dans le provider
        ref.read(navigationProvider.notifier).navigateTo(AppRoute.pos);
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
      final screenSize = MediaQuery.of(context).size;
      final logoSize = screenSize.width * 0.6; // 60% de la largeur de l'écran
      
      return Scaffold(
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo - Plus grand
                  Image.asset(
                    'assets/images/IntegralPOS.jpg',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
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
            // Texte "Développé par DS Solution" en bas - Plus visible
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Développé par DS Solution',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Always return a valid widget
    return const LoginPage();
  }
}

