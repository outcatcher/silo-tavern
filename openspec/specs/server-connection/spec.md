# Server Connection Specification

## Overview
This specification defines the requirements for connecting to servers in the SiloTavern application. The feature enables users to establish authenticated connections to their SillyTavern instances with proper CSRF handling, token management, and user feedback.

## Requirements

### Requirement: Connect to Server
The system SHALL provide the ability to connect to a configured server with proper authentication and token management.

#### Scenario: Successful server connection
- **WHEN** a user taps on a server in the server list
- **THEN** the system SHALL send a CSRF request to the server
- **AND** show a "Connecting to server..." toast notification
- **AND** store the token cookie for future requests
- **AND** navigate to an under construction page with server name as title

#### Scenario: CSRF request failure
- **WHEN** the CSRF request fails during server connection
- **THEN** the system SHALL show an "Error connecting to server" toast notification
- **AND** remain on the server list page

#### Scenario: Authentication failure
- **WHEN** the authentication request fails after successful CSRF
- **THEN** the system SHALL show an "Authentication failed" toast notification
- **AND** remain on the server list page

#### Scenario: Under construction page display
- **WHEN** a server connection is successful
- **THEN** the system SHALL display a page with the server name as title
- **AND** show a back arrow for navigation
- **AND** display "Under construction" as the main content
- **AND** show a standard image of things being built

## Technical Implementation Details

### API Integration
The feature integrates with the SillyTavern API as defined in `silly-tavern-openapi.yaml`:
- CSRF token endpoint: `/csrf-token` (GET)
- Authentication endpoints as defined in the OpenAPI specification

### Security Considerations
- Token cookies SHALL be stored securely using the existing secure storage mechanisms
- CSRF protection SHALL be implemented according to the API specification
- All network requests SHALL follow the authentication patterns established in the OpenAPI specification

### User Interface
- Toast notifications SHALL provide immediate feedback during connection process
- The under construction page SHALL include standard navigation elements (back arrow)
- Server name SHALL be displayed as the page title

## Future Considerations
- Token refresh mechanisms for handling expiration
- Enhanced server functionality beyond the under construction placeholder
- Offline connection state handling