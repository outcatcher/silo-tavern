# SiloTavern - Test Plan

## Overview
This document outlines the comprehensive test plan for the SiloTavern server management application, based on the specification.md requirements.

## Test Categories

### 1. Server List Display Tests

#### 1.1 Basic Display
- [ ] Verify app title "SiloTavern - Servers" is displayed
- [ ] Verify initial servers are displayed (Production, Staging, Development)
- [ ] Verify each server shows name, address, and status indicator
- [ ] Verify floating action button (+) is present

#### 1.2 Server Row UI
- [ ] Verify server rows use card layout with proper margins
- [ ] Verify status indicators (green check for active, grey X for inactive)
- [ ] Verify swipe actions show correct backgrounds and icons

### 2. Server Creation Tests

#### 2.1 Form Display
- [ ] Verify "Add New Server" title is displayed
- [ ] Verify back button and save button are present
- [ ] Verify required field indicators (*)
- [ ] Verify authentication section with radio buttons

#### 2.2 Form Validation
- [ ] Verify empty server name shows validation error
- [ ] Verify empty URL shows validation error
- [ ] Verify invalid URL format shows validation error
- [ ] Verify credentials fields are hidden when "None" selected
- [ ] Verify credentials fields are visible when "Credentials" selected
- [ ] Verify empty username shows validation error when credentials selected
- [ ] Verify empty password shows validation error when credentials selected

#### 2.3 Form Submission
- [ ] Verify valid form can be submitted
- [ ] Verify submitted server is returned to server list
- [ ] Verify back button cancels creation

### 3. Server Editing Tests

#### 3.1 Form Pre-population
- [ ] Verify "Edit Server" title is displayed
- [ ] Verify existing server data is pre-filled
- [ ] Verify server ID and active status are preserved

#### 3.2 Form Modification
- [ ] Verify form can be modified
- [ ] Verify modified data is saved correctly
- [ ] Verify back button cancels editing

### 4. Server Deletion Tests

#### 4.1 Swipe Action
- [ ] Verify right-to-left swipe shows red background with delete icon
- [ ] Verify swipe triggers deletion process

#### 4.2 Confirmation Dialog
- [ ] Verify confirmation dialog appears after swipe
- [ ] Verify dialog title is "Confirm Deletion"
- [ ] Verify server name is displayed in red with monospace font and light red background
- [ ] Verify CANCEL button is base color
- [ ] Verify DELETE button is red color

#### 4.3 Dialog Actions
- [ ] Verify CANCEL button preserves server
- [ ] Verify DELETE button removes server
- [ ] Verify server list updates after deletion

### 5. Authentication Tests

#### 5.1 None Authentication
- [ ] Verify "None" is default authentication option
- [ ] Verify username/password fields are hidden
- [ ] Verify server saves with no authentication

#### 5.2 Credentials Authentication
- [ ] Verify selecting "Credentials" shows username/password fields
- [ ] Verify username/password fields are required
- [ ] Verify server saves with credentials authentication

### 6. Navigation Tests

#### 6.1 Main Screen Navigation
- [ ] Verify floating action button navigates to creation screen
- [ ] Verify edit swipe navigates to edit screen

#### 6.2 Form Navigation
- [ ] Verify back button returns to server list
- [ ] Verify save button returns to server list with data
- [ ] Verify cancel confirmation when navigating away with unsaved changes (if applicable)

### 7. Data Integrity Tests

#### 7.1 Server Persistence
- [ ] Verify servers maintain their IDs
- [ ] Verify servers maintain their active status
- [ ] Verify authentication data is preserved

#### 7.2 Edge Cases
- [ ] Verify long server names are handled properly
- [ ] Verify long URLs are handled properly
- [ ] Verify special characters in names/URLs are handled
- [ ] Verify empty server list behavior (if all servers deleted)

### 8. Error Handling Tests

#### 8.1 Form Errors
- [ ] Verify validation errors are displayed appropriately
- [ ] Verify error messages are clear and helpful
- [ ] Verify forms cannot be submitted with validation errors

#### 8.2 System Errors
- [ ] Verify graceful handling of navigation failures
- [ ] Verify graceful handling of data saving failures
