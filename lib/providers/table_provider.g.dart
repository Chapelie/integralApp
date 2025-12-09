// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for TableService

@ProviderFor(tableService)
const tableServiceProvider = TableServiceProvider._();

/// Provider for TableService

final class TableServiceProvider
    extends $FunctionalProvider<TableService, TableService, TableService>
    with $Provider<TableService> {
  /// Provider for TableService
  const TableServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tableServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tableServiceHash();

  @$internal
  @override
  $ProviderElement<TableService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TableService create(Ref ref) {
    return tableService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TableService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TableService>(value),
    );
  }
}

String _$tableServiceHash() => r'c34ab4351ffac5f6ac147ca654c98c5df1463b7f';

/// Provider for all tables

@ProviderFor(TableList)
const tableListProvider = TableListProvider._();

/// Provider for all tables
final class TableListProvider
    extends $AsyncNotifierProvider<TableList, List<RestaurantTable>> {
  /// Provider for all tables
  const TableListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tableListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tableListHash();

  @$internal
  @override
  TableList create() => TableList();
}

String _$tableListHash() => r'5c88b7a0fd501803780439bf88a8d3522340505c';

/// Provider for all tables

abstract class _$TableList extends $AsyncNotifier<List<RestaurantTable>> {
  FutureOr<List<RestaurantTable>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<RestaurantTable>>, List<RestaurantTable>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<RestaurantTable>>,
                List<RestaurantTable>
              >,
              AsyncValue<List<RestaurantTable>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for available tables

@ProviderFor(availableTables)
const availableTablesProvider = AvailableTablesProvider._();

/// Provider for available tables

final class AvailableTablesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RestaurantTable>>,
          List<RestaurantTable>,
          FutureOr<List<RestaurantTable>>
        >
    with
        $FutureModifier<List<RestaurantTable>>,
        $FutureProvider<List<RestaurantTable>> {
  /// Provider for available tables
  const AvailableTablesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableTablesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableTablesHash();

  @$internal
  @override
  $FutureProviderElement<List<RestaurantTable>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RestaurantTable>> create(Ref ref) {
    return availableTables(ref);
  }
}

String _$availableTablesHash() => r'ae84e5ac70bd1bb34d3dd23aaea133153b2f3e2b';

/// Provider for occupied tables

@ProviderFor(occupiedTables)
const occupiedTablesProvider = OccupiedTablesProvider._();

/// Provider for occupied tables

final class OccupiedTablesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RestaurantTable>>,
          List<RestaurantTable>,
          FutureOr<List<RestaurantTable>>
        >
    with
        $FutureModifier<List<RestaurantTable>>,
        $FutureProvider<List<RestaurantTable>> {
  /// Provider for occupied tables
  const OccupiedTablesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'occupiedTablesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$occupiedTablesHash();

  @$internal
  @override
  $FutureProviderElement<List<RestaurantTable>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RestaurantTable>> create(Ref ref) {
    return occupiedTables(ref);
  }
}

String _$occupiedTablesHash() => r'95b1a8c7caa048bc067a778d8306c74c8fa5abc4';

/// Provider for table statistics

@ProviderFor(tableStatistics)
const tableStatisticsProvider = TableStatisticsProvider._();

/// Provider for table statistics

final class TableStatisticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  /// Provider for table statistics
  const TableStatisticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tableStatisticsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tableStatisticsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return tableStatistics(ref);
  }
}

String _$tableStatisticsHash() => r'0ef2fa446c7221473d437a6a607fb2bf1401d201';

/// Provider for tables by waiter

@ProviderFor(tablesByWaiter)
const tablesByWaiterProvider = TablesByWaiterFamily._();

/// Provider for tables by waiter

final class TablesByWaiterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RestaurantTable>>,
          List<RestaurantTable>,
          FutureOr<List<RestaurantTable>>
        >
    with
        $FutureModifier<List<RestaurantTable>>,
        $FutureProvider<List<RestaurantTable>> {
  /// Provider for tables by waiter
  const TablesByWaiterProvider._({
    required TablesByWaiterFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tablesByWaiterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tablesByWaiterHash();

  @override
  String toString() {
    return r'tablesByWaiterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RestaurantTable>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RestaurantTable>> create(Ref ref) {
    final argument = this.argument as String;
    return tablesByWaiter(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TablesByWaiterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tablesByWaiterHash() => r'b8a7afe5c47d9c84fd5737b3535111da1d686d8f';

/// Provider for tables by waiter

final class TablesByWaiterFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RestaurantTable>>, String> {
  const TablesByWaiterFamily._()
    : super(
        retry: null,
        name: r'tablesByWaiterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for tables by waiter

  TablesByWaiterProvider call(String waiterId) =>
      TablesByWaiterProvider._(argument: waiterId, from: this);

  @override
  String toString() => r'tablesByWaiterProvider';
}
