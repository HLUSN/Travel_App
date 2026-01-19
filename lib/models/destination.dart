class Destination {
  String name;
  String type;
  double rating;
  int? id; // for database operations
  int? tripId; // foreign key reference to Trip

  Destination({
    this.id,
    this.tripId,
    required this.name,
    required this.type,
    required this.rating,
  });

  // Methods as shown in UML diagram
  List<Destination> search() {
    // Implementation for searching destinations
    print('Searching destinations...');
    // Add actual search logic here
    return [];
  }

  Map<String, dynamic> getDetails() {
    // Implementation for getting destination details
    print('Getting details for destination: $name');
    // Add actual details retrieval logic here
    return {'name': name, 'type': type, 'rating': rating};
  }

  // Convert Destination to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'name': name,
      'type': type,
      'rating': rating,
    };
  }

  // Create Destination from Map (database result)
  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      id: map['id'],
      tripId: map['tripId'],
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'Destination{id: $id, tripId: $tripId, name: $name, type: $type, rating: $rating}';
  }
}
