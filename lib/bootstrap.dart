import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/mock/mock_seed.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _safeLoadEnv();
  await _safeInitializeFirebase();

  final database = AppDatabase();
  await database.customStatement('PRAGMA foreign_keys = OFF');
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

Future<void> _safeInitializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config not wired yet for foundation phase.
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
