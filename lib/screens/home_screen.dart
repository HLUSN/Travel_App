import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../models/trip.dart';
import '../models/destination.dart';
import '../models/notification.dart';
import '../services/database_helper.dart';
import '../services/user_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Trip> _trips = [];
  List<Destination> _destinations = [];
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _checkUserSession();
    _loadData();
  }

  void _checkUserSession() {
    if (!UserSession.instance.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    }
  }

  void _loadData() async {
    final currentUserId = UserSession.instance.currentUserId;
    if (currentUserId == null) {
      print('ERROR: No current user ID in _loadData');
      return;
    }

    try {
      print('Loading data for user $currentUserId...');
      final trips = await _databaseHelper.getTripsByUser(currentUserId);
      print('Loaded ${trips.length} trips from database');

      final allDestinations = await _databaseHelper.getDestinations();
      print(
        'Loaded ${allDestinations.length} total destinations from database',
      );

      final userTripIds = trips.map((trip) => trip.id).whereType<int>().toSet();
      final destinations = allDestinations
          .where(
            (destination) =>
                destination.tripId != null &&
                userTripIds.contains(destination.tripId),
          )
          .toList();
      print('Filtered to ${destinations.length} destinations for user trips');

      final notifications = await _databaseHelper.getNotificationsByUser(
        currentUserId,
      );
      print('Loaded ${notifications.length} notifications from database');

      setState(() {
        _trips = trips;
        _destinations = destinations;
        _notifications = notifications;
      });
    } catch (e, stackTrace) {
      print('ERROR loading data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _createTrip() async {
    final currentUserId = UserSession.instance.currentUserId;
    if (currentUserId == null) {
      print('ERROR: No current user ID');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _TripFormDialog(),
    );

    if (result != null) {
      try {
        // Create trip with user input
        Trip trip = Trip(
          userId: currentUserId,
          title: result['title'],
          startDate: result['startDate'],
          endDate: result['endDate'],
        );

        print('Creating trip: ${trip.title} for user $currentUserId');

        // Call addDestination method from Trip class
        trip.addDestination();

        // Call share method from Trip class
        trip.share();

        // Save to storage
        final tripId = await _databaseHelper.insertTrip(trip);
        trip.id = tripId;
        print('Trip saved to database with ID: $tripId');

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trip "${trip.title}" created successfully!'),
            ),
          );
        }
      } catch (e, stackTrace) {
        print('ERROR creating trip: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating trip: $e')));
        }
      }
    }
  }

  void _addDestination() async {
    if (_trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a trip first!')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DestinationFormDialog(trips: _trips),
    );

    if (result != null) {
      try {
        // Create destination with user input
        Destination destination = Destination(
          name: result['name'],
          type: result['type'],
          rating: result['rating'],
          tripId: result['tripId'],
        );

        print(
          'Adding destination: ${destination.name} to trip ${destination.tripId}',
        );

        // Call search method from Destination class
        destination.search();

        // Call getDetails method from Destination class
        destination.getDetails();

        // Save to storage
        final destinationId = await _databaseHelper.insertDestination(
          destination,
        );
        destination.id = destinationId;
        print('Destination saved to database with ID: $destinationId');

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Destination "${destination.name}" added successfully!',
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        print('ERROR adding destination: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding destination: $e')),
          );
        }
      }
    }
  }

  void _sendNotification() async {
    final currentUserId = UserSession.instance.currentUserId;
    if (currentUserId == null) {
      print('ERROR: No current user ID');
      return;
    }

    if (_trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a trip first!')),
      );
      return;
    }

    try {
      // Find the trip with the earliest start date
      Trip upcomingTrip = _trips.reduce(
        (a, b) => a.startDate.isBefore(b.startDate) ? a : b,
      );

      String message;
      if (upcomingTrip.startDate.isAfter(DateTime.now())) {
        final daysUntilTrip = upcomingTrip.startDate
            .difference(DateTime.now())
            .inDays;
        if (daysUntilTrip == 0) {
          message = 'Your trip "${upcomingTrip.title}" starts today!';
        } else if (daysUntilTrip == 1) {
          message = 'Your trip "${upcomingTrip.title}" starts tomorrow!';
        } else {
          message =
              'Your trip "${upcomingTrip.title}" starts in $daysUntilTrip days on ${upcomingTrip.startDate.day}/${upcomingTrip.startDate.month}/${upcomingTrip.startDate.year}';
        }
      } else {
        message =
            'Your trip "${upcomingTrip.title}" started on ${upcomingTrip.startDate.day}/${upcomingTrip.startDate.month}/${upcomingTrip.startDate.year}';
      }

      // Create notification with trip details
      AppNotification notification = AppNotification(
        message: message,
        type: 'trip_reminder',
        userId: currentUserId,
      );

      print('Creating notification for user $currentUserId: $message');

      // Call send method from AppNotification class
      notification.send();

      // Save to storage
      final notificationId = await _databaseHelper.insertNotification(
        notification,
      );
      notification.id = notificationId;
      print('Notification saved to database with ID: $notificationId');

      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!')),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR sending notification: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Animated App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Welcome, ${UserSession.instance.currentUserName ?? 'User'}!',
                                textStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                speed: const Duration(milliseconds: 100),
                              ),
                            ],
                            totalRepeatCount: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        UserSession.instance.logout();
                        Navigator.pushReplacementNamed(context, '/');
                      },
                    ),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action Buttons with Animations
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildActionButton(
                                            context,
                                            'Create Trip',
                                            Icons.add_circle_outline,
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            _createTrip,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildActionButton(
                                            context,
                                            'Add Destination',
                                            Icons.place_outlined,
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                            _addDestination,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildActionButton(
                                      context,
                                      'Send Notification',
                                      Icons.notifications_outlined,
                                      Colors.orange,
                                      _sendNotification,
                                      fullWidth: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      // Trips Section
                      _buildSectionHeader('My Trips', Icons.travel_explore),
                      const SizedBox(height: 16),
                      _trips.isEmpty
                          ? _buildEmptyState(
                              'No trips yet',
                              'Create your first amazing trip!',
                              Icons.travel_explore,
                            )
                          : _buildAnimatedList(_trips, _buildTripCard),

                      const SizedBox(height: 30),

                      // Destinations Section
                      _buildSectionHeader('Destinations', Icons.place),
                      const SizedBox(height: 16),
                      _destinations.isEmpty
                          ? _buildEmptyState(
                              'No destinations yet',
                              'Add some beautiful destinations!',
                              Icons.place,
                            )
                          : _buildAnimatedList(
                              _destinations,
                              _buildDestinationCard,
                            ),

                      const SizedBox(height: 30),

                      // Notifications Section
                      const SizedBox(height: 16),
                      _notifications.isEmpty
                          ? _buildEmptyState(
                              'No notifications yet',
                              'Stay tuned for updates!',
                              Icons.notifications,
                            )
                          : _buildAnimatedList(
                              _notifications,
                              _buildNotificationCard,
                            ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/reviews'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.rate_review, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(-20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Colors.grey[50]!, Colors.grey[100]!],
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editTrip(Trip trip) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _TripFormDialog(trip: trip),
    );

    if (result != null) {
      try {
        trip.title = result['title'];
        trip.startDate = result['startDate'];
        trip.endDate = result['endDate'];

        await _databaseHelper.updateTrip(trip);
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Trip "${trip.title}" updated!')),
          );
        }
      } catch (e) {
        print('Error updating trip: $e');
      }
    }
  }

  void _deleteTrip(Trip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Are you sure you want to delete "${trip.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseHelper.deleteTrip(trip.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Trip deleted')));
      }
    }
  }

  void _editDestination(Destination destination) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _DestinationFormDialog(trips: _trips, destination: destination),
    );

    if (result != null) {
      try {
        destination.name = result['name'];
        destination.type = result['type'];
        destination.rating = result['rating'];
        destination.tripId = result['tripId'];

        await _databaseHelper.updateDestination(destination);
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Destination "${destination.name}" updated!'),
            ),
          );
        }
      } catch (e) {
        print('Error updating destination: $e');
      }
    }
  }

  void _deleteDestination(Destination destination) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Destination'),
        content: Text('Are you sure you want to delete "${destination.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseHelper.deleteDestination(destination.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Destination deleted')));
      }
    }
  }

  Widget _buildAnimatedList<T>(List<T> items, Widget Function(T, int) builder) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: builder(items[index], index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTripCard(Trip trip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Future: Navigate to trip details
          },
          child: Column(
            children: [
              Stack(
                children: [
                  // Image
                  Hero(
                    tag: 'trip_image_${trip.id}',
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://picsum.photos/seed/${trip.id}/800/400',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Actions Menu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'edit') _editTrip(trip);
                          if (value == 'delete') _deleteTrip(trip);
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Edit'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                      ),
                    ),
                  ),
                  // Title and Date
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3.0,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.access_time,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.endDate.difference(trip.startDate).inDays + 1} Days',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Action Buttons Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      onPressed: () => trip.share(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(Destination destination, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Stack(
              children: [
                // Image
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://picsum.photos/seed/dest${destination.id}/800/400',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions Menu
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') _editDestination(destination);
                        if (value == 'delete') _deleteDestination(destination);
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                    ),
                  ),
                ),
                // Content
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            destination.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  destination.rating.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.category,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            destination.type,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Bottom Action Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => destination.getDetails(),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.orange.withOpacity(0.05)],
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
            title: Text(
              notification.message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Type: ${notification.type}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripFormDialog extends StatefulWidget {
  final Trip? trip;

  const _TripFormDialog({this.trip});

  @override
  State<_TripFormDialog> createState() => _TripFormDialogState();
}

class _TripFormDialogState extends State<_TripFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _titleController.text = widget.trip!.title;
      _startDate = widget.trip!.startDate;
      _endDate = widget.trip!.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _saveTripData() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'title': _titleController.text,
        'startDate': _startDate,
        'endDate': _endDate,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.trip == null ? 'Create New Trip' : 'Edit Trip'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Trip Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.travel_explore),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a trip name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Start Date'),
                  subtitle: Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                  ),
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(height: 8),

              // End Date
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('End Date'),
                  subtitle: Text(
                    '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                  ),
                  onTap: _selectEndDate,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Duration: ${_endDate.difference(_startDate).inDays + 1} days',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTripData,
          child: Text(widget.trip == null ? 'Create Trip' : 'Save Changes'),
        ),
      ],
    );
  }
}

class _DestinationFormDialog extends StatefulWidget {
  final List<Trip> trips;
  final Destination? destination;

  const _DestinationFormDialog({required this.trips, this.destination});

  @override
  State<_DestinationFormDialog> createState() => _DestinationFormDialogState();
}

class _DestinationFormDialogState extends State<_DestinationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  double _rating = 4.0;
  Trip? _selectedTrip;

  @override
  void initState() {
    super.initState();
    if (widget.destination != null) {
      _nameController.text = widget.destination!.name;
      _typeController.text = widget.destination!.type;
      _rating = widget.destination!.rating;
      try {
        _selectedTrip = widget.trips.firstWhere(
          (t) => t.id == widget.destination!.tripId,
        );
      } catch (e) {
        if (widget.trips.isNotEmpty) {
          _selectedTrip = widget.trips.first;
        }
      }
    } else if (widget.trips.isNotEmpty) {
      _selectedTrip = widget.trips.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  void _saveDestinationData() {
    if (_formKey.currentState!.validate() && _selectedTrip != null) {
      Navigator.pop(context, {
        'name': _nameController.text,
        'type': _typeController.text,
        'rating': _rating,
        'tripId': _selectedTrip!.id,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.destination == null ? 'Add Destination' : 'Edit Destination',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Destination Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a destination name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Type (e.g., Beach, Mountain, City)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter destination type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Trip Selection
              DropdownButtonFormField<Trip>(
                initialValue: _selectedTrip,
                decoration: const InputDecoration(
                  labelText: 'Select Trip',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.travel_explore),
                ),
                items: widget.trips.map((trip) {
                  return DropdownMenuItem<Trip>(
                    value: trip,
                    child: Text(trip.title),
                  );
                }).toList(),
                onChanged: (Trip? value) {
                  setState(() {
                    _selectedTrip = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a trip';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rating Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rating: ${_rating.toStringAsFixed(1)} stars'),
                  Slider(
                    value: _rating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 8,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _rating.floor()
                            ? Icons.star
                            : (index < _rating
                                  ? Icons.star_half
                                  : Icons.star_border),
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveDestinationData,
          child: Text(
            widget.destination == null ? 'Add Destination' : 'Save Changes',
          ),
        ),
      ],
    );
  }
}
