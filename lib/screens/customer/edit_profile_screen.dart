import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/vn_provinces.dart';
import '../../data/repositories/customer_repository.dart';
import '../../models/customer_model.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final CustomerModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const List<String> _genders = ['Nam', 'Nữ', 'Khác'];

  /// Giới hạn dung lượng ảnh avatar (sau nén) để lưu dạng base64 trong Firestore.
  /// Firestore giới hạn 1 MiB / document, nên giữ avatar nhỏ để không ảnh hưởng
  /// các trường khác và tốc độ tải hồ sơ.
  static const int _maxAvatarBytes = 200 * 1024;

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;

  String? _gender;
  String? _city;

  /// Ảnh mới chọn (chưa lưu). `null` = không thay đổi ảnh.
  Uint8List? _pickedAvatarBytes;

  /// Người dùng chọn xoá ảnh đại diện hiện tại.
  bool _removeAvatar = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    _addressController = TextEditingController(text: user.address);

    // Giá trị không hợp lệ (rỗng, 'Unknow', ...) -> null để bắt người dùng chọn lại,
    // tránh lỗi DropdownButtonFormField khi value không nằm trong danh sách items.
    _gender = _genders.contains(user.gender) ? user.gender : null;

    // Chuẩn hoá city cũ (vd: 'Bình Dương' -> 'TP. Hồ Chí Minh') về danh sách 34 tỉnh thành.
    _city = VnProvinces.normalize(user.city);
    _cityController = TextEditingController(text: _city ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _hasAvatar =>
      _pickedAvatarBytes != null || (!_removeAvatar && widget.user.avatar.isNotEmpty);

  // ---------------------------------------------------------------------------
  // Avatar
  // ---------------------------------------------------------------------------

  Future<void> _showAvatarOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.orange),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xoá ảnh đại diện', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'camera':
        await _pickAvatar(ImageSource.camera);
      case 'gallery':
        await _pickAvatar(ImageSource.gallery);
      case 'remove':
        setState(() {
          _pickedAvatarBytes = null;
          _removeAvatar = true;
        });
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      // Thu nhỏ + nén ngay khi chọn để ảnh chỉ còn vài chục KB.
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null) return; // Người dùng huỷ.

      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxAvatarBytes) {
        _showMessage('Ảnh quá lớn, vui lòng chọn ảnh khác.', isError: true);
        return;
      }

      if (!mounted) return;
      setState(() {
        _pickedAvatarBytes = bytes;
        _removeAvatar = false;
      });
    } on PlatformException catch (e) {
      _showMessage(
        e.code.contains('access_denied') || e.code.contains('permission')
            ? 'Ứng dụng chưa được cấp quyền truy cập camera / thư viện ảnh.'
            : 'Không thể mở ${source == ImageSource.camera ? 'camera' : 'thư viện ảnh'}.',
        isError: true,
      );
    } catch (_) {
      _showMessage('Không thể đọc ảnh đã chọn.', isError: true);
    }
  }

  // ---------------------------------------------------------------------------
  // City picker (có ô tìm kiếm)
  // ---------------------------------------------------------------------------

  Future<void> _pickCity() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CityPickerSheet(selected: _city),
    );

    if (selected != null && mounted) {
      setState(() {
        _city = selected;
        _cityController.text = selected;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'gender': _gender,
      'city': _city,
      'address': _addressController.text.trim(),
    };

    if (_pickedAvatarBytes != null) {
      data['avatar'] = UserAvatar.encode(_pickedAvatarBytes!);
    } else if (_removeAvatar) {
      data['avatar'] = '';
    }

    try {
      await CustomerRepository().updateCustomer(widget.user.uid, data);
      if (!mounted) return;
      _showMessage('Cập nhật thông tin thành công!');
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _showMessage('Lưu thất bại: ${e.message ?? e.code}', isError: true);
    } catch (e) {
      _showMessage('Lưu thất bại: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

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
              // --- Avatar ---
              GestureDetector(
                onTap: _isLoading ? null : _showAvatarOptions,
                child: Stack(
                  children: [
                    UserAvatar(
                      avatar: _removeAvatar ? '' : widget.user.avatar,
                      previewBytes: _pickedAvatarBytes,
                      name: _nameController.text,
                      radius: 50,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: primaryColor,
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Chạm để đổi ảnh đại diện', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 24),

              // --- Họ tên ---
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                textCapitalization: TextCapitalization.words,
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

              // --- SĐT ---
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

              // --- Giới tính ---
              DropdownButtonFormField<String>(
                initialValue: _gender,
                hint: const Text('Chọn giới tính'),
                decoration: const InputDecoration(
                  labelText: 'Giới tính',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                items: _genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _gender = val),
                validator: (v) => v == null ? 'Vui lòng chọn giới tính' : null,
              ),
              const SizedBox(height: 16),

              // --- Tỉnh / Thành phố ---
              TextFormField(
                controller: _cityController,
                readOnly: true,
                onTap: _isLoading ? null : _pickCity,
                decoration: const InputDecoration(
                  labelText: 'Tỉnh / Thành phố',
                  hintText: 'Chọn tỉnh / thành phố',
                  prefixIcon: Icon(Icons.location_city),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(),
                ),
                validator: (_) => _city == null ? 'Vui lòng chọn tỉnh / thành phố' : null,
              ),
              if (_city == null && widget.user.city.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Giá trị cũ "${widget.user.city}" không còn hợp lệ, vui lòng chọn lại.',
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // --- Địa chỉ ---
              TextFormField(
                controller: _addressController,
                maxLength: 200,
                maxLines: 2,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  hintText: 'Số nhà, tên đường, phường/xã',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập địa chỉ';
                  if (v.trim().length < 5) return 'Địa chỉ quá ngắn';
                  return null;
                },
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
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
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

/// Bottom sheet chọn tỉnh / thành phố có ô tìm kiếm (không phân biệt dấu).
class _CityPickerSheet extends StatefulWidget {
  final String? selected;

  const _CityPickerSheet({this.selected});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = VnProvinces.removeDiacritics(_query.trim());
    final items = q.isEmpty
        ? VnProvinces.all
        : VnProvinces.all.where((p) => VnProvinces.removeDiacritics(p).contains(q)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('Chọn tỉnh / thành phố', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm (vd: ho chi minh, da nang)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Không tìm thấy tỉnh / thành phố phù hợp'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final name = items[i];
                        final isSelected = name == widget.selected;
                        return ListTile(
                          title: Text(name),
                          trailing: isSelected ? Icon(Icons.check, color: Colors.orange.shade800) : null,
                          selected: isSelected,
                          selectedColor: Colors.orange.shade800,
                          onTap: () => Navigator.pop(context, name),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
