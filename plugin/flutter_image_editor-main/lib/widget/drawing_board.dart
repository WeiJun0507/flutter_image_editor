import 'package:flutter/material.dart';
import 'package:image_editor/painter/drawing_pad_painter.dart';

class DrawingBoard extends StatefulWidget {
  final DrawingController controller;
  final Rect rect;

  const DrawingBoard({
    super.key,
    required this.controller,
    required this.rect,
  });

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  /// Helper variable indicating that user has left the canvas so we can prevent linking next point
  /// with straight line.
  bool _isOutsideDrawField = false;

  /// Active pointer to prevent multitouch drawing
  int? activePointerId;

  void _addPoint(PointerEvent event, PointType type) {
    final Offset o = event.localPosition;

    //SAVE POINT ONLY IF IT IS IN THE SPECIFIED BOUNDARIES
    if ((o.dx > widget.rect.left && o.dx < widget.rect.right) &&
        (o.dy > widget.rect.top && o.dy < widget.rect.bottom)) {

      if (event is PointerDownEvent) {
        widget.controller.drawHistory.add(
          PointConfig(
            drawRecord: [],
            painterStyle: widget.controller.painterStyle,
          ),
        );
      }
      // IF USER LEFT THE BOUNDARY AND AND ALSO RETURNED BACK
      // IN ONE MOVE, RETYPE IT AS TAP, AS WE DO NOT WANT TO
      // LINK IT WITH PREVIOUS POINT

      PointType t = type;
      if (_isOutsideDrawField) {
        t = PointType.tap;

        _isOutsideDrawField = false;
        widget.controller.drawHistory.add(
          PointConfig(
            drawRecord: [],
            painterStyle: widget.controller.painterStyle,
          ),
        );
      } else {
        setState(() {
          //IF USER WAS OUTSIDE OF CANVAS WE WILL RESET THE HELPER VARIABLE AS HE HAS RETURNED
          widget.controller.addPoint(Point(o, t, event.pointer));
        });
      }

    } else {
      //NOTE: USER LEFT THE CANVAS!!! WE WILL SET HELPER VARIABLE
      //WE ARE NOT UPDATING IN setState METHOD BECAUSE WE DO NOT NEED TO RUN BUILD METHOD
      if (event is PointerDownEvent && !_isOutsideDrawField) {
        _isOutsideDrawField = true;
      }

      if (event is PointerMoveEvent && !_isOutsideDrawField) {
        widget.controller.addPoint(Point(o, PointType.tap, event.pointer));
        widget.controller.pushCurrentStateToUndoStack();
        _isOutsideDrawField = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent event) {
        if (activePointerId == null || activePointerId == event.pointer) {
          activePointerId = event.pointer;
          widget.controller.onDrawStart?.call();
          _addPoint(event, PointType.tap);
        }
      },
      onPointerUp: (PointerUpEvent event) {
        if (activePointerId == event.pointer) {
          _addPoint(event, PointType.tap);
          widget.controller.pushCurrentStateToUndoStack();
          widget.controller.onDrawEnd?.call();
          activePointerId = null;
        }
      },
      onPointerCancel: (PointerCancelEvent event) {
        if (activePointerId == event.pointer) {
          _addPoint(event, PointType.tap);
          widget.controller.pushCurrentStateToUndoStack();
          widget.controller.onDrawEnd?.call();
          activePointerId = null;
        }
      },
      onPointerMove: (PointerMoveEvent event) {
        if (activePointerId == event.pointer) {
          _addPoint(event, PointType.move);
          widget.controller.onDrawMove?.call();
        }
      },
      child: SizedBox(
        height: widget.rect.height,
        width: widget.rect.width,
      ),
    );
  }
}
