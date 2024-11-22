import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String selectedCategory = "";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController orderTimeController = TextEditingController();
  final TextEditingController pickupTimeController = TextEditingController();
  final TextEditingController peopleCountController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("팟빵 종류를 선택해주세요", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
              // Text(
              //   selectedCategory.isNotEmpty
              //       ? "선택된 카테고리: $selectedCategory"
              //       : "카테고리를 선택해주세요!",
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              // ),
              const SizedBox(height: 20),
              if (selectedCategory == "배달팟빵") ..._buildDeliveryFields(),
              if (selectedCategory == "택시팟빵") ..._buildTaxiFields(),
              if (selectedCategory == "공구팟빵") ..._buildShoppingFields(),
              if (selectedCategory == "기타팟빵") ..._buildOtherFields(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitData,
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
        backgroundColor: isSelected ? Colors.brown : Colors.white, // 선택된 버튼은 갈색, 나머지는 흰색
        foregroundColor: isSelected ? Colors.white : Colors.black, // 텍스트 색상 설정

      ),
      child: Text(category),
    );

  }

  // 배달팟빵
  List<Widget> _buildDeliveryFields() {
    return [
      Text("무엇을 먹을 건가요?", style: _fieldTitleStyle),
      Text("상호명은 풀네임으로 적는 게 좋아요", style: _subTitleStyle),
      _buildTextField("음식 이름을 입력하세요", nameController),
      Text("더 자세하게 알려주세요", style: _fieldTitleStyle),
      Text("주문 시간", style: _fieldTitleStyle),
      _buildTextField("주문 시간을 입력하세요", orderTimeController),
      Text("픽업 시간", style: _fieldTitleStyle),
      _buildTextField("픽업 시간을 입력하세요", pickupTimeController),
      Text("인원", style: _fieldTitleStyle),
      _buildTextField("인원수를 입력하세요", peopleCountController),
      Text("추가 사항", style: _fieldTitleStyle),
      _buildTextField("추가 사항을 입력하세요", detailController),
    ];
  }

  // 택시팟빵
  List<Widget> _buildTaxiFields() {
    return [
      Text("어디로 갈 건가요?", style: _fieldTitleStyle),
      Text("장소는 상세하게 적는 게 좋아요", style: _subTitleStyle),
      _buildTextField("목적지를 입력하세요", destinationController),
      Text("더 자세하게 알려주세요", style: _fieldTitleStyle),
      Text("탑승 시간", style: _fieldTitleStyle),
      _buildTextField("탑승 시간을 입력하세요", timeController),
      Text("탑승 장소", style: _fieldTitleStyle),
      _buildTextField("탑승 장소를 입력하세요", pickupTimeController),
      Text("인원", style: _fieldTitleStyle),
      _buildTextField("인원수를 입력하세요", peopleCountController),
      Text("추가 사항", style: _fieldTitleStyle),
      _buildTextField("추가 사항을 입력하세요", detailController),
    ];
  }

  // 공구팟빵
  List<Widget> _buildShoppingFields() {
    return [
      Text("어떤 물건인가요?", style: _fieldTitleStyle),
      Text("제품명은 풀네임으로 적는 게 좋아요", style: _subTitleStyle),
      _buildTextField("보들보들 치즈볶음면", nameController),
      Text("더 자세하게 알려주세요", style: _fieldTitleStyle),
      Text("마감일", style: _fieldTitleStyle),
      _buildTextField("11월 16일 (토) 오후 9시", timeController),
      Text("인원", style: _fieldTitleStyle),
      _buildTextField("인원수를 입력하세요", peopleCountController),
      Text("추가 사항", style: _fieldTitleStyle),
      _buildTextField("추가 사항을 입력하세요", detailController),
    ];
  }

  // 기타팟빵
  List<Widget> _buildOtherFields() {
    return [
      Text("무엇을 할 건가요?", style: _fieldTitleStyle),
      _buildTextField("롤 5대5 할 사람", nameController),
      Text("더 자세하게 알려주세요", style: _fieldTitleStyle),
      Text("마감일", style: _fieldTitleStyle),
      _buildTextField("11월 16일 (토) 오후 9시", timeController),
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

  // 파베에 데이터 저장
  Future<void> _submitData() async {
    Map<String, String> inputData = {};

    if (selectedCategory == "배달팟빵") {
      inputData = {
        'name': nameController.text,
        'orderTime': orderTimeController.text,
        'pickupTime': pickupTimeController.text,
        'detail': detailController.text,
      };
    } else if (selectedCategory == "택시팟빵") {
      inputData = {
        'destination': destinationController.text,
        'time': timeController.text,
        'peopleCount' : peopleCountController.text,
        'detail': detailController.text,
      };
    } else if (selectedCategory == "공구팟빵") {
      inputData = {
        'name': nameController.text,
        'time': timeController.text,
        'peopleCount' : peopleCountController.text,
        'detail': detailController.text,
      };
    }
    else if (selectedCategory == "기타팟빵") {
      inputData = {
        'name': nameController.text,
        'time': timeController.text,
        'peopleCount' : peopleCountController.text,
        'detail': detailController.text,
      };
    }

    if (selectedCategory.isEmpty || inputData.values.any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 항목을 다 입력해야 팟빵을 구울 수 있어요😢")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bread').add({
        'category': selectedCategory,
        'data': inputData,
        'createdAt': Timestamp.now(),
      });
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
    pickupTimeController.clear();
    destinationController.clear();
    timeController.clear();
    // setState(() {
    //   selectedCategory = "";
    // });
  }

  // 스타일
  final _fieldTitleStyle = TextStyle(fontSize: 26, fontWeight: FontWeight.bold);
  final _subTitleStyle = TextStyle(fontSize: 26, color: Colors.grey);
}
