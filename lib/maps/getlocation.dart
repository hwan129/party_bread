import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class GetLocation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모일 위치를 선택해주세요.'),
      ),
      body: const MapScreen(),
    );
  }
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final geoProvider = Provider.of<GeoProvider>(context, listen: false);

    final double latitude = geoProvider.latitude ?? 37.7749; // 기본값 (샌프란시스코)
    final double longitude = geoProvider.longitude ?? -122.4194; // 기본값 (샌프란시스코)

    final LatLng _center = LatLng(latitude, longitude);

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 18.0,
      ),
    );
  }
}
