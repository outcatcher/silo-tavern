# Project Context

## Purpose
SiloTavern is a Flutter application for managing server connections. It allows users to add, edit, and delete servers with optional authentication credentials.

## Tech Stack
- Dart/Flutter
- shared_preferences for local data persistence
- flutter_secure_storage for secure credential storage
- cupertino_icons for additional icon options

## Project Conventions

### Code Style
- Follow Dart's null safety features extensively
- Use final fields where possible for immutability
- Use named constructors for creating objects with different configurations
- Use const constructors where possible for performance optimization

### Architecture Patterns
- Domain-Driven Design: Business logic is separated from UI concerns
- Service Layer: Server management is handled through a service class rather than directly in UI
- State Management: Uses Flutter's built-in state management with StatefulWidget for simple state needs

### Testing Strategy
- Tagged Tests: Tests are organized with tags (unit, widget, integration)
- Grouping: Related tests are grouped using group() for better organization
- State Management: Widget tests focus on verifying UI state changes in response to user interactions

### Git Workflow
- Feature branches from main
- Squash merges for clean history
- Conventional commit messages

## Domain Context
- Server: Represents a server connection with name, address, and optional authentication
- AuthenticationInfo: Credentials for server authentication
- ServerService: Manages collection of servers

## Important Constraints
- Authentication Security: Passwords are stored using secure storage mechanisms
- Build Context Management: When showing dialogs after async operations, always check mounted before calling setState()
- Gesture Handling: Both long press and secondary tap are implemented for context menus to support different input methods

## External Dependencies
- shared_preferences: For local data persistence
- flutter_secure_storage: For secure credential storage
- cupertino_icons: For additional icon options
