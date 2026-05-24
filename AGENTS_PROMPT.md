# সহজ বাজার খাতা — Flutter App Development Agent Prompt

> **Version:** 1.0 | **Target:** Claude Code (or equivalent agentic coding agent)
> **Mode:** Orchestrator + Parallel Sub-Agents

---

## 0. Before Anything Else — Read These Files

```
project_root/
  assets/
    spec.pdf          ← Full technical specification (read FULLY before starting)
    prototype.jsx     ← React UI prototype (replicate EXACTLY in Flutter)
  todo.md             ← Create this. Task registry. Single source of truth.
  progress.md         ← Create this. Live progress log.
```

**Mandatory first steps:**
1. Read `assets/spec.pdf` completely — architecture, data model, APIs, roles, offline rules
2. Read `assets/prototype.jsx` completely — every screen, color, component, interaction
3. Extract and write `todo.md` (template in Section 9)
4. Write initial `progress.md` entry
5. THEN begin coding

---

## 1. Project Mission

Build **সহজ বাজার খাতা** — a collaborative office market and expense management Flutter app.

**Core promise:** বাজারের তালিকা, খরচ, আর টাকা কার কাছে কত আছে — সব এক জায়গায় সহজভাবে।

**Key constraints:**
- **No backend yet.** Use mock implementations behind abstract interfaces. Every mock must be swappable with a real API client by changing a single provider registration — zero other code changes.
- **Offline-first mandatory from day 1.** Drift (SQLite) is the primary data store. Remote is secondary.
- **Design parity with prototype.jsx is non-negotiable.** Colors, spacing, typography, component shapes — replicate exactly.
- **Bangla text throughout UI.** Use system fonts with Bangla fallback chain.

---

## 2. Architecture

### 2.1 Pattern: Feature-First Clean Architecture

```
lib/
├── main.dart
├── bootstrap.dart              ← ProviderScope, DI setup, Drift DB init
├── app.dart                    ← MaterialApp.router, theme, GoRouter
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart     ← ALL colors from prototype (no magic numbers elsewhere)
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart     ← GoRouter, all routes, guards
│   ├── network/
│   │   ├── dio_client.dart     ← Dio instance, interceptors
│   │   └── api_exception.dart
│   ├── database/
│   │   ├── app_database.dart   ← Drift DB definition (all tables)
│   │   └── app_database.g.dart
│   ├── sync/
│   │   ├── sync_engine.dart    ← SyncQueue processor
│   │   ├── sync_queue_dao.dart
│   │   └── connectivity_service.dart
│   ├── error/
│   │   └── failures.dart
│   └── utils/
│       ├── balance_formatter.dart  ← "হাতে আছে / পাওনা / মিলে গেছে" logic
│       ├── date_formatter.dart     ← Bangla date formatting
│       └── currency_formatter.dart ← ৳ formatting with Bengali numerals
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_local_datasource.dart
│   │   │   │   └── auth_remote_datasource.dart   ← interface + mock + real
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/user.dart
│   │   │   ├── repositories/auth_repository.dart  ← abstract
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       └── get_current_user_usecase.dart
│   │   └── presentation/
│   │       ├── screens/login_screen.dart
│   │       └── providers/auth_provider.dart
│   │
│   ├── wallet/         ← Balance, Wallet Detail, Assistant Ledger
│   ├── bazar/          ← Bazar List, Detail, New Bazar, Add Item, Summary
│   ├── item/           ← Item edit sheet, Price History
│   ├── money/          ← Money Entry, Direct Expense
│   ├── reports/        ← Reports screen, Monthly Close
│   ├── notifications/  ← Notifications screen
│   ├── search/         ← Search screen
│   ├── admin/          ← Admin Panel, Add User
│   ├── comments/       ← Bazar Comments
│   ├── sync/           ← Offline Queue screen
│   └── settings/       ← Settings, Profile Edit
│
└── shared/
    ├── widgets/
    │   ├── app_bar.dart
    │   ├── balance_card.dart
    │   ├── bazar_card.dart
    │   ├── item_tile.dart
    │   ├── status_chip.dart
    │   ├── wallet_selector.dart
    │   ├── sync_badge.dart
    │   ├── bottom_sheet_handle.dart
    │   ├── primary_button.dart
    │   ├── ghost_button.dart
    │   ├── section_header.dart
    │   └── frequent_items_row.dart
    ├── models/           ← shared enums (ItemStatus, BazarStatus, EntryType, Role)
    └── providers/        ← shared providers (syncStatusProvider, currentUserProvider)
```

### 2.2 Layered Dependency Rule
```
presentation → domain ← data
a presentation does NOT import data
data does NOT import presentation
All cross-feature communication goes through domain entities only
```

### 2.3 Mock → API Migration Strategy

Every remote data source follows this pattern:

```dart
// 1. Define abstract interface
abstract class BazarRemoteDataSource {
  Future<List<BazarModel>> getBazars({String? walletId, String? status});
  Future<BazarModel> createBazar(CreateBazarDto dto);
  Future<void> closeBazar(String id);
  // ... all API methods
}

// 2. Mock implementation (used from day 1, NO real network)
class MockBazarRemoteDataSource implements BazarRemoteDataSource {
  // Returns static data matching prototype.jsx exactly
  // Add artificial 300-500ms delay to simulate real API
  // Supports in-memory state mutations (create/update/delete work in memory)
}

// 3. Real implementation (added later, implements same interface)
class ApiBazarRemoteDataSource implements BazarRemoteDataSource {
  final Dio _dio;
  // Makes real HTTP calls to Laravel API
}

// 4. Provider registration — THE ONLY PLACE TO CHANGE
@riverpod
BazarRemoteDataSource bazarRemoteDataSource(Ref ref) {
  // Toggle this line when API is ready:
  // return ApiBazarRemoteDataSource(ref.watch(dioClientProvider));
  return MockBazarRemoteDataSource();
}
```

**Rule:** Mock data must exactly match the entities shown in `prototype.jsx` (same wallets, same bazar names, same items, same balances). This ensures the UI looks identical to the prototype from the first run.

---

## 3. Package List

### pubspec.yaml — Required Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # ── State Management ──────────────────────────────
  flutter_riverpod: ^2.6.1          # State management
  riverpod_annotation: ^2.3.5       # Code generation for providers

  # ── Navigation ────────────────────────────────────
  go_router: ^14.6.3                # Declarative routing, deep links, guards

  # ── Local Database (Offline-First) ────────────────
  drift: ^2.21.0                    # SQLite ORM, reactive queries
  sqlite3_flutter_libs: ^0.5.0      # SQLite native binaries
  path_provider: ^2.1.5             # DB file path
  path: ^1.9.1

  # ── Networking ────────────────────────────────────
  dio: ^5.7.0                       # HTTP client
  retrofit: ^4.4.2                  # Type-safe API client generator
  pretty_dio_logger: ^1.4.0         # Dev-only request logging

  # ── Connectivity & Sync ───────────────────────────
  connectivity_plus: ^6.1.0         # Network status detection

  # ── Secure Storage ────────────────────────────────
  flutter_secure_storage: ^9.2.2    # Auth token storage

  # ── Image Handling ────────────────────────────────
  image_picker: ^1.1.2              # Camera + gallery for receipts
  cached_network_image: ^3.4.1      # Remote image with cache

  # ── Push Notifications ────────────────────────────
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1

  # ── Internationalization ──────────────────────────
  intl: ^0.19.0                     # Date/number formatting

  # ── Utilities ─────────────────────────────────────
  freezed_annotation: ^2.4.4        # Immutable data classes
  json_annotation: ^4.9.0           # JSON serialization
  equatable: ^2.0.7                 # Value equality
  uuid: ^4.5.1                      # UUID generation for local records
  collection: ^1.19.1               # List/map utilities
  crypto: ^3.0.6                    # SHA-256 for snapshot hash (v1.5)

  # ── UI ────────────────────────────────────────────
  flutter_svg: ^2.0.16              # SVG icons if needed
  shimmer: ^3.0.0                   # Loading skeleton screens
  lottie: ^3.2.0                    # Animated success/empty states
  gap: ^3.0.1                       # Spacing widget (replaces SizedBox everywhere)
  percent_indicator: ^4.2.4         # Bar charts for reports screen

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.13
  riverpod_generator: ^2.4.3
  drift_dev: ^2.21.0
  retrofit_generator: ^9.1.7
  freezed: ^2.5.7
  json_serializable: ^6.8.0

  # Testing
  mocktail: ^1.0.4                  # Mocking for unit tests
  fake_async: ^1.3.2                # Control time in tests

flutter:
  uses-material-design: true
  assets:
    - assets/spec.pdf
    - assets/prototype.jsx
    - assets/images/
    - assets/animations/
```

---

## 4. Design Token Implementation

Extract these exact values from `prototype.jsx` into `app_colors.dart`:

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  // Primary
  static const primary       = Color(0xFF1565C0);
  static const primaryDark   = Color(0xFF0D47A1);
  static const primaryLight  = Color(0xFFEFF6FF);
  static const primaryText   = Color(0xFF1E3A5F);

  // Surfaces
  static const surface       = Color(0xFFFFFFFF);
  static const surface2      = Color(0xFFF8FAFC);
  static const surface3      = Color(0xFFF1F5F9);
  static const border        = Color(0xFFE2E8F0);
  static const border2       = Color(0xFFCBD5E1);

  // Text
  static const text1         = Color(0xFF0F172A);
  static const text2         = Color(0xFF334155);
  static const text3         = Color(0xFF64748B);
  static const text4         = Color(0xFF94A3B8);

  // Positive (balance > 0)
  static const positive      = Color(0xFF15803D);
  static const positiveLight = Color(0xFFDCFCE7);
  static const positiveDark  = Color(0xFF14532D);
  static const positiveCard  = Color(0xFF166534);

  // Negative (balance < 0)
  static const negative      = Color(0xFFDC2626);
  static const negativeLight = Color(0xFFFEE2E2);
  static const negativeDark  = Color(0xFF7F1D1D);
  static const negativeCard  = Color(0xFF991B1B);

  // Warning / in-progress
  static const warning       = Color(0xFFD97706);
  static const warningLight  = Color(0xFFFEF3C7);
  static const warningDark   = Color(0xFF78350F);

  // Neutral card bg
  static const neutralCard   = Color(0xFF1E3A5F);
}
```

---

## 5. Offline-First Data Flow

```
User Action
    │
    ▼
Repository.write(entity)
    │
    ├─► Drift local DB (immediate, synchronous-feel via Isolate)
    │       │
    │       └─► UI updates instantly via Stream (Riverpod watches Drift query)
    │
    └─► SyncQueue.enqueue(operation)
            │
            └─► SyncEngine (background Isolate)
                    │
                    ├─ Online? ──► POST/PUT/DELETE to API ──► mark synced
                    │
                    └─ Offline? ─► persist in sync_queue table
                                  ─► retry on connectivity restore
                                  ─► exponential backoff (1s, 2s, 4s, max 30s)

Sync Conflict Resolution:
  - Server receives two conflicting updates
  - Rule: latest `updated_at` timestamp wins
  - Loser version preserved in activity_logs
  - Admin UI (Offline Queue screen) shows conflicts
```

### Drift SyncQueue Table

```dart
// In app_database.dart
class SyncQueueItems extends Table {
  IntColumn get id       => integer().autoIncrement()();
  TextColumn get entityType => text()();  // 'bazar_item' | 'money_entry' | etc
  TextColumn get entityId   => text()();  // UUID
  TextColumn get operation  => text()();  // 'create' | 'update' | 'delete'
  TextColumn get payload    => text()();  // JSON
  IntColumn  get createdAt  => integer()();  // Unix ms
  IntColumn  get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError  => text().nullable()();
  BoolColumn get isSynced   => boolean().withDefault(const Constant(false))();
}
```

### Balance Calculation Rule

**NEVER store balance as a field.** Always compute:

```dart
// lib/core/utils/balance_calculator.dart
class BalanceCalculator {
  /// Called in repository layer. Returns live Stream via Drift.
  Stream<BalanceResult> watchBalance({
    required String walletId,
    required String assistantId,
  }) {
    // Uses last snapshot closing_balance as base (if exists)
    // + SUM(money_received) since snapshot
    // - SUM(item prices where status=done) since snapshot
    // - SUM(direct_expenses) since snapshot
    // - SUM(money_returned) since snapshot
    // +/- SUM(adjustments) since snapshot
    //
    // Returns BalanceResult {
    //   confirmedBalance,
    //   inProgressAmount,
    //   estimatedBalance,
    //   label,
    // }
  }
}
```

---

## 6. Sub-Agent Task Division

**Orchestrator Agent** (you) manages the full task graph. Spawn sub-agents as parallel Tasks. Each sub-agent must:
1. Read `todo.md` and claim their assigned tasks (mark status: `in_progress`)
2. Update `progress.md` on every meaningful milestone
3. NEVER modify files owned by another agent (ownership defined below)
4. Write tests for every use case and repository method

---

### Agent A — Foundation (run FIRST, blocks all others)

**Owns:** `pubspec.yaml`, `lib/main.dart`, `lib/bootstrap.dart`, `lib/app.dart`, `lib/core/database/`, `lib/core/theme/`, `lib/core/router/`

**Tasks:**
```
A1. Initialize Flutter project (android + ios targets)
A2. Add all packages from Section 3, run flutter pub get
A3. Implement app_colors.dart — ALL tokens from prototype.jsx
A4. Implement app_text_styles.dart + app_theme.dart (Material 3, light mode only for MVP)
A5. Implement app_database.dart — ALL Drift tables (wallets, bazars, bazar_items,
    money_entries, direct_expenses, wallet_snapshots, sync_queue, users, activity_logs,
    comments, attachments, wallet_members, wallet_assistant_restrictions)
A6. Run drift codegen: flutter pub run build_runner build
A7. Implement app_router.dart — GoRouter with all 24 routes + auth guard
A8. Implement bootstrap.dart — ProviderScope, DB init, Firebase init
A9. Write shared widgets: AppBar, PrimaryButton, GhostButton, SectionHeader,
    StatusChip, SyncBadge, Divider, FrequentItemsRow, BottomSheetHandle
A10. Write shared enums: ItemStatus, BazarStatus, EntryType, UserRole, SyncStatus
A11. Create mock seed data (lib/core/mock/mock_seed.dart) — exact data from prototype.jsx
A12. Write balance_formatter.dart, date_formatter.dart, currency_formatter.dart
```

**Signal when done:** Write `## Agent A: COMPLETE` in `progress.md`

---

### Agent B — Auth + Current User (depends on A)

**Owns:** `lib/features/auth/`

**Tasks:**
```
B1. Define User entity + AuthRepository abstract interface
B2. MockAuthRemoteDataSource — login always succeeds with seeded user
B3. LocalAuthDataSource — token in flutter_secure_storage
B4. AuthRepositoryImpl — local + remote composition
B5. LoginScreen — replicate prototype.jsx login exactly
B6. currentUserProvider — StreamProvider<User?> used app-wide
B7. Auth guard in GoRouter — redirect to /login if no token
B8. Logout flow — clear token, clear DB (optional based on spec)
B9. Unit tests for AuthRepository
```

---

### Agent C — Wallet + Balance (depends on A)

**Owns:** `lib/features/wallet/`

**Tasks:**
```
C1. Wallet entity + WalletRepository abstract + MockWalletRemoteDataSource
C2. Drift DAOs: WalletDao, WalletMemberDao, WalletSnapshotDao
C3. BalanceCalculator (streaming from Drift)
C4. BalanceResult entity { confirmedBalance, inProgressAmount, estimatedBalance, label }
C5. WalletRepositoryImpl
C6. WalletListProvider, WalletBalanceProvider (FutureProvider + StreamProvider)
C7. BalanceScreen — replicate prototype exactly
C8. WalletDetailScreen — replicate prototype exactly
C9. AssistantLedgerScreen — full double-entry ledger table per assistant
C10. Tests for BalanceCalculator with edge cases (negative, zero, in-progress)
```

---

### Agent D — Bazar Core (depends on A)

**Owns:** `lib/features/bazar/`

**Tasks:**
```
D1. Bazar entity + BazarRepository abstract + MockBazarRemoteDataSource
D2. Drift DAOs: BazarDao, BazarItemDao
D3. BazarRepositoryImpl (local Drift + remote mock)
D4. BazarListScreen — replicate prototype
D5. BazarDetailScreen — replicate prototype fully
D6. ItemEditSheet — bottom sheet overlay
D7. BazarSummaryScreen — post-close summary
D8. ActivityTimelineWidget — reads activity_logs from Drift
D9. Tests: BazarRepository, item status transitions, balance impact
```

---

### Agent E — New Bazar + Add Item + Direct Expense

**Owns:**
- `lib/features/bazar/presentation/screens/new_bazar_screen.dart`
- `lib/features/bazar/presentation/screens/add_item_screen.dart`
- `lib/features/money/presentation/screens/direct_expense_screen.dart`

**Tasks:**
```
E1. NewBazarScreen — dual mode
E2. AddItemScreen
E3. DirectExpenseScreen
E4. FrequentItemsProvider
E5. AutoParseService
```

---

### Agent F — Money Entry + Reports + Monthly Close

**Owns:** `lib/features/money/`, `lib/features/reports/`

**Tasks:**
```
F1. MoneyEntry entity + MoneyEntryRepository abstract + Mock
F2. Drift DAO: MoneyEntryDao + DirectExpenseDao
F3. MoneyEntryRepositoryImpl
F4. MoneyEntryScreen
F5. ReportsScreen
F6. MonthlyCloseScreen
F7. Tests
```

---

### Agent G — Admin + Notifications + Search

**Owns:** `lib/features/admin/`, `lib/features/notifications/`, `lib/features/search/`

**Tasks:**
```
G1. Admin entities + mock datasource
G2. AdminScreen
G3. AddUserScreen
G4. NotificationsScreen
G5. SearchScreen
G6. Push notification handler scaffold
G7. Tests
```

---

### Agent H — Settings + More + Comments + Price History

**Owns:** `lib/features/settings/`, `lib/features/comments/`

**Tasks:**
```
H1. MoreScreen
H2. ProfileEditScreen
H3. SettingsScreen
H4. OfflineQueueScreen
H5. BazarCommentsScreen
H6. PriceHistoryScreen
H7. Tests
```

---

### Agent I — Sync Engine + Connectivity

**Owns:** `lib/core/sync/`

**Tasks:**
```
I1. ConnectivityService
I2. SyncEngine
I3. SyncStatusProvider
I4. enqueue service
I5. Drift-to-API mappers
I6. Tests
```

---

## 7. todo.md Template

Create this file at project root on day 1. Every agent updates it.

```markdown
# সহজ বাজার খাতা — Task Registry

> Last updated: [timestamp]
> Status: 🔴 not_started | 🟡 in_progress | 🟢 done | ⛔ blocked

## Phase 1 — Foundation (Agent A) [BLOCKS ALL]
- [ ] A1. Flutter project init                         | Agent A | 🔴
- [ ] A2. pubspec.yaml + pub get                       | Agent A | 🔴
- [ ] A3. app_colors.dart                              | Agent A | 🔴
- [ ] A4. app_theme.dart                               | Agent A | 🔴
- [ ] A5. Drift DB all tables                          | Agent A | 🔴
- [ ] A6. Drift codegen                                | Agent A | 🔴
- [ ] A7. GoRouter all 24 routes                       | Agent A | 🔴
- [ ] A8. bootstrap.dart                               | Agent A | 🔴
- [ ] A9. Shared widgets (9 widgets)                   | Agent A | 🔴
- [ ] A10. Shared enums                                | Agent A | 🔴
- [ ] A11. Mock seed data                              | Agent A | 🔴
- [ ] A12. Formatters (balance/date/currency)          | Agent A | 🔴
```

---

## 8. progress.md Template

```markdown
# Build Progress Log

## [DATE TIME] — Agent A — Project initialized
- Created Flutter project targeting Android + iOS
- Added all packages. `flutter pub get` successful.
- Known issues: none
```

---

## 9. Coding Standards

- Feature-first clean architecture
- Presentation depends on domain, never data
- Bangla UI strings centralized
- Repositories should not throw raw exceptions
- All writes go to Drift first
- Tests required for repositories and critical logic

---

## 10. Mock Data Contract

Mock seed data must exactly match `prototype.jsx`:
- wallets
- bazars
- bazar items
- frequent items
- balances
- labels and statuses

---

## 11. API Readiness Checklist

When backend is ready:
- set base URL
- swap provider registration from mock to api
- keep interfaces unchanged
- run integration tests

---

## 12. Critical Rules (Do Not Violate)

1. Balance is never a stored field.
2. Mock and real must share identical interfaces.
3. All writes go to Drift first.
4. New Bazar must always support both text and manual modes.
5. Optional fields collapsed by default.
6. Monthly close = hard lock.
7. Button label must remain: `আজকের বাজার শেষ`.
8. Colors from `app_colors.dart` only.
9. Replicate `prototype.jsx` exactly.
10. Offline mode is mandatory.
