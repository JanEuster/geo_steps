import 'package:flutter/material.dart';

class SizeHelper {
  static const double navHeight = 46;
  late MediaQueryData media;
  late Size size;
  late double heightWithoutNav;
  late double padTopWithNav;
  late double width;
  late double height;
  late EdgeInsets pad;

  SizeHelper(BuildContext context) {
    media = MediaQuery.of(context);
    size = media.size;
    pad = media.viewPadding;
    width = size.width;
    height = size.height;
    heightWithoutNav =
        media.size.height - navHeight - media.viewPadding.vertical;
    padTopWithNav = navHeight + media.viewPadding.top;
  }

  static SizeHelper of(BuildContext context) {
    return SizeHelper(context);
  }
}
