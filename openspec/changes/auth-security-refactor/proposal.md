# Change: Authentication Security Refactor

## Why
Currently, the application stores server credentials (username/password) persistently, which is a security anti-pattern. This creates unnecessary risk as passwords are stored long-term and accessible in memory. The API supports session-based authentication where passwords can be used to obtain session cookies that expire and provide better security.

## What Changes
- **BREAKING** Remove credential storage from server configuration
- Add on-demand login page that appears when connecting to any server
- Store session cookies AND CSRF tokens securely instead of passwords
- Update authentication flow to be session-based
- Remove `AuthenticationInfo` model and related credential storage
- Add server connection status indicators (CSRF token status)
- Require authentication for ALL servers (no exceptions)

## Impact
- Affected specs: `server-management`, `server-connection`
- Affected code: `lib/domain/servers/models.dart`, `lib/services/servers/storage.dart`, `lib/ui/server_list_page.dart`, `lib/domain/servers/domain.dart`
- User experience: Additional login step when connecting to servers
- Security: No credential persistence, pure session-based authentication