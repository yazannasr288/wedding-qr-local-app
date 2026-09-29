import 'package:flutter/material.dart';

import '../../data/models/invitation.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../shared/widgets/primary_action_button.dart';
import '../../shared/widgets/section_card.dart';
import '../invitations/add_invitation_screen.dart';
import '../invitations/bulk_create_screen.dart';
import '../invitations/invitations_screen.dart';
import '../scanner/scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final InvitationRepository _repository = InvitationRepository();
  late Future<InvitationStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    _statsFuture = _repository.getStats();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: screen,
        ),
      ),
    );
    if (!mounted) return;
    setState(_loadStats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('زواجي')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(_loadStats),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              FutureBuilder<InvitationStats>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? const InvitationStats(total: 0, unused: 0, used: 0, cancelled: 0);
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _StatCard(label: 'الإجمالي', value: stats.total, icon: Icons.confirmation_number_outlined),
                      _StatCard(label: 'المتبقي', value: stats.unused, icon: Icons.event_available_outlined),
                      _StatCard(label: 'المستخدمة', value: stats.used, icon: Icons.check_circle_outline),
                      _StatCard(label: 'الملغاة', value: stats.cancelled, icon: Icons.cancel_outlined),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  children: [
                    PrimaryActionButton(
                      label: 'فحص دعوة QR',
                      icon: Icons.qr_code_scanner,
                      onPressed: () => _open(const ScannerScreen()),
                    ),
                    const SizedBox(height: 10),
                    PrimaryActionButton(
                      label: 'قائمة الدعوات',
                      icon: Icons.list_alt_outlined,
                      onPressed: () => _open(const InvitationsScreen()),
                    ),
                    const SizedBox(height: 10),
                    PrimaryActionButton(
                      label: 'إنشاء دعوة واحدة',
                      icon: Icons.person_add_alt_1_outlined,
                      onPressed: () => _open(const AddInvitationScreen()),
                    ),
                    const SizedBox(height: 10),
                    PrimaryActionButton(
                      label: 'إنشاء عدة دعوات',
                      icon: Icons.playlist_add_outlined,
                      onPressed: () => _open(const BulkCreateScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    );
  }
}
