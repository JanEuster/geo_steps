import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "dart:developer";
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class SimpleMap extends StatefulWidget {
  const SimpleMap({super.key});

  @override
  State<StatefulWidget> createState() => _SimpleMapState();
}

class _SimpleMapState extends State<SimpleMap> {
  @override
  void initState() {
    checkPosition();
    streamPosition();
  }

  List<Position> positions = <Position>[];
  late TargetPlatform defaultTargetPlatform = TargetPlatform.iOS;

  Future<void> checkPosition() async {
    while (true) {
      if (await Permission.locationAlways.request().isGranted) {
        break;
      }
    }
  }

  Future<void> streamPosition() async {
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 1),
          //(Optional) Set foreground notification config to keep the app alive
          //when going to the background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "Example app will continue to receive your location even when you aren't using it",
            notificationTitle: "Running in Background",
            enableWakeLock: true,
          ));
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      setState(() {
        if (positions.length < 10) {
          positions = [...positions, position!];
        }
      });
      log(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    defaultTargetPlatform = Theme.of(context).platform;
    if (positions.isNotEmpty) {
      Position lastPos = positions.last;
      return Column(
        children: [
          Text("longitude: ${lastPos.longitude}"),
          Text("latitude: ${lastPos.latitude}"),
          Text("min max: ${getCoordRange(positions)}"),
          Text("positions: $positions"),
          Center(child: CustomPaint(
              size: Size.square(100),
              foregroundPainter: CustomMapPainter(positions))),
          Padding(padding: EdgeInsets.only(bottom: 100)),
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

class CustomMapPainter extends CustomPainter {
  List<Position> positions;

  CustomMapPainter(this.positions) : super();

  @override
  void paint(Canvas canvas, Size size) {
    log("canvas size || width: ${size.width} height: ${size.height}");
    final basePaint = Paint()..color = Colors.yellow;
    final paint = Paint()
      ..strokeWidth = 2
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
        Rect.fromLTRB(0, 0, 0 , 0), basePaint);
    canvas.drawRect(
        Rect.fromLTRB(0, 0, 0, 0), paint);

    final lonlatRange = getCoordRange(positions);
    final xRange = lonlatRange.max.longitude - lonlatRange.min.longitude;
    final yRange = lonlatRange.max.latitude - lonlatRange.min.latitude;
    log("range x $xRange y $yRange");

    final path = Path();
    for (var i = 0; i < positions.length; i++) {
      var p = positions[i];
      final dx =
          (p.longitude - lonlatRange.min.longitude) / xRange * size.width;
      final dy =
          (p.latitude - lonlatRange.min.latitude) / yRange * size.height;
      log("x: $dx y: $dy");
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.relativeLineTo(dx, dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return false;
  }
}
