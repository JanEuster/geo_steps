import 'package:flutter/material.dart';


class Line extends StatelessWidget {
  const Line({Key? key, this.height = 1, this.color = Colors.black})
      : super(key: key);
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: color);
  }
}

class LineVertical extends StatelessWidget {
  const LineVertical({Key? key, this.width = 1, this.color = Colors.black})
      : super(key: key);
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, color: color);
  }
}


class DottedLine extends StatelessWidget {
  const DottedLine({Key? key, this.height = 1, this.color = Colors.black})
      : super(key: key);
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 10.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}