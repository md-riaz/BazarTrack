# সহজ বাজার খাতা — Market Khata

Offline-first Flutter app for collaborative office market, wallet, expense, and assistant balance management.

Core promise: বাজারের তালিকা, খরচ, আর টাকা কার কাছে কত আছে — সব এক জায়গায় সহজভাবে।

## Current implementation status

Implemented from `AGENTS_PROMPT.md`:

- Flutter + Riverpod + GoRouter app foundation
- Drift SQLite offline-first database and generated code
- Auth with secure-storage local session and mock remote source
- Wallet, balance, assistant ledger, and dynamic balance calculation
- Bazar list/detail/new/add-item/summary flows
- Money entry, direct expense, reports, and monthly close flows
- Admin, add user, notifications, and search flows
- More/settings/profile/offline queue/comments/price history flows
- Sync queue, connectivity abstraction, sync engine, API-client seam, and Drift-to-API mappers
- Router integration for implemented screens
- Mock data matching the prototype seed shape

## Architecture

Feature-first clean architecture:

```text
lib/
  core/
    database/     Drift schema and generated database
    router/       GoRouter routes and auth guard
    sync/         Offline sync queue and sync engine
    theme/        App colors, text styles, Material theme
    utils/        Currency/date/balance helpers
  features/
    auth/
    wallet/
    bazar/
    money/
    reports/
    admin/
    notifications/
    search/
    settings/
    comments/
  shared/
    models/
    providers/
    widgets/
```

Layering rule:

```text
presentation -> domain <- data
```

Presentation does not import data directly. Cross-feature use should go through domain/repository/provider seams.

## Offline-first rules

- Drift is the primary read/write store.
- UI reads from local state first.
- Writes persist locally before sync.
- Sync work is tracked in `sync_queue_items`.
- `SyncEngine` publishes pending rows through `SyncApiClient`.
- Current API implementation is mock/sink-based and swappable.

Balance is never stored as a wallet field. It is computed from:

- money received
- money returned
- adjustments
- direct expenses
- done bazar item prices
- latest wallet snapshot base
- in-progress bazar spending

## Mock-to-API handoff

The app is backend-ready through abstract seams:

- Auth: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Wallet: `lib/features/wallet/data/datasources/mock_wallet_remote_datasource.dart`
- Bazar: `lib/features/bazar/data/datasources/mock_bazar_remote_data_source.dart`
- Money: `lib/features/money/data/datasources/mock_money_remote_datasource.dart`
- Admin/notifications/search mock data sources under their feature folders
- Sync API seam: `lib/core/sync/sync_api_client.dart`

When backend is ready:

1. Add real API datasource classes implementing existing interfaces.
2. Swap provider registration only.
3. Keep domain repositories and UI unchanged.
4. Run repository, sync, and integration tests.

## Requirements

- Flutter SDK with Dart compatible with `sdk: ^3.11.1`
- Android SDK for APK builds
- iOS tooling for iOS builds if targeting iOS

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
flutter run
```

The app starts at `/login`. Demo login accepts any input and signs in as the seeded user.

## Test and validation

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Current verified baseline:

- `flutter analyze` — no issues
- `flutter test` — 63 tests passed
- Debug APK build passes after enabling Android core library desugaring

## Important routes

- `/login`
- `/`
- `/bazars`
- `/bazars/detail`
- `/bazars/new`
- `/bazars/items/add`
- `/bazars/summary`
- `/balance`
- `/wallets/detail`
- `/wallets/assistant-ledger`
- `/money/entry`
- `/money/direct-expense`
- `/reports`
- `/reports/monthly-close`
- `/admin`
- `/admin/users/add`
- `/notifications`
- `/search`
- `/more`
- `/settings`
- `/sync/offline-queue`
- `/comments`
- `/items/price-history`

## Key product constraints

- Bangla UI first.
- Optional item fields collapsed by default.
- New Bazar supports both manual and text/auto-parse modes.
- Button label remains `আজকের বাজার শেষ`.
- Monthly close is a hard lock.
- No backend required for MVP demo; all remote behavior is mocked behind interfaces.
