

import 'package:flutter/material.dart';

class MapMarkerTriangle extends CustomPainter {
  MapMarkerTriangle();

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    // Offset start = Offset(0, size.height / 2);
    // Offset end = Offset(size.width, size.height / 2);
    //
    // canvas.drawLine(start, end, paint);

    var path = Path();
    path.moveTo(0, 11);
    path.lineTo(18, 0);
    path.lineTo(18, 38);
    path.lineTo(0, 11);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}