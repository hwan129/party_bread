import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../provider.dart';

class GetLocation extends StatefulWidget {
  @override
  _GetLocationState createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocation> {
  late GoogleMapController _mapController;

  Marker? _currentMarker; // 현재 위치를 표시할 마커

  @override
  void initState() {
    super.initState();
    final geoProvider = Provider.of<GeoProvider>(context, listen: false);
    geoProvider.fetchGeoData(); // 앱 시작 시 위치 정보 가져오기
  }

  void _updateMarker(double latitude, double longitude) {
    setState(() {
      _currentMarker = Marker(
        markerId: MarkerId("selected_location"),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(title: "팟빵을 구울 위치"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final geoProvider = Provider.of<GeoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("모일 위치를 선택해주세요."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('선택 완료'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                geoProvider.latitude ?? 0.0,
                geoProvider.longitude ?? 0.0,
              ),
              zoom: 18,
            ),
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMarker(
                geoProvider.latitude!,
                geoProvider.longitude!,
              );
            },
            markers: _currentMarker != null ? {_currentMarker!} : {},
            onTap: (LatLng coordinate) {
              _mapController.animateCamera(
                CameraUpdate.newLatLng(coordinate),
              );
              _updateMarker(coordinate.latitude, coordinate.longitude);
              print(coordinate); // 마커 찍은 위치
            },
          ),
        ],
      ),
    );
  }
}
