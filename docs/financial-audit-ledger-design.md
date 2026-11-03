# Financial audit ledger

## Decision

Balance-affecting operations use an append-only ledger. Financial corrections are
new reversing entries; persisted ledger rows are never edited or deleted through
the application API.

## Scope

Money funding, bazar close/spend, and confirmed money returns each create a ledger
entry in the same database transaction that updates the assistant account balance.
Pending or rejected return requests do not affect a balance. An administrator may
post one corrective reversal per original ledger entry with a mandatory reason.
The reversal is a new, linked opposite-signed ledger entry; neither row is edited
or deleted.

## Entry invariants

Each entry records the account balance immediately before and after the signed
amount is applied. For an ordered account stream:

- `balance_after = balance_before + signed_amount`
- each entry's `balance_before` equals the previous entry's `balance_after`
- the final `balance_after` equals `fund_assistant_accounts.current_balance`

## Retry safety

A financial write must have an idempotency key scoped to company, actor, client,
and operation. A same-key retry returns its original result without a new ledger
entry; reusing the key with different business payload returns `409`.

## Reconciliation

The reconciliation API verifies stored balance, ledger aggregate, per-entry
arithmetic, and the before/after snapshot chain. It reports the first divergent
ledger entry for investigation.
