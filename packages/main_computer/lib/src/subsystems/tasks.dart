typedef EstimatedEndSetter = void Function(DateTime estimatedEnd);

class Task {
  final String name;
  final Future<void> Function(EstimatedEndSetter) _startTask;

  bool _finished = false;
  bool get finished => _finished;

  Future<void>? _startedTask;
  Future<void>? get startedTask => _startedTask;

  Task? _following;
  Task? get following => _following;

  DateTime? _estimatedEnd;
  DateTime? get estimatedEnd => _estimatedEnd;

  Task(this.name, this._startTask);

  void start() {
    if (startedTask != null) {
      throw StateError("Task already started");
    }

    _startedTask = _startTask(
      (newEstimatedEnd) => _estimatedEnd = newEstimatedEnd,
    );
    _startedTask!.then((_) {
      _finished = true;
      following?.start();
    });
  }

  set following(Task value) {
    if (_following != null) {
      throw StateError("Cannot change an existing following task");
    }

    _following = value;
    if (finished) {
      value.start();
    }
  }

  Task get last => following == null ? this : following!.last;
}
