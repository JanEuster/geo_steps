// flutter imports
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

// local imports
import 'package:geo_steps/src/application/location.dart';
import 'package:geo_steps/src/utils/map.dart';
import 'package:geo_steps/src/utils/sizing.dart';

class MapPreview extends StatefulWidget {
  List<LocationDataPoint> data = [];
  late double zoomMultiplier;

  MapPreview({super.key, required this.data, this.zoomMultiplier = 1});

  @override
  State<StatefulWidget> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  final mapController = MapController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        var coordRange = getCoordRange(widget.data);
        mapController.move(getCoordCenter(coordRange),
            widget.zoomMultiplier * getZoomLevel(coordRange));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeHelper sizer = SizeHelper();
    return Container(
      color: Colors.black,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
            onMapReady: () {
              // set initial position on map
            },
            zoom: 13.0,
            maxZoom: 19.0,
            keepAlive: true,
            interactiveFlags: // all interactions except rotation
                InteractiveFlag.none),
        nonRotatedChildren: [
          CustomAttributionWidget.defaultWidget(
            source: 'geo_steps',
            sourceTextStyle:
                const TextStyle(fontSize: 12, color: Color(0xFF0078a8)),
            onSourceTapped: () {},
          ),
        ],
        children: [
          // TileLayer(
          //   urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          //   userAgentPackageName: 'dev.janeuster.geo_steps',
          // ),

          PolylineLayer(
            polylineCulling: false,
            polylines: [
              Polyline(
                points: widget.data.toLatLng(),
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
          // if (locationService.hasPositions)
          //   MarkerLayer(
          //     markers: [
          //       Marker(
          //           point: LatLng(locationService.lastPos.latitude,
          //               locationService.lastPos.longitude),
          //           builder: (context) => const FlutterLogo())
          //     ],
          //   )
        ],
      ),
    );
  }
}



class CustomAttributionWidget extends AttributionWidget {
  const CustomAttributionWidget({super.key, required super.attributionBuilder});

  static Widget defaultWidget({
    required String source,
    void Function()? onSourceTapped,
    TextStyle sourceTextStyle = const TextStyle(color: Color(0xFF0078a8)),
    Alignment alignment = Alignment.bottomRight,
  }) =>
      Align(
        alignment: alignment,
        child: ColoredBox(
          color: const Color(0xCCFFFFFF),
          child: GestureDetector(
            onTap: onSourceTapped,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    cursor: onSourceTapped == null
                        ? MouseCursor.defer
                        : SystemMouseCursors.click,
                    child: Text(
                      source,
                      style: onSourceTapped == null ? null : sourceTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
