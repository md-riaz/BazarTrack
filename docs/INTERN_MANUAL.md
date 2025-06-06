# BazarTrack Intern Manual

Welcome to BazarTrack! This guide explains the project structure, core concepts and contribution guidelines. Read it fully before making changes.

## Project Philosophy

BazarTrack uses a modular, Domain Driven Design (DDD) approach. Each feature lives in its own directory under `lib/features`. We use GetX for navigation, dependency injection and state management. Data integrity is important – actions are logged through the history module to provide a full audit trail.

## Folder Layout

```
lib/
├── core/         # Shared utilities and exceptions
├── features/     # Feature modules (auth, orders, finance, etc.)
│   └── ...
├── services/     # Database and sync logic
├── ui/           # Common widgets and themes
└── main.dart     # Application entry point
```

Each feature follows this pattern:

```
features/<feature>/
├── controller/   # GetX controllers
├── repository/   # Data access layer
├── model/        # Domain models (if any)
└── <feature>_screen.dart  # UI layer
```

## Working Principle

1. **Routing and Screens**: Define routes in `lib/helper/route_helper.dart`. Use `Get.toNamed()` for navigation.
2. **Dependency Injection**: Register new controllers and repositories in `lib/helper/get_di.dart` so they can be retrieved with `Get.find()`.
3. **State Management**: Controllers extend `GetxController` and call `update()` after mutating state. UI uses `GetBuilder` to rebuild on changes.
4. **History Logging**: Important actions should create a `HistoryLog` entry via `HistoryController` for traceability.
5. **Persistence**: Simple features store data in `SharedPreferences`. More complex modules may connect to a backend service.

## Coding Style & Guidelines

- Format code with `dart format .`.
- Keep methods short and focused.
- Prefer descriptive names.
- Write immutable models using `toJson`/`fromJson` when storing data.
- Avoid business logic in widgets; place it inside controllers.

### Commit Rules

- Commit message format: `<module>: <short description>` (e.g. `orders: implement item model`).
- Run `flutter analyze` and `flutter test` before every commit.
- Place new Dart files in the correct feature directory.
- Register controllers in `helper/get_di.dart`.
- Update translation files under `assets/language/` when adding text.

### Do and Don’t

**Do**
- Follow the existing architecture when adding features.
- Keep all user actions logged for history tracing.
- Write self-explanatory code comments when the intent isn’t obvious.

**Don’t**
- Add dependencies without discussion.
- Put business logic inside widgets.
- Commit directly to main without a pull request.

Happy coding!
