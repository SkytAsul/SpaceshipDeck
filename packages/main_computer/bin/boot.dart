import 'dart:async';
import 'dart:io';

import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/utils/async.dart';

StreamSubscription? signalStreamSubscription;

Future<void> main() async {
  final kernel = await bootKernel();

  if (stdin.hasTerminal) {
    _showConsole(kernel, lineMode: false);
  }

  _catchSigint(kernel);

  await kernel.run();
  print("Kernel shut down.");

  await signalStreamSubscription?.cancel();
}

void _catchSigint(SpaceshipKernel kernel) {
  ProcessSignal.sigint
      .watch()
      .asBroadcastStream(
        onListen: (subscription) => signalStreamSubscription = subscription,
      )
      .next()
      .then((_) async {
        print("\nReceived SIGINT, shutting down.");
        kernel.askShutdown();
      });
}

void _showConsole(SpaceshipKernel kernel, {bool lineMode = false}) async {
  stdin.lineMode = lineMode;
  stdin.echoMode = lineMode;
  StreamSubscription? streamSubscription;
  final stdinStream = stdin.asBroadcastStream(
    onListen: (subscription) => streamSubscription = subscription,
  );

  if (!kernel.started) {
    await kernel.startedStream.next();
  }

  while (kernel.started) {
    try {
      bool manualExit = await SpaceshipShell(
        stdinStream,
        stdout,
        kernel: kernel,
        lineMode: lineMode,
      ).run();
      if (manualExit) {
        print("""
  You tried to exit the console from the bootloader.
  Use 'shutdown' instead if you want to exit the main spacehip computer.""");
      }
    } catch (ex, st) {
      print("An error occurred in the console.");
      print(ex);
      print(st);
    }
  }

  await streamSubscription!.cancel();
}
