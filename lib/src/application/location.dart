import 'dart:io';
import 'dart:async';
import "dart:developer";
import "dart:convert";

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

  /// last received step count value
  int? _newSteps;

  /// last received pedestrian status
  String _newPedStatus = LocationDataPoint.STATUS_STOPPED;

  /// time since last detected movement in milliseconds
  DateTime timeOfLastMove = DateTime(0);
  /// boundary for recorded speed value at which movement is detected
  double speedBoundary = 0.8;

  // List<Android.ActivityEvent> _activities = [];
  StreamSubscription<Position>? positionStream;
  StreamSubscription<StepCount>? stepCountStream;
  StreamSubscription<PedestrianStatus>? pedestrianStatusStream;

  // StreamSubscription<Android.ActivityEvent>? activityStream;

  LocationService();

  Future<void> init() async {
    var dirs = await ExternalPath.getExternalStorageDirectories();
    appDir = Directory("${dirs.first}/geo_steps");
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

  Position? get lastPos {
    return positions.isNotEmpty ? positions.last : null;
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
            trkpts: dataPoints.map((p) {
          return Wpt(
              ele: p.altitude,
              lat: p.latitude,
              lon: p.longitude,
              time: p.timestamp,
              type: p.pedStatus,
              desc: "steps:${p.steps};heading:${p.heading};speed:${p.speed}",
              extensions: {
                "pedStatus": p.pedStatus,
                "steps": p.steps.toString(),
                "heading": p.heading.toStringAsFixed(2),
                "speed": p.speed.toStringAsFixed(2),
              });
        }).toList())
      ])
    ];
    String gpxString = GpxWriter().asString(gpx, pretty: pretty);
    return gpxString;
  }

  Map<String, String> parseGPXDesc(String desc) {
    List<String> props = desc.split(";");
    Map<String, String> propMap;

    // weird error when the desc attribute = ""
    // somehow this scenario produces one prop = ""
    // that gets mapped and has only index 0 -> error
    if (!(desc.trim() == "" || props.isNotEmpty)) {
       propMap = Map.fromEntries(props.map((element) {
        List<String> prop = element.split(":");
        return MapEntry(prop[0], prop[1]);
      }));
    } else {
      propMap = {};
    }

    return propMap;
  }

  void dataPointsFromKV(List<dynamic> entries) {
    dataPoints = entries.toLocationDataPoints();
  }

  List<LocationDataPoint> fromGPX(String xml, {bool setPos = true}) {
    var xmlGpx = GpxReader().fromString(xml);
    List<LocationDataPoint> posList = [];
    for (var trk in xmlGpx.trks) {
      for (var trkseg in trk.trksegs) {
        for (var trkpt in trkseg.trkpts) {
          var gpxDesc = parseGPXDesc(trkpt.desc ?? "");
          var heading = double.parse(gpxDesc["heading"] ?? "0");
          var speed = double.parse(gpxDesc["speed"] ?? "0");
          var steps = gpxDesc["steps"] != "null"
              ? int.parse(gpxDesc["steps"] ?? "0")
              : null;

          var ext = trkpt.extensions;
          if (ext["heading"] != null) {
            heading = double.parse(ext["heading"] ?? "0");
          }
          if (ext["speed"] != null) speed = double.parse(ext["speed"] ?? "0");
          if (ext["steps"] != null) {
            steps = gpxDesc["steps"] != "null"
                ? int.parse(gpxDesc["steps"] ?? "0")
                : null;
          }

          posList.add(LocationDataPoint(
              Position(
                  longitude: trkpt.lon!,
                  latitude: trkpt.lat!,
                  timestamp: trkpt.time,
                  accuracy: 0,
                  altitude: trkpt.ele!,
                  heading: heading,
                  speed: speed,
                  speedAccuracy: 0),
              steps,
              trkpt.type ?? LocationDataPoint.STATUS_UNKNOWN));
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
    dataPoints.add(LocationDataPoint(position, _newSteps, _newPedStatus));
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
    streamPosition((p) {
      addPosition(p);

      if (p.speed > speedBoundary) {
        timeOfLastMove = p.timestamp ?? DateTime.now();
      }
    });
    streamSteps((s) {
      _newSteps = s.steps;
      timeOfLastMove = s.timeStamp;
    }); // steps value is never reset internally
    // -> steps totaled from first day of usage
    streamPedestrianStatus((p) {
      _newPedStatus = p.status;
      if (p.status == LocationDataPoint.STATUS_WALKING) {
        timeOfLastMove = p.timeStamp;
      }
    });

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
    String date = DateTime.now().toUtc().toIso8601String().split("T").first;
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
    if (dataPoints.isNotEmpty) {
      // optimizeCapturedData();

      var now = DateTime.now().toUtc();
      // check if its a new day and if so, remove all data from previous day
      // necessary because a new gpx file is created for every day -> no overlay in data
      // dates are converted to utc, because gpx stores dates as utc -> gpx files will not start before 0:00 and not end after 23:59
      if (lastDate.day != now.day) {
        dataPoints =
            dataPoints.where((p) => p.timestamp!.day == now.day).toList();
        lastDate = now;
      }
      String date = lastDate.toIso8601String().split("T").first;

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
    String date = DateTime.now().toUtc().toIso8601String().split("T").first;

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
    double minLon = positions.first.longitude;
    double minLat = positions.first.latitude;
    double maxLon = positions.first.longitude;
    double maxLat = positions.first.latitude;
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

  LocationDataPoint.fromJson(Map<String, dynamic> json) {
    latitude = double.parse(json["latitude"]);
    longitude = double.parse(json["longitude"]);
    altitude = double.parse(json["altitude"]);
    heading = double.parse(json["heading"]);
    speed = double.parse(json["speed"]);
    timestamp = DateTime.parse(json["timestamp"]);

    steps = json["steps"];
    pedStatus = json["pedStatus"];
  }

  Map<String, dynamic> toJson() {
    return {
      "longitude": longitude.toStringAsFixed(10),
      "latitude": latitude.toStringAsFixed(10),
      "altitude": altitude.toStringAsFixed(2),
      "heading": heading.toStringAsFixed(2),
      "speed": speed.toStringAsFixed(2),
      "timestamp": timestamp != null ? timestamp!.toIso8601String() : "",
      "steps": steps,
      "pedStatus": pedStatus,
    };
  }
}

extension Averaged on List<LocationDataPoint> {
  LatLng averaged() {
    return LatLng(map((e) => e.latitude).fold(0.0, (a, b) => a + b) / length,
        map((e) => e.longitude).fold(0.0, (a, b) => a + b) / length);
  }
}

extension ToJson on List<LocationDataPoint> {
  List<Map<String, dynamic>> toJson() {
    return map((e) => e.toJson()).toList();
  }
}

extension ToLocationDataPoints on List<dynamic> {
  List<LocationDataPoint> toLocationDataPoints() {
    return map((e) => LocationDataPoint.fromJson(e)).toList();
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
