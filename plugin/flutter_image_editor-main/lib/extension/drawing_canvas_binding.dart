import 'package:flutter/material.dart';
import 'package:image_editor/extension/general_binding.dart';
import 'package:image_editor/image_editor.dart';
import 'package:image_editor/widget/drawing_board.dart';
import 'package:image_editor/widget/editor_panel_controller.dart';

///drawing board
mixin SignatureBinding<T extends StatefulWidget> on State<ImageEditor> {
  DrawStyle get lastDrawStyle => painterController.drawStyle;

  ///Canvas layer for each draw action action.
  /// * e.g. First draw some path with white color, than change the color and draw some path again.
  /// * After this [pathRecord] will save 2 layes in it.
  final List<Widget> pathRecord = [];

  late StateSetter canvasSetter;

  ///mosaic pixel's width
  double mosaicWidth = 5.0;

  ///painter stroke width.
  double pStrockWidth = 5;

  ///painter color
  Color pColor = Colors.redAccent;

  ///painter controller
  late SignatureController painterController;

  @override
  void initState() {
    super.initState();
    pColor = widget.launcher.pColor;
    mosaicWidth = widget.launcher.mosaicWidth;
    pStrockWidth = widget.launcher.pStrockWidth;
  }

  ///switch painter's style
  /// * e.g. color、mosaic
  void switchPainterMode(DrawStyle style) {
    if (lastDrawStyle == style) return;
    changePainterColor(pColor);
    painterController.drawStyle = style;
  }

  ///change painter's color
  void changePainterColor(Color color) async {
    pColor = color;
    realState?.panelController.selectColor(color);
    pathRecord.insert(
        0,
        RepaintBoundary(
          child: CustomPaint(
              painter: SignaturePainter(painterController),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: double.infinity,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity),
              )),
        ));
    initPainter();
    _refreshBrushCanvas();
  }

  void _refreshBrushCanvas() {
    pathRecord.removeLast();
    //add new layer.
    pathRecord.add(Signature(
      controller: painterController,
      backgroundColor: Colors.transparent,
    ));
    _refreshCanvas();
  }

  ///undo last drawing.
  void undo() {
    painterController.undo();
  }

  ///refresh canvas.
  void _refreshCanvas() {
    canvasSetter(() {});
  }

  void initPainter() {
    painterController = SignatureController(
        penStrokeWidth: pStrockWidth,
        penColor: pColor,
        mosaicWidth: mosaicWidth);
  }

  Widget buildBrushCanvas(double width, double height) {
    if (pathRecord.isEmpty) {
      pathRecord.add(Signature(
        controller: painterController,
        backgroundColor: Colors.transparent,
        width: width,
        height: height,
      ));
    }
    return StatefulBuilder(
      builder: (ctx, canvasSetter) {
        this.canvasSetter = canvasSetter;
        return realState?.ignoreWidgetByType(
                OperateType.brush, Stack(children: pathRecord)) ??
            const SizedBox();
      },
    );
  }

  @override
  void dispose() {
    pathRecord.clear();
    super.dispose();
  }
}
