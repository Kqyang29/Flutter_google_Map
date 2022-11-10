import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemapapp/location_service.dart';

class MultiUser extends StatefulWidget {
  const MultiUser({super.key});

  @override
  State<MultiUser> createState() => _MultiUserState();
}

class _MultiUserState extends State<MultiUser> {
  late GoogleMapController googleMapController;
  TextEditingController _searchController = TextEditingController();
  List<LatLng> polylineCoordinates = [];

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _markers.addAll(_list);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("multi user"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _searchController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: "Search",
                      ),
                      onChanged: (value) {
                        print(value);
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  var place = await LocationService().getPlace(
                    _searchController.text,
                  );
                  _goToPlace(place);
                },
                icon: Icon(Icons.search),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: Set<Marker>.of(_markers),
              initialCameraPosition: _kGooglePlex,
              // plus and min in the map
              zoomControlsEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                googleMapController = controller;
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          Position position = await _determinePosition();

          print(position);

          googleMapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 14,
              ),
            ),
          );

          _list.add(
            Marker(
              markerId: MarkerId("3"),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: InfoWindow(
                title: "My current location",
              ),
            ),
          );

          setState(() {
            _markers.addAll(_list);
          });
        },
        label: Text('my current location'),
        icon: Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToPlace(Map<String, dynamic> place) async {
    final double lat = place['geometry']['location']['lat'];
    final double lng = place['geometry']['location']['lng'];

    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 12,
        ),
      ),
    );

    _list.add(
      Marker(
        markerId: MarkerId("marker"),
        position: LatLng(lat, lng),
      ),
    );

    setState(
      () {
        _markers.addAll(_list);
      },
    );
  }

  //current location
  Future<Position> _determinePosition() async {
    // check user gps enable or not
    bool serviceEnable;

    LocationPermission permission;

    serviceEnable = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnable) {
      return Future.error("location service are disabled");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error("location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("location permission are permanently denied");
    }

    Position position = await Geolocator.getCurrentPosition();

    return position;
  }
}
