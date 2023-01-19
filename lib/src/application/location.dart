import 'dart:io';

import 'package:flutter/foundation.dart';
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
  StreamSubscription<Position>? recordingStream;
  DateTime lastDate = DateTime.now().toUtc();

  LocationService({Function()? onReady}) {
    ExternalPath.getExternalStorageDirectories().then((dirs) {
      appDir = Directory("${dirs[0]}/geo_steps");
      appDir.create();
      if (onReady != null) {
        onReady();
      }
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

  String toGPX({bool pretty = false}) {
    var gpx = Gpx();
    gpx.creator = "app.janeuster.geo_steps";
    gpx.trks = [
      Trk(trksegs: [
        Trkseg(
            trkpts: positions
                .map((p) => Wpt(
                    ele: p.altitude,
                    lat: p.latitude,
                    lon: p.longitude,
                    time: p.timestamp))
                .toList())
      ])
    ];
    String gpxString = GpxWriter().asString(gpx, pretty: pretty);
    return gpxString;
  }

  List<Position> fromGPX(String xml, {bool setPos = true}) {
    var xmlGpx = GpxReader().fromString(xml);
    List<Position> posList = [];
    for (var trk in xmlGpx.trks) {
      for (var trkseg in trk.trksegs) {
        for (var trkpt in trkseg.trkpts) {
          posList.add(Position(
              longitude: trkpt.lon!,
              latitude: trkpt.lat!,
              timestamp: trkpt.time,
              accuracy: 0,
              altitude: trkpt.ele!,
              heading: 0,
              speed: 0,
              speedAccuracy: 0));
        }
      }
    }
    log("${posList.length} positions read from file");
    if (setPos) {
      positions = posList;
    }
    return posList;
  }

  void addPosition(Position position) {
    positions.add(position);
  }

  Future<void> record({Function(Position)? onReady}) async {
    log("start recording position data");
    Geolocator.getLastKnownPosition().then((p) {
      log("last position: $p");
      if (p != null) {
        positions.add(p);
        if (onReady != null) {
          onReady(p);
        }
      }

      Geolocator.getCurrentPosition().then((p) {
        log("init position: $p");
        positions.add(p);
        if (onReady != null) {
          onReady(p);
        }
      });
    });
    recordingStream = await streamPosition((p) => positions.add(p));
  }

  Future<void> stopRecording() async {
    log("stop recording position data");
    recordingStream?.cancel();
  }

  Future<void> loadToday() async {
    String date = DateTime.now().toUtc().toIso8601String().split("T")[0];
    var gpxDirPath = "${appDir.path}/gpxData";
    var gpxFilePath = "$gpxDirPath/${date}.gpx";
    var gpxFile = File(gpxFilePath);
    // load only if actually exists
    if (await gpxFile.exists()) {
      log("todays gpx file exists");
      var xml = await gpxFile.readAsString();
      fromGPX(xml);
    }
  }

  Future<void> saveToday() async {
    var now = DateTime.now().toUtc();
    // check if its a new day and if so, remove all data from previous day
    // necessary because a new gpx file is created for every day -> no overlay in data
    // dates are converted to utc, because gpx stores dates as utc -> gpx files will not start before 0:00 and not end after 23:59
    if (lastDate.day != now.day) {
      positions = positions.where((p) => p.timestamp!.day == now.day).toList();
      lastDate = now;
    }
    String date = lastDate.toIso8601String().split("T")[0];

    var gpxDirPath = "${appDir.path}/gpxData";
    var gpxDir = Directory(gpxDirPath);
    if (!(await gpxDir.exists())) {
      await gpxDir.create(recursive: true);
    }

    var gpxFilePath = "$gpxDirPath/${date}.gpx";
    var gpxFile = File(gpxFilePath);

    await gpxFile.writeAsString(toGPX(), flush: true);

    log("gpx file saved to $gpxFilePath");
  }

  Future<void> exportGpx() async {
    String downloadsPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    String date = DateTime.now().toUtc().toIso8601String().split("T")[0];

    var gpxDir = Directory(downloadsPath);
    if (!(await gpxDir.exists())) {
      await gpxDir.create(recursive: true);
    }

    var gpxFilePath = "$downloadsPath/${date}.gpx";
    var gpxFile = File(gpxFilePath);

    await gpxFile.writeAsString(toGPX(pretty: true), flush: true);

    log("gpx file exported to $gpxFilePath");
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
}

Future<StreamSubscription<Position>> streamPosition(
    Function(Position) addPosition) async {
  late LocationSettings locationSettings;

  if (defaultTargetPlatform == TargetPlatform.android) {
    locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      forceLocationManager: false,
      intervalDuration: const Duration(seconds: 1),
      //(Optional) Set foreground notification config to keep the app alive
      // when going to the background
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText:
            "currently tracking location",
        notificationTitle: "geo_steps location service",
        enableWakeLock: true,
      ),
    );
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
  });
  return positionStream;
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
