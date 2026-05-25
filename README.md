# সহজ বাজার খাতা — BazarTrack

BazarTrack is an offline-first Flutter app for collaborative office market management: bazar lists, wallet balances, assistant advances, direct expenses, reports, and monthly closing. The UI is Bangla-first with common English/Banglish product terms where they are more natural for daily users.

## Key Features

- Role-based demo login for **Admin**, **Owner**, and **Assistant** verification.
- Real dashboard with wallet summary, recent bazars, sync status, and quick actions.
- Create bazars manually or from pasted text lists.
- Add bazar items from frequent items, manual entry, or parsed text.
- Wallet balance and assistant ledger tracking.
- Money received/returned entries and direct expenses.
- Reports and monthly close flows.
- Admin panel for user/wallet management.
- Offline-first Drift SQLite storage with sync queue UI.
- GoRouter navigation with bottom tabs, inner page back navigation, and root exit confirmation.

## Tech Stack

- **Language**: Dart `^3.11.1`
- **Framework**: Flutter
- **State management**: Riverpod
- **Routing**: GoRouter
- **Local database**: Drift + SQLite
- **Networking seams**: Dio/Retrofit + mock remote datasources
- **Offline/sync**: Drift-backed sync queue, connectivity abstraction, sync engine seam
- **Notifications**: Firebase Messaging + Flutter Local Notifications dependencies wired for future production use
- **Testing**: Flutter tests, provider tests, widget tests

## Prerequisites

- Flutter SDK with Dart compatible with `sdk: ^3.11.1`
- Android SDK for APK builds
- iOS tooling if building for iOS

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Build a debug APK:

```bash
flutter build apk --debug
```

APK output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Demo Role Login

The login screen currently exposes temporary demo buttons so QA can verify role-specific behavior before production auth is connected.

| Button | Mock user | Role | Main purpose |
| --- | --- | --- | --- |
| `Login as Admin` | Admin User | Admin | Verify admin panel, all wallets/bazars, reports, money entry, direct expense |
| `Login as Owner` | Mr. CEO | Owner | Verify owned wallets, reports, monthly close, money entry |
| `Login as Assistant` | Rahim Uddin | Assistant | Verify shopping/bazar flow, direct expense, restricted reports/admin access |

The demo buttons are controlled by a compile-time flag in `login_screen.dart`:

```dart
const kEnableDemoRoleLogin = bool.fromEnvironment(
  'BAZAR_ENABLE_DEMO_ROLE_LOGIN',
  defaultValue: true,
);
```

To hide them in a future production-like build:

```bash
flutter build apk --debug --dart-define=BAZAR_ENABLE_DEMO_ROLE_LOGIN=false
```

## Role-Based App Flows

### Assistant Flow

Use **Login as Assistant**.

Assistant is the best role for verifying day-to-day shopping work.

Expected visible actions:

- Home dashboard
- Bazar list
- New bazar
- Balance
- Direct expense
- More/settings/offline queue

Expected hidden/restricted actions:

- Reports tab hidden
- Money entry hidden
- Admin panel hidden
- Monthly close hidden from More menu

#### Assistant: Create a Bazar and Add Items

1. Tap **Login as Assistant**.
2. From Home, tap **নতুন বাজার**.
3. On **নতুন বাজার** screen:
   - Select a **Wallet**.
   - Choose input mode:
     - **Manual**: type item name and optionally quantity/unit/brand.
     - **Text**: paste one item per line, e.g.
       ```text
       আলু ২ কেজি
       ডিম ১২টা
       দুধ ২ প্যাকেট
       ```
   - Optional: edit title/note.
4. Tap **বাজার তৈরি করুন →**.
5. The app opens the bazar detail page.
6. Tap **আইটেম যোগ**.
7. On **আইটেম যোগ করুন**:
   - Tap a frequent item, or
   - Type **আইটেম নাম**.
   - Optional: expand quantity/unit/brand/note.
8. Tap:
   - **+ আরেকটি** to add and stay on the item screen.
   - **✓ শেষ করুন** to add and return to bazar detail.
9. Back on bazar detail, tap an item to edit status/price through the item edit sheet.
10. Tap **আজকের বাজার শেষ** when the shopping is complete.

Relevant screens:

- `lib/features/bazar/presentation/screens/new_bazar_screen.dart`
- `lib/features/bazar/presentation/screens/bazar_detail_screen.dart`
- `lib/features/bazar/presentation/screens/add_item_screen.dart`

### Owner Flow

Use **Login as Owner**.

Owner is for money and reporting verification.

Expected visible actions:

- Home dashboard
- Bazar list
- New bazar
- Balance
- Reports tab
- Money entry
- Monthly close from More menu

Expected hidden/restricted actions:

- Admin panel hidden
- Direct expense hidden from home quick actions

Suggested verification path:

1. Tap **Login as Owner**.
2. Confirm Home shows `Mr. CEO — মালিক`.
3. Confirm Reports tab is visible.
4. Tap **টাকা এন্ট্রি** to verify owner/admin money entry access.
5. Go to **Reports** and verify monthly summary/report UI.
6. Go to **More** and verify:
   - Reports visible
   - Close হিসাব visible
   - Admin panel not visible
7. Go to **Balance** and verify owner-scoped wallets only.
8. Create a bazar from **নতুন বাজার** if you need to verify owner-created bazar flow for an owned wallet.

### Admin Flow

Use **Login as Admin**.

Admin is for full-access verification.

Expected visible actions:

- All dashboard actions
- Bazar list/new bazar
- Balance
- Reports
- Money entry
- Direct expense
- Admin panel
- Add user
- Add wallet
- More/settings/offline queue

Suggested verification path:

1. Tap **Login as Admin**.
2. Confirm Home shows `Admin User — অ্যাডমিন`.
3. Verify Reports tab is visible.
4. Verify both **টাকা এন্ট্রি** and **সরাসরি খরচ** are visible.
5. Go to **More** and verify **অ্যাডমিন প্যানেল** is visible.
6. Open Admin panel and verify add user/add wallet entry points.
7. Go to Balance and verify all wallets are visible.
8. Go to Bazar list and verify all bazars are visible.
9. Create a bazar and add items using the same flow as Assistant.

## Practical Role Playbooks

These are end-to-end ways to use the app with the current demo roles. They are written as real QA/user stories, not just permission checks.

### Owner Places a Bazar List for an Assistant

Use this when an owner wants to prepare a shopping list and let an assistant complete the market work.

Current supported app behavior:

- Owner can create a bazar under an owned wallet.
- Owner/Admin can pick a specific assistant in **Assign assistant**.
- Assistant can see bazars where `assignedTo == null` or `assignedTo == assistant.id`.
- If no assistant is selected, the bazar stays unassigned/team-visible for assistants.

Steps:

1. Login with **Login as Owner**.
2. Tap **নতুন বাজার** from Home.
3. Select the owner wallet, for example `CEO Personal`.
4. Under **Assign assistant**, pick an active assistant such as `Rahim Uddin`, or leave it as unassigned if any assistant can take it.
5. Choose input mode:
   - **একে একে** for adding items one by one.
   - **টেক্সট** for pasting a ready shopping list.
6. If using text mode, paste a list like:

   ```text
   আলু ২ কেজি
   পেঁয়াজ ১ কেজি
   ডিম ১২টা
   দুধ ২ প্যাকেট
   ```

7. Keep title as `আজকের বাজার` or rename it, e.g. `CEO Personal বাজার`.
8. Tap **বাজার তৈরি করুন →**.
9. Logout from More.
10. Login with **Login as Assistant**.
11. Open **বাজার** tab.
12. Find the bazar assigned to that assistant, or any unassigned bazar.
13. Open it and use:
    - **আইটেম যোগ** if more items are needed.
    - item tap/edit sheet to mark items done/not found and enter price.
14. Tap **আজকের বাজার শেষ** when shopping is done.
15. Logout and login as Owner again.
16. Owner checks **Balance** and **Reports** to review spend and remaining balance.

This flow is the direct owner-to-assistant handoff path in the app.

### Owner Gives Money to Assistant Before Shopping

Use this when an owner advances cash to an assistant.

1. Login with **Login as Owner**.
2. Tap **টাকা এন্ট্রি** from Home.
3. Select wallet/assistant fields shown on the money entry screen.
4. Enter the amount given to the assistant.
5. Save the entry.
6. Go to **Balance**.
7. Open the wallet or assistant ledger to verify the assistant balance changed.
8. Assistant can then login and complete bazar shopping.

Expected restrictions:

- Assistant should not see **টাকা এন্ট্রি**.
- Owner should not see **সরাসরি খরচ** from Home quick actions.

### Assistant Completes Shopping from an Owner List

Use this after an owner has created a bazar list.

1. Login with **Login as Assistant**.
2. Open **বাজার** tab.
3. Open the available unassigned/self bazar.
4. Review the item list.
5. Tap any item to update:
   - purchased/done status
   - price
   - not found status
   - notes
6. Tap **আইটেম যোগ** if an extra item needs to be added.
7. Use **+ আরেকটি** for multiple items or **✓ শেষ করুন** to return.
8. If there is a direct expense outside a bazar, go Home and tap **সরাসরি খরচ**.
9. Finish the bazar with **আজকের বাজার শেষ**.
10. Check More → Sync queue if offline work is pending.

Expected restrictions:

- Reports tab hidden.
- Money entry hidden.
- Monthly close hidden.
- Admin panel hidden.

### Owner Reviews Work and Closes Month

Use this after assistants have entered bazar prices and direct expenses.

1. Login with **Login as Owner**.
2. Open **Balance** to review wallet and assistant balances.
3. Open **Reports** to review monthly spend.
4. Open **More**.
5. Tap **Close হিসাব**.
6. Review monthly close data.
7. Complete close only after checking outstanding balances and pending sync queue.

Expected restrictions:

- Owner can access reports/monthly close.
- Owner cannot access admin panel.

### Admin Sets Up Demo Operating Structure

Use this when verifying admin-only operations.

1. Login with **Login as Admin**.
2. Open **More**.
3. Tap **অ্যাডমিন প্যানেল**.
4. Verify user and wallet management options.
5. Use add user/add wallet entry points if needed.
6. Return to Home.
7. Verify Admin can see:
   - Reports
   - Money entry
   - Direct expense
   - Admin panel
   - all wallets
   - all bazars
8. Create a bazar and add items to verify Admin can perform operational work too.

### Admin Audits Role Visibility

Use this to confirm role scoping during QA.

1. Login as Admin and note all wallets/bazars are visible.
2. Logout.
3. Login as Owner and confirm only owner/member wallets are visible.
4. Logout.
5. Login as Assistant and confirm only unassigned/self-assigned bazars are visible.
6. Verify assistant cannot see Reports/Admin/Money Entry.

## Direct Assistant Assignment

The **নতুন বাজার** screen includes an **Assign assistant** section for Owner/Admin. It lists active assistants and also supports an unassigned option.

Supported handoff flows:

```text
Owner/Admin assigns bazar to Rahim → Rahim sees it → Rahim completes shopping
Owner/Admin leaves bazar unassigned → assistants can see it → any assistant can take/action it
```

Assistant filtering respects:

```text
assignedTo == null || assignedTo == currentAssistant.id
```

## Bazar Creation and Item Entry Details

### Create Bazar

Route:

```text
/bazars/new
```

Entry points:

- Home quick action: **নতুন বাজার**
- Bazar-related navigation after login

Important behavior:

- `/bazars/new` must be matched before `/bazars/:bazarId` so `new` is not treated as a bazar ID.
- The screen supports **Manual** and **Text** input modes.
- Manual mode supports adding multiple items before creating the bazar.
- Text mode parses one item per line.
- Create button: **বাজার তৈরি করুন →**
- Draft button: **Draft সংরক্ষণ করুন**

### Add Items After Bazar Creation

From bazar detail:

- Action button: **আইটেম যোগ**
- Opens: **আইটেম যোগ করুন**
- Supports:
  - Frequent item chips
  - Manual item name
  - Optional quantity/unit/brand/note
  - **+ আরেকটি** to keep adding
  - **✓ শেষ করুন** to finish and return

### Edit Existing Items

On bazar detail, tapping an item opens the item edit sheet unless the bazar is closed.

Use this to verify:

- purchased/done status
- not found status
- price entry
- notes/status changes

## Role Permissions Summary

| Capability | Assistant | Owner | Admin |
| --- | --- | --- | --- |
| Login via demo button | Yes | Yes | Yes |
| Home dashboard | Yes | Yes | Yes |
| Create bazar | Yes | Yes | Yes |
| Add bazar item | Yes | Yes, where accessible | Yes |
| Direct expense | Yes | No | Yes |
| Money entry | No | Yes | Yes |
| Reports tab | No | Yes | Yes |
| Monthly close | No | Yes | Yes |
| Admin panel | No | No | Yes |
| Wallet visibility | Active wallets | Owned/member wallets | All wallets |
| Bazar visibility | Unassigned or assigned to self | Bazars in visible wallets | All bazars |

## Architecture

Feature-first clean architecture:

```text
lib/
  core/
    database/     Drift schema and generated database
    mock/         Seed data for local/demo runs
    router/       GoRouter routes, shell, redirects, role guards
    sync/         Offline sync queue and sync engine
    theme/        App colors, text styles, Material theme
    utils/        Currency/date/balance helpers
  features/
    admin/
    auth/
    bazar/
    comments/
    money/
    notifications/
    reports/
    search/
    settings/
    wallet/
  shared/
    models/
    providers/
    widgets/
```

Layering rule:

```text
presentation -> domain <- data
```

Presentation should use providers/repositories rather than directly reaching across into data implementation details.

## Offline-First Rules

- Drift is the primary local store.
- UI reads local state first.
- Writes persist locally before sync.
- Sync work is tracked in `sync_queue_items`.
- `SyncEngine` publishes pending rows through `SyncApiClient`.
- Current API implementation is mock/sink-based and swappable.

Balance is computed from:

- money received
- money returned
- adjustments
- direct expenses
- done bazar item prices
- latest wallet snapshot base
- in-progress bazar spending

Balance is not stored as a wallet field.

## Mock-to-API Handoff

The app is backend-ready through abstract seams:

- Auth: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Wallet: `lib/features/wallet/data/datasources/mock_wallet_remote_datasource.dart`
- Bazar: `lib/features/bazar/data/datasources/mock_bazar_remote_data_source.dart`
- Money: `lib/features/money/data/datasources/mock_money_remote_datasource.dart`
- Sync API seam: `lib/core/sync/sync_api_client.dart`

When backend is ready:

1. Add real API datasource classes implementing the existing interfaces.
2. Swap provider registration only.
3. Keep domain repositories and UI unchanged.
4. Run repository, sync, widget, and integration tests.
5. Disable demo role buttons for production builds.

## Important Routes

```text
/login
/
/bazars
/bazars/new
/bazars/:bazarId
/bazars/:bazarId/items/add
/bazars/:bazarId/summary
/bazars/:bazarId/comments
/bazars/:bazarId/price-history
/balance
/wallets/:walletId
/wallets/:walletId/assistant/:assistantId
/money/entry
/money/direct-expense
/reports
/reports/monthly-close
/admin
/admin/users/add
/admin/wallets/add
/notifications
/search
/more
/settings
/sync/offline-queue
/profile/edit
```

## Testing and Validation

Run static analysis:

```bash
flutter analyze
```

Run all tests:

```bash
flutter test
```

Run role-focused tests:

```bash
flutter test test/widget_test.dart
flutter test test/features/auth/data/repositories/auth_repository_impl_test.dart
flutter test test/features/settings/settings_screens_test.dart
flutter test test/features/wallet/presentation/providers/wallet_providers_test.dart
flutter test test/features/bazar/presentation/providers/bazar_providers_test.dart
```

Build debug APK:

```bash
flutter build apk --debug
```

Recently verified baseline:

- `flutter analyze` — passed
- `flutter test` — passed, 78 tests
- `flutter build apk --debug` — passed

## Known Non-Production Gaps

The app is suitable for local APK/demo verification, but not production-final yet.

Known gaps:

- Auth is still mock/demo.
- Sync API is currently a mock/sink seam, not a production server.
- Demo role buttons are enabled by default until production auth is ready.
- Some business actions may still be placeholders or require final backend contracts.
- Full manual APK QA should be repeated for each role before release.

## Recommended Manual QA Checklist

For each role:

1. Fresh install or logout.
2. Login with the matching demo button.
3. Confirm role label in Home and More.
4. Verify visible tabs/actions match the permission table.
5. Create a bazar.
6. Add items using frequent item, manual item, and text list where applicable.
7. Open bazar detail and edit item status/price.
8. Verify Balance visibility for the role.
9. Verify More menu restrictions.
10. Restart app and confirm the selected role/session restores correctly.

Admin-specific:

- Verify Admin panel is visible.
- Verify Add User/Add Wallet entry points.
- Verify all wallets/bazars are visible.

Owner-specific:

- Verify reports/monthly close.
- Verify money entry.
- Verify admin/direct expense restrictions.

Assistant-specific:

- Verify direct expense.
- Verify reports/monthly close/admin are hidden.
- Verify bazar visibility is unassigned/self-assigned only.
