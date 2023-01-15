import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:external_path/external_path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import "dart:developer";


class LocationService {
  List<Position> positions = [];
  late Directory appDir;

  LocationService() {
    ExternalPath.getExternalStorageDirectories().then((dirs) {
      appDir = Directory("${dirs[0]}/geo_steps");
      appDir.create();
    });
  }

  bool get hasPositions {
    return positions.isNotEmpty;
  }

  Position get lastPos {
    return positions.last;
  }

  int get posCount {
    return positions.length;
  }

  MinMax<LatLng> get range {
    return getCoordRange(positions);
  }

  List<LatLng> get latLngList {
    return positions.map((e) => LatLng(e.latitude, e.longitude)).toList();
  }

  String get gpxRepresentation {
    var gpx = Gpx();
    gpx.creator = "app.janeuster.geo_steps";
    gpx.trks = [
      Trk(trksegs: [
        Trkseg(trkpts: positions.map((p) =>
            Wpt(ele: p.altitude, lat: p.latitude, lon: p.longitude)).toList())
      ])
    ];
    String gpxString = GpxWriter().asString(gpx, pretty: false);
    log("gpx string: $gpxString");
    return gpxString;
  }

  void addPosition(Position position) {
    positions.add(position);
    if (positions.length == 10) {
      saveToday();
      exportGpx();
    }
  }

  Future<void> loadToday() async {
  }

  Future<void> saveToday() async {

    String date = DateTime.now().toUtc().toIso8601String().split("T")[0];

    var gpxDirPath = "${appDir.path}/gpxData";
    var gpxDir = Directory(gpxDirPath);
    if (!(await gpxDir.exists())) {
      await gpxDir.create(recursive: true);
    }

    var gpxFilePath = "$gpxDirPath/${date}.gpx";
    var gpxFile = File(gpxFilePath);

    await gpxFile.writeAsString(gpxRepresentation, flush: true);

    log("gpx file saved to $gpxFilePath");
  }

}


Future<void> checkPosition() async {
  while (true) {
    if (await Permission.locationAlways
        .request()
        .isGranted) {
      break;
    }
  }
}

Future<void> streamPosition(TargetPlatform defaultTargetPlatform,
    Function(Position) addPosition) async {
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
    addPosition(position!);
    // log location
    // log(position == null
    //     ? 'Unknown'
    //     : '${position.latitude.toString()}, ${position.longitude.toString()}');
  });
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
