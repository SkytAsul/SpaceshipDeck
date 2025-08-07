import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/utils/async.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:sembast/timestamp.dart';
import 'package:stack_trace/stack_trace.dart';

/// From https://v2test.asciiart.website/art/2526, https://emojicombos.com/solar-system-ascii-art
const _greetingIcons = [
  """
                                             ___
                                          ,o88888
                                       ,o8888888'
                 ,:o:o:oooo.        ,8O88Pd8888"
             ,.::.::o:ooooOoOoO. ,oO8O8Pd888'"
           ,.:.::o:ooOoOoOO8O8OOo.8OOPd8O8O"
          , ..:.::o:ooOoOOOO8OOOOo.FdO8O8"
         , ..:.::o:ooOoOO8O888O8O,COCOO"
        , . ..:.::o:ooOoOOOO8OOOOCOCO"
         . ..:.::o:ooOoOoOO8O8OCCCC"o
            . ..:.::o:ooooOoCoCCC"o:o
            . ..:.::o:o:,cooooCo"oo:o:
         `   . . ..:.:cocoooo"'o:o:::'
         .`   . ..::ccccoc"'o:o:o:::'
        :.:.    ,c:cccc"':.:.:.:.:.'
      ..:.:"'`::::c:"'..:.:.:.:.:.'
    ...:.'.:.::::"'    . . . . .'
   .. . ....:."' `   .  . . ''
 . . . ...."'
 .. . ."'
.
""",
  """
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢠⠄⠀⡐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠳⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⡈⣀⡴⢧⣀⠀⠀⣀⣠⠤⠤⠤⠤⣄⣀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠘⠏⢀⡴⠊⠁⠀⠄⠀⠀⠀⠀⠈⠙⠢⡀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣰⠋⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠘⢶⣶⣒⡶⠦⣠⣀⠀
⠀⠀⠀⠀⠀⠀⢀⣰⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠀⠈⣟⠲⡎⠙⢦⠈⢧
⠀⠀⠀⣠⢴⡾⢟⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡰⢃⡠⠋⣠⠋
⠐⠀⠞⣱⠋⢰⠁⢿⠀⠀⠀⠀⠄⢂⠀⠀⠀⠀⠀⣀⣠⠠⢖⣋⡥⢖⣩⠔⠊⠀⠀
⠈⠠⡀⠹⢤⣈⣙⠚⠶⠤⠤⠤⠴⠶⣒⣒⣚⣨⠭⢵⣒⣩⠬⢖⠏⠁⢀⣀⠀⠀⠀
⠀⠀⠈⠓⠒⠦⠍⠭⠭⣭⠭⠭⠭⠭⡿⡓⠒⠛⠉⠉⠀⠀⣠⠇⠀⠀⠘⠞⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠓⢤⣀⠀⠁⠀⠀⠀⠀⣀⡤⠞⠁⠀⣰⣆⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠿⠀⠀⠀⠀⠀⠉⠉⠙⠒⠒⠚⠉⠁⠀⠀⠀⠁⢣⡎⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀""",
  """
⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠖⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣷⣶⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⣧⡀⠤⠤⣤⣤⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⣿⣇⠀⣦⣤⣤⣄⣈⡉⠉⠛⠛⠷⢶⠄⢠⣴⣦⡀⠀⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠉⠉⠛⠛⠷⣦⣀⠀⠀⢻⣿⣿⣿⡀⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣹⡆⠀⠀⠈⠉⠘⡇⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⢀⠀⢀⣀⣠⣤⡴⠾⠋⠀⠀⠀⢀⣠⡾⠃⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⠶⠶⠶⠀⠿⠃⠘⠉⠉⠀⠀⢀⣀⣤⣴⠾⠛⠉⠀⠀⠀⠀⠀
⠀⣿⣿⣟⣉⣀⣀⣀⣀⣠⣤⣤⣤⣴⡶⠶⠿⠛⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠛⠛⠋⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁""",
];

class SpaceshipShell {
  final Stream<List<int>> inputStream;
  final IOSink outputStream;
  final SpaceshipKernel kernel;
  final bool lineMode;
  final ShellHistoryManager history;

  String lineBuffer = "";
  bool exitRequested = false;
  int? historyIndex;
  int cursor = 0;

  SpaceshipShell(
    this.inputStream,
    this.outputStream, {
    required this.kernel,
    this.lineMode = false,
  }) : history = ShellHistoryManager(kernel.get()!);

  Future<bool> run() async {
    _showGreetings();
    _showPrompt();

    // history loading is fast so the user won't notice the time it takes
    // between the display of the prompt and when the user input is echoed
    await history.load();

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
            _handleBackspace();
          case [0x15]:
            _eraseInput();
          case [0x1B, 0x5B, 65 || 66]:
            _handleVerticalMovement(codeUnits[2] == 66);
          case [0x1B, 0x5B, 67 || 68]:
            _handleHorizontalMovement(codeUnits[2] == 67);
          case [0x1B, 0x5B, 51, 126]:
            _handleDel();
          case [0x1B, ..._]:
          case [var point] when point <= 31:
            print("Unhandled escape codes: $codeUnits");
            _showPrompt();
            outputStream.write(lineBuffer);
            cursor = lineBuffer.length;
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
    }
  }

  void _handleVerticalMovement(bool down) {
    int toDisplay;
    if (historyIndex == null) {
      if (lineBuffer.isNotEmpty) {
        // do not overwrite input if its the first time accessing the history
        return;
      }

      if (history.commands.isEmpty || down) {
        return;
      }

      toDisplay = history.commands.length - 1;
    } else {
      toDisplay = historyIndex! + (down ? 1 : -1);
    }

    if (toDisplay < 0) {
      return;
    }
    if (toDisplay >= history.commands.length) {
      historyIndex = null;
      _eraseInput();
      return;
    }

    historyIndex = toDisplay;
    _eraseInput();
    var command = history.commands[toDisplay];
    _insertInput(command);
  }

  void _handleHorizontalMovement(bool right) {
    if ((!right && cursor == 0) || (right && cursor == lineBuffer.length)) {
      return;
    }

    cursor += (right ? 1 : -1);
    outputStream.write("\x1b[1${right ? "C" : "D"}");
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
      _insertInput(completion);
    }
  }

  Future<void> _handleChars(String chars) async {
    if (lineMode) {
      await _handleLine(chars.trimRight());
    } else {
      _insertInput(chars);
    }
  }

  void _handleBackspace() {
    if (lineBuffer.isEmpty) {
      return;
    }

    String rightPart = lineBuffer.substring(cursor);
    cursor--;
    lineBuffer = lineBuffer.substring(0, cursor);
    outputStream.write("\x08\x1b[0K");
    _insertInput(rightPart, false);
  }

  void _handleDel() {
    if (lineBuffer.isEmpty || cursor == lineBuffer.length) {
      return;
    }
    String rightPart = lineBuffer.substring(cursor + 1);
    lineBuffer = lineBuffer.substring(0, cursor);
    outputStream.write("\x1b[0K");
    _insertInput(rightPart, false);
  }

  void _eraseInput() {
    if (lineBuffer.isEmpty) {
      return;
    }

    int count = lineBuffer.length;
    lineBuffer = "";
    outputStream.write("\x1b[${count}D\x1b[0K");
    cursor = 0;
  }

  void _insertInput(String chars, [bool moveCursor = true]) {
    String rightPart = lineBuffer.substring(cursor);
    lineBuffer = lineBuffer.substring(0, cursor) + chars + rightPart;
    outputStream.write(lineBuffer.substring(cursor));

    int cursorBack = moveCursor ? rightPart.length : chars.length;

    if (cursorBack > 0) {
      outputStream.write("\x1b[${cursorBack}D");
    }
    if (moveCursor) {
      cursor += chars.length;
    }
  }

  Future<void> _handleLineBreak() async {
    outputStream.writeln();

    final line = lineBuffer.toString();
    lineBuffer = "";
    cursor = 0;
    await _handleLine(line);
  }

  Future<void> _handleLine(String line) async {
    if (line.trim().isNotEmpty) {
      try {
        historyIndex = null;
        history.add(line);
        await evaluate(line);
      } on UsageException catch (ex) {
        outputStream.writeln(ex);
      } catch (e, st) {
        outputStream.writeln(
          "An error occurred during the command evaluation.",
        );
        outputStream.writeln(e);
        outputStream.writeln(_prettifyStackTrace(st));
      }
      outputStream.writeln();
    }
    if (!exitRequested) {
      _showPrompt();
    }
  }

  Trace _prettifyStackTrace(StackTrace st) {
    var frames = Trace.from(st).terse.frames;
    for (int i = frames.length - 1; i >= 0; i--) {
      var frame = frames[i];
      if (frame.member == "SpaceshipShell._handleLine") {
        frames = frames.sublist(0, i);
        break;
      }
    }

    return Trace(frames);
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
    } else {
      await command.run(args.skip(1));
    }
  }

  void _showGreetings() {
    var greetingIcon = _greetingIcons[Random().nextInt(_greetingIcons.length)];
    outputStream.writeln(greetingIcon);
    outputStream.writeln("Enter 'exit' or ^D to exit.");
  }
}

List<String> _getArgs(String line) {
  return line.split(" "); // TODO handle quoting
}

class ShellHistoryManager {
  static const historySize = 1000;
  static final store = intMapStoreFactory.store("shell_history");

  final Database _db;
  final List<String> commands = [];

  ShellHistoryManager(this._db);

  Future<void> load() async {
    var records = await store.find(
      _db,
      finder: Finder(
        limit: historySize,
        sortOrders: [SortOrder("timestamp", false)],
      ),
    );
    commands.insertAll(
      0,
      records
          .map((record) => record.value["command"] as String)
          .toList()
          .reversed,
    );
  }

  Future<void> add(String command) async {
    commands.add(command);
    await store.add(_db, {"timestamp": Timestamp.now(), "command": command});
  }
}
