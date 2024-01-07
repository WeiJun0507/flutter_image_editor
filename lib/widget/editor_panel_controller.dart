import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_editor/model/picture_config.dart';
import '../flutter_image_editor.dart';

enum OperateType {
  non,
  drawing,
  text, //add text to canvas
  metrics,
}

/// Todo: set different page category for [drawing] | [text] | [metrics]
class EditorPanelController with DrawingBinding {
  EditorPanelController() {
    colorSelected = ValueNotifier(ImageEditor.uiDelegate.brushColors.first);
    initPainter(
      ImageEditor.canvasLauncher.pColor,
      ImageEditor.canvasLauncher.mosaicWidth,
      ImageEditor.canvasLauncher.pStrockWidth,
    );
  }

  final PageController imgPageController = PageController();

  /// Keep Edited [ui.Picture] for preview and final save.
  Map<String, PictureConfig> pictureMap = <String, PictureConfig>{};

  /// ============================ LifeCycle Init ============================
  void initPictureMap(List<ui.Image> images) {
    for (int i = 0; i < images.length; i++) {
      ui.Image image = images[i];
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);
      canvas.drawImage(image, Offset.zero, Paint());
      ui.Picture picture = recorder.endRecording();
      pictureMap['$i'] = PictureConfig(
        picture: picture,
        originalRect: Rect.fromLTWH(
          0.0,
          0.0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        currentRect: Rect.fromLTWH(
          0.0,
          0.0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
    }
  }

  Future<void> initPictureImage() async {
    pictureMap.forEach((key, value) async {
      value.image = await value.picture!.toImage(40, 40);
    });
  }

  /// Record down all the operations that have been performed

  ///take shot action listener
  /// * it's for hide some non-relative ui.
  /// * e.g. hide status bar, hide bottom bar
  ValueNotifier<bool> takeShot = ValueNotifier(false);

  ValueNotifier<OperateType> operateType = ValueNotifier(OperateType.non);

  void onSwitchColor(
    DrawStyle style, {
    Color? color,
  }) {
    assert(style == DrawStyle.mosaic || color != null);

    switchPainterColor(style, color: color);
    colorSelected.value = color ?? Colors.transparent;
  }

  ///switch operate type
  void switchOperateType(OperateType type) {
    if (operateType.value == type) {
      operateType.value = OperateType.non;
    } else {
      operateType.value = type;
    }
  }

  void cancelOperateType() {
    operateType.value = OperateType.non;
  }
}
