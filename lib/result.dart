import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultPage extends StatefulWidget {
  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late int categoryIndex; // 전달받은 인덱스
  String categoryName = ''; // 카테고리 이름
  List<Map<String, dynamic>> breads = []; // 해당 카테고리의 빵 데이터 저장
  bool isLoading = true; // 로딩 상태

  // 카테고리 목록
  final List<String> categories = ['배달팟빵', '택시팟빵', '공구팟빵', '기타팟빵'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // arguments로 전달된 인덱스를 받기
    categoryIndex = ModalRoute.of(context)?.settings.arguments as int;
    categoryName = categories[categoryIndex]; // 인덱스에 맞는 카테고리 이름 가져오기
    fetchBreadData();
  }

  // Firestore에서 데이터 가져오기
  Future<void> fetchBreadData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bread')
          .where('category', isEqualTo: categoryName)
          .get();

      setState(() {
        // 각 문서를 Map 형태로 변환하여 저장
        breads = querySnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // 'data' 필드에서 필요한 정보를 추출하여 반환
              return {
                'category': data['category'],
                'createdAt': data['createdAt'],
                'detail': data['data']['detail'], // data 안의 'detail' 값
                'name': data['data']['name'],     // data 안의 'name' 값
                'orderTime': data['data']['orderTime'], // data 안의 'orderTime' 값
                'pickupTime': data['data']['pickupTime'], // data 안의 'pickupTime' 값
              };
            })
            .toList();
        isLoading = false; // 로딩 완료
      });
    } catch (e) {
      setState(() {
        isLoading = false; // 로딩 실패
      });
      print('오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$categoryName 팟빵")),
      body: Column(
        children: [
          // ListView로 빵 목록 표시
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator()) // 로딩 중일 때 표시
                : breads.isEmpty
                    ? Center(child: Text("해당 카테고리의 빵이 없습니다.")) // 빵이 없을 때 표시
                    : ListView.builder(
                        itemCount: breads.length,
                        itemBuilder: (context, index) {
                          final bread = breads[index];
                          return ListTile(
                            title: Text(bread['name'] ?? '이름 없음'),
                            subtitle: Text(bread['detail'] ?? '상세 정보 없음'),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("주문 시간: ${bread['orderTime'] ?? '알 수 없음'}"),
                                Text("픽업 시간: ${bread['pickupTime'] ?? '알 수 없음'}"),
                              ],
                            ),
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
