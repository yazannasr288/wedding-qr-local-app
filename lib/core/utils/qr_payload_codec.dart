import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/invitation.dart';
import '../constants/app_constants.dart';

class QrPayload {
  const QrPayload({
    required this.appKey,
    required this.version,
    required this.eventId,
    required this.token,
    this.invitationId,
  });

  final String appKey;
  final int version;
  final String eventId;

  /// موجود فقط في تنسيق JSON القديم.
  /// التنسيق المختصر الجديد يعتمد على token وحده لتقليل كثافة رمز QR.
  final String? invitationId;
  final String token;

  bool get isForThisApp => appKey == AppConstants.appKey;
  bool get isSupportedVersion => version == AppConstants.qrVersion;
  bool get isForThisEvent => eventId == AppConstants.eventId;
}

class QrPayloadCodec {
  QrPayloadCodec._();

  /// بادئة قصيرة تميز رمز التطبيق وإصدار التنسيق.
  static const String _compactPrefix = 'W1.';

  /// يحول UUID المكون من 36 محرفًا إلى 22 محرفًا Base64 URL-safe.
  /// الناتج الكامل يكون عادة 25 محرفًا فقط بدل JSON يتجاوز 150 محرفًا.
  static String encode(Invitation invitation) {
    final compactToken = _uuidToBase64Url(invitation.token);

    // جميع الرموز المنشأة من InvitationRepository هي UUID v4.
    // هذا الاحتياط يحافظ على عمل التطبيق إذا وُجد token قديم غير قياسي.
    if (compactToken != null) {
      return '$_compactPrefix$compactToken';
    }

    return jsonEncode({
      'app': AppConstants.appKey,
      'v': AppConstants.qrVersion,
      'eventId': AppConstants.eventId,
      'id': invitation.id,
      'token': invitation.token,
    });
  }

  static QrPayload? tryDecode(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return null;

    final compactPayload = _tryDecodeCompact(value);
    if (compactPayload != null) return compactPayload;

    // دعم رموز JSON القديمة المطبوعة مسبقًا.
    return _tryDecodeLegacyJson(value);
  }

  static QrPayload? _tryDecodeCompact(String value) {
    if (!value.startsWith(_compactPrefix)) return null;

    final encodedToken = value.substring(_compactPrefix.length);
    final token = _base64UrlToUuid(encodedToken);
    if (token == null) return null;

    return QrPayload(
      appKey: AppConstants.appKey,
      version: AppConstants.qrVersion,
      eventId: AppConstants.eventId,
      token: token,
    );
  }

  static QrPayload? _tryDecodeLegacyJson(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;

      final appKey = decoded['app'];
      final version = decoded['v'];
      final eventId = decoded['eventId'];
      final invitationId = decoded['id'];
      final token = decoded['token'];

      if (appKey is! String ||
          version is! int ||
          eventId is! String ||
          invitationId is! String ||
          token is! String) {
        return null;
      }

      if (appKey.trim().isEmpty ||
          eventId.trim().isEmpty ||
          invitationId.trim().isEmpty ||
          token.trim().isEmpty) {
        return null;
      }

      return QrPayload(
        appKey: appKey,
        version: version,
        eventId: eventId,
        invitationId: invitationId,
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _uuidToBase64Url(String uuid) {
    final hex = uuid.replaceAll('-', '').toLowerCase();
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(hex)) return null;

    final bytes = Uint8List(16);
    for (var index = 0; index < bytes.length; index++) {
      bytes[index] = int.parse(
        hex.substring(index * 2, index * 2 + 2),
        radix: 16,
      );
    }

    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String? _base64UrlToUuid(String encoded) {
    // UUID من 16 بايت ينتج 22 محرفًا بعد حذف ==.
    if (encoded.length != 22 ||
        !RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(encoded)) {
      return null;
    }

    try {
      final padded = '$encoded==';
      final bytes = base64Url.decode(padded);
      if (bytes.length != 16) return null;

      final hex = bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

      return '${hex.substring(0, 8)}-'
          '${hex.substring(8, 12)}-'
          '${hex.substring(12, 16)}-'
          '${hex.substring(16, 20)}-'
          '${hex.substring(20, 32)}';
    } catch (_) {
      return null;
    }
  }
}
