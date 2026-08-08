import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/preference_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late String _gender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _cityController = TextEditingController(text: widget.user.city.isNotEmpty ? widget.user.city : "TP. Hồ Chí Minh");
    _gender = widget.user.gender.isNotEmpty ? widget.user.gender : "Nam";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedUser = UserModel(
      fullName: _nameController.text.trim(),
      email: widget.user.email,
      phone: _phoneController.text.trim(),
      password: widget.user.password,
      avatar: widget.user.avatar,
      gender: _gender,
      city: _cityController.text.trim(),
    );

    await PreferenceService.updateUser(updatedUser);

    if (!mounted) return;

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật thông tin thành công!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ tên';
                  if (v.trim().length > 50) return 'Tên tối đa 50 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
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
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Giới tính',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                  DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onChanged: (val) => setState(() => _gender = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Tỉnh / Thành phố',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LƯU THAY ĐỔI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
