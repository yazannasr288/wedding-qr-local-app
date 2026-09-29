import 'package:flutter/material.dart';
import 'package:wedding_qr_local_app/features/invitations/qr_view_screen_clean.dart';

import '../../data/repositories/invitation_repository.dart';
import '../../shared/widgets/primary_action_button.dart';

class AddInvitationScreen extends StatefulWidget {
  const AddInvitationScreen({super.key});

  @override
  State<AddInvitationScreen> createState() => _AddInvitationScreenState();
}

class _AddInvitationScreenState extends State<AddInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  final InvitationRepository _repository = InvitationRepository();

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final invitation = await _repository.createInvitation(
        guestName: _nameController.text,
        allowedCount: int.parse(_countController.text),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: QrViewScreen(invitation: invitation),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء دعوة')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'اسم المدعو أو العائلة',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'أدخل اسمًا واضحًا.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد الأشخاص المسموح لهم',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  if (count == null || count <= 0 || count > 99) {
                    return 'أدخل عددًا صحيحًا بين 1 و 99.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PrimaryActionButton(
                label: _saving ? 'جارٍ الحفظ...' : 'إنشاء QR',
                icon: Icons.qr_code_2,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
