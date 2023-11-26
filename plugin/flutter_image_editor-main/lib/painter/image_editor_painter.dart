import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_editor/extension/drawing_canvas_binding.dart';
import 'package:image_editor/model/float_text_model.dart';
import 'package:image_editor/painter/drawing_pad_painter.dart';
import 'package:image_editor/widget/editor_panel_controller.dart';

class ImageEditorPainter extends CustomPainter {
  EditorPanelController panelController;

  final Rect originalRect;
  final Rect cropRect;
  final ui.Image image;

  final List<FloatTextModel> textItems;
  BaseFloatModel? model;

  final List<PointConfig> points;

  final bool isGeneratingResult;

  ImageEditorPainter({
    required this.panelController,
    required this.originalRect,
    required this.cropRect,
    required this.image,
    required this.textItems,
    required this.points,
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

      paintDrawing(
        canvas,
        originalRect.size,
        Offset(cropRect.left, cropRect.top),
        points,
        isGeneratingResult,
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

      paintDrawing(
        canvas,
        cropRect.size,
        Offset(cropRect.left, cropRect.top),
        points,
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

  void paintDrawing(
    Canvas canvas,
    Size size,
    Offset cropTopLeftOffset,
    List<PointConfig> points,
    bool isGeneratingResult,
  ) {
    for (final point in points) {
      final Paint painter = Paint()
        ..color = point.painterStyle.color
        ..strokeWidth = point.painterStyle.strokeWidth
        ..style = PaintingStyle.stroke;

      switch (point.painterStyle.drawStyle) {
        case DrawStyle.normal:
          canvas.drawPath(
            paintPath(
              canvas,
              size,
              originalRect,
              isGeneratingResult ? cropRect : originalRect,
              point.drawRecord,
              painter,
            ),
            painter,
          );
          break;
        case DrawStyle.mosaic:
          //reduce the frequency of mosaic drawing.
          paintMosaic(
            canvas,
            size,
            isGeneratingResult ? cropRect : originalRect,
            point,
          );

          break;
        case DrawStyle.non:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ImageEditorPainter oldDelegate) => true;
}
