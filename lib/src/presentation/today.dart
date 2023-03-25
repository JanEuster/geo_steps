import 'dart:developer';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geo_steps/src/application/homepoints.dart';
import 'package:geo_steps/src/presentation/components/helper.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:intl/intl.dart';

// local imports
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/application/preferences.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/presentation/components/stats.dart';
import 'package:geo_steps/src/presentation/components/map.dart';
import 'package:geo_steps/src/utils/sizing.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<StatefulWidget> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(padding: EdgeInsets.zero, children: [
      TodaysMap(),
    ]);
  }
}

class TodaysMap extends StatefulWidget {
  late DateTime date;

  TodaysMap({super.key, showDate}) {
    if (showDate != null) {
      date = showDate;
    } else {
      date = DateTime.now();
    }
  }

  @override
  State<StatefulWidget> createState() => _TodaysMapState();
}

class _TodaysMapState extends State<TodaysMap>
    with SingleTickerProviderStateMixin {
  late Animation<double> detailsAnimation;
  late AnimationController detailsController;

  late LocationService locationService;
  late TargetPlatform defaultTargetPlatform = TargetPlatform.iOS;
  HomepointManager? homepointManager;
  final mapController = MapController();
  static const double mapHeightDetails = 150;

  bool showDetails = false;
  LocationDataPoint? selectedMinute;

  latlng.LatLng markerPosition = latlng.LatLng(0, 0);
  List<LocationDataPoint>? minutes;

  @override
  void initState() {
    super.initState();

    locationService = LocationService();
    locationService
        .init()
        .whenComplete(() =>
        locationService.loadToday().then((wasLoaded) {
          if (wasLoaded && locationService.hasPositions) {
            setState(() =>
                mapController.move(
                    latlng.LatLng(locationService.lastPos!.latitude,
                        locationService.lastPos!.longitude),
                    12.8));
            minutes = locationService.dataPointPerMinute;

            final firstP = locationService.dataPoints.first;
            markerPosition =
                latlng.LatLng(firstP.latitude, firstP.longitude);
          }
        }));

    AppSettings().trackingLocation.get().then((isTrackingLocation) {
      if (isTrackingLocation != true) {
        FlutterBackgroundService().on("sendTrackingData").listen((event) {
          setState(() {
            List<dynamic> receivedDataPoints = event!["trackingData"];
            var changed = locationService.dataPointsFromKV(receivedDataPoints);
            if (changed) {
              mapController.move(
                  latlng.LatLng(locationService.lastPos!.latitude,
                      locationService.lastPos!.longitude),
                  14.5);
            }
          });
        });
        Timer.periodic(const Duration(seconds: 10), (timer) {
          FlutterBackgroundService().invoke("requestTrackingData");
        });
      }
    });

    // locationService.record(onReady: (p) {
    //   mapController.move(
    //       LatLng(p.latitude, p.longitude), 12.8);
    // });

    detailsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    detailsAnimation = Tween<double>(
        begin: mapHeightDetails + 58,
        end: SizeHelper().heightWithoutNav - 200)
        .animate(detailsController)
      ..addListener(() {
        setState(() {});
      });

    homepointManager = HomepointManager();
    homepointManager!.init().then((value) =>
        homepointManager!.load().then((value) =>
            setState(() {
              homepointManager!.getVisits(locationService.dataPoints);
            }))
    );
  }

  @override
  void dispose() {
    // locationService.stopRecording();

    super.dispose();
  }

  void toggleDetailsOpen() {
    if (!showDetails) {
      detailsController.forward();
    } else {
      detailsController.reverse();
    }
    setState(() {
      showDetails = !showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    defaultTargetPlatform = Theme
        .of(context)
        .platform;
    SizeHelper sizer = SizeHelper();
    return SizedBox(
      height: sizer.heightWithoutNav,
      child: Stack(
        children: [
          Positioned(
            child: SizedBox(
                width: sizer.width,
                height: sizer.heightWithoutNav - detailsAnimation.value,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                      onMapReady: () {
                        // set initial position on map
                      },
                      zoom: 13.0,
                      maxZoom: 19.0,
                      keepAlive: true,
                      interactiveFlags: // all interactions except rotation
                      InteractiveFlag.all & ~InteractiveFlag.rotate),
                  nonRotatedChildren: [
                    CustomAttributionWidget.defaultWidget(
                      source: '© OpenStreetMap contributors',
                      sourceTextStyle: const TextStyle(
                          fontSize: 12, color: Color(0xFF0078a8)),
                      onSourceTapped: () {},
                    ),
                  ],
                  children: [
                    TileLayer(
                      urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'dev.janeuster.geo_steps',
                    ),
                    // kinda cool, shit res outside us, unknown projection - /{z}/{y}/{x} does not work
                    // TileLayer(urlTemplate: "https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/4/5/5?blankTile=false",
                    //   userAgentPackageName: 'dev.janeuster.geo_steps'),
                    // ),
                    PolylineLayer(
                      polylineCulling: false,
                      polylines: [
                        Polyline(
                          points: locationService.latLngList,
                          color: Colors.black,
                          strokeWidth: 8,
                        ),
                        Polyline(
                          points: locationService.latLngList,
                          color: Colors.white,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                    if (locationService.hasPositions)
                      MarkerLayer(
                        markers: [
                          Marker(
                              width: 46,
                              height: 46,
                              point: markerPosition,
                              builder: (context) =>
                                  Transform.translate(
                                    offset: const Offset(0, -23),
                                    child: Container(
                                        decoration: const BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage(
                                                    "assets/map_pin.png")))),
                                  )),
                          if (selectedMinute != null)
                            Marker(
                                point: markerPosition,
                                builder: (context) =>
                                    Transform.translate(
                                      offset: const Offset(28, -30),
                                      child: SizedBox(
                                        height: 40,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            SizedBox(
                                                child: CustomPaint(
                                                    painter:
                                                    MapMarkerTriangle())),
                                            Positioned(
                                                left: 18,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 4,
                                                      vertical: 2),
                                                  width: 60,
                                                  height: 38,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      if (selectedMinute!
                                                          .timestamp !=
                                                          null)
                                                        Text(
                                                          DateFormat("HH:mm")
                                                              .format(
                                                              selectedMinute!
                                                                  .timestamp!),
                                                          style: const TextStyle(
                                                              fontSize: 9,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w500),
                                                        ),
                                                      Text(
                                                        selectedMinute!
                                                            .pedStatus,
                                                        style: const TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                            FontWeight
                                                                .w500),
                                                      ),
                                                      Text(
                                                        "${selectedMinute!
                                                            .steps ?? 0} steps",
                                                        style: const TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                            FontWeight
                                                                .w500),
                                                      )
                                                    ],
                                                  ),
                                                ))
                                          ],
                                        ),
                                      ),
                                    ))
                          // Container(
                          //   width: 40,
                          //   height: 40,
                          //   decoration:
                          //   BoxDecoration(color: Colors.white, border: Border.all()),
                          // )
                        ],
                      )
                  ],
                )),
          ),
          Positioned(
            bottom: 0,
            child: SizedBox(
              height: detailsAnimation.value,
              child: Column(
                children: [
                  GestureDetector(
                      onTap: () => toggleDetailsOpen(),
                      child: Container(
                          width: sizer.width,
                          height: 58,
                          padding: const EdgeInsets.all(5),
                          color: Colors.black,
                          child: Column(
                            children: [
                              Text(
                                  "show ${showDetails
                                      ? "less"
                                      : "more"} info for ${DateFormat
                                      .yMMMMEEEEd().format(widget.date)}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 5)),
                              Transform.rotate(
                                  angle: showDetails ? 0.0 : 1.0 * math.pi,
                                  child: const Icon(
                                    Icomoon.arrow,
                                    color: Colors.white,
                                  )),
                            ],
                          ))),
                  SizedBox(
                    width: sizer.width,
                    height: detailsAnimation.value - 58,
                    child: ListView(
                      padding: const EdgeInsets.only(top: 10),
                      children: [
                        Padding(
                          padding: !showDetails
                              ? EdgeInsets.zero
                              : const EdgeInsets.only(left: 10, bottom: 15),
                          child: Row(
                            children: showDetails
                                ? [
                              OverviewTotals(
                                totalSteps: locationService.stepsTotal,
                                totalDistance:
                                locationService.distanceTotal,
                              ),
                              Expanded(child: Container()),
                            ]
                                : [],
                          ),
                        ),
                        Padding(
                            padding: !showDetails
                                ? EdgeInsets.zero
                                : const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 10),
                            child: showDetails
                                ? const DottedLine(
                              height: 2,
                            )
                                : null),
                        HourlyActivity(
                          data: locationService.hourlyStepsTotal,
                          onScroll: (percentage) {
                            var thisDate = DateTime.now();
                            final millisecondsToday =
                            (percentage * 24 * 60 * 60 * 1000).round();
                            final minutesToday =
                            (percentage * ((24 * 60) - 1)).round();
                            thisDate = DateTime(
                                thisDate.year, thisDate.month, thisDate.day);
                            thisDate = DateTime.fromMillisecondsSinceEpoch(
                                thisDate.millisecondsSinceEpoch +
                                    millisecondsToday);

                            if (locationService.hasPositions) {
                              // log("$minutes");
                              // var newPos = locationService.dataPointClosestTo(thisDate.toLocal());
                              // log("$newPos");
                              if (minutes != null) {
                                setState(() {
                                  selectedMinute = minutes![minutesToday];
                                  markerPosition = latlng.LatLng(
                                      selectedMinute!.latitude,
                                      selectedMinute!.longitude);
                                  mapController.move(markerPosition, 13.5);
                                });
                              }
                            }
                          },
                        ),
                        if (showDetails) ...[
                          const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 10),
                              child: DottedLine(
                                height: 2,
                              )),
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: OverviewBarChart(
                                  data: locationService.hourlyDistanceTotal
                                      .map((e) => e / 1000).toList(),
                                  title: "hourly average speed in km/h")),
                          if (homepointManager != null && homepointManager!.visits != null) Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: NamedBarChart(
                                data: homepointManager!.visits!,
                                title: "visited homepoints today"),
                          ),
                        ],
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
