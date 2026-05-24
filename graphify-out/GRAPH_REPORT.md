# Graph Report - Bazar  (2026-05-24)

## Corpus Check
- 39 files · ~21,906 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 210 nodes · 214 edges · 15 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 16 edges
2. `../../../../core/theme/app_text_styles.dart` - 8 edges
3. `../../../../core/theme/app_colors.dart` - 7 edges
4. `package:flutter_riverpod/flutter_riverpod.dart` - 6 edges
5. `AppDelegate` - 5 edges
6. `RunnerTests` - 3 edges
7. `../../../../core/router/app_router.dart` - 2 edges
8. `../models/app_enums.dart` - 2 edges
9. `package:go_router/go_router.dart` - 2 edges
10. `../../shared/providers/foundation_providers.dart` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Community 0"
Cohesion: 0.06
Nodes (32): ../../../../core/theme/app_colors.dart, ../../../../core/theme/app_text_styles.dart, ../models/app_enums.dart, package:flutter/material.dart, AppColors, AppBar, BazarAppBar, build (+24 more)

### Community 2 - "Community 2"
Cohesion: 0.08
Nodes (23): dart:io, ../database/app_database.dart, package:drift/drift.dart, package:drift/native.dart, package:path/path.dart, package:path_provider/path_provider.dart, ActivityLogs, AppDatabase (+15 more)

### Community 3 - "Community 3"
Cohesion: 0.09
Nodes (23): ../../features/auth/presentation/screens/login_screen.dart, package:go_router/go_router.dart, AppRoutes, AppRouteSpec, build, GoRouter, RoutePlaceholderScreen, Scaffold (+15 more)

### Community 4 - "Community 4"
Cohesion: 0.12
Nodes (13): currency_formatter.dart, package:intl/intl.dart, BalanceFormatter, BalancePresentation, format, CurrencyFormatter, format, toBanglaDigits (+5 more)

### Community 5 - "Community 5"
Cohesion: 0.13
Nodes (12): ../../../../core/router/app_router.dart, core/theme/app_theme.dart, package:bazar/app.dart, package:bazar/shared/providers/foundation_providers.dart, package:flutter_riverpod/flutter_riverpod.dart, package:flutter_test/flutter_test.dart, BazarApp, build (+4 more)

### Community 6 - "Community 6"
Cohesion: 0.25
Nodes (7): app.dart, core/database/app_database.dart, core/mock/mock_seed.dart, dart:async, package:firebase_core/firebase_core.dart, package:flutter/widgets.dart, _safeInitializeFirebase

### Community 7 - "Community 7"
Cohesion: 0.29
Nodes (5): app_colors.dart, app_text_styles.dart, AppTextStyles, AppTheme, ThemeData

### Community 8 - "Community 8"
Cohesion: 0.33
Nodes (3): FlutterAppDelegate, FlutterImplicitEngineDelegate, AppDelegate

### Community 9 - "Community 9"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 10 - "Community 10"
Cohesion: 0.5
Nodes (2): RunnerTests, XCTestCase

### Community 11 - "Community 11"
Cohesion: 0.67
Nodes (2): bootstrap.dart, bootstrap

### Community 12 - "Community 12"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 13 - "Community 13"
Cohesion: 0.67
Nodes (2): FlutterSceneDelegate, SceneDelegate

### Community 14 - "Community 14"
Cohesion: 0.67
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 15 - "Community 15"
Cohesion: 1.0
Nodes (1): MainActivity

## Knowledge Gaps
- **107 isolated node(s):** `bootstrap`, `bootstrap.dart`, `BazarApp`, `build`, `core/theme/app_theme.dart` (+102 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 9`** (4 nodes): `handle_new_rx_page()`, `__lldb_init_module()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `flutter_lldb_helper.py`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 10`** (4 nodes): `RunnerTests.swift`, `RunnerTests`, `.testExample()`, `XCTestCase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 11`** (3 nodes): `bootstrap.dart`, `main.dart`, `bootstrap`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 12`** (3 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant`, `.registerWith()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 13`** (3 nodes): `FlutterSceneDelegate`, `SceneDelegate.swift`, `SceneDelegate`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 14`** (3 nodes): `GeneratedPluginRegistrant.m`, `GeneratedPluginRegistrant`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 15`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 0` to `Community 3`, `Community 5`, `Community 7`?**
  _High betweenness centrality (0.122) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 5` to `Community 3`, `Community 6`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **Why does `../../../../core/theme/app_text_styles.dart` connect `Community 0` to `Community 3`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **What connects `bootstrap`, `bootstrap.dart`, `BazarApp` to the rest of the system?**
  _107 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._