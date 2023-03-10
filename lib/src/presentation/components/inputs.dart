import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/utils/sizing.dart';

import '../../application/location.dart';

class CustomInputField extends StatefulWidget {
  final String initialValue;
  final String? label;
  final Function(String) onChange;

  CustomInputField(
      {super.key, required this.onChange, this.initialValue = "", this.label});

  @override
  State<StatefulWidget> createState() =>
      _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {

  _CustomInputFieldState();

  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();
  TextStyle style = const TextStyle(fontSize: 22, color: Colors.black);
  Color cursorColor = Colors.black;
  Color backgroundCursorColor = Colors.grey;

  @override
  void initState() {
    controller.value = TextEditingValue(text: widget.initialValue);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.label != null) InputLabel(label: widget.label!),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(width: 2)),
            child: EditableText(
                onChanged: (value) {
                  log("changed $value");
                  widget.onChange(value);
                },
                onEditingComplete: () {
                  log("complete");
                  focusNode.unfocus();
                  widget.onChange(controller.value.text);
                },
                controller: controller,
                focusNode: focusNode,
                style: style,
                cursorColor: cursorColor,
                backgroundCursorColor: backgroundCursorColor)),
      ],
    );
  }
}

class CustomSliderInput extends StatefulWidget {
  late double initialValue;
  final MinMax<double> range;
  final String? label;
  final Function(double) onChange;
  final double width;

  CustomSliderInput(
      {super.key,
      required this.onChange,
      required this.range,
      this.label,
      double? initValue,
      this.width = 100}) {
    if (initValue != null) {
      initialValue = initValue;
    } else {
      initialValue = range.min;
    }
  }

  @override
  State<StatefulWidget> createState() =>
      _CustomSliderInputState();
}

class _CustomSliderInputState extends State<CustomSliderInput> {
  double percentage = 0;
  double value = 0;

  _CustomSliderInputState();

  @override
  void initState() {
    setState(() {
      // percentage = widget.initialValue/widget.range.diff;
      percentage = 0.2;
    });

    super.initState();
  }

  void setSliderPosition(double pos, double sliderWidth, double cursorSize) {
    log("$pos");
    setState(() {
      if (pos < cursorSize/2) {
        percentage = 0;
      } else if (pos > sliderWidth - cursorSize/2) {
        percentage = 1;
      } else {
        percentage = (pos - cursorSize / 2) / (sliderWidth-cursorSize);
      }
      value = ((widget.range.min + widget.range.diff * percentage) * 10)
              .roundToDouble() /
          10;
    });
    widget.onChange(value);
  }

  @override
  Widget build(BuildContext context) {
    double borderWidth = 3;
    double cursorSize = 28;
    double sideOffset = 30;
    var sliderWidth = widget.width - 66;
    double sliderPosition = (sliderWidth-cursorSize) * percentage;

    return Column(
      children: [
        if (widget.label != null) InputLabel(label: widget.label!),
        SizedBox(
          height: 50,
          child: Stack(
            children: [
              Positioned(
                  left: 0,
                  top: 31,
                  child: Text(
                      textAlign: TextAlign.start,
                      "${widget.range.min}",
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700))),
              Positioned(
                  right: 0,
                  top: 31,
                  child: Text(
                      textAlign: TextAlign.end,
                      "${widget.range.max}",
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700))),
              Positioned(
                  top: 28,
                  left: sideOffset + cursorSize/2,
                  child: Container(
                    width: sliderWidth - cursorSize,
                    height: 16,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(width: borderWidth),
                        borderRadius: BorderRadius.circular(8)),
                  )),
              Positioned(
                  left: sideOffset + sliderPosition - 3,
                  child: SizedBox(
                    width: sliderWidth,
                    height: 50,
                    child: Stack(
                      children: [
                        Positioned(
                            top: 22,
                            left: 3,
                            child: Container(
                              width: cursorSize,
                              height: cursorSize,
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(width: borderWidth),
                                  borderRadius: BorderRadius.circular(15)),
                            )),
                        if (value != null)
                          Positioned(
                              child: Text(
                                  textAlign: TextAlign.center,
                                  "$value",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700))),
                      ],
                    ),
                  )),
              Positioned(
                top: 20,
                left: sideOffset,
                child: GestureDetector(
                    onTapDown: (details) {
                      setSliderPosition(
                          details.localPosition.dx, sliderWidth, cursorSize);
                    },
                    onHorizontalDragUpdate: (details) {
                      setSliderPosition(
                          details.localPosition.dx, sliderWidth, cursorSize);
                    },
                    child: Container(
                      width: sliderWidth,
                      height: 32,
                      decoration: const BoxDecoration(),
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InputLabel extends StatelessWidget {
  String label;

  InputLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        child: FractionallySizedBox(
            widthFactor: 1,
            child: Row(
              children: [
                Transform.rotate(
                  angle: -math.pi / 2,
                  child: const Icon(
                    Icomoon.small_pin,
                    size: 15,
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    )),
              ],
            )));
  }
}
