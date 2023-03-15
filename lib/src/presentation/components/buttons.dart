import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/utils/sizing.dart';
import 'package:latlong2/latlong.dart';

class OptionsWidget extends StatefulWidget {
  void Function(int) indexChanged;
  List<String> options;
  int index;
  late int length;

  OptionsWidget(this.options,
      {super.key, this.index = 0, required this.indexChanged}) {
    length = options.length;
  }

  @override
  State<StatefulWidget> createState() => OptionsWidgetState();
}

class OptionsWidgetState extends State<OptionsWidget> {
  @override
  void initState() {
    super.initState();
  }

  void setOption(int value) {
    var index = value;
    if (value < 0) {
      index = widget.length + value;
    } else if (value >= widget.length) {
      index = value - widget.length;
    }
    widget.indexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    SizeHelper sizer = SizeHelper();
    return SizedBox(
      width: sizer.width - 100,
      child: Flex(direction: Axis.horizontal, children: [
        IconButtonWidget(
          onTap: () => setOption(widget.index - 1),
          color: Colors.black,
          icon: const Icon(
            Icomoon.arrow,
            size: 30,
            color: Colors.white,
          ),
          iconRotation: 1.5 * pi,
        ),
        const Padding(padding: EdgeInsets.only(left: 10)),
        Expanded(
          flex: 10,
          child: Center(
            child: Text(
              widget.options[widget.index],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(left: 10)),
        IconButtonWidget(
          onTap: () => setOption(widget.index + 1),
          color: Colors.black,
          icon: const Icon(
            Icomoon.arrow,
            size: 30,
            color: Colors.white,
          ),
          iconRotation: .5 * pi,
        ),
      ]),
    );
  }
}

typedef GestureTapCallback = void Function();

class IconButtonWidget extends StatelessWidget {
  double? width;
  double? height;
  late Widget icon;
  late double iconRotation;
  late GestureTapCallback? onTap = () {};
  Color? color;

  IconButtonWidget(
      {super.key,
      required this.icon,
      this.onTap,
      this.iconRotation = 0,
      this.color,
      this.width,
      this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: color,
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(6))),
          child: Transform.rotate(
            angle: iconRotation,
            child: icon,
          )),
    );
  }
}
