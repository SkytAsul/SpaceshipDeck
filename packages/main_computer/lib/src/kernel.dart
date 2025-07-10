import 'dart:async';

import 'package:logging/logging.dart';
import 'package:main_computer/src/kernel_commands.dart';
import 'package:space_traders/api.dart';

export 'kernel_commands.dart';

class SpaceshipKernel {
  final _logger = Logger("SpaceshipDeck.$SpaceshipKernel");

  ApiClient? _apiClient;
  ApiClient get apiClient => _apiClient!;

  bool _started = false;
  bool get started => _started;

  bool _shutdownRequested = false;

  final _startedStreamContoller = StreamController<bool>.broadcast();
  Stream<bool> get startedStream => _startedStreamContoller.stream;

  final Map<KernelUnit, _KernelUnitStatus> _units = {};

  Iterable<KernelUnit> get units => _units.keys;

  SpaceshipKernel({required List<KernelUnit> units}) {
    for (var unit in units) {
      _units[unit] = _createUnitStatus(unit);
    }
  }

  Future<void> run() async {
    _logger.info("Booting up...");

    for (var unit in _units.keys) {
      await loadUnit(unit);
    }
    _started = true;
    _startedStreamContoller.add(true);

    await _loop();

    _startedStreamContoller.add(false);
    _started = false;
    for (var unit in _units.keys) {
      await unloadUnit(unit);
    }
  }

  Future<void> _loop() async {
    while (!_shutdownRequested) {
      await Future.delayed(Duration(seconds: 1));
    }
  }

  void askShutdown() {
    _shutdownRequested = true;
  }

  KernelCommandRunner? getCommand(String name) {
    for (var unit in _units.keys) {
      if (unit is KernelCommand && unit.name == name) {
        final status = _units[unit]!;
        var commandRunner = unit.runnerProvider(name);
        commandRunner.context = status.context;
        return commandRunner;
      }
    }
    return null;
  }

  T? get<T>() {
    for (var status in _units.values) {
      final obj = status.context.exposed[T];
      if (obj is T) {
        return obj;
      }
    }
    return null;
  }

  Future<bool> loadUnit(KernelUnit unit) async {
    var status = _units[unit]!;
    var record = (unit, status);

    return switch (record) {
      (KernelService(), _KernelServiceStatus()) => await _loadService(
        record.$1,
        record.$2,
      ),
      (KernelTimer(), _KernelUnitStatus()) => await _loadTimer(
        record.$1,
        record.$2,
      ),
      (KernelCommand(), _KernelUnitStatus()) => true,
      _ => throw StateError("Mismatched unit and status types"),
    };
  }

  Future<bool> _loadService<T>(
    KernelService<T> service,
    _KernelServiceStatus<T> status,
  ) async {
    try {
      _logger.fine("Loading ${service.name}...");
      status.value = await service._callStart(status.context);
      status.status = KernelServiceStatus.loaded;
      _logger.info("Loaded ${service.name}.");
      return true;
    } catch (e, st) {
      _logger.severe("Error when loading service", e, st);
      status.status = KernelServiceStatus.failed;
      return false;
    }
  }

  Future<bool> _loadTimer(KernelTimer timer, _KernelUnitStatus status) {
    // TODO
    return Future.value(true);
  }

  Future<void> unloadUnit(KernelUnit unit) async {
    var status = _units[unit]!;
    var record = (unit, status);

    switch (record) {
      case (KernelService(), _KernelServiceStatus()):
        await _unloadService(record.$1, record.$2);
      case (KernelTimer() || KernelCommand(), _KernelUnitStatus()):
        break; // nothing to do
      case _:
        throw StateError("Mismatched unit and status types");
    }
  }

  Future<void> _unloadService<T>(
    KernelService<T> service,
    _KernelServiceStatus<T> status,
  ) async {
    if (status.status != KernelServiceStatus.loaded) {
      return;
    }

    _logger.fine("Unloading ${service.name}...");
    service._callStop(status.value as T);
    _logger.info("Unloaded ${service.name}.");
  }

  _KernelUnitStatus _createUnitStatus(KernelUnit unit) {
    final context = KernelUnitContext._(
      kernel: this,
      logger: Logger("SpaceshipDeck.${unit.name}"),
    );
    return switch (unit) {
      KernelService() => _KernelServiceStatus(context),
      KernelTimer() || KernelCommand() => _KernelUnitStatus(context),
    };
  }
}

class KernelUnitContext {
  final SpaceshipKernel kernel;
  final Logger logger;

  final Map<Type, Object?> exposed = {};

  KernelUnitContext._({required this.kernel, required this.logger});

  /// Exposes [instance] to all other units. If another instance of the same
  /// type has already been exposed by this unit, [instance] will replace it.
  ///
  /// In the case of a service, the exposed data will be lost when the service
  /// gets unloaded.
  void expose<T>(T instance) {
    exposed[T] = instance;
  }
}

sealed class KernelUnit {
  String get name;
}

final class KernelService<T> implements KernelUnit {
  @override
  final String name;
  final FutureOr<T> Function(KernelUnitContext)? start;
  final FutureOr<void> Function(T)? stop;

  KernelService({required this.name, this.start, this.stop});

  Future<T?> _callStart(KernelUnitContext context) async {
    if (start != null) {
      return await start!(context);
    }
    return null;
  }

  void _callStop(T value) async {
    if (stop != null) {
      await stop!(value);
    }
  }
}

final class KernelTimer implements KernelUnit {
  @override
  final String name;
  final Duration interval;
  final FutureOr<void> Function(KernelUnitContext) function;

  KernelTimer({
    required this.name,
    required this.interval,
    required this.function,
  });
}

final class KernelCommand implements KernelUnit {
  @override
  final String name;
  final KernelCommandRunner Function(String label) runnerProvider;

  KernelCommand(this.name, this.runnerProvider);
}

enum KernelServiceStatus { notLoaded, failed, loaded }

class _KernelUnitStatus {
  KernelUnitContext context;

  _KernelUnitStatus(this.context);
}

class _KernelServiceStatus<T> extends _KernelUnitStatus {
  KernelServiceStatus status = KernelServiceStatus.notLoaded;
  T? value;

  _KernelServiceStatus(super.context);
}
