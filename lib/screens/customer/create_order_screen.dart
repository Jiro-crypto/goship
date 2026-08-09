import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/order_model.dart';
import '../../services/geocoding_service.dart';
import '../../services/preference_service.dart';
import 'payment_qr_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nguoiNhanController = TextEditingController();
  final _sdtNguoiNhanController = TextEditingController();
  final _diaChiLayController = TextEditingController();
  final _diaChiGiaoController = TextEditingController();
  final _danhMucController = TextEditingController();
  final _khoiLuongController = TextEditingController();
  final _soLuongController = TextEditingController(text: '1');
  final _tienCODController = TextEditingController(text: '0');
  final _ghiChuController = TextEditingController();

  double _phiShip = 0;
  double _latLay = 0, _lngLay = 0;
  double _latGiao = 0, _lngGiao = 0;
  bool _isLoading = false;
  bool _isGeocodingLay = false;
  bool _isGeocodingGiao = false;

  @override
  void dispose() {
    _nguoiNhanController.dispose();
    _sdtNguoiNhanController.dispose();
    _diaChiLayController.dispose();
    _diaChiGiaoController.dispose();
    _danhMucController.dispose();
    _khoiLuongController.dispose();
    _soLuongController.dispose();
    _tienCODController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  void _calculateShippingFee() {
    double km = 1.0;
    if (_latLay != 0 && _lngLay != 0 && _latGiao != 0 && _lngGiao != 0) {
      double distanceInMeters = Geolocator.distanceBetween(_latLay, _lngLay, _latGiao, _lngGiao);
      km = distanceInMeters / 1000;
      if (km < 1.0) km = 1.0;
    }
    double khoiLuong = double.tryParse(_khoiLuongController.text) ?? 1.0;
    int soLuong = int.tryParse(_soLuongController.text) ?? 1;
    if (soLuong < 1) soLuong = 1;

    // Fee formula: 15,000đ base + 5,000đ/km + 2,000đ/kg + 5,000đ per extra quantity
    _phiShip = 15000 + (km * 5000) + (khoiLuong * 2000) + ((soLuong - 1) * 5000);
    setState(() {});
  }

  void _geocodeAddress(String address, {required bool isLay}) async {
    if (address.trim().length <= 5) return;

    setState(() {
      if (isLay) {
        _isGeocodingLay = true;
      } else {
        _isGeocodingGiao = true;
      }
    });

    final result = await GeocodingService.geocodeAddress(address);

    if (!mounted) return;

    if (result != null) {
      if (isLay) {
        _latLay = result['lat']!;
        _lngLay = result['lng']!;
      } else {
        _latGiao = result['lat']!;
        _lngGiao = result['lng']!;
      }
      _calculateShippingFee();
    }

    setState(() {
      if (isLay) {
        _isGeocodingLay = false;
      } else {
        _isGeocodingGiao = false;
      }
    });
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin bắt buộc (MSG10)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_latLay == 0 || _lngLay == 0) {
      _latLay = 10.7719;
      _lngLay = 106.7038;
    }
    if (_latGiao == 0 || _lngGiao == 0) {
      _latGiao = 10.7905;
      _lngGiao = 106.6775;
    }

    final newOrderId = 'GS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final currentUser = await PreferenceService.getUser();
    final userMaKH = (currentUser?.email.isNotEmpty == true)
        ? currentUser!.email.trim()
        : (currentUser?.phone.isNotEmpty == true ? currentUser!.phone.trim() : 'KH-001');

    final order = OrderModel(
      orderId: newOrderId,
      maKH: userMaKH,
      senderName: currentUser?.fullName.isNotEmpty == true ? currentUser!.fullName : 'Khách hàng',
      senderPhone: currentUser?.phone.isNotEmpty == true ? currentUser!.phone : '0987654321',
      tenNguoiNhan: _nguoiNhanController.text.trim(),
      sdtNguoiNhan: _sdtNguoiNhanController.text.trim(),
      diaChiLay: _diaChiLayController.text.trim(),
      latLay: _latLay,
      lngLay: _lngLay,
      diaChiGiao: _diaChiGiaoController.text.trim(),
      latGiao: _latGiao,
      lngGiao: _lngGiao,
      khoiLuong: double.tryParse(_khoiLuongController.text) ?? 1.0,
      ghiChu: _ghiChuController.text.trim(),
      tienCOD: double.tryParse(_tienCODController.text.trim()) ?? 0.0,
      phiShip: _phiShip > 0 ? _phiShip : 25000.0,
      trangThaiDon: 'Chờ phân công',
      thoiGianTao: DateTime.now(),
      danhMucHang: _danhMucController.text.trim().isNotEmpty ? _danhMucController.text.trim() : 'Hàng hóa chung',
      soLuong: int.tryParse(_soLuongController.text) ?? 1,
    );

    // Chuyển sang màn hình Thanh toán Chuyển khoản QR với đếm ngược 15 giây
    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentQRScreen(order: order),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt đơn vận chuyển', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // === Nhóm 1: Thông tin người nhận ===
              _buildSectionHeader('1. Thông tin người nhận & Địa chỉ'),
              TextFormField(
                controller: _nguoiNhanController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Tên người nhận *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên người nhận';
                  if (v.trim().length > 50) return 'Tên tối đa 50 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sdtNguoiNhanController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'SĐT người nhận *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập SĐT';
                  if (!RegExp(r'^0\d{9}$').hasMatch(v.trim())) return 'SĐT phải bắt đầu bằng số 0 và đúng 10 chữ số';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diaChiLayController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ lấy hàng *',
                  prefixIcon: const Icon(Icons.storefront),
                  counterText: '',
                  suffixIcon: _isGeocodingLay
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.pin_drop, color: Colors.blue),
                          onPressed: () => _geocodeAddress(_diaChiLayController.text, isLay: true),
                        ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập địa chỉ lấy hàng';
                  if (v.trim().length > 100) return 'Địa chỉ tối đa 100 ký tự';
                  return null;
                },
                onChanged: (v) {
                  if (v.length > 5) _geocodeAddress(v, isLay: true);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diaChiGiaoController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ giao hàng *',
                  prefixIcon: const Icon(Icons.location_on),
                  counterText: '',
                  suffixIcon: _isGeocodingGiao
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.pin_drop, color: Colors.red),
                          onPressed: () => _geocodeAddress(_diaChiGiaoController.text, isLay: false),
                        ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập địa chỉ giao hàng';
                  if (v.trim().length > 100) return 'Địa chỉ tối đa 100 ký tự';
                  if (v.trim().toLowerCase() == _diaChiLayController.text.trim().toLowerCase()) {
                    return 'Địa chỉ giao không được trùng địa chỉ lấy';
                  }
                  return null;
                },
                onChanged: (v) {
                  if (v.length > 5) _geocodeAddress(v, isLay: false);
                },
              ),

              // === Nhóm 2: Thông tin hàng hóa ===
              _buildSectionHeader('2. Thông tin hàng hóa'),
              TextFormField(
                controller: _danhMucController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Danh mục hàng',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _khoiLuongController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Trọng lượng (kg) *',
                        prefixIcon: Icon(Icons.scale),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nhập trọng lượng';
                        final d = double.tryParse(v.trim());
                        if (d == null || d <= 0) return 'Phải > 0 kg';
                        return null;
                      },
                      onChanged: (_) => _calculateShippingFee(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _soLuongController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        prefixIcon: Icon(Icons.format_list_numbered),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return 'Phải > 0';
                        }
                        return null;
                      },
                      onChanged: (_) => _calculateShippingFee(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tienCODController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 9,
                decoration: const InputDecoration(
                  labelText: 'Tiền thu hộ COD (đ)',
                  prefixIcon: Icon(Icons.monetization_on, color: Colors.green),
                  border: OutlineInputBorder(),
                  counterText: '',
                  hintText: 'Nhập tiền hàng nhờ Shipper thu hộ (nếu có)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ghiChuController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú cho Shipper',
                  prefixIcon: Icon(Icons.note_alt),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  counterText: '',
                ),
              ),

              // === Nhóm 3: Phương thức thanh toán ===
              _buildSectionHeader('3. Phương thức thanh toán'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance, color: Colors.blue.shade800, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chuyển khoản Ngân hàng',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Thanh toán chuyển khoản qua tài khoản ngân hàng',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: primaryColor, size: 22),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Hiển thị phí ship
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tiền thu COD ước tính:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '${_phiShip.toStringAsFixed(0)} đ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('XÁC NHẬN ĐẶT ĐƠN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
