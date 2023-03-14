import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/presentation/components/calender.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/presentation/components/map.dart';
import 'package:geo_steps/src/presentation/components/overview_stats.dart';
import 'package:geo_steps/src/utils/datetime.dart';
import 'package:geo_steps/src/utils/sizing.dart';
import 'package:geolocator/geolocator.dart';
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
  const OverviewPage({super.key});

  @override
  State<StatefulWidget> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  OverviewCategory selectedCategory = OverviewCategory.Day;
  late DateTime startDate;
  late DateTime endDate;
  bool showCalenderModal = false;
  bool startDateSet = false;
  LocationService? locationService;

  @override
  void initState() {
    super.initState();
    startDate = DateTime.now();
    endDate = startDate;
    locationService = LocationService();
    locationService!.init().whenComplete(() {
      setData();
    });
  }

  void setData() async {
    // TODO: get data for any date / range
    if (selectedCategory == OverviewCategory.Day &&
        startDate.isSameDate(DateTime.now())) {
      await locationService!.loadToday();
      setState(() {});
    } else {
      locationService?.clearData();
    }
    log("$locationService");
  }

  void changeCategory(OverviewCategory cat) {
    setState(() {
      if (selectedCategory == OverviewCategory.Range &&
          cat == OverviewCategory.Day) {
        // set startDate = endDate when switching from range to day
        endDate = startDate;
      }
      selectedCategory = cat;
      showCalenderModal = false; // hide calender when category is changed
      startDateSet = false;
    });
    log("change Category");
    setData();
  }

  Widget generateCategoryOption(OverviewCategory cat) {
    bool selected = selectedCategory == cat;
    return Expanded(
      flex: selected ? 4 : 3,
      child: GestureDetector(
        onTap: () => changeCategory(cat),
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
    var timeFrameString = startDate != endDate
        ? "${DateFormat.yMMMEd().format(startDate).replaceAll("/", ".")} — ${DateFormat.yMMMEd().format(endDate).replaceAll("/", ".")}"
        : DateFormat.yMEd().format(startDate).replaceAll("/", ".");
    return ListView(padding: EdgeInsets.zero, children: [
      SizedBox(
        height: showCalenderModal ? 580 : null,
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
                  timeFrameString,
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
              onClose: (date) {
                setState(() {
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
                });
                setData();
              },
            ),
        ]),
      ),
      if (locationService != null && locationService!.hasPositions)
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 15),
              child: Row(
                children: [
                  OverviewTotals(
                    timeFrameString: timeFrameString,
                    totalSteps: 6929,
                    totalDistance: 4200,
                  ),
                  Expanded(child: Container()),
                ],
              ),
            ),
            ActivityMap(data: locationService!.dataPoints),
            Padding(
                padding: const EdgeInsets.all(10),
                child: OverviewBarGraph(
                    scrollable: true,
                    data: [1, 2, 6, 2, 3, 1, 12, 42, 10, 1, 1, 3, 95, 32])),
          ],
        )
    ]);
  }
}

class ActivityMap extends StatelessWidget {
  List<LocationDataPoint> data = [];

  ActivityMap({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    log("positions: ${data.length}");
    return GestureDetector(
      onTap: () => null,
      child: SizedBox(
          height: 175,
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: sizer.width,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black)),
                child: data.isNotEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              child: const Text("view map",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500))),
                          Container(
                            decoration: const BoxDecoration(
                                border: Border(left: BorderSide(width: 1))),
                            width: sizer.width / 5 * 3,
                            child: MapPreview(data: data, zoomMultiplier: 0.95),
                          )
                        ],
                      )
                    : const Text("no data for today"),
              ))),
    );
  }
}
