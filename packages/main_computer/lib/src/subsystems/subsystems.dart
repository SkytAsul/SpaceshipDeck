import 'dart:async';

import 'package:args/args.dart';
import 'package:main_computer/main_computer.dart';
import 'package:main_computer/src/utils/async.dart';
import 'package:meta/meta.dart';
import 'package:space_traders/api.dart';

part 'agent.dart';
part 'contracts.dart';
part 'factions.dart';
part 'galaxy.dart';
part 'ships.dart';

List<KernelCommand> getSubsystemCommands() => [
  shipsCommand,
  agentCommand,
  contractsCommand,
];

List<KernelService> getSubsystemServices() => [
  getAgentService(),
  getContractsService(),
  getFactionsService(),
  getGalaxyService(),
  getShipsService(),
];
