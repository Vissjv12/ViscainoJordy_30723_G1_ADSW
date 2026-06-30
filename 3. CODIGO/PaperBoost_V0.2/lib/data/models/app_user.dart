class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.role,
  });

  final String id;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String role;

  AppUser copyWith({
    String? id,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    String? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'].toString(),
      email: map['email'].toString(),
      passwordHash: map['passwordHash'].toString(),
      passwordSalt: map['passwordSalt'].toString(),
      role: map['role'].toString(),
    );
  }

  @override
  String toString() {
    return 'AppUser('
        'id: $id, '
        'email: $email, '
        'role: $role'
        ')';
  }
}