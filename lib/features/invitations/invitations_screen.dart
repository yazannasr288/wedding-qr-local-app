import 'package:flutter/material.dart';
import 'package:wedding_qr_local_app/features/invitations/qr_view_screen_clean.dart';

import '../../data/models/invitation.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../shared/widgets/section_card.dart';
import 'edit_invitation_screen.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final InvitationRepository _repository = InvitationRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Invitation>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    _future = _repository.getInvitations(query: _searchController.text);
  }

  void _refresh() {
    setState(_load);
  }

  Future<void> _openQr(Invitation invitation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: QrViewScreen(invitation: invitation),
        ),
      ),
    );
  }

  Future<void> _openEdit(Invitation invitation) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: EditInvitationScreen(invitation: invitation),
        ),
      ),
    );
    if (changed == true) _refresh();
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('تأكيد')),
        ],
      ),
    );

    if (confirmed != true) return;
    await action();
    if (!mounted) return;
    _refresh();
  }

  Color _statusColor(InvitationStatus status, BuildContext context) {
    return switch (status) {
      InvitationStatus.unused => Colors.green,
      InvitationStatus.used => Colors.blueGrey,
      InvitationStatus.cancelled => Theme.of(context).colorScheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قائمة الدعوات')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'بحث بالاسم',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => _refresh(),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Invitation>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final invitations = snapshot.data ?? const <Invitation>[];
                  if (invitations.isEmpty) {
                    return const Center(child: Text('لا توجد دعوات بعد.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: invitations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final invitation = invitations[index];
                      return SectionCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(invitation.guestName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('عدد الأشخاص: ${invitation.allowedCount}'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.circle, size: 10, color: _statusColor(invitation.status, context)),
                                    const SizedBox(width: 6),
                                    Text(invitation.status.label),
                                  ],
                                ),
                                if (invitation.usedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text('وقت الاستخدام: ${_formatDate(invitation.usedAt!)}'),
                                ],
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'qr':
                                  await _openQr(invitation);
                                  break;
                                case 'edit':
                                  await _openEdit(invitation);
                                  break;
                                case 'cancel':
                                  await _confirmAction(
                                    title: 'إلغاء الدعوة',
                                    message: 'هل تريد إلغاء هذه الدعوة؟',
                                    action: () => _repository.cancelInvitation(invitation.id),
                                  );
                                  break;
                                case 'reset':
                                  await _confirmAction(
                                    title: 'إعادة الدعوة كغير مستخدمة',
                                    message: 'استخدم هذا الخيار فقط عند حدوث خطأ مؤكد في تأكيد الدخول.',
                                    action: () => _repository.resetInvitationToUnused(invitation.id),
                                  );
                                  break;
                                case 'delete':
                                  await _confirmAction(
                                    title: 'حذف الدعوة',
                                    message: 'سيتم حذف هذه الدعوة نهائيًا من هذا الجهاز.',
                                    action: () => _repository.deleteInvitation(invitation.id),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'qr', child: Text('عرض QR')),
                              PopupMenuItem(value: 'edit', child: Text('تعديل الاسم والعدد')),
                              PopupMenuItem(value: 'cancel', child: Text('إلغاء الدعوة')),
                              PopupMenuItem(value: 'reset', child: Text('إعادة كغير مستخدمة')),
                              PopupMenuItem(value: 'delete', child: Text('حذف')),
                            ],
                          ),
                          onTap: () => _openQr(invitation),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }
}
