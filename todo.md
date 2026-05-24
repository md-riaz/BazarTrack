# সহজ বাজার খাতা — Task Registry

> Last updated: 2025-02-14 UTC
> Status: 🔴 not_started | 🟡 in_progress | 🟢 done | ⛔ blocked

## Phase 0 — Discovery
- [x] D0. Read assets/spec.pdf fully                         | Orchestrator | 🟢
- [x] D1. Read assets/prototype.jsx fully                    | Orchestrator | 🟢
- [x] D2. Review AGENT_PROMPT.md                             | Orchestrator | 🟢
- [x] D3. Create todo.md                                     | Orchestrator | 🟢
- [x] D4. Create progress.md                                 | Orchestrator | 🟢

## Phase 1 — Foundation (Agent A) [BLOCKS ALL]
- [ ] A1. Flutter project init                               | Agent A | 🔴
- [ ] A2. pubspec.yaml + pub get                             | Agent A | 🔴
- [ ] A3. app_colors.dart                                    | Agent A | 🔴
- [ ] A4. app_text_styles.dart + app_theme.dart              | Agent A | 🔴
- [ ] A5. Drift DB all tables                                | Agent A | 🔴
- [ ] A6. Drift codegen                                      | Agent A | 🔴
- [ ] A7. GoRouter all routes                                | Agent A | 🔴
- [ ] A8. bootstrap.dart                                     | Agent A | 🔴
- [ ] A9. Shared widgets                                     | Agent A | 🔴
- [ ] A10. Shared enums                                      | Agent A | 🔴
- [ ] A11. Mock seed data from prototype.jsx                 | Agent A | 🔴
- [ ] A12. Formatters (balance/date/currency)                | Agent A | 🔴

## Phase 2 — Features (parallel after Phase 1)
### Agent B — Auth
- [ ] B1. User entity + repository abstraction               | Agent B | 🔴
- [ ] B2. MockAuthRemoteDataSource                           | Agent B | 🔴
- [ ] B3. LocalAuthDataSource                                | Agent B | 🔴
- [ ] B4. AuthRepositoryImpl                                 | Agent B | 🔴
- [ ] B5. LoginScreen parity                                 | Agent B | 🔴
- [ ] B6. currentUserProvider                                | Agent B | 🔴
- [ ] B7. Router auth guard                                  | Agent B | 🔴
- [ ] B8. Logout flow                                        | Agent B | 🔴
- [ ] B9. Auth tests                                          | Agent B | 🔴

### Agent C — Wallet + Balance
- [ ] C1. Wallet entity/repository/mock                      | Agent C | 🔴
- [ ] C2. Wallet DAOs                                        | Agent C | 🔴
- [ ] C3. BalanceCalculator                                  | Agent C | 🔴
- [ ] C4. BalanceResult entity                               | Agent C | 🔴
- [ ] C5. WalletRepositoryImpl                               | Agent C | 🔴
- [ ] C6. Wallet providers                                   | Agent C | 🔴
- [ ] C7. BalanceScreen parity                               | Agent C | 🔴
- [ ] C8. WalletDetailScreen parity                          | Agent C | 🔴
- [ ] C9. AssistantLedgerScreen                              | Agent C | 🔴
- [ ] C10. Balance tests                                     | Agent C | 🔴

### Agent D — Bazar Core
- [ ] D1. Bazar entity/repository/mock                       | Agent D | 🔴
- [ ] D2. Bazar DAOs                                         | Agent D | 🔴
- [ ] D3. BazarRepositoryImpl                                | Agent D | 🔴
- [ ] D4. BazarListScreen parity                             | Agent D | 🔴
- [ ] D5. BazarDetailScreen parity                           | Agent D | 🔴
- [ ] D6. ItemEditSheet parity                               | Agent D | 🔴
- [ ] D7. BazarSummaryScreen parity                          | Agent D | 🔴
- [ ] D8. ActivityTimelineWidget                             | Agent D | 🔴
- [ ] D9. Bazar tests                                        | Agent D | 🔴

### Agent E — New Bazar + Items + Direct Expense
- [ ] E1. NewBazarScreen dual mode                           | Agent E | 🔴
- [ ] E2. AddItemScreen                                      | Agent E | 🔴
- [ ] E3. DirectExpenseScreen                                | Agent E | 🔴
- [ ] E4. FrequentItemsProvider                              | Agent E | 🔴
- [ ] E5. AutoParseService                                   | Agent E | 🔴

### Agent F — Money + Reports + Monthly Close
- [ ] F1. MoneyEntry entity/repository/mock                  | Agent F | 🔴
- [ ] F2. MoneyEntry/DirectExpense DAOs                      | Agent F | 🔴
- [ ] F3. MoneyEntryRepositoryImpl                           | Agent F | 🔴
- [ ] F4. MoneyEntryScreen parity                            | Agent F | 🔴
- [ ] F5. ReportsScreen parity                               | Agent F | 🔴
- [ ] F6. MonthlyCloseScreen flow                            | Agent F | 🔴
- [ ] F7. Money/report tests                                 | Agent F | 🔴

### Agent G — Admin + Notifications + Search
- [ ] G1. Admin entities/mock                                | Agent G | 🔴
- [ ] G2. AdminScreen parity                                 | Agent G | 🔴
- [ ] G3. AddUserScreen                                      | Agent G | 🔴
- [ ] G4. NotificationsScreen                                | Agent G | 🔴
- [ ] G5. SearchScreen                                       | Agent G | 🔴
- [ ] G6. Push notification handler scaffold                 | Agent G | 🔴
- [ ] G7. Admin/search tests                                 | Agent G | 🔴

### Agent H — Settings + More + Comments + History
- [ ] H1. MoreScreen                                         | Agent H | 🔴
- [ ] H2. ProfileEditScreen                                  | Agent H | 🔴
- [ ] H3. SettingsScreen                                     | Agent H | 🔴
- [ ] H4. OfflineQueueScreen                                 | Agent H | 🔴
- [ ] H5. BazarCommentsScreen                                | Agent H | 🔴
- [ ] H6. PriceHistoryScreen                                 | Agent H | 🔴
- [ ] H7. Settings/comments tests                            | Agent H | 🔴

### Agent I — Sync Engine
- [ ] I1. ConnectivityService                                | Agent I | 🔴
- [ ] I2. SyncEngine                                         | Agent I | 🔴
- [ ] I3. SyncStatusProvider                                 | Agent I | 🔴
- [ ] I4. enqueue service                                    | Agent I | 🔴
- [ ] I5. Drift→API mappers                                  | Agent I | 🔴
- [ ] I6. Sync tests                                         | Agent I | 🔴

## Phase 3 — Integration + Polish
- [ ] Z1. Run integration tests                              | Orchestrator | 🔴
- [ ] Z2. Screen-by-screen visual comparison                 | Orchestrator | 🔴
- [ ] Z3. Offline end-to-end test                            | Orchestrator | 🔴
- [ ] Z4. Performance validation                             | Orchestrator | 🔴
- [ ] Z5. Accessibility validation                           | Orchestrator | 🔴
- [ ] Z6. API interface handoff docs                         | Orchestrator | 🔴
- [ ] Z7. README.md                                          | Orchestrator | 🔴
