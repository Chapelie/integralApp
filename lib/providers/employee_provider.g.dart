// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EmployeeNotifier)
const employeeProvider = EmployeeNotifierProvider._();

final class EmployeeNotifierProvider
    extends $NotifierProvider<EmployeeNotifier, EmployeeState> {
  const EmployeeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'employeeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$employeeNotifierHash();

  @$internal
  @override
  EmployeeNotifier create() => EmployeeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmployeeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmployeeState>(value),
    );
  }
}

String _$employeeNotifierHash() => r'39ccbf0ad5db2f44cd0ea58edf5e6ef8f6876e8b';

abstract class _$EmployeeNotifier extends $Notifier<EmployeeState> {
  EmployeeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<EmployeeState, EmployeeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EmployeeState, EmployeeState>,
              EmployeeState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
