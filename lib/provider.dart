import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GeoProvider with ChangeNotifier {
  String? _latitude;
  String? _longitude;
  String? _Si;
  String? _Gu;
  String? _Dong;
  String? _street;
  String? _errorMessage;

  String? get latitude => _latitude;
  String? get longitude => _longitude;
  String? get Si => _Si;
  String? get Gu => _Gu;
  String? get Dong => _Dong;
  String? get street => _street;
  String? get errorMessage => _errorMessage;

  bool isLoading = true;

  final String _API_KEY = 'AIzaSyAQ4KUztl0w0BqwRJSpf3EGWt49ascwPdQ';

  Future<void> fetchGeoData() async {
    try {
      // 위치 정보 획득 가능한지 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('위치 권한이 거부되었습니다.');
        return;
      }
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('위치 권한이 거부되었습니다.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 활성화해주세요.');
        return;
      }

      // 위치 정보 가져오기
      Position position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
      _errorMessage = null;

      print('position: $position');

      // 주소 가져오기
      await _fetchAddressFromCoordinates();

      notifyListeners();
    } catch (e) {
      _setError('오류 발생: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAddressFromCoordinates() async {
    try {
      if (_latitude == null || _longitude == null) {
        _setError('유효하지 않은 위도/경도 값입니다.');
        return;
      }

      final gpsUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$_latitude,$_longitude&key=$_API_KEY&language=ko';

      final response = await http.get(Uri.parse(gpsUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print(
            'Google Maps API Response: ${data['results'][0]['address_components']}');

        if (data['results'] != null && data['results'].isNotEmpty) {
          final address = data['results'][0]['address_components'];
          _Si = address[3]['long_name'];
          _Gu = address[2]['long_name'];
          _Dong = address[1]['long_name'];
          _street = address[0]['long_name'];
          _errorMessage = null;
          // isLoading = true;
          // notifyListeners();
        } else {
          _setError('주소를 찾을 수 없습니다.');
        }
      } else {
        _setError('Google Maps API 요청 실패: 상태 코드 ${response.statusCode}');
      }
    } catch (e) {
      _setError('주소 요청 중 오류 발생: ${e.toString()}');
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _Si = null;
    notifyListeners();
  }
}
