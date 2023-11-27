import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_editor/extension/drawing_canvas_binding.dart';
import 'package:image_editor/model/draw.dart';
import 'package:image_editor/widget/editor_panel_controller.dart';

class ImageEditorPainter extends CustomPainter {
  EditorPanelController panelController;

  final Rect originalRect;
  final Rect cropRect;
  final ui.Image image;

  final List<PaintOperation> drawHistory;

  final bool isGeneratingResult;

  ImageEditorPainter({
    required this.panelController,
    required this.originalRect,
    required this.cropRect,
    required this.image,
    required this.drawHistory,
    required this.isGeneratingResult,
  });

  /// Temp Picture is used to get the paint layer of [text, draw, crop] operation
  ui.Picture? tempPicture;

  /// Used to record when drawHistory too much, remove the first N and generate a picture using [PictureRecorder]
  ui.Picture? bigPicture;

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

    double flipValue = 0;
    double rotateRadians = 0;

    ui.Picture? limitPicture;

    if (drawHistory.isNotEmpty) {
      ui.PictureRecorder layerRecorder = ui.PictureRecorder();
      Canvas layerCanvas = Canvas(layerRecorder);

      if (drawHistory.length > 75) {
        for (int i = 0; i < drawHistory.length - 25; i++) {
          final history = drawHistory[i];
          switch (history.type) {
            case operationType.rotate:
              rotateRadians = history.data.radians;
              break;
            case operationType.flip:
              flipValue = history.data.flipRadians;
              break;
            case operationType.draw:
              final PointConfig points = history.data;
              paintDrawing(
                layerCanvas,
                isGeneratingResult ? cropRect.size : originalRect.size,
                Offset(cropRect.left, cropRect.top),
                points,
                isGeneratingResult,
              );
              break;
            case operationType.text:
              final FloatTextModel textItem = history.data;
              paintText(
                layerCanvas,
                originalRect.size,
                isGeneratingResult
                    ? Offset(cropRect.left, cropRect.top)
                    : Offset.zero,
                textItem,
                false,
              );
              break;
            case operationType.crop:
            default:
              break;
          }
        }

        limitPicture = layerRecorder.endRecording();
        layerRecorder = ui.PictureRecorder();
        layerCanvas = Canvas(layerRecorder);
        drawHistory.removeRange(0, drawHistory.length - 25);
      }

      for (int i = 0; i < drawHistory.length; i++) {
        switch (drawHistory[i].type) {
          case operationType.rotate:
            rotateRadians = drawHistory[i].data.radians;
            break;
          case operationType.flip:
            flipValue = drawHistory[i].data.flipRadians;
            break;
          case operationType.draw:
            final PointConfig points = drawHistory[i].data;
            paintDrawing(
              layerCanvas,
              isGeneratingResult ? cropRect.size : originalRect.size,
              Offset(cropRect.left, cropRect.top),
              points,
              isGeneratingResult,
            );
            break;
          case operationType.text:
            final FloatTextModel textItem = drawHistory[i].data;
            paintText(
              layerCanvas,
              originalRect.size,
              isGeneratingResult
                  ? Offset(cropRect.left, cropRect.top)
                  : Offset.zero,
              textItem,
              isGeneratingResult,
            );
            break;
          case operationType.crop:
          default:
            break;
        }
      }

      tempPicture = layerRecorder.endRecording();
    }

    if (bigPicture == null) {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final backgroundCanvas = Canvas(recorder);

      backgroundCanvas.save();

      backgroundCanvas.translate(size.width / 2, size.height / 2);
      backgroundCanvas.rotate(rotateRadians);
      backgroundCanvas.transform(Matrix4.rotationY(flipValue).storage);
      backgroundCanvas.translate(-(size.width / 2), -(size.height / 2));

      if (!isGeneratingResult) {
        backgroundCanvas.drawImage(image, Offset.zero, imgCoverPaint);
        backgroundCanvas.drawImageRect(
            image, cropRect, cropRect, croppedImgPaint);
      } else {
        backgroundCanvas.drawImageRect(
          image,
          cropRect,
          Rect.fromLTWH(0.0, 0.0, size.width, size.height),
          croppedImgPaint,
        );
      }

      if (limitPicture != null) {
        backgroundCanvas.drawPicture(limitPicture);
      }

      backgroundCanvas.restore();
      bigPicture = recorder.endRecording();
    }

    /// Step 1: always paint the bigPicture
    if (bigPicture != null) {
      canvas.drawPicture(bigPicture!);
    }

    /// Step 2: draw the remaining operation
    if (tempPicture != null) {
      canvas.drawPicture(tempPicture!);
    }

    // canvas.save();
    //
    // canvas.translate(size.width / 2, size.height /2);
    // canvas.rotate(radians);
    // canvas.transform(Matrix4.rotationY(flipRadians).storage);
    // canvas.translate(-(size.width / 2), -(size.height /2));
    //
    // if (!isGeneratingResult) {
    //   canvas.drawImage(image, Offset.zero, imgCoverPaint);
    //   canvas.drawImageRect(image, cropRect, cropRect, croppedImgPaint);
    //   paintText(
    //     canvas,
    //     size,
    //     Offset.zero,
    //     textItems,
    //     false,
    //   );
    //
    // } else {
    //   canvas.drawImageRect(
    //     image,
    //     cropRect,
    //     Rect.fromLTWH(0.0, 0.0, size.width, size.height),
    //     croppedImgPaint,
    //   );
    //   paintText(
    //     canvas,
    //     originalRect.size,
    //     Offset(cropRect.left, cropRect.top),
    //     textItems,
    //     isGeneratingResult,
    //   );
    // }
    // canvas.restore();
  }

  void paintText(
    Canvas canvas,
    Size size,
    Offset cropTopLeftOffset,
    FloatTextModel item,
    bool isGeneratingResult,
  ) {
    if (!isGeneratingResult) {
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
    } else {
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

  void paintDrawing(
    Canvas canvas,
    Size size,
    Offset cropTopLeftOffset,
    PointConfig point,
    bool isGeneratingResult,
  ) {
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
          originalRect,
          isGeneratingResult ? cropRect : originalRect,
          point,
        );

        break;
      case DrawStyle.non:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant ImageEditorPainter oldDelegate) => true;
}
