import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin/admin_home_screen.dart';
import 'shipper/shipper_home_screen.dart';
import 'customer_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Điền sẵn thông tin tài khoản demo Khách hàng
    emailController.text = "customer@goship.vn";
    passwordController.text = "password";
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    // Lấy thông tin người dùng nhập
    String inputEmail = emailController.text.trim();
    String inputPassword = passwordController.text.trim();

    // Giả lập logic kiểm tra Role (Sau này kết nối API/Firebase sẽ lấy từ Server)
    String? assignedRole;
    bool isSuccess = false;

    // Giả lập mật khẩu chung là "password" cho tất cả các Role để dễ test
    if (inputPassword == "password") {
      if (inputEmail == "customer@goship.vn") {
        assignedRole = "CUSTOMER";
        isSuccess = true;
      } else if (inputEmail == "admin@goship.vn") {
        assignedRole = "ADMIN";
        isSuccess = true;
      } else if (inputEmail == "shipper@goship.vn") {
        assignedRole = "SHIPPER";
        isSuccess = true;
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đăng nhập thành công! Đang chuyển hướng quyền $assignedRole..."),
          backgroundColor: Colors.green,
        ),
      );

      // ĐIỀU HƯỚNG DỰA TRÊN ROLE NGƯỜI DÙNG
      if (assignedRole == "ADMIN") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else if (assignedRole == "CUSTOMER") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      }  
      else if (assignedRole == "SHIPPER") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShipperHomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sai email hoặc mật khẩu! Vui lòng xem thông tin Demo bên dưới."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo GoShip Đặt hàng
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "GOSHIP",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    "Đặt hàng & Giao nhận siêu tốc",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Input
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email Khách hàng",
                      prefixIcon: Icon(Icons.email, color: primaryColor),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2.0),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Vui lòng nhập Email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: Icon(Icons.lock, color: primaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor, width: 2.0),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Vui lòng nhập mật khẩu";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Button Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "ĐĂNG NHẬP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  // Demo Account Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: primaryColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "Tài khoản Demo (Pass: password):",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text("• Điều phối viên: admin@goship.vn", style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text("• Khách hàng: customer@goship.vn"),
                        const Text("• Shipper: shipper@goship.vn"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Lớp phụ trợ nhanh để lưu trạng thái đăng nhập Khách hàng
class PreferenceServiceForClient {
  static const String clientLoginKey = "isClientLoggedIn";
  
  static Future<void> saveFakeSession() async {
    await AuthService.login(
      email: "customer@goship.vn",
      password: "password",
      rememberMe: true,
    );
  }
}
