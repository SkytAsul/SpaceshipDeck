import 'dart:convert';
import 'dart:io';

import 'package:main_computer/main_computer.dart';

Future<void> runConsole(SpaceshipKernel kernel) async {
  print("\nEnter 'exit' to quit.");

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
  }

  print("");
}

List<String> _getArgs(String line) {
  return line.split(" "); // TODO handle quoting
}
