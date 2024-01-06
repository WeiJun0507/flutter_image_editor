import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class EditedImagePainter extends CustomPainter {
  EditedImagePainter({required this.picture});

  final ui.Picture picture;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
