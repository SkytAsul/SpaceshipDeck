import 'dart:async';
import 'dart:io';

import 'package:main_computer/main_computer.dart';

/// Manages Telnet access
class _RemoteControl {
  final KernelUnitContext _context;

  ServerSocket? _serverSocket;

  _RemoteControl(this._context);

  Future<void> load() async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv6, 58471);
    _serverSocket!.listen(_receiveSocket);
    _context.logger.info(
      "Listening for remote connections at ${_serverSocket!.address.address}:${_serverSocket!.port}",
    );
  }

  void _receiveSocket(Socket socket) async {
    final sessionName = "${socket.remoteAddress.address}:${socket.remotePort}";
    _context.logger.info("Received new connection from $sessionName");

    final socketIn = socket.where((codeUnits) {
      if (codeUnits[0] == 0xff) {
        print("Received telnet escape codes: $codeUnits");
        return false;
      }
      return true;
    });

    bool result = await runZoned(
      () async {
        print("Welcome to the Spaceship Deck!");
        final shell = SpaceshipShell(
          socketIn,
          socket,
          kernel: _context.kernel,
          lineMode: true,
        );
        bool result = await shell.run();
        print("See you in the universe.");
        return result;
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          socket.writeln(line);
        },
      ),
    );
    _context.logger.info(
      "Remote session $sessionName ended with success mode: $result",
    );
    await socket.flush();
    await socket.close();
  }

  Future<void> close() async {
    if (_serverSocket != null) {
      await _serverSocket!.close();
    }
  }
}

KernelService getRemoteControlService() => KernelService<_RemoteControl>(
  name: "Remote Control",
  start: (context) async {
    final instance = _RemoteControl(context);
    await instance.load();
    return instance;
  },
  stop: (instance) => instance.close(),
);
