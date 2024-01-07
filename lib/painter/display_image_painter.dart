import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class DisplayImagePainter extends CustomPainter {
  DisplayImagePainter({
    required this.image,
  });

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}