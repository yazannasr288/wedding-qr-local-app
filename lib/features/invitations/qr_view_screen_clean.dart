import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/qr_payload_codec.dart';
import '../../data/models/invitation.dart';

class QrViewScreen extends StatelessWidget {
  const QrViewScreen({super.key, required this.invitation});

  final Invitation invitation;

  /// ضع الصورة المرفقة في هذا المسار داخل المشروع.
  static const String _backgroundAsset =
      'assets/1.png';

  /// أبعاد الصورة الأصلية المرفقة: 608 × 1080.
  static const double _designWidth = 608;
  static const double _designHeight = 1080;

  @override
  Widget build(BuildContext context) {
    final qrData = QrPayloadCodec.encode(invitation);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: _designWidth,
            height: _designHeight,
            child: Stack(
              children: [
                // التصميم بالكامل موجود داخل الصورة فقط.
                Positioned.fill(
                  child: Image.asset(
                    _backgroundAsset,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),

                // اسم المدعو فوق السطر المخصص له في الصورة.
                Positioned(
                  left: 254,
                  top: 792,
                  width: 145,
                  height: 38,
                  child: _SingleLineValue(
                    value: invitation.guestName,
                    fontSize: 18,
                  ),
                ),

                // عدد المدعوين فوق السطر المخصص له في الصورة.
                Positioned(
                  left: 100,
                  top: 790,
                  width: 112,
                  height: 38,
                  child: _SingleLineValue(
                    value: invitation.allowedCount.toString(),
                    fontSize: 18,
                  ),
                ),

                // رمز الدخول داخل المربع الفارغ الموجود في الصورة.
                Positioned(
                  left: 240,
                  top: 852,
                  width: 122,
                  height: 122,
                  child: Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      color: Colors.white,
                      padding: const EdgeInsets.all(2),
                      child: QrImageView(
                        size: 150,
                        data: qrData,
                        version: QrVersions.auto,
                        padding: EdgeInsets.zero,
                        backgroundColor: Color(0xfff2e5d5),
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        gapless: true,

                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SingleLineValue extends StatelessWidget {
  const _SingleLineValue({
    required this.value,
    required this.fontSize,
  });

  final String value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value.trim(),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          style: TextStyle(
            color: const Color(0xFF5C4630),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
