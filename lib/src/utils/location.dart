import 'package:geolocator/geolocator.dart';
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