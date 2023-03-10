import 'dart:math' show pi;
import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';

import 'package:geo_steps/src/application/preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool? isTrackingLocation;
  LocationService? locationService;

  @override
  void initState() {
    super.initState();

    AppSettings.instance.trackingLocation.get().then((value) {
      setState(() {
        isTrackingLocation = value;
        locationService = LocationService();
        locationService!.init().then((value) => locationService!.loadToday());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    return ListView(children: [
      Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text("3.742",
                      style:
                          TextStyle(fontSize: 75, fontWeight: FontWeight.w900)),
                  Text("10,2 km",
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
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
              width: media.size.width,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: Column(
                children: [
                  Container(
                      width: media.size.width,
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
                      width: media.size.width,
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
                          log("${isTrackingLocation == true}");
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
                          width: media.size.width,
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
                  // GestureDetector(
                  //   onTap: () async {
                  //     // locationService!.loadToday();
                  //     // FlutterBackgroundService().invoke("requestTrackingData");
                  //     // FlutterBackgroundService().on("sendTrackingData").listen((event) async {
                  //     //   locationService!.dataPointsFromKV(event!["trackingData"]);
                  //     //   log("${locationService!.dataPoints.length}");
                  //     //   log("${locationService!.dataPoints.map((e) => e.heading)}");
                  //     //   await locationService!.saveToday();
                  //     //   await locationService!.loadToday();
                  //     // });
                  //     await locationService!.loadToday();
                  //     log("dp len: ${locationService!.dataPoints.length}");
                  //     // locationService!.saveToday();
                  //   },
                  //   child: Container(
                  //       width: media.size.width,
                  //       height: 40,
                  //       color: Colors.white,
                  //       child: const Center(
                  //           child: Text("test data",
                  //               style: TextStyle(
                  //                   fontSize: 20,
                  //                   fontWeight: FontWeight.w500)))),
                  // )
                ],
              ))),
      const ActivityMap()
    ]);
  }
}

class ActivityMap extends StatelessWidget {
  const ActivityMap({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    return SizedBox(
        height: 380,
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
                width: media.size.width,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        child: const Text("todays map",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500))),
                    Container(
                        color: Colors.black,
                        width: media.size.width / 5 * 3,
                        height: 380)
                  ],
                ))));
  }
}
