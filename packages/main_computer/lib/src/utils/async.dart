import 'dart:async';

extension StreamUtilities<T> on Stream<T> {

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
