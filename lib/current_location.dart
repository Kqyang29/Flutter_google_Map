import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemapapp/location_service.dart';

class CurrentLocationPage extends StatefulWidget {
  const CurrentLocationPage({super.key});

  @override
  State<CurrentLocationPage> createState() => _CurrentLocationPageState();
}

class _CurrentLocationPageState extends State<CurrentLocationPage> {
  late GoogleMapController googleMapController;
  TextEditingController _searchController = TextEditingController();

  Set<Marker> markers = {};

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("Get Current User Location"),
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
              ElevatedButton(
                onPressed: () async {
                  Position position =
                      await LocationService().getCurrentPosition();

                  googleMapController.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(position.latitude, position.longitude),
                        zoom: 14,
                      ),
                    ),
                  );

                  markers.clear();

                  markers.add(
                    Marker(
                      markerId: MarkerId("currentLocation"),
                      position: LatLng(position.latitude, position.longitude),
                    ),
                  );

                  setState(() {});
                },
                child: Text("user"),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              markers: markers,
              initialCameraPosition: _kGooglePlex,
              // plus and min in the map
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                googleMapController = controller;
              },
            ),
          ),
        ],
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
    markers.clear();

    markers.add(
      Marker(
        markerId: MarkerId("marker"),
        position: LatLng(lat, lng),
      ),
    );

    setState(() {});
  }
}
