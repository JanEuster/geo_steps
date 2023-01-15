// dart imports
import "dart:developer";

// flutter imports
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

// local imports
import 'package:geo_steps/src/utils/location.dart';

class SimpleMap extends StatefulWidget {
  const SimpleMap({super.key});

  @override
  State<StatefulWidget> createState() => _SimpleMapState();
}

class _SimpleMapState extends State<SimpleMap> {
  List<Position> positions = <Position>[];
  late TargetPlatform defaultTargetPlatform = TargetPlatform.iOS;
  final mapController = MapController();
  MinMax<LatLng>? range;

  @override
  void initState() {
    super.initState();

    checkPosition();
    streamPosition(defaultTargetPlatform, (Position position) {
      setState(() {
        positions.add(position);
        range = getCoordRange(positions);
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    defaultTargetPlatform = Theme.of(context).platform;
    double width = MediaQuery.of(context).size.width;
    Position? lastPos;
    if (positions.isNotEmpty) {
      lastPos = positions.last;
    }
    return Column(
      children: [
        if (positions.isNotEmpty) ...[
          Text("longitude: ${lastPos!.longitude}"),
          Text("latitude: ${lastPos!.latitude}"),
          Text("min max: ${getCoordRange(positions)}"),
          Text("positions: ${positions.length}"),
        ],
        SizedBox(
            width: width,
            height: width,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                  onMapReady: () {
                    // set initial position on map
                    Geolocator.getLastKnownPosition().then((p) {
                      log("last position: $p");
                      if (p != null) {
                        setState(() {
                          positions.add(p);
                        });
                        mapController.move(
                            LatLng(p.latitude, p.longitude), 12.8);
                      }

                      Geolocator.getCurrentPosition().then((p) {
                        log("init position: $p");
                        setState(() {
                          positions.add(p);
                        });
                        mapController.move(
                            LatLng(p.latitude, p.longitude), 12.8);
                      });
                    });
                  },
                  zoom: 13.0,
                  maxZoom: 19.0,
                  keepAlive: true,
                  interactiveFlags: // all interactions except rotation
                      InteractiveFlag.all & ~InteractiveFlag.rotate),
              nonRotatedChildren: [
                CustomAttributionWidget.defaultWidget(
                  source: '© OpenStreetMap contributors; United States Geological Survey',
                  sourceTextStyle:
                      TextStyle(fontSize: 12, color: Color(0xFF0078a8)),
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
                      points: getLatLngList(positions),
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                    Polyline(points: [LatLng(42.4311972, -71.1088649)])
                  ],
                ),
                if (positions.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                          point: LatLng(lastPos!.latitude, lastPos!.longitude),
                          builder: (context) => FlutterLogo())
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

