import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:image_editor/extension/general_binding.dart';
import 'package:image_editor/model/draw.dart';
import 'package:image_editor/model/editor_result.dart';
import 'package:image_editor/painter/image_editor_painter.dart';
import 'package:image_editor/widget/color_picker.dart';
import 'dart:ui' as ui;

import 'extension/drawing_canvas_binding.dart';
import 'extension/matrix_changes_binding.dart';
import 'extension/num_extension.dart';
import 'package:path_provider/path_provider.dart';

import 'extension/text_canvas_binding.dart';
import 'widget/editor_panel_controller.dart';
import 'widget/image_editor_delegate.dart';

const CanvasLauncher _defaultLauncher =
    CanvasLauncher(mosaicWidth: 5.0, pStrockWidth: 5.0, pColor: Colors.red);

///The launcher provides some initial-values for canvas;
class CanvasLauncher {
  factory CanvasLauncher.auto() {
    return const CanvasLauncher(
        mosaicWidth: 5.0, pStrockWidth: 5.0, pColor: Colors.red);
  }

  const CanvasLauncher(
      {required this.mosaicWidth,
      required this.pStrockWidth,
      required this.pColor});

  ///mosaic pixel's width
  final double mosaicWidth;

  ///painter stroke width.
  final double pStrockWidth;

  ///painter color
  final Color pColor;
}

class ImageEditor extends StatefulWidget {
  const ImageEditor({
    Key? key,
    required this.originImage,
    required this.uiImage,
    required this.width,
    required this.height,
    this.savePath,
  }) : super(key: key);

  ///origin image
  /// * input for edit
  final File originImage;

  final ui.Image uiImage;

  ///edited-file's save path.
  /// * if null will save in temporary file.
  final Directory? savePath;

  /// Image Width
  final int width;

  /// Image Height
  final int height;

  ///[uiDelegate] is determine the editor's ui style.
  ///You can extends [ImageEditorDelegate] and custome it by youself.
  static ImageEditorDelegate uiDelegate = DefaultImageEditorDelegate();

  @override
  State<StatefulWidget> createState() {
    return ImageEditorState();
  }
}

class ImageEditorState extends State<ImageEditor>
    with
        DrawingBinding,
        TextCanvasBinding,
        RotateCanvasBinding,
        ClipCanvasBinding,
        LittleWidgetBinding,
        WindowUiBinding {
  final EditorPanelController panelController = EditorPanelController();

  GlobalKey _boundaryKey = GlobalKey();

  double get headerHeight => windowStatusBarHeight;

  double get bottomBarHeight => 105 + windowBottomBarHeight;

  ///Edit area height.
  double canvasHeight = 0.0;

  double get canvasWidth => screenWidth;

  ///Operation panel button's horizontal space.
  Widget get controlBtnSpacing => 5.hGap;

  /// Image original aspect ratio
  /// May be use later to generate the image when clip
  double get imgOriginalRatio => widget.height / widget.width;

  /// operation history
  /// Record down all the operations that have been performed
  final List<PaintOperation> operationHistory = List.empty(growable: true);

  List<FloatTextModel> get textModels => operationHistory
      .where((element) => element.type == operationType.text)
      .map<FloatTextModel>((e) => e.data as FloatTextModel)
      .toList();

  ///Save the edited-image to [widget.savePath] or [getTemporaryDirectory()].
  void saveImage() async {
    panelController.takeShot.value = true;

    final finalPainter = ImageEditorPainter(
      panelController: panelController,
      originalRect: Rect.fromLTWH(0, 0, screenWidth, canvasHeight),
      cropRect: Rect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        bottomRight.dx,
        bottomRight.dy,
      ),
      image: widget.uiImage,
      drawHistory: operationHistory,
      isGeneratingResult: true,
    );
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    // Make sure to apply scaling to the DPR of the window, since the framework will be scaling this picture normally in the layer tree
    canvas.save();
    canvas.scale(View.of(context).devicePixelRatio);

    final imgSize =
        Size(bottomRight.dx - topLeft.dx, bottomRight.dy - topLeft.dy);
    finalPainter.paint(canvas, imgSize);

    canvas.restore();
    final finalWidth = imgSize.width * View.of(context).devicePixelRatio;
    final finalHeight = imgSize.height * View.of(context).devicePixelRatio;

    final ui.Image recordedImg = await recorder
        .endRecording()
        .toImage(finalWidth.toInt(), finalHeight.toInt());

    final ByteData? imgBytes =
        await recordedImg.toByteData(format: ui.ImageByteFormat.png);
    if (imgBytes != null) {
      final pngBytes = imgBytes.buffer.asUint8List();
      final paths = widget.savePath ?? await getTemporaryDirectory();
      final file = await File('${paths.path}/' +
              md5.convert(utf8.encode(DateTime.now().toString())).toString() +
              '.jpg')
          .create();
      file.writeAsBytes(pngBytes);
      Navigator.pop(
        context,
        EditorImageResult(finalWidth.toInt(), finalHeight.toInt(), file),
      );
    } else {
      print("Error");
    }
  }

  static ImageEditorState? of(BuildContext context) {
    return context.findAncestorStateOfType<ImageEditorState>();
  }

  @override
  void initState() {
    super.initState();
    initPainter(
      _defaultLauncher.pColor,
      _defaultLauncher.mosaicWidth,
      _defaultLauncher.pStrockWidth,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      canvasHeight = min(
        widget.height.toDouble(),
        screenHeight - headerHeight - bottomBarHeight,
      );
      initClipper(screenWidth, canvasHeight, screenHeight - canvasHeight);
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    panelController.screenSize ??= windowSize;
    // ゴミ箱の位置を真ん中に調整（水平）
    panelController.trashCanPosition = Offset(
        (panelController.screenSize!.width - panelController.tcSize.width) / 2,
        panelController.trashCanPosition.dy);

    double positionTop = (screenHeight - headerHeight - canvasHeight) / 2;
    if (positionTop < headerHeight) positionTop = headerHeight;

    return Material(
      color: Colors.black,
      child: Listener(
        onPointerMove: panelController.pointerMoving,
        child: Stack(
          children: [
            //appBar
            ValueListenableBuilder<bool>(
                valueListenable: panelController.showAppBar,
                builder: (ctx, value, child) {
                  return AnimatedPositioned(
                      top: value ? 0 : -headerHeight,
                      left: 0,
                      right: 0,
                      child: ValueListenableBuilder<bool>(
                          valueListenable: panelController.takeShot,
                          builder: (ctx, value, child) {
                            return Opacity(
                              opacity: value ? 0 : 1,
                              child: AppBar(
                                iconTheme: const IconThemeData(
                                    color: Colors.white, size: 16),
                                leading: backWidget(),
                                backgroundColor: Colors.transparent,
                                actions: <Widget>[
                                  resetWidget(onTap: () {
                                    resetCanvasPlate();
                                    if (mounted) setState(() {});
                                  }),
                                ],
                              ),
                            );
                          }),
                      duration: panelController.panelDuration);
                }),
            //canvas
            Positioned.fromRect(
              rect: Rect.fromLTWH(
                0,
                positionTop,
                screenWidth,
                canvasHeight,
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: CustomPaint(
                        painter: ImageEditorPainter(
                          panelController: panelController,
                          originalRect:
                              Rect.fromLTWH(0, 0, screenWidth, canvasHeight),
                          cropRect: Rect.fromLTRB(
                            topLeft.dx,
                            topLeft.dy,
                            bottomRight.dx,
                            bottomRight.dy,
                          ),
                          image: widget.uiImage,
                          drawHistory: operationHistory,
                          isGeneratingResult: false,
                        ),
                        child: Stack(
                          children: <Widget>[
                            for (final model in textModels)
                              buildTextComponent(model),
                            if (panelController.operateType.value ==
                                    OperateType.brush ||
                                panelController.operateType.value ==
                                    OperateType.mosaic)
                              Positioned.fill(
                                child: buildDrawingComponent(
                                  Rect.fromLTRB(
                                    topLeft.dx,
                                    topLeft.dy,
                                    bottomRight.dx,
                                    bottomRight.dy,
                                  ),
                                  operationHistory,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (panelController.operateType.value == OperateType.clip)
                    buildClipCover(context),
                ],
              ),
            ),
            //bottom operation(control) bar
            ValueListenableBuilder<bool>(
                valueListenable: panelController.showBottomBar,
                builder: (ctx, value, child) {
                  return AnimatedPositioned(
                      bottom: value ? 0 : -bottomBarHeight,
                      child: SizedBox(
                        width: screenWidth,
                        child: ValueListenableBuilder<bool>(
                            valueListenable: panelController.takeShot,
                            builder: (ctx, value, child) {
                              return Opacity(
                                opacity: value ? 0 : 1,
                                child: _buildControlBar(),
                              );
                            }),
                      ),
                      duration: panelController.panelDuration);
                }),
            //trash bin
            ValueListenableBuilder<bool>(
                valueListenable: panelController.showTrashCan,
                builder: (ctx, value, child) {
                  return AnimatedPositioned(
                      bottom:
                          value ? panelController.trashCanPosition.dy : -100,
                      left: panelController.trashCanPosition.dx,
                      child: _buildTrashCan(),
                      duration: panelController.panelDuration);
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      color: Colors.black,
      width: screenWidth,
      height: bottomBarHeight,
      padding:
          EdgeInsets.only(left: 16, right: 16, bottom: windowBottomBarHeight),
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<OperateType>(
              valueListenable: panelController.operateType,
              builder: (ctx, value, child) {
                return Opacity(
                  opacity: panelController.show2ndPanel() ? 1 : 0,
                  child: Row(
                    mainAxisAlignment: value == OperateType.brush
                        ? MainAxisAlignment.spaceAround
                        : MainAxisAlignment.end,
                    children: [
                      if (value == OperateType.brush)
                        ...panelController.brushColor
                            .map<Widget>((e) => ColorPicker(
                                  color: e,
                                  valueListenable:
                                      panelController.colorSelected,
                                  onColorSelected: (color) {
                                    if (painterController.painterStyle.color ==
                                        color.value) return;
                                    changePainterColor(color);
                                  },
                                ))
                            .toList(),
                      35.hGap,
                      unDoWidget(onPressed: undo),
                      if (value == OperateType.mosaic) 7.hGap,
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildButton(OperateType.brush, 'Draw', onPressed: () {
                          switchPainterMode(DrawStyle.normal);
                          if (mounted) setState(() {});
                        }),
                        controlBtnSpacing,
                        _buildButton(OperateType.mosaic, 'Mosaic',
                            onPressed: () {
                          switchPainterMode(DrawStyle.mosaic);
                          if (mounted) setState(() {});
                        }),
                        controlBtnSpacing,
                        _buildButton(OperateType.text, 'Text',
                            onPressed: toTextEditorPage),
                        controlBtnSpacing,
                        _buildButton(OperateType.flip, 'Flip', onPressed: () {
                          flipCanvas();
                          if (mounted) setState(() {});
                        }),
                        controlBtnSpacing,
                        _buildButton(
                          OperateType.rotated,
                          'Rotate',
                          onPressed: () {
                            rotateCanvasPlate();
                            if (mounted) setState(() {});
                          },
                        ),
                        controlBtnSpacing,
                        _buildButton(
                          OperateType.clip,
                          'Clip',
                          onPressed: !mounted ? null : () => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
                doneButtonWidget(onPressed: saveImage),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrashCan() {
    return ValueListenableBuilder<Color>(
        valueListenable: panelController.trashColor,
        builder: (ctx, value, child) {
          final bool isActive =
              value.value == EditorPanelController.defaultTrashColor.value;
          return Container(
            width: panelController.tcSize.width,
            height: panelController.tcSize.height,
            decoration: BoxDecoration(
                color: value,
                borderRadius: const BorderRadius.all(Radius.circular(8))),
            child: Column(
              children: [
                12.vGap,
                const Icon(
                  Icons.delete_outline,
                  size: 32,
                  color: Colors.white,
                ),
                4.vGap,
                Text(
                  isActive ? 'move here for delete' : 'release to delete',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                )
              ],
            ),
          );
        });
  }

  Widget _buildButton(OperateType type, String txt, {VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: () {
        panelController.switchOperateType(type);
        onPressed?.call();
      },
      child: ValueListenableBuilder(
        valueListenable: panelController.operateType,
        builder: (ctx, value, child) {
          return SizedBox(
            width: 44,
            height: 41,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getOperateTypeRes(type,
                    choosen: panelController.isCurrentOperateType(type)),
                Text(
                  txt,
                  style: TextStyle(
                      color: panelController.isCurrentOperateType(type)
                          ? const Color(0xFFFA4D32)
                          : const Color(0xFF999999),
                      fontSize: 11),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

///Little widget binding is for unified manage the widgets that has common style.
/// * If you wanna custom this part, see [ImageEditorDelegate]
mixin LittleWidgetBinding<T extends StatefulWidget> on State<T> {
  ///go back widget
  Widget backWidget({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed ??
          () {
            Navigator.pop(context);
          },
      child: ImageEditor.uiDelegate.buildBackWidget(),
    );
  }

  ///operation button in control bar
  Widget getOperateTypeRes(OperateType type, {required bool choosen}) {
    return ImageEditor.uiDelegate.buildOperateWidget(type, choosen: choosen);
  }

  ///action done widget
  Widget doneButtonWidget({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ImageEditor.uiDelegate.buildDoneWidget(),
    );
  }

  ///undo action
  Widget unDoWidget({VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ImageEditor.uiDelegate.buildUndoWidget(),
    );
  }

  ///Ignore pointer evenet by [OperateType]
  Widget ignoreWidgetByType(OperateType type, Widget child) {
    return ValueListenableBuilder(
        valueListenable: realState?.panelController.operateType ??
            ValueNotifier(OperateType.non),
        builder: (ctx, type, c) {
          return IgnorePointer(
            ignoring: type != OperateType.brush && type != OperateType.mosaic,
            child: child,
          );
        });
  }

  ///reset button
  Widget resetWidget({VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6, right: 16),
      child: ValueListenableBuilder<OperateType>(
        valueListenable: realState?.panelController.operateType ??
            ValueNotifier(OperateType.non),
        builder: (ctx, value, child) {
          return Offstage(
            offstage: value != OperateType.rotated,
            child: GestureDetector(
              onTap: onTap,
              child: ImageEditor.uiDelegate.resetWidget,
            ),
          );
        },
      ),
    );
  }
}
