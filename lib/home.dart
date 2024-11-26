import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? latitude;
  String? longitude;
  String? errorMessage;

  Future<void> getGeoData() async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = '위치 권한이 거부되었습니다.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 활성화해주세요.';
        });
        return;
      }

      // 위치 정보 가져오기
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
      });
    } catch (e) {
      setState(() {
        errorMessage = '오류 발생: ${e.toString()}';
        print(e.toString());
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getGeoData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home"), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.person, semanticLabel: 'profile'),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ]),
      body: Column(
        children: [
          Column(
            children: [
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (latitude != null && longitude != null)
                Column(
                  children: [
                    Text('위도: $latitude'),
                    Text('경도: $longitude'),
                  ],
                )
              else
                const CircularProgressIndicator(),
              Text("어떤 팟빵에 드갈래"),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: 0,
                      );
                    },
                    child: const Text('배달팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: 1,
                      );
                    },
                    child: const Text('택시팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: 2,
                      );
                    },
                    child: const Text('공구팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/result',
                        arguments: 3,
                      );
                    },
                    child: const Text('기타팟빵'),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
