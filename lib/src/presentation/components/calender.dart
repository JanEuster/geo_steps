import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/buttons.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/utils/sizing.dart';

class CalenderWidget extends StatefulWidget {
  DateTime date;
  void Function(DateTime) onClose;

  CalenderWidget(this.date, {super.key, required this.onClose});

  @override
  State<StatefulWidget> createState() => CalenderWidgetState();
}

class CalenderWidgetState extends State<CalenderWidget> {
  List<String> yearOptions = ["2020", "2021", "2022", "2023"];
  List<String> monthOptions = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "November",
    "December"
  ];
  int year = 2022;
  int month = 0;
  int day = 1;

  @override
  void initState() {
    super.initState();
    year = widget.date.year;
    month = widget.date.month;
    day = widget.date.day;
  }

  @override
  Widget build(BuildContext context) {
    SizeHelper sizer = SizeHelper();
    var width = sizer.width - 30;
    var firstOfMonth = DateTime(year, month);
    var prevMonth = month - 1;
    var daysInPreviousMonth =
        DateUtils.getDaysInMonth(year, prevMonth != 0 ? prevMonth : 12);
    var daysInThisMonth = DateUtils.getDaysInMonth(year, month);
    var firstInCalender = -(firstOfMonth.weekday - 1);
    // days of this month get padded with days of previous and next month

    return Positioned(
      top: 60,
      left: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(10))),
        child: Center(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: OptionsWidget(
                  yearOptions,
                  index: yearOptions.indexOf(year.toString()),
                  indexChanged: (index) => setState(() {
                    year = int.parse(yearOptions[index]);
                  }),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: OptionsWidget(
                  monthOptions,
                  index: month - 1,
                  indexChanged: (index) => setState(() {
                    month = index + 1;
                  }),
                ),
              ),
              Container(
                  width: width,
                  height: 240,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GridView.count(
                    padding: const EdgeInsets.only(top: 10),
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 4 / 3,
                    children: List.generate(6 * 7, (index) {
                      var i = firstInCalender + index;
                      int thisDay;
                      bool enabled = true;
                      if (i < 0) {
                        // this day of the week is
                        thisDay = daysInPreviousMonth + i;
                        enabled = false;
                      } else {
                        thisDay = (i % daysInThisMonth) + 1;
                      }
                      if (i > daysInThisMonth-1) {
                        enabled = false;
                      }
                      // var week =  (index / 7).ceil(); // 1: 0-6 2: 7-13 ...
                      // var dayOfWeek = (firstOfMonth.weekday-1 + index) % 6; // 0: monday 1: tuesday ...
                      return IconButtonWidget(
                        onTap: enabled ? () => setState(() {
                          day = thisDay;
                        }) : null,
                        color: enabled && thisDay == day ? Colors.black : Colors.white,
                          icon: Center(
                        child: Text(
                          thisDay.toString(),
                          style: TextStyle(color: enabled ? (thisDay == day ? Colors.white : Colors.black) : Colors.grey),
                        ),
                      ));
                    }),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    IconButtonWidget(
                      onTap: () => widget.onClose(DateTime(year, month, day)),
                      width: width-40,
                      height: 40,
                        icon: const Center(
                      child: Text(
                        "Set Date",
                      ),
                    ))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
