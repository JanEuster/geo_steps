import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';

class SizeHelper {
  static const double navHeight = 46;
  late Size size;
  late double heightWithoutNav;
  late double padTopWithNav;
  late double width;
  late double height;
  late EdgeInsets pad;

  SizeHelper() {
    double ratio = window.devicePixelRatio;
    size = window.physicalSize / ratio;
    pad = EdgeInsets.fromLTRB(
        window.padding.left / ratio,
        window.padding.top / ratio,
        window.padding.right / ratio,
        window.padding.bottom / ratio);
    width = size.width;
    height = size.height;
    heightWithoutNav = size.height - navHeight - pad.vertical;
    padTopWithNav = navHeight + pad.top;
  }
}
