/// Danh sách 34 đơn vị hành chính cấp tỉnh của Việt Nam
/// (áp dụng từ 01/07/2025 theo Nghị quyết 202/2025/QH15).
class VnProvinces {
  VnProvinces._();

  /// 6 thành phố trực thuộc trung ương.
  static const List<String> cities = [
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Hải Phòng',
    'Đà Nẵng',
    'Huế',
    'Cần Thơ',
  ];

  /// 28 tỉnh (sắp xếp theo bảng chữ cái).
  static const List<String> provinces = [
    'An Giang',
    'Bắc Ninh',
    'Cà Mau',
    'Cao Bằng',
    'Đắk Lắk',
    'Điện Biên',
    'Đồng Nai',
    'Đồng Tháp',
    'Gia Lai',
    'Hà Tĩnh',
    'Hưng Yên',
    'Khánh Hòa',
    'Lai Châu',
    'Lâm Đồng',
    'Lạng Sơn',
    'Lào Cai',
    'Nghệ An',
    'Ninh Bình',
    'Phú Thọ',
    'Quảng Ngãi',
    'Quảng Ninh',
    'Quảng Trị',
    'Sơn La',
    'Tây Ninh',
    'Thái Nguyên',
    'Thanh Hóa',
    'Tuyên Quang',
    'Vĩnh Long',
  ];

  /// Toàn bộ 34 đơn vị: thành phố trực thuộc TW đứng trước, sau đó là các tỉnh.
  static const List<String> all = [...cities, ...provinces];

  /// Tên cũ / cách viết khác -> tên đơn vị hiện hành.
  /// Dùng để chuyển đổi dữ liệu city đã lưu trước khi sáp nhập.
  static const Map<String, String> _aliases = {
    // Cách viết khác
    'hồ chí minh': 'TP. Hồ Chí Minh',
    'tp hồ chí minh': 'TP. Hồ Chí Minh',
    'tp.hồ chí minh': 'TP. Hồ Chí Minh',
    'thành phố hồ chí minh': 'TP. Hồ Chí Minh',
    'tp.hcm': 'TP. Hồ Chí Minh',
    'tp hcm': 'TP. Hồ Chí Minh',
    'hcm': 'TP. Hồ Chí Minh',
    'sài gòn': 'TP. Hồ Chí Minh',
    'thừa thiên huế': 'Huế',
    'thừa thiên - huế': 'Huế',
    'thanh hoá': 'Thanh Hóa',
    'khánh hoà': 'Khánh Hòa',
    // Các tỉnh cũ đã sáp nhập
    'hà giang': 'Tuyên Quang',
    'yên bái': 'Lào Cai',
    'bắc kạn': 'Thái Nguyên',
    'vĩnh phúc': 'Phú Thọ',
    'hòa bình': 'Phú Thọ',
    'hoà bình': 'Phú Thọ',
    'bắc giang': 'Bắc Ninh',
    'thái bình': 'Hưng Yên',
    'hải dương': 'Hải Phòng',
    'hà nam': 'Ninh Bình',
    'nam định': 'Ninh Bình',
    'quảng bình': 'Quảng Trị',
    'quảng nam': 'Đà Nẵng',
    'kon tum': 'Quảng Ngãi',
    'bình định': 'Gia Lai',
    'ninh thuận': 'Khánh Hòa',
    'đắk nông': 'Lâm Đồng',
    'bình thuận': 'Lâm Đồng',
    'phú yên': 'Đắk Lắk',
    'bình dương': 'TP. Hồ Chí Minh',
    'bà rịa - vũng tàu': 'TP. Hồ Chí Minh',
    'bà rịa vũng tàu': 'TP. Hồ Chí Minh',
    'bình phước': 'Đồng Nai',
    'long an': 'Tây Ninh',
    'sóc trăng': 'Cần Thơ',
    'hậu giang': 'Cần Thơ',
    'bến tre': 'Vĩnh Long',
    'trà vinh': 'Vĩnh Long',
    'tiền giang': 'Đồng Tháp',
    'bạc liêu': 'Cà Mau',
    'kiên giang': 'An Giang',
  };

  /// Chuẩn hoá giá trị city bất kỳ về một phần tử trong [all].
  /// Trả về `null` nếu không nhận diện được (ví dụ: '', 'Unknow').
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (all.contains(value)) return value;

    final key = value.toLowerCase().replaceFirst(RegExp(r'^tỉnh\s+'), '');
    for (final name in all) {
      if (name.toLowerCase() == key) return name;
    }
    return _aliases[key];
  }

  static const _accented = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const _plain = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

  /// Chuyển về chữ thường không dấu, dùng cho tìm kiếm (vd: 'Đà Nẵng' -> 'da nang').
  static String removeDiacritics(String input) {
    final buffer = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      final i = _accented.indexOf(ch);
      buffer.write(i >= 0 ? _plain[i] : ch);
    }
    return buffer.toString();
  }
}
