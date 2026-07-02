import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Subtle folded-corner accent on the top-right of note cards.
class PaperFoldCorner extends StatelessWidget {
  const PaperFoldCorner({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PaperFoldPainter(
          foldColor: AppTheme.foldShadow,
        ),
      ),
    );
  }
}

class _PaperFoldPainter extends CustomPainter {
  const _PaperFoldPainter({required this.foldColor});

  final Color foldColor;

  @override
  void paint(Canvas canvas, Size size) {
    final foldPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(
      foldPath,
      Paint()..color = foldColor,
    );

    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height * 0.55),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PaperFoldPainter oldDelegate) {
    return oldDelegate.foldColor != foldColor;
  }
}
