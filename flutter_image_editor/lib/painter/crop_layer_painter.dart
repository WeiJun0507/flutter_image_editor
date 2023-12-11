import 'dart:math';

import 'package:flutter/material.dart';

class CropLayerPainter extends CustomPainter {
  final Rect cropRect;
  final double lineLength;

  CropLayerPainter({
    required this.cropRect,
    required this.lineLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final painter = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.save();

    // 画 四个角
    canvas.translate(cropRect.topLeft.dx, cropRect.topLeft.dy);
    // 左上角
    canvas.drawLine(Offset.zero, Offset(lineLength, 0.0), painter);
    canvas.drawLine(Offset.zero, Offset(0.0, lineLength), painter);

    canvas.translate(-cropRect.topLeft.dx, -cropRect.topLeft.dy);
    canvas.translate(cropRect.topRight.dx, cropRect.topRight.dy);

    // 右上角
    canvas.drawLine(Offset.zero, Offset(-lineLength, 0.0), painter);
    canvas.drawLine(Offset.zero, Offset(0.0, lineLength), painter);

    canvas.translate(-cropRect.topRight.dx, -cropRect.topRight.dy);
    canvas.translate(cropRect.bottomLeft.dx, cropRect.bottomLeft.dy);

    // 左下角
    canvas.drawLine(Offset.zero, Offset(lineLength, 0.0), painter);
    canvas.drawLine(Offset.zero, Offset(0.0, -lineLength), painter);

    canvas.translate(-cropRect.bottomLeft.dx, -cropRect.bottomLeft.dy);
    canvas.translate(cropRect.bottomRight.dx, cropRect.bottomRight.dy);
    // 右上角
    canvas.drawLine(Offset.zero, Offset(-lineLength, 0.0), painter);
    canvas.drawLine(Offset.zero, Offset(0.0, -lineLength), painter);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CropLayerPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect || oldDelegate.lineLength != lineLength;
}
