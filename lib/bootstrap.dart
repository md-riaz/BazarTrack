import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/mock/mock_seed.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

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
