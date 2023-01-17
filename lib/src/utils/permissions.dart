import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import "dart:developer";

Future<void> requestLocationAccess() async {
  // you need to request normal location access first, before being able to request locationAlways
  while (true) {
    log("storage status: ${await Permission.location.status}");
    if ((await Permission.location
        .request())
        .isGranted) {
      log("storage status: ${await Permission.location.status}");
      break;
    }
  }
  while (true) {
    log("storage status: ${await Permission.locationAlways.status}");
    if ((await Permission.locationAlways
        .request())
        .isGranted) {
      log("storage status: ${await Permission.locationAlways.status}");
      break;
    }
  }
}

Future<void> requestStorageAccess() async {
  while (true) {
    log("storage status: ${await Permission.locationAlways.status}");
    if ((await Permission.storage
        .request())
        .isGranted) {
      log("storage status: ${await Permission.storage.status}");
      break;
    }
  }
}

Future<void> requestNotificationAccess() async {
  while (true) {
    log("storage status: ${await Permission.locationAlways.status}");
    if ((await Permission.notification
        .request())
        .isGranted) {
      log("storage status: ${await Permission.notification.status}");
      break;
    }
  }
}


Future<void> requestAllNecessaryPermissions() async {
  log("request all necessary permissions");
  await requestLocationAccess();
  await requestStorageAccess();
  await requestNotificationAccess();
}