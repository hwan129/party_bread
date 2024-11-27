import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GeoProvider with ChangeNotifier {
  String? _latitude;
  String? _longitude;
  String? _address;
  String? _errorMessage;

  String? get latitude => _latitude;
  String? get longitude => _longitude;
  String? get address => _address;
  String? get errorMessage => _errorMessage;

  final String _API_KEY = 'AIzaSyAQ4KUztl0w0BqwRJSpf3EGWt49ascwPdQ';

  Future<void> fetchGeoData() async {
    try {
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

      // 주소 가져오기
      await _fetchAddressFromCoordinates();
    } catch (e) {
      _setError('오류 발생: ${e.toString()}');
    }
  }

  Future<void> _fetchAddressFromCoordinates() async {
    try {
      if (_latitude == null || _longitude == null) {
        _setError('유효하지 않은 위도/경도 값입니다.');
        return;
      }

      final gpsUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$_latitude,$_longitude&key=$_API_KEY';

      final response = await http.get(Uri.parse(gpsUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('Google Maps API Response: $data');

        if (data['results'] != null && data['results'].isNotEmpty) {
          _address = data['results'][0]['formatted_address'];
          _errorMessage = null;
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
    _address = null;
    notifyListeners();
  }
}
