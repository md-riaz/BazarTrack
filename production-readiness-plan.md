# BazarTrack Production-Readiness Plan

## Goal
Flutter app ও PHP API-কে একসাথে production-ready করা—API হবে source of truth, demo testing development mode-এ থাকবে, এবং deployment-এর আগে local PHP server-এর বিরুদ্ধে সব role flow verify হবে।

## Product decisions

- App API-first; production UI সরাসরি PHP API repositories ব্যবহার করবে।
- PHP session, cookie, JWT বা refresh token থাকবে না।
- Login একটি random opaque bearer token দেবে; token logout/admin revoke না করা পর্যন্ত valid থাকবে।
- Flutter token `flutter_secure_storage`-এ রাখবে এবং `Authorization: Bearer <token>` পাঠাবে।
- Demo login ও seed শুধু explicit development mode-এ থাকবে।
- Local PHP command: `php -S 127.0.0.1:8080 -t api`.

## Workstream 1 — API identity and authorization
**Owner:** API auth agent  
**Write scope:** `api/core/`, `api/controllers/AuthController.php`, `api/core/Schema.php`, `api/models/`

- `api_tokens` table এবং random-token login, `auth/me`, logout/revocation implement করা।
- Router policy দিয়ে health/login public, setup development-only, বাকি সব route protected করা।
- Token থেকে user, company ও role resolve করা; client-এর `companyId`, `createdBy`, `closedBy`, `confirmedBy`, `requestedBy` বিশ্বাস না করা।
- Admin, Fund Manager ও Assistant-এর function-level এবং object-level permissions enforce করা।
- Cross-company, unmanaged-fund, forged-actor এবং revoked-token tests যোগ করা।

**Done when:** token ছাড়া protected API `401`, unauthorized role `403`, এবং client actor spoofing balance/data পরিবর্তন করতে পারে না।

## Workstream 2 — Database and financial correctness
**Owner:** API data agent  
**Write scope:** API schema/migrations, accounts, ledger, money, returns, bazars, reports

- `create table if not exists` setup থেকে numbered transactional migrations-এ যাওয়া।
- Foreign keys, unique constraints, indexes, valid status/role/amount constraints যোগ করা।
- Money give, bazar close ও return confirmation transaction-safe এবং idempotent করা।
- একই request replay বা concurrent request-এ balance দুইবার পরিবর্তন হওয়া বন্ধ করা।
- Return request এবং manager confirmation আলাদা রাখা; Flutter repository-এর immediate auto-confirm সরানো।
- Confirmed ledger-কে balance/report source of truth করা এবং reconciliation test যোগ করা।
- SQLite development ও MySQL production—দুই database-এর migration/behavior verify করা।

**Done when:** replay, concurrent confirmation, rollback এবং insufficient-balance tests pass করে; ledger-derived balance stored balance-এর সঙ্গে মেলে।

## Workstream 3 — Complete and normalize the API
**Owner:** API feature agent  
**Write scope:** `api/controllers/`, `api/core/Request.php`, `api/core/Response.php`, API tests

- প্রতিটি action-এর HTTP method ও typed input validation enforce করা।
- Pagination/limits, nested bazar items, amounts, dates, IDs, roles এবং statuses validate করা।
- Missing feature contract finalize করা: fund edit/deactivate, activity, snapshots, report breakdowns, monthly close, adjustments এবং direct expenses।
- Product-এ যেসব feature থাকবে না সেগুলোর UI/API seam সরানো; unsupported runtime exceptions রেখে না দেওয়া।
- Stable success/error envelopes, correlation ID, safe error messages এবং structured server logging যোগ করা।
- CORS environment-based করা; production-এ wildcard origin বন্ধ করা।
- Login এবং mutation rate limiting যোগ করা।

**Done when:** API contract tests সব endpoint-এর success, validation, permission এবং failure response verify করে; production flow-এ `UnsupportedError` থাকে না।

## Workstream 4 — Flutter API integration and state consistency
**Owner:** Flutter integration agent  
**Write scope:** `lib/core/api/`, `lib/features/auth/`, `lib/features/api/`, affected providers/screens

- Bearer-token Dio interceptor, `auth/me` session restore এবং `401` logout flow implement করা।
- Hardcoded `u0/u1/u3` ↔ server ID mapping এবং default actor heuristics সরানো।
- API DTO/domain mappings contract অনুযায়ী normalize করা; invalid/missing server data silently `0` বা `DateTime.now()` না করা।
- Mutation-এর পরে affected Riverpod providers invalidate/refetch করা যাতে UI restart ছাড়াই update হয়।
- One-shot API streams-এর behavior পরিষ্কার করা; API query providers-কে explicit fetch/invalidation model-এ নেওয়া।
- Returned-money request ও confirmation-এর আলাদা UI/state flow করা।
- Loading, empty, retry এবং actionable API error states সব major screen-এ নিশ্চিত করা।
- Android emulator-এর development URL `10.0.2.2:8080`; desktop `127.0.0.1:8080`; physical device configurable LAN URL করা।

**Done when:** Admin, Fund Manager ও Assistant-এর সব visible action running PHP API-তে persist হয় এবং একই session-এ UI refresh হয়।

## Workstream 5 — App configuration, demo mode, and cleanup
**Owner:** Flutter platform agent  
**Write scope:** bootstrap/config, environments, notifications, dependencies, dead feature files, docs

- Development, test ও production configuration আলাদা করা; production build-এ localhost/default IDs/demo controls নিষিদ্ধ করা।
- `seed`/`seedDemo` development-only করা এবং deterministic demo users/data রাখা।
- App API-first হওয়ায় README থেকে misleading offline-first claims সরিয়ে actual behavior document করা; local Drift/sync code retained হলে তার exact responsibility নির্ধারণ করা, না হলে dead path সরানো।
- Firebase notification initialization সত্যি wire করা অথবা production scope থেকে dependency/UI সরানো।
- Unused packages, generators, inaccessible screens এবং obsolete direct-expense/local mock paths audit করে সরানো।
- Drift রাখা হলে foreign keys enable এবং migrations যোগ করা; production source of truth হিসেবে ব্যবহার না হলে scope ছোট করা।
- 1,125-line router/dashboard file-কে router, shell এবং home screen-এ split করা—behavior change ছাড়া।

**Done when:** release configuration-এ demo/setup/local endpoints নেই, dependency audit clean, এবং runtime architecture README-এর সঙ্গে মেলে।

## Workstream 6 — Automated demo and end-to-end acceptance
**Owner:** QA/integration agent  
**Depends on:** workstreams 1–5  
**Write scope:** `api/tests/`, Flutter integration tests, local verification scripts, QA docs

- One-command harness তৈরি করা যা isolated SQLite database দিয়ে PHP server start করে, migrate/seed করে, health wait করে, tests চালায় এবং server stop করে।
- API contract fixtures এবং Flutter JSON mapping tests একই payload দিয়ে চালানো।
- Demo journeys automate করা:
  1. Admin login, user/fund setup, all-data visibility.
  2. Fund Manager login, money give, bazar create/assign, reports.
  3. Assistant login, assigned bazar update/close, return request.
  4. Fund Manager return confirmation এবং final balance/report verification.
  5. Forbidden role actions ও cross-account IDs.
- App restart/session restore, network error, malformed API response এবং revoked-token behavior test করা।
- Drift test lifecycle warning fix করা এবং test databases reliably close করা।

**Done when:** isolated local run বারবার একই result দেয় এবং three-role end-to-end balance assertions pass করে।

## Workstream 7 — Deployment and operations
**Owner:** deployment agent  
**Depends on:** workstreams 1–6; always last

- HTTPS, MySQL credentials, trusted origins, rate-limit storage, backups এবং log retention configure করা।
- Production migration dry-run, backup restore এবং rollback/recovery rehearsal করা।
- CI gates: PHP lint/tests, API integration tests, `dart analyze`, `flutter test`, release APK/AAB build এবং dependency audit।
- Production smoke test: health, login, `auth/me`, authorized mutation, logout/revocation এবং forbidden action।
- Demo mode, setup routes, default credentials, wildcard CORS এবং verbose errors বন্ধ আছে verify করা।

**Done when:** নিচের সব release gate pass না করলে deployment block হয়।

## Release gates

- [ ] Protected APIs bearer token ছাড়া accessible নয়।
- [ ] Role, company, fund এবং account authorization server-side enforced।
- [ ] Financial requests replay/concurrency-তে double-apply হয় না।
- [ ] Returned money two-step confirmation ছাড়া ledger/balance পরিবর্তন করে না।
- [ ] Flutter-এর সব production-visible feature API-supported; runtime `UnsupportedError` নেই।
- [ ] Mutation-এর ফল UI-তে restart ছাড়া দেখা যায়।
- [ ] Production build-এ localhost, demo login, setup routes বা default credentials নেই।
- [ ] SQLite demo and MySQL migration/integration suites pass।
- [ ] PHP lint/tests, Dart analysis, Flutter tests এবং release build pass।
- [ ] Backup restoration এবং production smoke tests pass।

## Agent execution order

1. Workstream 1 এবং Workstream 2-এর migration design parallel শুরু করা যাবে; schema changes coordinate করতে হবে।
2. Workstream 3 শুরু হবে identity/authorization contract স্থির হলে।
3. Workstream 4 token এবং API response contracts স্থির হওয়ার পর শুরু হবে।
4. Workstream 5 API-first boundaries স্থির হওয়ার পরে cleanup করবে, আগে নয়।
5. Workstream 6 অন্য agents-এর completed work independently verify করবে।
6. Workstream 7 সর্বশেষ।

## Current verified baseline

- Local API is running at `http://127.0.0.1:8080/index.php`.
- PHP 8.3.30; health, base seed, demo seed এবং demo admin login pass করেছে।
- Seeded state: one fund এবং one assistant account.
- All API PHP files pass syntax lint.
- Dart analysis passes with no issues.
- Flutter tests: 84 passed; Drift multiple-database warnings remain to fix.
