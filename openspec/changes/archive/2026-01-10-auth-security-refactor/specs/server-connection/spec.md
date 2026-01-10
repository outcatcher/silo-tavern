## MODIFIED Requirements
### Requirement: Connect to Server
The system SHALL provide the ability to connect to a configured server with proper authentication and token management.

#### Scenario: Successful server connection
- **WHEN** a user taps on a server in the server list
- **THEN** the system SHALL display a login page for authentication
- **AND** send a CSRF request to the server
- **AND** authenticate using provided credentials
- **AND** store the session cookie for future requests
- **AND** navigate to an under construction page with server name as title

#### Scenario: CSRF request failure
- **WHEN** the CSRF request fails during server connection
- **THEN** the system SHALL show an "Error connecting to server" snackbar notification
- **AND** remain on the login page

#### Scenario: Authentication failure
- **WHEN** the authentication request fails after successful CSRF
- **THEN** the system SHALL show an "Authentication failed" snackbar notification
- **AND** remain on the login page

#### Scenario: Under construction page display
- **WHEN** a server connection is successful
- **THEN** the system SHALL display a page with the server name as title
- **AND** show a back arrow for navigation
- **AND** display "Under construction" as the main content
- **AND** show a standard image of things being built

## ADDED Requirements
### Requirement: On-Demand Authentication
The system SHALL prompt users for authentication credentials when connecting to servers.

#### Scenario: Login page display
- **WHEN** a user selects a server from the list
- **THEN** the system SHALL display a login form with username and password fields
- **AND** provide a "Remember me" checkbox
- **AND** provide a way to cancel the connection attempt

#### Scenario: Session cookie storage
- **WHEN** authentication is successful
- **THEN** the system SHALL securely store the session cookie
- **AND** use the stored cookie for subsequent API calls to the same server

#### Scenario: Remember me functionality
- **WHEN** a user successfully authenticates with "Remember me" selected
- **THEN** the system SHALL persist the session cookies for future use
- **AND** automatically log the user in on subsequent visits to the same server

#### Scenario: Session expiration handling
- **WHEN** a stored session cookie expires
- **THEN** the system SHALL automatically prompt for re-authentication
- **AND** update the stored session cookie

### Requirement: Server Connection Status
The system SHALL provide visual indicators for server connection status.

#### Scenario: CSRF token status indicator
- **WHEN** a server has a valid stored CSRF token
- **THEN** the system SHALL display a green lock icon
- **AND** show "Ready to connect" tooltip on hover

#### Scenario: CSRF token loading indicator
- **WHEN** the system is fetching a CSRF token for a server
- **THEN** the system SHALL display a loading animation
- **AND** show "Checking server availability" tooltip on hover

#### Scenario: CSRF token failure indicator
- **WHEN** the CSRF token request for a server fails
- **THEN** the system SHALL display a red stop sign icon
- **AND** show "Server unavailable" tooltip on hover

#### Scenario: Active session indicator
- **WHEN** a server has a valid stored session cookie
- **THEN** the system SHALL display a green checkmark icon
- **AND** show "Session active" tooltip on hover
