import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:image_editor/util/main.dart';
import 'package:image_editor/util/size.dart';
import 'package:image_editor/widget/delegate/image_editor_delegate_impl.dart';
import 'package:image_editor/painter/edited_image_painter.dart';
import 'package:image_editor/widget/drawing/color_palette_picker.dart';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../flutter_image_editor.dart';

class ImageEditor extends StatefulWidget {
  const ImageEditor({
    Key? key,
    required this.uiImage,
    required this.width,
    required this.height,
    this.savePath,
  }) : super(key: key);

  final ui.Image uiImage;

  ///edited-file's save path.
  /// * if null will save in temporary file.
  final Directory? savePath;

  /// Image Width
  final double width;

  /// Image Height
  final double height;

  ///[uiDelegate] is determine the editor's ui style.
  ///You can extends [ImageEditorDelegate] and custome it by youself.
  static ImageEditorDelegate uiDelegate = ImageEditorDelegateImpl();

  static CanvasLauncher canvasLauncher = CanvasLauncher(
    mosaicWidth: 5.0,
    pStrockWidth: 5.0,
    pColor: Colors.red,
  );

  @override
  State<StatefulWidget> createState() {
    return ImageEditorState();
  }
}

class ImageEditorState extends State<ImageEditor>
    with
        TextCanvasBinding,
        RotateCanvasBinding,
        ClipCanvasBinding,
        ScaleCanvasBinding,
        WindowUiBinding {
  final EditorPanelController panelController = EditorPanelController();

  @override
  void initState() {
    super.initState();
    panelController.initPictureMap([widget.uiImage]);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // Initialize clipper size
      initClipper(actualImageWidth, actualImageHeight);
    });
  }

  calculateImageSize() {
    actualImageHeight = getRotateDirection == RotateDirection.left ||
            getRotateDirection == RotateDirection.right
        ? widget.width
        : widget.height;

    actualImageWidth = getRotateDirection == RotateDirection.left ||
            getRotateDirection == RotateDirection.right
        ? widget.height
        : widget.width;

    if (actualImageWidth > screenWidth) {
      final tempWidth = actualImageWidth;
      actualImageWidth = screenWidth;
      actualImageHeight = actualImageHeight * (actualImageWidth / tempWidth);
    }

    if (actualImageHeight > screenHeight) {
      final tempHeight = actualImageHeight;
      actualImageHeight = screenHeight;
      actualImageWidth = actualImageWidth * (actualImageHeight / tempHeight);
    }

    calculateResizeRatio();
  }

  void calculateResizeRatio() {
    final widthRatio = widget.uiImage.width / actualImageWidth;
    final heightRatio = widget.uiImage.height / actualImageHeight;

    resizeRatio = max(widthRatio, heightRatio);
  }

  ///Save the edited-image to [widget.savePath] or [getTemporaryDirectory()].
  void saveImage() async {
    panelController.takeShot.value = true;

    try {
      final finalPainter = ImageEditorPainter(
        panelController: panelController,
        originalRect: Rect.fromLTWH(0, 0, widget.width, widget.height),
        cropRect: Rect.fromLTRB(
          topLeft.dx,
          topLeft.dy,
          bottomRight.dx,
          bottomRight.dy,
        ),
        image: widget.uiImage,
        resizeRatio: resizeRatio,
        drawHistory: panelController.operationHistory,
        isGeneratingResult: true,
        flipRadians: flipValue,
      );
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);

      // Make sure to apply scaling to the DPR of the window, since the framework will be scaling this picture normally in the layer tree
      canvas.scale(View.of(context).devicePixelRatio);

      final imgSize =
          Size(bottomRight.dx - topLeft.dx, bottomRight.dy - topLeft.dy);
      finalPainter.paint(canvas, imgSize);

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
        file.writeAsBytesSync(pngBytes);
        Navigator.pop(
          context,
          EditorImageResult(finalWidth.toInt(), finalHeight.toInt(), file),
        );
      } else {
        print("Error");
      }
    } catch (e) {
      print("On Save Image error: ${e}");
      Navigator.pop(context);
    }
  }

  /// Utility Tools
  void undoOperation() {
    if (panelController.operationHistory.isEmpty) return;
    PaintOperation operation = panelController.operationHistory.removeLast();
    switch (operation.type) {
      case OperationType.rotate:
        undoRotateCanvas();
        break;
      case OperationType.flip:
        undoFlipCanvas();
        break;
      default:
        break;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Initialize window size
    calculateImageSize();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          enableFeedback: true,
          onPressed: Navigator.of(context).pop,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          SizedBox(
            height: 40.0,
            width: 40.0,
            child: TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(FIESize.medium),
                backgroundColor: buttonBackgroundColor,
              ),
              onPressed: () =>
                  panelController.switchOperateType(OperateType.drawing),
              child: Icon(
                Icons.brush_outlined,
                color: Colors.white,
                size: 22.0,
              ),
            ),
          ),
          const SizedBox(width: FIESize.normal),
        ],
      ),
      body: Column(
        children: <Widget>[
          //image
          Expanded(
            child: RepaintBoundary(
              child: CustomPaint(
                size: MediaQuery.of(context).size,
                painter: EditedImagePainter(
                  picture: panelController.pictureMap.values.first,
                ),
                willChange: false,
              ),
            ),
          ),

          ValueListenableBuilder(
            valueListenable: panelController.operateType,
            builder: (BuildContext context, OperateType type, Widget? _) {
              return Container(
                height: kToolbarHeight,
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  key: ValueKey(type),
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: type == OperateType.drawing
                      ? ColorPalettePicker(
                          controller: panelController,
                          mosaicEnabled: true,
                        )
                      : type == OperateType.text
                          ? const SizedBox()
                          : type == OperateType.metrics
                              ? const SizedBox()
                              : const SizedBox(),
                ),
              );
            },
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}
