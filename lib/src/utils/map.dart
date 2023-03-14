import 'dart:math' as math;

import 'package:geo_steps/src/application/location.dart';
import 'package:latlong2/latlong.dart';

double haversineFormula(MinMax<LatLng> range) {
  // generally used geo measurement function
  var R = 6378.137; // Radius of earth in KM
  var dLat =
      range.max.latitude * math.pi / 180 - range.min.latitude * math.pi / 180;
  var dLon =
      range.max.longitude * math.pi / 180 - range.min.longitude * math.pi / 180;
  var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(range.min.latitude * math.pi / 180) *
          math.cos(range.max.latitude * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  var d = R * c;
  return d * 1000; // meters
}

double getZoomLevel(MinMax<LatLng> range) {
  double radius = haversineFormula(range);
  double zoomLevel = 11;
  if (radius > 0) {
    double radiusElevated = radius + radius / 2;
    double scale = radiusElevated / 500;
    zoomLevel = 16 - math.log(scale) / math.log(2);
  }
  zoomLevel = double.parse(zoomLevel.toStringAsFixed(2));
  return zoomLevel;
}