# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ArgusAI iOS is a SwiftUI prototype iPhone app for the ArgusAI home security system. It connects to an ArgusAI backend (local via Bonjour or cloud relay) to display security events and receive push notifications.

## Build and Run

Open in Xcode:
```bash
open argusai-ios/argusai-ios.xcodeproj
```

- **Build**: Cmd+B
- **Run**: Cmd+R (requires iOS device for push notifications)
- **Test**: Cmd+U

Requirements: iOS 26.2+, Xcode 26.2+, macOS 14+

## Architecture

### App Entry & Navigation
- `ArgusAIApp.swift` - App entry point, injects services via SwiftUI environment, contains `ContentView` router and `MainTabView`
- Navigation flow: `PairingView` (unauthenticated) → `MainTabView` with Events/Cameras/Settings tabs

### Services Layer (all in `Services/`)
- **AuthService** - JWT-based authentication with 6-digit pairing codes, token refresh with rotation
- **APIClient** - Actor-based HTTP client with automatic token refresh and exponential backoff retry
- **DiscoveryService** - Bonjour service discovery (`_argusai._tcp.local`), singleton with local/cloud URL fallback
- **KeychainService** - Secure credential storage
- **PushService** - APNS handling

### Data Flow Pattern
ViewModels use `@Observable` macro and are created as `@State` in Views. Services are injected via `@Environment`. All network operations use async/await.

```swift
// Typical pattern
@Environment(AuthService.self) private var authService
@State private var viewModel = EventListViewModel()

// In view body
.task { await viewModel.loadEvents(authService: authService) }
```

### Network Priority
1. Local discovery via Bonjour (`_argusai._tcp.local`)
2. Falls back to `cloudRelayURL` in DiscoveryService if local unavailable

### API Endpoints (all prefixed with `/api/v1/mobile/`)
- Auth: `POST /auth/pair`, `POST /auth/verify`, `POST /auth/refresh`
- Events: `GET /events`, `GET /events/{id}`, `GET /events/{id}/thumbnail`
- Cameras: `GET /cameras`, `GET /cameras/{id}/snapshot`
- Push: `POST /push/register`

## Key Patterns

### Token Management
- Access tokens expire after 1 hour, refresh tokens after 30 days
- Refresh tokens are rotated on each use
- `APIClient.authenticatedRequest` handles 401 errors with automatic refresh

### Models
- `EventSummary` for list views, `EventDetail` for full event data
- `SmartDetectionType` enum: person, vehicle, package, animal, motion
- All use `CodingKeys` with snake_case API mapping

### Error Handling
- `APIError` enum in `APIClient.swift` for network errors
- `AuthError` enum in `AuthService.swift` for auth failures
- Views display errors via `ErrorView` with retry button

## Test Structure

Tests are in `ArgusAITests/` directory:
- `ViewModels/PairingViewModelTests.swift` - Code validation, digit filtering
- `ViewModels/EventListViewModelTests.swift` - Model parsing
- `Services/APIClientTests.swift` - JSON decoding, error handling

## Configuration

Set cloud relay URL in `DiscoveryService.swift`:
```swift
var cloudRelayURL: String = "https://your-argusai-instance.example.com"
```
