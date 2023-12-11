import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';

///information about window
mixin WindowUiBinding<T extends StatefulWidget> on State<T> {
  Size get windowSize => MediaQuery.of(context).size;

  double get windowStatusBarHeight => View.of(context).padding.top;

  double get windowBottomBarHeight => View.of(context).padding.bottom;

  double get screenWidth => windowSize.width;

  double get screenHeight => windowSize.height;

  /// The Image position coordinate
  double xGap = 0.0;
  double yGap = 0.0;

  /// The width of the image after operation.
  double actualImageWidth = 0.0;

  /// The height of the image after operation.
  double actualImageHeight = 0.0;

  /// The resize ratio of the original image to the actual display on screen image.
  double resizeRatio = 0.0;
}

extension BaseImageEditorState on State {
  ImageEditorState? get realState {
    if (this is ImageEditorState) {
      return this as ImageEditorState;
    }
    return null;
  }
}
