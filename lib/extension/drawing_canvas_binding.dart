import 'dart:ui';

import 'package:flutter/material.dart';
import '../flutter_image_editor.dart';

///drawing board
mixin DrawingBinding<T extends StatefulWidget> on State<T> {
  /// Drawing Controller
  late DrawingController painterController;

  late StateSetter canvasSetter;

  ///switch painter's style
  /// * e.g. color、mosaic
  void switchPainterMode(DrawStyle style) {
    if (style == painterController.painterStyle.drawStyle) {
      painterController.painterStyle =
          painterController.painterStyle.copyWith(drawStyle: DrawStyle.non);
      realState?.panelController.cancelOperateType();
      return;
    }

    painterController.painterStyle =
        painterController.painterStyle.copyWith(drawStyle: style);
    realState?.panelController.operateType.value =
        style == DrawStyle.mosaic ? OperateType.mosaic : OperateType.brush;
  }

  ///change painter's color
  void changePainterColor(Color color) async {
    realState?.panelController.selectColor(color);
    painterController.painterStyle =
        painterController.painterStyle.copyWith(color: color);
  }

  ///undo last drawing.
  void undo() {
    painterController.undo();
  }

  void initPainter(
    Color painterColor,
    double mosaicWidth,
    double pStrokeWidth,
  ) {
    painterController = DrawingController();
    painterController.painterStyle = PainterStyle(
      color: painterColor,
      mosaicWidth: mosaicWidth,
      strokeWidth: pStrokeWidth,
      drawStyle: DrawStyle.non,
    );

    /// todo: See what the listener can do
    painterController.addListener(() {
      if (mounted) realState?.setState(() {});
    });
  }

  /// The Drawing Component should only put Listener
  /// instead of the whole function drawing pad
  Widget buildDrawingComponent(Rect rect, List<PaintOperation> drawHistory) {
    return DrawingBoard(
      controller: painterController,
      rect: rect,
      drawHistory: drawHistory,
    );
  }
}

extension DrawingPath on CustomPainter {
  //for draw [DrawStyle.mosaic]
  void paintMosaic(
    Canvas canvas,
    Size size,
    Rect oriRect,
    Rect rect,
    PointConfig point,
  ) {
    for (int i = 0; i < point.drawRecord.length; i += 2) {
      final Offset center = point.drawRecord[i].offset;
      Offset actualPos =
          center - Offset(rect.left - oriRect.left, rect.top - oriRect.top);
      actualPos = Offset(
        clampDouble(actualPos.dx, 0, rect.right),
        clampDouble(actualPos.dy, 0, rect.bottom),
      );

      final Paint paint = Paint()..color = Colors.black26;
      final double size = point.painterStyle.mosaicWidth;
      final double halfSize = size / 2;
      final Rect b1 = Rect.fromCenter(
        center: actualPos.translate(-halfSize, -halfSize),
        width: size,
        height: size,
      );
      //0,0
      canvas.drawRect(b1, paint);
      paint.color = Colors.grey.withOpacity(0.5);
      //0,1
      canvas.drawRect(b1.translate(0, size), paint);
      paint.color = Colors.black38;
      //0,2
      canvas.drawRect(b1.translate(0, size * 2), paint);
      paint.color = Colors.black12;
      //1,0
      canvas.drawRect(b1.translate(size, 0), paint);
      paint.color = Colors.black26;
      //1,1
      canvas.drawRect(b1.translate(size, size), paint);
      paint.color = Colors.black45;
      //1,2
      canvas.drawRect(b1.translate(size, size * 2), paint);
      paint.color = Colors.grey.withOpacity(0.5);
      //2,0
      canvas.drawRect(b1.translate(size * 2, 0), paint);
      paint.color = Colors.black12;
      //2,1
      canvas.drawRect(b1.translate(size * 2, size), paint);
      paint.color = Colors.black26;
      //2,2
      canvas.drawRect(b1.translate(size * 2, size * 2), paint);
    }
  }

  //for draw [DrawStyle.normal]
  Path paintPath(
    Canvas canvas,
    Size size,
    Rect oriRect,
    Rect rect,
    List<Point> points,
    Paint painter,
  ) {
    final Path path = Path();

    final Map<int, List<Point>> pathM = {};
    points.forEach((element) {
      if (pathM[element.eventId] == null) pathM[element.eventId] = [];
      pathM[element.eventId]!.add(element);
    });

    pathM.forEach((key, value) {
      final Point point = value.first;

      /// Calculate to maintain the actual initial position to start drawing
      Offset actualPos = point.offset -
          Offset(rect.left - oriRect.left, rect.top - oriRect.top);
      actualPos = Offset(
        clampDouble(actualPos.dx, 0, rect.right),
        clampDouble(actualPos.dy, 0, rect.bottom),
      );
      path.moveTo(actualPos.dx, actualPos.dy);

      if (value.length <= 3) {
        painter.style = PaintingStyle.fill;
        canvas.drawCircle(
          actualPos,
          painter.strokeWidth,
          painter,
        );
        painter.style = PaintingStyle.stroke;
      } else {
        value.forEach((e) {
          final Point tempPoint = e;

          /// this is the local position of the original rect
          /// should calculate to translate the position
          /// to the actual clipped position
          Offset actualPaintPoint = tempPoint.offset -
              Offset(rect.left - oriRect.left, rect.top - oriRect.top);
          actualPaintPoint = Offset(
            clampDouble(actualPaintPoint.dx, -5, rect.right),
            clampDouble(actualPaintPoint.dy, -5, rect.bottom),
          );

          path.lineTo(actualPaintPoint.dx, actualPaintPoint.dy);
        });
      }
    });
    return path;
  }
}
