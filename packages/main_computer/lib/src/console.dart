import 'dart:convert';
import 'dart:io';

Future<void> runConsole() async {
  print("Enter 'exit' to quit.");

  await for (var line in stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    print("You entered $line");
    
    if (line == "exit"){
      break;
    }
  }
}