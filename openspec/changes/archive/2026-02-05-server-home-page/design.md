# Server Home Page Design

## Architecture Overview

The server home page introduces a new navigation layer between server connection and future functionality. This design ensures proper authentication state management, consistent navigation patterns, and scalable integration with future features.

## Key Design Decisions

### 1. Route Structure
**Decision**: Use `/servers/<id>/dashboard` pattern
**Rationale**: 
- Clearly indicates server context in URL
- Supports multiple server dashboards
- Follows RESTful resource naming conventions
- Easy to extend with sub-routes (e.g., `/servers/<id>/dashboard/characters`)

### 2. Authentication Integration
**Decision**: Route-level authentication guards
**Rationale**:
- Centralized access control
- Reusable across multiple server routes
- Clear separation of authentication concerns
- Easy to test and maintain

### 3. Navigation Pattern
**Decision**: Top navigation bar with back/logout
**Rationale**:
- Consistent with mobile app patterns
- Clear user orientation within server context
- Provides emergency exit (logout) at all times
- Maintains navigation history properly

### 4. Menu Design
**Decision**: Card-like buttons within 700px constraint
**Rationale**:
- Mobile-first approach that scales to desktop
- Clear visual hierarchy and touch targets
- Consistent with Material Design principles
- Responsive within defined constraints

### 5. Under Construction Integration
**Decision**: Parameterized under-construction routing
**Rationale**:
- Single reusable component for all stub functionality
- Proper back navigation context preservation
- Easy to replace with actual functionality later
- Consistent user experience during development

## Technical Implementation

### Component Structure
```
ServerDashboardPage
├── DashboardAppBar (back + logout + title)
├── DashboardMenu
│   ├── PersonasCard (routes to /under-construction?backUrl=...)
│   ├── CharactersCard (routes to /under-construction?backUrl=...)
│   └── ContinueCard (routes to /under-construction?backUrl=...)
└── ResponsiveContainer (max-width: 700px)
```

### Route Configuration
```dart
GoRoute(
  path: '/servers/:serverId/dashboard',
  builder: (context, state) => ServerDashboardPage(
    serverId: state.params['serverId']!,
  ),
  redirect: (context, state) {
    // Authentication guard logic
    if (!hasValidTokens(state.params['serverId']!)) {
      return '/servers';
    }
    return null;
  },
),
```

### Authentication State Management
- Tokens stored per-server basis
- Route guards validate server-specific tokens
- Logout clears only the current server's authentication state
- State persistence through app restarts

### Navigation Flow
```
Server List → Server Dashboard → Under Construction
    ↑             ↑                    ↑
    └─────────────┴────────────────────┘ (back navigation)
```

## Cross-Cutting Concerns

### Responsive Design
- 700px max-width container for desktop/web
- Mobile-responsive card layout
- Adaptive spacing and typography

### Accessibility
- Proper semantic HTML structure
- Keyboard navigation support
- Screen reader compatibility
- Focus management

### Internationalization
- Prepared for text translation
- Culture-aware formatting
- RTL layout support

### Performance Considerations
- Lazy loading of dashboard components
- Efficient token validation
- Minimal re-renders on navigation

## Trade-offs Considered

### Alternative: Modal Dashboard
**Rejected**: Would break navigation history and make back behavior confusing

### Alternative: Single Dashboard Route
**Rejected**: Loses server context specificity and makes authentication more complex

### Alternative: Separate Under Construction Pages
**Rejected**: Creates maintenance overhead for temporary functionality

## Future Extension Points

1. **Actual Functionality**: Replace under-construction routes with real features
2. **Server Context Display**: Show server name, status, connection info
3. **Recent Activity**: "Continue" could show last-used functionality
4. **Permission-based Menu**: Show/hide menu items based on server permissions
5. **Multi-server Management**: Handle switching between multiple server dashboards

## Validation Metrics

- Dashboard load time < 200ms
- Authentication validation < 100ms
- Navigation transitions smooth (60fps)
- Memory usage minimal for dashboard components
- No memory leaks on navigation