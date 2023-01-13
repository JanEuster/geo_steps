
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geo_steps/src/utils/location.dart';
import "dart:developer";
import 'package:geolocator/geolocator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class SimpleMap extends StatefulWidget {
  const SimpleMap({super.key});

  @override
  State<StatefulWidget> createState() => _SimpleMapState();
}

class _SimpleMapState extends State<SimpleMap> {
  @override
  void initState() {
    checkPosition();
    streamPosition(defaultTargetPlatform, (Position position) {
      setState(() {
        positions = [...positions, position];
      });
    });
  }

  List<Position> positions = <Position>[];
  late TargetPlatform defaultTargetPlatform = TargetPlatform.iOS;
  MapController mapController = MapController.withPosition(
    initPosition: GeoPoint(
      latitude: 47.4358055,
      longitude: 8.4737324
      ,),
    areaLimit: BoundingBox(
      east: 10.4922941,
      north: 47.8084648,
      south: 45.817995,
      west:  5.9559113,
    ),
  );


  @override
  Widget build(BuildContext context) {
    defaultTargetPlatform = Theme.of(context).platform;
    double width = MediaQuery.of(context).size.width;
    if (positions.isNotEmpty) {
      Position lastPos = positions.last;
      return Column(
        children: [
          Text("longitude: ${lastPos.longitude}"),
          Text("latitude: ${lastPos.latitude}"),
          Text("min max: ${getCoordRange(positions)}"),
          Text("positions: ${positions.length}"),
          // Padding(
          //     padding: EdgeInsets.all(20),
          //     child: Center(
          //         child: CustomPaint(
          //             size: Size.square(MediaQuery.of(context).size.width - 40),
          //             foregroundPainter: CustomMapPainter(positions)))),
          Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                  child: SizedBox(width: width, height: width, child: OSMFlutter(
                    controller: mapController,
                    trackMyPosition: false,
                    initZoom: 12,
                    minZoomLevel: 8,
                    maxZoomLevel: 14,
                    stepZoom: 1.0,
                    userLocationMarker: UserLocationMaker(
                      personMarker: const MarkerIcon(
                        icon: Icon(
                          Icons.location_history_rounded,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                      directionArrowMarker: const MarkerIcon(
                        icon: Icon(
                          Icons.double_arrow,
                          size: 48,
                        ),
                      ),
                    ),
                    roadConfiguration: RoadConfiguration(
                      startIcon: const MarkerIcon(
                        icon: Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.brown,
                        ),
                      ),
                      roadColor: Colors.yellowAccent,
                    ),
                    markerOption: MarkerOption(
                        defaultMarker: const MarkerIcon(
                          icon: Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 56,
                          ),
                        )
                    ),
                  )))),
        ],
      );
    } else {
      return const Text("No Data to Display");
    }
  }
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

MinMax<LonLat> getCoordRange(List<Position> positions) {
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
  return MinMax(LonLat(minLon, minLat), LonLat(maxLon, maxLat));
}

LonLat getCoordCenter(MinMax<LonLat> range) {
  double longitude =
      (range.max.longitude - range.min.longitude) / 2 + range.min.longitude;
  double latitude =
      (range.max.latitude - range.min.latitude) / 2 + range.min.latitude;
  return LonLat(longitude, latitude);
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
