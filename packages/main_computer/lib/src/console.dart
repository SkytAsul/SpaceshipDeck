import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/utils/async.dart';

class SpaceshipConsole {
  final Stream<List<int>> inputStream;
  final Stdout outputStream;
  final SpaceshipKernel kernel;

  String lineBuffer = "";
  bool exitRequested = false;

  SpaceshipConsole(this.inputStream, this.outputStream, {required this.kernel});

  Future<bool> run() async {
    print("\nEnter 'exit' or ^D to exit.");

    showPrompt();
    try {
      await for (var codeUnits in inputStream.stopOn(
        kernel.startedStream.firstWhere((started) => !started),
      )) {
        switch (codeUnits) {
          case [0x04]:
            handleExitKey();
          case [0x09]:
            handleTab();
          case [0x0A]:
            await handleLineBreak();
          case [0x7F]:
            handleDel();
          case [0x1B, 0x5B, 65 || 66]:
            handleVerticalMovement(codeUnits[2] == 66);
          case [0x1B, 0x5B, 67 || 68]:
            handleHorizontalMovement(codeUnits[2] == 67);
          case [0x1B, ..._]:
            print("Unhandled escape code: $codeUnits");
          case [var point] when point <= 31:
            print("Unhandled control character: $point");
          case _:
            handleChar(utf8.decode(codeUnits));
        }

        if (exitRequested) {
          break;
        }
      }
    } on StreamStop {
      // means the kernel stopped
    }

    return exitRequested;
  }

  void showPrompt() {
    outputStream.write("> ");
  }

  void handleExitKey() {
    if (lineBuffer.isEmpty) {
      exitRequested = true;
      outputStream.writeln();
    }
  }

  void handleVerticalMovement(bool down) {
    // TODO history
  }

  void handleHorizontalMovement(bool right) {
    // TODO manage cursor position to prevent going before the prompt
  }

  void handleTab() {
    final args = _getArgs(lineBuffer.toString());
    if (args.length != 1) {
      return;
    }
    final commandLabel = args[0].toLowerCase();

    final commands = kernel.units
        .whereType<KernelCommand>()
        .where((cmd) => cmd.name.startsWith(commandLabel))
        .toList();

    if (commands.isNotEmpty) {
      final cmd = commands[0];
      final completion = cmd.name.substring(commandLabel.length);
      lineBuffer += completion;
      outputStream.write(completion);
    }
  }

  void handleChar(String char) {
    outputStream.write(char);
    lineBuffer += char;
  }

  void handleDel() {
    if (lineBuffer.isEmpty) {
      return;
    }

    lineBuffer = lineBuffer.substring(0, lineBuffer.length - 1);
    outputStream.write("\x08\x1b[0K");
  }

  Future<void> handleLineBreak() async {
    outputStream.writeln();

    if (lineBuffer.isNotEmpty) {
      final line = lineBuffer.toString();
      lineBuffer = "";
      try {
        await evaluate(line);
      } catch (e, st) {
        print("An error occurred during the command evaluation.");
        print(e);
        print(st);
      }
    }

    if (!exitRequested) {
      showPrompt();
    }
  }

  Future<void> evaluate(String line) async {
    final args = _getArgs(line);
    final commandLabel = args[0].toLowerCase();

    if (commandLabel == "exit") {
      exitRequested = true;
      return;
    }

    final command = kernel.getCommand(commandLabel);
    if (command == null) {
      print("Unknown command $commandLabel");
    } else {
      await command.run(args.skip(1));
    }
  }
}

List<String> _getArgs(String line) {
  return line.split(" "); // TODO handle quoting
}
