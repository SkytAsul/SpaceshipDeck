// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fetchSystem)
final fetchSystemProvider = FetchSystemFamily._();

final class FetchSystemProvider
    extends $FunctionalProvider<AsyncValue<System>, System, FutureOr<System>>
    with $FutureModifier<System>, $FutureProvider<System> {
  FetchSystemProvider._({
    required FetchSystemFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchSystemProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchSystemHash();

  @override
  String toString() {
    return r'fetchSystemProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<System> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<System> create(Ref ref) {
    final argument = this.argument as String;
    return fetchSystem(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchSystemProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchSystemHash() => r'f474b069aec2679a29a587708a1dcaa8035416bf';

final class FetchSystemFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<System>, String> {
  FetchSystemFamily._()
    : super(
        retry: null,
        name: r'fetchSystemProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchSystemProvider call(String symbol) =>
      FetchSystemProvider._(argument: symbol, from: this);

  @override
  String toString() => r'fetchSystemProvider';
}

@ProviderFor(fetchWaypoint)
final fetchWaypointProvider = FetchWaypointFamily._();

final class FetchWaypointProvider
    extends
        $FunctionalProvider<AsyncValue<Waypoint>, Waypoint, FutureOr<Waypoint>>
    with $FutureModifier<Waypoint>, $FutureProvider<Waypoint> {
  FetchWaypointProvider._({
    required FetchWaypointFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchWaypointProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchWaypointHash();

  @override
  String toString() {
    return r'fetchWaypointProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Waypoint> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Waypoint> create(Ref ref) {
    final argument = this.argument as String;
    return fetchWaypoint(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchWaypointProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchWaypointHash() => r'caff2db5644ae24e1d128e59e87f815ae5cd94bc';

final class FetchWaypointFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Waypoint>, String> {
  FetchWaypointFamily._()
    : super(
        retry: null,
        name: r'fetchWaypointProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  FetchWaypointProvider call(String symbol) =>
      FetchWaypointProvider._(argument: symbol, from: this);

  @override
  String toString() => r'fetchWaypointProvider';
}

@ProviderFor(fetchShips)
final fetchShipsProvider = FetchShipsFamily._();

final class FetchShipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ship>>,
          List<Ship>,
          FutureOr<List<Ship>>
        >
    with $FutureModifier<List<Ship>>, $FutureProvider<List<Ship>> {
  FetchShipsProvider._({
    required FetchShipsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fetchShipsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchShipsHash();

  @override
  String toString() {
    return r'fetchShipsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Ship>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Ship>> create(Ref ref) {
    final argument = this.argument as String;
    return fetchShips(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchShipsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchShipsHash() => r'65007276062adfc3dbb9e29aa2a4244f9e63089e';

final class FetchShipsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Ship>>, String> {
  FetchShipsFamily._()
    : super(
        retry: null,
        name: r'fetchShipsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  FetchShipsProvider call(String systemSymbol) =>
      FetchShipsProvider._(argument: systemSymbol, from: this);

  @override
  String toString() => r'fetchShipsProvider';
}
