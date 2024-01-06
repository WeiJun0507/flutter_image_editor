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

enum OperationType { draw, text, crop, flip, rotate }

class PaintOperation {
  final OperationType type;
  final dynamic data;

  PaintOperation({required this.type, required this.data});
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

class PainterStyle {
  double mosaicWidth;
  double strokeWidth;
  Color color;
  DrawStyle drawStyle;

  PainterStyle({
    color = Colors.red,
    mosaicWidth = 5.0,
    strokeWidth = 3.0,
    drawStyle = DrawStyle.non,
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

///The launcher provides some initial-values for canvas;
class CanvasLauncher {
  factory CanvasLauncher.auto() {
    return const CanvasLauncher(
        mosaicWidth: 5.0, pStrockWidth: 5.0, pColor: Colors.red);
  }

  const CanvasLauncher(
      {required this.mosaicWidth,
      required this.pStrockWidth,
      required this.pColor});

  ///mosaic pixel's width
  final double mosaicWidth;

  ///painter stroke width.
  final double pStrockWidth;

  ///painter color
  final Color pColor;
}

/// Text Model
class FloatTextModel {
  String text;

  TextStyle? style;

  ///the top of position
  double top;

  ///the left of position
  double left;

  ///widget's size
  Size? size;

  bool isSelected;

  FloatTextModel({
    required this.text,
    this.style,
    required this.top,
    required this.left,
    this.size,
    this.isSelected = false,
  });

  Size? get floatSize => size;

  bool compareTo(FloatTextModel model) {
    return text != model.text ||
        style.hashCode != model.style.hashCode ||
        top != model.top ||
        left != model.left;
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'style': style.toString(),
      'top': top,
      'left': left,
      'isSelected': isSelected,
    };
  }
}

/// This enum states the current rotate direction
/// [RotateDirection.top] will be the original states and when the value changes,
/// the rotate direction will change accordingly
/// -> [RotateDirection.left] -> [RotateDirection.bottom] -> [RotateDirection.right]
enum RotateDirection {
  left,
  top,
  right,
  bottom,
}

class RotateInfo {
  final double radians;
  final RotateDirection direction;

  RotateInfo({required this.radians, required this.direction});
}

class FlipInfo {
  final double flipRadians;

  FlipInfo({required this.flipRadians});
}

class CropInfo {
  final Rect cropRect;
  final Size originalSize;
  final Size size;
  final Offset offset;
  final double scale;
  final double rotate;
  final double flip;

  CropInfo({
    required this.cropRect,
    required this.originalSize,
    required this.size,
    required this.offset,
    required this.scale,
    required this.rotate,
    required this.flip,
  });
}
