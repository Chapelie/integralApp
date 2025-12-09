// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waiter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for WaiterService

@ProviderFor(waiterService)
const waiterServiceProvider = WaiterServiceProvider._();

/// Provider for WaiterService

final class WaiterServiceProvider
    extends $FunctionalProvider<WaiterService, WaiterService, WaiterService>
    with $Provider<WaiterService> {
  /// Provider for WaiterService
  const WaiterServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waiterServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waiterServiceHash();

  @$internal
  @override
  $ProviderElement<WaiterService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WaiterService create(Ref ref) {
    return waiterService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WaiterService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WaiterService>(value),
    );
  }
}

String _$waiterServiceHash() => r'b270afe770159a5a69d118603a7b035578b23592';

/// Provider for all waiters

@ProviderFor(WaiterList)
const waiterListProvider = WaiterListProvider._();

/// Provider for all waiters
final class WaiterListProvider
    extends $AsyncNotifierProvider<WaiterList, List<Waiter>> {
  /// Provider for all waiters
  const WaiterListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waiterListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waiterListHash();

  @$internal
  @override
  WaiterList create() => WaiterList();
}

String _$waiterListHash() => r'3244f368daff846a6393f37083b26beba9629be7';

/// Provider for all waiters

abstract class _$WaiterList extends $AsyncNotifier<List<Waiter>> {
  FutureOr<List<Waiter>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Waiter>>, List<Waiter>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Waiter>>, List<Waiter>>,
              AsyncValue<List<Waiter>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for active waiters

@ProviderFor(activeWaiters)
const activeWaitersProvider = ActiveWaitersProvider._();

/// Provider for active waiters

final class ActiveWaitersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Waiter>>,
          List<Waiter>,
          FutureOr<List<Waiter>>
        >
    with $FutureModifier<List<Waiter>>, $FutureProvider<List<Waiter>> {
  /// Provider for active waiters
  const ActiveWaitersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWaitersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWaitersHash();

  @$internal
  @override
  $FutureProviderElement<List<Waiter>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Waiter>> create(Ref ref) {
    return activeWaiters(ref);
  }
}

String _$activeWaitersHash() => r'352ce70c34073f815e8d9b480b17eeef6ae767d9';

/// Provider for waiter by ID

@ProviderFor(waiterById)
const waiterByIdProvider = WaiterByIdFamily._();

/// Provider for waiter by ID

final class WaiterByIdProvider
    extends $FunctionalProvider<AsyncValue<Waiter?>, Waiter?, FutureOr<Waiter?>>
    with $FutureModifier<Waiter?>, $FutureProvider<Waiter?> {
  /// Provider for waiter by ID
  const WaiterByIdProvider._({
    required WaiterByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'waiterByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$waiterByIdHash();

  @override
  String toString() {
    return r'waiterByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Waiter?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Waiter?> create(Ref ref) {
    final argument = this.argument as String;
    return waiterById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WaiterByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$waiterByIdHash() => r'4e06500fe268f045a0f2353aa3429364891ef680';

/// Provider for waiter by ID

final class WaiterByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Waiter?>, String> {
  const WaiterByIdFamily._()
    : super(
        retry: null,
        name: r'waiterByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for waiter by ID

  WaiterByIdProvider call(String waiterId) =>
      WaiterByIdProvider._(argument: waiterId, from: this);

  @override
  String toString() => r'waiterByIdProvider';
}
