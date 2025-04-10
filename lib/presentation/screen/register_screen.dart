import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t4/presentation/screen/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Kiểm tra thông tin nhập vào
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorMessage("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (password.length < 6) {
      _showErrorMessage("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    if (!email.contains('@')) {
      _showErrorMessage("Email không hợp lệ");
      return;
    }

    try {
      // Tạo tài khoản
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật tên người dùng
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);

        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đăng ký thành công!")),
          );

          // Chuyển đến trang đăng nhập
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = "Mật khẩu quá yếu";
          break;
        case 'email-already-in-use':
          errorMessage = "Email đã được sử dụng";
          break;
        case 'invalid-email':
          errorMessage = "Email không hợp lệ";
          break;
        case 'operation-not-allowed':
          errorMessage = "Đăng ký không được phép";
          break;
        default:
          errorMessage = e.message ?? "Đăng ký thất bại";
      }
      _showErrorMessage(errorMessage);
    } catch (e) {
      _showErrorMessage("Có lỗi xảy ra: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Logo PKN
                    Column(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 150,
                          height: 150,
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // Trường nhập họ và tên
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: "Họ và tên",
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trường nhập email
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          hintText: "Email của bạn là gì",
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Trường nhập mật khẩu
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: "Mật khẩu",
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Nút đăng ký
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF31C934),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Đăng ký",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // Dòng phân cách "Hoặc"
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("Hoặc",
                                style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),

                    // Nút đăng nhập bằng Google
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextButton.icon(
                        icon: Image.asset(
                          'assets/logo_icon.png',
                          height: 24,
                        ),
                        label: const Text(
                          "Đăng nhập bằng Google",
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, "/login");
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),

                    // Dòng chuyển đến đăng nhập
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Bạn đã có tài khoản?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, "/login");
                          },
                          child: const Text(
                            "Đăng nhập",
                            style: TextStyle(color: Color(0xFF1B7A10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
