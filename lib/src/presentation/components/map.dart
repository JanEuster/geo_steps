// flutter imports
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geo_steps/src/application/preferences.dart';
import 'package:latlong2/latlong.dart';

// local imports
import 'package:geo_steps/src/application/location.dart';

class SimpleMap extends StatefulWidget {
  const SimpleMap({super.key});

  @override
  State<StatefulWidget> createState() => _SimpleMapState();
}

class _SimpleMapState extends State<SimpleMap> {
  late LocationService locationService;
  late TargetPlatform defaultTargetPlatform = TargetPlatform.iOS;
  final mapController = MapController();

  @override
  void initState() {
    super.initState();

    locationService = LocationService();
    locationService.init().whenComplete(
        () => locationService.loadToday().then((value) => setState(() {
              if (locationService.hasPositions) {
                mapController.move(
                    LatLng(locationService.lastPos!.latitude,
                        locationService.lastPos!.longitude),
                    12.8);
              }
            })));

    AppSettings().trackingLocation.get().then((isTrackingLocation) {
      if (isTrackingLocation != null && isTrackingLocation) {
        FlutterBackgroundService().on("sendTrackingData").listen((event) {
          setState(() {
            locationService.dataPoints = (event!["trackingData"] as List<dynamic>).toLocationDataPoints();
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
  }

  @override
  void dispose() {
    // locationService.stopRecording();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    defaultTargetPlatform = Theme.of(context).platform;
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        if (locationService.hasPositions) ...[
          Text("longitude: ${locationService.lastPos!.longitude}"),
          Text("latitude: ${locationService.lastPos!.latitude}"),
          Text("min max: ${locationService.range}"),
          Text("positions: ${locationService.posCount}"),
        ],
        SizedBox(
            width: width,
            height: width,
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
                  sourceTextStyle:
                      const TextStyle(fontSize: 12, color: Color(0xFF0078a8)),
                  onSourceTapped: () {},
                ),
              ],
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
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
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                    Polyline(points: [LatLng(42.4311972, -71.1088649)])
                  ],
                ),
                if (locationService.hasPositions)
                  MarkerLayer(
                    markers: [
                      Marker(
                          point: LatLng(locationService.lastPos!.latitude,
                              locationService.lastPos!.longitude),
                          builder: (context) => const FlutterLogo())
                    ],
                  )
              ],
            )),
      ],
    );
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
