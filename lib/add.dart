import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'provider.dart';


class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String selectedCategory = "";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController orderTimeController = TextEditingController();
  final TextEditingController pickMeUpController = TextEditingController();
  final TextEditingController pickupTimeController = TextEditingController();
  final TextEditingController peopleCountController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final geoProvider = Provider.of<GeoProvider>(context, listen: false);

    print(
        'add position : ${geoProvider.selectedLatitude} ${geoProvider.selectedLongitude}');

    return Scaffold(
      appBar: AppBar(title: Text("Add")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("팟빵 종류를 선택해주세요",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton("배달팟빵"),
                  _buildCategoryButton("택시팟빵"),
                  _buildCategoryButton("공구팟빵"),
                  _buildCategoryButton("기타팟빵"),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              if (selectedCategory == "배달팟빵")
                ..._buildDeliveryFields(
                    geoProvider.latitude!, geoProvider.longitude!),
              if (selectedCategory == "택시팟빵")
                ..._buildTaxiFields(
                    geoProvider.latitude!, geoProvider.longitude!),
              if (selectedCategory == "공구팟빵")
                ..._buildShoppingFields(
                    geoProvider.latitude!, geoProvider.longitude!),
              if (selectedCategory == "기타팟빵")
                ..._buildOtherFields(
                    geoProvider.latitude!, geoProvider.longitude!),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _showConfirmationModal,
                  child: const Text('팟빵 굽기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 카테고리 버튼
  Widget _buildCategoryButton(String category) {
    bool isSelected = selectedCategory == category;

    return TextButton(
      onPressed: () {
        setState(() {
          selectedCategory = category;
        });
        _clearFields(); // 다른 카테고리 선택 시 입력한 거 다 사라짐
      },
      style: TextButton.styleFrom(
        backgroundColor:
            isSelected ? Colors.brown : Colors.white, // 선택된 버튼은 갈색, 나머지는 흰색
        foregroundColor: isSelected ? Colors.white : Colors.black, // 텍스트 색상 설정
      ),
      child: Text(category),
    );
  }

  // 배달팟빵
  List<Widget> _buildDeliveryFields(double latitude, double longitude) {
    return [
      Text("무엇을 먹을 건가요?", style: _fieldTitleStyle),
      Text("상호명은 풀네임으로 적는 게 좋아요", style: _subTitleStyle),
      _buildTextField("장충동왕족발보쌈", nameController),
      Text("더 자세하게 알려주세요", style: _fieldTitleStyle),
      Text("주문 시간", style: _fieldTitleStyle),
      _buildTimeField("주문 시간을 선택하세요", orderTimeController),
      Text("픽업 시간", style: _fieldTitleStyle),
      IconButton(
        icon: const Icon(Icons.map),
        onPressed: () {
          Navigator.pushNamed(context, '/getlocation');
        },
      ),
      _buildTimeField("픽업 시간을 선택하세요", pickupTimeController),
      Text("픽업 장소", style: _fieldTitleStyle),
      _buildTextField("하용조관 1층", pickMeUpController),
      Text("인원", style: _fieldTitleStyle),
      _buildTextField("인원수를 입력하세요", peopleCountController),
      Text("추가 사항", style: _fieldTitleStyle),
      _buildTextField("추가 사항을 입력하세요", detailController),
    ];
  }

  // 택시팟빵
  List<Widget> _buildTaxiFields(double latitude, double longitude) {
    return [
      Text("어디로 갈 건가요?", style: _fieldTitleStyle),
      Text("장소는 상세하게 적는 게 좋아요", style: _subTitleStyle),
      _buildTextField("목적지를 입력하세요", destinationController),
      Text("더 자세하게 알려주세요", style: _fieldTitleStyle),
      Text("탑승 시간", style: _fieldTitleStyle),
      _buildTimeField("탑승 시간을 선택하세요", timeController),
      Text("탑승 장소", style: _fieldTitleStyle),
      _buildTextField("탑승 장소를 입력하세요", pickMeUpController),
      Text("인원", style: _fieldTitleStyle),
      _buildTextField("인원수를 입력하세요", peopleCountController),
      Text("추가 사항", style: _fieldTitleStyle),
      _buildTextField("추가 사항을 입력하세요", detailController),
    ];
  }

  // 공구팟빵
  List<Widget> _buildShoppingFields(double latitude, double longitude) {
    return [
      Text("어떤 물건인가요?", style: _fieldTitleStyle),
      Text("제품명은 풀네임으로 적는 게 좋아요", style: _subTitleStyle),
      _buildTextField("보들보들 치즈볶음면", nameController),
      Text("더 자세하게 알려주세요", style: _fieldTitleStyle),
      Text("마감일", style: _fieldTitleStyle),
      _buildTimeField("마감일을 선택하세요", timeController),
      Text("인원", style: _fieldTitleStyle),
      _buildTextField("인원수를 입력하세요", peopleCountController),
      Text("추가 사항", style: _fieldTitleStyle),
      _buildTextField("추가 사항을 입력하세요", detailController),
    ];
  }

  // 기타팟빵
  List<Widget> _buildOtherFields(double latitude, double longitude) {
    return [
      Text("무엇을 할 건가요?", style: _fieldTitleStyle),
      _buildTextField("롤 5대5 할 사람", nameController),
      Text("더 자세하게 알려주세요", style: _fieldTitleStyle),
      Text("마감일", style: _fieldTitleStyle),
      _buildTimeField("마감일을 선택하세요", timeController),
      Text("인원", style: _fieldTitleStyle),
      _buildTextField("인원수를 입력하세요", peopleCountController),
      Text("추가 사항", style: _fieldTitleStyle),
      _buildTextField("추가 사항을 입력하세요", detailController),
    ];
  }

  // 공통 필드
  Widget _buildTextField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  // 시간 필드 추가
  Widget _buildTimeField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(),
              ),
              readOnly: true, // 입력 불가, Time Picker만 사용
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null) {
                // Time Picker에서 선택한 시간 텍스트로 설정
                controller.text = pickedTime.format(context);
              }
            },
          ),
        ],
      ),
    );
  }

  // 팝업 모달 표시
  void _showConfirmationModal() {
    Map<String, String> inputData = {};

    if (selectedCategory == "배달팟빵") {
      inputData = {
        '음식 이름': nameController.text,
        '주문 시간': orderTimeController.text,
        '픽업 시간': pickupTimeController.text,
        '픽업 위치': pickMeUpController.text,
        '인원 수': peopleCountController.text,
        '추가 사항': detailController.text,
      };
    } else if (selectedCategory == "택시팟빵") {
      inputData = {
        '목적지': destinationController.text,
        '탑승 시간': timeController.text,
        '탑승 장소': pickMeUpController.text,
        '인원 수': peopleCountController.text,
        '추가 사항': detailController.text,
      };
    } else if (selectedCategory == "공구팟빵") {
      inputData = {
        '제품명': nameController.text,
        '마감일': timeController.text,
        '인원 수': peopleCountController.text,
        '추가 사항': detailController.text,
      };
    } else if (selectedCategory == "기타팟빵") {
      inputData = {
        '이름': nameController.text,
        '마감일': timeController.text,
        '인원 수': peopleCountController.text,
        '추가 사항': detailController.text,
      };
    }

    // 모든 항목을 다 입력해야 팟빵을 구울 수 있다는 메시지
    if (inputData.values.any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 항목을 다 입력해야 팟빵을 구울 수 있어요😢")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("아래 내용이 맞나요?"),
        content: Container(
          width: 300, // 너비를 300으로 설정
          height: 300, // 높이를 400으로 설정
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: inputData.entries
                .map((entry) => Text("${entry.key}: ${entry.value}"))
                .toList(),
          ),
        ),
        // content: Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: inputData.entries
        //       .map((entry) => Text("${entry.key}: ${entry.value}"))
        //       .toList(),
        // ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Modal을 닫고 이전 화면으로 돌아갑니다.
            },
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () {
              _submitData(inputData); // Firebase에 데이터 전송
              Navigator.of(ctx).pop(); // Modal을 닫고 detail 화면으로 이동
              Navigator.pushNamed(context, '/detail'); // 페이지 네비게이션
            },
            child: Text("확인"),
          ),
        ],
      ),
    );
  }

  // 파이어베이스에 데이터 저장
  // 파이어베이스에 데이터 저장 및 유저 interactedDocs 업데이트
  Future<void> _submitData(Map<String, String> inputData) async {
    final geoProvider = Provider.of<GeoProvider>(context, listen: false);
    try {
      // Firestore에 팟빵 데이터 추가
      DocumentReference docRef = await FirebaseFirestore.instance.collection('bread').add({
        'category': selectedCategory,
        'data': inputData,
        'peopleCount': peopleCountController.text,
        'createdAt': Timestamp.now(),
        'lat': geoProvider.latitude,
        'lon': geoProvider.longitude,
        'selected_lat': geoProvider.selectedLatitude,
        'selected_lon': geoProvider.selectedLongitude,
      });

      // 현재 유저 가져오기
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 유저의 interactedDocs 필드 업데이트
        await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .update({
              'interactedDocs': FieldValue.arrayUnion([docRef.id]), // 문서 ID 추가
            });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("팟빵을 성공적으로 구웠어요!")),
      );
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("팟빵 굽기 실패: $e")),
      );
    }
  }


  // 입력 필드 초기화
  void _clearFields() {
    nameController.clear();
    detailController.clear();
    orderTimeController.clear();
    pickMeUpController.clear();
    pickupTimeController.clear();
    destinationController.clear();
    timeController.clear();
  }

  // 스타일
  final _fieldTitleStyle = TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
  final _subTitleStyle = TextStyle(fontSize: 26, color: Colors.grey);
}
