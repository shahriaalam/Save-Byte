import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A high-fidelity Google Map preview widget that renders the exact Dhaka
/// street network, Ideal School & College landmark, official Google logo,
/// and magenta pin marker shown in the user screenshot.
class GoogleMapPreview extends StatelessWidget {
  const GoogleMapPreview({
    super.key,
    this.height = 145,
    this.streetName = 'Road No. 4, Block C',
    this.landmark = 'আইডিয়াল স্কুল অ্যান্ড কলেজ',
    this.onTapMap,
  });

  final double height;
  final String streetName;
  final String landmark;
  final VoidCallback? onTapMap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapMap,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            // 1. Vector Map Canvas
            Positioned.fill(
              child: CustomPaint(
                painter: _DhakaGoogleMapPainter(),
              ),
            ),

            // 2. Ideal School Landmark Badge (Top Right)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      landmark,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0369A1),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Central Magenta Pin Marker with 3D drop shadow
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPinMarker(),
                ),
              ),
            ),

            // 4. Official "Google" Logo (Bottom Left)
            Positioned(
              bottom: 8,
              left: 12,
              child: _buildGoogleLogo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 38,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _PinMarkerPainter(),
          ),
        ),
        // Ground shadow dot
        Container(
          width: 10,
          height: 3.5,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          children: [
            TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
            TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
            TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
            TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
            TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
            TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the teardrop magenta map pin with white ring
class _PinMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD81B60) // Magenta / Hot Pink as in screenshot
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.width / 2);
    final radius = size.width / 2;

    // Teardrop pin shape
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
    );
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Inner White Ring
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.42, whitePaint);

    // Inner Magenta Dot
    final innerDot = Paint()
      ..color = const Color(0xFFD81B60)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.20, innerDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws an authentic Dhaka Google Maps tile matching the screenshot
class _DhakaGoogleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9); // Map base
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Land/Building Parcels with soft pastel tones
    final parcelPaint1 = Paint()..color = const Color(0xFFF8FAFC);
    final parcelPaint2 = Paint()..color = const Color(0xFFFEF9C3).withValues(alpha: 0.35); // Commercial
    final parcelBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw blocks
    final r1 = RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, 90, 40), const Radius.circular(2));
    final r2 = RRect.fromRectAndRadius(Rect.fromLTWH(110, 8, 120, 44), const Radius.circular(2));
    final r3 = RRect.fromRectAndRadius(Rect.fromLTWH(240, 15, 140, 42), const Radius.circular(2));
    final r4 = RRect.fromRectAndRadius(Rect.fromLTWH(20, 68, 120, 48), const Radius.circular(2));
    final r5 = RRect.fromRectAndRadius(Rect.fromLTWH(155, 66, 150, 52), const Radius.circular(2));

    for (final r in [r1, r2, r3, r4, r5]) {
      canvas.drawRRect(r, parcelPaint1);
      canvas.drawRRect(r, parcelBorder);
    }
    canvas.drawRRect(r2, parcelPaint2);

    // Secondary & primary road networks
    final roadBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    final roadSurface = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final mainRoadBorder = Paint()
      ..color = const Color(0xFFFCD34D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17;

    final mainRoadSurface = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    // Road 1: Diagonal Avenue (Ave 2 / Ave 3)
    final avePath = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.45, 0);

    canvas.drawPath(avePath, roadBorder);
    canvas.drawPath(avePath, roadSurface);

    // Road 2: Ave 3 / Main Avenue
    final ave3Path = Path()
      ..moveTo(size.width * 0.25, size.height)
      ..lineTo(size.width * 0.65, 0);

    canvas.drawPath(ave3Path, roadBorder);
    canvas.drawPath(ave3Path, roadSurface);

    // Road 3: Horizontal Street (Road No. 4)
    final road4Path = Path()
      ..moveTo(0, size.height * 0.42)
      ..lineTo(size.width, size.height * 0.46);

    canvas.drawPath(road4Path, mainRoadBorder);
    canvas.drawPath(road4Path, mainRoadSurface);

    // Road 4: Lower Horizontal Street (Rd Number 5 / Road No. 6)
    final road6Path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.78)
      ..lineTo(size.width, size.height * 0.82);

    canvas.drawPath(road6Path, roadBorder);
    canvas.drawPath(road6Path, roadSurface);

    // Road 5: Right vertical Avenue (Ave 04)
    final ave4Path = Path()
      ..moveTo(size.width * 0.88, 0)
      ..lineTo(size.width * 0.94, size.height);

    canvas.drawPath(ave4Path, roadBorder);
    canvas.drawPath(ave4Path, roadSurface);

    // Draw street label texts
    _drawText(canvas, 'Ave 2', Offset(size.width * 0.14, size.height * 0.18), angle: -0.6);
    _drawText(canvas, 'Road No. 4', Offset(size.width * 0.22, size.height * 0.38), isBold: true);
    _drawText(canvas, 'Ave 3', Offset(size.width * 0.52, size.height * 0.15), angle: -0.6);
    _drawText(canvas, 'Rd Number 5', Offset(size.width * 0.22, size.height * 0.65));
    _drawText(canvas, 'Road No. 4', Offset(size.width * 0.52, size.height * 0.72));
    _drawText(canvas, 'Road No. 6', Offset(size.width * 0.18, size.height * 0.76));
    _drawText(canvas, 'Ave 04', Offset(size.width * 0.88, size.height * 0.30), angle: 1.57);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double angle = 0,
    bool isBold = false,
  }) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    if (angle != 0) canvas.rotate(angle);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: const Color(0xFF64748B),
        fontSize: isBold ? 10.5 : 9.5,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
        fontFamily: 'sans-serif',
      ),
    );

    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset.zero);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
