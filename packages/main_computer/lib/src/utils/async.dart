import 'dart:async';

extension StreamUtilities<T> on Stream<T> {

  /// Returns a Future which completes with the next event from the Stream.
  Future<T> next() {
    final completer = Completer<T>();

    final sub = listen(null);
    sub.onData((event) {
      completer.complete(event);
      sub.cancel();
    });
    sub.onError((Object error, StackTrace? stackTrace) {
      completer.completeError(error, stackTrace);
      sub.cancel();
    });
    sub.onDone(() {
      completer.completeError("noData");
    });
    

    return completer.future;
  }

  /// Returns a Stream with the same events that this one, but with an added
  /// [StreamStop] error whenever the passed [future] completes.
  Stream<T> stopOn(Future future) {
    var ctrler = StreamController<T>();
    StreamSubscription? subs;
    ctrler.onListen = () {
      future.then((_) => ctrler.addError(StreamStop()));
      subs = listen(
        (event) => ctrler.add(event),
        onError: (error, st) => ctrler.addError(error, st),
        onDone: () => ctrler.close(),
      );
    };
    ctrler.onCancel = () {
      subs?.cancel();
    };
    return ctrler.stream;
  }

}

class StreamStop implements Exception {
  const StreamStop();
}
