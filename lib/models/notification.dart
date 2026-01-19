class AppNotification {
  String message;
  String type;
  int? id; // for database operations
  int? userId; // foreign key reference to User

  AppNotification({
    this.id,
    this.userId,
    required this.message,
    required this.type,
  });

  // Method as shown in UML diagram
  void send() {
    // Implementation for sending notification
    print('Sending notification: $message');
    // Add actual notification sending logic here
  }

  // Convert AppNotification to Map for database operations
  Map<String, dynamic> toMap() {
    return {'id': id, 'userId': userId, 'message': message, 'type': type};
  }

  // Create AppNotification from Map (database result)
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      userId: map['userId'] == null
          ? null
          : (map['userId'] is int
                ? map['userId'] as int
                : int.tryParse(map['userId'].toString())),
      message: map['message'] ?? '',
      type: map['type'] ?? '',
    );
  }

  @override
  String toString() {
    return 'AppNotification{id: $id, userId: $userId, message: $message, type: $type}';
  }
}
