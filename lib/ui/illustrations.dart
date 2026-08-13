import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

const _artSize = Size(240, 210);

class ScanArt extends StatefulWidget {
  const ScanArt({super.key});

  @override
  State<ScanArt> createState() => _ScanArtState();
}

class _ScanArtState extends State<ScanArt> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        size: _artSize,
        painter: _ScanPainter(colors, _controller.value),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.colors, this.progress);

  final AppColors colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final page = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 118,
      height: 152,
    );
    final rounded = RRect.fromRectAndRadius(page, const Radius.circular(10));

    canvas.drawRRect(
      rounded.shift(const Offset(0, 6)),
      Paint()
        ..color = colors.ink.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(rounded, Paint()..color = colors.surface);
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colors.hairline,
    );

    final line = Paint()
      ..color = colors.muted.withValues(alpha: 0.35)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < 6; index++) {
      final y = page.top + 26 + index * 20;
      final width = index.isEven ? 74.0 : 56.0;
      canvas.drawLine(Offset(page.left + 22, y), Offset(page.left + 22 + width, y), line);
    }

    final sweep = Curves.easeInOut.transform((math.sin(progress * math.pi * 2) + 1) / 2);
    final scanY = page.top + 14 + (page.height - 28) * sweep;

    canvas.drawRect(
      Rect.fromLTRB(page.left, scanY - 26, page.right, scanY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.accent.withValues(alpha: 0), colors.accent.withValues(alpha: 0.20)],
        ).createShader(Rect.fromLTRB(page.left, scanY - 26, page.right, scanY)),
    );
    canvas.drawLine(
      Offset(page.left + 4, scanY),
      Offset(page.right - 4, scanY),
      Paint()
        ..color = colors.accent
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..color = colors.accent;

    final frame = page.inflate(20);
    const arm = 24.0;

    for (final corner in [
      (frame.topLeft, 1.0, 1.0),
      (frame.topRight, -1.0, 1.0),
      (frame.bottomLeft, 1.0, -1.0),
      (frame.bottomRight, -1.0, -1.0),
    ]) {
      final (point, dx, dy) = corner;
      canvas.drawLine(point, point.translate(arm * dx, 0), bracket);
      canvas.drawLine(point, point.translate(0, arm * dy), bracket);
    }
  }

  @override
  bool shouldRepaint(_ScanPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

class StackArt extends StatelessWidget {
  const StackArt({super.key});

  @override
  Widget build(BuildContext context) {
    return _Settling(
      builder: (progress) => CustomPaint(
        size: _artSize,
        painter: _StackPainter(AppTheme.of(context), progress),
      ),
    );
  }
}

class _StackPainter extends CustomPainter {
  _StackPainter(this.colors, this.progress);

  final AppColors colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2 - 4);
    final sheets = [
      (16.0, colors.accent.withValues(alpha: 0.32), 34.0),
      (8.0, colors.accent.withValues(alpha: 0.55), 18.0),
      (0.0, colors.surface, 0.0),
    ];

    for (final sheet in sheets) {
      final (angle, colour, travel) = sheet;
      final settled = 1 - progress;

      canvas.save();
      canvas.translate(centre.dx, centre.dy + 60);
      canvas.rotate((angle * progress) * math.pi / 180);
      canvas.translate(-centre.dx, -centre.dy - 60 + travel * settled);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centre, width: 112, height: 146),
        const Radius.circular(11),
      );

      canvas.drawRRect(
        rect.shift(const Offset(0, 5)),
        Paint()
          ..color = colors.ink.withValues(alpha: 0.10 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawRRect(rect, Paint()..color = colour);

      if (colour == colors.surface) {
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = colors.hairline,
        );

        final line = Paint()
          ..color = colors.muted.withValues(alpha: 0.30)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;

        for (var index = 0; index < 5; index++) {
          final y = rect.top + 28 + index * 22;
          canvas.drawLine(
            Offset(rect.left + 20, y),
            Offset(rect.left + 20 + (index.isEven ? 70 : 48), y),
            line,
          );
        }
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StackPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

class ConvertArt extends StatelessWidget {
  const ConvertArt({super.key});

  @override
  Widget build(BuildContext context) {
    return _Settling(
      builder: (progress) => CustomPaint(
        size: _artSize,
        painter: _ConvertPainter(AppTheme.of(context), progress),
      ),
    );
  }
}

class _ConvertPainter extends CustomPainter {
  _ConvertPainter(this.colors, this.progress);

  final AppColors colors;
  final double progress;

  static const _chips = ['JPG', 'DOCX', 'PPTX', 'TXT'];

  @override
  void paint(Canvas canvas, Size size) {
    final page = Rect.fromLTWH(14, size.height / 2 - 66, 96, 132);
    final rounded = RRect.fromRectAndRadius(page, const Radius.circular(10));

    canvas.drawRRect(
      rounded.shift(const Offset(0, 5)),
      Paint()
        ..color = colors.ink.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(rounded, Paint()..color = colors.surface);
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colors.hairline,
    );
    _label(canvas, 'PDF', Offset(page.center.dx, page.center.dy), colors.accent, 15, true);

    final arrowStart = Offset(page.right + 14, size.height / 2);
    final arrowEnd = Offset(page.right + 44, size.height / 2);
    final arrow = Paint()
      ..color = colors.muted
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(arrowStart, arrowEnd, arrow);
    canvas.drawLine(arrowEnd, arrowEnd.translate(-7, -6), arrow);
    canvas.drawLine(arrowEnd, arrowEnd.translate(-7, 6), arrow);

    for (var index = 0; index < _chips.length; index++) {
      final appear = ((progress - index * 0.14) / 0.5).clamp(0.0, 1.0);
      if (appear == 0) continue;

      final eased = Curves.easeOutBack.transform(appear);
      final y = size.height / 2 - 60 + index * 34.0;
      final chip = RRect.fromRectAndRadius(
        Rect.fromLTWH(arrowEnd.dx + 16 + (1 - eased) * 12, y, 62, 26),
        const Radius.circular(8),
      );

      canvas.save();
      canvas.translate(chip.center.dx, chip.center.dy);
      canvas.scale(0.7 + 0.3 * eased);
      canvas.translate(-chip.center.dx, -chip.center.dy);

      canvas.drawRRect(chip, Paint()..color = colors.accent.withValues(alpha: 0.12 * appear));
      _label(
        canvas,
        _chips[index],
        chip.outerRect.center,
        colors.accent.withValues(alpha: appear),
        12,
        true,
      );
      canvas.restore();
    }
  }

  void _label(Canvas canvas, String text, Offset centre, Color colour, double size, bool bold) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: colour,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, centre - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_ConvertPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

class PrivacyArt extends StatelessWidget {
  const PrivacyArt({super.key});

  @override
  Widget build(BuildContext context) {
    return _Settling(
      builder: (progress) => CustomPaint(
        size: _artSize,
        painter: _PrivacyPainter(AppTheme.of(context), progress),
      ),
    );
  }
}

class _PrivacyPainter extends CustomPainter {
  _PrivacyPainter(this.colors, this.progress);

  final AppColors colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);

    for (var ring = 0; ring < 3; ring++) {
      final radius = 58.0 + ring * 22;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = colors.accent.withValues(alpha: 0.16 * progress * (1 - ring * 0.28)),
      );
    }

    final phone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: centre, width: 92, height: 150),
      const Radius.circular(16),
    );

    canvas.drawRRect(
      phone.shift(const Offset(0, 6)),
      Paint()
        ..color = colors.ink.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(phone, Paint()..color = colors.surface);
    canvas.drawRRect(
      phone,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = colors.hairline,
    );

    final shieldTop = centre.dy - 34;
    final shield = Path()
      ..moveTo(centre.dx, shieldTop)
      ..lineTo(centre.dx + 28, shieldTop + 14)
      ..lineTo(centre.dx + 28, shieldTop + 42)
      ..quadraticBezierTo(centre.dx + 28, shieldTop + 66, centre.dx, shieldTop + 78)
      ..quadraticBezierTo(centre.dx - 28, shieldTop + 66, centre.dx - 28, shieldTop + 42)
      ..lineTo(centre.dx - 28, shieldTop + 14)
      ..close();

    canvas.drawPath(shield, Paint()..color = colors.accent.withValues(alpha: 0.14));
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colors.accent,
    );

    final tick = Path()
      ..moveTo(centre.dx - 12, shieldTop + 38)
      ..lineTo(centre.dx - 3, shieldTop + 48)
      ..lineTo(centre.dx + 14, shieldTop + 28);

    canvas.drawPath(
      _trim(tick, Curves.easeOut.transform(progress)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = colors.accent,
    );
  }

  Path _trim(Path path, double fraction) {
    if (fraction >= 1) return path;

    final trimmed = Path();
    for (final metric in path.computeMetrics()) {
      trimmed.addPath(metric.extractPath(0, metric.length * fraction), Offset.zero);
    }
    return trimmed;
  }

  @override
  bool shouldRepaint(_PrivacyPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

class ProArt extends StatelessWidget {
  const ProArt({super.key});

  @override
  Widget build(BuildContext context) {
    return _Settling(
      duration: const Duration(milliseconds: 900),
      builder: (progress) => CustomPaint(
        size: const Size(240, 196),
        painter: _ProPainter(AppTheme.of(context), progress),
      ),
    );
  }
}

class _ProPainter extends CustomPainter {
  _ProPainter(this.colors, this.progress);

  final AppColors colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2 + 4);

    canvas.drawCircle(
      centre,
      92 * progress,
      Paint()
        ..shader = RadialGradient(
          colors: [colors.accent.withValues(alpha: 0.18), colors.accent.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: 92)),
    );

    for (final sheet in [(-13.0, 0.30), (-6.5, 0.55), (0.0, 1.0)]) {
      final (angle, opacity) = sheet;

      canvas.save();
      canvas.translate(centre.dx, centre.dy + 52);
      canvas.rotate(angle * progress * math.pi / 180);
      canvas.translate(-centre.dx, -centre.dy - 52);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centre, width: 84, height: 108),
        const Radius.circular(10),
      );

      if (opacity == 1.0) {
        canvas.drawRRect(
          rect.shift(const Offset(0, 5)),
          Paint()
            ..color = colors.ink.withValues(alpha: 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      canvas.drawRRect(
        rect,
        Paint()
          ..color = opacity == 1.0
              ? colors.surface
              : colors.accent.withValues(alpha: opacity * 0.55),
      );

      if (opacity == 1.0) {
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = colors.hairline,
        );

        final line = Paint()
          ..color = colors.muted.withValues(alpha: 0.28)
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round;

        for (var index = 0; index < 4; index++) {
          final y = rect.top + 24 + index * 20;
          canvas.drawLine(
            Offset(rect.left + 16, y),
            Offset(rect.left + 16 + (index.isEven ? 52 : 34), y),
            line,
          );
        }
      }

      canvas.restore();
    }

    final burst = Curves.easeOutBack.transform(((progress - 0.4) / 0.6).clamp(0.0, 1.0));
    if (burst <= 0) return;

    _star(canvas, centre.translate(72, -56), 17 * burst, colors.accent, 0.18);
    _star(canvas, centre.translate(-78, -22), 9 * burst, colors.accent.withValues(alpha: 0.55), -0.2);
    _star(canvas, centre.translate(64, 44), 7 * burst, colors.accent.withValues(alpha: 0.4), 0.3);
  }

  void _star(Canvas canvas, Offset centre, double radius, Color colour, double tilt) {
    final path = Path();

    for (var index = 0; index < 10; index++) {
      final angle = -math.pi / 2 + tilt + index * math.pi / 5;
      final length = index.isEven ? radius : radius * 0.44;
      final point = centre + Offset(math.cos(angle), math.sin(angle)) * length;
      index == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(_ProPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

class _Settling extends StatefulWidget {
  const _Settling({
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
  });

  final Widget Function(double progress) builder;
  final Duration duration;

  @override
  State<_Settling> createState() => _SettlingState();
}

class _SettlingState extends State<_Settling> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.duration)..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => widget.builder(_controller.value),
    );
  }
}
