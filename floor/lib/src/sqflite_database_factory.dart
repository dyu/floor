import 'dart:io';

import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show DatabaseFactory, databaseFactory, databaseFactoryFfi, sqfliteFfiInit;

// infers factory as nullable without explicit type definition
final DatabaseFactory sqfliteDatabaseFactory = () {
  if (Platform.isAndroid || Platform.isIOS) {
    return databaseFactory;
  } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  } else {
    throw UnsupportedError(
      'Platform ${Platform.operatingSystem} is not supported by Floor.',
    );
  }
}();

extension DatabaseFactoryExtension on DatabaseFactory {
  Future<String> getDatabasePath(final String name) async {
    final databasesPath = await this.getDatabasesPath();
    return join(databasesPath, name);
  }
}
