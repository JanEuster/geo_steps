import 'dart:async';
import "dart:developer";
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';

import 'package:geo_steps/src/application/location.dart';


@pragma("vm:entry-point")
FutureOr<bool> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  // initialize stuff
  LocationService locationService = LocationService();
  await locationService.init();

  Timer? trackingNotificationTimer;
  Timer? trackingSaveTimer;

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

  if (service is AndroidServiceInstance) {
    service.on("setAsForeground").listen((event) {
      service.setAsForegroundService();
    });
    service.on("setAsBackground").listen((event) {
      service.setAsBackgroundService();
    });
    // // start
    // service.on("startTracking").listen((event) async {
    //   log("starting tracking service");
    //   await locationService.loadToday();
    //   await locationService.record();
    //   trackingNotificationTimer =
    //       Timer.periodic(const Duration(seconds: 1), (timer) {
    //     updateTrackingNotification(locationService, timer);
    //   });
    //   trackingSaveTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
    //     locationService.saveToday();
    //   });
    // });
    // // stop
    // service.on("stopTracking").listen((event) async {
    //   log("stopping tracking service");
    //   await locationService.stopRecording();
    //   trackingNotificationTimer?.cancel();
    //   trackingSaveTimer?.cancel();
    //   await locationService.saveToday();
    // });
  }
  service.on("stopService").listen((event) async {
    log("stopping tracking service");
    await locationService.stopRecording();
    trackingNotificationTimer?.cancel();
    trackingSaveTimer?.cancel();
    await locationService.saveToday();;
    service.stopSelf();
  });

  // bring to foreground
  // Timer.periodic(const Duration(seconds: 1), (timer) async {
  //   if (service is AndroidServiceInstance) {
  //     if (await service.isForegroundService()) {
  //       service.setForegroundNotificationInfo(
  //         title: "geosteps tracking your moves",
  //         content: "Updated at ${DateTime.now()}",
  //       );
  //     }
  //   }
  // });

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
          autoStart: true,
          onForeground: onStart,
          onBackground: runBackgroundIosService),
      androidConfiguration: AndroidConfiguration(
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
      body:
          "${locationService.lastPos} \n pos count: ${locationService.posCount} \n ${DateTime.now().toIso8601String()}",
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
