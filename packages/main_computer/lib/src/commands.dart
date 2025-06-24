import 'package:main_computer/main_computer.dart';

List<KernelCommand> getKernelCommands() => [
  KernelCommand(name: "agent", function: _agentCommand)
];

Future<void> _agentCommand(KernelUnitContext context, List<String> args) async {
  print("uwu");
}
