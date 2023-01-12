import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import "dart:developer";

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);

    return ListView(children: [
      Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text("3.742",
                      style:
                      TextStyle(fontSize: 75, fontWeight: FontWeight.w900)),
                  Text("10,2 km",
                      style:
                      TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
                ],
              ),
              Container(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text("steps today", style: TextStyle())),
                      Padding(
                          padding: EdgeInsets.only(top: 35),
                          child: Text("traveled today", style: TextStyle()))
                    ],
                  )),
            ],
          )),
      Padding(
          padding: const EdgeInsets.all(30),
          child: Container(
              width: media.size.width,
              decoration:
              BoxDecoration(border: Border.all(color: Colors.black)),
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
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const Padding(padding: EdgeInsets.only(top: 12)),
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
                          const Padding(padding: EdgeInsets.only(top: 6)),
                          Row(
                            children: const [
                              Text("154.00 ",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700)),
                              Text("steps",
                                  textAlign: TextAlign.left,
                                  style:
                                  TextStyle(fontWeight: FontWeight.w400)),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Icon(Icons.arrow_right_alt, size: 40),
                              Padding(
                                  padding: EdgeInsets.only(bottom: 5),
                                  child: Text("more info",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500))),
                            ],
                          ),
                        ],
                      )),
                  Container(
                      width: media.size.width,
                      height: 40,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/line_pattern.jpg"),
                              repeat: ImageRepeat.repeat))),
                  SizedBox(
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
              ))),
      const ActivityMap()
    ]);
  }
}

class ActivityMap extends StatelessWidget {
  const ActivityMap({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQueryData media = MediaQuery.of(context);
    return SizedBox(
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
