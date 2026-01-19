import 'package:flutter/material.dart';
import '../models/review.dart';
import '../models/destination.dart';
import '../services/database_helper.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _commentController = TextEditingController();
  List<Review> _reviews = [];
  List<Destination> _destinations = [];
  int _selectedRating = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final reviews = await _databaseHelper.getReviews();
    final destinations = await _databaseHelper.getDestinations();

    setState(() {
      _reviews = reviews;
      _destinations = destinations;
    });
  }

  void _addReview() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a comment')));
      return;
    }

    if (_destinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a destination first')),
      );
      return;
    }

    final targetDestination = _destinations.first;
    if (targetDestination.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destination is missing an identifier, try again'),
        ),
      );
      return;
    }

    // Create a review
    Review review = Review(
      comment: _commentController.text,
      rating: _selectedRating,
      destinationId: targetDestination.id,
    );

    // Call addPhoto method from Review class
    review.addPhoto();

    // Save to storage
    final reviewId = await _databaseHelper.insertReview(review);
    review.id = reviewId;

    _commentController.clear();
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review added successfully!')),
      );
    }
  }

  void _editReview(Review review) {
    // Call edit method from Review class
    review.edit();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: review.comment),
              decoration: const InputDecoration(labelText: 'Comment'),
              onChanged: (value) => review.comment = value,
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: review.rating,
              items: [1, 2, 3, 4, 5].map((rating) {
                return DropdownMenuItem(
                  value: rating,
                  child: Text('$rating Stars'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  review.rating = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _databaseHelper.updateReview(review);
              _loadData();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review updated successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Review Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Rating: '),
                        DropdownButton<int>(
                          value: _selectedRating,
                          items: [1, 2, 3, 4, 5].map((rating) {
                            return DropdownMenuItem(
                              value: rating,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...List.generate(
                                    rating,
                                    (index) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                  ),
                                  Text(' ($rating)'),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRating = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addReview,
                      child: const Text('Add Review'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Reviews List
            Expanded(
              child: _reviews.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('No reviews yet. Add your first review!'),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.rate_review),
                            title: Text(review.comment),
                            subtitle: Row(
                              children: [
                                ...List.generate(
                                  review.rating,
                                  (index) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                                Text(' (${review.rating}/5)'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editReview(review),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.photo_camera),
                                  onPressed: () => review.addPhoto(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
