import 'dart:async';
import "dart:developer";
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';

import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/application/preferences.dart';

@pragma("vm:entry-point")
FutureOr<bool> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  // initialize stuff
  LocationService locationService = LocationService();
  await locationService.init();

  Timer? trackingNotificationTimer;
  Timer? trackingSaveTimer;
  Timer? checkStoppedTimer;

  log("starting tracking service");
  await locationService.loadToday();
  await locationService.record();
  trackingNotificationTimer =
      Timer.periodic(const Duration(seconds: 1), (timer) {
    updateTrackingNotification(locationService, timer);
  });
  trackingSaveTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
    locationService.saveToday();
  });
  checkStoppedTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    locationService.pauseIfStopped();
  });

  if (service is AndroidServiceInstance) {
    service.on("setAsForeground").listen((event) {
      service.setAsForegroundService();
    });
    service.on("setAsBackground").listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on("requestTrackingData").listen((event) {
    service.invoke("sendTrackingData",
        {"trackingData": locationService.dataPoints.toJson()});
  });
  service.on("saveTrackingData").listen((event) async {
    var isTrackingLocation = await AppSettings.instance.trackingLocation.get();
    if (isTrackingLocation != null && isTrackingLocation) {
      await locationService.saveToday();
    }
  });
  service.on("stopService").listen((event) async {
    log("stopping tracking service");
    await locationService.stopRecording();
    trackingNotificationTimer?.cancel();
    trackingSaveTimer?.cancel();
    checkStoppedTimer?.cancel();
    await locationService.saveToday();
    service.stopSelf();
  });

  return true;
}

@pragma("vm:entry-point")
FutureOr<bool> runBackgroundIosService(ServiceInstance service) async {
  return true;
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
      iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: runBackgroundIosService),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: onStart,
        isForegroundMode: false,
        notificationChannelId: 'geolocator_channel_01',
        initialNotificationTitle: 'geosteps background notification',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: 75415,
      ));
}

void updateTrackingNotification(LocationService locationService, Timer timer) {
  if (locationService.hasPositions) {
    // log("background pos: ${locationService.lastPos}");

    // channel key and notifiction id are those used by geolocator
    // for the foreground notifiction that keeps location tracking alive
    // when app is in background / closed
    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 75415,
      channelKey: 'geolocator_channel_01',
      title: 'background notification',
      body: locationService.isPaused
          ? "location updates paused - last: ${locationService.lastPos} at ${locationService.timeOfLastMove.toLocal()}"
          : "${locationService.lastPos} \n pos count: ${locationService.posCount} \n ${DateTime.now().toLocal()}",
      actionType: ActionType.Default,
      notificationLayout: NotificationLayout.BigText,
    ));
  } else {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 75415,
      channelKey: 'geolocator_channel_01',
      title: 'background notification',
      body: "no new position \n ${DateTime.now().toIso8601String()}",
      actionType: ActionType.Default,
      notificationLayout: NotificationLayout.BigText,
    ));
  }
}
