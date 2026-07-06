import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

/// Renders a circular salon photo pin and returns its PNG bytes
/// for use as a Yandex MapKit BitmapDescriptor.
Future<Uint8List> buildSalonPinBytes({
  String? imageUrl,
  String fallbackLetter = 'S',
  Color color = const Color(0xFF3B82F6),
  double size = 80,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final totalSize = size + 16; // pin shadow + arrow
  const arrowH = 12.0;
  const borderW = 3.0;

  final shadowPaint = Paint()..color = color.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  canvas.drawCircle(Offset(totalSize / 2, size / 2 + borderW), size / 2 + borderW + 2, shadowPaint);

  // Border circle
  final borderPaint = Paint()..color = Colors.white;
  canvas.drawCircle(Offset(totalSize / 2, size / 2 + borderW), size / 2 + borderW, borderPaint);

  // Clip circle for photo
  final clipPath = Path()..addOval(Rect.fromCircle(center: Offset(totalSize / 2, size / 2 + borderW), radius: size / 2));
  canvas.save();
  canvas.clipPath(clipPath);

  ui.Image? img;
  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final res = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final codec = await ui.instantiateImageCodec(res.bodyBytes, targetWidth: size.toInt(), targetHeight: size.toInt());
        final frame = await codec.getNextFrame();
        img = frame.image;
      }
    } catch (_) {}
  }

  if (img != null) {
    paintImage(canvas: canvas, rect: Rect.fromLTWH(totalSize / 2 - size / 2, borderW, size, size), image: img, fit: BoxFit.cover);
  } else {
    // Gradient fallback
    final bgPaint = Paint()..shader = RadialGradient(colors: [color, Color.lerp(color, Colors.black, 0.3)!]).createShader(
      Rect.fromCircle(center: Offset(totalSize / 2, size / 2 + borderW), radius: size / 2),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, totalSize, totalSize), bgPaint);

    final tp = TextPainter(
      text: TextSpan(text: fallbackLetter.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: size * 0.38, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(totalSize / 2 - tp.width / 2, size / 2 + borderW - tp.height / 2));
  }

  canvas.restore();

  // Bottom triangle arrow
  final arrowPaint = Paint()..color = Colors.white;
  final arrowPath = Path()
    ..moveTo(totalSize / 2 - 8, size + borderW * 2)
    ..lineTo(totalSize / 2 + 8, size + borderW * 2)
    ..lineTo(totalSize / 2, size + borderW * 2 + arrowH)
    ..close();
  canvas.drawPath(arrowPath, arrowPaint);

  // Blue accent ring
  final accentPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = borderW;
  canvas.drawCircle(Offset(totalSize / 2, size / 2 + borderW), size / 2 + borderW, accentPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(totalSize.toInt(), (size + borderW * 2 + arrowH).toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
