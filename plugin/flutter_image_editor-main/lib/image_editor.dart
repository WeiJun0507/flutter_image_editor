import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:crypto/crypto.dart';
import 'package:image_editor_dove/painter/crop_layer_painter.dart';
import 'package:image_editor_dove/painter/image_editor_painter.dart';
import 'dart:ui' as ui;

import 'extension/num_extension.dart';
import 'package:path_provider/path_provider.dart';

import 'model/float_text_model.dart';
import 'widget/drawing_board.dart';
import 'widget/editor_panel_controller.dart';
import 'widget/float_text_widget.dart';
import 'widget/image_editor_delegate.dart';
import 'widget/text_editor_page.dart';

const CanvasLauncher _defaultLauncher =
    CanvasLauncher(mosaicWidth: 5.0, pStrockWidth: 5.0, pColor: Colors.red);

///The editor's result.
class EditorImageResult {
  ///image width
  final int imgWidth;

  ///image height
  final int imgHeight;

  ///new file after edit
  final File newFile;

  EditorImageResult(this.imgWidth, this.imgHeight, this.newFile);
}

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
  const ImageEditor(
      {Key? key,
      required this.originImage,
      required this.uiImage,
      required this.width,
      required this.height,
      this.savePath,
      this.launcher = _defaultLauncher})
      : super(key: key);

  ///origin image
  /// * input for edit
  final File originImage;

  final ui.Image uiImage;

  ///edited-file's save path.
  /// * if null will save in temporary file.
  final Directory? savePath;

  ///provide some initial value
  final CanvasLauncher launcher;

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
        SignatureBinding,
        TextCanvasBinding,
        RotateCanvasBinding,
        ClipCanvasBinding,
        LittleWidgetBinding,
        WindowUiBinding {
  final EditorPanelController _panelController = EditorPanelController();

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

  ///Save the edited-image to [widget.savePath] or [getTemporaryDirectory()].
  void saveImage() async {
    _panelController.takeShot.value = true;

    final finalPainter = ImageEditorPainter(
      panelController: _panelController,
      originalRect: Rect.fromLTWH(0, 0, screenWidth, canvasHeight),
      cropRect: Rect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        bottomRight.dx,
        bottomRight.dy,
      ),
      image: widget.uiImage,
      textItems: textModels.toList(),
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

    // Future.value().then((value) async {
    //   if (painterController.points.isEmpty &&
    //       pathRecord.length == 1 &&
    //       textModels.isEmpty &&
    //       rotateValue == 0 &&
    //       flipValue == 0.0) {
    //     Navigator.pop(context, {'original': true});
    //     return;
    //   }
    //
    //   RenderRepaintBoundary boundary = _boundaryKey.currentContext
    //       ?.findRenderObject() as RenderRepaintBoundary;
    //
    //   ui.Image image =
    //       await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
    //   ByteData? byteData =
    //       await image.toByteData(format: ui.ImageByteFormat.png);
    //   var pngBytes = byteData?.buffer.asUint8List();
    //
    //   final paths = widget.savePath ?? await getTemporaryDirectory();
    //   final file = await File('${paths.path}/' +
    //           md5.convert(utf8.encode(DateTime.now().toString())).toString() +
    //           '.jpg')
    //       .create();
    //   file.writeAsBytes(pngBytes ?? []);
    //   decodeImg().then((value) {
    //     if (value == null) {
    //       Navigator.pop(context);
    //     } else {
    //       Navigator.pop(
    //           context, EditorImageResult(value.width, value.height, file));
    //     }
    //   }).catchError((e) {
    //     Navigator.pop(context);
    //   });
    // });
  }

  Future<ui.Image?> decodeImg() async {
    return await decodeImageFromList(widget.originImage.readAsBytesSync());
  }

  static ImageEditorState? of(BuildContext context) {
    return context.findAncestorStateOfType<ImageEditorState>();
  }

  @override
  void initState() {
    super.initState();
    initPainter();
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
    _panelController.screenSize ??= windowSize;
    // ゴミ箱の位置を真ん中に調整（水平）
    _panelController.trashCanPosition = Offset(
        (_panelController.screenSize!.width - _panelController.tcSize.width) /
            2,
        _panelController.trashCanPosition.dy);

    double positionTop = (screenHeight - headerHeight - canvasHeight) / 2;
    if (positionTop < headerHeight) positionTop = headerHeight;

    return Material(
      color: Colors.black,
      child: Listener(
        onPointerMove: (v) {
          _panelController.pointerMoving(v);
        },
        child: Stack(
          children: [
            //appBar
            ValueListenableBuilder<bool>(
                valueListenable: _panelController.showAppBar,
                builder: (ctx, value, child) {
                  return AnimatedPositioned(
                      top: value ? 0 : -headerHeight,
                      left: 0,
                      right: 0,
                      child: ValueListenableBuilder<bool>(
                          valueListenable: _panelController.takeShot,
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
                      duration: _panelController.panelDuration);
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
                          panelController: _panelController,
                          originalRect:
                              Rect.fromLTWH(0, 0, screenWidth, canvasHeight),
                          cropRect: Rect.fromLTRB(
                            topLeft.dx,
                            topLeft.dy,
                            bottomRight.dx,
                            bottomRight.dy,
                          ),
                          image: widget.uiImage,
                          textItems: textModels.toList(),
                          isGeneratingResult: false,
                        ),
                        child: Stack(
                          children: <Widget>[
                            for (final model in textModels)
                              buildTextComponent(model),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_panelController.operateType.value == OperateType.clip)
                    _buildClipCover(context),
                ],
              ),
            ),
            //bottom operation(control) bar
            ValueListenableBuilder<bool>(
                valueListenable: _panelController.showBottomBar,
                builder: (ctx, value, child) {
                  return AnimatedPositioned(
                      bottom: value ? 0 : -bottomBarHeight,
                      child: SizedBox(
                        width: screenWidth,
                        child: ValueListenableBuilder<bool>(
                            valueListenable: _panelController.takeShot,
                            builder: (ctx, value, child) {
                              return Opacity(
                                opacity: value ? 0 : 1,
                                child: _buildControlBar(),
                              );
                            }),
                      ),
                      duration: _panelController.panelDuration);
                }),
            //trash bin
            ValueListenableBuilder<bool>(
                valueListenable: _panelController.showTrashCan,
                builder: (ctx, value, child) {
                  return AnimatedPositioned(
                      bottom:
                          value ? _panelController.trashCanPosition.dy : -100,
                      left: _panelController.trashCanPosition.dx,
                      child: _buildTrashCan(),
                      duration: _panelController.panelDuration);
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
              valueListenable: _panelController.operateType,
              builder: (ctx, value, child) {
                return Opacity(
                  opacity: _panelController.show2ndPanel() ? 1 : 0,
                  child: Row(
                    mainAxisAlignment: value == OperateType.brush
                        ? MainAxisAlignment.spaceAround
                        : MainAxisAlignment.end,
                    children: [
                      if (value == OperateType.brush)
                        ..._panelController.brushColor
                            .map<Widget>((e) => CircleColorWidget(
                                  color: e,
                                  valueListenable:
                                      _panelController.colorSelected,
                                  onColorSelected: (color) {
                                    if (pColor.value == color.value) return;
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
              children: [
                _buildButton(OperateType.brush, 'Draw', onPressed: () {
                  switchPainterMode(DrawStyle.normal);
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
                controlBtnSpacing,
                _buildButton(OperateType.mosaic, 'Mosaic', onPressed: () {
                  switchPainterMode(DrawStyle.mosaic);
                  if (mounted) setState(() {});
                }),
                const Expanded(child: SizedBox()),
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
        valueListenable: _panelController.trashColor,
        builder: (ctx, value, child) {
          final bool isActive =
              value.value == EditorPanelController.defaultTrashColor.value;
          return Container(
            width: _panelController.tcSize.width,
            height: _panelController.tcSize.height,
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
        _panelController.switchOperateType(type);
        onPressed?.call();
      },
      child: ValueListenableBuilder(
        valueListenable: _panelController.operateType,
        builder: (ctx, value, child) {
          return SizedBox(
            width: 44,
            height: 41,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getOperateTypeRes(type,
                    choosen: _panelController.isCurrentOperateType(type)),
                Text(
                  txt,
                  style: TextStyle(
                      color: _panelController.isCurrentOperateType(type)
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
        valueListenable: realState?._panelController.operateType ??
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
        valueListenable: realState?._panelController.operateType ??
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

///This binding can make editor to roatate canvas
/// * for now, the paint-path,will change his relative position of canvas
/// * when canvas rotated. because the paint-path area it's full canvas and
/// * origin image is not maybe. if force to keep the relative path, will reduce
/// * the paint-path area.
mixin RotateCanvasBinding {
  ///canvas rotate value
  /// * 90 angle each time.
  int rotateValue = 0;

  ///canvas flip value
  /// * 180 angle each time.
  double flipValue = 0;

  ///flip canvas
  void flipCanvas() {
    flipValue = flipValue == 0 ? math.pi : 0;
  }

  ///routate canvas
  /// * will effect image, text, drawing board
  void rotateCanvasPlate() {
    rotateValue++;
  }

  ///reset canvas
  void resetCanvasPlate() {
    rotateValue = 0;
  }
}

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

mixin ClipCanvasBinding<T extends StatefulWidget> on State<T> {
  double oriWidth = 0.0;
  double oriHeight = 0.0;

  Offset topLeft = Offset.zero;
  Offset topRight = Offset.zero;
  Offset bottomLeft = Offset.zero;
  Offset bottomRight = Offset.zero;

  double headerHeight = 0.0;

  void initClipper(double width, double height, double headerHeight) {
    oriWidth = width;
    oriHeight = height;

    topRight = Offset(width, 0.0);
    bottomLeft = Offset(0.0, height);
    bottomRight = Offset(width, height);

    this.headerHeight = headerHeight;
  }

  bool exceedWidthBoundaries(Offset a, Offset b) {
    return (a.dx + 100 > b.dx || b.dx > oriWidth) || (a.dx < 0);
  }

  bool exceedHeightBoundaries(Offset a, Offset b) {
    return (a.dy + 100 > b.dy || b.dy > oriHeight) || (a.dy < 0);
  }

  bool checkBoundaries(Offset delta) {
    final changedTopLeft = topLeft + delta;
    final changedBottomRight = bottomRight + delta;
    if (changedTopLeft.dx < 0 || changedTopLeft.dy < 0) return true;
    if (changedBottomRight.dx > oriWidth || changedBottomRight.dy > oriHeight)
      return true;

    return false;
  }

  onCoordinateChange(DragUpdateDetails details) {
    if (!checkBoundaries(details.delta)) {
      topLeft += details.delta;
      topRight += details.delta;
      bottomLeft += details.delta;
      bottomRight += details.delta;
    }

    setState(() {});
  }

  onCornerChange(DragUpdateDetails details, Corner corner) {
    final globalPos = details.globalPosition;
    final finalGlobalPos = globalPos - Offset(0.0, headerHeight);
    if (corner == Corner.topLeft) onTopLeftChange(finalGlobalPos);
    if (corner == Corner.topRight) onTopRightChange(finalGlobalPos);
    if (corner == Corner.bottomLeft) onBottomLeftChange(finalGlobalPos);
    if (corner == Corner.bottomRight) onBottomRightChange(finalGlobalPos);

    setState(() {});
  }

  /// top need to minus top header height for details
  void onTopLeftChange(Offset globalPos) {
    if (!exceedWidthBoundaries(globalPos, topRight)) {
      topLeft = Offset(globalPos.dx, topLeft.dy);
      bottomLeft = Offset(globalPos.dx, bottomLeft.dy);
    }

    if (!exceedHeightBoundaries(globalPos, bottomLeft)) {
      topLeft = Offset(topLeft.dx, globalPos.dy);
      topRight = Offset(topRight.dx, globalPos.dy);
    }
  }

  void onTopRightChange(Offset globalPos) {
    if (!exceedWidthBoundaries(topLeft, globalPos)) {
      topRight = Offset(globalPos.dx, topRight.dy);
      bottomRight = Offset(globalPos.dx, bottomRight.dy);
    }

    if (!exceedHeightBoundaries(globalPos, bottomRight)) {
      topRight = Offset(topRight.dx, globalPos.dy);
      topLeft = Offset(topLeft.dx, globalPos.dy);
    }
  }

  /// bottom need to minus bottom control header height + tool bar heights for details
  void onBottomLeftChange(Offset globalPos) {
    if (!exceedWidthBoundaries(globalPos, bottomRight)) {
      bottomLeft = Offset(globalPos.dx, bottomLeft.dy);
      topLeft = Offset(globalPos.dx, topLeft.dy);
    }

    if (!exceedHeightBoundaries(topLeft, globalPos)) {
      bottomLeft = Offset(bottomLeft.dx, globalPos.dy);
      bottomRight = Offset(bottomRight.dx, globalPos.dy);
    }
  }

  void onBottomRightChange(Offset globalPos) {
    if (!exceedWidthBoundaries(bottomLeft, globalPos)) {
      bottomRight = Offset(globalPos.dx, bottomRight.dy);
      topRight = Offset(globalPos.dx, topRight.dy);
    }

    if (!exceedHeightBoundaries(topRight, globalPos)) {
      bottomRight = Offset(bottomRight.dx, globalPos.dy);
      bottomLeft = Offset(bottomLeft.dx, globalPos.dy);
    }
  }

  Widget _buildClipCover(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: CropLayerPainter(
          cropRect: Rect.fromLTRB(
            topLeft.dx,
            topLeft.dy,
            bottomRight.dx,
            bottomRight.dy,
          ),
          lineLength: 30.0,
        ),
        child: Stack(
          children: <Widget>[
            // move clipper
            Positioned.fill(
              child: GestureDetector(onPanUpdate: onCoordinateChange),
            ),

            // top left
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              child: Container(
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) => onCornerChange(
                    details,
                    Corner.topLeft,
                  ),
                ),
              ),
            ),

            // top right
            Positioned(
              left: topRight.dx - 30.0,
              top: topRight.dy,
              child: Container(
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) => onCornerChange(
                    details,
                    Corner.topRight,
                  ),
                ),
              ),
            ),

            // bottom left
            Positioned(
              left: bottomLeft.dx,
              top: bottomLeft.dy - 30.0,
              child: Container(
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) => onCornerChange(
                    details,
                    Corner.bottomLeft,
                  ),
                ),
              ),
            ),

            // bottom right
            Positioned(
              left: bottomRight.dx - 30.0,
              top: bottomRight.dy - 30.0,
              child: Container(
                width: 30.0,
                height: 30.0,
                child: GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) => onCornerChange(
                    details,
                    Corner.bottomRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///text painting
mixin TextCanvasBinding<T extends StatefulWidget> on State<T> {
  late StateSetter textSetter;

  final List<FloatTextModel> textModels = [];

  void addText(FloatTextModel model) {
    textModels.add(model);
    if (mounted) setState(() {});
  }

  ///delete a text from canvas
  void deleteTextWidget(FloatTextModel target) {
    textModels.remove(target);
    if (mounted) setState(() {});
  }

  void toTextEditorPage({FloatTextModel? model}) {
    realState?._panelController.hidePanel();
    if (mounted) setState(() {});

    Navigator.of(context)
        .push(PageRouteBuilder(
            opaque: false,
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return TextEditorPage(model: model);
            }))
        .then((value) {
      realState?._panelController.showPanel();
      if (value is Map) {
        if (value['isEdit']) {
          model = value['result'];
          if (mounted) setState(() {});
        } else if (value['result'] is FloatTextModel) {
          addText(value['result']);
        }
      }
    });
  }

  buildTextComponent(FloatTextModel model) {
    return Positioned(
      left: model.left,
      top: model.top,
      child: Container(
        width: model.size?.width,
        height: model.size?.height,
        child: GestureDetector(
          onTap: () {},
          onPanStart: (_) {
            realState?._panelController.moveText(model);
          },
          onPanUpdate: (details) {
            final textModel =
                realState?._panelController.movingTarget as FloatTextModel?;
            if (textModel != null) {
              textModel.isSelected = true;
              textModel.left += details.delta.dx;
              textModel.top += details.delta.dy;
              if (mounted) setState(() {});
              realState?._panelController.hidePanel();
            }
          },
          onPanEnd: (details) {
            //touch event up
            realState?._panelController.releaseText(details, model, () {
              deleteTextWidget(model);
            });

            model.isSelected = false;
            if (mounted) setState(() {});
            realState?._panelController.showPanel();
          },
          onPanCancel: () {
            model.isSelected = false;

            realState?._panelController.doIdle();
            realState?._panelController.showPanel();
          },
        ),
      ),
    );
  }
}

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
    realState?._panelController.selectColor(color);
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

  Widget _buildBrushCanvas(double width, double height) {
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

///information about window
mixin WindowUiBinding<T extends StatefulWidget> on State<T> {
  Size get windowSize => MediaQuery.of(context).size;

  double get windowStatusBarHeight => ui.window.padding.top;

  double get windowBottomBarHeight => ui.window.padding.bottom;

  double get screenWidth => windowSize.width;

  double get screenHeight => windowSize.height;
}

extension _BaseImageEditorState on State {
  ImageEditorState? get realState {
    if (this is ImageEditorState) {
      return this as ImageEditorState;
    }
    return null;
  }
}

///the color selected.
typedef OnColorSelected = void Function(Color color);

class CircleColorWidget extends StatefulWidget {
  final Color color;

  final ValueNotifier<int> valueListenable;

  final OnColorSelected onColorSelected;

  const CircleColorWidget(
      {Key? key,
      required this.color,
      required this.valueListenable,
      required this.onColorSelected})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CircleColorWidgetState();
  }
}

class CircleColorWidgetState extends State<CircleColorWidget> {
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
