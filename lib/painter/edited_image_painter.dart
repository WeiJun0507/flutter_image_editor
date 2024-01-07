import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_editor/flutter_image_editor.dart';
import 'package:image_editor/model/picture_config.dart';

class EditedImagePainter extends CustomPainter {
  EditedImagePainter({
    required this.config,
    required this.operateType,
    required this.operateHistory,
  }) : assert(config.picture != null,
            '[PictureConfig] ui.picture can not be null');

  /// Saved Picture Layer
  final PictureConfig config;

  /// Edited Operation Type
  final OperateType operateType;

  /// Drawing History according to current [operateType]
  final List<PaintOperation> operateHistory;

  /// Temp Picture is used to get the paint layer of [text, draw, crop] operation
  ui.Picture? tempPicture;

  /// Used to record when [operateHistory] too much, remove the first N and generate a picture using [PictureRecorder]
  ui.Picture? bigPicture;

  @override
  void paint(Canvas canvas, Size size) {
    if (operateType == OperateType.metrics) {
      canvas.scale(0.8, 0.8);
    }

    canvas.drawPicture(config.picture!);

    drawPaintingDrawing(operateHistory, canvas, config.currentRect!);
  }

  void drawPaintingDrawing(
    List<PaintOperation> drawHistory,
    Canvas canvas,
    Rect rect,
  ) {
    ui.PictureRecorder layerRecorder = ui.PictureRecorder();
    Canvas layerCanvas = Canvas(layerRecorder);

    ui.Picture? limitPicture;

    if (drawHistory.length > 75) {
      for (int i = 0; i < drawHistory.length - 25; i++) {
        final history = drawHistory[i];
        final PointConfig points = history.data;

        paintDrawing(
          layerCanvas,
          config.originalRect!,
          config.currentRect!,
          points,
        );
      }

      limitPicture = layerRecorder.endRecording();
      layerRecorder = ui.PictureRecorder();
      layerCanvas = Canvas(layerRecorder);

      /// [operateHistory] must always be the specific history type so that can remove directly
      drawHistory.removeRange(0, drawHistory.length - 25);
    }

    for (int i = 0; i < drawHistory.length; i++) {
      final PointConfig points = drawHistory[i].data;
      paintDrawing(
        layerCanvas,
        config.originalRect!,
        config.currentRect!,
        points,
      );
      tempPicture = layerRecorder.endRecording();
    }

    if (limitPicture != null) {
      canvas.drawPicture(limitPicture);
    }

    if (tempPicture != null) {
      canvas.drawPicture(tempPicture!);
    }
  }

  void paintDrawing(
    Canvas canvas,
    Rect originalRect,
    Rect currentRect,
    PointConfig point,
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
            originalRect,
            currentRect,
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
          originalRect,
          currentRect,
          point,
        );

        break;
      case DrawStyle.non:
        break;
    }
  }

  @override
  bool shouldRepaint(EditedImagePainter oldDelegate) {
    return !config.identical(oldDelegate.config) ||
        operateType != oldDelegate.operateType ||
        (operateHistory.length != oldDelegate.operateHistory.length ||
            operateHistory.hashCode != oldDelegate.operateHistory.hashCode);
  }
}
