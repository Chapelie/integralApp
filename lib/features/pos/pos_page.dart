import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:integralpos/models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/cash_register_provider.dart';
import '../../providers/sidebar_provider.dart';
import '../../core/responsive_helper.dart';
import '../../core/cash_register_service.dart';
import '../../core/beep_service.dart';
import '../../widgets/main_layout.dart';
import '../../widgets/price_input_dialog.dart';
import '../../widgets/mobile_header.dart';
import '../restaurant/widgets/restaurant_order_info.dart';
import '../cash_register/force_open_register_dialog.dart';
import 'widgets/products_grid.dart';
import 'widgets/order_panel.dart';
import 'widgets/order_panel_compact.dart';
import 'widgets/topbar.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentRoute = '/pos';

  @override
  void initState() {
    super.initState();
    print('[PosPage] ===== INIT STATE =====');
    print('[PosPage] Chargement des produits et de la caisse...');

    // Charger les produits et la caisse du stockage local immédiatement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[PosPage] PostFrameCallback exécuté');
      // D'abord charger depuis le stockage local
      print('[PosPage] Appel loadProductsFromStorage...');
      ref.read(productProvider.notifier).loadProductsFromStorage();
      // Charger la caisse actuelle
      print('[PosPage] Appel loadCurrentRegister...');
      ref.read(cashRegisterProvider.notifier).loadCurrentRegister();
      // Puis essayer de faire une mise à jour depuis l'API (sans bloquer l'interface)
      print('[PosPage] Appel _refreshProductsInBackground...');
      _refreshProductsInBackground();
    });
  }

  /// Rafraîchir les produits en arrière-plan sans bloquer l'interface
  Future<void> _refreshProductsInBackground() async {
    print('[PosPage] ===== DÉBUT _refreshProductsInBackground =====');
    try {
      print('[PosPage] Tentative de rafraîchissement depuis l\'API...');
      await ref.read(productProvider.notifier).loadProducts();
      print('[PosPage] ✅ Rafraîchissement réussi');
    } catch (e) {
      // Ignorer les erreurs de réseau en arrière-plan
      print('[PosPage] ❌ Background refresh failed: $e');
      print('[PosPage] Type d\'erreur: ${e.runtimeType}');
    }
    print('[PosPage] ===== FIN _refreshProductsInBackground =====');
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final cartState = ref.watch(cartProvider);
    final isDesktop = Responsive.isDesktop(context);
    final theme = FTheme.of(context);
    final isCollapsed = ref.watch(sidebarProvider);
    
    print('[PosPage] ===== BUILD =====');
    print('[PosPage] État des produits - isLoading: ${productState.isLoading}, products: ${productState.products.length}, error: ${productState.error}');
    print('[PosPage] Produits filtrés: ${productState.filteredProducts.length}');

    return MainLayout(
      currentRoute: _currentRoute,
      appBar: isDesktop ? const TopBar() : const MobileHeader(title: 'Point de vente'),
      floatingActionButton: !isDesktop && cartState.items.isNotEmpty
          ? _buildCartFab(context, cartState, theme)
          : null,
      child: _buildBody(context, productState, cartState, isDesktop, theme, isCollapsed),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductState productState,
    CartState cartState,
    bool isDesktop,
    FThemeData theme,
    bool isCollapsed,
  ) {
    if (productState.isLoading && productState.products.isEmpty) {
      return _buildLoadingState(context, theme);
    }

    if (productState.error != null && productState.products.isEmpty) {
      return _buildErrorState(context, productState.error!, theme);
    }

    // Afficher un message discret si on est en mode hors ligne mais qu'on a des produits
    if (productState.error != null && productState.products.isNotEmpty) {
      return Column(
        children: [
          // Message discret en mode hors ligne
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Mode hors ligne - Données locales',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      // Products grid
                      Expanded(
                        flex: isCollapsed ? 3 : 2,
                        child: Column(
                          children: [
                            const RestaurantOrderInfo(showCategories: true), // Catégories sur desktop
                            Expanded(
                              child: ProductsGrid(
                                products: productState.filteredProducts,
                                onProductAdd: _handleProductAdd,
                                onProductDetails: _handleProductDetails,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Order panel
                      Expanded(
                        flex: isCollapsed ? 2 : 1,
                        child: OrderPanel(),
                      ),
                    ],
                  )
                  : Scaffold(
                      key: _scaffoldKey,
                      body: Column(
                        children: [
                          const RestaurantOrderInfo(), // Types de services sur mobile
                          Expanded(
                            child: ProductsGrid(
                              products: productState.filteredProducts,
                              onProductAdd: _handleProductAdd,
                              onProductDetails: _handleProductDetails,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      );
    }

    if (isDesktop) {
      // Calculer les proportions en fonction de l'état de collapse
      final productsFlex = isCollapsed ? 3 : 2;
      final orderPanelFlex = isCollapsed ? 2 : 1;
      
      return Row(
        children: [
          // Products grid
          Expanded(
            flex: productsFlex,
            child: Column(
              children: [
                const RestaurantOrderInfo(showCategories: true), // Catégories sur desktop
                Expanded(
                  child: ProductsGrid(
                    products: productState.filteredProducts,
                    onProductAdd: _handleProductAdd,
                    onProductDetails: _handleProductDetails,
                  ),
                ),
              ],
            ),
          ),
          // Order panel
          Expanded(
            flex: orderPanelFlex,
            child: OrderPanel(),
          ),
        ],
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        body: Column(
          children: [
            const RestaurantOrderInfo(), // Types de services sur mobile
            Expanded(
              child: ProductsGrid(
                products: productState.filteredProducts,
                onProductAdd: _handleProductAdd,
                onProductDetails: _handleProductDetails,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingState(BuildContext context, FThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des produits...',
            style: theme.typography.base.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, FThemeData theme) {
    return Center(
      child: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colors.destructive,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            FButton(
              key: const Key('Réessayer'),
              prefix: const Icon(Icons.refresh),
              onPress: () {
                ref.read(productProvider.notifier).loadProducts();
              },
              style: FButtonStyle.primary(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartFab(BuildContext context, CartState cartState, FThemeData theme) {
    return Semantics(
      label: 'Aller au paiement, ${cartState.items.length} articles',
      button: true,
      child: FloatingActionButton.extended(
        onPressed: () => _goToPayment(context, cartState),
        backgroundColor: theme.colors.primary,
        icon: const Icon(FIcons.shoppingCart),
        label: Row(
          children: [
            Text(
              '${cartState.items.length}',
              style: theme.typography.base.copyWith(
                color: theme.colors.background,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Payer',
              style: theme.typography.base.copyWith(
                color: theme.colors.background,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToPayment(BuildContext context, CartState cartState) async {
    // Vérifier l'état de la caisse
    final cashRegisterState = ref.read(cashRegisterProvider);
    final cashRegisterService = CashRegisterService();
    final localRegister = cashRegisterService.getCurrentRegister();
    
    final hasRegister = (cashRegisterState.currentRegister != null && cashRegisterState.canSell) ||
                        (localRegister != null && localRegister.status == 'open');
    
    // Si aucune caisse n'est ouverte, afficher le dialog
    if (!hasRegister) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ForceOpenRegisterDialog(),
      );
      
      if (result != true) {
        return;
      }
      
      await ref.read(cashRegisterProvider.notifier).loadCurrentRegister();
      return;
    }
    
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le panier est vide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Naviguer directement vers la page de paiement
    await Navigator.of(context, rootNavigator: true).pushNamed(
      '/payment',
      arguments: cartState.total,
    );
  }

  Future<void> _handleProductAdd(Product product) async {
    // Vérifier si le produit a un prix défini
    if (!product.hasPrice) {
      // Afficher le dialog de saisie de prix
      final price = await showDialog<double>(
        context: context,
        builder: (context) => PriceInputDialog(
          productName: product.name,
          currentPrice: product.price,
        ),
      );

      if (price == null || price <= 0) {
        // L'utilisateur a annulé ou n'a pas entré de prix valide
        return;
      }

      // Créer une copie du produit avec le prix saisi
      final productWithPrice = product.copyWith(price: price);
      ref.read(cartProvider.notifier).addItem(productWithPrice);
    } else {
      // Permettre les ventes même avec stock négatif ou zéro (le backend le supporte)
      // Add to cart
      ref.read(cartProvider.notifier).addItem(product);
    }

    // Play sound feedback (le bip remplace le message)
    BeepService().playSuccess();
  }

  void _handleProductDetails(Product product) {
    // Show product details dialog
    showDialog(
      context: context,
      builder: (context) => _buildProductDetailsDialog(context, product),
    );
  }

  Widget _buildProductDetailsDialog(BuildContext context, Product product) {
    final theme = FTheme.of(context);

    return AlertDialog(
      title: Text(product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.description != null) ...[
            Text(
              product.description!,
              style: theme.typography.sm,
            ),
            const SizedBox(height: 16),
          ],
          _buildDetailRow('SKU', product.sku, theme),
          const SizedBox(height: 8),
          _buildDetailRow('Prix', product.formattedPrice, theme),
          const SizedBox(height: 8),
          _buildDetailRow('Stock', '${product.stock}', theme),
          if (product.minStock != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Stock minimum', '${product.minStock}', theme),
          ],
        ],
      ),
      actions: [
        FButton(
          onPress: () => Navigator.of(context).pop(),
          style: FButtonStyle.outline(),
          child: const Text('Fermer'),
        ),
        FButton(
          onPress: () {
            _handleProductAdd(product);
            Navigator.of(context).pop();
          },
          style: FButtonStyle.primary(),
          child: const Text('Ajouter au panier'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, FThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showOrderPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OrderPanelCompact(),
    );
  }

  void _handleNavigation(String route) {
    setState(() {
      _currentRoute = route;
    });

    // Close drawer if mobile
    if (!Responsive.isDesktop(context)) {
      Navigator.of(context).pop();
    }

    // Navigate to route
    if (route == '/pos') {
      // Already on POS page, do nothing
      return;
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
