import 'package:flutter/material.dart';
import 'package:image_editor/flutter_image_editor.dart';
import 'package:image_editor/model/picture_config.dart';
import 'package:image_editor/painter/display_image_painter.dart';
import 'package:image_editor/painter/edited_image_painter.dart';
import 'package:image_editor/util/size.dart';

class PictureListing extends StatelessWidget {
  final EditorPanelController controller;

  const PictureListing({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: FIESize.medium),
        itemCount: controller.pictureMap.length,
        itemBuilder: (BuildContext context, int index) {
          final PictureConfig config =
              controller.pictureMap.values.elementAt(index);

          if (config.image == null) {
            return SizedBox(
              height: 40.0,
              width: 40.0,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final double imgRatio =
              config.originalRect!.width / config.originalRect!.height;

          return RepaintBoundary(
            child: Container(
              margin: const EdgeInsets.only(right: FIESize.medium),
              decoration: BoxDecoration(
                border: Border.all(
                  color: controller.imgPageController.page?.floor() == index
                      ? Colors.blue
                      : Colors.transparent,
                  width: 2.0,
                ),
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                size: Size(40.0, 40.0),
                painter: DisplayImagePainter(image: config.image!),
                willChange: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
