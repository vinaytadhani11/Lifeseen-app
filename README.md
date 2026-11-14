# TableFlow+

**Restaurant Multi-Floor Table & Event Planner**

TableFlow+ is a comprehensive restaurant management application for Chicken Road restaurant, designed to manage multi-floor table operations, staff management, reservations, events, and cash payment processing.

## Features

- 🏢 **Multi-Floor Management**: Manage 4 floors with 40 tables (10 per floor)
- 👥 **Staff Management**: Role-based access control (Manager, Host, Captain, Waiter)
- 📅 **Reservations**: Complete reservation system with status tracking
- 🎉 **Event Planning**: Multi-floor event management
- 📊 **Calendar**: Daily/Weekly/Monthly views with reservations and events overlay
- 🍽️ **Menu Management**: Complete menu CRUD operations
- 🚗 **Parking System**: Vehicle tracking and parking slot management
- 💰 **Cash Payments**: Simple cash payment confirmation system
- 📈 **Revenue Analytics**: Comprehensive revenue tracking and analytics
- 🔐 **Authentication**: Firebase Auth with Email/Password, Apple Sign In, and Guest login

## Technology Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Backend**: Firebase Realtime Database
- **Authentication**: Firebase Auth
- **Navigation**: NavigationUtils (direct class navigation)

## Getting Started

### Prerequisites

- Flutter SDK (3.5.3 or higher)
- Firebase project setup
- iOS/Android development environment

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Add `google-services.json` for Android
   - Add `GoogleService-Info.plist` for iOS
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── theme/
│   ├── widgets/
│   └── utils/
├── models/
├── providers/
├── services/
├── views/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── staff/
│   ├── events/
│   ├── floorplan/
│   ├── reservations/
│   ├── calendar/
│   ├── revenue/
│   ├── menu/
│   ├── parking/
│   ├── profile/
│   └── payments/
└── main.dart
```

## Development Phases

- **Phase 1**: Base Setup (Firebase, Auth, Onboarding)
- **Phase 2**: Core Operations (Staff, Tables, Reservations, Events, Menu, Parking)
- **Phase 3**: Payments (Bills, Cash Payments, Receipts, Analytics)
- **Phase 4**: Profile & Settings
- **Phase 5**: Polish & Testing

## Documentation

- [Project Requirements Document](./docs/project_requirements_document.md)
- [Implementation Plan](./docs/implementation_plan.md)

## License

Private project for Chicken Road restaurant.
