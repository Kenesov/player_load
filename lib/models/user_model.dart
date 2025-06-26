class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phoneNumber;
  final String? bio;
  final String? profilePicture;
  final DateTime? dateOfBirth;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.bio,
    this.profilePicture,
    this.dateOfBirth,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Ensure all required fields have safe defaults
    int id = 0;
    if (json['id'] != null) {
      if (json['id'] is int) {
        id = json['id'];
      } else {
        id = int.tryParse(json['id'].toString()) ?? 0;
      }
    }

    return User(
      id: id,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      bio: json['bio']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'phone_number': phoneNumber,
      'bio': bio,
      'profile_picture': profilePicture,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
    };
  }

  // Convenience getters
  bool get isAthlete => role == 'ATHLETE';
  bool get isCoach => role == 'COACH';
  bool get isAdmin => role == 'ADMIN';

  String get fullName => '$firstName $lastName';

  @override
  String toString() {
    return 'User{id: $id, username: $username, role: $role, fullName: $fullName}';
  }
}
