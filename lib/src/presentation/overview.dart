import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/calender.dart';
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
        return "all";
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
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  bool showCalenderModal = false;

  @override
  void initState() {
    super.initState();
  }

  Widget generateCategoryOptions(OverviewCategory cat) {
    bool selected = selectedCategory == cat;
    return Expanded(
      flex: selected ? 4 : 3,
      child: GestureDetector(
        onTap: () => setState(() {
          selectedCategory = cat;
        }),
        child: Container(
            color: selected ? Colors.black : Colors.white,
            height: 45,
            child: Center(
              child: Text(cat.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.black)),
            )),
      ),
    );
    ;
  }

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    return ListView(padding: EdgeInsets.zero, children: [
      SizedBox(
        height: 650,
        child: Stack(children: [
          Column(children: [
            SizedBox(
                width: sizer.width,
                height: 45,
                child: Flex(
                  direction: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        showCalenderModal = !showCalenderModal;
                      }),
                      child: Container(
                          width: 70,
                          color: Colors.white,
                          child: Icon(Icomoon.calender,
                              size: 32,
                              color:
                                  selectedCategory != OverviewCategory.AllTime
                                      ? Colors.black
                                      : Colors.grey)),
                    ),
                    const LineVertical(),
                    generateCategoryOptions(OverviewCategory.Day),
                    const LineVertical(),
                    generateCategoryOptions(OverviewCategory.Range),
                    const LineVertical(),
                    generateCategoryOptions(OverviewCategory.AllTime),
                  ],
                )),
            const Line(),
          ]),
          Column(children: [
            const Padding(padding: EdgeInsets.only(top: 46)),
            Text(startDate.toString()),
            Text(endDate.toString()),
          ],),
          if (showCalenderModal) CalenderWidget(startDate, onClose: (date) => setState(() {
            startDate = date;
            endDate = date;
            showCalenderModal = false;
          }),),
        ]),
      ),
    ]);
  }
}
