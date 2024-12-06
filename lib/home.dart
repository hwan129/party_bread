import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Widget _categoryButton(String category) {
    return Flexible(
        child: Container(
      decoration: BoxDecoration(
        color: Colors.white, // 버튼 배경색
        shape: BoxShape.circle, // 원형으로 만들기
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // 그림자 색
            spreadRadius: 2, // 그림자의 확장 범위
            blurRadius: 5, // 그림자의 흐림 정도
            offset: Offset(0, 4), // 그림자의 위치 (x, y 방향)
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          int argument = 0; // 기본 값 설정
          if (category == "배달팟빵") {
            argument = 0;
          } else if (category == "택시팟빵") {
            argument = 1;
          } else if (category == "공구팟빵") {
            argument = 2;
          } else if (category == "기타팟빵") {
            argument = 3;
          }
          Navigator.pushNamed(context, '/result', arguments: argument);
        },
        style: TextButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(20),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          category,
          style: TextStyle(),
        ),
      ),
    ));
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
                if (data['category'] == '택시팟빵') {
                  return {
                    'category': data['category'],
                    'pickMeUp': data['data']['탑승 장소'],
                    'destination': data['data']['목적지'],
                    'deadline': data['data']['탑승 시간'],
                    'peopleCount': data['data']['인원 수'],
                    'currentpeopleCount': data['data']['현재 인원 수'],
                    'detail': data['data']['추가 사항'],
                  };
                } else if (data['category'] == '배달팟빵') {
                  return {
                    'category': data['category'],
                    'name': data['data']['음식 이름'],
                    'orderTime': data['data']['주문 시간'],
                    'deadline': data['data']['픽업 시간'],
                    'pickupArea': data['data']['픽업 위치'],
                    'peopleCount': data['data']['인원 수'],
                    'currentpeopleCount': data['data']['현재 인원 수'],
                    'detail': data['data']['추가 사항'],
                  };
                } else if (data['category'] == '공구팟빵') {
                  return {
                    'category': data['category'],
                    'name': data['data']['제품명'],
                    'deadline': data['data']['마감일'],
                    'peopleCount': data['data']['인원 수'],
                    'currentpeopleCount': data['data']['현재 인원 수'],
                    'detail': data['data']['추가 사항'],
                  };
                } else if (data['category'] == '기타팟빵') {
                  return {
                    'category': data['category'],
                    'name': data['data']['이름'],
                    'deadline': data['data']['마감일'],
                    'area': data['data']['장소'],
                    'peopleCount': data['data']['인원 수'],
                    'currentpeopleCount': data['data']['현재 인원 수'],
                    'detail': data['data']['추가 사항'],
                  };
                }
              }
            })
            .where((bread) => bread != null) // null 빼고 받아옴
            .cast<Map<String, dynamic>>() // 명시적 캐스팅, 리스트의 타입
            .take(4) // 불러올 개수
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
                if (bread['category'] == '택시팟빵') ...[
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
                  Text("탑승 시간: ${bread['deadline'] ?? '정보 없음'}"),
                ] else ...[
                  Text(
                    bread['name'] ?? '제목 없음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("주문 시간: ${bread['orderTime'] ?? '알 수 없음'}"),
                  Text("픽업 시간: ${bread['pickupTime'] ?? '미정'}"),
                ],
                SizedBox(height: 10),
                Text(
                  "현재 인원 수/인원 수: ${bread['currentpeopleCount'] ?? 0}/${bread['peopleCount'] ?? 0}",
                ),
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

                          // Firestore에서 해당 bread 문서 가져오기
                          final breadDoc = FirebaseFirestore.instance
                              .collection('bread')
                              .doc(bread['docId']);
                          final breadSnapshot = await breadDoc.get();

                          // 현재 인원 수와 최대 인원 수 가져오기
                          final dynamic currentPeopleCountRaw =
                              breadSnapshot.data()?['data']['현재 인원 수'] ?? 0;
                          final dynamic peopleCountRaw =
                              breadSnapshot.data()?['data']['인원 수'] ?? 0;

                          final int currentPeopleCount =
                              int.tryParse(currentPeopleCountRaw.toString()) ??
                                  0;
                          final int peopleCount =
                              int.tryParse(peopleCountRaw.toString()) ?? 0;

                          if (currentPeopleCount < peopleCount) {
                            // interactedDocs에 문서 ID가 없으면 추가
                            if (!interactedDocs.contains(bread['docId'])) {
                              await userDoc.update({
                                'interactedDocs': FieldValue.arrayUnion(
                                    [bread['docId']]) // 문서 ID 추가
                              });

                              // Firestore에서 해당 bread 문서의 '현재 인원 수' 증가
                              await breadDoc.update({
                                'data.현재 인원 수':
                                    currentPeopleCount + 1, // 현재 인원 수 +1
                              });
                            }

                            // 채팅 화면으로 이동
                            Navigator.pushNamed(
                              context,
                              '/chatting',
                              arguments: {'roomId': bread['category']},
                            );
                          } else {
                            // 인원이 다 찼을 경우 알림 출력
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('인원이 다 찼습니다!')),
                            );
                          }
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

  Widget _listTileBuild(Map<String, dynamic> bread) {
    print('list bread : ${bread}');
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: InkWell(
          onTap: () => showBreadDetails(bread),
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // 배경색 설정
                borderRadius: BorderRadius.circular(10), // 둥근 모서리 설정
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // 그림자 색
                    spreadRadius: 2, // 그림자의 확장 범위
                    blurRadius: 5, // 그림자의 흐림 정도
                    offset: Offset(1, 1), // 그림자의 위치 (x, y 방향)
                  ),
                ],
              ),
              child: ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bread['category'] == '택시팟빵'
                          ? "${bread['pickMeUp']} -> ${bread['destination']}"
                          : '${bread['name']}',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF574142),
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  // mainAxisAlignment: ,
                  children: [
                    Text(
                      "${bread['category']}  |  ${bread['currentpeopleCount']} / ${bread['peopleCount']}  |  ${bread['deadline']}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF574142),
                      ),
                    ),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward),
                onTap: () => {showBreadDetails(bread)},
              )),
        ));
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
            return Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "곧 식어버리는 팟빵들이에요.",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF574142),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text("완료되기까지"),
                  Text("시간이 얼마남지 않았으니 서두르세요!"),
                  SizedBox(
                    height: 10,
                  ),
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
                          return _listTileBuild(bread);
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Text("팟빵이 없어요 ㅠㅠ"),
                      ),
                    ),
                  Center(
                    child: Text(
                      "어떤 팟빵에 들어가고 싶으신가요?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF574142),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _categoryButton("배달팟빵"),
                      _categoryButton("택시팟빵"),
                      _categoryButton("공구팟빵"),
                      _categoryButton("기타팟빵"),
                    ],
                  )
                ],
              ),
            );
          }
          return const Center(child: Text("데이터를 가져올 수 없습니다."));
        }));
  }
}
