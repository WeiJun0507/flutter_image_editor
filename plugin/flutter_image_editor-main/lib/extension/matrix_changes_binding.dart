import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_editor/extension/general_binding.dart';
import 'package:image_editor/model/draw.dart';
import 'package:image_editor/painter/crop_layer_painter.dart';

/// Rotation and Flip features Binding class which holds rotate value and flip value
/// The value will be used to effect on canvas when drawing the image and
/// its relative drawing content.
mixin RotateCanvasBinding<T extends StatefulWidget> on State<T> {
  ///canvas rotate value
  /// * 90 angle each time.
  double rotateValue = 0;

  ///canvas flip value
  /// * 180 angle each time.
  double flipValue = 0;

  RotateDirection get getRotateDirection {
    if (rotateValue == 0) {
      return RotateDirection.top;
    } else if (rotateValue == 1) {
      return RotateDirection.left;
    } else if (rotateValue == 2) {
      return RotateDirection.bottom;
    } else {
      return RotateDirection.right;
    }
  }

  ///flip canvas
  void flipCanvas() {
    flipValue = flipValue == 0 ? math.pi : 0;
    PaintOperation value = PaintOperation(
      type: operationType.flip,
      data: FlipInfo(flipRadians: flipValue),
    );
    realState?.operationHistory.add(value);
  }

  ///routate canvas
  /// * will effect image, text, drawing board
  void rotateCanvasPlate() {
    rotateValue = (rotateValue + 1) % 4;
    PaintOperation value = PaintOperation(
      type: operationType.rotate,
      data: RotateInfo(
          radians: rotateValue * math.pi / 2, direction: getRotateDirection),
    );
    realState?.operationHistory.add(value);
  }

  ///reset canvas
  void resetCanvasPlate() {
    PaintOperation value = PaintOperation(
      type: operationType.rotate,
      data: RotateInfo(radians: 0, direction: getRotateDirection),
    );
    realState?.operationHistory.add(value);
  }
}

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

mixin ClipCanvasBinding<T extends StatefulWidget> on State<T> {
  double oriWidth = 0.0;
  double oriHeight = 0.0;

  Offset topLeft = Offset.zero;
  Offset topRight = Offset.zero;
  Offset bottomLeft = Offset.zero;
  Offset bottomRight = Offset.zero;

  double headerHeight = 0.0;

  void initClipper(double width, double height, double headerHeight) {
    oriWidth = width;
    oriHeight = height;

    topRight = Offset(width, 0.0);
    bottomLeft = Offset(0.0, height);
    bottomRight = Offset(width, height);

    this.headerHeight = headerHeight;
  }

  bool exceedWidthBoundaries(Offset a, Offset b) {
    return (a.dx + 100 > b.dx || b.dx > oriWidth) || (a.dx < 0);
  }

  bool exceedHeightBoundaries(Offset a, Offset b) {
    return (a.dy + 100 > b.dy || b.dy > oriHeight) || (a.dy < 0);
  }

  bool checkBoundaries(Offset delta) {
    final changedTopLeft = topLeft + delta;
    final changedBottomRight = bottomRight + delta;
    if (changedTopLeft.dx < 0 || changedTopLeft.dy < 0) return true;
    if (changedBottomRight.dx > oriWidth || changedBottomRight.dy > oriHeight)
      return true;

    return false;
  }

  onCoordinateChange(DragUpdateDetails details) {
    if (!checkBoundaries(details.delta)) {
      topLeft += details.delta;
      topRight += details.delta;
      bottomLeft += details.delta;
      bottomRight += details.delta;
    }

    setState(() {});
  }

  onCornerChange(DragUpdateDetails details, Corner corner) {
    final globalPos = details.globalPosition;
    final finalGlobalPos = globalPos - Offset(0.0, headerHeight);
    if (corner == Corner.topLeft) onTopLeftChange(finalGlobalPos);
    if (corner == Corner.topRight) onTopRightChange(finalGlobalPos);
    if (corner == Corner.bottomLeft) onBottomLeftChange(finalGlobalPos);
    if (corner == Corner.bottomRight) onBottomRightChange(finalGlobalPos);

    setState(() {});
  }

  /// top need to minus top header height for details
  void onTopLeftChange(Offset globalPos) {
    if (!exceedWidthBoundaries(globalPos, topRight)) {
      topLeft = Offset(globalPos.dx, topLeft.dy);
      bottomLeft = Offset(globalPos.dx, bottomLeft.dy);
    }

    if (!exceedHeightBoundaries(globalPos, bottomLeft)) {
      topLeft = Offset(topLeft.dx, globalPos.dy);
      topRight = Offset(topRight.dx, globalPos.dy);
    }
  }

  void onTopRightChange(Offset globalPos) {
    if (!exceedWidthBoundaries(topLeft, globalPos)) {
      topRight = Offset(globalPos.dx, topRight.dy);
      bottomRight = Offset(globalPos.dx, bottomRight.dy);
    }

    if (!exceedHeightBoundaries(globalPos, bottomRight)) {
      topRight = Offset(topRight.dx, globalPos.dy);
      topLeft = Offset(topLeft.dx, globalPos.dy);
    }
  }

  /// bottom need to minus bottom control header height + tool bar heights for details
  void onBottomLeftChange(Offset globalPos) {
    if (!exceedWidthBoundaries(globalPos, bottomRight)) {
      bottomLeft = Offset(globalPos.dx, bottomLeft.dy);
      topLeft = Offset(globalPos.dx, topLeft.dy);
    }

    if (!exceedHeightBoundaries(topLeft, globalPos)) {
      bottomLeft = Offset(bottomLeft.dx, globalPos.dy);
      bottomRight = Offset(bottomRight.dx, globalPos.dy);
    }
  }

  void onBottomRightChange(Offset globalPos) {
    if (!exceedWidthBoundaries(bottomLeft, globalPos)) {
      bottomRight = Offset(globalPos.dx, bottomRight.dy);
      topRight = Offset(globalPos.dx, topRight.dy);
    }

    if (!exceedHeightBoundaries(topRight, globalPos)) {
      bottomRight = Offset(bottomRight.dx, globalPos.dy);
      bottomLeft = Offset(bottomLeft.dx, globalPos.dy);
    }
  }

  Widget buildClipCover(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: CropLayerPainter(
          cropRect: Rect.fromLTRB(
            topLeft.dx,
            topLeft.dy,
            bottomRight.dx,
            bottomRight.dy,
          ),
          lineLength: 30.0,
        ),
        child: Stack(
          children: <Widget>[
            // move clipper
            Positioned.fill(
              child: GestureDetector(onPanUpdate: onCoordinateChange),
            ),

            // top left
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              child: Container(
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) => onCornerChange(
                    details,
                    Corner.topLeft,
                  ),
                ),
              ),
            ),

            // top right
            Positioned(
              left: topRight.dx - 30.0,
              top: topRight.dy,
              child: Container(
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) => onCornerChange(
                    details,
                    Corner.topRight,
                  ),
                ),
              ),
            ),

            // bottom left
            Positioned(
              left: bottomLeft.dx,
              top: bottomLeft.dy - 30.0,
              child: Container(
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) => onCornerChange(
                    details,
                    Corner.bottomLeft,
                  ),
                ),
              ),
            ),

            // bottom right
            Positioned(
              left: bottomRight.dx - 30.0,
              top: bottomRight.dy - 30.0,
              child: Container(
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) => onCornerChange(
                    details,
                    Corner.bottomRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
