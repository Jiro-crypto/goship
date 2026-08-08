import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = UserModel(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        avatar: "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
        gender: "Nam",
        city: "TP. Hồ Chí Minh",
      );

      final result = await AuthService.register(user);
      if (!mounted) return;

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký tài khoản thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thất bại. Vui lòng thử lại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.person_add_alt_1, size: 70, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'TẠO TÀI KHOẢN GOSHIP',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 24),
              // Họ tên
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ tên';
                  if (v.trim().length > 50) return 'Tên tối đa 50 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                  if (v.trim().length > 50) return 'Email tối đa 50 ký tự';
                  if (!v.contains('@') || !v.contains('.')) return 'Email phải chứa ký tự @ và đuôi hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // SĐT
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập SĐT';
                  if (!RegExp(r'^0\d{9}$').hasMatch(v.trim())) {
                    return 'SĐT phải bắt đầu bằng số 0 và đúng 10 chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Mật khẩu
              TextFormField(
                controller: _passwordController,
                obscureText: _hidePassword,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock, color: primaryColor),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  if (v.length > 30) return 'Mật khẩu tối đa 30 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Xác nhận mật khẩu
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _hideConfirmPassword,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_hideConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _hideConfirmPassword = !_hideConfirmPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                  if (v.length > 30) return 'Mật khẩu tối đa 30 ký tự';
                  if (v != _passwordController.text) return 'Mật khẩu không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ĐĂNG KÝ TÀI KHOẢN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đã có tài khoản? Quay lại đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
