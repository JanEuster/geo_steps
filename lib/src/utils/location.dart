import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import "dart:developer";

Future<void> checkPosition() async {
  while (true) {
    if (await Permission.locationAlways.request().isGranted) {
      break;
    }
  }
}

Future<void> streamPosition(TargetPlatform defaultTargetPlatform, Function(Position) addPosition) async {
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

List<LatLng> getLatLngList(List<Position> positions) {
  return positions.map((e) => LatLng(e.latitude, e.longitude)).toList();
}