// lib/widgets/app_shell.dart
// Shell principal de l'application avec IndexedStack pour préserver l'état

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../features/pos/pos_page.dart';
import '../features/products/products_page.dart';
import '../features/customers/customer_list_page.dart';
import '../features/products/stock_management_page.dart';
import '../features/employees/employees_page.dart';
import '../features/cash_register/cash_register_page.dart';
import '../features/reports/reports_page.dart';
import '../features/sales/receipts_page.dart';
import '../features/accounting/accounting_page.dart';
import '../features/settings/settings_page.dart';
import '../features/restaurant/tables_page.dart';
import '../features/restaurant/waiters_page.dart';
import '../features/restaurant/kitchen_page.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final currentRoute = navigationState.currentRoute;

    // Créer toutes les pages (elles seront préservées en mémoire)
    final pages = [
      // Index 0: PosPage
      const PosPage(),
      // Index 1: ProductsPage
      const ProductsPage(),
      // Index 2: CustomerListPage
      const CustomerListPage(),
      // Index 3: InventoryPage (remplacé par StockManagementPage pour la gestion)
      const StockManagementPage(),
      // Index 4: EmployeesPage
      const EmployeesPage(),
      // Index 5: CashRegisterPage
      const CashRegisterPage(),
      // Index 6: ReportsPage
      const ReportsPage(),
      // Index 7: ReceiptsPage
      const ReceiptsPage(),
      // Index 8: AccountingPage
      const AccountingPage(),
      // Index 9: SettingsPage
      const SettingsPage(),
      // Index 10: TablesPage
      const TablesPage(),
      // Index 11: WaitersPage
      const WaitersPage(),
      // Index 12: KitchenPage
      const KitchenPage(),
    ];

    // Obtenir l'index de la route actuelle
    final currentIndex = _getRouteIndex(currentRoute);

    // Utiliser IndexedStack pour préserver l'état de toutes les pages
    return IndexedStack(
      index: currentIndex,
      children: pages,
    );
  }

  int _getRouteIndex(AppRoute route) {
    switch (route) {
      case AppRoute.pos:
        return 0;
      case AppRoute.products:
        return 1;
      case AppRoute.customers:
        return 2;
      case AppRoute.inventory:
        return 3;
      case AppRoute.employees:
        return 4;
      case AppRoute.cashRegister:
        return 5;
      case AppRoute.reports:
        return 6;
      case AppRoute.receipts:
        return 7;
      case AppRoute.accounting:
        return 8;
      case AppRoute.settings:
        return 9;
      case AppRoute.tables:
        return 10;
      case AppRoute.waiters:
        return 11;
      case AppRoute.kitchen:
        return 12;
    }
  }
}

