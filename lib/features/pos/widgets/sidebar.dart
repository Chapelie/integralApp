import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../core/responsive_helper.dart';
import '../../../core/business_config.dart';
import '../../../core/company_warehouse_service.dart';
import '../../../providers/sidebar_provider.dart';
import '../../../providers/auth_provider.dart';

class Sidebar extends ConsumerWidget {
  final String? currentRoute;
  final Function(String)? onNavigate;

  const Sidebar({
    super.key,
    this.currentRoute,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarProvider);
    final theme = FTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    
    final sidebarWidth = isCollapsed ? 80.0 : Responsive.sidebarWidth(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          right: BorderSide(
            color: theme.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header avec logo et bouton collapse
          _buildHeader(context, ref, isCollapsed, theme),
          
          // Navigation items
          Expanded(
            child: _buildNavigationItems(context, ref, isCollapsed, theme),
          ),
          
          // Footer avec informations utilisateur
          _buildFooter(context, ref, isCollapsed, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isCollapsed, FThemeData theme) {
    return Container(
      height: 80,
      padding: EdgeInsets.all(isCollapsed ? 8 : 16),
      child: isCollapsed
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/IntegralPOS.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.point_of_sale,
                          size: 24,
                          color: theme.colors.primary,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton collapse même quand collapsed
                if (MediaQuery.of(context).size.width > 1024)
                  IconButton(
                    onPressed: () {
                      ref.read(sidebarProvider.notifier).toggleCollapse();
                    },
                    icon: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colors.mutedForeground,
                    ),
                    tooltip: 'Développer',
                  ),
              ],
            )
          : Row(
              children: [
                // Logo
                Container(
                  width: 48,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/IntegralPOS.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.point_of_sale,
                          size: 32,
                          color: theme.colors.primary,
                        );
                      },
                    ),
                  ),
                ),
                
                // Bouton collapse (seulement sur desktop)
                if (MediaQuery.of(context).size.width > 1024) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      ref.read(sidebarProvider.notifier).toggleCollapse();
                    },
                    icon: Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: theme.colors.mutedForeground,
                    ),
                    tooltip: 'Réduire',
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildNavigationItems(BuildContext context, WidgetRef ref, bool isCollapsed, FThemeData theme) {
    final businessConfig = BusinessConfig();
    final items = <SidebarItem>[
      SidebarItem(
        icon: Icons.shopping_cart,
        activeIcon: Icons.shopping_cart,
        label: 'Ventes',
        route: '/pos',
        semanticLabel: 'Naviguer vers Ventes',
      ),

      // Restaurant-specific: Tables
      if (businessConfig.isFeatureEnabled('enableTables'))
        SidebarItem(
          icon: Icons.table_restaurant,
          activeIcon: Icons.table_restaurant,
          label: 'Tables',
          route: '/tables',
          semanticLabel: 'Naviguer vers Tables',
        ),

      // Restaurant-specific: Waiters
      if (businessConfig.isFeatureEnabled('enableWaiters'))
        SidebarItem(
          icon: Icons.room_service,
          activeIcon: Icons.room_service,
          label: 'Personnel',
          route: '/waiters',
          semanticLabel: 'Naviguer vers Personnel',
        ),

      // Restaurant-specific: Kitchen
      if (businessConfig.isFeatureEnabled('enableKitchen'))
        SidebarItem(
          icon: Icons.restaurant_menu,
          activeIcon: Icons.restaurant_menu,
          label: 'Cuisine',
          route: '/kitchen',
          semanticLabel: 'Naviguer vers Cuisine',
        ),

      SidebarItem(
        icon: Icons.inventory_2,
        activeIcon: Icons.inventory_2,
        label: 'Produits',
        route: '/products',
        semanticLabel: 'Naviguer vers Produits',
      ),

      if (businessConfig.isFeatureEnabled('enableInventory'))
        SidebarItem(
          icon: Icons.inventory,
          activeIcon: Icons.inventory,
          label: 'Stock',
          route: '/inventory',
          semanticLabel: 'Naviguer vers Stock',
        ),

      if (businessConfig.isFeatureEnabled('enableCustomers'))
        SidebarItem(
          icon: Icons.people,
          activeIcon: Icons.people,
          label: 'Clients',
          route: '/customers',
          semanticLabel: 'Naviguer vers Clients',
        ),

      // Employés retiré côté mobile/desktop selon consigne

      SidebarItem(
        icon: Icons.account_balance_wallet,
        activeIcon: Icons.account_balance_wallet,
        label: 'Caisse',
        route: '/cash-register',
        semanticLabel: 'Naviguer vers Caisse',
      ),

      if (businessConfig.isFeatureEnabled('enableReports'))
        SidebarItem(
          icon: Icons.assessment,
          activeIcon: Icons.assessment,
          label: 'Rapports',
          route: '/reports',
          semanticLabel: 'Naviguer vers Rapports',
        ),

      SidebarItem(
        icon: Icons.account_balance,
        activeIcon: Icons.account_balance,
        label: 'Comptabilisation',
        route: '/accounting',
        semanticLabel: 'Naviguer vers Comptabilisation',
      ),

      SidebarItem(
        icon: Icons.settings,
        activeIcon: Icons.settings,
        label: 'Paramètres',
        route: '/settings',
        semanticLabel: 'Naviguer vers Paramètres',
      ),
      SidebarItem(
        icon: Icons.receipt,
        activeIcon: Icons.receipt,
        label: 'Reçus',
        route: '/receipts',
        semanticLabel: 'Naviguer vers Reçus',
      ),
      SidebarItem(
        icon: Icons.receipt_long,
        activeIcon: Icons.receipt_long,
        label: 'Additions',
        route: '/tabs',
        semanticLabel: 'Naviguer vers Additions',
      ),
      SidebarItem(
        icon: Icons.credit_card,
        activeIcon: Icons.credit_card,
        label: 'Avoirs',
        route: '/credit-notes',
        semanticLabel: 'Naviguer vers Avoirs',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isActive = currentRoute == item.route;
        
        return _buildNavigationItem(
          context,
          ref,
          item,
          isActive,
          isCollapsed,
          theme,
        );
      },
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    WidgetRef ref,
    SidebarItem item,
    bool isActive,
    bool isCollapsed,
    FThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate?.call(item.route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? theme.colors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 20,
                  color: isActive 
                      ? theme.colors.primary 
                      : theme.colors.mutedForeground,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.typography.sm.copyWith(
                        color: isActive 
                            ? theme.colors.primary 
                            : theme.colors.foreground,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, bool isCollapsed, FThemeData theme) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colors.border,
            width: 1,
          ),
        ),
      ),
      child: isCollapsed
          ? Icon(
              Icons.person,
              size: 24,
              color: theme.colors.mutedForeground,
            )
          : FutureBuilder<Map<String, String?>>(
              future: _getUserAndCompanyInfo(),
              builder: (context, snapshot) {
                final userName = user?.name ?? 'Utilisateur';
                final companyName = snapshot.data?['companyName'] ?? 'Compagnie';
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: theme.colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colors.foreground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            companyName,
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  /// Récupère les informations de l'utilisateur et de la compagnie
  Future<Map<String, String?>> _getUserAndCompanyInfo() async {
    try {
      final companyWarehouseService = CompanyWarehouseService();
      final company = await companyWarehouseService.getSelectedCompany();
      
      return {
        'companyName': company?.name,
      };
    } catch (e) {
      print('[Sidebar] Error getting company info: $e');
      return {
        'companyName': null,
      };
    }
  }
}

class SidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String semanticLabel;

  const SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.semanticLabel,
  });
}