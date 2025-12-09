// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProductNotifier)
const productProvider = ProductNotifierProvider._();

final class ProductNotifierProvider
    extends $NotifierProvider<ProductNotifier, ProductState> {
  const ProductNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productNotifierHash();

  @$internal
  @override
  ProductNotifier create() => ProductNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductState>(value),
    );
  }
}

String _$productNotifierHash() => r'7b0909c9f0f31f9f9c28112443e6351632685a28';

abstract class _$ProductNotifier extends $Notifier<ProductState> {
  ProductState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ProductState, ProductState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProductState, ProductState>,
              ProductState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
