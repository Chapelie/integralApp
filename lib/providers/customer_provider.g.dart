// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CustomerNotifier)
const customerProvider = CustomerNotifierProvider._();

final class CustomerNotifierProvider
    extends $NotifierProvider<CustomerNotifier, CustomerState> {
  const CustomerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerNotifierHash();

  @$internal
  @override
  CustomerNotifier create() => CustomerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomerState>(value),
    );
  }
}

String _$customerNotifierHash() => r'9f793864f64628418d5441f94d03c82c6d8da0b2';

abstract class _$CustomerNotifier extends $Notifier<CustomerState> {
  CustomerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CustomerState, CustomerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CustomerState, CustomerState>,
              CustomerState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
