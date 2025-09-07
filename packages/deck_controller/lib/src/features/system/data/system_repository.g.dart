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

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
