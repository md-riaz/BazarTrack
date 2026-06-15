# Backend Fund Account API Plan

## Product model

Use a fund-based ledger model, not a fixed wallet/moneybag model.

```text
Company
  Users
  Funds / Fund Accounts
    Fund Managers
    Fund-Assistant Accounts
      Ledger Entries
      Bazars
      Fund Disbursements
      Return Requests
```

A fund account represents office money context such as `Office Lunch Bazar`, `CEO Office Bazar`, or another cost center. Multiple account-dept users can manage the same fund account.

A running balance exists per fund-assistant pair:

```text
fund_id + assistant_id = fund_assistant_account
```

Balance meaning:

| Balance | Meaning |
| --- | --- |
| Positive | Assistant has fund/company money |
| Zero | Clear |
| Negative | Fund/company owes assistant |

## Roles and permissions

### Admin

- Manage users.
- Create/deactivate fund accounts.
- Add/remove fund managers.
- Link assistants to fund accounts.
- See all accounts, bazars, ledgers, reports.
- Perform admin-only monthly close if that feature remains.

### Fund Manager / Account Dept

Current app role key remains `owner` for compatibility, but product label should be **Fund Manager** / **হিসাব ম্যানেজার**.

A fund manager can act only on assigned fund accounts and explicit permissions:

- Create bazar.
- Assign assistant.
- Give money to assistant.
- Confirm returned money from assistant.
- View fund account reports.
- View fund-assistant balances.
- Create correction/adjustment if allowed.

### Assistant

Assistant can only see fund-assistant accounts where `assistant_id == current_user.id`.

Assistant can:

- See own fund account balances.
- See assigned/self-available bazars.
- Update item prices/status.
- Close assigned bazar.
- Create a return-money request.

Assistant cannot directly mutate returned-money ledger balance without manager confirmation.

## Required backend tables

### companies

```sql
companies (
  id uuid primary key,
  name text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null
)
```

### users

```sql
users (
  id uuid primary key,
  company_id uuid not null references companies(id),
  role text not null check (role in ('admin', 'owner', 'assistant')),
  name text not null,
  phone text,
  email text,
  password_hash text,
  is_active boolean not null default true,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

`owner` is kept as API-compatible role value. Product label: Fund Manager.

### funds

```sql
funds (
  id uuid primary key,
  company_id uuid not null references companies(id),
  name text not null,
  type text not null default 'office_bazar',
  status text not null check (status in ('active', 'inactive')),
  created_by uuid references users(id),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deactivated_at timestamptz
)
```

### fund_managers

```sql
fund_managers (
  id uuid primary key,
  company_id uuid not null references companies(id),
  fund_id uuid not null references funds(id),
  user_id uuid not null references users(id),
  can_create_bazar boolean not null default true,
  can_assign_assistant boolean not null default true,
  can_give_money boolean not null default true,
  can_confirm_return boolean not null default true,
  can_adjust_balance boolean not null default false,
  can_view_reports boolean not null default true,
  created_at timestamptz not null,
  unique(fund_id, user_id)
)
```

### fund_assistant_accounts

```sql
fund_assistant_accounts (
  id uuid primary key,
  company_id uuid not null references companies(id),
  fund_id uuid not null references funds(id),
  assistant_id uuid not null references users(id),
  current_balance numeric(12,2) not null default 0,
  status text not null check (status in ('active', 'inactive')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deactivated_at timestamptz,
  unique(company_id, fund_id, assistant_id)
)
```

### bazars

```sql
bazars (
  id uuid primary key,
  company_id uuid not null references companies(id),
  fund_id uuid not null references funds(id),
  account_id uuid references fund_assistant_accounts(id),
  assistant_id uuid references users(id),
  title text,
  note text,
  status text not null check (status in ('draft', 'open', 'assigned', 'in_progress', 'closed', 'cancelled')),
  created_by uuid not null references users(id),
  assigned_by uuid references users(id),
  assigned_at timestamptz,
  closed_by uuid references users(id),
  closed_at timestamptz,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

### bazar_items

```sql
bazar_items (
  id uuid primary key,
  company_id uuid not null references companies(id),
  bazar_id uuid not null references bazars(id),
  name text not null,
  quantity text,
  unit text,
  brand text,
  note text,
  estimated_price numeric(12,2),
  actual_price numeric(12,2),
  status text not null check (status in ('pending', 'purchased', 'not_found', 'cancelled')),
  created_by uuid not null references users(id),
  updated_by uuid references users(id),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

### ledger_entries

Ledger is append-only. Never edit balances directly.

```sql
ledger_entries (
  id uuid primary key,
  company_id uuid not null references companies(id),
  fund_id uuid not null references funds(id),
  account_id uuid not null references fund_assistant_accounts(id),
  type text not null check (type in ('fund_gave_money', 'assistant_return_confirmed', 'bazar_spend', 'adjustment')),
  amount numeric(12,2) not null check (amount >= 0),
  signed_amount numeric(12,2) not null,
  source_type text not null check (source_type in ('money_entry', 'return_request', 'bazar', 'adjustment')),
  source_id uuid,
  created_by uuid not null references users(id),
  paid_by uuid references users(id),
  paid_to uuid references users(id),
  returned_by uuid references users(id),
  received_by uuid references users(id),
  note text,
  entry_date date not null,
  created_at timestamptz not null,
  voided_at timestamptz,
  voided_by uuid references users(id),
  void_reason text
)
```

Signed amount rules:

| Type | signed_amount |
| --- | ---: |
| `fund_gave_money` | `+amount` |
| `assistant_return_confirmed` | `-amount` |
| `bazar_spend` | `-amount` |
| `adjustment` | signed correction |

### money_entries

`money_entries` are only fund-manager transfers to assistants, plus explicit corrections if allowed. Assistant spending is captured through bazar item prices. Returned money is intentionally not a direct `money_entries` row; it goes through return request confirmation.

```sql
money_entries (
  id uuid primary key,
  company_id uuid not null references companies(id),
  fund_id uuid not null references funds(id),
  account_id uuid not null references fund_assistant_accounts(id),
  type text not null check (type in ('fund_gave_money', 'adjustment')),
  amount numeric(12,2) not null,
  signed_amount numeric(12,2) not null,
  note text,
  entry_date date not null,
  created_by uuid not null references users(id),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
)
```

### money_return_requests

Two-step return confirmation is required for transparency.

```sql
money_return_requests (
  id uuid primary key,
  company_id uuid not null references companies(id),
  fund_id uuid not null references funds(id),
  account_id uuid not null references fund_assistant_accounts(id),
  assistant_id uuid not null references users(id),
  amount numeric(12,2) not null check (amount > 0),
  note text,
  requested_by uuid not null references users(id),
  expected_receiver_id uuid references users(id),
  status text not null check (status in ('pending', 'confirmed', 'rejected', 'cancelled')),
  requested_at timestamptz not null,
  confirmed_by uuid references users(id),
  confirmed_at timestamptz,
  rejected_by uuid references users(id),
  rejected_at timestamptz,
  rejection_reason text,
  ledger_entry_id uuid references ledger_entries(id),
  idempotency_key text,
  unique(company_id, idempotency_key)
)
```

Flow:

1. Assistant creates pending return request after physically returning cash, or manager creates pending request while receiving cash.
2. Authorized fund manager confirms after verifying cash.
3. Backend creates one ledger entry with `type = assistant_return_confirmed` and `signed_amount = -amount`.
4. Backend updates account current balance in same transaction.
5. If rejected/cancelled, no ledger entry is created.

Confirmation must be idempotent. Repeating confirm for same request must return the existing confirmed result, not create another ledger entry.


## API endpoints

### Auth

```http
POST /auth/login
POST /auth/refresh
POST /auth/logout
GET  /auth/me
```

### Users

```http
GET    /users
POST   /users
GET    /users/:id
PATCH  /users/:id
DELETE /users/:id
```

### Funds

```http
GET    /funds
POST   /funds
GET    /funds/:fundId
PATCH  /funds/:fundId
DELETE /funds/:fundId
```

### Fund managers

```http
GET    /funds/:fundId/managers
POST   /funds/:fundId/managers
PATCH  /funds/:fundId/managers/:userId
DELETE /funds/:fundId/managers/:userId
```

### Fund-assistant accounts

```http
GET  /accounts
POST /funds/:fundId/accounts
GET  /accounts/:accountId
GET  /accounts/:accountId/ledger
GET  /accounts/:accountId/balance
PATCH /accounts/:accountId
```

### Bazars

```http
GET    /bazars
POST   /bazars
GET    /bazars/:id
PATCH  /bazars/:id
POST   /bazars/:id/assign
POST   /bazars/:id/close
DELETE /bazars/:id
```

Close bazar transaction:

1. Validate access.
2. Lock bazar row.
3. Reject if already closed, or return existing close result idempotently.
4. Sum purchased item prices.
5. Mark bazar closed.
6. Insert `ledger_entries` row with `type = bazar_spend`, `signed_amount = -total`.
7. Update `fund_assistant_accounts.current_balance`.
8. Write activity log.

### Bazar items

```http
POST  /bazars/:bazarId/items
PATCH /bazars/:bazarId/items/:itemId
DELETE /bazars/:bazarId/items/:itemId
```

### Money entries

```http
GET  /money-entries
POST /money-entries
GET  /money-entries/:id
DELETE /money-entries/:id
```

Fund gives money example:

```json
{
  "accountId": "acc1",
  "type": "fund_gave_money",
  "amount": 5000,
  "paidBy": "manager1",
  "paidTo": "assistant1",
  "entryDate": "2026-06-15",
  "note": "Advance for lunch bazar"
}
```

### Money return requests

```http
GET  /money-return-requests
POST /money-return-requests
GET  /money-return-requests/:id
POST /money-return-requests/:id/confirm
POST /money-return-requests/:id/reject
POST /money-return-requests/:id/cancel
```

Create request example:

```json
{
  "accountId": "acc1",
  "amount": 1000,
  "expectedReceiverId": "manager2",
  "note": "Returned extra cash to Accounts"
}
```

Confirm request example:

```json
{
  "receivedBy": "manager2",
  "note": "Cash counted and confirmed"
}
```

Confirm response:

```json
{
  "data": {
    "request": {
      "id": "return1",
      "status": "confirmed"
    },
    "ledgerEntry": {
      "id": "ledger1",
      "type": "assistant_return_confirmed",
      "signedAmount": -1000
    },
    "accountBalance": 1800
  }
}
```


### Reports

```http
GET /reports/summary?from=2026-06-01&to=2026-06-30
GET /reports/accounts/:accountId?from=2026-06-01&to=2026-06-30
GET /reports/funds/:fundId?from=2026-06-01&to=2026-06-30
```

## Tracking and analytics contract

Use fund-account terminology in analytics. Do not introduce new dashboard fields named `wallet_id` for the backend model.

Recommended properties:

- `fund_account_id` for the fund-assistant account visible in the app.
- `fund_id` for the parent fund/cost center.
- `legacy_wallet_id` only during Flutter migration if existing reports depend on local wallet ids.
- `fund_account_selection_method` with `auto_single_account` or `manual_selector`.
- `actor_product_role` with values such as `fund_manager`, `assistant`, `admin`.
- `actor_role_key` for compatibility values such as `owner`, `assistant`, `admin`.

Returned money must not be tracked as a normal `money_returned` balance mutation. Use return-request lifecycle events:

- `return_request_create_started`
- `return_request_submitted`
- `return_request_created`
- `return_request_create_failed`
- `return_request_confirm_viewed`
- `return_request_confirm_submitted`
- `return_request_confirmed`
- `return_request_rejected`
- `return_request_cancelled`
- `return_request_confirm_failed`

Return-request event properties should include:

- `return_request_id`
- `fund_account_id`
- `fund_id`
- `account_id` if separate from `fund_account_id`
- `assistant_id`
- `amount`
- `status`
- `requested_by`
- `expected_receiver_id`
- `confirmed_by`
- `received_by`
- `rejected_by`
- `actor_role_key`
- `actor_product_role`
- `idempotency_key` or `client_operation_id`
- `ledger_entry_id` only after confirmation
- `can_confirm_return`
- `permission_result`
- `managed_fund_account`
- `failure_reason`, e.g. `unauthorized`, `already_confirmed`, `invalid_status`, `offline_pending`, `network_error`
- `sync_state`, e.g. `local_created`, `queued`, `synced`, `failed`
- `operation_id`
- `idempotent_retry_outcome`, e.g. `created`, `existing_confirmed_returned`, `duplicate_blocked`

Only `return_request_confirmed` / `assistant_return_confirmed` should have `balance_mutation = true` for returned money. Pending request creation must not update balance, ledger, reports, or money totals.

## Offline sync and idempotency

Every mutating endpoint must accept:

```http
Idempotency-Key: <client_operation_id>
X-Client-Id: <device_id>
```

Backend must store applied operations to avoid duplicate money entries, bazar close entries, and return confirmations.

Recommended MVP:

1. REST endpoints with idempotency headers.
2. Existing Flutter sync queue posts operations when online.
3. Later add batch sync:

```http
POST /sync/push
GET  /sync/pull?cursor=<cursor>
```

## Flutter migration notes

Current app still has `wallet` names in code and database for demo compatibility. Future migration should map:

| Current app term | Backend/product term |
| --- | --- |
| Wallet | Fund account |
| Wallet member owner | Fund manager |
| Wallet detail | Fund account ledger |
| Assistant ledger | Fund-assistant ledger |
| Money returned | Return request + manager confirmation |
| Owner role | Fund Manager role |

Do not deeply refactor Flutter storage until API contract is approved. First add labels/docs, then migrate data model/API adapters in a dedicated phase.
