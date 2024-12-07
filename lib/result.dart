import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 추가
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
                  final DateTime now = DateTime.now();
                  print("현재 시간: $now");

                  if (data['category'] == '배달팟빵' ||
                      data['category'] == '택시팟빵') {
                    // 시간 문자열을 24시간 형식으로 변환
                    final DateTime itemTime =
                        DateFormat('hh:mm a', 'en_US').parse(timeText);

                    // 현재 날짜에 변환된 시간 적용
                    final DateTime itemDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      itemTime.hour,
                      itemTime.minute,
                    );
                    // 변환된 시간과 현재 시간 비교
                    print("현재 날짜에 맞춘 시간: $itemDateTime");
                    if (itemDateTime.isBefore(now)) {
                      print("입력된 시간이 이미 지났습니다.");
                      return null;
                    }
                  } else {
                    final String deadlineString =
                        '${data['data']['마감일']} ${data['data']['마감 시간']}';
                    final DateFormat inputFormat =
                        DateFormat('yyyy-MM-dd h:mm a');
                    final DateTime deadline = inputFormat.parse(deadlineString);

                    if (deadline.isBefore(now)) {
                      print("입력된 시간이 이미 지났습니다.");
                      return null;
                    }
                  }
                } catch (e) {
                  print("시간 변환 중 오류 발생: $e");
                  return null;
                }
              }

              if (distance <= 1000) {
                if (data['category'] == '택시팟빵') {
                  return {
                    'docId': doc.id,
                    'category': data['category'],
                    'meetArea': data['data']['탑승 장소'],
                    'destination': data['data']['목적지'],
                    'deadline': data['data']['탑승 시간'],
                    'peopleCount': data['data']['인원 수'],
                    'currentpeopleCount': data['data']['현재 인원 수'],
                    'detail': data['data']['추가 사항'],
                    'selected_loc': LatLng(selectedLat, selectedLon)
                  };
                } else if (data['category'] == '배달팟빵') {
                  return {
                    'docId': doc.id,
                    'category': data['category'],
                    'name': data['data']['음식 이름'],
                    'orderTime': data['data']['주문 시간'],
                    'deadline': data['data']['픽업 시간'],
                    'meetArea': data['data']['픽업 위치'],
                    'peopleCount': data['data']['인원 수'],
                    'currentpeopleCount': data['data']['현재 인원 수'],
                    'detail': data['data']['추가 사항'],
                    'selected_loc': LatLng(selectedLat, selectedLon)
                  };
                } else if (data['category'] == '공구팟빵') {
                  return {
                    'docId': doc.id,
                    'category': data['category'],
                    'name': data['data']['제품명'],
                    'deadline': data['data']['마감일'],
                    'peopleCount': data['data']['인원 수'],
                    'currentpeopleCount': data['data']['현재 인원 수'],
                    'detail': data['data']['추가 사항'],
                    'selected_loc': LatLng(selectedLat, selectedLon)
                  };
                } else if (data['category'] == '기타팟빵') {
                  return {
                    'docId': doc.id,
                    'category': data['category'],
                    'name': data['data']['이름'],
                    'deadline': data['data']['마감일'],
                    'meetArea': data['data']['장소'],
                    'peopleCount': data['data']['인원 수'],
                    'currentpeopleCount': data['data']['현재 인원 수'],
                    'detail': data['data']['추가 사항'],
                    'selected_loc': LatLng(selectedLat, selectedLon)
                  };
                }
              }
            })
            .where((bread) => bread != null) // null 제거
            .cast<Map<String, dynamic>>() // 명시적 캐스팅
            .take(4)
            .toList();

        isLoading = false;
        print("bread ${breads}");
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('오류 발생: $e');
    }
  }

  void showBreadDetails(Map<String, dynamic> bread) {
    print('detail bread:${bread}');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        final geoProvider = Provider.of<GeoProvider>(context);
        late GoogleMapController _mapController;
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  //택시
                  Text(
                    "${bread['meetArea']} -> ${bread['destination']}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "탑승 시간 : ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20), // 볼드 처리
                        ),
                        TextSpan(
                            text: "${bread['deadline'] ?? '알 수 없음'}",
                            style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ] else if (bread['category'] == '배달팟빵') ...[
                  // 배달
                  Text(
                    bread['name'] ?? '제목 없음',
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "주문 시간 : ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20), // 볼드 처리
                        ),
                        TextSpan(
                            text: "${bread['orderTime'] ?? '알 수 없음'}",
                            style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "픽업 시간 : ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20), // 볼드 처리
                        ),
                        TextSpan(
                            text: "${bread['deadline'] ?? '알 수 없음'}",
                            style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ] else ...[
                  // 공구, 기타
                  Text(
                    bread['name'],
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "마감일 : ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        TextSpan(
                            text: "${bread['deadline']}",
                            style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ],
                // 공통
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "현재 인원 수 : ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20), // 볼드 처리
                      ),
                      TextSpan(
                          text:
                              "${bread['currentpeopleCount'] ?? 0}/${bread['peopleCount'] ?? 0}",
                          style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "세부사항: ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20), // 볼드 처리
                      ),
                      TextSpan(
                          text: "${bread['detail'] ?? '없음'}",
                          style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                if (bread['category'] == '공구팟빵') ...[
                  Spacer()
                ] else ...[
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: "${bread['meetArea'] ?? '?'}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        TextSpan(
                          text: "  (으)로 모이세요!",
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: bread['selected_loc'],
                        zoom: 17,
                      ),
                      mapType: MapType.normal,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      onTap: (LatLng coordinate) {
                        _mapController.animateCamera(
                          CameraUpdate.newLatLng(coordinate),
                        );
                        geoProvider.updateLocation(
                            coordinate.latitude, coordinate.longitude);
                      },
                      markers: {
                        Marker(
                          markerId: MarkerId("1"),
                          position: bread['selected_loc'],
                        ),
                      },
                    ),
                  ),
                ],
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
                            // 'currentpeopleCount'와 'peopleCount'가 null이 아니고, int로 변환 가능한지 체크
                            if (bread['currentpeopleCount'] != null &&
                                bread['peopleCount'] != null) {
                              try {
                                // String을 int로 변환
                                int currentPeopleCount = int.tryParse(
                                        bread['currentpeopleCount']
                                            .toString()) ??
                                    0;
                                int peopleCount = int.tryParse(
                                        bread['peopleCount'].toString()) ??
                                    0;

                                // 인원 수가 같지 않으면
                                if (currentPeopleCount != peopleCount) {
                                  await userDoc.update({
                                    'interactedDocs': FieldValue.arrayUnion(
                                        [bread['docId']]) // 문서 ID 추가
                                  });

                                  // Firestore에서 해당 bread 문서의 '현재 인원 수' 증가
                                  final breadDoc = FirebaseFirestore.instance
                                      .collection('bread')
                                      .doc(bread['docId']);
                                  final breadSnapshot = await breadDoc.get();
                                  String currentPeopleCountStr = breadSnapshot
                                          .data()?['data']['현재 인원 수']
                                          ?.toString() ??
                                      '0';

                                  // int로 변환
                                  int currentPeopleCount =
                                      int.tryParse(currentPeopleCountStr) ?? 0;
                                  await breadDoc.update({
                                    'data.현재 인원 수':
                                        currentPeopleCount + 1, // 현재 인원 수 +1
                                  });

                                  await createChatRoom(bread['docId']);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('인원이 다 찼습니다!')),
                                  );
                                }
                              } catch (e) {
                                print('변환 오류 발생: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('숫자 변환 중 오류가 발생했습니다.')),
                                );
                              }
                            }
                          } else {
                            await createChatRoom(bread['docId']);
                          }
                        }
                      } catch (e) {
                        print('문서 업데이트 중 오류 발생: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
                        );
                      }
                    },
                    child: Text('팟빵 함께 먹기',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF574142),
                      foregroundColor: Color(0xFFF5E0D3),
                      minimumSize: Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
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
                          ? "${bread['meetArea']} -> ${bread['destination']}"
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
              )),
        ));
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

                              return _listTileBuild(bread);
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

  Future<void> createChatRoom(String docId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 새로운 채팅방 문서를 Firestore에 생성
      final chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(docId);

      // 채팅방 생성 (이미 존재하는 채팅방을 체크하지 않음)
      await chatRoomRef.set({
        'docId': docId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // 채팅방 생성 후 해당 채팅방으로 이동
      Navigator.pushNamed(
        context,
        '/chatting',
        arguments: {'roomId': docId}, // 문서 ID를 이용해 채팅방으로 이동
      );
    }
  } catch (e) {
    print('채팅방 생성 중 오류 발생: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('채팅방 생성 중 오류가 발생했습니다.')),
    );
  }
}}

