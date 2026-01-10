# Remember Me Functionality Specification

## Overview
This document specifies the implementation details for the "Remember me" functionality in the SiloTavern server login feature. This functionality allows users to persist their session across application restarts by storing session cookies securely.

## Requirements

### Functional Requirements

#### Requirement: Remember Me Checkbox
The system SHALL provide a "Remember me" checkbox on the login page.

##### Scenario: Display remember me checkbox
- **WHEN** a user accesses the login page
- **THEN** the system SHALL display a "Remember me" checkbox
- **AND** the checkbox SHALL be unchecked by default

#### Requirement: Persistent Session Storage
The system SHALL store session cookies persistently when "Remember me" is selected.

##### Scenario: Store session cookies when remember me is selected
- **WHEN** a user successfully authenticates with "Remember me" selected
- **THEN** the system SHALL store the session cookies in secure persistent storage
- **AND** the cookies SHALL be associated with the specific server ID

##### Scenario: Skip login for existing persistent sessions
- **WHEN** a user accesses a server with valid persistent session cookies
- **THEN** the system SHALL skip the login page
- **AND** proceed directly to the under construction page

#### Requirement: Session Expiration Handling
The system SHALL handle expired persistent sessions appropriately.

##### Scenario: Expired persistent session
- **WHEN** a user accesses a server with expired persistent session cookies
- **THEN** the system SHALL remove the expired cookies
- **AND** display the login page for re-authentication

### Technical Requirements

#### Requirement: Secure Storage
The system SHALL store persistent session cookies using secure storage mechanisms.

##### Scenario: Secure cookie storage
- **WHEN** session cookies are stored for persistent sessions
- **THEN** the cookies SHALL be encrypted and stored using platform-appropriate secure storage
- **AND** the cookies SHALL NOT be accessible to other applications

#### Requirement: Cookie Association
The system SHALL associate persistent session cookies with specific servers.

##### Scenario: Server-specific cookie storage
- **WHEN** session cookies are stored for persistent sessions
- **THEN** the cookies SHALL be stored with an association to the server ID
- **AND** only be used for requests to that specific server

## Implementation Details

### UI Changes

1. Add a "Remember me" checkbox to the login page:
   ```dart
   CheckboxListTile(
     title: const Text('Remember me'),
     value: _rememberMe,
     onChanged: (value) {
       setState(() {
         _rememberMe = value ?? false;
       });
     },
     controlAffinity: ListTileControlAffinity.leading,
   )
   ```

2. Initialize `_rememberMe` state variable to `false` by default

### Domain Layer Changes

1. Update `authenticateWithServer` method to accept a `rememberMe` parameter:
   ```dart
   Future<ConnectionResult> authenticateWithServer(
     server_models.Server server,
     ConnectionCredentials credentials, {
     bool rememberMe = false,
   }) async
   ```

2. When `rememberMe` is true, save session cookies to secure storage:
   ```dart
   if (rememberMe) {
     final cookies = await session.getSessionCookies();
     await secureStorage.saveSessionCookies(server.id, cookies);
   }
   ```

3. Add method to check for persistent sessions:
   ```dart
   Future<bool> hasPersistentSession(server_models.Server server) async {
     final cookies = await secureStorage.loadSessionCookies(server.id);
     return cookies != null && cookies.isNotEmpty && !cookiesAreExpired(cookies);
   }
   ```

4. Add method to load persistent session cookies:
   ```dart
   Future<List<Cookie>?> loadPersistentSessionCookies(String serverId) async {
     return await secureStorage.loadSessionCookies(serverId);
   }
   ```

### Session Interface Changes

1. Add method to retrieve session cookies from a connection session:
   ```dart
   Future<List<Cookie>> getSessionCookies();
   ```

### Login Page Changes

1. Check for existing persistent sessions when the page loads:
   ```dart
   @override
   void initState() {
     super.initState();
     _checkForExistingSession();
   }
   
   void _checkForExistingSession() async {
     // Check both in-memory and persistent sessions
     if (widget.connectionDomain.hasExistingSession(widget.server) ||
         await widget.connectionDomain.hasPersistentSession(widget.server)) {
       // Skip login and go directly to connect page
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
           router.go(/* connect page route */);
         }
       });
     }
   }
   ```

### Storage Layer Changes

1. The existing `saveSessionCookies` and `loadSessionCookies` methods in `ConnectionStorage` can be used for persistent storage
2. Add utility method to check if cookies are expired:
   ```dart
   bool cookiesAreExpired(List<Cookie> cookies) {
     final now = DateTime.now();
     return cookies.any((cookie) => cookie.expires != null && cookie.expires!.isBefore(now));
   }
   ```

## Security Considerations

1. Session cookies MUST be stored using secure storage mechanisms (`FlutterSecureStorage`)
2. Session cookies SHOULD be associated with specific servers to prevent cross-site usage
3. Expired cookies MUST be removed from persistent storage
4. The "Remember me" feature SHOULD be opt-in (unchecked by default)
5. Session cookies SHOULD have appropriate expiration times set by the server

## Testing Requirements

### Unit Tests

1. Test `authenticateWithServer` with `rememberMe` parameter:
   - Verify session cookies are saved when `rememberMe` is true
   - Verify session cookies are not saved when `rememberMe` is false
   - Verify cookies are associated with the correct server ID

2. Test `hasPersistentSession` method:
   - Verify returns true when valid cookies exist
   - Verify returns false when no cookies exist
   - Verify returns false when cookies are expired

3. Test `loadPersistentSessionCookies` method:
   - Verify returns correct cookies when they exist
   - Verify returns null when no cookies exist

### Widget Tests

1. Test login page with "Remember me" checkbox:
   - Verify checkbox is displayed
   - Verify checkbox state changes on user interaction
   - Verify authentication is called with correct `rememberMe` value

2. Test login page with existing persistent sessions:
   - Verify navigation to connect page when valid persistent sessions exist
   - Verify login form is displayed when no valid persistent sessions exist

### Integration Tests

1. Test complete flow with "Remember me" selected:
   - Verify session cookies are stored after successful authentication
   - Verify login page is skipped on subsequent access
   - Verify session cookies are used for API requests

2. Test complete flow with expired persistent sessions:
   - Verify expired cookies are removed
   - Verify login page is displayed for re-authentication

## Future Considerations

1. Implement automatic session refresh mechanisms for long-lived sessions
2. Add user preference to clear all persistent sessions
3. Consider adding a "Remember me for X days" option with configurable duration