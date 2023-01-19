import 'dart:async';
import "dart:developer";

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:workmanager/workmanager.dart';

const locationTrackingTask = "janeuster.geo_steps.gps_tracking";


void registerLocationTrackingTask() {
  Workmanager().registerPeriodicTask(locationTrackingTask, locationTrackingTask,
      tag: "tracking", initialDelay: const Duration(seconds: 0), frequency: const Duration(hours: 2));
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log("task: $task");
    switch (task) {
      case locationTrackingTask: {
        LocationService locationService = LocationService();

        await locationService.record();


        var notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (locationService.hasPositions) {
            log("background pos: ${locationService.lastPos}");
            AwesomeNotifications
              ().createNotification(
                content: NotificationContent(
                  id: 10,
                  channelKey: 'basic_channel',
                  title: 'background notification',
                  body: "${locationService.lastPos} \n pos count: ${locationService.posCount} \n ${DateTime.now().toIso8601String()}",
                  actionType: ActionType.Default,
                    notificationLayout: NotificationLayout.BigText,
                ));
          } else {
            AwesomeNotifications
              ().createNotification(
                content: NotificationContent(
                  id: 10,
                  channelKey: 'basic_channel',
                  title: 'background notification',
                  body: "no new position \n ${DateTime.now().toIso8601String()}",
                  actionType: ActionType.Default,
                  notificationLayout: NotificationLayout.BigText,
                ));
          }
        });
        var saveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          locationService.saveToday();
        });
        await Future.delayed(const Duration(hours: 2));
        locationService.stopRecording();
        notificationTimer.cancel();
        saveTimer.cancel();

        return true;
      }
      default: {
        return false;
      }
    }
  });
}
