import 'package:flutter/material.dart';
import 'package:image_editor/flutter_image_editor.dart';
import 'package:image_editor/util/size.dart';

class ColorPalettePicker extends StatelessWidget {
  final EditorPanelController controller;
  final List<Color> colors;
  final bool mosaicEnabled;
  ColorPalettePicker({
    super.key,
    required this.controller,
    colors,
    this.mosaicEnabled = false,
  }) : this.colors = colors ?? ImageEditor.uiDelegate.brushColors;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.colorSelected,
      builder: (BuildContext context, Color selectedColor, Widget? _) {
        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (Color color in colors)
              GestureDetector(
                onTap: () => controller.onSwitchColor(
                  DrawStyle.normal,
                  color: color,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  margin: const EdgeInsets.symmetric(
                    horizontal: FIESize.small,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        selectedColor == color ? FIESize.small : FIESize.normal,
                  ),
                  alignment: Alignment.center,
                  width: selectedColor == color ? 35.0 : 25.0,
                  height: selectedColor == color ? 35.0 : 25.0,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            if (mosaicEnabled)
              GestureDetector(
                onTap: () => controller.onSwitchColor(DrawStyle.mosaic),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  padding: EdgeInsets.symmetric(horizontal: FIESize.small),
                  width: selectedColor == Colors.transparent ? 40.0 : 30.0,
                  height: selectedColor == Colors.transparent ? 40.0 : 30.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.auto_awesome_mosaic,
                    size: selectedColor == Colors.transparent ? 22.0 : 14.0,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
