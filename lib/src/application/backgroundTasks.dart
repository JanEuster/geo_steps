import 'dart:async';
import "dart:developer";

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:workmanager/workmanager.dart';

const locationTrackingTask = "janeuster.geo_steps.gps_tracking";


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case locationTrackingTask: {
        LocationService locationService = LocationService();
        await locationService.record();


        Timer.periodic(const Duration(minutes: 1), (timer) {
          log("background pos: ${locationService.lastPos}");
          AwesomeNotifications
            ().createNotification(
              content: NotificationContent(
                id: 10,
                channelKey: 'basic_channel',
                title: 'background notification',
                body: "background pos: ${locationService.lastPos}",
                actionType: ActionType.Default,
              ));
        });
        await Future.delayed(const Duration(minutes: 10));
        locationService.stopRecording();

        return true;
      }
      default: {
        return false;
      }
    }
  });
}
