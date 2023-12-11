import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<ByteData> getImageBytes(String path) async {
  return await rootBundle.load(path);
}

Future<ui.Image> getUiImageWithoutSize(String imageAssetPath) async {
  final bytes = await getImageBytes(imageAssetPath);
  return decodeImageFromList(bytes.buffer.asUint8List());
}

Future<ui.Image> getUiImageWithSize(
  ByteData bytes,
  double height,
  double width,
) async {
  final codec = await ui.instantiateImageCodec(
    bytes.buffer.asUint8List(),
    targetHeight: height.toInt(),
    targetWidth: width.toInt(),
  );
  final image = (await codec.getNextFrame()).image;
  return image;
}
