import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/utils/sizing.dart';

class OverviewTotals extends StatelessWidget {
  final String timeFrameString;
  final int totalSteps;

  /// total distance in meters
  final double totalDistance;

  OverviewTotals(
      {super.key,
      required this.timeFrameString,
      required this.totalSteps,
      required this.totalDistance});

  @override
  Widget build(BuildContext context) {
    var textStyle = const TextStyle(fontWeight: FontWeight.w500, fontSize: 24);
    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: SizedBox(
            width: 140,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "Totals - $timeFrameString",
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const Padding(
                  padding: EdgeInsets.only(top: 5, bottom: 10),
                  child: Line(
                    height: 2,
                  )),
              Text(
                "$totalSteps steps",
                style: textStyle,
              ),
              Text(
                "${(totalDistance / 1000).toStringAsFixed(1)} km",
                style: textStyle,
              ),
            ]),
          ),
        ));
  }
}

class NamedBarGraph extends StatelessWidget {
  final String title;
  final double height;
  final bool scrollable;

  /// only takes effect when scrollable=true
  final List<MapEntry<String, int>> data;
  late List<String> dataKeys;
  late List<int> dataValues;
  late double max;

  NamedBarGraph(
      {super.key,
      required this.data,
      this.title = "geo_steps stats",
      this.scrollable = false,
      this.height = 150}) {
    dataKeys = data.map((e) => e.key).toList();
    dataValues = data.map((e) => e.value).toList();
    max = MinMax.fromList(dataValues.map((e) => e.toDouble()).toList()).max;
  }


  @override
  Widget build(BuildContext context) {
    var textStyleOnWhite = const TextStyle(
        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500);
    var textStyleOnBlack =
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    final double rowHeight = 28;
    var sizer = SizeHelper();
    return SizedBox(
      height: height,
      child: SizedBox(
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      data.length,
                      (index) => Container(
                          alignment: Alignment.center,
                          height: rowHeight,
                          child: Text(dataKeys[index], style: textStyleOnBlack,)),
                    ),
                  ),
                ),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                      data.length,
                      (index) => FractionallySizedBox(
                            widthFactor: dataValues[index] / max,
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Container(
                                  height: rowHeight - 8,
                                  decoration:
                                      const BoxDecoration(color: Colors.black),
                                )),
                          )),
                )),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      data.length,
                      (index) => Container(
                          alignment: Alignment.center,
                          height: rowHeight,
                          child: Text(dataValues[index].toString(), style: textStyleOnBlack)),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: 18,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: textStyleOnWhite),
                  Text("${data.length} bars", style: textStyleOnWhite)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class OverviewBarGraph extends StatelessWidget {
  final String title;
  final double height;
  final bool scrollable;

  /// only takes effect when scrollable=true
  final double scrollWidth;
  final List<double> data;
  late MinMax<double> valuesMinMax;

  OverviewBarGraph(
      {super.key,
      required this.data,
      this.title = "geo_steps stats",
      this.scrollable = false,
      this.scrollWidth = 600,
      this.height = 150}) {
    valuesMinMax = MinMax.fromList(data);
  }

  @override
  Widget build(BuildContext context) {
    var textStyleOnWhite = const TextStyle(
        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500);
    var textStyleOnBlack =
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    var sizer = SizeHelper();
    return SizedBox(
      height: height,
      child: SizedBox(
        child: Column(
          children: [
            Expanded(
                child: Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10, left: 4, right: 0),
                    child: SizedBox(
                      child: Row(
                        children: [
                          Column(
                            verticalDirection: VerticalDirection.up,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(4, (i) {
                              String value;
                              if (i == 0) {
                                value =
                                    valuesMinMax.min.toStringAsFixed(1);
                              } else if (i == 3) {
                                value =
                                    valuesMinMax.max.toStringAsFixed(1);
                              } else {
                                value = (valuesMinMax.diff / 3 * i)
                                    .toStringAsFixed(1);
                              }
                              return Text(
                                value,
                                style: textStyleOnBlack,
                              );
                            }),
                          ),
                          scrollable
                              ? Expanded(
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      SizedBox(
                                          width: scrollWidth,
                                          child: BarChart(data: data)),
                                    ],
                                  ),
                                )
                              : Expanded(child: BarChart(data: data))
                        ],
                      ),
                    ))),
            Container(
              height: 18,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: textStyleOnWhite),
                  Text("${data.length} bars", style: textStyleOnWhite)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class BarChart extends StatelessWidget {
  final List<double> data;
  late MinMax<double> valuesMinMax;

  BarChart({super.key, required this.data}) {
    valuesMinMax = MinMax.fromList(data);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((e) {
        var heightFactor = (((e - valuesMinMax.min) / valuesMinMax.max) * 100)
                .roundToDouble() /
            100;
        if (heightFactor < 0.013) {
          heightFactor = 0.013;
        }
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 3),
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              child: Container(
                constraints: const BoxConstraints(
                    minHeight: 1, minWidth: 1, maxWidth: 40),
                color: Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class HourlyActivity extends StatefulWidget {
  final double hourWidth = 50;
  final List<double> data;
  late double max;

  HourlyActivity({super.key, required this.data}) {
    max = MinMax.fromList(data).max;
  }

  @override
  State<StatefulWidget> createState() => _HourlyActivityState();
}

class _HourlyActivityState extends State<HourlyActivity> {
  ScrollController scrollController =
      ScrollController(initialScrollOffset: 715);
  bool isScrolling = false;
  int selectedHourIndex = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollController.addListener(() {
        if (scrollController.position.pixels ==
                scrollController.position.maxScrollExtent ||
            scrollController.position.pixels ==
                scrollController.position.minScrollExtent) {
          setSelectedHour();
        }
      });
      scrollController.position.isScrollingNotifier.addListener(() {
        if (scrollController.positions.isNotEmpty) {
          var scrollBool = scrollController.position.isScrollingNotifier.value;
          if (scrollBool != isScrolling) {
            setState(() {
              isScrolling = scrollBool;
            });
            if (scrollBool == false) {
              setSelectedHour();
            }
          }
        }
      });
      setSelectedHour();
    });
    super.initState();
  }

  setSelectedHour() {
    var pixels = scrollController.position.pixels + widget.hourWidth / 2;
    int newIndex =
        (pixels / scrollController.position.maxScrollExtent * 23).floor();
    setState(() {
      selectedHourIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    return SizedBox(
        width: sizer.width,
        height: 139,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          child: ListView.builder(
              itemCount: 24,
              padding: EdgeInsets.symmetric(
                  horizontal: sizer.width / 2 - 25, vertical: 0),
              scrollDirection: Axis.horizontal,
              controller: scrollController,
              itemBuilder: (BuildContext context, int index) {
                List<double> hoursPercent = widget.data.map((h) => h/widget.max).toList();
                return Container(
                  padding: index < 23
                      ? const EdgeInsets.only(right: 5)
                      : const EdgeInsets.all(0),
                  height: 139,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Padding(padding: EdgeInsets.only(bottom: 5)),
                      Container(
                          color: index == selectedHourIndex
                              ? Colors.black
                              : Colors.white,
                          width: widget.hourWidth,
                          height: 3),
                      SizedBox(
                          height: 105,
                          child: Column(children: [
                            Expanded(
                                child: Container(
                              width: widget.hourWidth,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black, width: 1)),
                            )),
                            Container(
                                width: widget.hourWidth,
                                height: 105 * hoursPercent[index],
                                constraints: const BoxConstraints(minHeight: 0, maxHeight: 105),
                                color: index == selectedHourIndex
                                    ? null
                                    : Colors.black,
                                decoration: index == selectedHourIndex
                                    ? BoxDecoration(
                                        border: Border.all(
                                            color: Colors.black, width: 1),
                                        image: const DecorationImage(
                                            fit: BoxFit.none,
                                            scale: 2.5,
                                            image: AssetImage(
                                                "assets/line_pattern.jpg"),
                                            repeat: ImageRepeat.repeat))
                                    : null),
                          ])),
                      SizedBox(height: 16, child: Text("$index"))
                    ],
                  ),
                );
              }),
        ));
  }
}
