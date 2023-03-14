import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final mapController = MapController();
  bool showDetails = false;
  static const double mapHeightDetails = 150;

  @override
  void initState() {
    super.initState();

    locationService = LocationService();
    locationService
        .init()
        .whenComplete(() => locationService.loadToday().then((wasLoaded) {
              if (wasLoaded && locationService.hasPositions) {
                setState(() => mapController.move(
                    LatLng(locationService.lastPos!.latitude,
                        locationService.lastPos!.longitude),
                    12.8));
              }
            }));

    AppSettings().trackingLocation.get().then((isTrackingLocation) {
      if (isTrackingLocation != null && isTrackingLocation) {
        FlutterBackgroundService().on("sendTrackingData").listen((event) {
          setState(() {
            List<dynamic> receivedDataPoints = event!["trackingData"];
            var changed = locationService.dataPointsFromKV(receivedDataPoints);
            if (changed) {
              mapController.move(
                  LatLng(locationService.lastPos!.latitude,
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
    defaultTargetPlatform = Theme.of(context).platform;
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
                              point: LatLng(locationService.lastPos!.latitude,
                                  locationService.lastPos!.longitude),
                              builder: (context) => Transform.translate(
                                    offset: const Offset(0, -23),
                                    child: Container(
                                        decoration: const BoxDecoration(
                                            image: DecorationImage(
                                                image: AssetImage(
                                                    "assets/map_pin.png")))),
                                  ))
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
                                  "show ${showDetails ? "less" : "more"} info for ${DateFormat.yMMMMEEEEd().format(widget.date)}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 5)),
                              Transform.rotate(
                                  angle: showDetails ? 0 : 1 * pi,
                                  child: const Icon(
                                    Icomoon.arrow,
                                    color: Colors.white,
                                  )),
                            ],
                          ))),
                  SizedBox(
                    width: sizer.width,
                    height: detailsAnimation.value - 58,
                    child: !showDetails
                        ? const HourlyActivity()
                        : ListView(
                          padding: const EdgeInsets.only(top: 10),
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, bottom: 15),
                                child: Row(
                                  children: [
                                    OverviewTotals(
                                      timeFrameString: "Today",
                                      totalSteps: 6929,
                                      totalDistance: 4200,
                                    ),
                                    Expanded(child: Container()),
                                  ],
                                ),
                              ),
                              const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 10),
                                  child: DottedLine(
                                    height: 2,
                                  )),
                              const HourlyActivity(),
                              const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 10),
                                  child: DottedLine(
                                    height: 2,
                                  )),
                              Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: OverviewBarGraph(data: [
                                    1,
                                    2,
                                    6,
                                    2,
                                    3,
                                    1,
                                    12,
                                    42,
                                    10,
                                    1,
                                    1,
                                    3,
                                    95,
                                    32
                                  ])),
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
