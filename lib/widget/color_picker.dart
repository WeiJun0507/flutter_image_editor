import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  final Color color;

  final ValueNotifier<int> valueListenable;

  final void Function(Color color) onColorSelected;

  const ColorPicker(
      {Key? key,
      required this.color,
      required this.valueListenable,
      required this.onColorSelected})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ColorPickerState();
  }
}

class ColorPickerState extends State<ColorPicker> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onColorSelected(widget.color);
      },
      child: ValueListenableBuilder<int>(
        valueListenable: widget.valueListenable,
        builder: (ctx, value, child) {
          final double size = value == widget.color.value ? 25 : 21;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.white,
                  width: value == widget.color.value ? 4 : 2),
              shape: BoxShape.circle,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}
