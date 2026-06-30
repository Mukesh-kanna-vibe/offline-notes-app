# Offline Notes

Offline-first Flutter notes app with automatic sync and conflict resolution.

## Tech Stack

| Layer            | Choice                    |
| ---------------- | ------------------------- |
| Local storage    | **SQLite** (`sqflite`)    |
| State management | **Bloc** (`flutter_bloc`) |
| Remote API       | JSON Server (mock REST)   |
| Connectivity     | `connectivity_plus`       |
| HTTP             | `dio`                     |

## Features

- Create, edit, delete, and view notes — fully offline
- SQLite persistence with a pending-operations queue
- Automatic sync when connectivity is restored
- Sync status badges: **Synced**, **Pending Sync**, **Conflict**
- Conflict resolution UI: keep local, keep server, or merge manually

## Project Structure

```
lib/
├── bloc/notes/          # NotesBloc, events, state
├── config/              # API base URL
├── data/                # SQLite database + local data source
├── models/              # Note, PendingOperation, SyncStatus
├── repositories/        # NotesRepository
├── screens/             # List, editor, conflict resolution
├── services/            # API, connectivity, sync
└── widgets/             # NoteCard, SyncStatusBadge
```

## Getting Started

### 1. Install Flutter dependencies

```bash
flutter pub get
```

### 2. Start the mock API server

```bash
cd mock_server
yarn install
yarn start
```

The server runs at `http://localhost:3000`.

### 3. Run the app

```bash
flutter run
```

- **Android emulator** uses `http://10.0.2.2:3000` automatically
- **iOS simulator / macOS** uses `http://localhost:3000`

## Testing Conflict Resolution

1. Start the mock server and run the app while online — notes sync from the server.
2. Turn off Wi‑Fi / enable airplane mode.
3. Edit a note locally (shows **Pending Sync**).
4. In `mock_server/db.json`, change the same note's title/body and bump `updatedAt`.
5. Go back online and tap sync — the note shows **Conflict**.
6. Tap the note to open the conflict resolution screen.

## Sync Flow

```
Offline edit → SQLite + pending_operations queue
       ↓
Connectivity restored → SyncService
       ↓
Pull remote changes → detect conflicts (local + remote both changed)
       ↓
Push pending operations → API
       ↓
Update sync_status in SQLite
```

## Architecture Decisions

- **SQLite** gives relational storage, easy querying, and no code generation.
- **Bloc** separates UI from business logic with explicit events and states.
- **Pending operations queue** ensures offline CRUD is replayed in order when online.
- **Timestamp-based conflict detection** compares `localUpdatedAt` vs `serverUpdatedAt`.
