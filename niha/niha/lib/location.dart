import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:background_location/background_location.dart';
import 'package:permission_handler/permission_handler.dart';

class Explore extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const Explore({super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  final MapController mapController = MapController();
  LatLng? location;
  String? pincode;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      location = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _getPincode(location!.latitude, location!.longitude);
    }
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  void _getCurrentLocation() async {
    await BackgroundLocation.startLocationService();
    BackgroundLocation.getLocationUpdates((location) {
      setState(() {
        this.location = LatLng(location.latitude!, location.longitude!);
        mapController.move(this.location!, 13.0);
        _getPincode(location.latitude!, location.longitude!);
      });
    });
  }

  Future<void> _getPincode(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          pincode = placemarks.first.postalCode;
        }); // Print the pincode to the terminal
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 15, 94, 205),
          ),
          child: AppBar(
            title: const Text(
              'KO',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 25),
                  child: TextField(
                    onSubmitted: (value) {
                      _getLocationFromQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: GestureDetector(
                        onTap: _getCurrentLocation,
                        child: const Icon(Icons.location_searching_rounded),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 280,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: location ?? const LatLng(11.0168, 76.9558),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      if (location != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 150.0,
                              height: 150.0,
                              point: location!,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40.0,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (pincode != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Pincode: $pincode',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 15, 94, 205),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, pincode);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _getLocationFromQuery(String query) async {
    try {
      var locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        var firstLocation = locations.first;
        double latitude = firstLocation.latitude;
        double longitude = firstLocation.longitude;

        setState(() {
          location = LatLng(latitude, longitude);
          mapController.move(location!, 13.0);
          _getPincode(latitude, longitude);
        });
      } else {}
      // ignore: empty_catches
    } catch (e) {}
  }
}
