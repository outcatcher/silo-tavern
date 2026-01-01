# Change: Connect to Server

## Why
Users need to establish connections to configured servers to access their SillyTavern instances. This feature enables authentication and navigation to a dedicated server interface.

## What Changes
- Add server connection workflow with CSRF token handling
- Implement authentication with token cookie storage
- Create under construction page for connected servers
- Add user feedback through snackbar notifications

## Impact
- Affected specs: server-connection
- Affected code: Server list UI, networking layer, navigation
