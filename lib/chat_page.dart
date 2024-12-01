import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    fetchUserNickname();
  }

  // 현재 로그인된 사용자의 닉네임을 Firebase에서 가져옴
  Future<void> fetchUserNickname() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print('사용자가 로그인되어 있지 않습니다.');
        return;
      }

      final userDoc =
          await _firestore.collection('user').doc(uid).get(); // 'user' 컬렉션에서 uid로 조회
      setState(() {
        nickname = userDoc.data()?['name'] ?? '익명';
      });
    } catch (e) {
      print('닉네임 로드 오류: $e');
    }
  }

  // 메시지 전송 함수
  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty || nickname == null) return;

    try {
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

      _messageController.clear(); // 메시지 입력창 초기화
    } catch (e) {
      print('메시지 전송 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('채팅방: ${widget.roomId}')),
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
