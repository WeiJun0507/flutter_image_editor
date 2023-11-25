import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';

///information about window
mixin WindowUiBinding<T extends StatefulWidget> on State<T> {
  Size get windowSize => MediaQuery.of(context).size;

  double get windowStatusBarHeight => View.of(context).padding.top;

  double get windowBottomBarHeight => View.of(context).padding.bottom;

  double get screenWidth => windowSize.width;

  double get screenHeight => windowSize.height;
}

extension BaseImageEditorState on State {
  ImageEditorState? get realState {
    if (this is ImageEditorState) {
      return this as ImageEditorState;
    }
    return null;
  }
}
