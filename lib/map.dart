import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

class Maps extends StatefulWidget {
  @override
  _MapsState createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  GoogleMapController? mapController;
  LatLng currentLocation = LatLng(9.456212021104868, 77.79621762414783);
  LatLng destination = LatLng(0, 0);
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  BitmapDescriptor? scooterIcon;

  void setCustomMarkerIcons() async {
    scooterIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'images/custommarker.png',
    );

    setState(() {
      // Update the marker icon with the scooterIcon
      markers = markers.map((marker) {
        if (marker.markerId == MarkerId('currentLocation')) {
          return marker.copyWith(iconParam: scooterIcon);
        }
        return marker;
      }).toSet();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchDestinationCoordinates();
    getCurrentLocation();
    setCustomMarkerIcons();
  }

  void fetchDestinationCoordinates() async {
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String apiUrl = 'http://Santhose:3000/map?date=$currentDate';

    var response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print('Response Body: $data');
      if (data != null && data['locations'] != null) {
        List<dynamic> locations = data['locations'];

        // Find the highest latitude and longitude
        double highestLat = double.negativeInfinity;
        double highestLng = double.negativeInfinity;

        locations.forEach((location) {
          double latitude = double.parse(location['lat'].toString());
          double longitude = double.parse(location['log'].toString());

          // Update highest latitude and longitude if found
          if (latitude > highestLat && longitude > highestLng) {
            highestLat = latitude;
            highestLng = longitude;
          }

          LatLng latLng = LatLng(latitude, longitude);
          setState(() {
            markers.add(
              Marker(
                markerId: MarkerId('$latitude-$longitude'),
                position: latLng,
                icon: BitmapDescriptor.defaultMarker,
              ),
            );
          });
        });

        // Set the highest latitude and longitude as the destination
        LatLng destination = LatLng(highestLat, highestLng);

        setState(() {
          markers.add(
            Marker(
              markerId: MarkerId('destination'),
              position: destination,
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
        });
      } else {
        print('Invalid data format');
      }
    } else {
      print('Failed to fetch destination coordinates.');
    }
  }

  void drawRoute(LatLng destination) async {
    String apiKey = 'AIzaSyCBd9MiKrWxkR0Sau2pUsMeKJ5ncvkUXFk';

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation.latitude},${currentLocation.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data.containsKey('routes') &&
          data['routes'] is List &&
          data['routes'].length > 0) {
        List<LatLng> routeCoords =
            decodePolyline(data['routes'][0]['overview_polyline']['points']);
        setState(() {
          polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: routeCoords,
            color: Colors.purple,
            width: 5,
          ));
        });
      } else {
        print('No valid route found');
      }
    } else {
      print('Failed to fetch route data. Status code: ${response.statusCode}');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1e5;
      double longitude = lng / 1e5;
      points.add(LatLng(latitude, longitude));
    }

    return points;
  }

  /*void getCurrentLocation() async {
    /*geolocator.Position? currentPosition;
    geolocator.LocationPermission permission =
        await geolocator.Geolocator.checkPermission();

    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied ||
          permission == geolocator.LocationPermission.deniedForever) {
        return;
      }
    }

    currentPosition = await geolocator.Geolocator.getCurrentPosition(
      desiredAccuracy: geolocator.LocationAccuracy.best,
    );

    if (currentPosition != null) {
      setState(() {
        currentLocation = LatLng(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );

        markers.removeWhere(
            (marker) => marker.markerId.value == 'currentLocation');

        markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: currentLocation,
            icon: scooterIcon!,
          ),
        );

        drawRoute(destination);
      });
    }*/

    setState(() {
      currentLocation = LatLng(9.456212021104868, 77.79621762414783);

      markers
          .removeWhere((marker) => marker.markerId.value == 'currentLocation');

      markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: currentLocation,
          icon: scooterIcon!,
        ),
      );

      drawRoute(destination);
    });
  }*/
  void getCurrentLocation() {
    setState(() {
      currentLocation = LatLng(9.456212021104868, 77.79621762414783);

      markers
          .removeWhere((marker) => marker.markerId.value == 'currentLocation');

      markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: currentLocation,
          icon: scooterIcon != null
              ? scooterIcon!
              : BitmapDescriptor.defaultMarker,
        ),
      );

      drawRoute(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Location'),
        backgroundColor: Colors.purple[100],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLocation,
          zoom: 13,
        ),
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        markers: markers,
        polylines: polylines,
      ),
    );
  }
}
