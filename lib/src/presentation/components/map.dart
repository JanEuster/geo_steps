// flutter imports
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

// local imports
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/application/preferences.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/utils/map.dart';
import 'package:geo_steps/src/utils/sizing.dart';

class MapPreview extends StatefulWidget {
  List<LocationDataPoint> data = [];
  late double zoomMultiplier;

  MapPreview({super.key, required this.data, this.zoomMultiplier = 1});

  @override
  State<StatefulWidget> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  final mapController = MapController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        var coordRange = getCoordRange(widget.data);
        mapController.move(getCoordCenter(coordRange),
            widget.zoomMultiplier * getZoomLevel(coordRange));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeHelper sizer = SizeHelper();
    return Container(
      color: Colors.black,
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
            InteractiveFlag.none),
        nonRotatedChildren: [
          CustomAttributionWidget.defaultWidget(
            source: 'geo_steps',
            sourceTextStyle:
            const TextStyle(fontSize: 12, color: Color(0xFF0078a8)),
            onSourceTapped: () {},
          ),
        ],
        children: [
          // TileLayer(
          //   urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          //   userAgentPackageName: 'dev.janeuster.geo_steps',
          // ),

          PolylineLayer(
            polylineCulling: false,
            polylines: [
              Polyline(
                points: widget.data.toLatLng(),
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
          // if (locationService.hasPositions)
          //   MarkerLayer(
          //     markers: [
          //       Marker(
          //           point: LatLng(locationService.lastPos.latitude,
          //               locationService.lastPos.longitude),
          //           builder: (context) => const FlutterLogo())
          //     ],
          //   )
        ],
      ),
    );
  }
}

class SimpleMap extends StatefulWidget {
  late DateTime date;

  SimpleMap({super.key, showDate}) {
    if (showDate != null) {
      date = showDate;
    } else {
      date = DateTime.now();
    }
  }

  @override
  State<StatefulWidget> createState() => _SimpleMapState();
}

class _SimpleMapState extends State<SimpleMap>
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
        .whenComplete(() =>
        locationService.loadToday().then((wasLoaded) {
          if (wasLoaded && locationService.hasPositions) {
            setState(() =>
                mapController.move(
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
    log("before $showDetails");
    setState(() {
      showDetails = !showDetails;
    });
    log("after $showDetails");
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
                              point: LatLng(locationService.lastPos!.latitude,
                                  locationService.lastPos!.longitude),
                              builder: (context) =>
                                  Transform.translate(
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
                      children: [
                        const Padding(
                            padding: EdgeInsets.only(bottom: 10)),
                        const HourlyActivity(),
                        if (showDetails)
                          Column(
                            children: const [
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 10),
                                  child: DottedLine(
                                    height: 2,
                                  )),
                            ],
                          )
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

class HourlyActivity extends StatefulWidget {
  final double hourWidth = 50;

  const HourlyActivity({super.key});

  @override
  State<StatefulWidget> createState() => _HourlyActivityState();
}

class _HourlyActivityState extends State<HourlyActivity> {
  ScrollController scrollController =
  ScrollController(initialScrollOffset: 700);
  bool isScrolling = false;
  int selectedHourIndex = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollController.addListener(() {
        if (scrollController.position.pixels == scrollController.position.maxScrollExtent || scrollController.position.pixels == scrollController.position.minScrollExtent) {
          setSelectedHour();
        }
      });
      scrollController.position.isScrollingNotifier.addListener(() {
        if (scrollController.positions.isNotEmpty) {
          var scrollBool = scrollController.position.isScrollingNotifier
              .value;
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
    });
    super.initState();
  }

  setSelectedHour() {
    var pixels = scrollController.position.pixels + widget.hourWidth/2;
    int newIndex = (pixels /
        scrollController.position.maxScrollExtent * 23).floor();
    setState(() {
      selectedHourIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    return SizedBox(
        width: sizer.width,
        height: 120,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          child: ListView.builder(
              itemCount: 24,
              padding: EdgeInsets.symmetric(
                  horizontal: sizer.width / 2 - 25, vertical: 0),
              scrollDirection: Axis.horizontal,
              controller: scrollController,
              itemBuilder: (BuildContext context, int index) {
                List<double> hours = [
                  0,
                  0,
                  0,
                  0,
                  0,
                  .1,
                  .4,
                  .6,
                  0,
                  0,
                  .1,
                  0,
                  .3,
                  1,
                  .5,
                  1,
                  .1,
                  .3,
                  .2,
                  0,
                  0,
                  0,
                  0,
                  0
                ]; // TODO: use real data
                return Padding(
                  padding: index < 23
                      ? const EdgeInsets.only(right: 5)
                      : const EdgeInsets.all(0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                          child: Container(
                            width: widget.hourWidth,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.black,
                                    width: index == selectedHourIndex ? 3 : 1)),
                          )),
                      Container(
                          width: widget.hourWidth,
                          height: 90 * hours[index],
                          color: Colors.black),
                      Text("$index")
                    ],
                  ),
                );
              }),
        ));
  }
}

class CustomAttributionWidget extends AttributionWidget {
  const CustomAttributionWidget({super.key, required super.attributionBuilder});

  static Widget defaultWidget({
    required String source,
    void Function()? onSourceTapped,
    TextStyle sourceTextStyle = const TextStyle(color: Color(0xFF0078a8)),
    Alignment alignment = Alignment.bottomRight,
  }) =>
      Align(
        alignment: alignment,
        child: ColoredBox(
          color: const Color(0xCCFFFFFF),
          child: GestureDetector(
            onTap: onSourceTapped,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    cursor: onSourceTapped == null
                        ? MouseCursor.defer
                        : SystemMouseCursors.click,
                    child: Text(
                      source,
                      style: onSourceTapped == null ? null : sourceTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
