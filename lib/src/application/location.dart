import 'dart:io';
import 'dart:async';
import "dart:developer";

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:external_path/external_path.dart';
import 'package:pedometer/pedometer.dart';

class LocationService {
  late Directory appDir;
  DateTime lastDate = DateTime.now().toUtc();

  List<LocationDataPoint> dataPoints = [];
  int? _newSteps = null;
  String _newPedStatus = LocationDataPoint.STATUS_STOPPED;

  // List<Android.ActivityEvent> _activities = [];
  StreamSubscription<Position>? positionStream;
  StreamSubscription<StepCount>? stepCountStream;
  StreamSubscription<PedestrianStatus>? pedestrianStatusStream;

  // StreamSubscription<Android.ActivityEvent>? activityStream;

  LocationService();

  Future<void> init() async {
    var dirs = await ExternalPath.getExternalStorageDirectories();
    appDir = Directory("${dirs[0]}/geo_steps");
    appDir.create();

    log("location service initialized");
  }

  List<Position> get positions {
    return dataPoints.map((e) => e.position).toList();
  }

  // List<Android.ActivityEvent> get activities {
  //   return _activities;
  // }

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
        // ...segmentDataToWpt().map((wpts) => Trkseg(trkpts: wpts))
        Trkseg(

            trkpts: dataPoints
                .map((p) => Wpt(
                    ele: p.altitude,
                    lat: p.latitude,
                    lon: p.longitude,
                    time: p.timestamp,
              type: p.pedStatus,
              desc: "steps:${p.steps};heading:${p.heading};speed:${p.speed}"
            ))
                .toList())
      ])
    ];
    String gpxString = GpxWriter().asString(gpx, pretty: pretty);
    return gpxString;
  }

  List<LocationDataPoint> fromGPX(String xml, {bool setPos = true}) {
    var xmlGpx = GpxReader().fromString(xml);
    List<LocationDataPoint> posList = [];
    for (var trk in xmlGpx.trks) {
      for (var trkseg in trk.trksegs) {
        for (var trkpt in trkseg.trkpts) {
          posList.add(LocationDataPoint(
              Position(
                  longitude: trkpt.lon!,
                  latitude: trkpt.lat!,
                  timestamp: trkpt.time,
                  accuracy: 0,
                  altitude: trkpt.ele!,
                  heading: 0,
                  speed: 0,
                  speedAccuracy: 0),
              0,
              LocationDataPoint.STATUS_UNKNOWN));
        }
      }
    }
    log("${posList.length} positions read from file");
    if (setPos) {
      dataPoints = posList;
    }
    return posList;
  }

  void addPosition(Position position) {
    // LocationDataPoint can only have steps > 0 if ped status is not stopped
    // -> detecting stops clearer?
    log("$position $_newSteps $_newPedStatus");
    if (_newPedStatus == LocationDataPoint.STATUS_STOPPED && _newSteps != null && dataPoints[dataPoints.length - 2].steps != null) {
      dataPoints.add(LocationDataPoint(position, 0, _newPedStatus));
      dataPoints[dataPoints.length - 2].steps = _newSteps! + dataPoints[dataPoints.length - 2].steps!;
    } else {
      dataPoints.add(LocationDataPoint(position, _newSteps, _newPedStatus));
    }
    _newSteps = 0; // reset steps
  }

  Future<void> record({Function(Position)? onReady}) async {
    log("start recording position data");
    Geolocator.getLastKnownPosition().then((p) {
      log("last known position: $p");
      if (p != null) {
        addPosition(p);
        if (onReady != null) {
          onReady(p);
        }
      }
    });
    streamPosition((p) => addPosition(p));
    streamSteps((s) => _newSteps = s.steps);  // steps value is never reset internally
                                              // -> steps totaled from first day of usage
    streamPedestrianStatus((p) => _newPedStatus = p.status);

    // if (defaultTargetPlatform == TargetPlatform.android) {
    // streamActivities((a) => _activities.add(a),
    //     (obj) => log("error streaming activities: $obj}"));
    // log("start recording activity data");
    // }
  }

  Future<void> stopRecording() async {
    log("stop recording position data");
    positionStream?.cancel();
    stepCountStream?.cancel();
    pedestrianStatusStream?.cancel();
    // if (defaultTargetPlatform == TargetPlatform.android) {
    //   log("stop recording activity data");
    // activityStream?.cancel();
    // }
  }

  Future<void> loadToday() async {
    String date = DateTime.now().toUtc().toIso8601String().split("T")[0];
    var gpxDirPath = "${appDir.path}/gpxData";
    var gpxFilePath = "$gpxDirPath/$date.gpx";
    var gpxFile = File(gpxFilePath);
    // load only if actually exists
    if (await gpxFile.exists()) {
      log("todays gpx file exists");
      var xml = await gpxFile.readAsString();
      fromGPX(xml);
    }
  }

  Future<void> saveToday() async {
    if (dataPoints.length > 0) {
    optimizeCapturedData();

    var now = DateTime.now().toUtc();
    // check if its a new day and if so, remove all data from previous day
    // necessary because a new gpx file is created for every day -> no overlay in data
    // dates are converted to utc, because gpx stores dates as utc -> gpx files will not start before 0:00 and not end after 23:59
    if (lastDate.day != now.day) {
      dataPoints =
          dataPoints.where((p) => p.timestamp!.day == now.day).toList();
      lastDate = now;
    }
    String date = lastDate.toIso8601String().split("T")[0];

    var gpxDirPath = "${appDir.path}/gpxData";
    var gpxDir = Directory(gpxDirPath);
    if (!(await gpxDir.exists())) {
      await gpxDir.create(recursive: true);
    }

    var gpxFilePath = "$gpxDirPath/$date.gpx";
    var gpxFile = File(gpxFilePath);

    await gpxFile.writeAsString(toGPX(), flush: true);

    log("gpx file saved to $gpxFilePath");
    } else {
      log("no dataPoint to save");
    }
  }

  Future<void> exportGpx() async {
    String downloadsPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    String date = DateTime.now().toUtc().toIso8601String().split("T")[0];

    var gpxDir = Directory(downloadsPath);
    if (!(await gpxDir.exists())) {
      await gpxDir.create(recursive: true);
    }

    var gpxFilePath = "$downloadsPath/$date.gpx";
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

  StreamSubscription<Position> streamPosition(Function(Position) addPosition) {
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
          notificationText: "currently tracking location",
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
        distanceFilter: 10,
      );
    }

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      addPosition(position!);
    });
    return positionStream!;
  }

  StreamSubscription<StepCount> streamSteps(Function(StepCount) addStepCount) {
    stepCountStream = Pedometer.stepCountStream.listen((event) {
      addStepCount(event);
      log("steps: $event");
    });

    return stepCountStream!;
  }

  StreamSubscription<PedestrianStatus> streamPedestrianStatus(
      Function(PedestrianStatus) addPedStatus) {
    pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen((event) {
      addPedStatus(event);
      log("ped status: $event");
    });

    return pedestrianStatusStream!;
  }

// StreamSubscription<Android.ActivityEvent> streamActivities(
//     Function(Android.ActivityEvent) addActivity,
//     void Function(Object) onError) {
//   activityStream = Android.ActivityRecognition()
//       .activityStream(runForegroundService: true)
//       .listen(addActivity, onError: onError);
//   return activityStream!;
// }
}

/// type for positions with step and pedestrian status data
class LocationDataPoint {
  static const STATUS_WALKING = 'walking';
  static const STATUS_STOPPED = 'stopped';
  static const STATUS_UNKNOWN = 'unknown';

  late final double latitude;
  late final double longitude;
  late final double altitude;
  late final double heading;
  late final double speed;
  late final DateTime? timestamp;

  late int? steps;
  late final String pedStatus;

  LocationDataPoint(Position pos, int? stepCount, String ped) {
    latitude = pos.latitude;
    longitude = pos.longitude;
    altitude = pos.altitude;
    heading = pos.heading;
    speed = pos.speed;
    timestamp = pos.timestamp!;

    steps = stepCount;
    pedStatus = ped;
  }

  bool get isStopped {
    return pedStatus == STATUS_STOPPED;
  }

  Position get position {
    return Position(
        longitude: longitude,
        latitude: latitude,
        timestamp: timestamp,
        accuracy: 0,
        altitude: altitude,
        heading: heading,
        speed: speed,
        speedAccuracy: 0);
  }
}

class StopLocation {
  final int startIndex;
  final int endIndex;
  final List<LocationDataPoint> dataPoints;

  StopLocation(this.startIndex, this.endIndex, this.dataPoints);
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
