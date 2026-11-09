import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Hiển thị avatar người dùng từ giá trị lưu trong Firestore.
///
/// Hỗ trợ 2 định dạng:
///  - Data URI base64: `data:image/jpeg;base64,...` (dùng với gói Firebase Spark,
///    vì không có Cloud Storage).
///  - URL http(s) (dùng nếu sau này chuyển sang Storage / CDN).
///
/// Nếu [avatar] rỗng hoặc lỗi, hiển thị chữ cái đầu của [name] hoặc icon người.
class UserAvatar extends StatefulWidget {
  final String avatar;
  final String name;
  final double radius;

  /// Ảnh vừa chọn nhưng chưa lưu (ưu tiên hiển thị để xem trước).
  final Uint8List? previewBytes;

  const UserAvatar({
    super.key,
    required this.avatar,
    this.name = '',
    this.radius = 50,
    this.previewBytes,
  });

  static const String dataUriPrefix = 'data:image/jpeg;base64,';

  /// Chuyển bytes ảnh thành chuỗi để lưu vào trường `avatar`.
  static String encode(Uint8List bytes) => '$dataUriPrefix${base64Encode(bytes)}';

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  ImageProvider? _provider;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ decode lại khi dữ liệu thực sự thay đổi (tránh decode base64 mỗi lần build).
    if (oldWidget.avatar != widget.avatar || oldWidget.previewBytes != widget.previewBytes) {
      _resolve();
    }
  }

  void _resolve() {
    _hasError = false;
    _provider = null;

    if (widget.previewBytes != null) {
      _provider = MemoryImage(widget.previewBytes!);
      return;
    }

    final value = widget.avatar.trim();
    if (value.isEmpty) return;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      _provider = NetworkImage(value);
    } else if (value.startsWith('data:image')) {
      try {
        final base64Part = value.substring(value.indexOf(',') + 1);
        _provider = MemoryImage(base64Decode(base64Part));
      } catch (_) {
        _provider = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showImage = _provider != null && !_hasError;
    final initial = widget.name.trim().isNotEmpty ? widget.name.trim()[0].toUpperCase() : '';

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.orange.shade100,
      backgroundImage: showImage ? _provider : null,
      onBackgroundImageError: showImage
          ? (_, _) {
              if (mounted) setState(() => _hasError = true);
            }
          : null,
      child: showImage
          ? null
          : initial.isNotEmpty
              ? Text(
                  initial,
                  style: TextStyle(
                    fontSize: widget.radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                )
              : Icon(Icons.person, size: widget.radius, color: Colors.orange.shade800),
    );
  }
}
