import '../models/user.dart';
import '../models/trip.dart';
import '../models/destination.dart';
import '../models/notification.dart';
import '../models/review.dart';

class InMemoryStorage {
  static final InMemoryStorage _instance = InMemoryStorage._internal();
  static InMemoryStorage get instance => _instance;
  InMemoryStorage._internal();

  // In-memory storage lists
  final List<Users> _users = [];
  final List<Trip> _trips = [];
  final List<Destination> _destinations = [];
  final List<AppNotification> _notifications = [];
  final List<Review> _reviews = [];

  // Auto-increment counters
  int _userIdCounter = 1;
  int _tripIdCounter = 1;
  int _destinationIdCounter = 1;
  int _notificationIdCounter = 1;
  int _reviewIdCounter = 1;

  // User operations
  Future<int> insertUser(Users user) async {
    user.id = _userIdCounter++;
    _users.add(user);
    return user.id!;
  }

  Future<List<Users>> getUsers() async {
    return List.from(_users);
  }

  Future<Users?> getUserByEmail(String email) async {
    try {
      return _users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<Users?> authenticateUser(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user != null && user.login(password)) {
      return user;
    }
    return null;
  }

  // Trip operations
  Future<int> insertTrip(Trip trip) async {
    trip.id = _tripIdCounter++;
    _trips.add(trip);
    return trip.id!;
  }

  Future<List<Trip>> getTrips() async {
    return List.from(_trips);
  }

  Future<List<Trip>> getTripsByUser(int userId) async {
    return _trips.where((trip) => trip.userId == userId).toList();
  }

  Future<void> updateTrip(Trip trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
    }
  }

  Future<void> deleteTrip(int id) async {
    _trips.removeWhere((trip) => trip.id == id);
  }

  // Destination operations
  Future<int> insertDestination(Destination destination) async {
    destination.id = _destinationIdCounter++;
    _destinations.add(destination);
    return destination.id!;
  }

  Future<List<Destination>> getDestinations() async {
    return List.from(_destinations);
  }

  Future<List<Destination>> getDestinationsByTrip(int tripId) async {
    return _destinations.where((dest) => dest.tripId == tripId).toList();
  }

  // Notification operations
  Future<int> insertNotification(AppNotification notification) async {
    notification.id = _notificationIdCounter++;
    _notifications.add(notification);
    return notification.id!;
  }

  Future<List<AppNotification>> getNotifications() async {
    return List.from(_notifications);
  }

  Future<List<AppNotification>> getNotificationsByUser(int userId) async {
    return _notifications.where((notif) => notif.userId == userId).toList();
  }

  // Review operations
  Future<int> insertReview(Review review) async {
    review.id = _reviewIdCounter++;
    _reviews.add(review);
    return review.id!;
  }

  Future<List<Review>> getReviews() async {
    return List.from(_reviews);
  }

  Future<List<Review>> getReviewsByDestination(int destinationId) async {
    return _reviews
        .where((review) => review.destinationId == destinationId)
        .toList();
  }

  Future<void> updateReview(Review review) async {
    final index = _reviews.indexWhere((r) => r.id == review.id);
    if (index != -1) {
      _reviews[index] = review;
    }
  }

  // Clear all data (for testing)
  void clearAll() {
    _users.clear();
    _trips.clear();
    _destinations.clear();
    _notifications.clear();
    _reviews.clear();
    _userIdCounter = 1;
    _tripIdCounter = 1;
    _destinationIdCounter = 1;
    _notificationIdCounter = 1;
    _reviewIdCounter = 1;
  }
}
