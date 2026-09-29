import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/qr_payload_codec.dart';
import '../local/app_database.dart';
import '../models/invitation.dart';

class InvitationValidationResult {
  const InvitationValidationResult({
    required this.state,
    required this.message,
    this.invitation,
  });

  final InvitationValidationState state;
  final String message;
  final Invitation? invitation;

  bool get canEnter => state == InvitationValidationState.valid;
}

enum InvitationValidationState {
  valid,
  used,
  cancelled,
  invalid,
}

class ConsumeInvitationResult {
  const ConsumeInvitationResult({
    required this.success,
    required this.message,
    this.invitation,
  });

  final bool success;
  final String message;
  final Invitation? invitation;
}

class InvitationRepository {
  InvitationRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<Invitation> createInvitation({
    required String guestName,
    required int allowedCount,
  }) async {
    final db = await _database.database;
    final invitation = Invitation(
      id: _uuid.v4(),
      guestName: guestName.trim(),
      allowedCount: allowedCount,
      token: _uuid.v4(),
      status: InvitationStatus.unused,
      createdAt: DateTime.now(),
    );

    await db.insert(
      'invitations',
      invitation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return invitation;
  }

  Future<List<Invitation>> createBulkInvitations({
    required int count,
    String namePrefix = 'دعوة',
    int allowedCount = 1,
  }) async {
    final db = await _database.database;
    final createdAt = DateTime.now();
    final invitations = List.generate(count, (index) {
      final number = index + 1;
      return Invitation(
        id: _uuid.v4(),
        guestName: '$namePrefix $number',
        allowedCount: allowedCount,
        token: _uuid.v4(),
        status: InvitationStatus.unused,
        createdAt: createdAt,
      );
    });

    await db.transaction((txn) async {
      for (final invitation in invitations) {
        await txn.insert(
          'invitations',
          invitation.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });

    return invitations;
  }

  Future<List<Invitation>> getInvitations({String? query}) async {
    final db = await _database.database;
    final trimmedQuery = query?.trim();
    final maps = await db.query(
      'invitations',
      where: trimmedQuery == null || trimmedQuery.isEmpty ? null : 'guest_name LIKE ?',
      whereArgs: trimmedQuery == null || trimmedQuery.isEmpty ? null : ['%$trimmedQuery%'],
      orderBy: 'created_at DESC',
    );
    return maps.map(Invitation.fromMap).toList(growable: false);
  }

  Future<Invitation?> getInvitationById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'invitations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Invitation.fromMap(rows.first);
  }

  Future<InvitationStats> getStats() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = 'unused' THEN 1 ELSE 0 END) AS unused,
        SUM(CASE WHEN status = 'used' THEN 1 ELSE 0 END) AS used,
        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled
      FROM invitations
    ''');

    final row = rows.first;
    return InvitationStats(
      total: (row['total'] as int?) ?? 0,
      unused: (row['unused'] as int?) ?? 0,
      used: (row['used'] as int?) ?? 0,
      cancelled: (row['cancelled'] as int?) ?? 0,
    );
  }

  Future<InvitationValidationResult> validateRawQr(String rawValue) async {
    final payload = QrPayloadCodec.tryDecode(rawValue);
    if (payload == null) {
      return const InvitationValidationResult(
        state: InvitationValidationState.invalid,
        message: 'رمز QR غير مفهوم أو لا يخص هذا التطبيق.',
      );
    }

    if (!payload.isForThisApp || !payload.isSupportedVersion || !payload.isForThisEvent) {
      return const InvitationValidationResult(
        state: InvitationValidationState.invalid,
        message: 'رمز QR غير تابع لهذا الحفل.',
      );
    }

    final db = await _database.database;

    // التنسيق المختصر الجديد يحتوي على token فقط لتقليل كثافة QR.
    // رموز JSON القديمة ما زالت تُفحص بواسطة id + token.
    final rows = payload.invitationId == null
        ? await db.query(
            'invitations',
            where: 'token = ?',
            whereArgs: [payload.token],
            limit: 1,
          )
        : await db.query(
            'invitations',
            where: 'id = ? AND token = ?',
            whereArgs: [payload.invitationId, payload.token],
            limit: 1,
          );

    if (rows.isEmpty) {
      return const InvitationValidationResult(
        state: InvitationValidationState.invalid,
        message: 'هذه الدعوة غير موجودة في قاعدة بيانات هذا الجهاز.',
      );
    }

    final invitation = Invitation.fromMap(rows.first);
    return switch (invitation.status) {
      InvitationStatus.unused => InvitationValidationResult(
          state: InvitationValidationState.valid,
          message: 'الدعوة صحيحة وغير مستخدمة.',
          invitation: invitation,
        ),
      InvitationStatus.used => InvitationValidationResult(
          state: InvitationValidationState.used,
          message: 'هذه الدعوة مستخدمة مسبقًا.',
          invitation: invitation,
        ),
      InvitationStatus.cancelled => InvitationValidationResult(
          state: InvitationValidationState.cancelled,
          message: 'هذه الدعوة ملغاة.',
          invitation: invitation,
        ),
    };
  }

  Future<ConsumeInvitationResult> consumeInvitation(Invitation invitation) async {
    final db = await _database.database;
    final now = DateTime.now();

    return db.transaction((txn) async {
      final rowsAffected = await txn.update(
        'invitations',
        {
          'status': InvitationStatus.used.dbValue,
          'used_at': now.toIso8601String(),
        },
        where: 'id = ? AND token = ? AND status = ?',
        whereArgs: [invitation.id, invitation.token, InvitationStatus.unused.dbValue],
      );

      if (rowsAffected == 1) {
        final updated = invitation.copyWith(status: InvitationStatus.used, usedAt: now);
        await _insertScanLog(
          txn,
          invitationId: updated.id,
          result: 'accepted',
          message: 'تم تأكيد الدخول.',
        );
        return ConsumeInvitationResult(
          success: true,
          message: 'تم تأكيد الدخول بنجاح.',
          invitation: updated,
        );
      }

      final latestRows = await txn.query(
        'invitations',
        where: 'id = ?',
        whereArgs: [invitation.id],
        limit: 1,
      );

      final latest = latestRows.isEmpty ? null : Invitation.fromMap(latestRows.first);
      final message = latest == null
          ? 'الدعوة لم تعد موجودة.'
          : latest.status == InvitationStatus.used
              ? 'الدعوة مستخدمة مسبقًا.'
              : latest.status == InvitationStatus.cancelled
                  ? 'الدعوة ملغاة.'
                  : 'تعذر تأكيد الدخول. أعد المحاولة.';

      await _insertScanLog(
        txn,
        invitationId: latest?.id,
        result: 'rejected',
        message: message,
      );

      return ConsumeInvitationResult(
        success: false,
        message: message,
        invitation: latest,
      );
    });
  }


  Future<void> updateInvitationDetails({
    required String id,
    required String guestName,
    required int allowedCount,
  }) async {
    final db = await _database.database;
    await db.update(
      'invitations',
      {
        'guest_name': guestName.trim(),
        'allowed_count': allowedCount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cancelInvitation(String id) async {
    final db = await _database.database;
    await db.update(
      'invitations',
      {'status': InvitationStatus.cancelled.dbValue},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> resetInvitationToUnused(String id) async {
    final db = await _database.database;
    await db.update(
      'invitations',
      {
        'status': InvitationStatus.unused.dbValue,
        'used_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteInvitation(String id) async {
    final db = await _database.database;
    await db.delete('invitations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _insertScanLog(
    Transaction txn, {
    required String? invitationId,
    required String result,
    required String message,
  }) async {
    await txn.insert('scan_logs', {
      'invitation_id': invitationId,
      'result': result,
      'message': message,
      'scanned_at': DateTime.now().toIso8601String(),
    });
  }
}
