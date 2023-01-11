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

          return PageWithNav(title: title, color: const Color(0xFFFFFFFF), child: const MyHomePage());
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
    return WidgetsApp(
      onGenerateRoute: generate,
      onUnknownRoute: unKnownRoute,
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
      initialRoute: "/",
      color: const Color.fromRGBO(255, 0, 0, 1.0),
      title: title,
    );
  }
}

class PageWithNav extends StatelessWidget {
  PageWithNav({super.key, this.title = "", this.child, this.color});

  String title;
  Widget? child;
  Color? color;

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    EdgeInsets padding = media.viewPadding;
    return Column(children: [
      Padding(padding: EdgeInsets.only(top: padding.top)),
      Navbar(title: title),
      Container(
          color: color,
          child:       SizedBox(
              height: media.size.height -
                  46 -
                  media.viewPadding.top -
                  media.viewPadding.bottom,
              child: child),),
      Padding(padding: EdgeInsets.only(bottom: padding.bottom)),
    ]);
  }
}

class Navbar extends StatelessWidget {
  Navbar({super.key, this.title = ""});

  String title;

  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          color: Colors.white,
          height: 45,
          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              child: Row(
                children: [
                  GestureDetector(onTap: () {}, child: const Icon(Icons.menu)),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      title,
                      style: const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(onTap: () {}, child: const Icon(Icons.settings)),
          ])),
      Container(height: 1, color: Colors.black),
    ]);
  }
}

class ActivityMap extends StatelessWidget {
  ActivityMap({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    return Container(
        height: 380,
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
                width: media.size.width,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        child: const Text("todays map",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500))),
                    Container(
                        color: Colors.black,
                        width: media.size.width / 5 * 3,
                        height: 380)
                  ],
                ))));
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);

    return SizedBox(
        height: media.size.height -
            46 -
            media.viewPadding.top -
            media.viewPadding.bottom,
        child: ListView(children: [
          Container(
              child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text("3.742",
                              style: TextStyle(
                                  fontSize: 75, fontWeight: FontWeight.w900)),
                          Text("10,2 km",
                              style: TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.w700)),
                        ],
                      )),
                      Container(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Padding(
                                  padding: EdgeInsets.only(top: 50),
                                  child:
                                      Text("steps today", style: TextStyle())),
                              Padding(
                                  padding: EdgeInsets.only(top: 35),
                                  child: Text("traveled today",
                                      style: TextStyle()))
                            ],
                          )),
                    ],
                  ))),
          Container(
              child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Container(
                      width: media.size.width,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black)),
                      child: Column(
                        children: [
                          Container(
                              width: media.size.width,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("tracking uptime",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700)),
                                  const Padding(
                                      padding: EdgeInsets.only(top: 12)),
                                  Row(
                                    children: const [
                                      Text("24 ",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700)),
                                      Text("days",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                  const Padding(
                                      padding: EdgeInsets.only(top: 6)),
                                  Row(
                                    children: const [
                                      Text("154.00 ",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700)),
                                      Text("steps",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400)),
                                    ],
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.arrow_right_alt, size: 40),
                                      Padding(
                                          padding: EdgeInsets.only(bottom: 5),
                                          child: Text("more info",
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight:
                                                      FontWeight.w500))),
                                    ],
                                  ),
                                ],
                              )),
                          Container(
                              width: media.size.width,
                              height: 40,
                              decoration: const BoxDecoration(
                                  image: DecorationImage(
                                      image:
                                          AssetImage("assets/line_pattern.jpg"),
                                      repeat: ImageRepeat.repeat))),
                          Container(
                            width: media.size.width,
                            height: 40,
                            child: GestureDetector(
                                onTap: () {},
                                child: const Center(
                                    child: Text("stop tracking",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500)))),
                          )
                        ],
                      )))),
          ActivityMap()
        ]));
  }
}
