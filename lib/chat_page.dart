import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomListPage extends StatefulWidget {
  @override
  _ChatRoomListPageState createState() => _ChatRoomListPageState();
}

class _ChatRoomListPageState extends State<ChatRoomListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 채팅방 생성 함수
  Future<void> createNewChatRoom(String roomName) async {
    try {
      final newRoom = {
        'name': roomName, // 채팅방 이름
        'createdAt': FieldValue.serverTimestamp(), // 생성 시간
      };
      final newRoomRef = await _firestore.collection('chat_rooms').add(newRoom);

      // 생성된 채팅방으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(roomId: newRoomRef.id),
        ),
      );
    } catch (e) {
      print('채팅방 생성 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('채팅방 목록')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final chatRooms = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = chatRooms[index].data() as Map<String, dynamic>;
                    final roomId = chatRooms[index].id;
                    final roomName = room['name'] ?? '이름 없음';

                    return ListTile(
                      title: Text(roomName),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPage(roomId: roomId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(),
                    decoration: InputDecoration(
                      hintText: '새 채팅방 이름 입력',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        createNewChatRoom(value.trim());
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final roomNameController = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('채팅방 생성'),
                          content: TextField(
                            controller: roomNameController,
                            decoration: InputDecoration(hintText: '채팅방 이름 입력'),
                          ),
                          actions: [
                            TextButton(
                              child: Text('취소'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: Text('확인'),
                              onPressed: () {
                                final roomName = roomNameController.text.trim();
                                if (roomName.isNotEmpty) {
                                  createNewChatRoom(roomName);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  final String roomId; // 채팅방 ID

  ChatRoomPage({required this.roomId});

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? nickname;
  String appBarTitle = ''; // AppBar 제목 초기화

  @override
  void initState() {
    super.initState();
    initializeChatRoom(); // 초기화 함수 호출
  }

  // 초기화 함수
  Future<void> initializeChatRoom() async {
    await fetchUserNickname();
    await fetchChatRoomDetails();
    setState(() {}); // 초기화 후 상태 업데이트
  }

  // 닉네임 가져오기
  Future<void> fetchUserNickname() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('user').doc(uid).get();
    nickname = userDoc.data()?['name'] ?? '익명';
  }

  // 채팅방 세부 정보 가져오기
  Future<void> fetchChatRoomDetails() async {
    final roomDoc = await _firestore.collection('bread').doc(widget.roomId).get();
    if (roomDoc.exists) {
      final data = roomDoc.data();
      final category = data?['category'];
      final roomData = data?['data'];

      switch (category) {
        case "택시팟빵":
          appBarTitle = roomData?['목적지'] ?? "알 수 없는 목적지";
          break;
        case "배달팟빵":
          appBarTitle = roomData?['음식 이름'] ?? "알 수 없는 음식 이름";
          break;
        case "공구팟빵":
          appBarTitle = roomData?['제품명'] ?? "알 수 없는 제품명";
          break;
        case "기타팟빵":
          appBarTitle = roomData?['이름'] ?? "알 수 없는 이름";
          break;
        default:
          appBarTitle = "알 수 없는 채팅방";
      }
    } else {
      appBarTitle = "채팅방 정보 없음";
    }
  }

  // 메시지 전송 함수
  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty || nickname == null) return;

    final message = {
      'nickname': nickname,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('chat_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add(message);

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle), // 즉시 표시되는 제목
      ),
      body: Column(
        children: [
          // 실시간 메시지 스트림
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final sender = message['nickname'] ?? '익명';
                    final text = message['message'] ?? '';
                    final timestamp = message['timestamp'] != null
                        ? (message['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    return ListTile(
                      title: Text(sender),
                      subtitle: Text(text),
                      trailing: Text(
                        '${timestamp.hour}:${timestamp.minute}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // 메시지 입력창
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
