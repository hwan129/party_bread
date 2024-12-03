import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../provider.dart';

class ResultPage extends StatefulWidget {
  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late int categoryIndex;
  String categoryName = '';
  List<Map<String, dynamic>> breads = [];
  bool isLoading = true;

  final List<String> categories = ['배달팟빵', '택시팟빵', '공구팟빵', '기타팟빵'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    categoryIndex = ModalRoute.of(context)?.settings.arguments as int;
    categoryName = categories[categoryIndex]; // 인덱스에 맞는 카테고리 이름 가져오기

    // 위치 초기화
    final geoProvider = Provider.of<GeoProvider>(context, listen: false);
    geoProvider.updateLocation(geoProvider.latitude!, geoProvider.longitude!);
    fetchBreadData();
  }

  double calculateDistance(
      double startLat, double startLon, double endLat, double endLon) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon);
  }

  Future<void> fetchBreadData() async {
    try {
      final geoProvider = Provider.of<GeoProvider>(context, listen: false);
      final userLat = geoProvider.latitude!;
      final userLon = geoProvider.longitude!;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('bread')
          .where('category', isEqualTo: categoryName)
          .get();

      setState(() {
        breads = querySnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final selectedLat = data['selected_lat'] ?? 0.0;
              final selectedLon = data['selected_lon'] ?? 0.0;

              double distance =
                  calculateDistance(userLat, userLon, selectedLat, selectedLon);

              if (distance <= 500) {
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
                  'name': data['data']['음식 이름'], // 수정된 변수명
                  'orderTime': data['data']['주문 시간'], // 수정된 변수명
                  'pickupTime': data['data']['픽업 시간'], // 수정된 변수명
                  'peopleCount': data['data']['인원 수'], // 수정된 변수명
                  'detail': data['data']['추가 사항'], // 수정된 변수명
                };
              }
            })
            .where((bread) => bread != null) // null 제거
            .cast<Map<String, dynamic>>() // 명시적 캐스팅
            .toList();

        isLoading = false;
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
                if (categoryName == '택시팟빵') ...[
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
      appBar: AppBar(title: Text("$categoryName 팟빵")),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : breads.isEmpty
                    ? Center(child: Text("해당 카테고리의 빵이 없습니다."))
                    : ListView.builder(
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
                              onTap: () => showBreadDetails(bread),
                            );
                          }
                          return ListTile(
                            title: Text(bread['name'] ?? '이름 없음'),
                            subtitle: Text(bread['detail'] ?? '상세 정보 없음'),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () => showBreadDetails(bread),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("원하시는 팟빵이 없으신가?"),
                Text("만들자!"),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add');
                  },
                  child: const Text('반죽하러 가기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
