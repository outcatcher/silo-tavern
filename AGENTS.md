<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Agent Guide for SiloTavern

This document provides essential information for AI agents working with the SiloTavern codebase.

## Project Overview

SiloTavern is a Flutter application for managing server connections. It allows users to add, edit, and delete servers with optional authentication credentials.

## Code Organization

```
lib/
├── domain/          # Core data models and business logic
│   ├── server.dart          # Server and AuthenticationInfo models
│   └── server_service.dart  # Service for managing server collection
├── ui/              # User interface components
│   ├── server_list_page.dart     # Main screen showing server list
│   └── server_creation_page.dart # Screen for adding/editing servers
├── services/        # External service integrations (currently empty)
└── utils/           # Utility functions
    └── network_utils.dart  # Network-related helper functions

test/
├── 00_unit/         # Unit tests for models and services
├── 01_widget/       # Widget/UI tests
└── 02_integration/  # Integration tests
```

## Essential Commands

### Development Workflow

```bash
# Enable desktop builds
task setup

# Run unit tests
task test:unit

# Run widget tests
task test:widget

# Run integration tests
task test:integration

# Run all tests with coverage
task test:all

# Run linter
task lint

# Format code
task format

# Run on Linux desktop
task run:linux

# Run on web
task run:web
```

### Build Commands

```bash
# Build for web
task build:web

# Build for Linux
task build:linux
```

## Code Patterns and Conventions

### Dart/Flutter Standards

1. **Null Safety**: The project uses Dart's null safety features extensively
2. **Immutability**: Data models use final fields where possible
3. **Named Constructors**: Used for creating objects with different configurations (e.g., `AuthenticationInfo.none()` and `AuthenticationInfo.credentials()`)
4. **Const Constructors**: Used where possible for performance optimization

### Testing Approach

1. **Tagged Tests**: Tests are organized with tags (`unit`, `widget`, `integration`)
2. **Grouping**: Related tests are grouped using `group()` for better organization
3. **State Management**: Widget tests focus on verifying UI state changes in response to user interactions

### UI Components

1. **Material Design**: Uses Flutter's Material Design widgets
2. **Gestures**: Implements various gesture handlers (long press, secondary tap) for context menus
3. **Dismissible Widgets**: Uses `Dismissible` for swipe gestures to edit/delete items
4. **Navigation**: Uses `context.go()` for screen transitions (NEVER use `Navigator.push()` or `Navigator.pop()`)

## Key Gotchas

1. **BuildContext Management**: When showing dialogs after async operations, always check `mounted` before calling `setState()`
2. **Gesture Handling**: Both long press and secondary tap are implemented for context menus to support different input methods
3. **Swipe Actions**: Custom `confirmDismiss` implementation handles different swipe directions for edit/delete actions
4. **Authentication Security**: Passwords are stored using secure storage mechanisms (via `flutter_secure_storage` dependency)

## Dependencies

Core dependencies include:
- `shared_preferences`: For local data persistence
- `flutter_secure_storage`: For secure credential storage
- `cupertino_icons`: For additional icon options

Development dependencies:
- `flutter_lints`: For code quality enforcement
- `flutter_test`: For testing framework

## Architecture Notes

1. **Domain-Driven Design**: Business logic is separated from UI concerns
2. **Service Layer**: Server management is handled through a service class rather than directly in UI
3. **State Management**: Uses Flutter's built-in state management with `StatefulWidget` for simple state needs