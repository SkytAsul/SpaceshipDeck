// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchSystemHash() => r'f474b069aec2679a29a587708a1dcaa8035416bf';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [fetchSystem].
@ProviderFor(fetchSystem)
const fetchSystemProvider = FetchSystemFamily();

/// See also [fetchSystem].
class FetchSystemFamily extends Family<AsyncValue<System>> {
  /// See also [fetchSystem].
  const FetchSystemFamily();

  /// See also [fetchSystem].
  FetchSystemProvider call(String symbol) {
    return FetchSystemProvider(symbol);
  }

  @override
  FetchSystemProvider getProviderOverride(
    covariant FetchSystemProvider provider,
  ) {
    return call(provider.symbol);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchSystemProvider';
}

/// See also [fetchSystem].
class FetchSystemProvider extends AutoDisposeFutureProvider<System> {
  /// See also [fetchSystem].
  FetchSystemProvider(String symbol)
    : this._internal(
        (ref) => fetchSystem(ref as FetchSystemRef, symbol),
        from: fetchSystemProvider,
        name: r'fetchSystemProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$fetchSystemHash,
        dependencies: FetchSystemFamily._dependencies,
        allTransitiveDependencies: FetchSystemFamily._allTransitiveDependencies,
        symbol: symbol,
      );

  FetchSystemProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.symbol,
  }) : super.internal();

  final String symbol;

  @override
  Override overrideWith(
    FutureOr<System> Function(FetchSystemRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchSystemProvider._internal(
        (ref) => create(ref as FetchSystemRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        symbol: symbol,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<System> createElement() {
    return _FetchSystemProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchSystemProvider && other.symbol == symbol;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, symbol.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchSystemRef on AutoDisposeFutureProviderRef<System> {
  /// The parameter `symbol` of this provider.
  String get symbol;
}

class _FetchSystemProviderElement
    extends AutoDisposeFutureProviderElement<System>
    with FetchSystemRef {
  _FetchSystemProviderElement(super.provider);

  @override
  String get symbol => (origin as FetchSystemProvider).symbol;
}

String _$fetchWaypointHash() => r'caff2db5644ae24e1d128e59e87f815ae5cd94bc';

/// See also [fetchWaypoint].
@ProviderFor(fetchWaypoint)
const fetchWaypointProvider = FetchWaypointFamily();

/// See also [fetchWaypoint].
class FetchWaypointFamily extends Family<AsyncValue<Waypoint>> {
  /// See also [fetchWaypoint].
  const FetchWaypointFamily();

  /// See also [fetchWaypoint].
  FetchWaypointProvider call(String symbol) {
    return FetchWaypointProvider(symbol);
  }

  @override
  FetchWaypointProvider getProviderOverride(
    covariant FetchWaypointProvider provider,
  ) {
    return call(provider.symbol);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchWaypointProvider';
}

/// See also [fetchWaypoint].
class FetchWaypointProvider extends FutureProvider<Waypoint> {
  /// See also [fetchWaypoint].
  FetchWaypointProvider(String symbol)
    : this._internal(
        (ref) => fetchWaypoint(ref as FetchWaypointRef, symbol),
        from: fetchWaypointProvider,
        name: r'fetchWaypointProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$fetchWaypointHash,
        dependencies: FetchWaypointFamily._dependencies,
        allTransitiveDependencies:
            FetchWaypointFamily._allTransitiveDependencies,
        symbol: symbol,
      );

  FetchWaypointProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.symbol,
  }) : super.internal();

  final String symbol;

  @override
  Override overrideWith(
    FutureOr<Waypoint> Function(FetchWaypointRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchWaypointProvider._internal(
        (ref) => create(ref as FetchWaypointRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        symbol: symbol,
      ),
    );
  }

  @override
  FutureProviderElement<Waypoint> createElement() {
    return _FetchWaypointProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchWaypointProvider && other.symbol == symbol;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, symbol.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchWaypointRef on FutureProviderRef<Waypoint> {
  /// The parameter `symbol` of this provider.
  String get symbol;
}

class _FetchWaypointProviderElement extends FutureProviderElement<Waypoint>
    with FetchWaypointRef {
  _FetchWaypointProviderElement(super.provider);

  @override
  String get symbol => (origin as FetchWaypointProvider).symbol;
}

String _$fetchShipsHash() => r'65007276062adfc3dbb9e29aa2a4244f9e63089e';

/// See also [fetchShips].
@ProviderFor(fetchShips)
const fetchShipsProvider = FetchShipsFamily();

/// See also [fetchShips].
class FetchShipsFamily extends Family<AsyncValue<List<Ship>>> {
  /// See also [fetchShips].
  const FetchShipsFamily();

  /// See also [fetchShips].
  FetchShipsProvider call(String systemSymbol) {
    return FetchShipsProvider(systemSymbol);
  }

  @override
  FetchShipsProvider getProviderOverride(
    covariant FetchShipsProvider provider,
  ) {
    return call(provider.systemSymbol);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchShipsProvider';
}

/// See also [fetchShips].
class FetchShipsProvider extends FutureProvider<List<Ship>> {
  /// See also [fetchShips].
  FetchShipsProvider(String systemSymbol)
    : this._internal(
        (ref) => fetchShips(ref as FetchShipsRef, systemSymbol),
        from: fetchShipsProvider,
        name: r'fetchShipsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$fetchShipsHash,
        dependencies: FetchShipsFamily._dependencies,
        allTransitiveDependencies: FetchShipsFamily._allTransitiveDependencies,
        systemSymbol: systemSymbol,
      );

  FetchShipsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.systemSymbol,
  }) : super.internal();

  final String systemSymbol;

  @override
  Override overrideWith(
    FutureOr<List<Ship>> Function(FetchShipsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchShipsProvider._internal(
        (ref) => create(ref as FetchShipsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        systemSymbol: systemSymbol,
      ),
    );
  }

  @override
  FutureProviderElement<List<Ship>> createElement() {
    return _FetchShipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchShipsProvider && other.systemSymbol == systemSymbol;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, systemSymbol.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchShipsRef on FutureProviderRef<List<Ship>> {
  /// The parameter `systemSymbol` of this provider.
  String get systemSymbol;
}

class _FetchShipsProviderElement extends FutureProviderElement<List<Ship>>
    with FetchShipsRef {
  _FetchShipsProviderElement(super.provider);

  @override
  String get systemSymbol => (origin as FetchShipsProvider).systemSymbol;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
