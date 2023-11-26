import 'package:flutter/material.dart';

enum DrawStyle {
  non,
  normal,
  mosaic,
}

/// type of user display finger movement
enum PointType {
  /// one touch on specific place - tap
  tap,

  /// finger touching the display and moving around
  move,
}

/// one point on canvas represented by offset and type
class Point {
  /// constructor
  Point(this.offset, this.type, this.eventId);

  /// x and y value on 2D canvas
  Offset offset;

  /// type of user display finger movement
  PointType type;

  int eventId;
}

class PointConfig {
  /// Current Layer Draw History
  List<Point> drawRecord;

  /// Current Layer Drawing Painter Style
  PainterStyle painterStyle;

  PointConfig({
    required this.drawRecord,
    required this.painterStyle,
  });
}

class PainterStyle {
  double mosaicWidth;
  double strokeWidth;
  Color color;
  DrawStyle drawStyle;

  PainterStyle({
    color = Colors.red,
    mosaicWidth = 5.0,
    strokeWidth = 3.0,
    drawStyle = DrawStyle.normal,
  })  : this.color = color,
        this.mosaicWidth = mosaicWidth,
        this.strokeWidth = strokeWidth,
        this.drawStyle = drawStyle;

  bool isSame(PainterStyle style) {
    return mosaicWidth == style.mosaicWidth &&
        strokeWidth == style.strokeWidth &&
        color == style.color &&
        drawStyle == style.drawStyle &&
        hashCode == style.hashCode;
  }

  PainterStyle copyWith({
    Color? color,
    double? mosaicWidth,
    double? strokeWidth,
    DrawStyle? drawStyle,
  }) {
    return PainterStyle(
      color: color ?? this.color,
      mosaicWidth: mosaicWidth ?? this.mosaicWidth,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      drawStyle: drawStyle ?? this.drawStyle,
    );
  }
}

/// class for interaction with signature widget
/// manages points representing signature on canvas
/// provides signature manipulation functions (export, clear)
class DrawingController extends ChangeNotifier {
  /// constructor
  DrawingController({
    this.exportBackgroundColor,
    this.onDrawStart,
    this.onDrawMove,
    this.onDrawEnd,
  });

  /// Current Painter Style
  PainterStyle painterStyle = PainterStyle();

  /// background color to be used in exported png image
  final Color? exportBackgroundColor;

  /// Draw Points Record
  final List<PointConfig> drawHistory = List.empty(growable: true);

  /// stack-like list of point to save user's latest action
  final List<PointConfig> _latestActions = <PointConfig>[];

  /// stack-like list that use to save points when user undo the signature
  final List<PointConfig> _revertedActions = <PointConfig>[];

  /// callback to notify when drawing has started
  VoidCallback? onDrawStart;

  /// callback to notify when the pointer was moved while drawing.
  VoidCallback? onDrawMove;

  /// callback to notify when drawing has stopped
  VoidCallback? onDrawEnd;

  /// add point to point collection
  void addPoint(Point point) {
    final PointConfig config = drawHistory.last;
    config.drawRecord.add(point);
    notifyListeners();
  }

  /// REMEMBERS CURRENT CANVAS STATE IN UNDO STACK
  void pushCurrentStateToUndoStack() {
    _latestActions.add(drawHistory.last);
    //CLEAR ANY UNDO-ED ACTIONS. IF USER UNDO-ED ANYTHING HE ALREADY MADE
    // ANOTHER CHANGE AND LEFT THAT OLD PATH.
    _revertedActions.clear();
  }

  /// check if canvas is empty (opposite of isNotEmpty method for convenience)
  bool get isEmpty {
    return drawHistory.isEmpty;
  }

  /// clear the canvas
  void clear() {
    drawHistory.clear();
    _latestActions.clear();
    _revertedActions.clear();
  }

  /// It will remove last action from [_latestActions].
  /// The last action will be saved to [_revertedActions]
  /// that will be used to do redo-ing.
  /// Then, it will modify the real points with the last action.
  void undo() {
    if (drawHistory.isNotEmpty) {
      drawHistory.removeLast();
      final PointConfig lastAction = _latestActions.removeLast();
      _revertedActions.add(lastAction);
      notifyListeners();
    }
  }

  /// It will remove last reverted actions and add it into [_latestActions]
  /// Then, it will modify the real points with the last reverted action.
  void redo() {
    if (_revertedActions.isEmpty) return;

    final PointConfig lastRevertedAction = _revertedActions.removeLast();
    drawHistory.add(lastRevertedAction);
    _latestActions.add(lastRevertedAction);
    notifyListeners();
  }

// /// convert to
// Future<ui.Image?> toImage() async {
//   if (isEmpty) {
//     return null;
//   }
//
//   double minX = double.infinity,
//       minY = double.infinity;
//   double maxX = 0,
//       maxY = 0;
//   for (Point point in points) {
//     if (point.offset.dx < minX) {
//       minX = point.offset.dx;
//     }
//     if (point.offset.dy < minY) {
//       minY = point.offset.dy;
//     }
//     if (point.offset.dx > maxX) {
//       maxX = point.offset.dx;
//     }
//     if (point.offset.dy > maxY) {
//       maxY = point.offset.dy;
//     }
//   }
//
//   final ui.PictureRecorder recorder = ui.PictureRecorder();
//   final ui.Canvas canvas = Canvas(recorder)
//     ..translate(-(minX - penStrokeWidth), -(minY - penStrokeWidth));
//   if (exportBackgroundColor != null) {
//     final ui.Paint paint = Paint()
//       ..color = exportBackgroundColor!;
//     canvas.drawPaint(paint);
//   }
//   // SignaturePainter(this).paint(canvas, Size.infinite);
//   // final ui.Picture picture = recorder.endRecording();
//   // return picture.toImage(
//   //   (maxX - minX + penStrokeWidth * 2).toInt(),
//   //   (maxY - minY + penStrokeWidth * 2).toInt(),
//   // );
//
//   return null;
// }
//
// /// convert canvas to dart:ui Image and then to PNG represented in Uint8List
// Future<Uint8List?> toPngBytes() async {
//   if (!kIsWeb) {
//     final ui.Image? image = await toImage();
//     if (image == null) {
//       return null;
//     }
//     final ByteData? bytes = await image.toByteData(
//       format: ui.ImageByteFormat.png,
//     );
//     return bytes?.buffer.asUint8List();
//   } else {
//     return _toPngBytesForWeb();
//   }
// }
//
// // 'image.toByteData' is not available for web. So we are using the package
// // 'image' to create an image which works on web too
// Uint8List? _toPngBytesForWeb() {
//   if (isEmpty) {
//     return null;
//   }
//   final Color backgroundColor = exportBackgroundColor ?? Colors.transparent;
//
//   double minX = double.infinity;
//   double maxX = 0;
//   double minY = double.infinity;
//   double maxY = 0;
//
//   for (Point point in points) {
//     minX = min(point.offset.dx, minX);
//     maxX = max(point.offset.dx, maxX);
//     minY = min(point.offset.dy, minY);
//     maxY = max(point.offset.dy, maxY);
//   }
//
//   //point translation
//   final List<Point> translatedPoints = <Point>[];
//   for (Point point in points) {
//     translatedPoints.add(Point(
//       Offset(
//         point.offset.dx - minX + penStrokeWidth,
//         point.offset.dy - minY + penStrokeWidth,
//       ),
//       point.type,
//       point.eventId,
//     ));
//   }
//
//   final int width = (maxX - minX + penStrokeWidth * 2).toInt();
//   final int height = (maxY - minY + penStrokeWidth * 2).toInt();
//
//   // create the image with the given size
//   final img.Image signatureImage = img.Image(width: width, height: height);
//   // set the image background color
//   img.fill(
//     signatureImage,
//     color: img.ColorInt32.rgba(
//       backgroundColor.red,
//       backgroundColor.green,
//       backgroundColor.blue,
//       backgroundColor.alpha.toInt(),
//     ),
//   );
//
//   // read the drawing points list and draw the image
//   // it uses the same logic as the CustomPainter Paint function
//   for (int i = 0; i < translatedPoints.length - 1; i++) {
//     if (translatedPoints[i + 1].type == PointType.move) {
//       img.drawLine(signatureImage,
//           x1: translatedPoints[i].offset.dx.toInt(),
//           y1: translatedPoints[i].offset.dy.toInt(),
//           x2: translatedPoints[i + 1].offset.dx.toInt(),
//           y2: translatedPoints[i + 1].offset.dy.toInt(),
//           color: img.ColorInt32.rgb(
//             penColor.red,
//             penColor.green,
//             penColor.blue,
//           ),
//           thickness: penStrokeWidth);
//     } else {
//       // draw the point to the image
//       img.fillCircle(
//         signatureImage,
//         x: translatedPoints[i].offset.dx.toInt(),
//         y: translatedPoints[i].offset.dy.toInt(),
//         radius: penStrokeWidth.toInt(),
//         color: img.ColorInt32.rgb(
//           penColor.red,
//           penColor.green,
//           penColor.blue,
//         ),
//       );
//     }
//   }
//   // encode the image to PNG
//   return Uint8List.fromList(img.encodePng(signatureImage));
// }
}
