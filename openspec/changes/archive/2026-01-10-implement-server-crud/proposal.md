# Change: Implement Server CRUD Operations

## Why
The current server management implementation is incomplete and has several critical issues:
1. Missing `loadServers` and `saveServers` methods in `ServerStorage` class
2. Incorrect import path in `server_service.dart` referencing a non-existent file
3. Incomplete `saveServer` method implementation
4. Missing proper CRUD operations (list, get, create, update, delete)

These issues prevent the application from properly managing server data with full persistence and cleanup.

## What Changes
- Implement complete CRUD operations in server storage layer:
  - `listServers()` - Retrieve all servers
  - `getServer(String id)` - Retrieve a specific server by ID
  - `createServer(Server server)` - Create a new server
  - `updateServer(Server server)` - Update an existing server
  - `deleteServer(String id)` - Delete a server and all associated data
- Fix import path in `server_service.dart`
- Ensure proper ordering of servers is maintained
- Ensure all data is completely removed when a server is deleted
- Add proper error handling and validation

## Impact
- Affected specs: server-management
- Affected code: 
  - `lib/services/server_storage.dart`
  - `lib/domain/server_service.dart`
  - `lib/services/server_models.dart`