import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/utils/sizing.dart';
import 'package:latlong2/latlong.dart';

class OptionsWidget extends StatefulWidget {
  void Function(int) indexChanged;
  List<String> options;
  int index;
  late int length;

  OptionsWidget(this.options, {super.key, this.index = 0, required this.indexChanged}) {
    length = options.length;
  }

  @override
  State<StatefulWidget> createState() => OptionsWidgetState();
}

class OptionsWidgetState extends State<OptionsWidget> {
  late int index;

  @override
  void initState() {
    index = widget.index;
  }

  void setOption(int value) {
    if (value < 0) {
      setState(() {
        index = widget.length + value;
      });
    } else if (value >= widget.length) {
      setState(() {
        index = value - widget.length;
      });
    } else {
      setState(() {
        index = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeHelper sizer = SizeHelper();
    return SizedBox(
      width: sizer.width - 100,
      height: 100,
      child: Row(children: [
        IconButton(
          onTap: () => setOption(index - 1),
          icon: const Icon(Icomoon.arrow, size: 30),
          iconRotation: 1.5 * pi,
        ),
        const Padding(padding: EdgeInsets.only(left: 10)),
        Text(
          widget.options[index],
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const Padding(padding: EdgeInsets.only(left: 10)),
        IconButton(
          onTap: () => setOption(index + 1),
          icon: const Icon(Icomoon.arrow, size: 30),
          iconRotation: .5 * pi,
        ),
      ]),
    );
  }
}


typedef GestureTapCallback = void Function();

class IconButton extends StatelessWidget {
  late Icon icon;
  late double iconRotation;
  late GestureTapCallback? onTap = () {};

  IconButton(
      {super.key, required this.icon, this.onTap, this.iconRotation = 0});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(6))),
          child: Transform.rotate(
            angle: iconRotation,
            child: icon,
          )),
    );
  }
}
