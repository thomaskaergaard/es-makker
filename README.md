# Es Makker – Score Tracker 🃏

A Flutter web application for tracking scores while playing the Danish card game **Es Makker**.

## Features

- **Flexible player setup** – support for 2–6 players with customisable names
- **Per-round scoring** – enter each player's score (positive or negative) after every round
- **Live scoreboard** – sorted standings with 🥇🥈🥉 medals showing the current leader
- **Round history** – a full table showing every round's scores plus running totals
- **Undo last round** – remove a mistakenly entered round with one tap
- **New game** – reset and start fresh without reloading the page
- **PWA-ready** – installable as a Progressive Web App on any device

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.24

### Running locally

```bash
# Install dependencies
flutter pub get

# Run in Chrome (web mode)
flutter run -d chrome
```

### Running tests

```bash
flutter test
```

### Building for production

```bash
flutter build web --release
# Output is in build/web/
```

## App structure

```
lib/
├── main.dart                  # Entry point
├── theme/
│   └── app_theme.dart         # Colours and Material 3 theme
├── models/
│   ├── player.dart            # Player data model
│   ├── round.dart             # Round data model
│   └── game_state.dart        # Immutable game state + business logic
└── screens/
    ├── setup_screen.dart      # Configure players before the game starts
    ├── game_screen.dart       # Tab host (Round + Scoreboard)
    ├── round_screen.dart      # Enter scores for the current round
    └── scoreboard_screen.dart # Cumulative standings and round history
```

## Scoring

Es Makker is a Danish trick-taking card game. This app is agnostic about the
exact scoring rules – simply enter whatever points each player earned (or lost)
in the round. The app accumulates the scores across all rounds and shows a live
leaderboard.

## CI / CD

The repository includes a GitHub Actions workflow (`.github/workflows/flutter-ci.yml`)
that:

1. Runs `flutter analyze` and `flutter test` on every push / PR.
2. Builds the web app and uploads the artefact so it is ready for deployment.