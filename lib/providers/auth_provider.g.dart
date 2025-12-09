// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthNotifier)
const authProvider = AuthNotifierProvider._();

final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, AuthProviderState> {
  const AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthProviderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthProviderState>(value),
    );
  }
}

String _$authNotifierHash() => r'ec6c94d6712281cc5b67735715da32c55d090722';

abstract class _$AuthNotifier extends $Notifier<AuthProviderState> {
  AuthProviderState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AuthProviderState, AuthProviderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthProviderState, AuthProviderState>,
              AuthProviderState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
