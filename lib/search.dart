import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 추가
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../provider.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String categoryName = '';
  String filter = '';
  String _searchQuery = "";
  List<Map<String, dynamic>> breads = [];
  bool isLoading = true;

  final List<String> categories = ['배달팟빵', '택시팟빵', '공구팟빵', '기타팟빵'];

  TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    filter = ModalRoute.of(context)?.settings.arguments as String;

    // 처음에만 filter 값 가져오고 이후에는 사용자가 입력한 값으로..
    if (_searchQuery.isEmpty) {
      filter = ModalRoute.of(context)?.settings.arguments as String;
      setState(() {
        _searchQuery = filter;
        _searchController.text = filter;
      });
    }

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
    // try {
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

            // 시간 데이터 처리
            final String? timeText = data['data']['픽업 시간'] ??
                data['data']['탑승 시간'] ??
                data['data']['마감일'];
            // print('time text : ${timeText}');

            if (!data.toString().contains(_searchQuery)) {
              return null; // 검색어에 일치하지 않으면 제외
            }

            if (timeText != null) {
              // try {
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
              // } catch (e) {
              //   print("시간 변환 중 오류 발생: $e");
              //   return null;
              // }
            }

            String category = data['category'] ?? '';
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
          })
          .where((bread) => bread != null) // null 제거
          .cast<Map<String, dynamic>>() // 명시적 캐스팅
          .toList();

      isLoading = false;
      print("bread ${breads}");
    });
    // } catch (e) {
    //   setState(() {
    //     isLoading = false;
    //   });
    //   print('오류 발생: $e');
    // }
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
                            text: "${bread['deadline']}'",
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

                                  // 채팅 화면으로 이동
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
                            fontSize: 20, fontWeight: FontWeight.bold)),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> createChatRoom(String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // 새로운 채팅방 문서를 Firestore에 생성
        final chatRoomRef =
            FirebaseFirestore.instance.collection('chatRooms').doc(docId);

        // 이미 채팅방이 존재하는지 확인 (중복 생성 방지)
        final chatRoomSnapshot = await chatRoomRef.get();

        if (!chatRoomSnapshot.exists) {
          // 채팅방 생성
          await chatRoomRef.set({
            'docId': docId,
            'createdAt': FieldValue.serverTimestamp(),
            'members': [user.uid], // 채팅방에 참여한 사용자의 UID
            'lastMessage': '',
            'isActive': true,
          });

          // 채팅방 생성 후 해당 채팅방으로 이동
          Navigator.pushNamed(
            context,
            '/chatting',
            arguments: {'roomId': docId}, // 문서 ID를 이용해 채팅방으로 이동
          );
        } else {
          // 이미 존재하는 채팅방으로 이동
          Navigator.pushNamed(
            context,
            '/chatting',
            arguments: {'roomId': docId},
          );
        }
      }
    } catch (e) {
      print('채팅방 생성 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 생성 중 오류가 발생했습니다.')),
      );
    }
  }

  Widget _listTileBuild(Map<String, dynamic> bread) {
    print('list bread : ${bread}');
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: InkWell(
          onTap: () => showBreadDetails(bread),
          child: Container(
              height: 85,
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
                    SizedBox(height: 3),
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
      // appBar: AppBar(
      //   title: Text("검색 결과"),
      //   backgroundColor: Colors.white, // 배경색 지정 (선택 사항)
      //   foregroundColor: Color(0xFF574142),
      //   // automaticallyImplyLeading: false, // 기본 back 버튼 비활성화
      //   elevation: 0,
      //     // Text("검색 결과")
      // ),
      appBar: AppBar(
        backgroundColor: Colors.white, // 배경색 지정
        foregroundColor: Color(0xFF574142),
        elevation: 0,
        title: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim(); // 입력 내용 저장
            });
            fetchBreadData();
          },
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
            fetchBreadData();
          },
          decoration: InputDecoration(
            hintText: '세 글자 이상 입력하세요',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
            suffixIcon: Icon(
              Icons.search,
              color: Color(0xFF574142),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(vertical: 10.0, horizontal: 1.0),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent), // 아래 선 색상
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent), // 포커스 시 색상 변경
            ),
          ),
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF574142),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20), // 간격 추가
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : breads.isEmpty
                      ? Center(
                          child: Text(
                            "검색 결과가 없습니다.",
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: breads.length,
                          itemBuilder: (context, index) {
                            final bread = breads[index];
                            // 검색어 필터 적용
                            if (_searchQuery.isNotEmpty &&
                                !bread.toString().contains(_searchQuery)) {
                              return SizedBox(); // 검색어와 일치하지 않으면 빈 공간
                            }
                            return _listTileBuild(bread); // 검색 결과 표시
                          },
                        ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "원하는 팟빵이 없으신가요?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
                Text(
                  "새로운 팟빵을 만들어보세요!",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
