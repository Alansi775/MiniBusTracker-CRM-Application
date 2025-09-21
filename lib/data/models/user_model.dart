enum UserRole { superAdmin, admin, user, pending }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String surname;
  final String username;
  final UserRole role;
  final bool isBlocked;
  final bool mustChangePassword;
  final bool isApproved; // حقل الموافقة

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.surname,
    required this.username,
    required this.role,
    this.isBlocked = false,
    this.mustChangePassword = true,
    this.isApproved = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    UserRole parseRole(String roleString) {
      if (roleString == 'superAdmin') return UserRole.superAdmin;
      if (roleString == 'admin') return UserRole.admin;
      if (roleString == 'pending') return UserRole.pending;
      return UserRole.user;
    }

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      username: data['username'] ?? '',
      role: parseRole(data['role'] ?? 'pending'),
      isBlocked: data['isBlocked'] ?? false,
      mustChangePassword: data['mustChangePassword'] ?? true,
      isApproved: data['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'surname': surname,
      'username': username,
      'role': role.toString().split('.').last,
      'isBlocked': isBlocked,
      'mustChangePassword': mustChangePassword,
      'isApproved': isApproved,
    };
  }
}