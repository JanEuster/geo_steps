import 'dart:async';
import "dart:developer";

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart'
    as nl;
import 'package:awesome_notifications/awesome_notifications.dart';
import "package:flutter_activity_recognition/flutter_activity_recognition.dart";

// local imports
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/homepoints.dart';
import 'package:geo_steps/src/presentation/overview.dart';
import 'package:geo_steps/src/presentation/today.dart';
import 'package:geo_steps/src/presentation/home.dart';
import 'package:geo_steps/src/presentation/components/nav.dart';
import 'package:geo_steps/src/application/notification.dart';
import 'package:geo_steps/src/application/background_tasks.dart';
import 'package:geo_steps/src/utils/permissions.dart';
import 'package:geo_steps/src/application/preferences.dart';

// ignore: constant_identifier_names
const String APP_TITLE = "geo_steps";
const String SPLASH_SCREEN = "spash_screen";


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      "resource://drawable/res_notifications_icon", // default icon
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
            channelGroupName: 'geo_steps')
      ],
      debug: false);

  await initializeBackgroundService();

  var isTrackingLocation = await AppSettings.instance.trackingLocation.get();
  log("isTrackingLocation: $isTrackingLocation");
  if (isTrackingLocation == true) {
    await FlutterBackgroundService().startService();
    // FlutterBackgroundService().invoke("startTracking");
  }

  // set initial values for app settings if not already set
  // before the app is built
  AppSettings.initialize().then((_) {
    runApp(MyWidgetsApp());
  });
}

class AppRoute {
  String title;
  String route;
  IconData icon;
  Widget page;

  AppRoute(this.title, this.route, this.icon, this.page);
}

class MyWidgetsApp extends StatefulWidget {
  final Map<String, AppRoute> routes = {
    "/": AppRoute(APP_TITLE, "/", Icomoon.walking_1, const MyHomePage()),
    "/today": AppRoute("today", "/today", Icomoon.stats_1, const TodayPage()),
    "/overviews": AppRoute(
        "overviews", "/overviews", Icomoon.stats_2, const OverviewPage()),
    "/places": AppRoute(
        "home⋅points", "/places", Icomoon.homepin_1, const HomepointsPage()),
  };
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  MyWidgetsApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyWidgetsAppState();
}

class LoadingAnimation extends StatelessWidget {
  double? width;
  double? height;

  LoadingAnimation({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/loading.gif"),
                repeat: ImageRepeat.repeat)));
  }
}

class _MyWidgetsAppState extends State<MyWidgetsApp> {
  final _activityStreamController = StreamController<Activity>();
  StreamSubscription<Activity>? _activityStreamSubscription;

  @override
  void initState() {
    super.initState();
    requestAllNecessaryPermissions();

    // Only after at least the action method is set, the notification events are delivered
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);
  }

  @override
  void dispose() {
    _activityStreamController.close();
    _activityStreamSubscription?.cancel();
    super.dispose();
  }

  Route generate(RouteSettings settings) {
    Route page;
    if (widget.routes[settings.name] != null) {
      var title = widget.routes[settings.name]!.title;
      page = PageRouteBuilder(pageBuilder: (BuildContext context,
          Animation<double> animation, Animation<double> secondaryAnimation) {
        // EdgeInsets insets = MediaQuery.of(context).viewInsets;
        // EdgeInsets padding = MediaQuery.of(context).viewPadding;

        return PageWithNav(
            title: title,
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
    } else if (settings.name == SPLASH_SCREEN) {
      page = PageRouteBuilder(
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(seconds: 3), () {
              Navigator.of(context).pushReplacementNamed("/");
            });
          });
          return Container(color: Colors.white,child: Center(child: LoadingAnimation(width: 80, height: 80)));
        },
      );
    } else if (settings.name == "/notification-page") {
      // redirect to today page from notification
      var c = context;
      // SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      //   Navigator.of(c).pushNamed("/today");
      // });
      // page = PageWithNav(title: "Notification Page", navItems: widget.routes.values.toList(), child: const Text("redirecting to relevant page"),) as Route;

      var route = widget.routes["/today"]!;
      page = PageRouteBuilder(pageBuilder: (BuildContext context,
          Animation<double> animation, Animation<double> secondaryAnimation) {
        // EdgeInsets insets = MediaQuery.of(context).viewInsets;
        // EdgeInsets padding = MediaQuery.of(context).viewPadding;

        return PageWithNav(
            title: route.title,
            color: const Color(0xFFFFFFFF),
            navItems: widget.routes.values.toList(),
            child: route.page);
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
    } else if (settings.name == "/notification-page") {
      // redirect to today page from notification
      var c = context;
      // SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      //   Navigator.of(c).pushNamed("/today");
      // });
      // page = PageWithNav(title: "Notification Page", navItems: widget.routes.values.toList(), child: const Text("redirecting to relevant page"),) as Route;

      var route = widget.routes["/today"]!;
      page = PageRouteBuilder(pageBuilder: (BuildContext context,
          Animation<double> animation, Animation<double> secondaryAnimation) {
        // EdgeInsets insets = MediaQuery.of(context).viewInsets;
        // EdgeInsets padding = MediaQuery.of(context).viewPadding;

        return PageWithNav(
            title: route.title,
            color: const Color(0xFFFFFFFF),
            navItems: widget.routes.values.toList(),
            child: route.page);
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
                        Text(settings.name ?? ""),
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
      initialRoute: SPLASH_SCREEN,
      color: const Color.fromRGBO(255, 0, 0, 1.0),
      title: APP_TITLE,
    );
  }
}
