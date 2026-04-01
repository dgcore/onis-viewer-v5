import "dart:io";

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'app/onis_viewer_app.dart';

bool isPerfectGrayscalePng(String path) {
  final bytes = File(path).readAsBytesSync();
  final image = img.decodePng(bytes);

  if (image == null) {
    throw Exception('Failed to decode PNG: $path');
  }

  //check perfect grayscale:
  bool isPerfectGrayscale = true;
  bool isPerfectRedScale = true;
  bool isPerfectGreenScale = true;
  bool isPerfectBlueScale = true;
  int pixelIndex = 0;
  for (final pixel in image) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();

    if (r != g || g != b) {
      //print("index: $pixelIndex, r: $r, g: $g, b: $b");
      isPerfectGrayscale = false;
    }

    if (g != 0 || b != 0) {
      print("index: $pixelIndex, r: $r, g: $g, b: $b");
      isPerfectRedScale = false;
    }
    if (r != 0 || b != 0) {
      isPerfectGreenScale = false;
    }

    if (r != 0 || g != 0) {
      isPerfectBlueScale = false;
    }

    pixelIndex++;
  }

  print("isPerfectGrayscale: $isPerfectGrayscale");
  print("isPerfectRedScale: $isPerfectRedScale");
  print("isPerfectGreenScale: $isPerfectGreenScale");
  print("isPerfectBlueScale: $isPerfectBlueScale");

  return true;
}

void main() {
  // Set up SSL certificate validation override for desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    HttpOverrides.global = _MyHttpOverrides();
  }

  /*String basePath = "/Users/cedric/Downloads/The4thPNGs2/";
  String baseName = "frame_";
  String full709Range = "709Full_";
  String limited709Range = "709Limited_";
  String limited607Range = "601Limited_";
  String limited709RangeV2 = "709Limited_v2_";
  String greyBase = "gray32level";
  String redBase = "R32level";
  String greenBase = "G32level";
  String blueBase = "B32level";

  isPerfectGrayscalePng("$basePath$baseName$limited709RangeV2$redBase.png");
*/
  /*print("--------------------------------");
  print("709 FULL RANGE");
  print("--------------------------------");
  print("GRAYSCALE COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$full709Range$greyBase.png");
  print("--------------------------------");
  print("GREEN COLOR GREEN");
  isPerfectGrayscalePng("$basePath$baseName$full709Range$greenBase.png");
  print("--------------------------------");
  print("RED COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$full709Range$redBase.png");
  print("--------------------------------");
  print("BLUE COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$full709Range$blueBase.png");

  print("--------------------------------");
  print("709 LIMITED RANGE");
  print("--------------------------------");
  print("GRAYSCALE COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited709Range$greyBase.png");
  print("--------------------------------");
  print("GREEN COLOR GREEN");
  isPerfectGrayscalePng("$basePath$baseName$limited709Range$greenBase.png");
  print("--------------------------------");
  print("RED COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited709Range$redBase.png");
  print("--------------------------------");
  print("BLUE COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited709Range$blueBase.png");

  print("--------------------------------");
  print("709 LIMITED RANGE V2");
  print("--------------------------------");
  print("GRAYSCALE COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited709RangeV2$greyBase.png");
  print("--------------------------------");
  print("GREEN COLOR GREEN");
  isPerfectGrayscalePng("$basePath$baseName$limited709RangeV2$greenBase.png");
  print("--------------------------------");
  print("RED COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited709RangeV2$redBase.png");
  print("--------------------------------");
  print("BLUE COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited709RangeV2$blueBase.png");

  print("--------------------------------");
  print("601 LIMITED RANGE");
  print("--------------------------------");
  print("GRAYSCALE COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited607Range$greyBase.png");
  print("--------------------------------");
  print("GREEN COLOR GREEN");
  isPerfectGrayscalePng("$basePath$baseName$limited607Range$greenBase.png");
  print("--------------------------------");
  print("RED COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited607Range$redBase.png");
  print("--------------------------------");
  print("BLUE COLOR BAR");
  isPerfectGrayscalePng("$basePath$baseName$limited607Range$blueBase.png");*/

  runApp(const OnisViewerApp());
}

/// HTTP overrides to ignore SSL certificate validation
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true;
    };
    return client;
  }
}
