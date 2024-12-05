import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';  // FirebaseAuth 추가
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

  Future<void> fetchBreadData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bread')
          .where('category', isEqualTo: categoryName)
          .get();

      setState(() {
        breads = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

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
        }).toList();
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
                          final userDoc = FirebaseFirestore.instance.collection('user').doc(user.uid);

                          // 유저의 interactedDocs 배열에 해당 문서 ID가 존재하는지 확인
                          final userSnapshot = await userDoc.get();
                          final interactedDocs = List<String>.from(userSnapshot.data()?['interactedDocs'] ?? []);

                          // 문서 ID가 없으면 추가
                          if (!interactedDocs.contains(bread['docId'])) {
                            await userDoc.update({
                              'interactedDocs': FieldValue.arrayUnion([bread['docId']]) // 문서 ID 추가
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
