import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_editor/widget/text/dash_border.dart';
import '../../flutter_image_editor.dart';

class FloatTextWidget extends StatefulWidget {
  final FloatTextModel textModel;

  const FloatTextWidget({Key? key, required this.textModel}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FloatTextWidgetState();
  }
}

class FloatTextWidgetState extends State<FloatTextWidget> {
  FloatTextModel get model => widget.textModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        RenderObject? ro = context.findRenderObject();
        if (ro is RenderBox) {
          widget.textModel.size ??= ro.size;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      constraints: BoxConstraints(minWidth: 10, maxWidth: 335),
      decoration: BoxDecoration(
          border: model.isSelected
              ? DashBorder()
              : null),
      child: Text(
        model.text,
        style: model.style,
      ),
    );
  }
}