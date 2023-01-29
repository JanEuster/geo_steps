import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/calender.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/presentation/components/map.dart';
import 'package:geo_steps/src/utils/sizing.dart';
import 'package:intl/intl.dart';

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
  late DateTime startDate;
  late DateTime endDate;
  bool showCalenderModal = false;
  bool startDateSet = false;

  @override
  void initState() {
    super.initState();
    startDate = DateTime.now();
    endDate = startDate;
  }

  Widget generateCategoryOption(OverviewCategory cat) {
    bool selected = selectedCategory == cat;
    return Expanded(
      flex: selected ? 4 : 3,
      child: GestureDetector(
        onTap: () => setState(() {
          selectedCategory = cat;
          showCalenderModal = false; // hide calender when category is changed
          startDateSet = false;
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
                        // all time does not need a calender, therefore the calender is greyed out
                        // and tapping the icon does not open the modal when this category is selected
                        if (selectedCategory != OverviewCategory.AllTime) {
                          showCalenderModal = !showCalenderModal;
                        }
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
                    generateCategoryOption(OverviewCategory.Day),
                    const LineVertical(),
                    generateCategoryOption(OverviewCategory.Range),
                    const LineVertical(),
                    generateCategoryOption(OverviewCategory.AllTime),
                  ],
                )),
            const Line(),
          ]),
          Column(
            children: [
              const Padding(padding: EdgeInsets.only(top: 46)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Text(
                  startDate != endDate
                      ? "${DateFormat.yMEd().format(startDate).replaceAll("/", ".")} — ${DateFormat.yMEd().format(endDate).replaceAll("/", ".")}"
                      : DateFormat.yMEd()
                          .format(startDate)
                          .replaceAll("/", "."),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic),
                ),
              )
            ],
          ),
          if (showCalenderModal)
            CalenderWidget(
              startDate,
              dateName: selectedCategory == OverviewCategory.Range
                  ? (startDateSet ? "End Date" : "Start Date")
                  : null,
              onClose: (date) => setState(() {
                if (selectedCategory == OverviewCategory.Range) {
                  if (startDateSet) {
                    endDate = date;
                    showCalenderModal = false;
                    startDateSet = false;
                  } else {
                    startDate = date;
                    startDateSet = true;
                  }
                } else {
                  startDate = date;
                  endDate = date;
                  showCalenderModal = false;
                }
              }),
            ),
        ]),
      ),
    ]);
  }
}
