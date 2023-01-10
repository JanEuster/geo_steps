import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "dart:developer";

void main() => runApp(new MyWidgetsApp());

class MyWidgetsApp extends StatelessWidget {
  final String title = "geo_steps";

  Route generate(RouteSettings settings) {
    Route page;
    switch (settings.name) {
      case "/":
        page = PageRouteBuilder(pageBuilder: (BuildContext context,
            Animation<double> animation, Animation<double> secondaryAnimation) {
          EdgeInsets insets = MediaQuery.of(context).viewInsets;
          EdgeInsets padding = MediaQuery.of(context).viewPadding;
          log("device insets || insets: $insets, padding: $padding");
          return Container(
              color: const Color.fromRGBO(255, 255, 255, 1.0),
              child: Column(children: [
                Padding(padding: EdgeInsets.only(top: padding.top)),
                MyHomePage(title: title),
                Padding(padding: EdgeInsets.only(top: padding.bottom)),
              ]));
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
        break;
      default:
        {
          page = unKnownRoute(settings);
        }
    }
    return page;
  }

  Route unKnownRoute(RouteSettings settings) {
    return PageRouteBuilder(pageBuilder: (BuildContext context,
        Animation<double> animation, Animation<double> secondaryAnimation) {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Error!",
              textDirection: TextDirection.ltr,
            ),
            const Padding(padding: EdgeInsets.all(10.0)),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                color: const Color.fromRGBO(0, 0, 255, 1.0),
                child: const Text("Return to Home Page"),
              ),
            )
          ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      onGenerateRoute: generate,
      onUnknownRoute: unKnownRoute,
      textStyle: const TextStyle(),
      initialRoute: "/",
      color: const Color.fromRGBO(255, 0, 0, 1.0),
      title: title,
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key, this.title = ""});

  String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
            color: Colors.white,
            height: 45,
            padding: EdgeInsets.only(left: 10.0, right: 10.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Row(
                      children: [
                        GestureDetector(onTap: () {}, child: Icon(Icons.menu)),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            title,
                            textScaleFactor: 1.2,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(onTap: () {}, child: Icon(Icons.settings)),
                ])),
        Container(height: 1, color: Colors.black),
        const Padding(padding: EdgeInsets.all(10.0)),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed("/first"),
          child: Container(
            padding: EdgeInsets.all(10.0),
            color: const Color.fromRGBO(0, 0, 255, 1.0),
            child: const Text("Go to First Page"),
          ),
        ),
        const Padding(padding: EdgeInsets.all(10.0)),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed("/abcd"),
          child: Container(
            padding: const EdgeInsets.all(10.0),
            color: const Color.fromRGBO(0, 0, 255, 1.0),
            child: const Text("Unkown Route"),
          ),
        )
      ],
    );
  }
}
