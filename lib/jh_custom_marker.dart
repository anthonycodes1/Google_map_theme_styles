import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarkerIcon {
  final double size;
  final String imagePath;
  final Color backgroundColor;

  CustomMarkerIcon({
    required this.size,
    required this.imagePath,
    required this.backgroundColor,
  });

  Future<BitmapDescriptor> createMarkerIcon() async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double radius = size / 2.0;


    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List byteList = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(byteList);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    final double imageSize = size * 0.9;
    final double imageLeft = radius - imageSize / 2.0;
    final double imageTop = radius - imageSize / 2.0;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(imageLeft, imageTop, imageSize, imageSize),
      Paint(),
    );

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}
