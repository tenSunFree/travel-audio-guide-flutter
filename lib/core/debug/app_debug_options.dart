import 'package:flutter/rendering.dart';

class AppDebugOptions {
  const AppDebugOptions._();

  static const bool _enableRepaintRainbow = false;

  static void configure() {
    assert(() {
      debugRepaintRainbowEnabled = _enableRepaintRainbow;
      return true;
    }());
  }
}
