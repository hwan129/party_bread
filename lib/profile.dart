import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "사용자 이름";
  String userProfileImage =
      "https://firebasestorage.googleapis.com/v0/b/party-bread.firebasestorage.app/o/potbbang.png?alt=media&token=d0f000c8-3dee-4cb0-8461-4d7bbf136c4b";
  List<Map<String, dynamic>> activityHistory = []; // 활동 내역 저장

  final List<String> profileImages = [
    "https://firebasestorage.googleapis.com/v0/b/party-bread.firebasestorage.app/o/1111.jpg?alt=media&token=96e301dd-ebb6-40ca-9456-2f0e0d03dd78",
    "https://firebasestorage.googleapis.com/v0/b/party-bread.firebasestorage.app/o/potbbang.png?alt=media&token=d0f000c8-3dee-4cb0-8461-4d7bbf136c4b",
    "https://firebasestorage.googleapis.com/v0/b/party-bread.firebasestorage.app/o/potbbang.png?alt=media&token=d0f000c8-3dee-4cb0-8461-4d7bbf136c4b",
    "https://firebasestorage.googleapis.com/v0/b/party-bread.firebasestorage.app/o/potbbang.png?alt=media&token=d0f000c8-3dee-4cb0-8461-4d7bbf136c4b",
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadActivityHistory();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('user').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? userName;
          userProfileImage = userDoc['profileImage'] ?? userProfileImage;
        });
      }
    }
  }

  Future<void> _loadActivityHistory() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot userDoc =
        await _firestore.collection('user').doc(user.uid).get();

    if (userDoc.exists && userDoc['interactedDocs'] != null) {
      List<dynamic> interactedDocs = userDoc['interactedDocs'];

      for (String docId in interactedDocs) {
        DocumentSnapshot doc =
            await _firestore.collection('bread').doc(docId).get();

        if (doc.exists) {
          setState(() {
            activityHistory.add({
              'category': doc['category'] ?? '',
              'data': doc['data'] ?? {},
            });
          });
        } else {
          print('Document not found for $docId');
        }
      }
    } else {
      print('No interacted docs found for the user');
    }
  } else {
    print('No current user found');
  }
}


  Future<void> _changeProfileImage(String imageUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('user').doc(user.uid).update({
        'profileImage': imageUrl,
      });
      setState(() {
        userProfileImage = imageUrl;
      });
    }
  }
  Widget _listTileBuild(Map<String, dynamic> bread) {
  print('Bread data: $bread');  // Bread 데이터 구조를 디버깅하기 위한 출력

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
                  ? "${bread['data']['탑승 장소']} -> ${bread['data']['목적지']}"
                  : bread['category'] == '배달팟빵'
                      ? "${bread['data']['음식 이름']}"
                      : bread['category'] == '기타팟빵'
                          ? "${bread['data']['이름']}"
                          : bread['category'] == '공구팟빵'
                            ? "${bread['data']['제품명']}"
                            : "알 수 없는 카테고리",
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
            children: [
              Text(
                "${bread['category']}  |  ${bread['data']['현재 인원 수']} / ${bread['data']['인원 수']}",
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
        ),
      ),
    ),
  );
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
                    "출발지: ${bread['data']['탑승 장소'] ?? '정보 없음'}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "목적지: ${bread['data']['목적지'] ?? '정보 없음'}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text("탑승 시간: ${bread['data']['탑승 시간'] ?? '정보 없음'}"),
                ] else if (bread['category'] == '배달팟빵')...[
                  Text(
                    bread['data']['음식 이름'] ?? '제목 없음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("주문 시간: ${bread['data']['주문 시간'] ?? '알 수 없음'}"),
                  Text("픽업 시간: ${bread['data']['픽업 시간'] ?? '미정'}"),
                ]
                else if (bread['category'] == '공구팟빵')...[
                  Text(
                    bread['data']['제품명'] ?? '제목 없음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("마감일: ${bread['data']['마감일'] ?? '알 수 없음'}"),
                ]
                else if (bread['category'] == '기타팟빵')...[
                  Text(
                    bread['data']['이름'] ?? '제목 없음',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("마감일: ${bread['data']['마감일'] ?? '알 수 없음'}"),
                  Text("장소: ${bread['data']['장소'] ?? '미정'}"),
                ],
                
                SizedBox(height: 10),
                Text(
                  "현재 인원 수/인원 수: ${bread['data']['현재 인원 수'] ?? 0}/${bread['data']['인원 수'] ?? 0}",
                ),
                SizedBox(height: 10),
                Text("세부사항: ${bread['data']['detail'] ?? '없음'}"),
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
                            // 'currentpeopleCount'와 'peopleCount'가 null이 아니고, int로 변환 가능한지 체크
                            if (bread['currentpeopleCount'] != null && bread['peopleCount'] != null) {
                              try {
                                // String을 int로 변환
                                int currentPeopleCount = int.tryParse(bread['currentpeopleCount'].toString()) ?? 0;
                                int peopleCount = int.tryParse(bread['peopleCount'].toString()) ?? 0;

                                // 인원 수가 같지 않으면
                                if (currentPeopleCount != peopleCount) {
                                  await userDoc.update({
                                    'interactedDocs': FieldValue.arrayUnion([bread['docId']]) // 문서 ID 추가
                                  });

                                  // Firestore에서 해당 bread 문서의 '현재 인원 수' 증가
                                  final breadDoc = FirebaseFirestore.instance
                                      .collection('bread')
                                      .doc(bread['docId']);
                                  final breadSnapshot = await breadDoc.get();
                                  String currentPeopleCountStr = breadSnapshot.data()?['data']['현재 인원 수']?.toString() ?? '0';

                          // int로 변환
                                  int currentPeopleCount = int.tryParse(currentPeopleCountStr) ?? 0;
                                  await breadDoc.update({
                                    'data.현재 인원 수': currentPeopleCount + 1, // 현재 인원 수 +1
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
                                  SnackBar(content: Text('숫자 변환 중 오류가 발생했습니다.')),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: TabBar(
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "프로필"),
                  Tab(text: "활동 내역"),
                ],
              ),
            ),
            Expanded(
  child: TabBarView(
    children: [
      // 프로필 화면
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(userProfileImage),
                  backgroundColor: Colors.transparent,
                ),
                SizedBox(width: 16),
                Text(
                  userName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Select Profile Image", style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: profileImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _changeProfileImage(profileImages[index]);
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            NetworkImage(profileImages[index]),
                        backgroundColor: Colors.transparent,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      // 활동 내역 화면
      activityHistory.isEmpty
          ? Center(
              child: Text("활동 내역이 없습니다.",
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: activityHistory.length,
              itemBuilder: (context, index) {
                final activity = activityHistory[index];
                //final data = activity['data'] ?? {}; // data가 null일 경우 빈 Map을 사용
                final category = activity['category'] ?? 'No Category'; // 카테고리 확인

                // activity 데이터를 _listTileBuild에 전달
                return _listTileBuild(activity);
              },
            ),
    ],
  ),
)





          ],
        ),
      ),
    );
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
}

}
