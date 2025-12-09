// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SalesNotifier)
const salesProvider = SalesNotifierProvider._();

final class SalesNotifierProvider
    extends $NotifierProvider<SalesNotifier, SalesState> {
  const SalesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesNotifierHash();

  @$internal
  @override
  SalesNotifier create() => SalesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SalesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SalesState>(value),
    );
  }
}

String _$salesNotifierHash() => r'40c9a751c1acd466227857c30e1b4c6e70c4070d';

abstract class _$SalesNotifier extends $Notifier<SalesState> {
  SalesState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SalesState, SalesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SalesState, SalesState>,
              SalesState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
