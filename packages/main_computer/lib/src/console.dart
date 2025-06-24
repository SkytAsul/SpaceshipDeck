import 'dart:convert';
import 'dart:io';

import 'package:main_computer/main_computer.dart';

Future<void> runConsole(SpaceshipKernel kernel) async {
  print("\nEnter 'exit' to quit.");

  // TODO: read character by character to handle tab-completion
  // TODO: await kernel shutdown to gracefully quit
  // TODO: use Zone to change print OR stdout and add > at the right position
  stdout.write("> ");
  await for (var line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final args = _getArgs(line);
    final commandLabel = args[0].toLowerCase();

    if (commandLabel == "exit") {
      break;
    }
    
    final command = kernel.getCommand(commandLabel);
    if (command == null) {
      print("Unknown command $commandLabel");
    } else {
      await command(args);
    }

    stdout.write("> ");
  }

  print("");
}

List<String> _getArgs(String line) {
  return line.split(" "); // TODO handle quoting
}
