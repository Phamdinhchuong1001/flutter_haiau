import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  // Lấy danh sách người dùng
  Stream<List<UserModel>> getUsers() {
    return usersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Thêm người dùng
  Future<void> addUser(UserModel user) async {
    await usersRef.add(user.toMap());
  }

  // Cập nhật vai trò
  Future<void> updateUserRole(String id, String newRole) async {
    await usersRef.doc(id).update({'role': newRole});
  }

  // Xóa người dùng
  Future<void> deleteUser(String id) async {
    await usersRef.doc(id).delete();
  }
}
