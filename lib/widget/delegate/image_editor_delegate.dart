import 'package:flutter/material.dart';
import '../../flutter_image_editor.dart';

class DefaultTextConfigModel extends TextConfigModel {
  @override
  double get initSize => 14;

  @override
  double get sliderBottomLimit => 14;

  @override
  double get sliderUpLimit => 36;

  @override
  Color get cursorColor => const Color(0xFFF83112);
}

///This model for [TextEditorPage] to initial text style.
abstract class TextConfigModel {
  ///slider up limit
  double get sliderUpLimit;

  ///slider bottom limit
  double get sliderBottomLimit;

  ///initial size
  double get initSize;

  ///input field's cursor color.
  Color get cursorColor;

  bool get isLegal =>
      initSize >= sliderBottomLimit && initSize <= sliderUpLimit;
}

///For delegate [ImageEditor]'s ui style.
abstract class ImageEditorDelegate {
  ///Brush colors
  /// * color's amount in [1,7]
  List<Color> get brushColors;

  ///Text Colors
  /// * color's amount in [1,7]
  List<Color> get textColors;

  ///Slider's theme data
  SliderThemeData sliderThemeData(BuildContext context);

  ///Text config model
  /// * see also: [TextEditorPage]
  TextConfigModel get textConfigModel;

  Widget appBarDelegate(BuildContext context, EditorPanelController controller);

  Widget toolDelegate(BuildContext context, EditorPanelController controller);
}
