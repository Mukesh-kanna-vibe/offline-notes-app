# Offline First Notes

A production-quality Flutter notes application that works **completely offline** and synchronizes with **MockAPI** when connectivity is restored. Built with Clean Architecture, Bloc state management, and SQLite persistence — including automatic sync, a pending operation queue, and full conflict detection & resolution.

> Capture ideas anywhere. Notes are saved locally first, synced in the background, and conflicts are resolved with clear user control.

---

## ✨ Features

### Core Notes

- 📝 **Create notes** — title & body, works fully offline
- ✏️ **Edit notes** — local-first updates with pending sync status
- 🗑️ **Delete notes** — soft delete locally, synced to server when online
- 📋 **View all notes** — list with timestamps and sync badges
- 🔍 **Search** — filter by title and body in real time
- 🔀 **Sorting** — newest, oldest, title A→Z, title Z→A, created date

### Offline & Sync

- 📴 **Offline CRUD** — all operations write to SQLite immediately
- 🗄️ **SQLite storage** — `notes` + `sync_queue` tables with schema migrations (v5)
- 📤 **Pending queue** — create / update / delete operations enqueued while offline
- 🔄 **Automatic sync** — triggers when connectivity is restored (no manual sync button required)
- 🌐 **MockAPI integration** — remote CRUD via Dio REST client
- ⬆️ **Push pending changes** — processes queue FIFO when online
- ⬇️ **Pull remote updates** — fetches latest server notes after push
- 🔁 **Retry logic** — failed sync operations retry up to 3 times
- 🔃 **Pull-to-refresh** — manual sync trigger on the notes list

### Sync Status

Each note displays one of three states:

- ✅ **Synced** — local and remote are in agreement
- ⏳ **Pending Sync** — local changes waiting to upload
- ⚠️ **Conflict** — local and server versions both changed

Aggregate pending/conflict counts are shown on the home screen.

### Conflict Resolution

- 🔎 **Conflict detection** — three-way comparison using sync baseline snapshots + timestamp fallback
- 📱 **Local version** — shows device-side content in the resolution UI
- ☁️ **Remote version** — shows MockAPI server content side-by-side
- ✅ **Keep Local** — force-push local version to server
- ☁️ **Keep Remote** — overwrite local with server version (requires internet)
- 🔀 **Merge** — open merge editor to combine title & body manually
- 🔔 **Auto-navigation** — app navigates to conflict screen when a conflict is detected

### UI & UX

- 🎨 **Material 3** — modern components, rounded surfaces, filled buttons
- 🖋️ **Google Fonts** — Inter (app-wide), Playfair Display (onboarding headings)
- ✨ **Shimmer loading** — skeleton placeholders while notes load
- 📭 **Empty states** — dedicated UI for no notes and no search results
- 📶 **Connectivity bar** — live Online / Offline indicator
- 🚀 **Onboarding** — premium 3-page first-launch experience (Skip / Continue / Get Started)
- 🎯 **Premium editorial theme** — warm cream palette, paper-fold note cards, soft shadows

---

## 🏗 Architecture

This project follows **Feature-First Clean Architecture** — each layer has a single responsibility and dependencies point inward.

```
Presentation  →  Domain  →  Data  →  Core / Services
(Bloc + UI)      (Entities      (Repository    (ApiClient,
                  + Contract)    + DataSources)  NetworkInfo,
                                                SQLite)
```

### Clean Architecture

Separates UI, business rules, and data access. The presentation layer never imports Dio or SQLite directly — it depends only on the `NotesRepository` contract.

### Feature-First Structure

Code is organized by feature (`notes`, `onboarding`) rather than by technical layer at the root. Each feature contains its own `data`, `domain`, and `presentation` folders — making the codebase scalable and easy to navigate.

### Repository Pattern

`NotesRepository` (domain contract) abstracts all data operations. `NotesRepositoryImpl` coordinates local SQLite, the sync queue, and MockAPI — keeping sync logic in one place.

### Dependency Injection

`AppDependencies` wires all dependencies manually in `initialize()` — database, API client, datasources, repository, Bloc, and connectivity service. Exposed via `AppScope` and `AppBlocProvider` InheritedWidgets.

### Bloc State Management

`NotesBloc` handles all note-related events (CRUD, search, sort, sync, conflict resolution). UI reacts to immutable `NotesState` — predictable, testable, and decoupled from data sources.

---

## 🛠 Tech Stack

| Technology             | Purpose                              |
| ---------------------- | ------------------------------------ |
| **Flutter**            | Cross-platform UI framework          |
| **Dart**               | Programming language (SDK ^3.12.2)   |
| **flutter_bloc**       | State management (Bloc pattern)      |
| **equatable**          | Value equality for entities & states |
| **sqflite**            | SQLite local database                |
| **path**               | Database file path resolution        |
| **Dio**                | HTTP client for MockAPI REST calls   |
| **connectivity_plus**  | Network connectivity detection       |
| **uuid**               | Local note ID generation             |
| **intl**               | Date/time formatting                 |
| **shimmer**            | Loading skeleton animations          |
| **google_fonts**       | Inter & Playfair Display typography  |
| **shared_preferences** | First-launch onboarding flag         |
| **MockAPI.io**         | Remote REST backend (notes resource) |
| **Material 3**         | UI design system                     |

---

## 📁 Folder Structure

```
lib/
├── main.dart                          # App entry point
├── app/
│   ├── app.dart                       # MaterialApp root
│   ├── app_start_page.dart            # Onboarding vs Notes routing
│   ├── di/
│   │   └── app_dependencies.dart      # Manual DI container
│   └── theme/
│       └── app_theme.dart             # Material 3 theme & palette
├── core/
│   ├── constants/
│   │   ├── api_constants.dart         # MockAPI base URL & timeouts
│   │   └── db_constants.dart          # SQLite table & column names
│   ├── error/
│   │   └── exceptions.dart            # Typed exception hierarchy
│   ├── network/
│   │   ├── api_client.dart            # Dio HTTP wrapper
│   │   └── network_info.dart          # Connectivity abstraction
│   └── storage/
│       └── onboarding_storage.dart    # First-launch SharedPreferences flag
├── features/
│   ├── notes/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── database_helper.dart
│   │   │   │   ├── notes_local_datasource.dart
│   │   │   │   ├── notes_remote_datasource.dart
│   │   │   │   └── sync_queue_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── note_model.dart
│   │   │   └── repositories/
│   │   │       └── notes_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── note_entities.dart
│   │   │   └── repositories/
│   │   │       └── notes_repository.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── notes_bloc.dart
│   │       │   ├── notes_event.dart
│   │       │   └── notes_state.dart
│   │       ├── pages/
│   │       │   ├── notes_list_page.dart
│   │       │   ├── note_editor_page.dart
│   │       │   └── conflict_resolution_page.dart
│   │       └── widgets/
│   │           ├── note_card.dart
│   │           ├── sync_status_badge.dart
│   │           ├── connectivity_status_bar.dart
│   │           ├── premium_search_bar.dart
│   │           ├── note_card_shimmer.dart
│   │           ├── notes_empty_state.dart
│   │           └── ...
│   └── onboarding/
│       └── presentation/
│           ├── pages/
│           │   └── landing_page.dart
│           ├── theme/
│           │   └── onboarding_typography.dart
│           └── widgets/
│               ├── onboarding_feature_chip.dart
│               ├── onboarding_phone_preview.dart
│               └── onboarding_preview_note_card.dart
└── services/
    └── connectivity_service.dart      # Auto-sync on connectivity change

test/
├── note_entity_test.dart
├── notes_repository_sync_test.dart
└── widget_test.dart

assets/
└── images/
    └── app_icon.png
```

---

## 🔄 Offline Sync Flow

Every CRUD operation follows the same local-first pipeline:

```
User Action (Create / Edit / Delete)
        ↓
   SQLite (immediate write)
        ↓
   Sync Queue (enqueue operation)
        ↓
   Sync Status → Pending Sync
        ↓
   Connectivity Restored  ←  ConnectivityService listens
        ↓
   Push Queue → MockAPI (POST / PUT / DELETE)
        ↓
   Pull Remote → MockAPI (GET /notes)
        ↓
   Sync Status → Synced
```

### Push Details

- Queue processed FIFO by `queue_created_at`
- Operations are coalesced (e.g. create + delete removes the note permanently)
- Conflicts during push halt sync and mark the note as **Conflict**
- Failed operations retry up to **3 times** (`ApiConstants.maxRetryAttempts`)

### Pull Details

- Fetches all remote notes after a successful push
- New remote notes are inserted locally with a new UUID + `serverId`
- Existing synced notes are updated if remote `updatedAt` is newer
- Remote-deleted notes are permanently removed locally

### Sync Triggers

1. `ConnectivityService` — on connectivity restore and initial app launch
2. After CRUD — if device is already online
3. Pull-to-refresh — user-initiated via `NotesRefreshed` event

---

## ⚔️ Conflict Resolution

### Detection

Conflicts are detected in `NotesRepositoryImpl._hasConflict()` when:

1. A note has **Pending Sync** status and a known `serverId`
2. Local and remote content differ (title, body, or delete state)
3. **Both** local and remote changed since the last known sync baseline

Detection uses two strategies:

- **Sync baseline** — `syncBaseTitle`, `syncBaseBody`, `syncBaseIsDeleted` captured when a synced note is edited
- **Timestamp fallback** — compares `updatedAt` vs `remoteUpdatedAt` when baseline is unavailable

When a conflict is found, local and remote snapshots are stored and the note status becomes **Conflict**. The sync queue entry for that note is cleared.

### Resolution UI

`ConflictResolutionPage` presents:

- ⚠️ Warning banner explaining the conflict
- 📱 **Local Version** card — device content with timestamp
- ☁️ **Remote Version** card — server content with timestamp
- Three resolution actions:

| Action          | Behavior                                                                                   |
| --------------- | ------------------------------------------------------------------------------------------ |
| **Keep Local**  | Clears snapshots → force-pushes local version to MockAPI                                   |
| **Keep Remote** | Fetches remote → overwrites local → marks Synced                                           |
| **Merge**       | Opens `NoteEditorPage` in merge mode → user edits combined content → pushes merged version |

---

## 📱 Screens

| Screen                  | File                            | Description                                                         |
| ----------------------- | ------------------------------- | ------------------------------------------------------------------- |
| **App Start**           | `app_start_page.dart`           | Routes to onboarding or notes home based on first-launch flag       |
| **Onboarding**          | `landing_page.dart`             | 3-page premium onboarding (features, app preview, get started)      |
| **Notes Home**          | `notes_list_page.dart`          | Note list with search, sort, sync badges, FAB, pull-to-refresh      |
| **Note Editor**         | `note_editor_page.dart`         | Create new note or edit existing note                               |
| **Merge Editor**        | `note_editor_page.dart`         | Merge mode — side-by-side local/remote preview with editable fields |
| **Conflict Resolution** | `conflict_resolution_page.dart` | Compare versions and choose Keep Local / Keep Remote / Merge        |

---

## 🚀 Installation

### Prerequisites

- Flutter SDK (stable, ^3.12.2)
- Dart SDK
- Android Studio / Xcode (for device emulation)
- A free [MockAPI.io](https://mockapi.io) account

### Steps

```bash
# Clone the repository
git clone <your-repo-url>
cd offline_notes

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Run Tests

```bash
flutter test
```

---

## ⚙️ Configuration

### MockAPI Setup

1. Create a free project at [mockapi.io](https://mockapi.io)
2. Create a **notes** resource with these fields:

| Field       | Type              |
| ----------- | ----------------- |
| `id`        | string            |
| `title`     | string            |
| `body`      | string            |
| `createdAt` | string (datetime) |
| `updatedAt` | string (datetime) |
| `isDeleted` | boolean           |

3. Update the base URL in:

```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = 'https://YOUR-PROJECT-ID.mockapi.io';
```

4. The notes endpoint is `/notes` (defined as `ApiConstants.notesEndpoint`)

### App Icon & Splash

Configured in `pubspec.yaml` via `flutter_launcher_icons` and `flutter_native_splash`. Regenerate after changing `assets/images/app_icon.png`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## 📦 Dependencies

### Production (`dependencies`)

| Package              | Version  |
| -------------------- | -------- |
| `flutter`            | sdk      |
| `cupertino_icons`    | ^1.0.8   |
| `flutter_bloc`       | ^9.1.1   |
| `equatable`          | ^2.0.7   |
| `dio`                | ^5.8.0+1 |
| `sqflite`            | ^2.4.2   |
| `path`               | ^1.9.1   |
| `connectivity_plus`  | ^6.1.4   |
| `uuid`               | ^4.5.1   |
| `intl`               | ^0.20.2  |
| `shimmer`            | ^3.0.0   |
| `google_fonts`       | ^6.2.1   |
| `shared_preferences` | ^2.5.5   |

### Development (`dev_dependencies`)

| Package                  | Version |
| ------------------------ | ------- |
| `flutter_test`           | sdk     |
| `flutter_lints`          | ^6.0.0  |
| `bloc_test`              | ^10.0.0 |
| `mocktail`               | ^1.0.4  |
| `flutter_launcher_icons` | ^0.14.3 |
| `flutter_native_splash`  | ^2.4.6  |

---

## 🌟 Project Highlights

This project demonstrates production-ready Flutter development across multiple dimensions:

- **Offline-first by design** — local SQLite is the source of truth; the network is an enhancement, not a requirement
- **Real sync engine** — push-then-pull with queue coalescing, retry logic, and mutex-guarded sync cycles
- **Conflict handling beyond basics** — three-way baseline detection, snapshot storage, and three resolution strategies including manual merge
- **Clean Architecture in practice** — strict layer separation with repository abstraction, typed exceptions, and manual DI
- **Thoughtful UX** — sync status on every note, connectivity indicator, shimmer loading, empty states, and auto-navigation to conflicts
- **Testable core** — repository sync logic covered by unit tests with mocked datasources (`mocktail`)

---

## 🔮 Future Improvements

Optional enhancements that could be added next:

- [ ] Bloc unit tests using `bloc_test` (package already in dev_dependencies)
- [ ] Widget / integration tests for key user flows
- [ ] Domain use-case layer between Bloc and Repository
- [ ] Structured logging service (replace Dio-only `LogInterceptor`)
- [ ] Wire `AppDependencies.dispose()` into app lifecycle
- [ ] SQLite-backed reactive streams instead of polling in `watchNotes()`
- [ ] Background sync with `workmanager` for killed-app scenarios
- [ ] Dark mode polish and theme toggle in settings

---

## 👨‍💻 Developed By

**Mukesh Kanna**  
Flutter Developer

---

## 📄 License

MIT — portfolio and assignment use.
