import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/business_config.dart';
import '../../../providers/auth_provider.dart';

class HamburgerMenu extends StatefulWidget {
  final String? currentRoute;
  final Function(String)? onNavigate;

  const HamburgerMenu({
    super.key,
    this.currentRoute,
    this.onNavigate,
  });

  @override
  State<HamburgerMenu> createState() => _HamburgerMenuState();
}

class _HamburgerMenuState extends State<HamburgerMenu> {
  List<MenuItemData> _buildItems() {
    final businessConfig = BusinessConfig();
    final items = <MenuItemData>[
      MenuItemData(
        icon: FIcons.shoppingBag,
        activeIcon: FIcons.shoppingBag,
        label: 'Ventes',
        route: '/pos',
        semanticLabel: 'Naviguer vers Ventes',
      ),
      // Restaurant-specific: Tables
      if (businessConfig.isFeatureEnabled('enableTables'))
        MenuItemData(
          icon: Icons.table_restaurant,
          activeIcon: Icons.table_restaurant,
          label: 'Tables',
          route: '/tables',
          semanticLabel: 'Naviguer vers Tables',
        ),
      // Restaurant-specific: Personnel (serveurs)
      if (businessConfig.isFeatureEnabled('enableWaiters'))
        MenuItemData(
          icon: FIcons.user,
          activeIcon: FIcons.user,
          label: 'Personnel',
          route: '/waiters',
          semanticLabel: 'Naviguer vers Personnel',
        ),
      // Restaurant-specific: Cuisine
      if (businessConfig.isFeatureEnabled('enableKitchen'))
        MenuItemData(
          icon: FIcons.chefHat,
          activeIcon: FIcons.chefHat,
          label: 'Cuisine',
          route: '/kitchen',
          semanticLabel: 'Naviguer vers Cuisine',
        ),
      MenuItemData(
        icon: FIcons.package,
        activeIcon: FIcons.package,
        label: 'Produits',
        route: '/products',
        semanticLabel: 'Naviguer vers Produits',
      ),
      if (businessConfig.isFeatureEnabled('enableInventory'))
        MenuItemData(
          icon: FIcons.box,
          activeIcon: FIcons.box,
          label: 'Stock',
          route: '/inventory',
          semanticLabel: 'Naviguer vers Stock',
        ),
      if (businessConfig.isFeatureEnabled('enableCustomers'))
        MenuItemData(
          icon: FIcons.users,
          activeIcon: FIcons.users,
          label: 'Clients',
          route: '/customers',
          semanticLabel: 'Naviguer vers Clients',
        ),
      MenuItemData(
        icon: FIcons.wallet,
        activeIcon: FIcons.wallet,
        label: 'Caisse',
        route: '/cash-register',
        semanticLabel: 'Naviguer vers Caisse',
      ),
      if (businessConfig.isFeatureEnabled('enableReports'))
        MenuItemData(
          icon: FIcons.fileText,
          activeIcon: FIcons.fileText,
          label: 'Rapports',
          route: '/reports',
          semanticLabel: 'Naviguer vers Rapports',
        ),
      MenuItemData(
        icon: FIcons.calculator,
        activeIcon: FIcons.calculator,
        label: 'Comptabilisation',
        route: '/accounting',
        semanticLabel: 'Naviguer vers Comptabilisation',
      ),
      MenuItemData(
        icon: FIcons.settings,
        activeIcon: FIcons.settings,
        label: 'Paramètres',
        route: '/settings',
        semanticLabel: 'Naviguer vers Paramètres',
      ),
      MenuItemData(
        icon: Icons.receipt,
        activeIcon: Icons.receipt,
        label: 'Reçus',
        route: '/receipts',
        semanticLabel: 'Naviguer vers Reçus',
      ),
      MenuItemData(
        icon: Icons.receipt_long,
        activeIcon: Icons.receipt_long,
        label: 'Additions',
        route: '/tabs',
        semanticLabel: 'Naviguer vers Additions',
      ),
      MenuItemData(
        icon: Icons.credit_card,
        activeIcon: Icons.credit_card,
        label: 'Avoirs',
        route: '/credit-notes',
        semanticLabel: 'Naviguer vers Avoirs',
      ),
    ];
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Drawer(
      child: Container(
        color: theme.colors.background,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: BoxDecoration(
                color: theme.colors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/IntegralPOS.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                FIcons.store,
                                color: theme.colors.primary,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Système de caisse',
                    style: theme.typography.sm.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _buildItems().map((item) => _buildMenuItem(context, item)).toList(),
              ),
            ),

            // Divider
            Divider(
              height: 1,
              color: theme.colors.border,
            ),

            // User Info (real user data)
            Consumer(
              builder: (context, ref, _) {
                final authState = ref.watch(authProvider);
                final user = authState.user;
                final userName = user?.name ?? user?.email ?? 'Utilisateur';
                final userEmail = user?.email;
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          FIcons.user,
                          size: 24,
                          color: theme.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.typography.base.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (userEmail != null)
                              Text(
                                userEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(FIcons.logOut),
                        onPressed: () {
                          // TODO: implement logout via auth provider
                        },
                        tooltip: 'Déconnexion',
                      ),
                    ],
                  ),
                );
              },
            ),

            // Version
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Version 1.0.0',
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItemData item) {
    final theme = FTheme.of(context);
    final isActive = widget.currentRoute == item.route;

    return Semantics(
      label: item.semanticLabel,
      button: true,
      selected: isActive,
      child: ListTile(
        leading: Icon(
          isActive ? item.activeIcon : item.icon,
          size: 24,
          color: isActive
              ? theme.colors.primary
              : theme.colors.foreground,
        ),
        title: Text(
          item.label,
          style: theme.typography.base.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? theme.colors.primary
                : theme.colors.foreground,
          ),
        ),
        selected: isActive,
        selectedTileColor: theme.colors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () async {
          // Fermer le drawer d'abord
          Navigator.of(context).pop();
          
          // Petit délai pour s'assurer que le drawer est fermé
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Puis naviguer
          if (widget.onNavigate != null) {
            widget.onNavigate!(item.route);
          }
        },
      ),
    );
  }
}

class MenuItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String semanticLabel;

  MenuItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.semanticLabel,
  });
}
