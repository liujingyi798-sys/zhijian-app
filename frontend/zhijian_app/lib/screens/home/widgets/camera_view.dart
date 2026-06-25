import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';

class CameraView extends StatelessWidget {
  final String photoType;
  final void Function(Uint8List bytes, String fileName) onCapture;

  const CameraView({
    Key? key,
    required this.photoType,
    required this.onCapture,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ZhiJianTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择拍照方式',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ZhiJianTheme.text)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _OptionTile(icon: Icons.camera_alt, label: '相机拍摄',
                      onTap: () => Navigator.pop(ctx, ImageSource.camera)),
                  _OptionTile(icon: Icons.photo_library, label: '相册选择',
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final xfile = await picker.pickImage(source: source, imageQuality: 90, maxWidth: 1920);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      onCapture(bytes, xfile.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final angleLabels = {'front': '正面照', 'side': '侧面照', 'back': '背面照'};
    final angleGuides = {
      'front': '面对镜头，双臂自然下垂，双脚与肩同宽',
      'side': '侧身对镜头，自然站立，手臂不遮挡躯干',
      'back': '背对镜头，双臂自然下垂，保持与正面相同站位',
    };

    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: ZhiJianTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZhiJianTheme.primary.withOpacity(0.3), width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: CustomPaint(size: const Size(220, 300), painter: _BodyOutlinePainter()),
            ),
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Column(children: [
                Text(angleLabels[photoType] ?? '拍摄',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ZhiJianTheme.text)),
                const SizedBox(height: 6),
                Text(angleGuides[photoType] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: ZhiJianTheme.textSecondary)),
                const SizedBox(height: 12),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, border: Border.all(color: ZhiJianTheme.primary, width: 3)),
                  child: Center(
                    child: Container(
                      width: 50, height: 50,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: ZhiJianTheme.primary),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ZhiJianTheme.primary.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(size.width / 2, 35), 25, paint);
    canvas.drawLine(Offset(size.width / 2, 60), Offset(size.width / 2, 75), paint);
    canvas.drawLine(Offset(size.width * 0.15, 85), Offset(size.width * 0.85, 85), paint);
    final torsoPath = Path()
      ..moveTo(size.width * 0.15, 85)
      ..lineTo(size.width * 0.1, 200)
      ..lineTo(size.width * 0.9, 200)
      ..lineTo(size.width * 0.85, 85)
      ..close();
    canvas.drawPath(torsoPath, paint);
    canvas.drawLine(Offset(size.width * 0.15, 85), Offset(size.width * 0.05, 200), paint);
    canvas.drawLine(Offset(size.width * 0.85, 85), Offset(size.width * 0.95, 200), paint);
    canvas.drawLine(Offset(size.width * 0.1, 200), Offset(size.width * 0.05, 290), paint);
    canvas.drawLine(Offset(size.width * 0.9, 200), Offset(size.width * 0.95, 290), paint);
    canvas.drawLine(Offset(size.width * 0.1, 200), Offset(size.width * 0.35, 290), paint);
    canvas.drawLine(Offset(size.width * 0.9, 200), Offset(size.width * 0.65, 290), paint);

    final textPainter = TextPainter(
      text: TextSpan(text: '请对齐轮廓', style: TextStyle(color: ZhiJianTheme.primary.withOpacity(0.4), fontSize: 12)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: ZhiJianTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZhiJianTheme.textSecondary.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, size: 36, color: ZhiJianTheme.primary),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: ZhiJianTheme.text, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
