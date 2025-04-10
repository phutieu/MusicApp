import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t4/presentation/screen/register_screen.dart';
import 'package:t4/presentation/screen/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Kiểm tra nếu đã đăng nhập bằng Google
      final savedGoogleSignIn = prefs.getBool('googleSignIn') ?? false;
      if (savedGoogleSignIn) {
        // Kiểm tra nếu người dùng vẫn còn đăng nhập Firebase
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      }

      // Kiểm tra đăng nhập thông thường
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password');
      final savedRememberMe = prefs.getBool('rememberMe') ?? false;

      if (savedEmail != null && savedPassword != null && savedRememberMe) {
        setState(() {
          emailController.text = savedEmail;
          passwordController.text = savedPassword;
          _rememberMe = true;
        });

        // Tự động đăng nhập nếu có thông tin đã lưu
        await _login();
      }
    } catch (e) {
      print("Lỗi kiểm tra thông tin đăng nhập: ${e.toString()}");
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', emailController.text);
      await prefs.setString('password', passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorMessage("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _saveCredentials();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "Không tìm thấy tài khoản";
          break;
        case 'wrong-password':
          errorMessage = "Mật khẩu không đúng";
          break;
        case 'invalid-email':
          errorMessage = "Email không hợp lệ";
          break;
        case 'user-disabled':
          errorMessage = "Tài khoản đã bị vô hiệu hóa";
          break;
        default:
          errorMessage = e.message ?? "Đăng nhập thất bại";
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Đảm bảo đã khởi tạo GoogleSignIn
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Đăng xuất Google trước để tránh lỗi
      await googleSignIn.signOut();

      // Bắt đầu quá trình đăng nhập bằng Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Người dùng hủy đăng nhập
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Lấy thông tin xác thực từ Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập với Firebase bằng thông tin xác thực từ Google
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Lưu thông tin đăng nhập nếu chọn "Nhớ mật khẩu"
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('googleSignIn', true);
          await prefs.setBool('rememberMe', true);
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print("Lỗi đăng nhập Google: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập Google thất bại: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showErrorMessage("Vui lòng nhập email để đặt lại mật khẩu");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Đã gửi email đặt lại mật khẩu. Vui lòng kiểm tra hộp thư của bạn."),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "Không tìm thấy email trong hệ thống";
          break;
        case 'invalid-email':
          errorMessage = "Email không hợp lệ";
          break;
        default:
          errorMessage = e.message ?? "Không thể gửi email đặt lại mật khẩu";
      }
      _showErrorMessage(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    width: 170,
                    height: 170,
                  ),
                  const SizedBox(height: 60),

                  // Trường nhập email
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        hintText: "Nhập email",
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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

                  // Hàng chứa "Ghi nhớ đăng nhập" và "Quên mật khẩu"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Checkbox "Ghi nhớ đăng nhập"
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFF31C934),
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            "Ghi nhớ đăng nhập",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                      // Quên mật khẩu
                      TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          "Quên mật khẩu?",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Nút đăng nhập
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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
                              "Đăng nhập",
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
                      onPressed: _signInWithGoogle,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),

                  // Dòng chuyển đến đăng ký
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Bạn chưa có tài khoản?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: const Text(
                          "Đăng ký",
                          style: TextStyle(color: Color(0xFF1B7A10)),
                        ),
                      ),
                    ],
                  ),
                ],
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
