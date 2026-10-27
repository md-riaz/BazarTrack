import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/mock/mock_seed.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _safeLoadEnv();

  final database = AppDatabase();
  await _enableAndVerifyForeignKeys(database);
  await MockSeed.seed(database);

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const BazarApp(),
    ),
  );
}

Future<void> _safeLoadEnv() async {
  try {
    await dotenv.load(fileName: 'assets/env/app.env');
  } catch (_) {
    // Local .env is optional; compile-time --dart-define values still work.
  }
}

Future<void> _enableAndVerifyForeignKeys(AppDatabase database) async {
  await database.customStatement('PRAGMA foreign_keys = ON');
  final row = await database.customSelect('PRAGMA foreign_keys').getSingle();
  if (row.read<int>('foreign_keys') != 1) {
    throw StateError('SQLite foreign key enforcement could not be enabled.');
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
