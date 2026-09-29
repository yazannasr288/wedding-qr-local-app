import 'package:flutter/material.dart';

import '../../data/models/invitation.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../shared/widgets/primary_action_button.dart';

class EditInvitationScreen extends StatefulWidget {
  const EditInvitationScreen({super.key, required this.invitation});

  final Invitation invitation;

  @override
  State<EditInvitationScreen> createState() => _EditInvitationScreenState();
}

class _EditInvitationScreenState extends State<EditInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _countController;
  final InvitationRepository _repository = InvitationRepository();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.invitation.guestName);
    _countController = TextEditingController(text: widget.invitation.allowedCount.toString());
  }

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
      await _repository.updateInvitationDetails(
        id: widget.invitation.id,
        guestName: _nameController.text,
        allowedCount: int.parse(_countController.text),
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الدعوة')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المدعو أو العائلة',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) return 'أدخل اسمًا واضحًا.';
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
                  if (count == null || count <= 0 || count > 99) return 'أدخل عددًا صحيحًا بين 1 و 99.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PrimaryActionButton(
                label: _saving ? 'جارٍ الحفظ...' : 'حفظ التعديل',
                icon: Icons.save_outlined,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
