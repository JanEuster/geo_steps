import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// local imports
import 'package:geo_steps/src/application/homepoints.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/inputs.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/presentation/components/map.dart';
import 'package:geo_steps/src/utils/sizing.dart';

class HomepointsPage extends StatefulWidget {
  const HomepointsPage({super.key});

  @override
  State<StatefulWidget> createState() => _HomepointsPageState();
}

class _HomepointsPageState extends State<HomepointsPage> {
  bool addingPoint = false;
  MapEntry<String, Homepoint>? editingPoint;
  HomepointManager? homepointManager;

  @override
  void initState() {
    super.initState();

    homepointManager = HomepointManager();
    homepointManager!.init().then((value) async {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(
        child: ListView(padding: EdgeInsets.zero, children: [
          const SizedBox(
            height: 50,
            child: Center(
                child: Text(
              "places to track visits for",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            )),
          ),
          const Line(
            height: 4,
          ),
          if (homepointManager != null)
            Column(
              children:
                  List.generate(homepointManager!.homepoints.length, (index) {
                final point =
                    homepointManager!.homepoints.entries.toList()[index];
                log("$point");
                return SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Expanded(
                          child: Center(
                        child: Text(point.value.name),
                      )),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            editingPoint = point;
                            log("editing $editingPoint");
                          });
                        },
                        child: const SizedBox(
                          width: 50,
                          child: Icon(Icomoon.edit),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            homepointManager!.removePoint(point.key);
                          });
                        },
                        child: const SizedBox(
                          width: 50,
                          child: Icon(Icomoon.trash),
                        ),
                      ),
                    ],
                  ),
                );
              })
              // List.generate(length, (index) => null).toList()
              ,
            )
        ]),
      ),
      if (!addingPoint && editingPoint == null)
        Positioned(
            bottom: 40,
            right: 25,
            child: GestureDetector(
                onTap: () {
                  log("adding");
                  setState(() {
                    addingPoint = true;
                  });
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                      border: Border.all(width: 4)),
                  child: const Icon(
                    size: 36,
                    Icomoon.plus,
                    color: Colors.white,
                  ),
                ))),
      if (addingPoint || editingPoint != null)
        Positioned(
          top: 50 + 2,
          left: 10,
          child: AddHomepointModal(
              basedOn: editingPoint != null ? editingPoint!.value : null,
              onClose: (Homepoint? point) {
                log("close modal");
                log("with data $point");

                if (point != null) {
                  setState(() {
                    if (editingPoint != null) {
                      homepointManager!.updatePoint(editingPoint!.key, point);
                    } else {
                      homepointManager!.addPoint(point);
                    }
                  });
                }
                setState(() {
                  addingPoint = false;
                  editingPoint = null;
                });
              },
              confirmText: addingPoint
                  ? "Add"
                  : (editingPoint != null ? "Update" : null)),
        ),
    ]);
  }
}

class AddHomepointModal extends StatefulWidget {
  Function(Homepoint?) onClose;
  String? confirmText;
  Homepoint? basedOn;

  AddHomepointModal(
      {super.key, required this.onClose, this.confirmText, this.basedOn});

  @override
  State<StatefulWidget> createState() => _AddHomepointModalState();
}

class _AddHomepointModalState extends State<AddHomepointModal> {
  late MapController mapController = MapController();
  String name = "homepoint 1";
  double radius = 80;
  LatLng? point;
  final GlobalKey _mapKey = GlobalKey();
  bool failedToSubmit = false;

  @override
  void initState() {
    super.initState();

    if (widget.basedOn != null) {
      setState(() {
        name = widget.basedOn!.name;
        radius = widget.basedOn!.radius;
        point = widget.basedOn!.position;
      });
    }

    if (widget.basedOn != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        mapController.move(widget.basedOn!.position, 14.75);
      });
    } else {
      Geolocator.getLastKnownPosition().then((pos) {
        mapController.move(LatLng(pos!.latitude, pos!.longitude), 14);
      });
    }
  }

  void submit() {
    widget.onClose(Homepoint(name, point!, radius: radius));

    // reset
    setState(() {
      name = "homepoint 1";
      failedToSubmit = false;
      point = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    var sizer = SizeHelper();
    var width = sizer.width - 20;
    var height = sizer.heightWithoutNav - 100;
    return Container(
        width: width,
        height: height,
        decoration:
            BoxDecoration(color: Colors.white, border: Border.all(width: 2)),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomInputField(
              initialValue: name,
              label: "name",
              onChange: (newValue) => setState(() => name = newValue),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomSliderInput(
              label: "radius",
              range: MinMax(15, 500),
              onChange: (newValue) => setState(() => radius = newValue),
              initValue: radius,
              width: width - 16,
            ),
          ),
          const Line(
            height: 2,
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              child: FlutterMap(
                key: _mapKey,
                mapController: mapController,
                options: MapOptions(
                    onMapReady: () {
                      // set initial position on map
                    },
                    onTap: ((tapPosition, p) {
                      setState(() {
                        point = p;
                      });
                    }),
                    zoom: 13.0,
                    maxZoom: 19.0,
                    keepAlive: false,
                    interactiveFlags: // all interactions except rotation
                        InteractiveFlag.all & ~InteractiveFlag.rotate),
                nonRotatedChildren: [
                  CustomAttributionWidget.defaultWidget(
                    source: '© OpenStreetMap contributors',
                    sourceTextStyle:
                        const TextStyle(fontSize: 12, color: Color(0xFF0078a8)),
                    onSourceTapped: () {},
                  ),
                ],
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'dev.janeuster.geo_steps',
                  ),
                  if (point != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: point!,
                          radius: radius,
                          useRadiusInMeter: true,
                          color: Colors.white.withOpacity(0.6),
                          borderColor: Colors.black,
                          borderStrokeWidth: 3,
                        ),
                        CircleMarker(
                          point: point!,
                          radius: 4,
                          color: Colors.black,
                        )
                      ],
                    ),
                  if (point != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                            width: 46,
                            height: 46,
                            point: point!,
                            builder: (context) => Transform.translate(
                                offset: const Offset(0, -23),
                                child: Container(
                                    decoration: const BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage(
                                                "assets/map_pin.png")))))),
                      ],
                    )
                ],
              ),
            ),
          ),
          if (failedToSubmit)
            Container(
              height: 30,
              color: Colors.red,
              child: const Center(
                  child: Text("select a position for your homepoint on the map",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
            ),
          SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onClose(null),
                    child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(width: 2))),
                        child: Center(
                          child: Transform.rotate(
                              angle: math.pi / 4,
                              child: const Icon(Icomoon.plus, size: 40)),
                        )),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: () {
                      if (point != null) {
                        submit();
                      } else {
                        setState(() {
                          failedToSubmit = true;
                        });
                      }
                    },
                    child: Container(
                      color: Colors.black,
                      child: Center(
                          child: Text(
                        widget.confirmText ?? "Save",
                        style:
                            const TextStyle(fontSize: 24, color: Colors.white),
                      )),
                    ),
                  ),
                ),
              ],
            ),
          )
        ]));
  }
}
