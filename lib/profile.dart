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
                'data': {
                  '음식 이름': doc['data']['음식 이름'] ?? '',
                  '주문 시간': doc['data']['주문 시간'] ?? '',
                  '추가 사항': doc['data']['추가 사항'] ?? '',
                  '픽업 시간': doc['data']['픽업 시간'] ?? '',
                  '픽업 위치': doc['data']['픽업 위치'] ?? '',
                },
              });
            });
          }
        }
      }
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
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
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
                            Text("Select Profile Image",
                                style: TextStyle(fontSize: 18)),
                            SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey)),
                        )
                      : ListView.builder(
                          itemCount: activityHistory.length,
                          itemBuilder: (context, index) {
                            final activity = activityHistory[index];
                            final data = activity['data'];
                            final category = activity['category'];

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              elevation: 4.0,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Category: $category",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    if (category == "택시팟빵") ...[
                                      Text("목적지: ${data['음식 이름']}"),
                                      Text("탑승 시간: ${data['주문 시간']}"),
                                      Text("추가 사항: ${data['추가 사항']}"),
                                      Text("탑승 장소: ${data['픽업 위치']}"),
                                    ] else ...[
                                      Text("음식 이름: ${data['음식 이름']}"),
                                      Text("주문 시간: ${data['주문 시간']}"),
                                      Text("추가 사항: ${data['추가 사항']}"),
                                      Text("픽업 시간: ${data['픽업 시간']}"),
                                      Text("픽업 위치: ${data['픽업 위치']}"),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
