import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/utils/async.dart';

class SpaceshipShell {
  final Stream<List<int>> inputStream;
  final IOSink outputStream;
  final SpaceshipKernel kernel;
  final bool lineMode;

  String lineBuffer = "";
  bool exitRequested = false;

  SpaceshipShell(
    this.inputStream,
    this.outputStream, {
    required this.kernel,
    this.lineMode = false,
  });

  Future<bool> run() async {
    outputStream.writeln("\nEnter 'exit' or ^D to exit.");

    _showPrompt();
    try {
      await for (var codeUnits in inputStream.stopOn(
        kernel.startedStream.firstWhere((started) => !started),
      )) {
        switch (codeUnits) {
          case [0x04]:
            _handleExitKey();
          case [0x09]:
            _handleTab();
          case [0x0A]:
            await _handleLineBreak();
          case [0x7F]:
            _handleDel();
          case [0x1B, 0x5B, 65 || 66]:
            _handleVerticalMovement(codeUnits[2] == 66);
          case [0x1B, 0x5B, 67 || 68]:
            _handleHorizontalMovement(codeUnits[2] == 67);
          case [0x1B, ..._]:
            print("Unhandled escape code: $codeUnits");
          case [var point] when point <= 31:
            print("Unhandled control character: $point");
          case _:
            _handleChars(utf8.decode(codeUnits));
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

  void _showPrompt() {
    outputStream.write("> ");
  }

  void _handleExitKey() {
    if (lineBuffer.isEmpty) {
      exitRequested = true;
      outputStream.writeln();
      print("exit");
    }
  }

  void _handleVerticalMovement(bool down) {
    // TODO history
  }

  void _handleHorizontalMovement(bool right) {
    // TODO manage cursor position to prevent going before the prompt
  }

  void _handleTab() {
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

  Future<void> _handleChars(String chars) async {
    if (lineMode) {
      await _handleLine(chars.trimRight());
    } else {
      outputStream.write(chars);
      lineBuffer += chars;
    }
  }

  void _handleDel() {
    if (lineBuffer.isEmpty) {
      return;
    }

    lineBuffer = lineBuffer.substring(0, lineBuffer.length - 1);
    outputStream.write("\x08\x1b[0K");
  }

  Future<void> _handleLineBreak() async {
    outputStream.writeln();

    if (lineBuffer.isEmpty) {
      _showPrompt();
    } else {
      final line = lineBuffer.toString();
      lineBuffer = "";
      await _handleLine(line);
    }
  }

  Future<void> _handleLine(String line) async {
    try {
      await evaluate(line);
    } catch (e, st) {
      outputStream.writeln("An error occurred during the command evaluation.");
      outputStream.writeln(e);
      outputStream.writeln(st);
    }
    if (!exitRequested) {
      _showPrompt();
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
      outputStream.writeln("Unknown command $commandLabel");
      print(commandLabel.codeUnits);
    } else {
      await command.run(args.skip(1));
    }
  }
}

List<String> _getArgs(String line) {
  return line.split(" "); // TODO handle quoting
}
