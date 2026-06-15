# সহজ বাজার খাতা — BazarTrack

BazarTrack is an offline-first Flutter app for collaborative office market management: bazar lists, fund-account balances, assistant advances, bazar item expenses, reports, and admin monthly closing. The UI is Bangla-first with common English/Banglish product terms where they are more natural for daily users.

## Key Features

- Role-based demo login for **Admin**, **Fund Manager**, and **Assistant** verification.
- Real dashboard with fund-account summary, recent bazars, sync status, and quick actions.
- Create bazars manually or from pasted text lists.
- Add bazar items from frequent items, manual entry, or parsed text.
- Fund-account balance and assistant ledger tracking.
- Fund money given entries, two-step returned-money confirmation plan, and bazar item expenses.
- Reports and admin monthly close flows.
- Admin panel for user/fund-account management.
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
| `Login as Admin` | Admin User | Admin | Verify admin panel, all fund accounts/bazars, reports, monthly close, money entry |
| `Login as Fund Manager` | Mr. CEO | Fund Manager (`owner` role key) | Verify managed fund accounts, reports, money entry |
| `Login as Assistant` | Rahim Uddin | Assistant | Verify shopping/bazar flow and restricted reports/admin/money-entry access |

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
   - Select a **Fund account** when more than one is visible.
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

### Fund Manager Flow

Use **Login as Fund Manager**.

Fund Manager is for account-dept/fund-owner money and reporting verification. The underlying demo role key is still `owner` for compatibility.

Expected visible actions:

- Home dashboard
- Bazar list
- New bazar
- Balance
- Reports tab
- Money entry

Expected hidden/restricted actions:

- Admin panel hidden

Suggested verification path:

1. Tap **Login as Fund Manager**.
2. Confirm Home shows `Mr. CEO — হিসাব ম্যানেজার`.
3. Confirm Reports tab is visible.
4. Tap **টাকা এন্ট্রি** to verify fund-manager/admin money entry access.
5. Go to **Reports** and verify monthly summary/report UI.
6. Go to **More** and verify:
   - Reports visible
   - Close হিসাব not visible
   - Admin panel not visible
7. Go to **Balance** and verify manager-scoped fund accounts only.
8. Create a bazar from **নতুন বাজার** if you need to verify manager-created bazar flow for a managed fund account.

### Admin Flow

Use **Login as Admin**.

Admin is for full-access verification.

Expected visible actions:

- All dashboard actions
- Bazar list/new bazar
- Balance
- Reports
- Money entry
- Admin panel
- Add user
- Add fund account
- More/settings/offline queue

Suggested verification path:

1. Tap **Login as Admin**.
2. Confirm Home shows `Admin User — অ্যাডমিন`.
3. Verify Reports tab is visible.
4. Verify **টাকা এন্ট্রি** is visible.
5. Go to **More** and verify **অ্যাডমিন প্যানেল** is visible.
6. Open Admin panel and verify add user/add fund account entry points.
7. Go to Balance and verify all fund accounts are visible.
8. Go to Bazar list and verify all bazars are visible.
9. Create a bazar and add items using the same flow as Assistant.

## Practical Role Playbooks

These are end-to-end ways to use the app with the current demo roles. They are written as real QA/user stories, not just permission checks.

### Fund Manager Places a Bazar List for an Assistant

Use this when a fund manager/account-dept user wants to prepare a shopping list and let an assistant complete the market work.

Current supported app behavior:

- Fund Manager can create a bazar under a managed fund account.
- Fund Manager/Admin can pick a specific assistant in **Assign assistant**.
- Assistant can see bazars where `assignedTo == null` or `assignedTo == assistant.id`.
- If no assistant is selected, the bazar stays unassigned/team-visible for assistants.

Steps:

1. Login with **Login as Fund Manager**.
2. Tap **নতুন বাজার** from Home.
3. Select the fund account, for example `Office Lunch Bazar`, if more than one fund account is visible.
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

7. Keep title as `আজকের বাজার` or rename it, e.g. `Office Lunch Bazar`.
8. Tap **বাজার তৈরি করুন →**.
9. Logout from More.
10. Login with **Login as Assistant**.
11. Open **বাজার** tab.
12. Find the bazar assigned to that assistant, or any unassigned bazar.
13. Open it and use:
    - **আইটেম যোগ** if more items are needed.
    - item tap/edit sheet to mark items done/not found and enter price.
14. Tap **আজকের বাজার শেষ** when shopping is done.
15. Logout and login as Fund Manager again.
16. Fund Manager checks **Balance** and **Reports** to review spend and remaining balance.

This flow is the direct fund-manager-to-assistant handoff path in the app.

### Fund Manager Gives Money to Assistant Before Shopping

Use this when a fund manager/account-dept user advances cash to an assistant.

1. Login with **Login as Fund Manager**.
2. Tap **টাকা এন্ট্রি** from Home.
3. Select fund account/assistant fields shown on the money entry screen.
4. Enter the amount given to the assistant.
5. Save the entry.
6. Go to **Balance**.
7. Open the fund account or assistant ledger to verify the assistant balance changed.
8. Assistant can then login and complete bazar shopping.

Expected restrictions:

- Assistant should not see **টাকা এন্ট্রি**.

### Assistant Completes Shopping from a Fund Manager List

Use this after a fund manager has created a bazar list.

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
8. Finish the bazar with **আজকের বাজার শেষ**.
9. Check More → Sync queue if offline work is pending.

Expected restrictions:

- Reports tab hidden.
- Money entry hidden.
- Monthly close hidden.
- Admin panel hidden.

### Fund Manager Reviews Work Continuously

Use this after assistants have entered bazar item prices.

1. Login with **Login as Fund Manager**.
2. Open **Balance** to review fund-account and assistant balances.
3. Open **Reports** to review monthly spend.
4. Use **টাকা এন্ট্রি** when fund money is given to an assistant.
5. For returned money, use the backend two-step flow: assistant creates a return request, then a fund manager confirms after counting cash.
6. Keep the assistant balance active until the employee/assistant leaves or is fired.
7. Settle the assistant balance back to 0 through confirmed money entries/return confirmations instead of monthly close.

Expected restrictions:

- Fund Manager can access reports and money entry.
- Fund Manager cannot access monthly close or admin panel.

### Admin Sets Up Demo Operating Structure

Use this when verifying admin-only operations.

1. Login with **Login as Admin**.
2. Open **More**.
3. Tap **অ্যাডমিন প্যানেল**.
4. Verify user and fund-account management options.
5. Use add user/add fund account entry points if needed.
6. Return to Home.
7. Verify Admin can see:
   - Reports
   - Money entry
   - Admin panel
   - all fund accounts
   - all bazars
8. Create a bazar and add items to verify Admin can perform operational work too.

### Admin Audits Role Visibility

Use this to confirm role scoping during QA.

1. Login as Admin and note all fund accounts/bazars are visible.
2. Logout.
3. Login as Fund Manager and confirm only managed fund accounts are visible.
4. Logout.
5. Login as Assistant and confirm only unassigned/self-assigned bazars are visible.
6. Verify assistant cannot see Reports/Admin/Money Entry.

## Direct Assistant Assignment

The **নতুন বাজার** screen includes an **Assign assistant** section for Fund Manager/Admin. It lists active assistants and also supports an unassigned option.

Supported handoff flows:

```text
Fund Manager/Admin assigns bazar to Rahim → Rahim sees it → Rahim completes shopping
Fund Manager/Admin leaves bazar unassigned → assistants can see it → any assistant can take/action it
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
- If the role has exactly one visible fund account, the account is auto-selected and the selector is hidden.
- If the role has multiple visible fund accounts, the fund account selector is shown.

Tracking handoff notes:

- Monthly close events should allow `admin` only as actor role; fund-manager monthly-close entry/impression/click/submit events are unexpected.
- Bazar creation analytics should include the resolved `fund_account_id` and `fund_account_selection_method` with values `auto_single_account` or `manual_selector`.
- Analytics should store `actor_product_role = fund_manager` separately from compatibility `actor_role_key = owner`.
- Returned-money analytics should use return-request lifecycle events, not normal money-entry create events, and balance/report totals should update only after `return_request_confirmed` / `assistant_return_confirmed`.
- Return-request tracking should include confirmation status, permission result, sync state, idempotency/client operation id, and `ledger_entry_id` only after confirmation.
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

| Capability | Assistant | Fund Manager | Admin |
| --- | --- | --- | --- |
| Login via demo button | Yes | Yes | Yes |
| Home dashboard | Yes | Yes | Yes |
| Create bazar | Yes | Yes | Yes |
| Add bazar item | Yes | Yes, where accessible | Yes |
| Money entry | No | Yes | Yes |
| Returned-money confirmation | Request only | Confirm for managed fund | Yes |
| Reports tab | No | Yes | Yes |
| Monthly close | No | No | Yes |
| Admin panel | No | No | Yes |
| Fund account visibility | Linked fund accounts | Managed fund accounts | All fund accounts |
| Bazar visibility | Unassigned or assigned to self | Bazars in managed fund accounts | All bazars |

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
    wallet/       current local feature name for fund-account balance/ledger
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

- fund money given to assistant
- manager-confirmed returned money
- adjustments
- done bazar item prices
- latest fund-account snapshot base
- in-progress bazar spending

Balance is not stored as a fund-account field in the current app; future backend may cache `current_balance` transactionally while keeping ledger entries as source of truth.

## Mock-to-API Handoff

The app is backend-ready through abstract seams:

- Auth: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- Fund account / current wallet seam: `lib/features/wallet/data/datasources/mock_wallet_remote_datasource.dart`
- Bazar: `lib/features/bazar/data/datasources/mock_bazar_remote_data_source.dart`
- Money: `lib/features/money/data/datasources/mock_money_remote_datasource.dart`
- Sync API seam: `lib/core/sync/sync_api_client.dart`

Backend planning note:

- The approved backend direction is fund-account based, not fixed wallet/moneybag based.
- `owner` remains the compatibility role key, but product label is **Fund Manager** / **হিসাব ম্যানেজার**.
- Returned money must use two-step confirmation: assistant creates a return request; authorized fund manager confirms before ledger balance changes.
- Full backend plan: `docs/backend-fund-account-api-plan.md`.

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
- `flutter test` — passed, 84 tests
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

- Verify Add User/Add Fund Account entry points.
- Verify all fund accounts/bazars are visible.

Fund Manager-specific:

- Verify reports and money entry.
- Verify admin restrictions.
- Verify returned-money confirmation is not treated as direct assistant balance mutation.

Assistant-specific:

- Verify reports/monthly close/admin are hidden.
- Verify bazar visibility is unassigned/self-assigned only.
