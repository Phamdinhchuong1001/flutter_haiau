import 'package:flutter/material.dart';
import 'package:flutter_haiau/services/user_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers (thêm fullname, birthDate, position)
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu nhập lại không khớp')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 🟡 LOG: Data sắp gửi API
    debugPrint('====== 📤 SIGNUP REQUEST ======');
    debugPrint('Fullname: ${fullnameController.text.trim()}');
    debugPrint('BirthDate: ${birthDateController.text.trim()}');
    debugPrint('Position: ${positionController.text.trim()}');
    debugPrint('Email: ${emailController.text.trim()}');
    debugPrint('===============================');

    try {
      final result = await _userService.registerUser(
        fullname: fullnameController.text.trim(),
        birthDate: birthDateController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        position: positionController.text.trim(),
      );

      // 🟢 LOG: Kết quả API trả về
      debugPrint('====== ✅ SIGNUP RESPONSE ======');
      debugPrint(result.toString());
      debugPrint('================================');

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Đăng ký thành công!')),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        final msg = result?['message'] ?? 'Đăng ký thất bại. Vui lòng thử lại.';
        debugPrint('❌ SIGNUP FAILED: $msg');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      // 🔴 LOG: Lỗi khi gọi API
      debugPrint('====== 🔥 SIGNUP ERROR ======');
      debugPrint(e.toString());
      debugPrint('=============================');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi kết nối API')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    fullnameController.dispose();
    birthDateController.dispose();
    positionController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          return Row(
            children: [
              if (isWide)
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0xFF005BFF),
                    child: const Center(
                      child: Text(
                        "WELCOME",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 60,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('assets/logokonen.png', height: 90),
                          const SizedBox(height: 30),
                          const Center(
                            child: Text(
                              "Đăng ký",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Họ và tên
                                TextFormField(
                                  controller: fullnameController,
                                  decoration: InputDecoration(
                                    labelText: "Họ và tên",
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      228,
                                      238,
                                      255,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập họ và tên';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Ngày sinh
                                TextFormField(
                                  controller: birthDateController,
                                  decoration: InputDecoration(
                                    labelText: "Ngày sinh (YYYY-MM-DD)",
                                    hintText: "2000-01-30",
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      228,
                                      238,
                                      255,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập ngày sinh';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Chức vụ
                                TextFormField(
                                  controller: positionController,
                                  decoration: InputDecoration(
                                    labelText: "Chức vụ",
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      228,
                                      238,
                                      255,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập chức vụ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Email
                                TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      228,
                                      238,
                                      255,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Mật khẩu
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: "Mật khẩu",
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      228,
                                      238,
                                      255,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    if (value.length < 6) {
                                      return 'Mật khẩu ít nhất 6 ký tự';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Nhập lại mật khẩu
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: "Nhập lại mật khẩu",
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      228,
                                      238,
                                      255,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập lại mật khẩu';
                                    }
                                    if (value != passwordController.text) {
                                      return 'Mật khẩu không khớp';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Nút đăng ký
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              _signup();
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF005BFF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            "Đăng ký",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Đã có tài khoản? "),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Đăng nhập",
                                        style: TextStyle(
                                          color: Color(0xFF005BFF),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
