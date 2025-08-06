import 'dart:io';

import 'package:main_computer/main_computer.dart';
import 'package:sembast/sembast_io.dart';

KernelService getStorageService() => KernelService<Database>(
  name: "Storage",
  start: (context) async {
    var dataPath =
        Platform.environment["XDG_DATA_HOME"] ??
        "${Platform.environment["HOME"]!}/.local/share";
    var storagePath = "$dataPath/spaceship_deck";

    await Directory(storagePath).create(recursive: true);

    var db = await databaseFactoryIo.openDatabase(
      "$storagePath/storage.db",
      mode: DatabaseMode.create,
    );
    context.expose(db);

    return db;
  },
  stop: (db) async => await db.close(),
);
