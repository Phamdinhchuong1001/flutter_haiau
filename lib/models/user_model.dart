class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // admin, nhanvien, kythuatvien

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'nhanvien',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'role': role};
  }
}
