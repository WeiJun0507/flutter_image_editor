import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../flutter_image_editor.dart';

class ImageEditorPainter extends CustomPainter {
  EditorPanelController panelController;

  final Rect originalRect;
  final Rect cropRect;
  final ui.Image image;
  final double resizeRatio;

  final List<PaintOperation> drawHistory;

  final bool isGeneratingResult;
  final double flipRadians;

  ImageEditorPainter({
    required this.panelController,
    required this.originalRect,
    required this.cropRect,
    required this.image,
    required this.resizeRatio,
    required this.drawHistory,
    required this.isGeneratingResult,
    required this.flipRadians,
  });

  /// Temp Picture is used to get the paint layer of [text, draw, crop] operation
  ui.Picture? tempPicture;

  /// Clip Rect display picture where its image is according to the cropRect
  ui.Picture? clipPicture;

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

    RotateDirection direction = RotateDirection.top;

    ui.Picture? limitPicture;

    if (drawHistory.isNotEmpty) {
      ui.PictureRecorder layerRecorder = ui.PictureRecorder();
      Canvas layerCanvas = Canvas(layerRecorder);

      if (drawHistory.length > 75) {
        for (int i = 0; i < drawHistory.length - 25; i++) {
          final history = drawHistory[i];
          switch (history.type) {
            case OperationType.draw:
              final PointConfig points = history.data;
              paintDrawing(
                layerCanvas,
                isGeneratingResult ? cropRect.size : originalRect.size,
                Offset(cropRect.left, cropRect.top),
                points,
                isGeneratingResult,
              );
              break;
            case OperationType.text:
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
            case OperationType.crop:
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
          case OperationType.draw:
            final PointConfig points = drawHistory[i].data;
            paintDrawing(
              layerCanvas,
              isGeneratingResult ? cropRect.size : originalRect.size,
              Offset(cropRect.left, cropRect.top),
              points,
              isGeneratingResult,
            );
            break;
          case OperationType.text:
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
          case OperationType.crop:
          default:
            break;
        }
      }

      tempPicture = layerRecorder.endRecording();
    }

    if (bigPicture == null) {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final backgroundCanvas = Canvas(recorder);

      if (!isGeneratingResult) {
        paintImage(
          canvas: backgroundCanvas,
          rect: originalRect,
          image: image,
          fit: BoxFit.cover,
        );
      } else {
        canvas.translate(size.width / 2, size.height /2);
        // canvas.rotate(radians);

        canvas.transform(Matrix4.rotationY(flipRadians).storage);
        canvas.translate(-(size.width / 2), -(size.height /2));

        final actualRect = Rect.fromLTWH(
          cropRect.left * resizeRatio,
          cropRect.top * resizeRatio,
          cropRect.width * resizeRatio,
          cropRect.height * resizeRatio,
        );

        backgroundCanvas.drawImageRect(
          image,
          actualRect,
          Rect.fromLTWH(0.0, 0.0, size.width, size.height),
          croppedImgPaint,
        );
      }

      if (limitPicture != null) {
        backgroundCanvas.drawPicture(limitPicture);
      }

      bigPicture = recorder.endRecording();
    }

    /// Step 2: always paint the bigPicture
    if (bigPicture != null) {
      canvas.drawPicture(bigPicture!);
    }

    /// Step 3: draw the remaining operation
    if (tempPicture != null) {
      canvas.drawPicture(tempPicture!);
    }

    if (!isGeneratingResult) {
      drawUnwantedPath(canvas, size, cropRect, imgCoverPaint, direction);
    }

    if (isGeneratingResult) canvas.restore();
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

      /// 1. get dx diff from text to the crop size
      final widthDiff = item.left - cropTopLeftOffset.dx;

      /// 2. get dy diff from text to the crop size
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

  void drawUnwantedPath(
    Canvas canvas,
    Size size,
    Rect cropRect,
    Paint painter,
    RotateDirection direction,
  ) {
    final unusedTopPath = Path();
    final unusedLeftPath = Path();
    final unusedRightPath = Path();
    final unusedBottomPath = Path();

    /// Q: When rotate to either direction left or right, the path cannot cover the whole width
    /// A: Wrong design. Cropped path doesn't mean it should dependents to the rotation degree.
    /// When user has rotated the canvas, let the crop to be rotated as well.

    /// Draw top unused path
    /// The path is first moving downward,
    /// then move to the size.width, back to y-axis 0, and close the path
    unusedTopPath.moveTo(0.0, 0.0);
    unusedTopPath.lineTo(size.width, 0.0);
    unusedTopPath.lineTo(size.width, cropRect.top);
    unusedTopPath.lineTo(0.0, cropRect.top);
    unusedTopPath.close();

    /// Draw left unused path
    /// Path is first moving to the right,
    /// then move to the size.height, back to x-axis 0, and close the path
    unusedLeftPath.moveTo(0.0, cropRect.top);
    unusedLeftPath.relativeLineTo(cropRect.left, 0.0);
    unusedLeftPath.relativeLineTo(0.0, cropRect.bottom - cropRect.top);
    unusedLeftPath.relativeLineTo(-cropRect.left, 0.0);
    unusedLeftPath.close();

    /// moving canvas position to the right size
    unusedRightPath.moveTo(size.width, cropRect.top);

    /// Draw right unused path
    /// Path is first moving to the right,
    /// then move to the canvas height, lastly move the canvas back to the right path
    /// close the path.
    unusedRightPath.relativeLineTo(-(size.width - cropRect.right), 0.0);
    unusedRightPath.relativeLineTo(0.0, cropRect.bottom - cropRect.top);
    unusedRightPath.relativeLineTo(size.width - cropRect.right, 0.0);
    unusedRightPath.close();

    /// Draw bottom unused path
    unusedBottomPath.moveTo(0.0, cropRect.bottom);
    unusedBottomPath.lineTo(0.0, size.height);
    unusedBottomPath.lineTo(size.width, size.height);
    unusedBottomPath.lineTo(size.width, cropRect.bottom);
    unusedBottomPath.close();

    /// Path is first moving to the bottom,

    canvas.drawPath(unusedTopPath, painter);
    canvas.drawPath(unusedLeftPath, painter);
    canvas.drawPath(unusedRightPath, painter);
    canvas.drawPath(unusedBottomPath, painter);
  }

  @override
  bool shouldRepaint(covariant ImageEditorPainter oldDelegate) => true;
}
