# Travel App

A Flutter mobile application implementing the UML class diagram with SQLite database integration.

## Features

This app implements the exact class structure from the provided UML diagram:

### Classes Implemented

1. **Users** - with attributes `name`, `email` and methods:
   - `login()` - User authentication
   - `savePreferences()` - Save user preferences
   - `createTrip()` - Create new trip

2. **Trip** - with attributes `title`, `startDate`, `endDate` and methods:
   - `addDestination()` - Add destination to trip
   - `share()` - Share trip with others

3. **Destination** - with attributes `name`, `type`, `rating` and methods:
   - `search()` - Search for destinations
   - `getDetails()` - Get destination details

4. **AppNotification** - with attributes `message`, `type` and method:
   - `send()` - Send notification to user

5. **Review** - with attributes `comment`, `rating` and methods:
   - `addPhoto()` - Add photo to review
   - `edit()` - Edit existing review

### Database Features

- SQLite database integration using `sqflite` package
- Complete CRUD operations for all entities
- Proper foreign key relationships as shown in UML diagram
- Database helper class for managing all database operations

### UI Screens

1. **Login Screen** - User authentication interface
2. **Home Screen** - Main dashboard showing trips, destinations, and notifications
3. **Reviews Screen** - Manage destination reviews and ratings

## Class Relationships

The app maintains the relationships shown in the UML diagram:
- Users can create multiple Trips (1 to many)
- Users receive Notifications (1 to many) 
- Trips include multiple Destinations (1 to many)
- Destinations have Reviews (1 to many)
- Users write Notifications

## Dependencies

- `flutter` - Flutter framework
- `sqflite` - SQLite database integration
- `path` - Path manipulation utilities
- `intl` - Internationalization support

## Getting Started

1. Ensure Flutter is installed and set up
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application

## Project Structure

```
lib/
├── main.dart                 # App entry point and navigation
├── models/                   # Data models matching UML diagram
│   ├── user.dart            # Users class
│   ├── trip.dart            # Trip class
│   ├── destination.dart     # Destination class
│   ├── notification.dart    # AppNotification class
│   └── review.dart          # Review class
├── services/                 # Database and business logic
│   └── database_helper.dart  # SQLite database operations
└── screens/                  # UI screens
    ├── login_screen.dart     # User login interface
    ├── home_screen.dart      # Main dashboard
    └── reviews_screen.dart   # Reviews management
```

## Usage

1. **Login**: Enter your name and email to login
2. **Create Trip**: Use the "Create Trip" button to add new trips
3. **Add Destinations**: Add destinations to your trips
4. **Send Notifications**: Create and send notifications
5. **Write Reviews**: Add reviews and ratings for destinations
6. **Edit Reviews**: Modify existing reviews

All data is persisted in SQLite database and follows the exact structure and relationships defined in the UML diagram.
