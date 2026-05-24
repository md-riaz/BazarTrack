# সহজ বাজার খাতা — Task Registry

> Last updated: 2026-05-24 UTC
> Status: 🔴 not_started | 🟡 in_progress | 🟢 done | ⛔ blocked

## Phase 0 — Discovery
- [x] D0. Read assets/spec.pdf fully                         | Orchestrator | 🟢
- [x] D1. Read assets/prototype.jsx fully                    | Orchestrator | 🟢
- [x] D2. Review AGENTS_PROMPT.md                            | Orchestrator | 🟢
- [x] D3. Create todo.md                                     | Orchestrator | 🟢
- [x] D4. Create progress.md                                 | Orchestrator | 🟢

## Phase 1 — Foundation (Agent A) [BLOCKS ALL]
- [x] A1. Flutter project init                               | Agent A | 🟢
- [x] A2. pubspec.yaml + pub get                             | Agent A | 🟢
- [x] A3. app_colors.dart                                    | Agent A | 🟢
- [x] A4. app_text_styles.dart + app_theme.dart              | Agent A | 🟢
- [x] A5. Drift DB all tables                                | Agent A | 🟢
- [x] A6. Drift codegen                                      | Agent A | 🟢
- [x] A7. GoRouter all routes                                | Agent A | 🟢
- [x] A8. bootstrap.dart                                     | Agent A | 🟢
- [x] A9. Shared widgets                                     | Agent A | 🟢
- [x] A10. Shared enums                                      | Agent A | 🟢
- [x] A11. Mock seed data from prototype.jsx                 | Agent A | 🟢
- [x] A12. Formatters (balance/date/currency)                | Agent A | 🟢

## Phase 2 — Features (parallel after Phase 1)
### Agent B — Auth
- [x] B1. User entity + repository abstraction               | Agent B | 🟢
- [x] B2. MockAuthRemoteDataSource                           | Agent B | 🟢
- [x] B3. LocalAuthDataSource                                | Agent B | 🟢
- [x] B4. AuthRepositoryImpl                                 | Agent B | 🟢
- [x] B5. LoginScreen parity                                 | Agent B | 🟢
- [x] B6. currentUserProvider                                | Agent B | 🟢
- [x] B7. Router auth guard                                  | Agent B | 🟢
- [x] B8. Logout flow                                        | Agent B | 🟢
- [x] B9. Auth tests                                         | Agent B | 🟢

### Agent C — Wallet + Balance
- [x] C1. Wallet entity/repository/mock                      | Agent C | 🟢
- [x] C2. Wallet DAOs                                        | Agent C | 🟢
- [x] C3. BalanceCalculator                                  | Agent C | 🟢
- [x] C4. BalanceResult entity                               | Agent C | 🟢
- [x] C5. WalletRepositoryImpl                               | Agent C | 🟢
- [x] C6. Wallet providers                                   | Agent C | 🟢
- [x] C7. BalanceScreen parity                               | Agent C | 🟢
- [x] C8. WalletDetailScreen parity                          | Agent C | 🟢
- [x] C9. AssistantLedgerScreen                              | Agent C | 🟢
- [x] C10. Balance tests                                     | Agent C | 🟢

### Agent D — Bazar Core
- [x] D1. Bazar entity/repository/mock                       | Agent D | 🟢
- [x] D2. Bazar DAOs                                         | Agent D | 🟢
- [x] D3. BazarRepositoryImpl                                | Agent D | 🟢
- [x] D4. BazarListScreen parity                             | Agent D | 🟢
- [x] D5. BazarDetailScreen parity                           | Agent D | 🟢
- [x] D6. ItemEditSheet parity                               | Agent D | 🟢
- [x] D7. BazarSummaryScreen parity                          | Agent D | 🟢
- [x] D8. ActivityTimelineWidget                             | Agent D | 🟢
- [x] D9. Bazar tests                                        | Agent D | 🟢

### Agent E — New Bazar + Items + Direct Expense
- [x] E1. NewBazarScreen dual mode                           | Agent E | 🟢
- [x] E2. AddItemScreen                                      | Agent E | 🟢
- [x] E3. DirectExpenseScreen                                | Agent E | 🟢
- [x] E4. FrequentItemsProvider                              | Agent E | 🟢
- [x] E5. AutoParseService                                   | Agent E | 🟢

### Agent F — Money + Reports + Monthly Close
- [x] F1. MoneyEntry entity/repository/mock                  | Agent F | 🟢
- [x] F2. MoneyEntry/DirectExpense DAOs                      | Agent F | 🟢
- [x] F3. MoneyEntryRepositoryImpl                           | Agent F | 🟢
- [x] F4. MoneyEntryScreen parity                            | Agent F | 🟢
- [x] F5. ReportsScreen parity                               | Agent F | 🟢
- [x] F6. MonthlyCloseScreen flow                            | Agent F | 🟢
- [x] F7. Money/report tests                                 | Agent F | 🟢

### Agent G — Admin + Notifications + Search
- [x] G1. Admin entities/mock                                | Agent G | 🟢
- [x] G2. AdminScreen parity                                 | Agent G | 🟢
- [x] G3. AddUserScreen                                      | Agent G | 🟢
- [x] G4. NotificationsScreen                                | Agent G | 🟢
- [x] G5. SearchScreen                                       | Agent G | 🟢
- [x] G6. Push notification handler scaffold                 | Agent G | 🟢
- [x] G7. Admin/search tests                                 | Agent G | 🟢

### Agent H — Settings + More + Comments + History
- [x] H1. MoreScreen                                         | Agent H | 🟢
- [x] H2. ProfileEditScreen                                  | Agent H | 🟢
- [x] H3. SettingsScreen                                     | Agent H | 🟢
- [x] H4. OfflineQueueScreen                                 | Agent H | 🟢
- [x] H5. BazarCommentsScreen                                | Agent H | 🟢
- [x] H6. PriceHistoryScreen                                 | Agent H | 🟢
- [x] H7. Settings/comments tests                            | Agent H | 🟢

### Agent I — Sync Engine
- [x] I1. ConnectivityService                                | Agent I | 🟢
- [x] I2. SyncEngine                                         | Agent I | 🟢
- [x] I3. SyncStatusProvider                                 | Agent I | 🟢
- [x] I4. enqueue service                                    | Agent I | 🟢
- [x] I5. Drift→API mappers                                  | Agent I | 🟢
- [x] I6. Sync tests                                         | Agent I | 🟢

## Phase 3 — Integration + Polish
- [x] Z1. Run integration tests                              | Orchestrator | 🟢
- [ ] Z2. Screen-by-screen visual comparison                 | Orchestrator | 🔴
- [ ] Z3. Offline end-to-end test                            | Orchestrator | 🔴
- [x] Z4. Build/performance readiness baseline               | Orchestrator | 🟢
- [ ] Z5. Accessibility validation                           | Orchestrator | 🔴
- [x] Z6. API interface handoff docs                         | Orchestrator | 🟢
- [x] Z7. README.md                                          | Orchestrator | 🟢
