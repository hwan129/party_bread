import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GeoProvider with ChangeNotifier {
  String? _latitude;
  String? _longitude;
  String? _errorMessage;

  String? get latitude => _latitude;
  String? get longitude => _longitude;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGeoData() async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = '위치 권한이 거부되었습니다.';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 활성화해주세요.';
        notifyListeners();
        return;
      }

      // 위치 정보 가져오기
      Position position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '오류 발생: ${e.toString()}';
      print(e.toString());
    }
    notifyListeners();
  }
}
