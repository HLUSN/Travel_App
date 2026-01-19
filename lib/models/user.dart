class Users {
  int? id;
  String name;
  String email;
  String? password; // Store hashed password

  Users({this.id, required this.name, required this.email, this.password});

  // Methods as shown in UML diagram
  bool login(String inputPassword) {
    // Implementation for user login with password verification
    if (password != null && _verifyPassword(inputPassword, password!)) {
      print('User $name logged in successfully');
      return true;
    }
    print('Login failed for user $name');
    return false;
  }

  // Password hashing (simple implementation)
  static String _hashPassword(String password) {
    // Simple hash - in production use proper bcrypt or similar
    return password.hashCode.toString();
  }

  // Password verification
  static bool _verifyPassword(String inputPassword, String hashedPassword) {
    return _hashPassword(inputPassword) == hashedPassword;
  }

  // Set password (hashed)
  void setPassword(String rawPassword) {
    password = _hashPassword(rawPassword);
  }

  void savePreferences() {
    // Implementation for saving user preferences
    print('Saving preferences for user $name');
    // Add actual preference saving logic here
  }

  void createTrip() {
    // Implementation for creating a trip
    print('User $name is creating a trip');
    // Add actual trip creation logic here
  }

  // Convert User to Map for database operations
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email, 'password': password};
  }

  // Create User from Map (database result)
  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'],
    );
  }

  @override
  String toString() {
    return 'Users{id: $id, name: $name, email: $email}';
  }
}
