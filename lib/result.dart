import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 추가
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

              // 시간 데이터 처리
              final String? timeText = data['data']['픽업 시간'] ??
                  data['data']['탑승 시간'] ??
                  data['data']['마감일'];
              print('time text : ${timeText}');

              if (timeText != null) {
                try {
                  // 시간 형식 검증
                  final timeRegex = RegExp(r'^\d{1,2}:\d{2} (AM|PM)$');
                  if (!timeRegex.hasMatch(timeText)) {
                    print("시간 형식이 올바르지 않습니다: $timeText");
                    return null;
                  }

                  final DateTime now = DateTime.now();
                  print("현재 시간: $now");

                  // 시간 문자열을 24시간 형식으로 변환
                  final DateTime itemTime =
                      DateFormat('hh:mm a', 'en_US').parse(timeText);
                  final String formattedTime =
                      DateFormat('HH:mm').format(itemTime); // 24시간 형식으로 변환
                  print("픽업 시간 (24시간 형식): $formattedTime");

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
                if (categoryName == '택시팟빵') {

            return {
              'docId': doc.id, // 문서 ID 추가
              'category': data['category'],
              'pickMeUp': data['data']['탑승 장소'], // 수정된 변수명
              'destination': data['data']['목적지'], // 수정된 변수명
              'time': data['data']['탑승 시간'], // 수정된 변수명
              'peopleCount': data['data']['인원 수'], // 수정된 변수명
              'detail': data['data']['추가 사항'], // 수정된 변수명
            };
          }

                return {
                  'docId': doc.id, // 문서 ID 추가
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "탑승 시간: ${bread['time'] ?? '정보 없음'}"
                  ),
                ] else ...[
                  Text(
                    bread['name'] ?? '제목 없음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("주문 시간: ${bread['orderTime'] ?? '알 수 없음'}"),
                  Text("픽업 시간: ${bread['pickupTime'] ?? '미정'}"),
                ],
                SizedBox(height: 10),
                Text("세부사항: ${bread['detail'] ?? '없음'}"),
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          // Firestore에서 user 컬렉션에 접근
                          final userDoc = FirebaseFirestore.instance
                              .collection('user')
                              .doc(user.uid);

                          // 유저의 interactedDocs 배열에 해당 문서 ID가 존재하는지 확인
                          final userSnapshot = await userDoc.get();
                          final interactedDocs = List<String>.from(
                              userSnapshot.data()?['interactedDocs'] ?? []);

                          // 문서 ID가 없으면 추가
                          if (!interactedDocs.contains(bread['docId'])) {
                            await userDoc.update({
                              'interactedDocs': FieldValue.arrayUnion([bread['docId']]) // 문서 ID 추가
                            });

                            // Firestore에서 해당 bread 문서의 '현재 인원 수' 증가
                            final breadDoc = FirebaseFirestore.instance
                                .collection('bread')
                                .doc(bread['docId']);
                            final breadSnapshot = await breadDoc.get();
                            final currentPeopleCount = breadSnapshot.data()?['data']['현재 인원 수'] ?? 0;

                            await breadDoc.update({
                              'data.현재 인원 수': currentPeopleCount + 1, // 현재 인원 수 +1
                            });
                          }

                          // 채팅 화면으로 이동
                          Navigator.pushNamed(
                            context,
                            '/chatting',
                            arguments: {'roomId': bread['category']},
                          );
                        }
                      } catch (e) {
                        print('문서 업데이트 중 오류 발생: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
                        );
                      }
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
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

                                return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: InkWell(
                                      onTap: () => showBreadDetails(bread),
                                      child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white, // 배경색 설정
                                            borderRadius: BorderRadius.circular(
                                                10), // 둥근 모서리 설정
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2), // 그림자 색
                                                spreadRadius: 2, // 그림자의 확장 범위
                                                blurRadius: 5, // 그림자의 흐림 정도
                                                offset: Offset(
                                                    1, 1), // 그림자의 위치 (x, y 방향)
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            title: Text(title),
                                            subtitle: Text(subtitle),
                                          )),
                                    ));
                              }
                              return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: InkWell(
                                    onTap: () => showBreadDetails(bread),
                                    child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white, // 배경색 설정
                                          borderRadius: BorderRadius.circular(
                                              10), // 둥근 모서리 설정
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.2), // 그림자 색
                                              spreadRadius: 1, // 그림자의 확장 범위
                                              blurRadius: 4, // 그림자의 흐림 정도
                                              offset: Offset(
                                                  1, 1), // 그림자의 위치 (x, y 방향)
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          title: Text(bread['name'] ?? '이름 없음'),
                                          subtitle: Text(
                                              bread['detail'] ?? '상세 정보 없음'),
                                        )),
                                  ));
                            },
                          ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "원하는 팟빵이 없으신가요?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    "새로운 팟빵을 만들어보세요!",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add');
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFF574142),
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 13, horizontal: 80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text(
                        '반죽하러 가기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
