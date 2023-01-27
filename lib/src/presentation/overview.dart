import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/presentation/components/map.dart';
import 'package:geo_steps/src/utils/sizing.dart';

enum OverviewCategory {
  Day,
  Range,
  AllTime,
}

extension OverviewCategoryExtension on OverviewCategory {
  String get name {
    switch (this) {
      case OverviewCategory.Day:
        return "day";
      case OverviewCategory.Range:
        return "range";
      case OverviewCategory.AllTime:
        return "alltime";
    }
    return ""; // never gets called
  }
}

class OverviewPage extends StatefulWidget {
  OverviewPage({super.key});

  @override
  State<StatefulWidget> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  OverviewCategory selectedCategory = OverviewCategory.Day;

  @override
  void initState() {
    super.initState();
  }

  Widget generateCategoryOptions(OverviewCategory cat) {
    Widget option = Expanded(
      flex: 3,
      child: GestureDetector(
        onTap: () => setState(() {
          selectedCategory = cat;
        }),
        child: Container(
            color: Colors.white,
            height: 45,
            child: Center(
              child: Text(cat.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            )),
      ),
    );
    if (cat == selectedCategory) {
      option = Expanded(
        flex: 4,
        child: GestureDetector(
          onTap: () => setState(() {
            selectedCategory = cat;
          }),
          child: Container(
              color: Colors.black,
              height: 45,
              child: Expanded(
                  child: Center(
                child: Text(cat.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ))),
        ),
      );
    }
    return option;
  }

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    return ListView(padding: EdgeInsets.zero, children: [
      SizedBox(
          width: sizer.width,
          height: 45,
          child: Row(
            children: [
              Container(
                  width: 70,
                  color: Colors.white,
                  child: const Icon(Icomoon.calender, size: 32)),
              LineVertical(),
              generateCategoryOptions(OverviewCategory.Day),
              LineVertical(),
              generateCategoryOptions(OverviewCategory.Range),
              LineVertical(),
              generateCategoryOptions(OverviewCategory.AllTime),
            ],
          )),
      const Line(),
    ]);
  }
}
