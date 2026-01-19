class Review {
  String comment;
  int rating;
  int? id; // for database operations
  int? destinationId; // foreign key reference to Destination

  Review({
    this.id,
    this.destinationId,
    required this.comment,
    required this.rating,
  });

  // Methods as shown in UML diagram
  void addPhoto() {
    // Implementation for adding photo to review
    print('Adding photo to review: $comment');
    // Add actual photo adding logic here
  }

  void edit() {
    // Implementation for editing review
    print('Editing review: $comment');
    // Add actual review editing logic here
  }

  // Convert Review to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destinationId': destinationId,
      'comment': comment,
      'rating': rating,
    };
  }

  // Create Review from Map (database result)
  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      destinationId: map['destinationId'],
      comment: map['comment'] ?? '',
      rating: map['rating'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Review{id: $id, destinationId: $destinationId, comment: $comment, rating: $rating}';
  }
}
