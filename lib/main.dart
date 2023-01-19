import 'dart:async';
import "dart:developer";

import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart'
    as nl;
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

// local imports
import 'package:geo_steps/src/presentation/home.dart';
import 'package:geo_steps/src/presentation/nav.dart';
import 'package:geo_steps/src/presentation/map.dart';
import 'package:geo_steps/src/application/notification.dart';
import 'package:geo_steps/src/application/background_tasks.dart';
import 'package:geo_steps/src/utils/permissions.dart';
import 'package:geo_steps/src/application/preferences.dart';

// ignore: constant_identifier_names
const String APP_TITLE = "geo_steps";

// define the handler for ui
void onData(nl.NotificationEvent event) {
  log(event.toString());
}

Future<void> initPlatformState() async {
  nl.NotificationsListener.initialize();
  // register you event handler in the ui logic.
  nl.NotificationsListener.receivePort?.listen((evt) => onData(evt));
}

void startListeningToNotifications() async {
  log("start listening");
  var hasPermission = await nl.NotificationsListener.hasPermission;
  if (!hasPermission!) {
    log("no permission, so open settings");
    nl.NotificationsListener.openPermissionSettings();
    return;
  }

  var isR = await nl.NotificationsListener.isRunning;

  if (!isR!) {
    await nl.NotificationsListener.startService(
        foreground: true,
        // use false will not promote to foreground and without a notification
        title: "Change the title",
        description: "Change the text");
  }
}

void main() async {
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null, // default icon
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          playSound: false,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          onlyAlertOnce: true,
          enableVibration: false,
          enableLights: false,
        ),
        NotificationChannel(
          channelKey: 'geolocator_channel_01',
          channelName: 'Background Location Notices',
          channelDescription: 'GPS',
          playSound: false,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          onlyAlertOnce: true,
          enableVibration: false,
          enableLights: false,
        ),
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);

  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );

  // set initial values for app settings if not already set
  // before the app is built
  AppSettings().initialize().then((_) {
    runApp(MyWidgetsApp());
  });
}

class AppRoute {
  String title;
  String route;
  IconData icon;
  StatelessWidget page;

  AppRoute(this.title, this.route, this.icon, this.page);
}

class MyWidgetsApp extends StatefulWidget {
  String title = APP_TITLE;

  final Map<String, AppRoute> routes = {
    "/": AppRoute(
        APP_TITLE, "/", Icons.nordic_walking, Container(child: const MyHomePage())),
    "/today": AppRoute(
        "today",
        "/today",
        Icons.bar_chart,
        ListView(children: const [
          SimpleMap(),
        ])),
    "/overviews":
        AppRoute("overviews", "/overviews", Icons.leaderboard, Container()),
    "/places": AppRoute("home⋅points", "/places", Icons.push_pin, Container()),
  };
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  MyWidgetsApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyWidgetsAppState();
}

class _MyWidgetsAppState extends State<MyWidgetsApp> {
  @override
  void initState() {
    requestAllNecessaryPermissions();
    // startListeningToNotifications();

    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);

    super.initState();
  }

  Route generate(RouteSettings settings) {
    Route page;
    if (widget.routes[settings.name] != null) {
      widget.title = widget.routes[settings.name]!.title;
      page = PageRouteBuilder(pageBuilder: (BuildContext context,
          Animation<double> animation, Animation<double> secondaryAnimation) {
        EdgeInsets insets = MediaQuery.of(context).viewInsets;
        EdgeInsets padding = MediaQuery.of(context).viewPadding;
        log("device insets || insets: $insets, padding: $padding");
        return PageWithNav(
            title: widget.title,
            color: const Color(0xFFFFFFFF),
            navItems: widget.routes.values.toList(),
            child: widget.routes[settings.name]?.page);
      }, transitionsBuilder: (_, Animation<double> animation,
          Animation<double> second, Widget child) {
        return FadeTransition(
          opacity: animation,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(second),
            child: child,
          ),
        );
      });
    } else {
      page = unKnownRoute(settings);
    }

    return page;
  }

  Route unKnownRoute(RouteSettings settings) {
    return PageRouteBuilder(pageBuilder: (BuildContext context,
        Animation<double> animation, Animation<double> secondaryAnimation) {
      return PageWithNav(
          title: "error",
          color: const Color(0xFFFFFFFF),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "Error!",
                  textDirection: TextDirection.ltr,
                ),
                const Padding(padding: EdgeInsets.all(10.0)),
                GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          color: const Color(0xFFAAAAFF),
                          child: const Text("Return to Home Page"),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          color: const Color(0xFFBBAAFF),
                          child: const Text("Return to Home Page"),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          color: const Color(0xFFCCAAFF),
                          child: const Text("Return to Home Page"),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          color: const Color(0xFFDDAAFF),
                          child: const Text("Return to Home Page"),
                        ),
                      ],
                    ))
              ]));
    });
  }

  @override
  Widget build(BuildContext context) {
    log("target: ${Theme.of(context).platform}");
    return WidgetsApp(
      navigatorKey: MyWidgetsApp.navigatorKey,
      onGenerateRoute: generate,
      onUnknownRoute: unKnownRoute,
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
      initialRoute: "/",
      color: const Color.fromRGBO(255, 0, 0, 1.0),
      title: widget.title,
    );
  }
}
