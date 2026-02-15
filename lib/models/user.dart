class User {
  final int? id;
  final String username;
  final String password;
  final String userType; // 'เกษตรกร', 'Admin'
  final String fullName;
  final String createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.userType,
    required this.fullName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'username': username,
      'password': password,
      'user_type': userType,
      'full_name': fullName,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['user_id'],
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      userType: map['user_type'] ?? 'เกษตรกร',
      fullName: map['full_name'] ?? '',
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}
