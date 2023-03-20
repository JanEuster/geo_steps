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
  bool _initialized = false;
  late Directory appDir;
  DateTime lastDate = DateTime.now().toLocal();

  List<LocationDataPoint> dataPoints = [];
  List<TripSegment> segmentedData = [];

  /// last received step count value
  int? _newSteps;

  /// last received pedestrian status
  String _newPedStatus = LocationDataPoint.STATUS_STOPPED;

  /// time since last detected movement in milliseconds
  DateTime timeOfLastMove = DateTime.now();

  /// boundary for recorded speed value at which movement is detected
  double speedBoundary = 0.8;

  /// whether adding location updates to dataPoints is paused or not
  bool isPaused = false;

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
    _initialized = true;
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
    return getCoordRange(dataPoints);
  }

  List<LatLng> get latLngList {
    return positions.map((e) => LatLng(e.latitude, e.longitude)).toList();
  }

  bool get isInitialized {
    return _initialized;
  }

  int get stepsMin {
    for (final p in dataPoints) {
      if (p.steps != null) {
        return p.steps!;
      }
    }
    return 0;
  }

  /// total steps
  ///
  /// from last measured steps count - first measured steps count
  int get stepsTotal {
    if (hasPositions) {
      var stepsStart = stepsMin;
      var stepsEnd = stepsMin;
      for (final p in dataPoints.reversed) {
        if (p.steps != null) {
          stepsEnd = p.steps!;
          break;
        }
      }
      return stepsEnd - stepsStart;
    } else {
      return 0;
    }
  }

  List<double> get hourlyStepsTotal {
    List<double> hours = List.generate(24, (index) => 0);
    var stepsBefore = stepsMin;
    for (final p in dataPoints) {
      if (p.timestamp != null) {
        var i = p.timestamp!.toLocal().hour;
        if (p.steps != null && p.steps! > stepsBefore) {
          hours[i] += p.steps! - stepsBefore;
          stepsBefore = p.steps!;
        }
      }
    }
    log("hourly steps $hours");
    return hours;
  }

  /// total distance in meters
  /// TODO: more accurate distance calculation
  double get distanceTotal {
    double dist = 0;
    for (var i = 0; i < dataPoints.length - 1; i++) {
      final p1 = dataPoints[i];
      final p2 = dataPoints[i + 1];
      dist += const Distance().distance(
          LatLng(p1.latitude, p1.longitude), LatLng(p2.latitude, p2.longitude));
    }
    return dist;
  }

  LocationDataPoint dataPointClosestTo(DateTime time) {
    int? smallestDiff;
    int smallestDiffI = 0;
    var timeMillis = time.dayInMillis();

    var i = 0;
    while (i < dataPoints.length) {
      final p = dataPoints[i];
      if (p.timestamp != null) {
        var pMillis = p.timestamp!.dayInMillis();
        final diff = (timeMillis - pMillis).abs();

        if (smallestDiff == null) {
          smallestDiff = diff;
          smallestDiffI = 0;
        }

        log("$i - $diff");
        if (smallestDiff != null && diff < smallestDiff!) {
          log("index: $i");
          smallestDiffI = i;
          smallestDiff = diff;
        }
        i++;
      } else {
        i++;
      }
    }
    log("--- index $smallestDiffI ---");
    return dataPoints[smallestDiffI];
  }

  /// list of closest datapoint for every minute of the day
  ///
  /// dataPointPerMinute.length = 24 * 60 = 1440
  List<LocationDataPoint> get dataPointPerMinute {
    List<LocationDataPoint?> minutesNullable = List.generate(1440, (index) => null);
    for (final p in dataPoints) {
      final pMinute = p.timestamp!.dayInMinutes();
      if (minutesNullable[pMinute] == null) {
        minutesNullable[pMinute] = p;
      } else {
        // add up miutes of datapoints in the same minute
        if (minutesNullable[pMinute]!.steps != null) {
          minutesNullable[pMinute]!.steps =
              (minutesNullable[pMinute]!.steps ?? 0) + (p.steps ?? 0);
        }
        // set pedStatus if its unknown on the current datapoint
        if (minutesNullable[pMinute]!.pedStatus == LocationDataPoint.STATUS_UNKNOWN &&
            p.pedStatus != LocationDataPoint.STATUS_UNKNOWN) {
          minutesNullable[pMinute]!.pedStatus == p.pedStatus;
        }
      }
    }
    List<LocationDataPoint> minutes = [];
    for (var i = 0; i < minutesNullable.length; i++) {
      var p = minutesNullable[i];
      if (p == null) {
        var closestI = minutesNullable.closestNonNull(i);
        if (closestI != null) {
          p = minutesNullable[closestI];
        }
      }
      minutes.add(p ?? dataPoints.first);
    }
    return minutes;
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

    if (isPaused) {
      isPaused = false;
    } else {
      streamPosition((p) {
        // LocationDataPoint can only have steps > 0 if ped status is not stopped
        // -> detecting stops clearer?
        log("$p $_newSteps $_newPedStatus");
        dataPoints.add(LocationDataPoint(p, _newSteps, _newPedStatus));

        if (p.speed > speedBoundary) {
          timeOfLastMove = p.timestamp ?? DateTime.now();
        }
      });
    }
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
  }

  Future<void> stopRecording() async {
    log("stop recording position data");
    positionStream?.cancel();
    stepCountStream?.cancel();
    pedestrianStatusStream?.cancel();
  }

  /// determines whether the dataPoint.last is at a defined homepoint
  bool isAtHomepoint() {
    return false;
  }

  /// pauses location update streams until new movement is detected
  Future<void> pauseIfStopped() async {
    log("pauseIfStopped - isPaused: $isPaused - time since move ${DateTime.now().difference(timeOfLastMove).inSeconds}s");
    if (!isPaused &&
        (DateTime.now().difference(timeOfLastMove).inSeconds >= 60 ||
            isAtHomepoint())) {
      log("pausing location stream");
      isPaused = true;
      positionStream?.pause();

      Timer.periodic(const Duration(seconds: 45), (timer) async {
        var newPos = await Geolocator.getCurrentPosition();
        var dist = Geolocator.distanceBetween(dataPoints.last.latitude,
            dataPoints.last.longitude, newPos.latitude, newPos.longitude);
        log("new dist $dist");
        // distance
        if (dist > 60 || (dist > 35 && newPos.speed > speedBoundary)) {
          timeOfLastMove = newPos.timestamp ?? DateTime.now();
          log("resuming location stream");
          dataPoints.add(LocationDataPoint(newPos, _newSteps, _newPedStatus));
          isPaused = false;
          positionStream?.resume();
          timer.cancel();
        }
      });
    }
  }

  /// returns whether data has changed
  bool dataPointsFromKV(List<dynamic> entries) {
    var kvDP = entries.toLocationDataPoints();
    if (dataPoints.length != kvDP.length) {
      dataPoints = kvDP;
      return true;
    }
    return false;
  }

  void addPosition(Position position) {
    // LocationDataPoint can only have steps > 0 if ped status is not stopped
    // -> detecting stops clearer?
    log("$position $_newSteps $_newPedStatus");
    dataPoints.add(LocationDataPoint(position, _newSteps, _newPedStatus));
  }

  void optimizeCapturedData() {
    // remove redundant data points from positions list
    // - keep only start and end of a stop
    // - average multiple points at a location, when little movement is happening
    log("optimize data");

    // into segments
    List<TripSegment> segments = [];
    var i = 0;
    // speed at which a dataPoint is thought of as moving
    var startI = i;
    while (i < dataPoints.length - 1) {
      // is stop
      if (dataPoints[i].isStopped && dataPoints[i].speed < speedBoundary) {
        var endOfStop = false;
        while (!endOfStop) {
          var point = dataPoints[i];
          if (!point.isStopped || point.speed > speedBoundary) {
            var endI = i - 1;
            segments.add(StopSegment(
                startI, endI, dataPoints.sublist(startI, endI + 1)));
            startI = i;
            endOfStop = true;
          }
          if (i < dataPoints.length - 1) {
            i++;
          } else {
            break;
          }
        }
      }

      // is moving
      var endOfMove = false;
      while (!endOfMove) {
        var point = dataPoints[i];
        if (point.isStopped && point.speed < speedBoundary) {
          var endI =
              i; // one too high because sublist is not inclusive sublist(10,11) => [10]
          segments
              .add(MoveSegment(startI, endI, dataPoints.sublist(startI, endI)));
          startI = i;
          endOfMove = true;
        }
        if (i < dataPoints.length - 1) {
          i++;
        } else {
          break;
        }
      }

      i++;
    }

    // remove artifacts:
    // - short stops at a junction
    // - short walks around the house
    TripSegment mergeSegments(
        TripSegment s1, TripSegment s2, bool firstLonger) {
      var startIndex = s1.startIndex;
      var endIndex = s2.endIndex;
      List<LocationDataPoint> dps = [...s1.dataPoints, ...s2.dataPoints];

      if (s1.runtimeType == MoveSegment) {
        return MoveSegment(startIndex, endIndex, dps);
      } else {
        return StopSegment(startIndex, endIndex, dps);
      }
    }

    /// min duration of a segment in seconds
    const minSegmentLength = 45;
    var index = 1;
    while (index < segments.length) {
      var s1 = segments[index - 1];
      var s2 = segments[index];

      if (s1.duration().inSeconds < minSegmentLength ||
          s2.duration().inSeconds < minSegmentLength) {
        // this 2. condition should only be necessary for the last segment,
        // because it will never be s1, only s2 and therefore otherwise
        // not checked for length

        // merge segments
        // is first longer
        TripSegment mergedSegment = mergeSegments(
            s1, s2, s1.duration().inSeconds > s2.duration().inSeconds);
        segments = [
          ...segments.sublist(0, index - 1),
          mergedSegment,
          ...segments.sublist(index + 1)
        ];
      } else {
        index++;
      }
    }
    log("optimized segments");
    for (var element in segments) {
      log(element.toString());
    }
    segmentedData = segments;
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
            steps = int.tryParse(ext["steps"]!);
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

  List<Trkseg> dataToTrksegs() {
    List<Trkseg> trksegs = [];
    //    <trkpt lat="42.453298333333336" lon="-71.1212">
    //      <ele>78.0</ele>
    //      <time>2023-01-21T17:36:54.083Z</time>
    //      <type>stopped|walking|biking|transportation</type>
    //      <cmt>steps:5;heading:NNW;speed:5kmh</cmt>
    //      or
    //      <extensions>
    //        <?xml version="1.0" encoding="UTF-8"?>
    //        <steps>3</steps>
    //      </extensions>
    //    </trkpt>

    // determine type of movement for <type>
    // - based on speed between points, average speed over all points
    // -> 5-20km/h = biking; 20-150km/h = car or train; >150km/h = train
    // -> outlier data points like a 25km/h bike ride or >150km/h autobahn drive should probably be ignored
    // - based on pedestrian status, which will not have steps recorded, when not on foot
    // NOT ACTUALLY WHAT THE CODE BELOW DOES; JUST AN IDEA
    // BELOW ITS A MORE CRUDE APPROACH
    /// gets speed value as m/s
    String typeBasedOnSpeed(String pedStatus, double speed) {
      if (pedStatus == LocationDataPoint.STATUS_WALKING) {
        if (speed > 6) {
          return LocationDataPoint.STATUS_BIKING;
        } else {
          return pedStatus;
        }
      } else if (pedStatus == LocationDataPoint.STATUS_STOPPED) {
        if (speed > 6) {
          return LocationDataPoint.STATUS_DRIVING;
        } else {
          return pedStatus;
        }
      } else {
        // pedStatus == LocationDataPoint.STATUS_UNKNOWN
        return LocationDataPoint.STATUS_UNKNOWN;
      }
    }

    for (var seg in segmentedData) {
      trksegs.add(Trkseg(
          trkpts: seg.dataPoints
              .map((p) => Wpt(
                      ele: p.altitude,
                      lat: p.latitude,
                      lon: p.longitude,
                      time: p.timestamp,
                      type: typeBasedOnSpeed(p.pedStatus, p.speed),
                      desc:
                          "steps:${p.steps};heading:${p.heading};speed:${p.speed}",
                      extensions: {
                        "pedStatus": p.pedStatus,
                        "steps": p.steps.toString(),
                        "heading": p.heading.toStringAsFixed(2),
                        "speed": p.speed.toStringAsFixed(2),
                      }))
              .toList(),
          extensions: {
            "duration": "${seg.duration().inSeconds}s",
            "startTime": seg.startTime != null ? seg.startTime.toString() : "",
            "endTime":
                seg.endTime != null ? seg.endTime.toString() : "",
          }));
    }

    return trksegs;
  }

  String toGPX({bool pretty = true}) {
    var gpx = Gpx();
    gpx.creator = "app.janeuster.geo_steps";
    gpx.trks = [Trk(trksegs: dataToTrksegs())];
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

  Future<void> exportGpx() async {
    String downloadsPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    String date = DateTime.now().toLocal().toIso8601String().split("T").first;

    var gpxDir = Directory(downloadsPath);
    if (!(await gpxDir.exists())) {
      await gpxDir.create(recursive: true);
    }

    var gpxFilePath = "$downloadsPath/$date.gpx";
    var gpxFile = File(gpxFilePath);

    await gpxFile.writeAsString(toGPX(pretty: true), flush: true);

    log("gpx file exported to $gpxFilePath");
  }

  Future<bool> loadToday() async {
    String date = DateTime.now().toLocal().toIso8601String().split("T").first;
    var gpxDirPath = "${appDir.path}/gpxData";
    var gpxFilePath = "$gpxDirPath/$date.gpx";
    var gpxFile = File(gpxFilePath);
    // load only if actually exists
    if (await gpxFile.exists()) {
      log("todays gpx file exists");
      var xml = await gpxFile.readAsString();
      fromGPX(xml);
      return true;
    }
    return false;
  }

  Future<void> saveToday() async {
    if (dataPoints.isNotEmpty) {
      optimizeCapturedData();

      var now = DateTime.now().toLocal();
      // check if its a new day and if so, remove all data from previous day
      // necessary because a new gpx file is created for every day -> no overlay in data
      // dates are converted to utc, because gpx stores dates as utc -> gpx files will not start before 0:00 and not end after 23:59
      if (lastDate.toLocal().day != now.toLocal().day) {
        dataPoints = dataPoints
            .where((p) => p.timestamp!.toLocal().day == now.toLocal().day)
            .toList();
        lastDate = now;
      }
      String date = lastDate.toLocal().toIso8601String().split("T").first;

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

  void clearData() {
    dataPoints = [];
  }

  StreamSubscription<Position> streamPosition(Function(Position) addPosition) {
    late LocationSettings locationSettings;

    const distanceFilter = 24;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
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
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
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
}

MinMax<LatLng> getCoordRange(List<LocationDataPoint> positions) {
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

/// type for positions with step and pedestrian status data
class LocationDataPoint {
  static const STATUS_WALKING = 'walking';
  static const STATUS_STOPPED = 'stopped';
  static const STATUS_UNKNOWN = 'unknown';
  static const STATUS_BIKING = 'biking';
  static const STATUS_DRIVING = 'driving';

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

  @override
  String toString() {
    return "LocationDataPoint at $timestamp { lat: $latitude lon: $longitude alt: $altitude dir: $heading° spe: $speed m/s with status: $pedStatus - $steps steps }";
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

extension ToLatLng on List<LocationDataPoint> {
  List<LatLng> toLatLng() {
    return map((e) => LatLng(e.latitude, e.longitude)).toList();
  }
}

abstract class TripSegment {
  final int startIndex;
  final int endIndex;
  late final DateTime? startTime;
  late final DateTime? endTime;
  final List<LocationDataPoint> dataPoints;

  TripSegment(this.startIndex, this.endIndex, this.dataPoints) {
    startTime = dataPoints[0].timestamp;
    endTime = dataPoints[dataPoints.length - 1].timestamp;
  }

  Duration duration() {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return const Duration(seconds: 1);
  }
}

class MoveSegment extends TripSegment {
  MoveSegment(super.startIndex, super.endIndex, super.dataPoints);

  @override
  String toString() {
    return "MoveSegment[indexes: $startIndex-$endIndex, time: $startTime - $endTime, duration: ${duration().inSeconds}]";
  }
}

class StopSegment extends TripSegment {
  StopSegment(super.startIndex, super.endIndex, super.dataPoints);

  @override
  String toString() {
    return "StopSegment[indexes: $startIndex-$endIndex, time: $startTime - $endTime, duration: ${duration().inSeconds}]";
  }
}

class MinMax<T> {
  T min;
  T max;

  MinMax(this.min, this.max);

  static MinMax<double> fromList(List<double> list) {
    double min = list.first;
    double max = list.first;
    for (var e in list) {
      if (e > max) {
        max = e;
      } else if (e < min) {
        min = e;
      }
    }
    return MinMax(min, max);
  }

  @override
  String toString() {
    return "[min] $min [max] $max";
  }
}

extension Double on MinMax<double> {
  double get diff {
    return max - min;
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

extension Range on MinMax<LatLng> {
  double get latRange {
    return max.latitude - min.latitude;
  }

  double get lngRange {
    return max.longitude - min.longitude;
  }
}

extension DayIn on DateTime {
  /// minutes from start of day
  int dayInMinutes() {
    return (hour * 60) + minute;
  }

  /// milliseconds from start of day
  int dayInMillis() {
    return (hour * 3600 * 1000) +
        (minute * 60 * 1000) +
        (second * 1000) +
        millisecond;
  }
}

extension NullableList<T> on List<T?> {
  /// find index of closest list entry that is not null
  int? closestNonNull(int fromI) {
    var walkedDistance = 1;
    while (true) {
      // negative/down walk index
      var mI = fromI - walkedDistance;
      // positive/up walk index
      var pI = fromI + walkedDistance;
      if (mI >= 0 && this[mI] != null) {
        return mI;
      } else if (pI < length && this[pI] != null) {
        return pI;
      } else {
        walkedDistance++;
      }
      if (mI < 0 && pI >= length) {
        return null;
      }
    }
  }
}
