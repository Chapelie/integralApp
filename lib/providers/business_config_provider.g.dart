// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BusinessConfigNotifier)
const businessConfigProvider = BusinessConfigNotifierProvider._();

final class BusinessConfigNotifierProvider
    extends $NotifierProvider<BusinessConfigNotifier, BusinessConfigState> {
  const BusinessConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'businessConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$businessConfigNotifierHash();

  @$internal
  @override
  BusinessConfigNotifier create() => BusinessConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusinessConfigState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusinessConfigState>(value),
    );
  }
}

String _$businessConfigNotifierHash() =>
    r'b6ff84690da0bb87a7288dfb77fd4d2896fa3f68';

abstract class _$BusinessConfigNotifier extends $Notifier<BusinessConfigState> {
  BusinessConfigState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<BusinessConfigState, BusinessConfigState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BusinessConfigState, BusinessConfigState>,
              BusinessConfigState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
