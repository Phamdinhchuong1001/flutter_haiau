import 'package:cloud_functions/cloud_functions.dart';

class UserService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> registerUser({
    required String fullname,
    required String birthDate,
    required String email,
    required String password,
    required String position,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('registerUser');
      final response = await callable.call({
        'fullname': fullname.trim(),
        'birthDate': birthDate.trim(),
        'email': email.trim(),
        'password': password.trim(),
        'position': position.trim(),
      });

      return {
        'success': true,
        'message': response.data['message'] ?? 'Đăng ký thành công!',
        'role': response.data['role'],
      };
    } on FirebaseFunctionsException catch (e) {
      return {'success': false, 'message': e.message ?? 'Lỗi từ server.'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi không xác định: $e'};
    }
  }
}
