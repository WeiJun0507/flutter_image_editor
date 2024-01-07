import 'package:flutter/material.dart';
import '../flutter_image_editor.dart';

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
  void addPoint(PaintOperation operation, Point point) {
    if (operation.type != OperationType.draw) return;

    final PointConfig config = operation.data as PointConfig;
    config.drawRecord.add(point);
    notifyListeners();
  }

  /// REMEMBERS CURRENT CANVAS STATE IN UNDO STACK
  void pushCurrentStateToUndoStack() {
    // if (drawHistory.isEmpty) return;
    // _latestActions.add(drawHistory.last);
    //CLEAR ANY UNDO-ED ACTIONS. IF USER UNDO-ED ANYTHING HE ALREADY MADE
    // ANOTHER CHANGE AND LEFT THAT OLD PATH.
    // _revertedActions.clear();
  }

  /// check if canvas is empty (opposite of isNotEmpty method for convenience)
  // bool get isEmpty {
  //   return drawHistory.isEmpty;
  // }

  /// clear the canvas
  void clear() {
    _latestActions.clear();
    _revertedActions.clear();
  }

  /// It will remove last action from [_latestActions].
  /// The last action will be saved to [_revertedActions]
  /// that will be used to do redo-ing.
  /// Then, it will modify the real points with the last action.
  void undo() {
    // if (drawHistory.isNotEmpty) {
    //   drawHistory.removeLast();
    //   final PointConfig lastAction = _latestActions.removeLast();
    //   _revertedActions.add(lastAction);
    //   notifyListeners();
    // }
  }

  /// It will remove last reverted actions and add it into [_latestActions]
  /// Then, it will modify the real points with the last reverted action.
  void redo() {
    if (_revertedActions.isEmpty) return;

    final PointConfig lastRevertedAction = _revertedActions.removeLast();
    // drawHistory.add(lastRevertedAction);
    _latestActions.add(lastRevertedAction);
    notifyListeners();
  }
}
