import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geo_steps/src/presentation/components/buttons.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/utils/sizing.dart';
import 'package:intl/intl.dart';

class CalenderWidget extends StatefulWidget {
  DateTime date;
  String? dateName;

  void Function(DateTime) onClose;

  CalenderWidget(this.date, {super.key, required this.onClose, this.dateName});

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
    "October",
    "November",
    "December"
  ];
  final year = ValueNotifier<int>(2022);
  int month = 0;
  int day = 1;

  @override
  void initState() {
    super.initState();
    year.value = widget.date.year;
    month = widget.date.month;
    day = widget.date.day;
  }

  void dayStillInRange() {
    // check whether after month/ year change,
    // a day is still in the months range of days
    // and set it to the highest possible if not
    var daysInThisMonth = DateUtils.getDaysInMonth(year.value, month);
    if (daysInThisMonth < day) {
      setState(() {
        day = daysInThisMonth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeHelper sizer = SizeHelper();
    var width = sizer.width - 30;
    var firstOfMonth = DateTime(year.value, month);
    var prevMonth = month - 1;
    var daysInPreviousMonth =
        DateUtils.getDaysInMonth(year.value, prevMonth != 0 ? prevMonth : 12);
    var daysInThisMonth = DateUtils.getDaysInMonth(year.value, month);
    var firstInCalender = -(firstOfMonth.weekday - 1);
    // days of this month get padded with days of previous and next month
    return Positioned(
      top: 80,
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
                child: ValueListenableBuilder(
                  valueListenable: year,
                  builder: ((context, value, widget) {
                    return OptionsWidget(
                      yearOptions,
                      index: yearOptions.indexOf(value.toString()),
                      indexChanged: (index) {
                        year.value = int.parse(yearOptions[index]);
                        dayStillInRange();
                      },
                    );
                  }),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: OptionsWidget(
                  monthOptions,
                  index: month - 1,
                  indexChanged: (index) {
                    setState(() {
                      if (month == monthOptions.length && index + 1 == 1) {
                        // month wrapped at top
                        // -> year++
                        year.value++;
                      } else if (index + 1 == monthOptions.length &&
                          month == 1) {
                        // month wrapped at bottom
                        // -> year--
                        year.value--;
                      }
                      month = index + 1;
                    });
                    dayStillInRange();
                  },
                ),
              ),
              Container(
                  width: width,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Flex(
                        direction: Axis.horizontal,
                        children: List.generate(7, (index) {
                          return Expanded(
                              child: Text(
                            ["M", "T", "W", "T", "F", "S", "S"][index],
                            textAlign: TextAlign.center,
                          ));
                        }),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      height: 240,
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
                          if (i > daysInThisMonth - 1) {
                            enabled = false;
                          }
                          // var week =  (index / 7).ceil(); // 1: 0-6 2: 7-13 ...
                          // var dayOfWeek = (firstOfMonth.weekday-1 + index) % 6; // 0: monday 1: tuesday ...
                          return IconButtonWidget(
                              onTap: enabled
                                  ? () => setState(() {
                                        day = thisDay;
                                      })
                                  : null,
                              color: enabled && thisDay == day
                                  ? Colors.black
                                  : Colors.white,
                              icon: Center(
                                child: Text(
                                  thisDay.toString(),
                                  style: TextStyle(
                                      color: enabled
                                          ? (thisDay == day
                                              ? Colors.white
                                              : Colors.black)
                                          : Colors.grey),
                                ),
                              ));
                        }),
                      ),
                    ),
                  ])),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    IconButtonWidget(
                        onTap: () => widget.onClose(DateTime(year.value, month, day)),
                        width: width - 40,
                        height: 40,
                        icon: Center(
                          child: Text(
                            "Set ${widget.dateName ?? "Date"}",
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
