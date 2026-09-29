import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/models/invitation.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../shared/widgets/section_card.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final InvitationRepository _repository = InvitationRepository();
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _locked = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_locked) return;

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .firstOrNull;

    if (rawValue == null) return;

    setState(() => _locked = true);
    await _controller.stop();

    final validation = await _repository.validateRawQr(rawValue);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ScanResultSheet(
          result: validation,
          onConfirmEntry: validation.canEnter && validation.invitation != null
              ? () => _confirmEntry(validation.invitation!)
              : null,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _locked = false);
    await _controller.start();
  }

  Future<void> _confirmEntry(Invitation invitation) async {
    final result = await _repository.consumeInvitation(invitation);
    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فحص QR'),
        actions: [
          IconButton(
            tooltip: 'تشغيل/إيقاف الفلاش',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on_outlined),
          ),
          IconButton(
            tooltip: 'تبديل الكاميرا',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SectionCard(
                child: Text(
                  _locked ? 'تمت قراءة الرمز. راجع النتيجة.' : 'وجّه الكاميرا نحو رمز QR.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({
    required this.result,
    required this.onConfirmEntry,
  });

  final InvitationValidationResult result;
  final VoidCallback? onConfirmEntry;

  Color _color(BuildContext context) {
    return switch (result.state) {
      InvitationValidationState.valid => Colors.green,
      InvitationValidationState.used => Theme.of(context).colorScheme.error,
      InvitationValidationState.cancelled => Colors.orange,
      InvitationValidationState.invalid => Theme.of(context).colorScheme.error,
    };
  }

  IconData get _icon {
    return switch (result.state) {
      InvitationValidationState.valid => Icons.check_circle_outline,
      InvitationValidationState.used => Icons.block_outlined,
      InvitationValidationState.cancelled => Icons.warning_amber_outlined,
      InvitationValidationState.invalid => Icons.error_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final invitation = result.invitation;
    final color = _color(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(_icon, color: color, size: 54),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            if (invitation != null) ...[
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invitation.guestName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('عدد الأشخاص المسموح لهم: ${invitation.allowedCount}'),
                    const SizedBox(height: 8),
                    Text('الحالة: ${invitation.status.label}'),
                    if (invitation.usedAt != null) ...[
                      const SizedBox(height: 8),
                      Text('استخدمت بتاريخ: ${_formatDate(invitation.usedAt!)}'),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (onConfirmEntry != null)
              FilledButton.icon(
                onPressed: onConfirmEntry,
                icon: const Icon(Icons.login_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('تأكيد الدخول'),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('فحص رمز آخر'),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
