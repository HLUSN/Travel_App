class Trip {
  String title;
  DateTime startDate;
  DateTime endDate;
  int? id; // for database operations
  int? userId; // foreign key reference to User

  Trip({
    this.id,
    this.userId,
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  // Methods as shown in UML diagram
  void addDestination() {
    // Implementation for adding destination to trip
    print('Adding destination to trip: $title');
    // Add actual destination adding logic here
  }

  void share() {
    // Implementation for sharing trip
    print('Sharing trip: $title');
    // Add actual sharing logic here
  }

  // Convert Trip to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  // Create Trip from Map (database result)
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      userId: map['userId'],
      title: map['title'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }

  @override
  String toString() {
    return 'Trip{id: $id, userId: $userId, title: $title, startDate: $startDate, endDate: $endDate}';
  }
}
