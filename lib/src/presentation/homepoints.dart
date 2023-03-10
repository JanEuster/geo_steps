import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geo_steps/src/application/homepoints.dart';
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/presentation/components/icons.dart';
import 'package:geo_steps/src/presentation/components/inputs.dart';
import 'package:geo_steps/src/presentation/components/lines.dart';
import 'package:geo_steps/src/presentation/components/map.dart';
import 'package:geo_steps/src/utils/sizing.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class HomepointsPage extends StatefulWidget {
  const HomepointsPage({super.key});

  @override
  State<StatefulWidget> createState() => _HomepointsPageState();
}

class _HomepointsPageState extends State<HomepointsPage> {
  bool addingPoint = true;
  bool editingPoint = false;

  @override
  void initState() {
    super.initState();
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
          Column(
            children: []
            // List.generate(length, (index) => null).toList()
            ,
          )
        ]),
      ),
      if (!addingPoint)
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
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                      border: Border.all(width: 4)),
                  child: const Icon(size: 36, Icomoon.plus),
                ))),
      if (addingPoint)
        Positioned(
          top: 50 + 2,
          left: 10,
          child: AddHomepointModal(
              onClose: (Homepoint point) {},
              confirmText:
                  addingPoint ? "Add" : (editingPoint ? "Update" : null)),
        ),
    ]);
  }
}

class AddHomepointModal extends StatefulWidget {
  Function(Homepoint) onClose;
  String? confirmText;

  AddHomepointModal({super.key, required this.onClose, this.confirmText});

  @override
  State<StatefulWidget> createState() => _AddHomepointModalState();
}

class _AddHomepointModalState extends State<AddHomepointModal> {
  late MapController mapController;
  String name = "";
  double radius = 80;
  LatLng? point;
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    mapController = MapController();
    Geolocator.getLastKnownPosition().then((pos) {
      mapController.move(LatLng(pos!.latitude, pos!.longitude), 14);
    });
    Geolocator.getCurrentPosition().then((pos) {
      mapController.move(LatLng(pos.latitude, pos.longitude), 14);
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
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomInputField(
              initialValue: "homepoint 1",
              label: "name",
              onChange: (newValue) => setState(() => name = newValue),
            ),
          )),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomSliderInput(
                label: "radius",
                range: MinMax(15, 500),
                onChange: (newValue) {},
                initValue: radius,
                width: width - 16,
              ),
            ),
          ),
          const Line(
            height: 2,
          ),
          Expanded(
            flex: 4,
            child: GestureDetector(
              // onTapDown: (details) {
              //   final size = _mapKey.currentContext!.size;
              //   final mapWidth = size!.width;
              //   final mapHeight = size!.height;
              //   final clickX = details.localPosition.dx;
              //   final clickY = details.localPosition.dy;
              //
              //   final xPercent = clickX/mapWidth;
              //   final yPercent = 1-clickY/mapHeight;
              //   log("x ${xPercent*100}% y ${yPercent*100}%");
              //
              //   final mapWest = mapController.bounds!.west;
              //   final mapEast = mapController.bounds!.east;
              //   final mapNorth = mapController.bounds!.north;
              //   final mapSouth = mapController.bounds!.south;
              //
              //   final mapLatDiff = getCoordDiff(mapEast, mapWest);
              //   final mapLngDiff = getCoordDiff(mapNorth, mapSouth);
              //
              //   // log("lat $mapLatDiff lng $mapLngDiff");
              //   log("map: ${mapController.center}");
              //   log("n $mapNorth");
              //   log("s $mapSouth");
              //   log("w $mapWest");
              //   log("e $mapEast");
              //
              //   double latitude = mapSouth + mapLatDiff * yPercent;
              //   double longitude = mapWest + mapLngDiff * xPercent;
              //   setState(() {
              //     point = LatLng(latitude, longitude);
              //   });
              //   log("$point");
              // },
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
                    keepAlive: true,
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
          Container(
            height: 60,
            color: Colors.black,
            child: Center(
                child: Text(
              widget.confirmText ?? "Save",
              style: TextStyle(fontSize: 24, color: Colors.white),
            )),
          )
        ]));
  }
}
