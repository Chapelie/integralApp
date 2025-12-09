// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_register_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CashRegisterNotifier)
const cashRegisterProvider = CashRegisterNotifierProvider._();

final class CashRegisterNotifierProvider
    extends $NotifierProvider<CashRegisterNotifier, CashRegisterState> {
  const CashRegisterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cashRegisterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cashRegisterNotifierHash();

  @$internal
  @override
  CashRegisterNotifier create() => CashRegisterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CashRegisterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CashRegisterState>(value),
    );
  }
}

String _$cashRegisterNotifierHash() =>
    r'8e6aa93a024be5636a859f6115e30b5cb97f646d';

abstract class _$CashRegisterNotifier extends $Notifier<CashRegisterState> {
  CashRegisterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CashRegisterState, CashRegisterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CashRegisterState, CashRegisterState>,
              CashRegisterState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
