import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PictureConfig {
  ui.Picture? picture;
  ui.Image? image;
  Rect? originalRect;
  Rect? currentRect;

  GlobalKey pictureKey = GlobalKey();

  /// todo: Add actual image size and image ratio
  /// todo: Add individual operateHistory,
  /// todo: Add individual GlobalKey

  PictureConfig({
    this.picture,
    this.image,
    this.originalRect,
    this.currentRect,
  });

  PictureConfig copyWith({
    ui.Picture? picture,
    ui.Image? image,
    Rect? originalRect,
    Rect? currentRect,
  }) {
    return PictureConfig(
      picture: picture ?? this.picture,
      image: image ?? this.image,
      originalRect: originalRect ?? this.originalRect,
      currentRect: currentRect ?? this.currentRect,
    );
  }

  bool identical(PictureConfig other) {
    return picture == other.picture &&
        image == other.image &&
        originalRect == other.originalRect &&
        currentRect == other.currentRect &&
        currentRect.hashCode == other.currentRect.hashCode;
  }
}
