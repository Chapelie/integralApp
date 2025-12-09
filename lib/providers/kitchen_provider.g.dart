// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for KitchenService

@ProviderFor(kitchenService)
const kitchenServiceProvider = KitchenServiceProvider._();

/// Provider for KitchenService

final class KitchenServiceProvider
    extends $FunctionalProvider<KitchenService, KitchenService, KitchenService>
    with $Provider<KitchenService> {
  /// Provider for KitchenService
  const KitchenServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kitchenServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kitchenServiceHash();

  @$internal
  @override
  $ProviderElement<KitchenService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KitchenService create(Ref ref) {
    return kitchenService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KitchenService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KitchenService>(value),
    );
  }
}

String _$kitchenServiceHash() => r'3fdd49f5ac9f2102a1a641ca14fcd58afdb5333a';

/// Provider for all kitchen orders

@ProviderFor(KitchenOrderList)
const kitchenOrderListProvider = KitchenOrderListProvider._();

/// Provider for all kitchen orders
final class KitchenOrderListProvider
    extends $AsyncNotifierProvider<KitchenOrderList, List<KitchenOrder>> {
  /// Provider for all kitchen orders
  const KitchenOrderListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kitchenOrderListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kitchenOrderListHash();

  @$internal
  @override
  KitchenOrderList create() => KitchenOrderList();
}

String _$kitchenOrderListHash() => r'7511517076803d53cc46e65c30f4f4eec735e3ef';

/// Provider for all kitchen orders

abstract class _$KitchenOrderList extends $AsyncNotifier<List<KitchenOrder>> {
  FutureOr<List<KitchenOrder>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<KitchenOrder>>, List<KitchenOrder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<KitchenOrder>>, List<KitchenOrder>>,
              AsyncValue<List<KitchenOrder>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for active kitchen orders

@ProviderFor(activeKitchenOrders)
const activeKitchenOrdersProvider = ActiveKitchenOrdersProvider._();

/// Provider for active kitchen orders

final class ActiveKitchenOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KitchenOrder>>,
          List<KitchenOrder>,
          FutureOr<List<KitchenOrder>>
        >
    with
        $FutureModifier<List<KitchenOrder>>,
        $FutureProvider<List<KitchenOrder>> {
  /// Provider for active kitchen orders
  const ActiveKitchenOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeKitchenOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeKitchenOrdersHash();

  @$internal
  @override
  $FutureProviderElement<List<KitchenOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KitchenOrder>> create(Ref ref) {
    return activeKitchenOrders(ref);
  }
}

String _$activeKitchenOrdersHash() =>
    r'3cd7f8c79878da982aa7a10819bec24d4aa80b82';

/// Provider for orders by status

@ProviderFor(ordersByStatus)
const ordersByStatusProvider = OrdersByStatusFamily._();

/// Provider for orders by status

final class OrdersByStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KitchenOrder>>,
          List<KitchenOrder>,
          FutureOr<List<KitchenOrder>>
        >
    with
        $FutureModifier<List<KitchenOrder>>,
        $FutureProvider<List<KitchenOrder>> {
  /// Provider for orders by status
  const OrdersByStatusProvider._({
    required OrdersByStatusFamily super.from,
    required KitchenOrderStatus super.argument,
  }) : super(
         retry: null,
         name: r'ordersByStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ordersByStatusHash();

  @override
  String toString() {
    return r'ordersByStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<KitchenOrder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KitchenOrder>> create(Ref ref) {
    final argument = this.argument as KitchenOrderStatus;
    return ordersByStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrdersByStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ordersByStatusHash() => r'ecf3cc0fdd9dd60e1cb83cea657a4488519e9133';

/// Provider for orders by status

final class OrdersByStatusFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<KitchenOrder>>,
          KitchenOrderStatus
        > {
  const OrdersByStatusFamily._()
    : super(
        retry: null,
        name: r'ordersByStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for orders by status

  OrdersByStatusProvider call(KitchenOrderStatus status) =>
      OrdersByStatusProvider._(argument: status, from: this);

  @override
  String toString() => r'ordersByStatusProvider';
}

/// Provider for kitchen statistics

@ProviderFor(kitchenStatistics)
const kitchenStatisticsProvider = KitchenStatisticsProvider._();

/// Provider for kitchen statistics

final class KitchenStatisticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  /// Provider for kitchen statistics
  const KitchenStatisticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kitchenStatisticsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kitchenStatisticsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return kitchenStatistics(ref);
  }
}

String _$kitchenStatisticsHash() => r'0c8d6b6522d2691fa0d4f991592528d7bfc294c8';

/// Provider for order by sale ID

@ProviderFor(orderBySaleId)
const orderBySaleIdProvider = OrderBySaleIdFamily._();

/// Provider for order by sale ID

final class OrderBySaleIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<KitchenOrder?>,
          KitchenOrder?,
          FutureOr<KitchenOrder?>
        >
    with $FutureModifier<KitchenOrder?>, $FutureProvider<KitchenOrder?> {
  /// Provider for order by sale ID
  const OrderBySaleIdProvider._({
    required OrderBySaleIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderBySaleIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderBySaleIdHash();

  @override
  String toString() {
    return r'orderBySaleIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<KitchenOrder?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<KitchenOrder?> create(Ref ref) {
    final argument = this.argument as String;
    return orderBySaleId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderBySaleIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderBySaleIdHash() => r'38aede68df1964584b9ed24f3f3f7ab316d59490';

/// Provider for order by sale ID

final class OrderBySaleIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<KitchenOrder?>, String> {
  const OrderBySaleIdFamily._()
    : super(
        retry: null,
        name: r'orderBySaleIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for order by sale ID

  OrderBySaleIdProvider call(String saleId) =>
      OrderBySaleIdProvider._(argument: saleId, from: this);

  @override
  String toString() => r'orderBySaleIdProvider';
}
