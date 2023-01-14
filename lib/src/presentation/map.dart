import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geo_steps/src/utils/location.dart';
import "dart:developer";
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart'; // Suitable for most situations
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

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
              options: MapOptions(onMapReady: () {
                // set initial position on map
                Geolocator.getLastKnownPosition().then((p) {
                  log("last position: $p");
                  if (p != null) {
                    setState(() {
                      positions.add(p);
                    });
                    mapController.move(LatLng(p.latitude, p.longitude), 12.8);
                  }

                  Geolocator.getCurrentPosition().then((p) {
                    log("init position: $p");
                    setState(() {
                      positions.add(p);
                    });
                    mapController.move(LatLng(p.latitude, p.longitude), 12.8);
                  });
                });
              },         zoom: 13.0,
                maxZoom: 19.0,keepAlive: true, interactiveFlags: InteractiveFlag.all),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'dev.janeuster.geo_steps',
                ),
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
                if (positions.isNotEmpty) MarkerLayer(markers: [
                  Marker(point: LatLng(lastPos!.latitude, lastPos!.longitude), builder: (context) => FlutterLogo())
                ],)
              ],
              nonRotatedChildren: [
                CustomAttributionWidget.defaultWidget(
                  source: '© OpenStreetMap contributors',
                  sourceTextStyle: TextStyle(fontSize: 12, color: Color(0xFF0078a8)),

                  onSourceTapped: () {},
                ),
              ],
            )),
      ],
    );
  }
}

class CustomAttributionWidget extends AttributionWidget {
  CustomAttributionWidget({required super.attributionBuilder});

  static Widget defaultWidget({
    required String source,
    void Function()? onSourceTapped,
    TextStyle sourceTextStyle = const TextStyle(color: Color(0xFF0078a8)),
    Alignment alignment = Alignment.bottomRight,
  }) =>       Align(
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

class MinMax<T> {
  T min;
  T max;

  MinMax(this.min, this.max);

  @override
  String toString() {
    return "[min] $min [max] $max";
  }
}

class LonLat {
  double longitude;
  double latitude;

  LonLat(this.longitude, this.latitude);

  @override
  String toString() {
    return "long: $longitude, lat: $latitude";
  }
}

MinMax<LatLng> getCoordRange(List<Position> positions) {
  double minLon = positions[0].longitude;
  double minLat = positions[0].latitude;
  double maxLon = positions[0].longitude;
  double maxLat = positions[0].latitude;
  for (var i = 0; i < positions.length; i++) {
    var p = positions[i];
    if (p.longitude > maxLon) {
      maxLon = p.longitude;
    } else if (p.longitude < minLon) {
      minLon = p.longitude;
    }
    if (p.latitude > maxLat) {
      maxLat = p.latitude;
    } else if (p.latitude < minLat) {
      minLat = p.latitude;
    }
  }
  return MinMax(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
}

LatLng getCoordCenter(MinMax<LatLng> range) {
  double longitude =
      (range.max.longitude - range.min.longitude) / 2 + range.min.longitude;
  double latitude =
      (range.max.latitude - range.min.latitude) / 2 + range.min.latitude;
  return LatLng(latitude, longitude);
}

List<LatLng> getLatLngList(List<Position> positions) {
  return positions.map((e) => LatLng(e.latitude, e.longitude)).toList();
}

// class CustomMapPainter extends CustomPainter {
//   List<Position> positions;
//
//   CustomMapPainter(this.positions) : super();
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final basePaint = Paint()..color = Colors.yellow;
//     final paint = Paint()
//       ..strokeWidth = 2
//       ..color = Colors.black
//       ..style = PaintingStyle.stroke;
//
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
//
//     final lonlatRange = getCoordRange(positions);
//     final xRange = lonlatRange.max.longitude - lonlatRange.min.longitude;
//     final yRange = lonlatRange.max.latitude - lonlatRange.min.latitude;
//
//     final path = Path();
//
//     double prevX = 0;
//     double prevY = 0;
//     for (var i = 0; i < positions.length; i++) {
//       var p = positions[i];
//       final dx =
//           (p.longitude - lonlatRange.min.longitude) / xRange * size.width;
//       final dy = (p.latitude - lonlatRange.min.latitude) / yRange * size.height;
//       if (i == 0) {
//         path.moveTo(dx, dy);
//       } else {
//         path.relativeLineTo(dx - prevX, dy - prevY);
//       }
//       prevX = dx;
//       prevY = dy;
//     }
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     // TODO: implement shouldRepaint
//     return false;
//   }
// }
