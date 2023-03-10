import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';

class CustomInputField extends StatefulWidget {
  String initialValue;
  String? label;
  Function(String) onChange;

  CustomInputField(
      {super.key, required this.onChange, this.initialValue = "", this.label});

  @override
  State<StatefulWidget> createState() =>
      _CustomInputFieldState(onChange: onChange);
}

class _CustomInputFieldState extends State<CustomInputField> {
  late Function(String) onChange;

  _CustomInputFieldState({required this.onChange});

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
        if (widget.label != null)
          Padding(
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
                            widget.label!,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          )),
                    ],
                  ))),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(width: 2)),
            child: EditableText(
                onChanged: (value) {
                  log("changed $value");
                  onChange(value);
                },
                onEditingComplete: () {
                  log("complete");
                  focusNode.unfocus();
                  onChange(controller.value.text);
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
