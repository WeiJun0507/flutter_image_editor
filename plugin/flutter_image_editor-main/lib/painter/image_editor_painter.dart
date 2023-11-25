import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_editor/model/float_text_model.dart';
import 'package:image_editor/widget/editor_panel_controller.dart';

class ImageEditorPainter extends CustomPainter {
  EditorPanelController panelController;

  final Rect originalRect;
  final Rect cropRect;
  final ui.Image image;

  final List<FloatTextModel> textItems;
  BaseFloatModel? model;

  final bool isGeneratingResult;

  ImageEditorPainter({
    required this.panelController,
    required this.originalRect,
    required this.cropRect,
    required this.image,
    required this.textItems,
    required this.isGeneratingResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint imgCoverPaint = Paint()
      ..color = Colors.black38.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Paint croppedImgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    if (!isGeneratingResult) {
      canvas.drawImage(image, Offset.zero, imgCoverPaint);
      canvas.drawImageRect(image, cropRect, cropRect, croppedImgPaint);
      paintText(
        canvas,
        size,
        Offset.zero,
        textItems,
        false,
      );
    } else {
      canvas.drawImageRect(
        image,
        cropRect,
        Rect.fromLTWH(0.0, 0.0, size.width, size.height),
        croppedImgPaint,
      );
      paintText(
        canvas,
        originalRect.size,
        Offset(cropRect.left, cropRect.top),
        textItems,
        isGeneratingResult,
      );
    }
  }

  void paintText(
    Canvas canvas,
    Size size,
    Offset cropTopLeftOffset,
    List<FloatTextModel> textItems,
    bool isGeneratingResult,
  ) {
    if (!isGeneratingResult) {
      for (final item in textItems) {
        final textStyle = item.style;
        final textSpan = TextSpan(
          text: item.text,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        final offset = Offset(item.left, item.top);
        textPainter.paint(canvas, offset);
      }
    } else {
      for (final item in textItems) {
        final textStyle = item.style;
        final textSpan = TextSpan(
          text: item.text,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        // 1. get dx diff from text to the crop size
        final widthDiff = item.left - cropTopLeftOffset.dx;

        // 2. get dy diff from text to the crop size
        final heightDiff = item.top - cropTopLeftOffset.dy;

        final offset = Offset(widthDiff, heightDiff);
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ImageEditorPainter oldDelegate) => true;
}
