// lib/core/constants.dart
// Configuration constants for IntegralPOS application

class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.integralpos.com/api';
  static const String apiVersion = '/v1';
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String baseUrl = 'http://192.168.11.107:8000/api';
  // Application
  static const String appName = 'IntegralPOS';
  static const String appVersion = '1.0.2';

  // Locale & Currency
  static const String defaultLocale = 'fr';
  static const String defaultCurrency = 'XOF';
  static const String currencySymbol = 'FCFA';

  // Printer Configuration
  static const bool printerStubEnabled = true;
  static const int escPosCharsPerLine = 48;
  static const int escPosCharsPerLineNarrow = 32;


  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String deviceIdKey = 'device_id';
  static const String userKey = 'user_data';
  static const String businessTypeKey = 'business_type';
  static const String darkModeKey = 'dark_mode';
  static const String currentCashRegisterKey = 'current_cash_register';

  // Hive Box Names
  static const String productsBox = 'products';
  static const String salesBox = 'sales';
  static const String salesPendingBox = 'sales_pending';
  static const String syncQueueBox = 'sync_queue';
  static const String settingsBox = 'settings';
  static const String customersBox = 'customers';
  static const String cashRegistersBox = 'cash_registers';
  static const String cashMovementsBox = 'cash_movements';
  static const String employeesBox = 'employees';

  // PIN Configuration
  static const int pinLength = 4;
  static const int maxPinAttempts = 5;
  static const int pinLockoutDurationSeconds = 30;
  static const int inactivityTimeoutSeconds = 60; // 1 minute d'inactivité

  // Sync Configuration
  static const int syncRetryMaxCount = 3;
  static const int syncRetryBaseDelayMs = 1000;

  // Tax Rates (examples)
  static const double defaultTaxRate = 18.0; // 18%
  static const double zeroTaxRate = 0.0;

  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double baseSpacing = 8.0;
  static const double cardElevation = 2.0;
  static const double minTouchTarget = 44.0;

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  // Grid Columns
  static const int gridColumnsMobile = 2;
  static const int gridColumnsTablet = 3;
  static const int gridColumnsDesktop = 4;
  static const int gridColumnsDesktopLarge = 6;

  // API Endpoints - Authentication
  static String get authLoginEndpoint => '$baseUrl/auth/login';
  static String get authRegisterEndpoint => '$baseUrl/auth/register';
  static String get authLogoutEndpoint => '$baseUrl/auth/logout';
  static String get authMeEndpoint => '$baseUrl/auth/me';
  static String get authRefreshEndpoint => '$baseUrl/auth/refresh';

  // API Endpoints - Onboarding
  static String get onboardingCompanyEndpoint => '$baseUrl/onboarding/company';
  static String get onboardingWarehouseEndpoint => '$baseUrl/onboarding/warehouse';
  static String get onboardingUserWarehouseEndpoint => '$baseUrl/onboarding/user-warehouse';

  // API Endpoints - Companies
  static String get companiesEndpoint => '$baseUrl/companies';
  static String companyEndpoint(String id) => '$companiesEndpoint/$id';

  // API Endpoints - Warehouses
  static String warehousesEndpoint(String companyId) => '$baseUrl/$companyId/warehouses';
  static String warehouseEndpoint(String companyId, String warehouseId) => '$baseUrl/$companyId/warehouses/$warehouseId';
  static String get warehouseTypesEndpoint => '$baseUrl/warehousetype';
  static String warehouseTypeEndpoint(String warehouseId) => '$baseUrl/$warehouseId/warehousetype';
  static String addWarehouseTypeEndpoint(String companyId, String warehouseId) => '$baseUrl/$companyId/warehouses/$warehouseId/warehousetype';

  // API Endpoints - Devices
  static String deviceRegistrationEndpoint(String warehouseId) => '$baseUrl$apiVersion/devices/register';
  static String devicesEndpoint(String companyId, String warehouseId) => '$baseUrl/$companyId/warehouses/$warehouseId/devices';
  static String deviceEndpoint(String companyId, String warehouseId, String deviceId) => '$baseUrl/$companyId/warehouses/$warehouseId/devices/$deviceId';

  // API Endpoints - Categories
  static String categoriesEndpoint(String warehouseId) => '$baseUrl/$warehouseId/categories';
  static String categoryEndpoint(String id) => '$baseUrl/categories/$id';
  static String get createCategoryEndpoint => '$baseUrl/categories';

  // API Endpoints - Employees
  static String get employeesEndpoint => '$baseUrl/employees';
  static String employeeEndpoint(String id) => '$employeesEndpoint/$id';

  // API Endpoints - Products
  static String productsEndpoint(String companyId, String warehouseId) => '$baseUrl/$warehouseId/products';
  static String productEndpoint(String companyId, String warehouseId, String id) => '$baseUrl/$warehouseId/products/$id';

  // API Endpoints - Inventory Movements
  static String inventoryMovementsEndpoint(String companyId, String warehouseId) => '$baseUrl/$companyId/warehouses/$warehouseId/inventory-movements';
  static String inventoryMovementEndpoint(String companyId, String warehouseId, String id) => '$baseUrl/$companyId/warehouses/$warehouseId/inventory-movements/$id';

  // API Endpoints - Customers
  static String get customersEndpoint => '$baseUrl/customers';
  static String customerEndpoint(String id) => '$customersEndpoint/$id';

  // API Endpoints - Sales
  static String get salesEndpoint => '$baseUrl/sales';
  static String saleEndpoint(String id) => '$salesEndpoint/$id';

  // API Endpoints - Cash Registers
  static String get cashRegistersEndpoint => '$baseUrl/cash-registers';
  static String get activeCashRegisterEndpoint => '$cashRegistersEndpoint/active';
  static String get openCashRegisterEndpoint => '$cashRegistersEndpoint/open';
  static String cashRegisterEndpoint(String id) => '$cashRegistersEndpoint/$id';
  static String closeCashRegisterEndpoint(String id) => '$cashRegistersEndpoint/$id/close';
  static String cashRegisterSummaryEndpoint(String id) => '$cashRegistersEndpoint/$id/summary';
  static String cashRegisterMovementsEndpoint(String id) => '$cashRegistersEndpoint/$id/movements';
  static String get dailySummaryEndpoint => '$cashRegistersEndpoint/daily-summary';

  // API Endpoints - Cash Movements
  static String get cashMovementsEndpoint => '$baseUrl/cash-movements';
  static String get cashMovementsByPeriodEndpoint => '$cashMovementsEndpoint/by-period';
  static String get cashMovementsByPaymentMethodEndpoint => '$cashMovementsEndpoint/by-payment-method';
  static String get cashMovementsSalesEndpoint => '$cashMovementsEndpoint/sales';
  static String get cashMovementsManualEndpoint => '$cashMovementsEndpoint/manual';
  static String cashMovementEndpoint(String id) => '$cashMovementsEndpoint/$id';

  // API Endpoints - Sync
  static String get syncStartEndpoint => '$baseUrl/sync/start';
  static String syncStreamEndpoint(String session) => '$baseUrl/sync/stream/$session';
  static String get syncPushEndpoint => '$baseUrl/sync/push';
  static String get syncPullEndpoint => '$baseUrl/sync/pull';
  static String syncStatusEndpoint(String session) => '$baseUrl/sync/status/$session';
  static String get syncConflictsEndpoint => '$baseUrl/sync/conflicts';
  static String resolveConflictEndpoint(String conflict) => '$baseUrl/sync/conflicts/$conflict/resolve';
  static String get syncStatsEndpoint => '$baseUrl/sync/stats';
  static String get syncForceFullEndpoint => '$baseUrl/sync/force-full';

  // API Endpoints - Kitchen/Tickets
  static String kitchenTicketsEndpoint(String warehouseId) => '$baseUrl/$warehouseId/kitchen/tickets';
  static String kitchenTicketEndpoint(String warehouseId, String ticketId) => '$baseUrl/$warehouseId/kitchen/tickets/$ticketId';

  // API Endpoints - Tables
  static String tablesEndpoint(String warehouseId) => '$baseUrl/$warehouseId/tables';
  static String tableEndpoint(String warehouseId, String tableId) => '$baseUrl/$warehouseId/tables/$tableId';
  static String occupyTableEndpoint(String warehouseId, String tableId) => '$baseUrl/$warehouseId/tables/$tableId/occupy';
  static String releaseTableEndpoint(String warehouseId, String tableId) => '$baseUrl/$warehouseId/tables/$tableId/release';

  // API Endpoints - Credit Notes
  static String creditNotesEndpoint(String warehouseId) => '$baseUrl/$warehouseId/credit-notes';
  static String creditNoteEndpoint(String warehouseId, String id) => '${creditNotesEndpoint(warehouseId)}/$id';
  static String applyCreditNoteEndpoint(String warehouseId, String id) => '${creditNotesEndpoint(warehouseId)}/$id/apply';

  // API Endpoints - Tabs (Additions)
  static String tabsEndpoint(String warehouseId) => '$baseUrl/$warehouseId/tabs';
  static String tabEndpoint(String warehouseId, String id) => '${tabsEndpoint(warehouseId)}/$id';
  static String settleTabEndpoint(String warehouseId, String id) => '${tabsEndpoint(warehouseId)}/$id/settle';

  // API Endpoints - Refunds
  static String refundsEndpoint(String warehouseId) => '$baseUrl/$warehouseId/refunds';
  static String refundEndpoint(String warehouseId, String id) => '${refundsEndpoint(warehouseId)}/$id';
  static String processRefundEndpoint(String warehouseId, String refundId) => '${refundsEndpoint(warehouseId)}/$refundId/process';

  // API Endpoints - Stock Adjustments
  static String stockAdjustmentsEndpoint(String warehouseId) => '$baseUrl/$warehouseId/stock-adjustments';
  static String stockAdjustmentEndpoint(String warehouseId, String id) => '${stockAdjustmentsEndpoint(warehouseId)}/$id';
  static String completeStockAdjustmentEndpoint(String warehouseId, String adjustmentId) => '${stockAdjustmentsEndpoint(warehouseId)}/$adjustmentId/complete';

  // Helper Methods (legacy - use specific endpoint methods above)
  // static String productEndpoint(String id) => '$productsEndpoint/$id';
  // static String customerEndpoint(String id) => '$customersEndpoint/$id';
  // static String saleEndpoint(String id) => '$salesEndpoint/$id';
  // static String cashRegisterEndpoint(String id) => '$cashRegistersEndpoint/$id';
}