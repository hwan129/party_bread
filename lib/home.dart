import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;
  List<Map<String, dynamic>> breads = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // GeoProvider의 fetchGeoData 호출하고 완료를 기다림
      await Provider.of<GeoProvider>(context, listen: false).fetchGeoData();

      // fetchGeoData가 완료된 후 fetchBreadData 실행
      fetchBreadData();
    });
  }

  double calculateDistance(
      double startLat, double startLon, double endLat, double endLon) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  Future<void> fetchBreadData() async {
    print("start fetch bread");
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

              print("data : ${data}");
              double distance =
                  calculateDistance(userLat, userLon, selectedLat, selectedLon);

              // 시간 데이터 처리
              final String? timeText = data['data']['픽업 시간'] ??
                  data['data']['탑승 시간'] ??
                  data['data']['마감일'];

              if (timeText != null) {
                try {
                  // 시간 형식 검증
                  final timeRegex = RegExp(r'^\d{1,2}:\d{2} (AM|PM)$');
                  if (!timeRegex.hasMatch(timeText)) {
                    print("시간 형식이 올바르지 않습니다: $timeText");
                    return null;
                  }

                  final DateTime now = DateTime.now();
                  // print("현재 시간: $now");

                  // 시간 문자열을 24시간 형식으로 변환
                  final DateTime itemTime =
                      DateFormat('hh:mm a', 'en_US').parse(timeText);
                  // final String formattedTime =
                  //     DateFormat('HH:mm').format(itemTime); // 24시간 형식으로 변환
                  // print("픽업 시간 (24시간 형식): $formattedTime");

                  // 현재 날짜에 변환된 시간 적용
                  final DateTime itemDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    itemTime.hour,
                    itemTime.minute,
                  );

                  print("현재 날짜에 맞춘 시간: $itemDateTime");

                  // 변환된 시간과 현재 시간 비교
                  if (itemDateTime.isBefore(now)) {
                    print("입력된 시간이 이미 지났습니다.");
                    return null;
                  }
                } catch (e) {
                  print("시간 변환 중 오류 발생: $e");
                  return null;
                }
              }

              if (distance <= 1000) {
                if (data['categoryName'] == '택시팟빵') {
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
              }
            })
            .where((bread) => bread != null) // null 빼고 받아옴
            .cast<Map<String, dynamic>>() // 명시적 캐스팅, 리스트의 타입
            .toList();

        isLoading = false;
        print("breads : ${breads}");
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('오류 발생: $e');
    }
  }

  void showBreadDetails(Map<String, dynamic> bread) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (bread['categoryName'] == '택시팟빵') ...[
                  Text(
                    "출발지: ${bread['pickMeUp'] ?? '정보 없음'}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "목적지: ${bread['destination'] ?? '정보 없음'}",
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                ] else ...[
                  Text(
                    bread['name'] ?? '제목 없음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
                SizedBox(height: 10),
                Text("세부사항: ${bread['detail'] ?? '없음'}"),
                SizedBox(height: 10),
                Text("주문 시간: ${bread['orderTime'] ?? '알 수 없음'}"),
                Text("픽업 시간: ${bread['pickupTime'] ?? '미정'}"),
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/chatting',
                        arguments: {'roomId': bread['category']},
                      );
                    },
                    child: Text('팟빵 함께 먹기'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: EdgeInsets.fromLTRB(7, 0, 0, 0),
            child: Image.asset('assets/image/potbbang_ko.png'),
          ),
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
                Text("곧 식어버리는 팟빵들이에요."),
                Text("완료되기까지"),
                Text("시간이 얼마남지 않았으니 서두르세요!"),
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
                        if (bread['categoryName'] == '택시팟빵') {
                          final title =
                              "${bread['pickMeUp'] ?? '출발지 없음'} → ${bread['destination'] ?? '목적지 없음'}";
                          final subtitle = bread['detail'] ?? '세부 정보 없음';

                          return ListTile(
                            title: Text(title),
                            subtitle: Text(subtitle),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () => {showBreadDetails(bread)},
                          );
                        }
                        return ListTile(
                          title: Text(bread['name'] ?? '이름 없음'),
                          subtitle: Text(bread['detail'] ?? '상세 정보 없음'),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () => {showBreadDetails(bread)},
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
