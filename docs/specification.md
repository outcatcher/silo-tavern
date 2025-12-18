# SiloTavern - Server Management Application

## Overview
SiloTavern is a Flutter application for managing game servers. Users can view, add, edit, and delete servers with various configurations.

## Core Features

### 1. Server List Display
- Displays a list of configured game servers
- Each server shows:
  - Name
  - Address/URL
  - Status indicator (active/inactive)
- Servers are displayed in a scrollable list
- Each server row is swipeable for quick actions

### 2. Server Creation
- Add new servers through a dedicated creation form
- Required fields:
  - Server Name
  - Server URL (must be valid HTTP/HTTPS URL)
- Optional authentication configuration:
  - None (default)
  - Credentials (username and password required)
- Form validation ensures all required fields are filled
- Save button creates and returns the new server
- Back/cancel button discards changes

### 3. Server Editing
- Edit existing servers by swiping left-to-right on server row
- Opens the same form as creation but pre-filled with existing data
- Preserves server ID and active status
- Save updates the server configuration
- Back/cancel button discards changes

### 4. Server Deletion
- Delete servers by swiping right-to-left on server row
- Shows confirmation dialog before deletion
- Confirmation dialog includes:
  - Title: "Confirm Deletion"
  - Message: "Delete [Server Name]?" (with server name in red, monospace font, light red background)
  - Two buttons:
    - CANCEL (base color) - cancels deletion
    - DELETE (red color) - confirms deletion
- CANCEL keeps the server in the list
- DELETE removes the server from the list

### 5. Server Status Management
- Servers have an active/inactive status
- Visual indicator shows current status:
  - Green circle with checkmark = Active
  - Grey circle with X = Inactive
- Status is preserved during edit operations

## User Interface

### Main Screen
- App bar with title "SiloTavern - Servers"
- Scrollable list of servers
- Floating action button (+) for adding new servers

### Server Row
- Card-based layout with margin
- Left-to-right swipe: Edit action (blue background with edit icon)
- Right-to-left swipe: Delete action (red background with delete icon)
- Leading avatar shows status
- Title shows server name
- Subtitle shows server address

### Server Creation/Edit Screen
- App bar with:
  - Back arrow button (cancels operation)
  - Title ("Add New Server" or "Edit Server")
  - Checkmark button (saves changes)
- Form fields:
  - Server Name (required)
  - Server URL (required, validated)
  - Authentication section:
    - Radio buttons for None/Credentials
    - Username field (required when credentials selected)
    - Password field (required when credentials selected)
- Helper text indicating required fields

## Data Model

### Server
- id: Unique identifier
- name: Server name (string)
- address: Server URL (string)
- isActive: Status flag (boolean)
- authentication: Authentication configuration

### AuthenticationInfo
- useCredentials: Boolean flag
- username: Username string (empty if not using credentials)
- password: Password string (empty if not using credentials)

## Business Rules

### Validation Rules
1. Server Name: Cannot be empty
2. Server URL: Cannot be empty, must start with http:// or https://
3. Authentication Credentials:
   - If credentials selected, username and password are required
   - If none selected, username and password are ignored

### Navigation Rules
1. Back button/cancel discards unsaved changes
2. Save button validates form and returns server data
3. Invalid forms cannot be saved

### Deletion Rules
1. Deletion requires explicit confirmation
2. Canceling confirmation preserves the server
3. Confirming deletion permanently removes the server

## Error Handling
- Form validation prevents invalid data entry
- Network/API errors would be handled gracefully (future enhancement)
- Invalid states are prevented through validation

## Future Enhancements
- Server connectivity testing
- Server grouping/categories
- Import/export server configurations
- Dark/light theme support
- Server statistics and monitoring