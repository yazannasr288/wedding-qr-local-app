import 'package:flutter/material.dart';

import '../../data/repositories/invitation_repository.dart';
import '../../shared/widgets/primary_action_button.dart';
import 'invitations_screen.dart';

class BulkCreateScreen extends StatefulWidget {
  const BulkCreateScreen({super.key});

  @override
  State<BulkCreateScreen> createState() => _BulkCreateScreenState();
}

class _BulkCreateScreenState extends State<BulkCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController(text: '10');
  final _prefixController = TextEditingController(text: 'دعوة');
  final _allowedCountController = TextEditingController(text: '1');
  final InvitationRepository _repository = InvitationRepository();

  bool _creating = false;

  @override
  void dispose() {
    _countController.dispose();
    _prefixController.dispose();
    _allowedCountController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _creating = true);
    try {
      await _repository.createBulkInvitations(
        count: int.parse(_countController.text),
        namePrefix: _prefixController.text.trim().isEmpty ? 'دعوة' : _prefixController.text.trim(),
        allowedCount: int.parse(_allowedCountController.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الدعوات بنجاح.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const Directionality(
            textDirection: TextDirection.rtl,
            child: InvitationsScreen(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء عدة دعوات')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد رموز QR المطلوبة',
                  prefixIcon: Icon(Icons.format_list_numbered_rtl),
                ),
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  if (count == null || count <= 0 || count > 1000) {
                    return 'أدخل عددًا صحيحًا بين 1 و 1000.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prefixController,
                decoration: const InputDecoration(
                  labelText: 'بادئة الاسم',
                  helperText: 'مثال: دعوة، عائلة، ضيف',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allowedCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد الأشخاص لكل دعوة',
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
                label: _creating ? 'جارٍ الإنشاء...' : 'إنشاء الدعوات',
                icon: Icons.add_card_outlined,
                onPressed: _creating ? null : _create,
              ),
              const SizedBox(height: 12),
              const Text('يمكنك تعديل أسماء الدعوات لاحقًا من القائمة إن احتجت لذلك.'),
            ],
          ),
        ),
      ),
    );
  }
}
