import 'dart:async';

import 'package:logging/logging.dart';
import 'package:main_computer/src/communication_bus/communication_bus.dart';
import 'package:space_traders/api.dart';

class SpaceshipKernel {
  final _logger = Logger("SpaceshipDeck.$SpaceshipKernel");

  ApiClient? _apiClient;
  ApiClient get apiClient => _apiClient!;

  Map<KernelUnit, _KernelUnitStatus> _units;

  SpaceshipKernel({required List<KernelUnit> units})
    : _units = Map.fromIterable(
        units,
        value: (unit) => _createUnitStatus(unit),
      );

  Future<void> boot() async {
    _logger.info("Booting up...");

    for (var unit in _units.keys) {
      await loadUnit(unit);
    }

    daemon();
  }

  void daemon() async {
    /*while (false) {
      // do loop
    }*/
  }

  Future<void> shutdown() async {
    for (var unit in _units.keys) {
      await unloadUnit(unit);
    }
  }

  Future<bool> loadUnit(KernelUnit unit) async {
    var status = _units[unit]!;
    var record = (unit, status);

    _logger.fine("Loading ${unit.name}...");

    final result = switch (record) {
      (KernelService(), _KernelServiceStatus()) => await _loadService(
        record.$1,
        record.$2,
      ),
      (KernelTimer(), _KernelTimerStatus()) => await _loadTimer(
        record.$1,
        record.$2,
      ),
      _ => throw StateError("Mismatched unit and status types"),
    };

    if (result) {
      _logger.info("Loaded ${unit.name}.");
    } else {
      _logger.severe("Failed to load ${unit.name}.");
    }

    return result;
  }

  Future<bool> _loadService<T>(
    KernelService<T> service,
    _KernelServiceStatus<T> status,
  ) async {
    try {
      final context = KernelUnitContext._(
        kernel: this,
        logger: Logger("SpaceshipDeck.${service.name}"),
      );
      status.value = await service._callStart(context);
      status.status = KernelServiceStatus.loaded;
      return true;
    } catch (e, st) {
      _logger.severe("Error when loading service", e, st);
      status.status = KernelServiceStatus.failed;
      return false;
    }
  }

  Future<bool> _loadTimer(KernelTimer timer, _KernelTimerStatus status) {
    // TODO
    return Future.value(true);
  }

  Future<void> unloadUnit(KernelUnit unit) async {
    var status = _units[unit]!;
    var record = (unit, status);

    _logger.fine("Unloading ${unit.name}...");

    switch (record) {
      case (KernelService(), _KernelServiceStatus()):
        await _unloadService(record.$1, record.$2);
      case (KernelTimer(), _KernelTimerStatus()):
        break; // nothing to do
      case _:
        throw StateError("Mismatched unit and status types");
    }

    _logger.info("Unloaded ${unit.name}.");
  }

  Future<void> _unloadService<T>(
    KernelService<T> service,
    _KernelServiceStatus<T> status,
  ) async {
    if (status.status != KernelServiceStatus.loaded) {
      return;
    }

    service._callStop(status.value as T);
  }
}

class KernelUnitContext {
  final SpaceshipKernel kernel;
  final Logger logger;

  KernelUnitContext._({required this.kernel, required this.logger});
}

sealed class KernelUnit {
  String get name;
}

interface class KernelService<T> implements KernelUnit {
  @override
  final String name;
  final FutureOr<T> Function(KernelUnitContext)? start;
  final FutureOr<void> Function(T)? stop;

  KernelService({required this.name, this.start, required this.stop});

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

class KernelTimer implements KernelUnit {
  @override
  final String name;
  final Duration interval;
  final FutureOr<void> Function(SpaceshipKernel) function;

  KernelTimer({
    required this.name,
    required this.interval,
    required this.function,
  });
}

enum KernelServiceStatus { notLoaded, failed, loaded }

_KernelUnitStatus _createUnitStatus(KernelUnit unit) {
  return switch (unit) {
    KernelService() => _KernelServiceStatus(),
    KernelTimer() => _KernelTimerStatus(),
  };
}

sealed class _KernelUnitStatus {}

class _KernelServiceStatus<T> implements _KernelUnitStatus {
  KernelServiceStatus status = KernelServiceStatus.notLoaded;
  T? value;
}

class _KernelTimerStatus implements _KernelUnitStatus {}
