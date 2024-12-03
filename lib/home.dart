import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  late int categoryIndex;
  String categoryName = '';
  List<Map<String, dynamic>> breads = [];
  final List<String> categories = ['배달팟빵', '택시팟빵', '공구팟빵', '기타팟빵'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // GeoProvider의 fetchGeoData 호출하고 완료를 기다림
      await Provider.of<GeoProvider>(context, listen: false).fetchGeoData();

      // fetchGeoData가 완료된 후 fetchBreadData 실행
      fetchBreadData();
    });
  }

  Future<void> fetchBreadData() async {
    try {
      final geoProvider = Provider.of<GeoProvider>(context, listen: false);
      final userLat = geoProvider.latitude!;
      final userLon = geoProvider.longitude!;

      final querySnapshot =
          await FirebaseFirestore.instance.collection('bread').get();

      setState(() {
        breads = querySnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final selectedLat = data['selected_lat'] ?? 0.0;
              final selectedLon = data['selected_lon'] ?? 0.0;

              if (categoryName == '택시팟빵') {
                return {
                  'category': data['category'],
                  'pickMeUp': data['data']['픽업 위치'],
                  'destination': data['data']['목적지'],
                  'time': data['data']['탑승 시간'],
                  'peopleCount': data['data']['인원 수'],
                  'detail': data['data']['추가 사항'],
                };
              }

              return {
                'category': data['category'],
                'name': data['data']['음식 이름'],
                'orderTime': data['data']['주문 시간'],
                'pickupTime': data['data']['픽업 시간'],
                'peopleCount': data['data']['인원 수'],
                'detail': data['data']['추가 사항'],
              };
            })
            .where((bread) => bread != null) // null 빼고 받아옴
            .cast<Map<String, dynamic>>() // 명시적 캐스팅, 리스트의 타입
            .toList();

        isLoading = false;
        print(breads);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Consumer<GeoProvider>(
            builder: (context, geoProvider, child) {
              return Text(
                geoProvider.Si != null
                    ? '${geoProvider.Si} ${geoProvider.Gu} ${geoProvider.Dong} ${geoProvider.street}'
                    : "주소를 가져오는 중...",
                style: const TextStyle(fontSize: 16),
              );
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.person, semanticLabel: 'profile'),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
        body: Consumer<GeoProvider>(builder: (context, geoProvider, child) {
          if (geoProvider.isLoading) {
            // 로딩 중 표시
            return const Center(child: CircularProgressIndicator());
          }
          if (geoProvider.errorMessage != null) {
            return Center(
              child: Text(
                geoProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (geoProvider.latitude != null && geoProvider.longitude != null) {
            return Column(
              children: [
                if (geoProvider.errorMessage != null)
                  Text(
                    geoProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                if (breads.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: breads.length,
                      itemBuilder: (context, index) {
                        final bread = breads[index];
                        if (categoryName == '택시팟빵') {
                          final title =
                              "${bread['pickMeUp'] ?? '출발지 없음'} → ${bread['destination'] ?? '목적지 없음'}";
                          final subtitle = bread['detail'] ?? '세부 정보 없음';

                          return ListTile(
                            title: Text(title),
                            subtitle: Text(subtitle),
                            trailing: Icon(Icons.arrow_forward),
                          );
                        }
                        return ListTile(
                          title: Text(bread['name'] ?? '이름 없음'),
                          subtitle: Text(bread['detail'] ?? '상세 정보 없음'),
                          trailing: Icon(Icons.arrow_forward),
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Text("팟빵이 없어요 ㅠㅠ"),
                    ),
                  ),
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
            );
          }
          return const Center(child: Text("데이터를 가져올 수 없습니다."));
        }));
  }
}
