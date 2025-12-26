# Platform E2E Tests

This directory contains true end-to-end tests that run the entire SiloTavern application on a platform, interacting with it as a real user would.

## Test Files

- `server_list_e2e_test.dart` - Main E2E tests that verify the complete application workflow
- `e2e_main.dart` - Special main entry point that uses isolated storage for E2E tests
- `driver.dart` - Driver script required for integration testing

## Running E2E Tests

To run the end-to-end tests on Linux platform:

```bash
flutter drive -t test/02_integration/e2e_main.dart --driver=test/02_integration/driver.dart --target=test/02_integration/server_list_e2e_test.dart -d linux
```

## Test Coverage

The E2E tests verify:

1. **Smoke Test**: Basic app loading and navigation
2. **Add Server Workflow**: Creating and saving a new server
3. **Full Workflow**: Complete cycle of Create, Edit, Delete operations
4. **UI Interactions**: Tapping buttons, entering text, navigating between screens
5. **Data Persistence**: Verifying servers are properly saved and displayed

## Storage Isolation

To prevent E2E tests from interfering with the main application data, a special isolated storage system is used:

- **Regular App**: Uses `servers/*` prefix for storage keys
- **E2E Tests**: Uses `e2e_servers/*` prefix for storage keys

This ensures that:
1. Running E2E tests won't affect your regular application data
2. Your regular app usage won't interfere with E2E test execution
3. Test data is completely isolated and automatically cleaned up

The isolation is achieved by using different key prefixes at the storage layer, so both the app and tests can run simultaneously without any data conflicts.

## How It Works

These tests use the `integration_test` package to:
- Launch the complete SiloTavern application on a real platform (Linux in this case)
- Interact with real UI components using `WidgetTester`
- Verify UI state changes and transitions
- Test the full stack from UI to data persistence

Unlike unit/widget tests, these tests run the entire application on a real platform and exercise the complete workflow with actual storage implementations.