import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemapapp/location_service.dart';
import 'package:location/location.dart';

class LiveTracker extends StatefulWidget {
  const LiveTracker({super.key});

  @override
  State<LiveTracker> createState() => _LiveTrackerState();
}

class _LiveTrackerState extends State<LiveTracker> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation =
      LatLng(37.42796133580664, -122.085749655962);
  static const LatLng destinationLocation = LatLng(37.427961, 122.085742);

  List<LatLng> polylineCoordinates = [];

  LocationData? currentLocation;

  List<Marker> _markers = [];

  List<Marker> _list = [
    Marker(
      markerId: MarkerId("1"),
      position: LatLng(37.42796133580664, -122.085749655962),
      infoWindow: InfoWindow(
        title: "My first post point",
      ),
    ),
    Marker(
      markerId: MarkerId("1"),
      position: LatLng(37, -122),
      infoWindow: InfoWindow(
        title: "My second post point",
      ),
    ),
  ];

  void getCurrentLocation() {
    Location location = Location();

    location.getLocation().then(
      (location) {
        currentLocation = location;
        _list.add(
          Marker(
            markerId: MarkerId("currentLocation"),
            position:
                LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
            infoWindow: InfoWindow(
              title: "currentLocation",
            ),
          ),
        );
        _markers.addAll(_list);
      },
    );
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      LocationService().key,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destinationLocation.latitude, destinationLocation.longitude),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );

      setState(() {});
    }
  }

  @override
  void initState() {
    getCurrentLocation();
    // getPolyPoints();

    super.initState();
    _markers.addAll(_list);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("Live Tracker"),
        centerTitle: true,
        elevation: 0,
      ),
      body: currentLocation == null
          ? Center(
              child: Text("Loading"),
            )
          : GoogleMap(
              mapType: MapType.normal,
              // polylines: {
              //   Polyline(
              //     polylineId: PolylineId("route"),
              //     points: polylineCoordinates,
              //     color: Colors.blue,
              //     width: 5,
              //   ),
              // },
              markers: Set<Marker>.of(_markers),
              // markers: _markers,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
                zoom: 13.5,
              ),
              // plus and min in the map
              zoomControlsEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () async {
      //     Position position = await _determinePosition();

      //     googleMapController.animateCamera(
      //       CameraUpdate.newCameraPosition(
      //         CameraPosition(
      //           target: LatLng(position.latitude, position.longitude),
      //           zoom: 14,
      //         ),
      //       ),
      //     );

      //     _list.add(
      //       Marker(
      //         markerId: MarkerId("3"),
      //         position: LatLng(position.latitude, position.longitude),
      //         infoWindow: InfoWindow(
      //           title: "My current location",
      //         ),
      //       ),
      //     );

      //     setState(() {
      //       _markers.addAll(_list);
      //     });
      //   },
      //   label: Text('my current location'),
      //   icon: Icon(Icons.directions_boat),
      // ),
    );
  }
}
