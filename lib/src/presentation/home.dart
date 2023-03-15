import 'dart:math' show pi;
import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/map.dart';
import 'package:geo_steps/src/application/preferences.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/application/background_tasks.dart';

import '../utils/sizing.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool? isTrackingLocation;
  late LocationService locationService;

  @override
  void initState() {
    super.initState();

    locationService = LocationService();

    AppSettings.instance.trackingLocation.get().then((value) {
      isTrackingLocation = value;
      locationService.init().then((value) =>
          locationService.loadToday().then((value) => setState(() {})));
    });
  }

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    return ListView(children: [
      Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(locationService.stepsTotal.toString(),
                      style: const TextStyle(
                          fontSize: 75, fontWeight: FontWeight.w900)),
                  Text(
                      "${(locationService.distanceTotal / 1000).toStringAsFixed(1)} km",
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w700)),
                ],
              ),
              Container(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text("steps today", style: TextStyle())),
                      Padding(
                          padding: EdgeInsets.only(top: 35),
                          child: Text("traveled today", style: TextStyle()))
                    ],
                  )),
            ],
          )),
      Padding(
          padding: const EdgeInsets.all(30),
          child: Container(
              width: sizer.width,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: Column(
                children: [
                  Container(
                      width: sizer.width,
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("tracking uptime",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const Padding(padding: EdgeInsets.only(top: 12)),
                          Row(
                            children: const [
                              Text("24 ",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700)),
                              Text("days",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400)),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.only(top: 6)),
                          Row(
                            children: const [
                              Text("154.00 ",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700)),
                              Text("steps",
                                  textAlign: TextAlign.left,
                                  style:
                                      TextStyle(fontWeight: FontWeight.w400)),
                            ],
                          ),
                          SizedBox(
                              height: 40,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Transform.rotate(
                                      angle: 0.5 * pi,
                                      child:
                                          const Icon(Icomoon.arrow, size: 30)),
                                  const Padding(
                                      padding:
                                          EdgeInsets.only(left: 5, bottom: 2),
                                      child: Text("more info",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500))),
                                ],
                              )),
                        ],
                      )),
                  Container(
                      width: sizer.width,
                      height: 40,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/line_pattern.jpg"),
                              repeat: ImageRepeat.repeat))),
                  if (isTrackingLocation != null)
                    GestureDetector(
                      onTap: () {
                        if (isTrackingLocation != null) {
                          setState(() {
                            isTrackingLocation = !isTrackingLocation!;
                          });
                          AppSettings.instance.trackingLocation
                              .set(isTrackingLocation!);

                          log("isTrackingLocation: $isTrackingLocation");
                          if (isTrackingLocation == true) {
                            log("startTracking");
                            FlutterBackgroundService().startService();
                          } else {
                            FlutterBackgroundService().invoke("stopService");
                            AwesomeNotifications().cancel(75415);
                            AwesomeNotifications().cancelAll();
                          }
                        }
                      },
                      child: Container(
                          width: sizer.width,
                          height: 40,
                          color: Colors.white,
                          child: Center(
                              child: Text(
                                  isTrackingLocation!
                                      ? "stop tracking"
                                      : "start tracking",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500)))),
                    ),
                ],
              ))),
      if (locationService.isInitialized)
        ActivityMap(locationService: locationService),
      const Padding(padding: EdgeInsets.only(bottom: 50)),
    ]);
  }
}

class ActivityMap extends StatefulWidget {
  final LocationService locationService;

  ActivityMap({super.key, required this.locationService});

  @override
  State<StatefulWidget> createState() => _ActivityMapState();
}

class _ActivityMapState extends State<ActivityMap> {
  List<LocationDataPoint> dataToday = [];

  @override
  void initState() {
    super.initState();
    widget.locationService.loadToday().then((wasLoaded) {
      if (wasLoaded) {
        setState(() {
          dataToday = widget.locationService.dataPoints;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    log("positions: ${dataToday.length}");
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed("/today"),
      child: SizedBox(
          height: 320,
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: sizer.width,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black)),
                child: dataToday.isNotEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              child: const Text("todays map",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500))),
                          Container(
                            decoration: const BoxDecoration(
                                border: Border(left: BorderSide(width: 1))),
                            width: sizer.width / 5 * 3,
                            child: MapPreview(data: dataToday),
                          )
                        ],
                      )
                    : const Text("no data for today"),
              ))),
    );
  }
}
